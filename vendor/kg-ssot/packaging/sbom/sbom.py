#!/usr/bin/env python3
"""O SBOM CycloneDX 1.7 (JSON) de cada artefato da release do KG-SSOT, só com a biblioteca padrão.

Uso:
  python3 -I packaging/sbom/sbom.py ARTEFATO... --outdir DIR [--env PYTHON] [--npm-lock package-lock.json]
  python3 -I packaging/sbom/sbom.py --image REF --out ARQUIVO

Cada ARTEFATO (o wheel, o sdist, o tarball npm, o .mcpb) vira DIR/<nome do artefato>.cdx.json. O que entra:
  - o próprio artefato em metadata.component, com o sha256 do arquivo e a licença;
  - as dependências de primeiro nível que o artefato declara, lidas DENTRO dele (o METADATA do wheel, o PKG-INFO do
    sdist, o package.json do tarball, o pyproject.toml e o uv.lock do bundle). Nenhum artefato embute código de
    terceiros: as dependências são instaladas pelo pip, pelo npm ou pelo uv do adotante, e por isso vão com
    isExternal true. Uma faixa declarada (>=6.0.2) vai em versionRange, na sintaxe vers; uma versão exata, em version;
  - com --env, o Python de um ambiente onde a release foi testada (o wheel instalado com tools/requirements.txt):
    a licença de cada dependência, a versão testada (propriedade kg-ssot:tested-version) e as transitivas que esse
    ambiente resolveu;
  - com --npm-lock, as transitivas do tarball npm, com a versão, o hash e a licença do lockfile do build;
  - no bundle com uv.lock, todo pacote travado, com o hash de cada arquivo de distribuição.
O gerador recusa (rc 1) um artefato que embuta código de terceiros (node_modules, site-packages, um wheel dentro de
outro pacote): o SBOM afirma que não há, e a afirmação tem de ser conferida.

Com --image, o SBOM da imagem OCI: a imagem base (a do FROM de packaging/oci/Dockerfile, pelo digest), os pacotes
Debian dela (/var/lib/dpkg/status), o interpretador Python e toda distribuição Python instalada, lidos da imagem por
docker run sem rede.

SOURCE_DATE_EPOCH, quando definido, data o SBOM; o serialNumber deriva do sha256 do artefato, e o mesmo artefato dá o
mesmo SBOM. rc: 0 ok · 1 artefato com código de terceiros embutido ou leitura falhou · 2 entrada quebrada.
"""
import argparse
import base64
import datetime
import hashlib
import io
import json
import os
import pathlib
import re
import subprocess
import urllib.parse
import sys
import tarfile
import tomllib
import uuid
import zipfile
from email.parser import Parser

ROOT = pathlib.Path(__file__).resolve().parents[2]
SPEC_VERSION = "1.7"
MIRROR = "https://github.com/marciocar/kg-ssot"
AUTHOR = "Marcio Carvalho"
LICENSE = "Apache-2.0"
NS = uuid.UUID("5b0e3c1e-6f4f-4f55-9a3e-6b6b2f5d1c07")  # o espaço do uuid5 do serialNumber
REQ = re.compile(r"^\s*([A-Za-z0-9][A-Za-z0-9._-]*)\s*(?:\[[^\]]*\])?\s*\(?([^;()]*)\)?\s*(?:;\s*(.*))?$")
EXTRA = re.compile(r"""extra\s*==\s*["']([^"']+)["']""")
# o campo License (antigo) que já é um id SPDX vira license.id; o resto vai como nome
SPDX_IDS = {"MIT", "ISC", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "PSF-2.0", "MPL-2.0", "0BSD", "Unlicense"}
VERS_OPS = ("===", "==", "!=", "<=", ">=", "<", ">")  # o ~= não tem par no vers: vai só na propriedade


class Broken(Exception):
    """Entrada quebrada: rc 2."""


class Embedded(Exception):
    """O artefato embute código de terceiros: rc 1."""


def norm(name):
    """O nome PyPI normalizado (PEP 503), que é o do purl."""
    return re.sub(r"[-_.]+", "-", name).lower()


def pypi_purl(name, version=None):
    return f"pkg:pypi/{norm(name)}" + (f"@{version}" if version else "")


