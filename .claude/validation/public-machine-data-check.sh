#!/usr/bin/env bash
# public-machine-data-check.sh — REGRA 120: registro da federação, diário e espelho do diário sem dado de máquina.
#
# POR QUE EXISTE (defeito datado). Medido em 2026-11-09, na rodada do /meta:personality-sync: o repo é
# PÚBLICO (decisão do maestro, 2026-10-13) e o `members.yaml` trazia, em campos e comentários, host da VPS,
# dois IPs públicos e o nome do arquivo de chave SSH; quatro entradas do diário traziam os mesmos dados, e o
# índice herdava um deles. A REGRA 99 só lê campos de nó de `.kg.yaml`, a REGRA 106 só olha o que viaja e a
# REGRA 36 julga nome de cliente. Comentário de YAML e corpo de diário não tinham ninguém.
#
# SÓ JULGA A FONTE. `.claude/validation` viaja, e cada adotante tem diário e pode ser privado. Fora de
# `role: source` (e numa porta, `kind: door`) a guarda sai 0 e calada: o público é propriedade deste repo.
#
# A CLASSE (motor: `re` do Python, sem locale):
#   ip   IPv4 que o `ipaddress` diz is_global, mais o CGNAT (100.64/10), com zero à esquerda normalizado e a forma
#        `ip-a-b-c-d`. Isentos: loopback, rede privada, documentação, número com um dígito em cada parte (4.6.4.1,
#        que no repo é numeração de seção ou versão) e token de produto (`Chrome/120.0.0.0`);
#   host a forma HOST_FORM de machine_path.py (o MESMO padrão da REGRA 99, num lugar só);
#   key  caminho sob `.ssh/` que nomeia arquivo, menos known_hosts, config e authorized_keys e suas cópias.
# O NOME DO ARQUIVO também é julgado, e a forma do host e do IP vale nele.
#
# A SAÍDA PARA FALSO POSITIVO: `machine-data-ok: <motivo>` na própria linha cala a linha. Sem motivo não cala.
#
# QUEM CONTROLA A ENTRADA: só commit neste repo. O registro e o diário são escritos pela sessão do core;
# sinal de adotante não chega a estes caminhos, então terceiro não dispara o veto à distância.
#
# A SAÍDA NÃO IMPRIME O VALOR: arquivo, linha e classe. O log do CI é público, e repetir o IP ali seria o vazamento.
#
# Uso : bash public-machine-data-check.sh [<raiz>] [--tsv]
#       bash public-machine-data-check.sh --selftest
# Exit: 0 = ok · 1 = violação · 2 = não pôde julgar (NAO VERIFICADO; nunca é verde).
#
# TETO DECLARADO:
#   · porta de rede NÃO é classe: número de porta é indistinguível de contagem, e a guarda não a vê;
#   · só os três caminhos acima. Outros arquivos rastreados ainda citam estes dados (medido em 2026-11-09: 34);
#   · o histórico do git segue público: esta guarda olha a árvore, e nada aqui o reescreve;
#   · host fora da forma HOST_FORM e IPv6 não são vistos; nome de chave sem `.ssh/` no caminho também não;
#   · IP depois de letra e barra (`x/151.101.1.1`) cala como token de produto; IP público com um dígito em cada
#     parte, como 8.8.8.8, também;
#   · número de 4 partes com algum octeto de 2 dígitos ou mais (`12.3.4.1`) é acusado: use o marcador;
#   · o marcador é honra visível no diff: não há contagem nem catraca dele;
#   · não vê `local_path` nem caminho de home: esses têm consumidor de código e ficam, por decisão registrada no grafo.
set -uo pipefail

_HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${_HERE}/../utils/kg"
ROOT=""; MODE="human"
while [ $# -gt 0 ]; do
  case "$1" in
    --tsv) MODE="tsv"; shift ;;
    --selftest) MODE="selftest"; shift ;;
    -*) echo "ERRO: flag desconhecida '$1'" >&2; exit 2 ;;
    *) [ -z "${ROOT}" ] || { echo "ERRO: raiz duplicada '$1'" >&2; exit 2; }; ROOT="$1"; shift ;;
  esac
done

