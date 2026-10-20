#!/usr/bin/env python3
"""O teste da imagem OCI do kg-mcp, só com a biblioteca padrão e o docker: o que o workflow do espelho roda antes do
push, e o que tools/test_kg_oci.py estende com os clientes reais. Precisa de KG_OCI_IMAGE, a tag de uma imagem já
construída por packaging/oci/build.py; sem ela, ou sem docker, os testes são pulados com o motivo.
Uso: KG_OCI_IMAGE=kg-ssot:X.Y.Z python3 -I packaging/oci/smoke.py
"""
import json
import os
import pathlib
import shutil
import socket
import subprocess
import time
import unittest
import urllib.error
import urllib.request
import uuid

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
IMAGE = os.environ.get("KG_OCI_IMAGE")
GOOD = (ROOT / "spec/conformance/fixtures/latest/form/minimal/valid-minimal.kg.yaml").read_text(encoding="utf-8")
BAD = (ROOT / "spec/conformance/fixtures/latest/form/minimal/bad-node-missing-label.kg.yaml").read_text(encoding="utf-8")
MODERN = {"io.modelcontextprotocol/protocolVersion": "2026-07-28", "io.modelcontextprotocol/clientCapabilities": {}}
SECRET = "s3gr3do-da-imagem"


def docker(*args, **kw):
    return subprocess.run(["docker", *args], capture_output=True, text=True, timeout=kw.pop("timeout", 120), **kw)