def npm_purl(name, version=None):
    path = name.replace("@", "%40", 1) if name.startswith("@") else name
    return f"pkg:npm/{path}" + (f"@{version}" if version else "")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def license_of(meta):
    """A licença da distribuição: a License-Expression (PEP 639) como expressão SPDX; senão o nome curto do campo
    License ou do classifier. Nada de texto de licença inteiro no SBOM."""
    expr = (meta.get("expression") or "").strip()
    if expr:
        return [{"expression": expr}]
    name = (meta.get("license") or "").strip()
    if name in SPDX_IDS:
        return [{"license": {"id": name}}]
    if name and "\n" not in name and len(name) <= 80:
        return [{"license": {"name": name}}]
    for c in meta.get("classifiers", []):
        if c.startswith("License :: "):
            return [{"license": {"name": c.rsplit(" :: ", 1)[-1]}}]
    return None


def vers(scheme, spec):
    """A faixa declarada na sintaxe vers (vers:pypi/>=6.0.2|<7); None quando não há par (o ~= do Python)."""
    parts = [p.strip() for p in spec.split(",") if p.strip()]
    out = []
    for p in parts:
        op = next((o for o in VERS_OPS if p.startswith(o)), None)
        if op is None:
            return None
        v = p[len(op):].strip()
        out.append(v if op in ("==", "===") else f"{op}{v}")
    return f"vers:{scheme}/" + "|".join(out) if out else None


def requirement(line):
    """(nome, faixa, extra) de uma linha Requires-Dist."""
    m = REQ.match(line)
    if not m:
        raise Broken(f"Requires-Dist ilegível: {line!r}")
    extra = EXTRA.search(m.group(3) or "")
    return m.group(1), m.group(2).strip(), extra.group(1) if extra else None


def env_dists(python):
    """{nome normalizado: {name, version, expression, license, classifiers, requires}} do ambiente testado."""
    code = ("import importlib.metadata as m, json\n"
            "out = []\n"
            "for d in m.distributions():\n"
            "    md = d.metadata\n"
            "    out.append({'name': md['Name'], 'version': d.version, 'expression': md.get('License-Expression'),"
            " 'license': md.get('License'), 'classifiers': md.get_all('Classifier') or [], 'requires': d.requires or []})\n"
            "print(json.dumps(out))\n")
    p = subprocess.run([python, "-I", "-c", code], capture_output=True, text=True)
    if p.returncode:
        raise Broken(f"o ambiente {python} não se lê: {p.stderr.strip()[-300:]}")
    return {norm(d["name"]): d for d in json.loads(p.stdout)}


def closure(roots, dists):
    """As transitivas que o ambiente resolveu a partir de roots, sem os extras de ninguém."""
    seen, todo = set(), [norm(r) for r in roots]
    while todo:
        n = todo.pop()
        if n in seen or n not in dists:
            continue
        seen.add(n)
        for line in dists[n]["requires"]:
            name, _, extra = requirement(line)
            if extra is None:
                todo.append(norm(name))
    return seen


def depends(dists, n):
    """As dependências instaladas de n (sem extras), em bom-ref."""
    out = set()
    for line in dists[n]["requires"]:
        name, _, extra = requirement(line)
        if extra is None and norm(name) in dists:
            out.add(pypi_purl(dists[norm(name)]["name"], dists[norm(name)]["version"]))
    return sorted(out)


def timestamp():
    epoch = os.environ.get("SOURCE_DATE_EPOCH")
    t = datetime.datetime.fromtimestamp(int(epoch), datetime.UTC) if epoch else datetime.datetime.now(datetime.UTC)
    return t.replace(microsecond=0).isoformat().replace("+00:00", "Z")


def bom(root, components, dependencies, seed, version):
    """O documento CycloneDX: metadata (o artefato, a ferramenta, o autor, a fase de build), componentes e o grafo."""
    meta = {
        "timestamp": timestamp(),
        "lifecycles": [{"phase": "build"}],
        "tools": {"components": [{"type": "application", "name": "kg-ssot-sbom", "version": version,
                                  "description": "packaging/sbom/sbom.py of the KG-SSOT release",
                                  "externalReferences": [{"type": "vcs", "url": MIRROR}]}]},
        "authors": [{"name": AUTHOR}],
        "component": root,
    }
    return {
        "$schema": "http://cyclonedx.org/schema/bom-1.7.schema.json",
        "bomFormat": "CycloneDX",
        "specVersion": SPEC_VERSION,
        "serialNumber": f"urn:uuid:{uuid.uuid5(NS, seed)}",
        "version": 1,
        "metadata": meta,
        "components": sorted(components, key=lambda c: c["bom-ref"]),
        "dependencies": sorted(dependencies, key=lambda d: d["ref"]),
    }