command -v python3 >/dev/null 2>&1 || { echo "public-machine-data: python3 ausente — NAO VERIFICADO" >&2; exit 2; }
[ -f "${LIB}/machine_path.py" ] || { echo "public-machine-data: machine_path.py não está em ${LIB} — NAO VERIFICADO" >&2; exit 2; }
if [ "${MODE}" != "selftest" ]; then
  [ -n "${ROOT}" ] || ROOT="$(pwd)"
  command -v git >/dev/null 2>&1 || { echo "public-machine-data: git ausente — NAO VERIFICADO" >&2; exit 2; }
  _top="$(git -C "${ROOT}" rev-parse --show-toplevel 2>/dev/null || true)"
  [ -n "${_top}" ] || { echo "public-machine-data: '${ROOT}' não é repositório git — NAO VERIFICADO" >&2; exit 2; }
  ROOT="${_top}"
  _stamp="${ROOT}/.claude/.onion-version"
  if [ -f "${_stamp}" ]; then
    _role_v="$(awk '/^role:/{print $2; exit}' "${_stamp}")"
    _door="$(grep -cE '^[[:space:]]*kind:[[:space:]]*door([[:space:]]|$)' "${_stamp}" || true)"
    if [ "${_role_v:-source}" != "source" ] || [ "${_door:-0}" != "0" ]; then
      [ "${MODE}" = "tsv" ] || echo "public-machine-data: ISENCAO — só a fonte é julgada (papel '${_role_v:-?}')"
      exit 0
    fi
  fi
fi

python3 -I -B - "${LIB}" "${ROOT:-.}" "${MODE}" <<'PY'
import ipaddress, os, re, subprocess, sys
lib, root, mode = sys.argv[1:4]
sys.path.insert(0, lib)
import machine_path as mp

IP_RE = re.compile(r'(?<![\w.])(?<![A-Za-z]/)(\d{1,3}(?:\.\d{1,3}){3})(?!\d|\.\d)')
DASH_RE = re.compile(r'(?<![A-Za-z0-9])ip-(\d{1,3})-(\d{1,3})-(\d{1,3})-(\d{1,3})(?!\d)', re.I)
HOST_RE = re.compile(r'(?<![A-Za-z0-9_.-])' + mp.HOST_FORM + r'(?![A-Za-z0-9_-])', re.I)
KEY_RE = re.compile(r'\.ssh/([\w.-]+)')
KEY_OK = {"known_hosts", "config", "authorized_keys", "authorized_keys2"}
MARK_RE = re.compile(r'machine-data-ok:\s*\S')
CGNAT = ipaddress.ip_network("100.64.0.0/10")


def is_public(octets):
    if all(len(o) == 1 for o in octets):  # 4.6.4.1 é numeração de seção ou versão (medido no repo)
        return False
    vals = [int(o) for o in octets]
    if any(v > 255 for v in vals):
        return False
    ip = ipaddress.IPv4Address(".".join(str(v) for v in vals))
    return ip.is_global or ip in CGNAT


def classes(text):
    out = []
    for m in IP_RE.finditer(text):
        if is_public(m.group(1).split(".")):
            out.append("ip")
    for m in DASH_RE.finditer(text):
        if is_public(list(m.groups())):
            out.append("ip")
    if HOST_RE.search(text):
        out.append("host")
    for m in KEY_RE.finditer(text):
        if m.group(1).rstrip(".").split(".")[0] not in KEY_OK:
            out.append("key")
    return out


def judge(line):
    if MARK_RE.search(line):
        return []
    return classes(line)