@unittest.skipUnless(IMAGE and shutil.which("docker"), "sem docker ou sem KG_OCI_IMAGE (a tag de uma imagem construída)")
class ImageTests(unittest.TestCase):
    """Critérios 3 a 6, rodando a imagem."""

    def stdio(self, *msgs):
        p = docker("run", "-i", "--rm", "--network", "none", IMAGE,
                   input="".join(json.dumps(m) + "\n" for m in msgs))
        self.assertEqual(p.returncode, 0, p.stderr)
        return [json.loads(line) for line in p.stdout.splitlines()]

    def test_usuario_sem_privilegio(self):
        p = docker("run", "--rm", "--entrypoint", "sh", IMAGE, "-c", "id -u; id -g; stat -c %u:%g /data")
        self.assertEqual(p.stdout.split(), ["10001", "10001", "10001:10001"])  # um usuário e um grupo só, donos do /data
        p = docker("image", "inspect", IMAGE, "--format", "{{json .Config.Labels}}")
        labels = json.loads(p.stdout)
        self.assertEqual(labels["io.modelcontextprotocol.server.name"], "io.github.marciocar/kg-ssot")
        version = json.loads((ROOT / "spec" / "release.json").read_text(encoding="utf-8"))["version"]
        self.assertEqual(labels["org.opencontainers.image.version"], version)

    def test_stdio_nas_duas_eras(self):
        init, disc, good, bad = self.stdio(
            {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-11-25"}},
            {"jsonrpc": "2.0", "id": 2, "method": "server/discover", "params": {"_meta": MODERN}},
            {"jsonrpc": "2.0", "id": 3, "method": "tools/call",
             "params": {"name": "kg_validate", "arguments": {"text": GOOD}, "_meta": MODERN}},
            {"jsonrpc": "2.0", "id": 4, "method": "tools/call", "params": {"name": "kg_validate", "arguments": {"text": BAD}}})
        self.assertEqual(init["result"]["serverInfo"]["name"], "kg-ssot")
        self.assertIn("2026-07-28", disc["result"]["supportedVersions"])
        self.assertEqual(good["result"]["structuredContent"]["results"][0]["verdict"], "PASS")
        self.assertEqual(bad["result"]["structuredContent"]["results"][0]["verdict"], "FAIL")

    def test_perfil_sem_segredo_nao_sobe(self):
        """Critério 6: no perfil sem segredo, o container sai com rc diferente de 0 e não serve nada."""
        name = f"kg-oci-failclosed-{uuid.uuid4().hex[:8]}"
        try:  # um container que sobe por engano não fica de pé depois do teste
            p = docker("run", "--rm", "--name", name, IMAGE, "--http", "8080", "--host", "0.0.0.0", "--allow-remote",
                       "--identity-header", "X-User-Email", "--secret-env", "KG_MCP_SECRET", "--root", "/data/areas",
                       "--init", timeout=30)
        except subprocess.TimeoutExpired:
            self.fail("o container subiu sem o segredo")
        finally:
            docker("rm", "-f", name)
        self.assertNotEqual(p.returncode, 0)
        self.assertIn("KG_MCP_SECRET", p.stderr)


@unittest.skipUnless(IMAGE and shutil.which("docker"), "sem docker ou sem KG_OCI_IMAGE (a tag de uma imagem construída)")
class ProfileImageTests(unittest.TestCase):
    """Critério 5: a imagem no perfil 'atrás de proxy', como o LibreChat a roda, com o armazém num volume."""

    @classmethod
    def setUpClass(cls):
        cls.volume = f"kg-oci-test-{uuid.uuid4().hex[:8]}"
        docker("volume", "create", cls.volume)
        with socket.socket() as s:
            s.bind(("127.0.0.1", 0))
            cls.port = s.getsockname()[1]
        p = docker("run", "-d", "--rm", "-p", f"127.0.0.1:{cls.port}:8080", "-e", f"KG_MCP_SECRET={SECRET}",
                   "-v", f"{cls.volume}:/data", IMAGE, "--http", "8080", "--host", "0.0.0.0", "--allow-remote",
                   "--identity-header", "X-User-Email", "--secret-env", "KG_MCP_SECRET",
                   "--root", "/data/areas", "--init", "--backend", "versioned")
        assert p.returncode == 0, p.stderr
        cls.container = p.stdout.strip()
        cls.url = f"http://127.0.0.1:{cls.port}/mcp"
        for _ in range(100):
            try:
                urllib.request.urlopen(urllib.request.Request(cls.url, method="GET"), timeout=1)
            except urllib.error.HTTPError:
                break  # respondeu (405 no GET): está de pé
            except OSError:
                time.sleep(0.2)

    @classmethod
    def tearDownClass(cls):
        docker("rm", "-f", cls.container)
        docker("volume", "rm", "-f", cls.volume)

    def post(self, msg, headers):
        req = urllib.request.Request(self.url, data=json.dumps(msg).encode(), method="POST",
                                     headers={"Content-Type": "application/json", **headers})
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.status, json.loads(r.read() or b"null")
        except urllib.error.HTTPError as e:
            return e.code, None

    def areas(self):
        p = docker("run", "--rm", "-v", f"{self.volume}:/data", "--entrypoint", "sh", IMAGE, "-c",
                   "cd /data/areas 2>/dev/null && find . -name '*.kg.yaml' | sort")
        return p.stdout.split()

    def test_sem_segredo_401_e_gravacao_na_area(self):
        write = {"jsonrpc": "2.0", "id": 1, "method": "tools/call",
                 "params": {"name": "kg_write", "arguments": {"name": "g.kg.yaml", "text": GOOD}}}
        self.assertEqual(self.post(write, {"X-User-Email": "ana@example.org"})[0], 401)
        self.assertEqual(self.post(write, {"X-Api-Key": SECRET})[0], 401)
        status, body = self.post(write, {"X-User-Email": "ana@example.org", "X-Api-Key": SECRET})
        self.assertEqual(status, 200)
        self.assertTrue(body["result"]["structuredContent"]["written"], body)
        found = [a for a in self.areas() if a.endswith("/g.kg.yaml")]
        self.assertEqual(len(found), 1, self.areas())
        self.assertTrue(found[0].startswith("./u-ana_example.org-"), found)


if __name__ == "__main__":
    unittest.main()