def root_component(kind, name, version, path, purl=None, ctype="library"):
    c = {"type": ctype, "bom-ref": purl or f"{name}@{version}#{kind}", "name": name, "version": version,
         "description": f"KG-SSOT {kind}: {path.name}", "authors": [{"name": AUTHOR}],
         "licenses": [{"license": {"id": LICENSE}}], "hashes": [{"alg": "SHA-256", "content": sha256(path)}],
         "externalReferences": [{"type": "vcs", "url": MIRROR}, {"type": "website", "url": MIRROR}]}
    if purl:
        c["purl"] = purl
    return c


def declared_python(requires, dists, scheme="pypi"):
    """Os componentes das dependências de primeiro nível declaradas (o ambiente testado dá a licença e a versão
    testada) e as transitivas que o ambiente resolveu. Devolve (componentes, refs diretas, grafo).

    A dependência declarada com faixa não leva purl, e o bom-ref dela não tem a forma de purl (declared:pypi/nome): um
    purl sem versão casa qualquer versão num scanner, e o grype lê o bom-ref como purl quando falta o purl (dava
    achados abaixo da faixa). Ela leva a faixa em versionRange e aponta, no grafo, para o componente da versão testada,
    que tem o purl com versão. Só o pino exato (==X) vira version e purl com versão. As linhas da mesma dependência
    (obrigatória e num extra, ou com marcadores diferentes) viram um componente só: obrigatório se alguma linha for, com
    cada linha declarada numa propriedade, e a faixa só quando todas as linhas dizem a mesma."""
    comps, direct, graph = {}, [], []
    groups = {}
    for line in requires:
        name, spec, extra = requirement(line)
        groups.setdefault(norm(name), []).append((name, spec, extra, line))
    for n, lines in groups.items():
        name = lines[0][0]
        specs = sorted({spec for _, spec, _, _ in lines})
        extras = sorted({extra for _, _, extra, _ in lines if extra})
        required = any(extra is None for _, _, extra, _ in lines)
        c = {"type": "library", "bom-ref": f"declared:pypi/{n}", "name": name, "isExternal": True,
             "scope": "required" if required else "optional"}
        props = []
        if len(specs) == 1 and specs[0]:
            spec = specs[0]
            exact = re.fullmatch(r"===?\s*([^\s,*]+)", spec)
            r = None if exact else vers(scheme, spec)
            if exact:  # o pino exato (kg-ssot==X no bundle) é a versão, não uma faixa
                c["version"] = exact.group(1)
                c["purl"] = pypi_purl(name, c["version"])
            elif r:
                c["versionRange"] = r
            else:
                props.append({"name": "kg-ssot:declared-range", "value": spec})
        props += [{"name": "kg-ssot:declared", "value": line.strip()} for _, _, _, line in lines]
        props += [{"name": "kg-ssot:extra", "value": e} for e in extras]
        if dists and n in dists:
            lic = license_of(dists[n])
            if lic:
                c["licenses"] = lic
            props.append({"name": "kg-ssot:tested-version", "value": dists[n]["version"]})
        c["properties"] = props
        comps[c["bom-ref"]] = c
        direct.append(c["bom-ref"])
    if dists:
        roots = [requirement(x)[0] for x in requires if requirement(x)[2] is None]
        for n in sorted(closure(roots, dists)):
            d = dists[n]
            ref = pypi_purl(d["name"], d["version"])
            c = {"type": "library", "bom-ref": ref, "name": d["name"], "version": d["version"], "purl": ref,
                 "isExternal": True, "scope": "required",
                 "properties": [{"name": "kg-ssot:resolved-from", "value": "tested environment"}]}
            lic = license_of(d)
            if lic:
                c["licenses"] = lic
            comps[ref] = c
            graph.append({"ref": ref, "dependsOn": depends(dists, n)})
        for n in groups:  # o declarado aponta para o resolvido
            ref = f"declared:pypi/{n}"
            if comps[ref]["scope"] == "required" and n in dists:
                graph.append({"ref": ref, "dependsOn": [pypi_purl(dists[n]["name"], dists[n]["version"])]})
    return list(comps.values()), direct, graph