if mode == "selftest":
    ok = bad = 0
    def check(name, text, want):
        global ok, bad
        got = sorted(set(judge(text)))
        if got == sorted(want):
            ok += 1; print(f"  ✅ {name}")
        else:
            bad += 1; print(f"  ✗ {name} — esperava {want}, veio {got}")
    # Acusa: as formas medidas em 2026-11-09, com valores fictícios para o dado real não entrar no repo.
    check("acusa: IP público em comentário de YAML", "# DNS @ e app → 151.101.1.1 (via API). TTL 300.", ["ip"])
    check("acusa: IP entre parênteses, seguido de vírgula", "rollback (IP antigo 151.101.1.1), depois deletado.", ["ip"])
    check("acusa: IP em URL", "abra http://151.101.1.1/painel", ["ip"])
    check("acusa: IP com zero à esquerda", "o velho 151.101.001.001 respondeu", ["ip"])
    check("acusa: IP na forma com hífens", "o nó ip-151-101-1-1 respondeu", ["ip"])
    check("acusa: IP colado numa letra", "151.101.1.1a", ["ip"])
    check("acusa: CGNAT", "túnel em 100.64.10.20", ["ip"])
    check("acusa: host na forma da casa", "host: srv123456      # 8 vCPU", ["host"])
    check("acusa: host em maiúsculas", "o SRV123456 respondeu", ["host"])
    check("acusa: host entre parênteses", "a máquina é a VPS (srv123456)", ["host"])
    check("acusa: arquivo de chave sob ~/.ssh", "Acesso por ssh (~/.ssh/chave_da_vps); backup", ["key"])
    check("acusa: arquivo de chave sob home absoluto", "ssh -i /home/conta/.ssh/id_ed25519 alvo", ["key"])
    check("acusa: as três classes na mesma linha", "srv123456 em 151.101.1.1 com ~/.ssh/chave", ["host", "ip", "key"])
    check("acusa: marcador sem motivo não cala", "151.101.1.1 machine-data-ok:", ["ip"])
    # Cala: o que é honesto nestes arquivos.
    check("cala: loopback", "reverse_proxy 127.0.0.1:8787 → bridge", [])
    check("cala: rede privada e bind geral", "lan 192.168.0.10 e 10.0.0.1; escuta em 0.0.0.0", [])
    check("cala: faixa de documentação", "exemplo 203.0.113.7 e 198.51.100.2", [])
    check("cala: versão com v na frente", "subiu para v1.2.3.4 hoje", [])
    check("cala: versão de 3 partes", "Claude Code 2.1.319", [])
    check("cala: número de 4 partes fora de faixa", "contagem 2.1.319.8", [])
    check("cala: versão de 5 partes", "pacote 1.2.3.4.5", [])
    check("cala: versão de 5 partes com octeto maior", "pacote 12.30.4.1.5", [])
    check("cala: numeração de seção com um dígito por parte", "ver a seção 4.6.4.1 e a versão 6.2.1.5", [])
    check("cala: token de produto", "User-Agent Chrome/120.0.0.0 no log", [])
    check("cala: arquivos de ssh que não são chave", "~/.ssh/known_hosts, ~/.ssh/config e ~/.ssh/authorized_keys", [])
    check("cala: cópia de arquivo de ssh que não é chave", "backup em ~/.ssh/known_hosts.old", [])
    check("cala: pasta .ssh sem arquivo", "permissão 700 em ~/.ssh/ e fim", [])
    check("cala: palavra que começa com srv", "o srvteste e o serviço srv-api", [])
    check("cala: forma do host colada à esquerda", "o mysrv123456 da doc", [])
    check("cala: forma do host colada à direita", "o srv123456x da doc", [])
    check("cala: placeholder do host", "a máquina é <host-da-vps>", [])
    check("cala: marcador com motivo", "versão 12.3.4.1 do pacote  <!-- machine-data-ok: é versão -->", [])
    print(f"public-machine-data selftest: {ok} passaram, {bad} falharam")
    sys.exit(1 if bad else 0)

ls = subprocess.run(["git", "-C", root, "ls-files", "-z", "--", "docs/evolution/federation/members.yaml",
                     ".claude/diary/*.md", "docs/evolution/outbox/diary/*.md"], capture_output=True)
if ls.returncode != 0:
    print("public-machine-data: git ls-files falhou — NAO VERIFICADO", file=sys.stderr); sys.exit(2)
files = [p.decode("utf-8", "surrogateescape") for p in ls.stdout.split(b"\0") if p]
if not files and os.path.exists(os.path.join(root, "docs/evolution/federation/members.yaml")):
    print("public-machine-data: lista vazia com o registro no disco — NAO VERIFICADO", file=sys.stderr); sys.exit(2)
rc = n = 0


def report(path, where, cls):
    global rc, n
    rc = 1; n += 1
    msg = f"{where}: dado de máquina da classe '{cls}' num arquivo de repo público. Troque por descrição; falso positivo: `machine-data-ok: <motivo>` na linha (o valor não é impresso de propósito)"
    print(f"HARD\tDADO-DE-MAQUINA\t{path}\t{msg}" if mode == "tsv" else f"HARD: [{path}] {msg}")


for f in files:
    # hífen e sublinhado são separadores no nome do arquivo, e a fronteira da classe os trata como parte da palavra
    for cls in sorted(set(classes(f)) | set(classes(re.sub(r"[-_]", " ", f)))):
        report(f, "nome do arquivo", cls)
    try:
        lines = open(os.path.join(root, f), encoding="utf-8").read().splitlines()
    except (OSError, UnicodeDecodeError) as e:
        print(f"public-machine-data: {f} ilegível ({type(e).__name__}) — NAO VERIFICADO", file=sys.stderr); sys.exit(2)
    for i, line in enumerate(lines, 1):
        for cls in sorted(set(judge(line))):
            report(f, f"linha {i}", cls)
if mode == "human":
    print(f"public-machine-data: {len(files)} arquivo(s), {n} acusação(ões)")
sys.exit(rc)
PY