def own_names(names, allowed, what):
    """Recusa o artefato que embute código de terceiros."""
    bad = sorted(n for n in names if re.search(r"(^|/)(node_modules|site-packages)/|\.whl$|\.egg$", n) or not allowed(n))
    if bad:
        raise Embedded(f"{what} embute código de terceiros: {', '.join(bad[:5])}")


def python_artifact(path, dists):
    if path.name.endswith(".whl"):
        with zipfile.ZipFile(path) as z:
            names = z.namelist()
            own_names(names, lambda n: n.startswith(("kg_ssot/", "kg_ssot-")), path.name)
            meta = next(n for n in names if n.endswith(".dist-info/METADATA"))
            text, kind = z.read(meta).decode("utf-8"), "wheel"
    else:
        with tarfile.open(path) as t:
            names = t.getnames()
            top = names[0].split("/")[0]
            own_names(names, lambda n: n == top or n.startswith((f"{top}/src/kg_ssot", f"{top}/README", f"{top}/LICENSE",
                                                                 f"{top}/NOTICE", f"{top}/pyproject.toml", f"{top}/PKG-INFO")),
                      path.name)
            text, kind = t.extractfile(f"{top}/PKG-INFO").read().decode("utf-8"), "sdist"
    msg = Parser().parsestr(text)
    name, version = msg["Name"], msg["Version"]
    purl = pypi_purl(name, version)
    root = root_component(kind, name, version, path, purl)
    root["bom-ref"] = f"{purl}#{kind}"
    comps, direct, graph = declared_python(msg.get_all("Requires-Dist") or [], dists)
    graph.append({"ref": root["bom-ref"], "dependsOn": direct})
    return bom(root, comps, graph, f"{kind}:{sha256(path)}", version)


def npm_artifact(path, lock):
    with tarfile.open(path) as t:
        names = t.getnames()
        own_names(names, lambda n: n.startswith("package/"), path.name)
        pkg = json.loads(t.extractfile("package/package.json").read())
    name, version = pkg["name"], pkg["version"]
    purl = npm_purl(name, version)
    root = root_component("npm package", name, version, path, purl)
    packages = json.loads(pathlib.Path(lock).read_text(encoding="utf-8"))["packages"] if lock else {}
    entries = {k: v for k, v in packages.items() if k and not v.get("dev") and v.get("version")}
    comps, direct, graph = {}, [], []

    def resolve(at, dep):
        """O caminho do lockfile que o Node acha para dep a partir de at: o node_modules aninhado mais perto, subindo
        até o topo (um ajv que traz o próprio fast-uri não usa o do topo)."""
        base = at
        while True:
            key = f"{base}/node_modules/{dep}" if base else f"node_modules/{dep}"
            if key in entries:
                return key
            if not base:
                return None
            base = base.rsplit("/node_modules/", 1)[0] if "/node_modules/" in base else ""

    def component(key, n, v, entry, how):
        ref = npm_purl(n, v)
        c = {"type": "library", "bom-ref": ref, "name": n, "version": v, "purl": ref, "isExternal": True,
             "scope": "required", "properties": [{"name": "kg-ssot:resolved-from", "value": how}]}
        if key and "/node_modules/" in key:
            c["properties"].append({"name": "kg-ssot:lockfile-path", "value": key})
        if entry.get("license"):
            c["licenses"] = [{"expression": entry["license"]}]
        integrity = entry.get("integrity", "")
        if integrity.startswith("sha512-"):
            c["hashes"] = [{"alg": "SHA-512", "content": base64.b64decode(integrity[7:]).hex()}]
        if entry.get("resolved"):
            c["externalReferences"] = [{"type": "distribution", "url": entry["resolved"]}]
        comps.setdefault(ref, c)
        return ref

    for dep, spec in sorted(pkg.get("dependencies", {}).items()):
        key = resolve("", dep)
        entry = entries.get(key, {}) if key else {}
        if lock and entry.get("version") != spec:
            raise Broken(f"o package.json do tarball fixa {dep} {spec}, e o lockfile do build tem {entry.get('version')}")
        if re.fullmatch(r"\d+\.\d+\.\d+(?:[-+][\w.-]+)?", spec):
            direct.append(component(key, dep, spec, entry, "package.json (exact)"))
        else:  # faixa sem lockfile: sem purl, que sem versão casaria qualquer versão num scanner
            ref = f"declared:npm/{dep}"
            comps[ref] = {"type": "library", "bom-ref": ref, "name": dep, "isExternal": True, "scope": "required",
                          "versionRange": f"vers:npm/{spec}"}
            direct.append(ref)
    if lock:  # as transitivas do build, pelo lockfile, cada uma no caminho dela
        edges = {}
        for key, entry in sorted(entries.items()):
            n = key.rsplit("node_modules/", 1)[-1]
            ref = component(key, n, entry["version"], entry, "build lockfile")
            deps = (resolve(key, d) for d in {**entry.get("dependencies", {}), **entry.get("optionalDependencies", {})})
            edges.setdefault(ref, set()).update(npm_purl(k.rsplit("node_modules/", 1)[-1], entries[k]["version"])
                                                for k in deps if k)
        graph += [{"ref": r, "dependsOn": sorted(d)} for r, d in sorted(edges.items())]
    graph.append({"ref": purl, "dependsOn": direct})
    return bom(root, list(comps.values()), graph, f"npm:{sha256(path)}", version)


def mcpb_artifact(path, dists):
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        own_names(names, lambda n: n in ("manifest.json", "pyproject.toml", "uv.lock", "icon.png", "LICENSE", "NOTICE",
                                         "server/main.py") or n.startswith("mcpb-resources/"), path.name)
        manifest = json.loads(z.read("manifest.json"))
        project = tomllib.loads(z.read("pyproject.toml").decode("utf-8"))["project"]
        lock = tomllib.loads(z.read("uv.lock").decode("utf-8")) if "uv.lock" in names else None
    version = manifest["version"]
    root = root_component("MCP Bundle", manifest["name"], version, path, ctype="application")
    root["bom-ref"] = f"{manifest['name']}@{version}#mcpb"
    root["properties"] = [{"name": "kg-ssot:mcpb-server-type", "value": manifest["server"]["type"]}]
    if lock is None:
        comps, direct, graph = declared_python(project.get("dependencies", []), dists)
        graph.append({"ref": root["bom-ref"], "dependsOn": direct})
        return bom(root, comps, graph, f"mcpb:{sha256(path)}", version)
    comps, graph = [], []
    pkgs = {norm(p["name"]): p for p in lock["package"] if p.get("source", {}).get("virtual") != "."
            and p.get("source", {}).get("editable") != "."}
    for n, p in sorted(pkgs.items()):
        ref = pypi_purl(p["name"], p["version"])
        c = {"type": "library", "bom-ref": ref, "name": p["name"], "version": p["version"], "purl": ref,
             "isExternal": True, "scope": "required",
             "properties": [{"name": "kg-ssot:resolved-from", "value": "uv.lock in the bundle"}]}
        files = ([p["sdist"]] if "sdist" in p else []) + p.get("wheels", [])
        refs = [{"type": "distribution", "url": f["url"],
                 "hashes": [{"alg": "SHA-256", "content": f["hash"].split(":", 1)[1]}]}
                for f in files if f.get("url") and f.get("hash", "").startswith("sha256:")]
        if refs:
            c["externalReferences"] = refs
        if dists and n in dists:
            lic = license_of(dists[n])
            if lic:
                c["licenses"] = lic
        comps.append(c)
        graph.append({"ref": ref, "dependsOn": sorted(pypi_purl(pkgs[norm(d["name"])]["name"], pkgs[norm(d["name"])]["version"])
                                                      for d in p.get("dependencies", []) if norm(d["name"]) in pkgs)})
    direct = []
    for line in project.get("dependencies", []):
        n = norm(requirement(line)[0])
        if n not in pkgs:
            raise Broken(f"o pyproject do bundle pede {line}, e o uv.lock não o trava")
        direct.append(pypi_purl(pkgs[n]["name"], pkgs[n]["version"]))
    graph.append({"ref": root["bom-ref"], "dependsOn": direct})
    return bom(root, comps, graph, f"mcpb:{sha256(path)}", version)


def docker(*args):
    p = subprocess.run(["docker", *args], capture_output=True, text=True)
    if p.returncode:
        raise Broken(f"docker {args[0]}: {p.stderr.strip()[-300:]}")
    return p.stdout


def dpkg(status):
    """Os pacotes instalados do /var/lib/dpkg/status."""
    out = []
    for block in status.split("\n\n"):
        f = {}
        for line in block.splitlines():
            if line[:1].strip() and ":" in line:
                k, v = line.split(":", 1)
                f[k] = v.strip()
        if f.get("Package") and "installed" in f.get("Status", "").split():
            out.append(f)
    return out


def image_bom(ref, dockerfile):
    info = json.loads(docker("image", "inspect", ref))[0]
    labels = info.get("Config", {}).get("Labels") or {}
    env = dict(e.split("=", 1) for e in info.get("Config", {}).get("Env") or [] if "=" in e)
    version = labels.get("org.opencontainers.image.version") or ""
    if not version:
        raise Broken(f"{ref} sem o label org.opencontainers.image.version")
    run = ["run", "--rm", "--network", "none", "--entrypoint"]
    status = docker(*run, "cat", ref, "/var/lib/dpkg/status")
    osr = dict(line.split("=", 1) for line in docker(*run, "cat", ref, "/etc/os-release").splitlines() if "=" in line)
    distro = f"{osr.get('ID', 'debian').strip(chr(34))}-{osr.get('VERSION_ID', '').strip(chr(34))}"
    code = ("import importlib.metadata as m, json\n"
            "print(json.dumps([{'name': d.metadata['Name'], 'version': d.version, 'expression': d.metadata.get('License-Expression'),"
            " 'license': d.metadata.get('License'), 'classifiers': d.metadata.get_all('Classifier') or [],"
            " 'requires': d.requires or []} for d in m.distributions()]))\n")
    dists = {norm(d["name"]): d for d in json.loads(docker(*run, "python", ref, "-I", "-c", code))}
    if "kg-ssot" not in dists:
        raise Broken(f"{ref} não tem o kg-ssot instalado")
    base = re.search(r"^FROM\s+(\S+)", pathlib.Path(dockerfile).read_text(encoding="utf-8"), re.M).group(1)
    m = re.fullmatch(r"(?:(?P<reg>[^/]+\.[^/]+)/)?(?P<repo>[^:@]+)(?::(?P<tag>[^@]+))?@(?P<digest>sha256:[0-9a-f]{64})", base)
    if not m:
        raise Broken(f"o FROM do Dockerfile não é fixado por digest: {base}")
    repo = m["repo"] if "/" in m["repo"] else f"library/{m['repo']}"
    base_ref = f"pkg:oci/{repo.rsplit('/', 1)[-1]}@{m['digest'].replace(':', '%3A')}?repository_url={m['reg'] or 'docker.io'}/{repo}" + (
        f"&tag={m['tag']}" if m["tag"] else "")
    name = ref.split("@")[0].rsplit(":", 1)[0] if ":" in ref.split("/")[-1] else ref.split("@")[0]
    digests = [d.split("@", 1)[1] for d in info.get("RepoDigests") or [] if d.startswith(name + "@")]
    root = {"type": "container", "bom-ref": f"{name}@{version}#oci", "name": name, "version": version,
            "description": labels.get("org.opencontainers.image.description", ""), "authors": [{"name": AUTHOR}],
            "licenses": [{"license": {"id": LICENSE}}],
            "externalReferences": [{"type": "vcs", "url": MIRROR}],
            "properties": [{"name": "kg-ssot:image-id", "value": info["Id"]},
                           {"name": "kg-ssot:platform", "value": f"{info.get('Os')}/{info.get('Architecture')}"}]}
    if digests:
        root["purl"] = f"pkg:oci/{name.rsplit('/', 1)[-1]}@{digests[0].replace(':', '%3A')}?repository_url={name}"
    comps = [{"type": "container", "bom-ref": base_ref, "name": m["repo"], "version": m["tag"] or m["digest"],
              "purl": base_ref, "hashes": [{"alg": "SHA-256", "content": m["digest"].split(":", 1)[1]}],
              "description": "base image (FROM of packaging/oci/Dockerfile)"}]
    under_base = []
    for f in dpkg(status):
        arch = f.get("Architecture", "")
        ver = urllib.parse.quote(f.get("Version", ""), safe="+~.-_")  # a época do Debian (1:2.3) vai como %3A no purl
        # o pacote-fonte vai no qualificador upstream: é por ele que o scanner acha o aviso do Debian (o aviso de
        # glibc vale para o libc6). O campo Source traz às vezes a versão da fonte entre parênteses: "bash (5.2.37-2)".
        source = f.get("Source", "").split(" (", 1)[0].strip()
        up = f"&upstream={urllib.parse.quote(source, safe='+~.-_')}" if source else ""
        ref_ = f"pkg:deb/debian/{f['Package']}@{ver}?arch={arch}&distro={distro}{up}"
        c = {"type": "library" if f["Package"].startswith("lib") else "application", "bom-ref": ref_,
             "name": f["Package"], "version": f.get("Version", ""), "purl": ref_}
        if f.get("Source"):
            c["properties"] = [{"name": "kg-ssot:deb-source", "value": f["Source"]}]
        comps.append(c)
        under_base.append(ref_)
    if env.get("PYTHON_VERSION"):
        pref = f"pkg:generic/python@{env['PYTHON_VERSION']}"
        comps.append({"type": "application", "bom-ref": pref, "name": "python", "version": env["PYTHON_VERSION"],
                      "purl": pref, "licenses": [{"expression": "PSF-2.0"}],
                      # sem purl de registro, o CPE é o que liga o interpretador aos avisos do CPython no NVD
                      "cpe": f"cpe:2.3:a:python_software_foundation:python:{env['PYTHON_VERSION']}:*:*:*:*:*:*:*",
                      "description": "CPython interpreter of the base image (/usr/local)"})
        under_base.append(pref)
    ours = closure(["kg-ssot"], dists)
    graph = []
    for n, d in sorted(dists.items()):
        r = pypi_purl(d["name"], d["version"])
        c = {"type": "library", "bom-ref": r, "name": d["name"], "version": d["version"], "purl": r}
        lic = license_of(d)
        if lic:
            c["licenses"] = lic
        comps.append(c)
        graph.append({"ref": r, "dependsOn": depends(dists, n)})
        if n not in ours:
            under_base.append(r)
    graph.append({"ref": base_ref, "dependsOn": sorted(under_base)})
    graph.append({"ref": root["bom-ref"], "dependsOn": [base_ref, pypi_purl("kg-ssot", dists["kg-ssot"]["version"])]})
    return bom(root, comps, graph, f"oci:{info['Id']}", version)


def write(doc, out):
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{out.name}: {len(doc['components'])} componente(s), CycloneDX {SPEC_VERSION}")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("artifacts", nargs="*", type=pathlib.Path, help="o wheel, o sdist, o tarball npm, o .mcpb")
    ap.add_argument("--outdir", type=pathlib.Path, help="onde gravar <artefato>.cdx.json")
    ap.add_argument("--env", help="o Python do ambiente testado (licenças, versões testadas e transitivas)")
    ap.add_argument("--npm-lock", help="o package-lock.json do build do tarball npm (as transitivas)")
    ap.add_argument("--image", help="a imagem OCI construída (docker), em vez dos artefatos")
    ap.add_argument("--dockerfile", default=str(ROOT / "packaging" / "oci" / "Dockerfile"))
    ap.add_argument("--out", type=pathlib.Path, help="o arquivo do SBOM da imagem")
    a = ap.parse_args(argv)
    try:
        if a.image:
            if not a.out or a.artifacts:
                raise Broken("com --image, diga --out e nenhum artefato")
            write(image_bom(a.image, a.dockerfile), a.out)
            return 0
        if not a.artifacts or not a.outdir:
            raise Broken("diga os artefatos e --outdir")
        dists = env_dists(a.env) if a.env else None
        for path in a.artifacts:
            if not path.is_file():
                raise Broken(f"{path} não existe")
            if path.name.endswith((".whl", ".tar.gz")):
                doc = python_artifact(path, dists)
            elif path.name.endswith(".tgz"):
                doc = npm_artifact(path, a.npm_lock)
            elif path.name.endswith(".mcpb"):
                doc = mcpb_artifact(path, dists)
            else:
                raise Broken(f"{path.name}: tipo de artefato desconhecido (.whl, .tar.gz, .tgz, .mcpb)")
            write(doc, a.outdir / f"{path.name}.cdx.json")
        return 0
    except Embedded as exc:
        print(f"SBOM RECUSADO  {exc}")
        return 1
    except (Broken, OSError, ValueError, KeyError, StopIteration, tarfile.TarError, zipfile.BadZipFile) as exc:
        print(f"ENTRADA QUEBRADA  {exc}")
        return 2


if __name__ == "__main__":
    sys.exit(main())
