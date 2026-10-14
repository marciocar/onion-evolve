#!/usr/bin/env bash
# =============================================================================
# drive-automate.sh — o degrau AUTOMATE do /meta:drive: as PARADAS DURAS como predicado executável.
#
# ── POR QUE EXISTE ───────────────────────────────────────────────────────────────────────────────
# A decisão D_AUTO_DRIVE_DEGRAU_AUTOMATE (docs/evolution/research/auto-drive-2026-10/), selada pelo
# maestro em 2026-10-12 por /meta:decide, foi «Forjar com as objeções»: o degrau nasce com as QUATRO
# arestas CONSTRAINS do grafo como requisito e com o MERGE DESLIGADO POR PADRÃO. A doutrina do drive
# (§0) já dizia que o degrau só abre quando as paradas forem predicados com mutante: merge por padrão
# sobre parada em prosa é o carimbo automático que ela existe para matar. Este script é esse predicado.
# O laço continua na sessão (o /meta:drive); o que decide PARA ou SEGUE mora aqui, e a sessão só
# executa o veredito. O LLM é veto-only: nada do que ele escreve aqui abre uma parada.
#
# ── AS QUATRO OBJEÇÕES, e onde cada uma vira código ─────────────────────────────────────────────────
#  (1) E_OPINIAO_EXPANSAO_AINDA_NAO_CONFIAVEL — o GRAFO é a SSOT da ordem; o task manager é projeção.
#      `plan` expande a cadeia pelo grafo (x_drive_parent + DEPENDS_ON), ordena topologicamente (filho
#      antes do pai, predecessor antes do dependente) e PARA em voz alta em: CICLO · ITEM-SEM-NO (item
#      do task manager sem nó, inclusive subtarefa) · NO-SEM-ITEM · PAI-FILHO-DIVERGENTE · TM-ILEGIVEL.
#  (2) E_OPINIAO_CARIMBO_PELO_QUE_FOI_LIDO — `stamp` fecha o nó só com o que LEU do forge (mergedAt,
#      SHA do merge, id do run de CI dos checks exigidos), nunca com o que a sessão diz ter feito; não
#      fecha `decision`, não faz flip de verdade (→refuted/→superseded) e não fecha pai com filho aberto.
#  (3) E_OPINIAO_RISCOS_QUE_FALTAVAM — `gate` exige os checks do ruleset PRESENTES e verdes (CI verde
#      vazio PARA); resíduo da REGRA 56 com Elenxo por agente SEPARADO (`elenxo_isolado: sim`); estado
#      retomável por item (x_drive_pr no nó, a passada no meta); insumo STALE de impacto alto PARA; o
#      status do task manager nunca fecha nada (o do Zoho mente por omissão); --merge DESLIGADO por
#      padrão, e mesmo ligado nunca para item `decision`.
#  (4) E_DOGFOOD_POR_COMANDO_REAL — o script USA a maquinaria: lê o task manager só por `tm.sh`, mergeia
#      só por `ops/merge-serial.sh` (core-only), escreve o checkpoint por `kg-drive-project.sh --close-lot`
#      e mede por `kg-radar.sh`. Não chama `gh pr merge`, API de provedor, deploy, push nem relógio.
#
# ── INVARIANTES QUE NÃO SE NEGOCIAM ────────────────────────────────────────────────────────────────
#  · MERGE: só com `--merge` na ABERTURA da passada E na chamada do `merge`. Nenhuma variável de
#    ambiente, default ou campo de grafo liga o merge sozinho. E o caminho é um só: ops/merge-serial.sh (core-only)
#    (que chama ops/pr-merge-verified.sh). Sem ele no projeto (adotante), o merge é recusado. (core-only)
#  · MOAT: diff fora da allowlist do ADR (docs/analysis, docs/evolution, docs/discussions, docs/onion, e a
#    projeção docs/backlog.md) PARA — tudo que viaja ao adotante, publica ou serve é AUDIT para sempre;
#    PR de outro repositório PARA (I3); PR que toca o próprio grafo de controle PARA (o lote é selo do
#    maestro); nó marcado ou com vocabulário de deploy/publicação/relógio PARA. Este script não agenda,
#    não faz laço e não se auto-inicia: cada chamada é uma decisão e termina.
#  · TETO: `--max-nodes` itens iniciados e `--budget` tokens por passada; estourou, PARA (budget é o que a
#    sessão declara com `charge`, fronteira escrita abaixo). Sem passada aberta, não há laço.
#  · CONTROLE: a passada (meta.x_drive_pass) e o checkpoint (meta.x_drive_checkpoint) moram no GRAFO, não
#    em prosa nem em STATE.md. Checkpoint pendente PARA tudo; a queda da sessão retoma do grafo.
#
# ── FRONTEIRA DECLARADA (o que este script NÃO prova) ──────────────────────────────────────────────
#  · Quem digitou `--merge`. O hook vê a string do modelo, não o autor da ordem; a ordem do maestro é a
#    invocação do /meta:drive. O que é mecânico: o merge não liga por omissão, e a passada que o ligou
#    fica registrada no grafo e nomeada no checkpoint, que viaja no diff do lote.
#  · O budget em tokens é DECLARADO pela sessão (`charge`). O teto de itens é contado aqui.
#  · `elenxo_isolado: sim` é auto-atestado no resíduo; o que o script exige é que a declaração exista.
#  · O que a sessão faz FORA deste script (deploy, publicação por wrapper, push) segue o
#    pretooluse-moat-gate.sh e o pretooluse-merge-gate.sh; publicar por ops/publish-door.sh --push é (core-only)
#    wrapper versionado e passa no hook — o AUTOMATE não o chama, e a parada de nó MOAT existe por isso.
#  · O selo da passada (segredo no diretório do repositório) pega edição à mão e passada sem `begin`; quem
#    lê o segredo e recalcula o hash forja, e isso é fabricação deliberada, não engano.
#  · A janela entre o gate e o merge: o merge-serial recebe só o número do PR. A política é RELIDA no estado
#    final e PARA sem carimbo (POS-MERGE-FORA-DA-POLITICA), mas o merge já aconteceu; amarrar o head dentro
#    do caminho verificado (--match-head-commit) é o que fecharia a janela, e não foi feito aqui.
#  · A parada NO-MOAT por vocabulário é rede secundária; a defesa do merge é a allowlist de caminho.
#
# ── A 1ª PASSADA ADVERSARIAL (2026-10-14) REPROVOU ESTE SCRIPT, e as curas ficaram nomeadas no código:
#    merge ligado editando o grafo (o selo), head mergeado ≠ julgado (política relida pós-merge), ordem só no
#    `next` (chain_halts em todo passo), teto furado por x_drive_pr à mão (pass_item), decisão fechada por PR
#    dentro da allowlist (PR-MEXE-EM-DECISAO), grafo fora do ROOT, carimbo que não reaplicava a política,
#    carimbo impossível no merge sem CI após rebase (runs do head julgado), estouro que matava só o filho,
#    escrita sem trava, StatusContext pendente. Cada uma tem caso (e1..e13) e mutante.
#
# Uso:
#   drive-automate.sh --status
#   drive-automate.sh plan  <grafo> [--root <NODE|ITEM>]...
#   drive-automate.sh begin <grafo> --max-nodes N --budget T [--merge] [--root <NODE|ITEM>]...
#   drive-automate.sh next  <grafo>
#   drive-automate.sh track <grafo> <NODE> --pr N
#   drive-automate.sh charge <grafo> --tokens N
#   drive-automate.sh gate  <grafo> <NODE> [--merge]
#   drive-automate.sh merge <grafo> <NODE> --merge
#   drive-automate.sh stamp <grafo> <NODE>
#   drive-automate.sh end   <grafo> "<nota do lote>"
# Exit: 0 = segue (PRONTO / MERGE-OK / escrito) · 1 = PARA (parada dura nomeada) · 2 = uso ou leitura
#       impossível (nunca vira verde) · 3 = AUDIT (merge desligado: o PR verde vai para o lote humano).
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_drive_automate_selftests).
# =============================================================================
set -uo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || { echo "drive-automate: fora de um repo git — recuso" >&2; exit 2; }
# Os irmãos (radar, censo, tm.sh) se resolvem PELO PRÓPRIO ARQUIVO, nunca por `.claude/…` literal: no plugin o
# assembler reescreve esse prefixo para ${CLAUDE_PLUGIN_ROOT}, que dentro do python não se expande (a classe que
# deixou o /onion:backlog publicado e morto em 2026-09-06). ops/ fica na raiz do projeto: é core-only.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || exit 2
cd "${ROOT}" || exit 2
command -v python3 >/dev/null 2>&1 || { echo "drive-automate: python3 ausente — as paradas não podem ser lidas (fail-closed)" >&2; exit 2; }
exec python3 -B - "${ROOT}" "${HERE}" "$@" <<'DRIVE_AUTOMATE_PY'
import sys
sys.path = [p for p in sys.path if p not in ("", ".")]
import json, os, re, subprocess, datetime, hashlib, secrets, signal, fcntl, tempfile, contextlib

try:
    import yaml
except ImportError:
    print("drive-automate: PyYAML ausente — o grafo não pode ser lido por YAML (fail-closed)", file=sys.stderr)
    sys.exit(2)

ROOT, HERE = sys.argv[1], sys.argv[2]
ARGS = sys.argv[3:]
RADAR = os.path.join(HERE, "kg-radar.sh")
DRIVE = os.path.join(HERE, "kg-drive-project.sh")
TM = os.path.normpath(os.path.join(HERE, "..", "utils", "task-manager", "tm.sh"))
MERGE_SERIAL = os.path.join(ROOT, "ops/merge-serial.sh")  # (core-only)
VERIFIED = os.path.join(ROOT, "ops/pr-merge-verified.sh")  # (core-only)
RULESET = os.path.join(ROOT, "ops/github-ruleset-main.json")  # (core-only)

# Allowlist do ADR onion-adr-autonomous-thread-runtime-2026-07 (pré-condição 2: path-allowlist mecânica).
# ALLOWLIST, nunca denylist: diretório novo que viaja ao adotante cai fora por default.
AUTOMATE_PREFIXES = ("docs/analysis/", "docs/evolution/", "docs/discussions/", "docs/onion/")
AUTOMATE_EXACT = ("docs/backlog.md",)   # projeção gerada (onion-regen-lib.sh) que não viaja
# Dentro da allowlist, o que muda o mundo lá fora: o registro da federação diz para onde se publica e quem a
# REGRA 36 protege (Elenxo da forja, achado 5). Sai da allowlist por NOME, e a lista só cresce.
AUTOMATE_DENY = ("docs/evolution/federation/",)
DIFF_CAP = 60                            # cap de tamanho do diff (ADR, pré-condição 3); o forge corta em 100
STALE_IMPACT = 4
MERGE_TIMEOUT = 36000                    # acima do envelope do merge-serial (rodadas × espera de CI ≈ 9,5 h)
# Rede SECUNDÁRIA, por vocabulário (o Elenxo mediu 3 de 15 formulações pegas pela 1ª versão). A defesa do merge é a
# allowlist de caminho; esta parada só existe para o trabalho que o hook do MOAT não vê (wrapper versionado).
MOAT_VOCAB = re.compile(r"(?i)(deploy|implant|produ[cç][aã]o|public|publish|release|marketplace|\bporta\b|"
                        r"\bcron|crontab|agend|schedul|\btimer\b|systemctl|systemd|rsync|\bvps\b|--push\b|\bpush\b|"
                        r"co-deliver|adotante|materializ)")
OK_VERDICTS = ("APROVADO", "CORRIGIDO", "REPROVADO_E_CURADO", "SEM_ACHADOS")


class Halt(Exception):
    """Parada dura: rc 1, com nome."""


class Usage(Exception):
    """Uso ou leitura impossível: rc 2."""


def say(msg=""):
    print(msg)


TIMED_OUT = 124


def run(cmd, timeout=120):
    """Roda num GRUPO de processos próprio: no estouro mata o grupo inteiro (um neto vivo seguia mergeando depois
    de o filho morrer, e o script declarava RECUSADO — Elenxo, achado 9). Estouro devolve 124, nunca sucesso."""
    try:
        p = subprocess.Popen(cmd, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                             stdin=subprocess.DEVNULL, start_new_session=True)
    except OSError as e:
        return 127, "", str(e)
    try:
        out, err = p.communicate(timeout=timeout)
        return p.returncode, out, err
    except subprocess.TimeoutExpired:
        with contextlib.suppress(OSError):
            os.killpg(p.pid, signal.SIGKILL)
        out, err = p.communicate()
        return TIMED_OUT, out or "", (err or "") + "\n(estouro de %ss: o grupo de processos foi morto)" % timeout


# ── trava e escrita atômica (Elenxo, achado 11: 8 `charge` concorrentes perdiam 200 tokens) ───────────
def _state_dir():
    rc, out, _ = run(["git", "rev-parse", "--path-format=absolute", "--git-common-dir"])
    if rc != 0 or not out.strip():
        raise Usage("não achei o diretório do git para a trava e a testemunha da passada")
    d = os.path.join(out.strip(), "onion-drive-pass")
    os.makedirs(d, mode=0o700, exist_ok=True)
    return d


@contextlib.contextmanager
def graph_lock(path):
    key = hashlib.sha256(os.path.realpath(path).encode()).hexdigest()[:24]
    fd = os.open(os.path.join(_state_dir(), key + ".lock"), os.O_CREAT | os.O_RDWR, 0o600)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        with contextlib.suppress(OSError):
            fcntl.flock(fd, fcntl.LOCK_UN)
        os.close(fd)


def write_atomic(path, txt):
    d = os.path.dirname(os.path.abspath(path))
    fd, tmp = tempfile.mkstemp(prefix=".drive-", dir=d)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(txt)
        with contextlib.suppress(OSError):
            os.chmod(tmp, os.stat(path).st_mode & 0o777)
        os.replace(tmp, path)
    except BaseException:
        with contextlib.suppress(OSError):
            os.unlink(tmp)
        raise


# ── leitura do grafo ──────────────────────────────────────────────────────────────────────────────
def load(path):
    if not os.path.isfile(path):
        raise Usage("grafo ausente: %s" % path)
    txt = open(path, encoding="utf-8").read()
    try:
        data = yaml.safe_load(txt) or {}
    except Exception as e:
        raise Usage("YAML ilegível em %s: %s" % (path, e))
    if not isinstance(data, dict) or not isinstance(data.get("nodes"), list):
        raise Usage("%s não tem `nodes:` em lista" % path)
    return txt, data


def node_map(data):
    out = {}
    for n in data.get("nodes") or []:
        if isinstance(n, dict) and n.get("id") is not None:
            out[str(n["id"])] = n
    return out


def edges(data):
    out = []
    for e in data.get("edges") or []:
        if isinstance(e, dict):
            out.append((str(e.get("from")), str(e.get("edge_type")), str(e.get("to"))))
    return out


def is_open(n):
    return str(n.get("status", "")) == "open"


def meta(data):
    m = data.get("meta")
    return m if isinstance(m, dict) else {}


def checkpoint(data):
    m = meta(data)
    v = m.get("x_drive_checkpoint", m.get("drive_checkpoint"))
    return "" if v is None else str(v)


def integrity(path):
    rc, out, err = run(["bash", RADAR, path, "--integrity", "--schema"])
    if rc != 0:
        raise Usage("o radar reprova %s em --integrity --schema (rc=%s) — não se conduz grafo que o motor não lê" % (path, rc))


# ── escrita textual verificada (lê de volta por YAML antes de gravar) ─────────────────────────────
def q(v):
    return json.dumps(str(v), ensure_ascii=False)


def _block_end(lines, start, ind):
    j = start + 1
    while j < len(lines):
        ln = lines[j]
        if ln.strip() == "" or ln.lstrip().startswith("#"):
            j += 1
            continue
        if len(ln) - len(ln.lstrip(" ")) <= ind:
            break
        j += 1
    return j


def _strip_key(body, key, ind):
    out, skip = [], False
    for ln in body:
        cur = len(ln) - len(ln.lstrip(" "))
        if skip:
            if ln.strip() == "" or cur > ind:
                continue
            skip = False
        if re.match(r"^ {%d}%s\s*:" % (ind, re.escape(key)), ln):
            skip = True
            continue
        out.append(ln)
    return out


def set_node_fields(txt, node_id, fields):
    """fields: lista de (chave, linhas já formatadas SEM a indentação base). Substitui a chave inteira."""
    lines = txt.split("\n")
    pat = re.compile(r"^(\s*)- id:\s*[\"']?%s[\"']?\s*$" % re.escape(node_id))
    hits = [i for i, l in enumerate(lines) if pat.match(l)]
    if len(hits) != 1:
        raise Usage("nó %s aparece %d vez(es) como `- id:` em bloco — escrita recusada" % (node_id, len(hits)))
    i = hits[0]
    dash = len(pat.match(lines[i]).group(1))
    ind = dash + 2
    j = _block_end(lines, i, dash)
    body = lines[i + 1:j]
    for key, _ in fields:
        body = _strip_key(body, key, ind)
    new = []
    for _, flines in fields:
        new.extend(" " * ind + fl for fl in flines)
    return "\n".join(lines[:i + 1] + new + body + lines[j:])


def set_meta_pass(txt, passd):
    lines = txt.split("\n")
    try:
        i = next(k for k, l in enumerate(lines) if l.rstrip() == "meta:")
    except StopIteration:
        raise Usage("o grafo não tem `meta:` em forma de bloco no nível 0 — escrita da passada recusada")
    j = _block_end(lines, i, 0)
    body = _strip_key(lines[i + 1:j], "x_drive_pass", 2)
    new = []
    if passd is not None:
        new.append("  x_drive_pass:")
        for k in PASS_KEYS + ("seal",):
            v = passd.get(k, "")
            if k in ("max_nodes", "budget", "spent"):
                new.append("    %s: %d" % (k, int(v)))
            else:
                new.append("    %s: %s" % (k, q(v)))
    return "\n".join(lines[:i + 1] + new + body + lines[j:])


def commit_text(path, old, new, check):
    try:
        data = yaml.safe_load(new) or {}
    except Exception as e:
        raise Usage("a escrita não relê como YAML (%s) — nada gravado" % e)
    if not check(data):
        raise Usage("a escrita não relê como escrita — nada gravado")
    write_atomic(path, new)
    rc, _, _ = run(["bash", RADAR, path, "--integrity", "--schema"])
    if rc != 0:
        write_atomic(path, old)
        raise Usage("depois da escrita o radar reprova %s — escrita DESFEITA" % path)


# ── a passada (o teto e o estado retomável) ────────────────────────────────────────────────────────
PASS_KEYS = ("id", "roots", "max_nodes", "budget", "spent", "merge", "tracked", "merged")


def get_pass(data):
    p = meta(data).get("x_drive_pass")
    if p is None:
        return None
    if not isinstance(p, dict):
        raise Usage("meta.x_drive_pass não é um mapa — campo de controle ilegível")
    out = {}
    for k in PASS_KEYS:
        out[k] = p.get(k, "")
    try:
        for k in ("max_nodes", "budget", "spent"):
            out[k] = int(out[k])
    except (TypeError, ValueError):
        raise Usage("meta.x_drive_pass com teto não inteiro — campo de controle ilegível")
    if out["merge"] not in ("ligado", "desligado"):
        raise Usage("meta.x_drive_pass.merge com valor desconhecido: %r (aceito: ligado|desligado)" % out["merge"])
    if out["spent"] < 0 or out["max_nodes"] < 1 or out["budget"] < 1:
        raise Halt("PASSADA-ADULTERADA: meta.x_drive_pass com teto ou gasto impossível (spent=%d, max_nodes=%d, budget=%d)"
                   % (out["spent"], out["max_nodes"], out["budget"]))
    out["tracked"] = [t for t in str(out["tracked"] or "").split(",") if t]
    out["merged"] = [t for t in str(out["merged"] or "").split(",") if t]
    out["roots"] = [t for t in str(out["roots"] or "").split(",") if t]
    # A TESTEMUNHA (Elenxo, achado 1: trocar `merge: "desligado"` por "ligado" no YAML ligava o merge, e uma passada
    # escrita à mão sem `begin` era aceita). Só o `begin` cria o segredo da passada, fora da árvore versionada
    # (no diretório do repositório), e toda escrita do executor re-sela. Editar a passada à mão quebra o selo e PARA.
    # TETO: quem lê o segredo e recalcula o hash forja — é fabricação deliberada, não engano, e fica declarada.
    want = pass_seal(out)
    if not want or str(p.get("seal") or "") != want:
        raise Halt("PASSADA-ADULTERADA: o selo de meta.x_drive_pass não confere (editada à mão, ou aberta sem `begin`) — feche-a com o maestro e abra outra")
    return out


def _nonce_path(pid):
    return os.path.join(_state_dir(), "pass-" + re.sub(r"[^A-Za-z0-9_.-]", "_", str(pid)))


def pass_seal(p):
    try:
        nonce = open(_nonce_path(p["id"]), encoding="utf-8").read().strip()
    except OSError:
        return None
    canon = json.dumps({k: (",".join(p[k]) if isinstance(p[k], list) else p[k]) for k in PASS_KEYS}, sort_keys=True)
    return hashlib.sha256((nonce + "\n" + canon).encode()).hexdigest()


def pass_to_yaml(p):
    d = dict(p)
    d["tracked"] = ",".join(p["tracked"])
    d["merged"] = ",".join(p["merged"])
    d["roots"] = ",".join(p["roots"])
    d["seal"] = pass_seal(p) or ""
    return d


def tracked_map(p):
    out = {}
    for t in p["tracked"]:
        node, _, pr = t.partition(":")
        out[node] = pr
    return out


def require_no_pending(data):
    ck = checkpoint(data)
    if ck == "pending":
        raise Halt("CHECKPOINT-PENDENTE: o lote anterior não foi selado (meta.x_drive_checkpoint: pending) — %s"
                   % (meta(data).get("x_drive_checkpoint_note") or "sem nota"))
    if ck not in ("", "sealed"):
        raise Usage("meta.x_drive_checkpoint com valor desconhecido: %r" % ck)


def require_pass(data):
    p = get_pass(data)
    if p is None:
        raise Halt("SEM-PASSADA: não há passada aberta (meta.x_drive_pass) — sem teto não há laço; abra com `begin`")
    return p


def require_budget(p):
    if p["spent"] >= p["budget"]:
        raise Halt("BUDGET-ESGOTADO: gasto %d de %d tokens declarados nesta passada" % (p["spent"], p["budget"]))


# ── task manager: SÓ pelo tm.sh (objeção 4) ───────────────────────────────────────────────────────
def tm_json(args):
    if not os.path.isfile(TM):
        raise Halt("TM-ILEGIVEL: sem o tm.sh (utils/task-manager/) — não leio o task manager por fora do adapter")
    rc, out, err = run(["bash", TM] + args, timeout=90)
    if rc != 0:
        raise Halt("TM-ILEGIVEL: tm.sh %s saiu rc=%s (%s)" % (" ".join(args), rc, (err or "").strip()[:200]))
    try:
        return json.loads(out)
    except ValueError:
        raise Halt("TM-ILEGIVEL: tm.sh %s não devolveu JSON" % " ".join(args))


def tm_parent(item):
    d = tm_json(["item.read", item, "--lean"])
    par = d.get("parent") if isinstance(d, dict) else None
    if isinstance(par, dict):
        return str(par.get("identifier") or par.get("id") or "") or None
    return None


def tm_children(item):
    d = tm_json(["hierarchy.subtask_list", item])
    kids = d.get("subtasks") if isinstance(d, dict) else None
    if not isinstance(kids, list):
        raise Halt("TM-ILEGIVEL: hierarchy.subtask_list %s sem lista `subtasks`" % item)
    return [str(k.get("identifier") or k.get("id")) for k in kids if isinstance(k, dict)]


# ── a expansão (objeção 1): o grafo é a SSOT da ordem ─────────────────────────────────────────────
def attention(path):
    rc, out, _ = run(["bash", RADAR, path, "--open-tsv"])
    att = {}
    if rc == 0:
        for ln in out.splitlines():
            f = ln.split("\t")
            if len(f) >= 8:
                try:
                    att[f[1]] = float(f[7])
                except ValueError:
                    pass
    return att


def expand(path, data, roots):
    nodes = node_map(data)
    order_in_file = {nid: k for k, nid in enumerate(nodes)}
    stops = []
    by_item = {}
    for nid, n in nodes.items():
        it = n.get("x_tm_item")
        if it:
            by_item.setdefault(str(it), []).append(nid)
    children = {}
    for nid, n in nodes.items():
        par = n.get("x_drive_parent")
        if par is not None:
            par = str(par)
            if par not in nodes:
                stops.append("PAI-INEXISTENTE: %s declara x_drive_parent %s, que não existe no grafo" % (nid, par))
                continue
            children.setdefault(par, []).append(nid)
    deps = {}
    for f, t, to in edges(data):
        if t == "DEPENDS_ON" and f in nodes and to in nodes:
            deps.setdefault(f, []).append(to)

    start = []
    if not roots:
        start = [nid for nid, n in nodes.items() if is_open(n)]
    for r in roots:
        if r in nodes:
            start.append(r)
        elif r in by_item:
            if len(by_item[r]) > 1:
                stops.append("ITEM-AMBIGUO: o item %s aparece em %d nós (%s)" % (r, len(by_item[r]), ",".join(by_item[r])))
            else:
                start.append(by_item[r][0])
        else:
            stops.append("ITEM-SEM-NO: %s não é id de nó nem x_tm_item de nenhum nó deste grafo" % r)

    chain, stack = [], list(start)
    seen = set()
    while stack:
        nid = stack.pop(0)
        if nid in seen:
            continue
        seen.add(nid)
        chain.append(nid)
        stack.extend(children.get(nid, []))
        stack.extend(d for d in deps.get(nid, []) if is_open(nodes[d]))

    # ordem topológica: predecessor antes do dependente; filho antes do pai
    before = {nid: set() for nid in chain}
    for nid in chain:
        for d in deps.get(nid, []):
            if d in before:
                before[nid].add(d)
        for c in children.get(nid, []):
            if c in before:
                before[nid].add(c)
    att = attention(path)
    ordered, left = [], set(chain)
    while left:
        ready = [n for n in left if not (before[n] & left)]
        if not ready:
            stops.append("CICLO: a cadeia tem ciclo em DEPENDS_ON/x_drive_parent entre %s" % ",".join(sorted(left)))
            break
        ready.sort(key=lambda n: (-att.get(n, 0.0), order_in_file[n]))
        ordered.append(ready[0])
        left.discard(ready[0])

    for nid in chain:
        n = nodes[nid]
        if not is_open(n):
            continue
        if str(n.get("node_type")) == "decision":
            stops.append("DECISAO-NAO-TOMADA: %s é decision aberta — o AUTOMATE não conduz nem fecha decisão; selo do maestro (/meta:decide) ou drive AUDIT" % nid)
        if n.get("x_drive_moat"):
            stops.append("NO-MOAT: %s está marcado x_drive_moat (%s) — deploy, publicação, repo alheio e relógio são do maestro" % (nid, n.get("x_drive_moat")))
        else:
            txt = " ".join(str(n.get(k) or "") for k in ("label", "narrative"))
            m = MOAT_VOCAB.search(txt)
            if m:
                stops.append("NO-MOAT: %s fala em %r no label/narrative — trabalho de deploy, publicação ou relógio não roda no AUTOMATE (conduza em AUDIT ou reescreva o nó)" % (nid, m.group(1)))

    tm_mode = str(meta(data).get("x_drive_tm") or "")
    if tm_mode != "none":
        item_of = {nid: str(nodes[nid].get("x_tm_item")) for nid in chain if nodes[nid].get("x_tm_item")}
        for nid in chain:
            if is_open(nodes[nid]) and nid not in item_of:
                stops.append("NO-SEM-ITEM: %s está na cadeia e não tem x_tm_item (declare meta.x_drive_tm: none se o plano não projeta no task manager)" % nid)
        if not any(s.startswith("NO-SEM-ITEM") for s in stops):
            for nid in chain:
                if nid not in item_of:
                    continue
                item = item_of[nid]
                gpar = nodes[nid].get("x_drive_parent")
                gpar_item = str(nodes[str(gpar)].get("x_tm_item")) if gpar and str(gpar) in nodes and nodes[str(gpar)].get("x_tm_item") else None
                tpar = tm_parent(item)
                if (gpar_item or None) != (tpar or None):
                    stops.append("PAI-FILHO-DIVERGENTE: %s (%s) tem pai %s no grafo e %s no task manager" % (nid, item, gpar_item or "nenhum", tpar or "nenhum"))
                for kid in tm_children(item):
                    if kid not in by_item:
                        stops.append("ITEM-SEM-NO: a subtarefa %s de %s no task manager não tem nó no grafo" % (kid, item))
                    elif str(nodes[by_item[kid][0]].get("x_drive_parent") or "") != nid:
                        stops.append("PAI-FILHO-DIVERGENTE: %s é filha de %s no task manager e não no grafo" % (kid, item))
    return nodes, ordered, stops, tm_mode


def state_of(n, tracked):
    nid = str(n.get("id"))
    if not is_open(n):
        return "FEITO"
    if str(n.get("node_type")) == "decision":
        return "DECISAO"
    if n.get("x_drive_pr") or nid in tracked:
        return "EM-VOO"
    return "TODO"


def print_plan(nodes, ordered, stops, tracked, tm_mode):
    say("# drive-automate plan — a cadeia pela ordem do grafo")
    for k, nid in enumerate(ordered, 1):
        n = nodes[nid]
        say("ITEM\t%d\t%s\t%s\t%s\t%s\t%s" % (k, nid, n.get("node_type"), state_of(n, tracked),
                                            n.get("x_tm_item") or "-", n.get("x_drive_pr") or tracked.get(nid) or "-"))
    if tm_mode == "none":
        say("AVISO\to plano declara meta.x_drive_tm: none — nó↔item não foi conferido no task manager")
    for s in stops:
        say("PARA\t" + s)
    say("VEREDITO\t%s" % ("PARA" if stops else "PRONTO"))


# ── forge (leitura) ───────────────────────────────────────────────────────────────────────────────
PR_FIELDS = "number,url,state,isDraft,baseRefName,headRefName,headRefOid,mergedAt,mergeCommit,isCrossRepository,statusCheckRollup,files"


def pr_view(pr):
    rc, out, err = run(["gh", "pr", "view", str(pr), "--json", PR_FIELDS], timeout=90)
    if rc != 0:
        raise Halt("FORGE-ILEGIVEL: gh pr view %s saiu rc=%s (%s)" % (pr, rc, (err or "").strip()[:200]))
    try:
        return json.loads(out)
    except ValueError:
        raise Halt("FORGE-ILEGIVEL: gh pr view %s não devolveu JSON" % pr)


def origin_slug():
    rc, out, _ = run(["git", "remote", "get-url", "origin"])
    if rc != 0:
        return None
    m = re.search(r"[:/]([^/:]+/[^/]+?)(?:\.git)?/?$", out.strip())
    return m.group(1).lower() if m else None


def required_checks():
    if not os.path.isfile(RULESET):
        return None
    try:
        d = json.load(open(RULESET, encoding="utf-8"))
        out = [c["context"] for r in d.get("rules", []) if r.get("type") == "required_status_checks"
               for c in r.get("parameters", {}).get("required_status_checks", [])]
    except (ValueError, KeyError, TypeError):
        return None
    return out or None


def run_id(url):
    m = re.search(r"/actions/runs/(\d+)", str(url or ""))
    return m.group(1) if m else None


def checks_verdict(pr, req):
    """Objeção 3: CI verde VAZIO não é verde. Devolve {nome: run_id} dos exigidos."""
    roll = pr.get("statusCheckRollup") or []
    if not roll:
        raise Halt("CI-VAZIO: o PR #%s não tem check nenhum no head — verde vazio não é verde" % pr.get("number"))
    seen = {}
    for c in roll:
        name = c.get("name") or c.get("context")
        concl = (c.get("conclusion") or c.get("state") or "").upper()
        status = (c.get("status") or "COMPLETED").upper()
        # StatusContext legado não tem `status`: o pendente vem em `state` (Elenxo, achado 12)
        if status != "COMPLETED" or concl in ("PENDING", "EXPECTED", "QUEUED", "IN_PROGRESS"):
            raise Halt("CI-PENDENTE: o check %s do PR #%s ainda está %s" % (name, pr.get("number"), concl if status == "COMPLETED" else status))
        if concl in ("FAILURE", "TIMED_OUT", "CANCELLED", "ACTION_REQUIRED", "STARTUP_FAILURE", "ERROR"):
            if name == "onion-review-verdict":
                continue   # o veredito do revisor sem crédito: a dispensa NOMEADA é do merge-serial, que para em achado
            raise Halt("CI-VERMELHO: o check %s do PR #%s saiu %s — vermelho inesperado PARA (abort-on-anomaly)" % (name, pr.get("number"), concl))
        seen.setdefault(name, []).append((concl, c.get("detailsUrl")))
    out = {}
    for r in req:
        got = seen.get(r)
        if not got:
            raise Halt("CI-SEM-CHECK-EXIGIDO: o check %s do ruleset não aparece no PR #%s — verde sem ele é verde vazio" % (r, pr.get("number")))
        if not any(cc == "SUCCESS" for cc, _ in got):
            raise Halt("CI-SEM-CHECK-EXIGIDO: o check %s do PR #%s saiu %s, não SUCCESS" % (r, pr.get("number"), got[0][0]))
        out[r] = next((run_id(u) for cc, u in got if cc == "SUCCESS" and run_id(u)), None)
    return out


def path_allowed(p):
    if p.startswith(AUTOMATE_DENY):
        return False
    return p.startswith(AUTOMATE_PREFIXES) or p in AUTOMATE_EXACT


def freshness_halts(path, nodes, nid, data):
    rc, out, _ = run(["bash", RADAR, path, "--freshness-tsv"])
    if rc != 0:
        raise Halt("FRESCOR-ILEGIVEL: kg-radar --freshness-tsv saiu rc=%s" % rc)
    inputs = {nid}
    for f, t, to in edges(data):
        if f == nid and t == "DEPENDS_ON":
            inputs.add(to)
        if to == nid and t in ("SUPPORTS", "CONSTRAINS", "TRACES_TO"):
            inputs.add(f)
    for ln in out.splitlines():
        f = ln.split("\t")
        if len(f) < 11 or f[0] not in inputs:
            continue
        try:
            imp = int(float(f[4]))
        except ValueError:
            imp = 0
        if f[-1].startswith("STALE") and imp >= STALE_IMPACT:
            raise Halt("INSUMO-VENCIDO: %s (impacto %d) está %s — rode /meta:kg-freshness antes de conduzir %s" % (f[0], imp, f[-1], nid))


def show(ref, rel):
    rc, out, _ = run(["git", "show", "%s:%s" % (ref, rel)])
    return out if rc == 0 else None


def residue(pr):
    slug = str(pr.get("headRefName") or "").replace("/", "-")
    rel = "docs/evolution/review/%s.md" % slug
    paths = [f.get("path") for f in (pr.get("files") or [])]
    if rel not in paths:
        raise Halt("SEM-RESIDUO: o PR #%s não traz %s (REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial))" % (pr.get("number"), rel))
    out = show(pr.get("headRefOid"), rel)
    if out is None:
        raise Halt("RESIDUO-ILEGIVEL: não li %s no head %s (a branch foi buscada?)" % (rel, str(pr.get("headRefOid"))[:12]))
    m = re.match(r"^---\n(.*?)\n---", out, re.S)
    try:
        fm = yaml.safe_load(m.group(1)) if m else None
    except Exception:
        fm = None
    if not isinstance(fm, dict):
        raise Halt("RESIDUO-ILEGIVEL: %s sem frontmatter YAML" % rel)
    return rel, fm


def _decisions(txt):
    try:
        d = yaml.safe_load(txt) or {}
    except Exception:
        return None
    out = {}
    for n in (d.get("nodes") or []) if isinstance(d, dict) else []:
        if isinstance(n, dict) and n.get("id") is not None:
            out[str(n["id"])] = (str(n.get("node_type")), str(n.get("status")))
    return out


def graph_rel_of(path):
    real, root = os.path.realpath(path), os.path.realpath(ROOT)
    if os.path.commonpath([real, root]) != root:
        raise Usage("o grafo de controle %s está fora deste projeto (%s) — o AUTOMATE só conduz o grafo do repo que o hospeda" % (path, ROOT))
    return os.path.relpath(real, root)


def pr_policy(pr, path):
    """As paradas que valem para o PR em QUALQUER momento (antes do merge e depois, e no carimbo):
    repositório, base, tamanho, grafo de controle, allowlist e decisão mexida."""
    pr_num = pr.get("number")
    slug = origin_slug()
    url = str(pr.get("url") or "")
    m = re.search(r"github\.com/([^/]+/[^/]+)/pull/", url)
    if not slug or not m or m.group(1).lower() != slug:
        raise Halt("REPO-ALHEIO: o PR %s não é do repositório deste projeto (%s) — I3" % (url or pr_num, slug or "origin ilegível"))
    if pr.get("isCrossRepository"):
        raise Halt("REPO-ALHEIO: o PR #%s vem de um fork (isCrossRepository) — I3" % pr_num)
    if pr.get("baseRefName") != "main":
        raise Halt("BASE-NAO-MAIN: o PR #%s mira %s" % (pr_num, pr.get("baseRefName")))
    files = [f.get("path") for f in (pr.get("files") or [])]
    if len(files) >= DIFF_CAP:
        raise Halt("DIFF-GRANDE: o PR #%s toca %d arquivos (cap %d) — o forge corta a lista em 100 e diff grande é AUDIT" % (pr_num, len(files), DIFF_CAP))
    graph_rel = graph_rel_of(path)
    if graph_rel in files:
        raise Halt("PR-DO-CONTROLE: o PR #%s toca o grafo de controle %s — o lote é selo do maestro, nunca auto-merge" % (pr_num, graph_rel))
    out = [f for f in files if not path_allowed(f)]
    if out:
        raise Halt("PATH-VENDORIZADO: o PR #%s toca fora da allowlist do AUTOMATE (%s) — o que viaja, publica ou serve é AUDIT para sempre" % (pr_num, ", ".join(out[:5])))
    # Um PR na allowlist pode FECHAR uma decisão em outro grafo (Elenxo, achado 5): a objeção 2 vale para o diff também.
    head = pr.get("headRefOid")
    for f in files:
        if not f.endswith(".kg.yaml"):
            continue
        new = show(head, f)
        if new is None:
            raise Halt("GRAFO-ILEGIVEL: não li %s no head %s — não sei se o PR mexe em decisão" % (f, str(head)[:12]))
        old = show("origin/main", f)
        dn, do = _decisions(new), (_decisions(old) if old is not None else {})
        if dn is None or do is None:
            raise Halt("GRAFO-ILEGIVEL: %s não lê como YAML no head ou na base" % f)
        for nid in set(dn) | set(do):
            a, b = do.get(nid), dn.get(nid)
            if (a and a[0] == "decision") or (b and b[0] == "decision"):
                if a != b:
                    raise Halt("PR-MEXE-EM-DECISAO: o PR #%s muda a decision %s em %s (%s → %s) — decisão é selo do maestro" % (pr_num, nid, f, a, b))
    return files


def pass_item(p, nid, n):
    """O item tem de estar vinculado NESTA passada (Elenxo, achado 4: x_drive_pr escrito à mão ou herdado de outra
    passada não contava no teto). Devolve o número do PR."""
    pr_num = tracked_map(p).get(nid)
    if not pr_num:
        raise Halt("ITEM-FORA-DA-PASSADA: %s não foi vinculado nesta passada (track) — só se julga o que conta no teto" % nid)
    if n.get("x_drive_pr") and str(n.get("x_drive_pr")) != pr_num:
        raise Halt("PR-TROCADO: %s tem x_drive_pr %s no nó e %s na passada" % (nid, n.get("x_drive_pr"), pr_num))
    return pr_num


def chain_halts(nodes, nid, data):
    """A ordem topológica vale em TODO passo, não só no next (Elenxo, achado 3)."""
    kids_open = [c for c, cn in nodes.items() if str(cn.get("x_drive_parent") or "") == nid and is_open(cn)]
    if kids_open:
        raise Halt("PAI-COM-FILHO-ABERTO: %s tem filho(s) aberto(s): %s" % (nid, ",".join(kids_open)))
    preds = [to for f, t, to in edges(data) if f == nid and t == "DEPENDS_ON" and to in nodes and is_open(nodes[to])]
    if preds:
        raise Halt("PREDECESSOR-ABERTO: %s depende de %s, ainda aberto(s) — a cadeia anda em ordem" % (nid, ",".join(preds)))


def gate(path, nid, want_merge, quiet=False):
    """O predicado do merge. Devolve (rc, motivo, contexto)."""
    graph_rel_of(path)
    integrity(path)
    txt, data = load(path)
    require_no_pending(data)
    p = require_pass(data)
    require_budget(p)
    nodes = node_map(data)
    if nid not in nodes:
        raise Usage("nó inexistente: %s" % nid)
    n = nodes[nid]
    if str(n.get("node_type")) == "decision":
        raise Halt("ITEM-E-DECISION: %s é decision — o AUTOMATE nunca mergeia nem fecha decisão (objeção 3)" % nid)
    if not is_open(n):
        raise Halt("ITEM-FECHADO: %s já está %s — nó em voo nunca é re-selecionado" % (nid, n.get("status")))
    chain_halts(nodes, nid, data)
    pr_num = pass_item(p, nid, n)
    freshness_halts(path, nodes, nid, data)
    pr = pr_view(pr_num)
    if pr.get("state") != "OPEN" or pr.get("isDraft"):
        raise Halt("PR-NAO-ABERTO: o PR #%s está %s%s" % (pr_num, pr.get("state"), " (draft)" if pr.get("isDraft") else ""))
    pr_policy(pr, path)
    req = required_checks()
    if req is None:
        raise Halt("SEM-RULESET: ops/github-ruleset-main.json ausente ou ilegível — não sei quais checks são exigidos (core-only)")
    runs = checks_verdict(pr, req)
    rel, fm = residue(pr)
    if str(fm.get("elenxo") or "").lower() != "sim":
        raise Halt("ELENXO-AUSENTE: %s declara elenxo: %s" % (rel, fm.get("elenxo")))
    if str(fm.get("elenxo_isolado") or "").lower() != "sim":
        raise Halt("ELENXO-UMA-VOZ: %s não declara elenxo_isolado: sim — Elenxo do mesmo agente é uma voz só (objeção 3)" % rel)
    if str(fm.get("verdict") or "") not in OK_VERDICTS:
        raise Halt("ELENXO-REPROVADO: %s tem verdict %s" % (rel, fm.get("verdict")))
    if str(fm.get("reviewed_diff_sha256") or "pendente").lower() in ("pendente", ""):
        raise Halt("RESIDUO-PENDENTE: %s ainda tem reviewed_diff_sha256 pendente — o pr-finalize não fechou o PR" % rel)
    if not want_merge:
        return 3, "AUDIT: o PR #%s passou em todas as paradas, e o merge está DESLIGADO (sem --merge) — vai para o lote humano" % pr_num, (pr, runs)
    if p["merge"] != "ligado":
        raise Halt("MERGE-NAO-AUTORIZADO-NA-PASSADA: a passada %s foi aberta sem --merge — o merge não liga no meio do laço" % p["id"])
    if not (os.path.isfile(MERGE_SERIAL) and os.path.isfile(VERIFIED)):
        raise Halt("SEM-CAMINHO-VERIFICADO: ops/merge-serial.sh ou ops/pr-merge-verified.sh ausente (core-only) — o AUTOMATE não mergeia por outro caminho")
    return 0, "MERGE-OK: o PR #%s pode entrar pelo ops/merge-serial.sh" % pr_num, (pr, runs)  # (core-only)


# ── comandos ──────────────────────────────────────────────────────────────────────────────────────
def parse_roots(rest):
    roots, other = [], []
    k = 0
    while k < len(rest):
        if rest[k] == "--root":
            if k + 1 >= len(rest) or not rest[k + 1] or rest[k + 1].startswith("--"):
                raise Usage("--root exige um valor")
            roots.append(rest[k + 1])
            k += 2
        else:
            other.append(rest[k])
            k += 1
    return roots, other


def opt(rest, name, required=True):
    if name in rest:
        k = rest.index(name)
        if k + 1 >= len(rest) or rest[k + 1].startswith("--"):
            raise Usage("%s exige um valor" % name)
        return rest[k + 1]
    if required:
        raise Usage("%s é obrigatório" % name)
    return None


def as_int(v, name):
    if not re.fullmatch(r"\d+", str(v or "")):
        raise Usage("%s exige inteiro >= 0 (veio %r)" % (name, v))
    return int(v)


def cmd_status():
    say("# AUTOMATE do /meta:drive — estado medido agora")
    say("- merge por padrão: DESLIGADO (decisão de 2026-10-12, D_AUTO_DRIVE_DEGRAU_AUTOMATE); liga só com --merge no begin E no merge")
    say("- caminho de merge verificado: %s" % ("presente (ops/merge-serial.sh → ops/pr-merge-verified.sh)" if os.path.isfile(MERGE_SERIAL) and os.path.isfile(VERIFIED) else "AUSENTE — neste projeto o AUTOMATE só chega a PR-verde (AUDIT)"))  # (core-only)
    req = required_checks()
    say("- checks exigidos pelo ruleset: %s" % (", ".join(req) if req else "ILEGÍVEL — gate recusa o merge"))
    moat = os.path.isfile(os.path.join(ROOT, "ops/moat-targets.tsv"))  # (core-only)
    say("- veto do MOAT por alvo (pretooluse-moat-gate.sh): %s" % ("armado" if moat else "DESARMADO (sem ops/moat-targets.tsv) — MOAT segue prosa aqui"))  # (core-only)
    # pré-filtro por texto (superconjunto: a chave citada num label também casa), e o veredito por YAML.
    # Ler os ~150 grafos por PyYAML custava 12 s na carga do comando; o filtro deixa só os candidatos.
    rc, out, _ = run(["git", "grep", "-l", "-E", "^[[:space:]]+x_drive_(checkpoint|pass)[[:space:]]*:", "--", "*.kg.yaml"])
    if rc not in (0, 1):
        say("- passadas e checkpoints: NÃO PUDE MEDIR (git grep saiu rc=%s)" % rc)
        return 0
    pend, opened = [], []
    for rel in out.splitlines():
        if "/fixtures/" in rel:
            continue
        try:
            d = yaml.safe_load(open(os.path.join(ROOT, rel), encoding="utf-8")) or {}
        except Exception:
            continue
        m = d.get("meta") if isinstance(d, dict) and isinstance(d.get("meta"), dict) else {}
        if str(m.get("x_drive_checkpoint", "")) == "pending":
            pend.append(rel)
        if isinstance(m.get("x_drive_pass"), dict):
            pp = m["x_drive_pass"]
            opened.append("%s (passada %s, merge %s, gasto %s/%s)" % (rel, pp.get("id"), pp.get("merge"), pp.get("spent"), pp.get("budget")))
    say("- checkpoint pendente (PARA tudo): %s" % (", ".join(pend) if pend else "nenhum"))
    say("- passada AUTOMATE aberta (retomar, nunca reabrir): %s" % ("; ".join(opened) if opened else "nenhuma"))
    return 0


def cmd_plan(path, rest):
    roots, other = parse_roots(rest)
    if other:
        raise Usage("argumento desconhecido em plan: %s" % " ".join(other))
    graph_rel_of(path)
    integrity(path)
    txt, data = load(path)
    stops = []
    ck = checkpoint(data)
    if ck == "pending":
        stops.append("CHECKPOINT-PENDENTE: o lote anterior não foi selado — %s" % (meta(data).get("x_drive_checkpoint_note") or "sem nota"))
    p = get_pass(data)
    nodes, ordered, st, tm_mode = expand(path, data, roots or (p["roots"] if p else []))
    stops.extend(st)
    print_plan(nodes, ordered, stops, tracked_map(p) if p else {}, tm_mode)
    return 1 if stops else 0


def cmd_begin(path, rest):
    roots, other = parse_roots(rest)
    want_merge = "--merge" in other
    other = [o for o in other if o != "--merge"]
    maxn = as_int(opt(other, "--max-nodes"), "--max-nodes")
    budget = as_int(opt(other, "--budget"), "--budget")
    if maxn < 1 or budget < 1:
        raise Usage("--max-nodes e --budget têm de ser >= 1 — sem teto não há laço")
    graph_rel_of(path)
    integrity(path)
    txt, data = load(path)
    require_no_pending(data)
    old = get_pass(data)
    if old is not None:
        say("RETOMADA: a passada %s segue aberta (gasto %d/%d, iniciados %d/%d, merge %s) — o teto e o gasto NÃO zeram"
            % (old["id"], old["spent"], old["budget"], len(old["tracked"]), old["max_nodes"], old["merge"]))
        if roots and roots != old["roots"]:
            say("AVISO: a retomada mantém as raízes da passada (%s); as pedidas agora (%s) foram IGNORADAS"
                % (",".join(old["roots"]) or "fila inteira", ",".join(roots)))
        if want_merge and old["merge"] != "ligado":
            raise Halt("MERGE-NAO-AUTORIZADO-NA-PASSADA: a passada aberta tem merge desligado — não se liga merge numa retomada; feche o lote (end) e abra outra")
        return 0
    nodes, ordered, stops, tm_mode = expand(path, data, roots)
    if stops:
        print_plan(nodes, ordered, stops, {}, tm_mode)
        return 1
    pid = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H%M%SZ") + "-" + secrets.token_hex(3)
    fd = os.open(_nonce_path(pid), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        f.write(secrets.token_hex(32) + "\n")
    newp = {"id": pid, "roots": roots, "max_nodes": maxn, "budget": budget, "spent": 0,
            "merge": "ligado" if want_merge else "desligado", "tracked": [], "merged": []}
    new = set_meta_pass(txt, pass_to_yaml(newp))
    commit_text(path, txt, new, lambda d: isinstance(meta(d).get("x_drive_pass"), dict) and meta(d)["x_drive_pass"].get("id") == pid)
    say("PASSADA-ABERTA\t%s\tmax_nodes=%d\tbudget=%d\tmerge=%s" % (pid, maxn, budget, newp["merge"]))
    return 0


def cmd_next(path, rest):
    if rest:
        raise Usage("next não aceita argumentos")
    graph_rel_of(path)
    integrity(path)
    txt, data = load(path)
    require_no_pending(data)
    p = require_pass(data)
    require_budget(p)
    nodes, ordered, stops, tm_mode = expand(path, data, p["roots"])
    if stops:
        print_plan(nodes, ordered, stops, tracked_map(p), tm_mode)
        return 1
    tm = tracked_map(p)
    for nid in ordered:
        if state_of(nodes[nid], tm) == "EM-VOO":
            if nid not in tm and len(p["tracked"]) >= p["max_nodes"]:
                raise Halt("TETO-DE-NOS: %s está em voo de outra passada e esta já iniciou %d de %d itens" % (nid, len(p["tracked"]), p["max_nodes"]))
            say("RETOMAR\t%s\tPR #%s%s" % (nid, tm.get(nid) or nodes[nid].get("x_drive_pr"), "" if nid in tm else "\t(de outra passada: vincule com track, conta no teto)"))
            return 0
    if len(p["tracked"]) >= p["max_nodes"]:
        raise Halt("TETO-DE-NOS: a passada já iniciou %d de %d itens — feche o lote (end)" % (len(p["tracked"]), p["max_nodes"]))
    done = {nid for nid in ordered if not is_open(nodes[nid])}
    deps = {}
    for f, t, to in edges(data):
        if t == "DEPENDS_ON":
            deps.setdefault(f, set()).add(to)
    for nid in ordered:
        n = nodes[nid]
        if state_of(n, tm) != "TODO":
            continue
        pending_kids = [c for c in ordered if str(nodes[c].get("x_drive_parent") or "") == nid and is_open(nodes[c])]
        blocked = [d for d in deps.get(nid, ()) if d in nodes and is_open(nodes[d])]
        if pending_kids or blocked:
            continue
        freshness_halts(path, nodes, nid, data)
        say("PROXIMO\t%s\t%s" % (nid, n.get("x_tm_item") or "-"))
        return 0
    say("DONE\tnada pronto na cadeia (feitos: %d de %d)" % (len(done), len(ordered)))
    return 0


def cmd_track(path, rest):
    if len(rest) < 1:
        raise Usage("track <grafo> <NODE> --pr N")
    nid = rest[0]
    pr = as_int(opt(rest[1:], "--pr"), "--pr")
    graph_rel_of(path)
    integrity(path)
    txt, data = load(path)
    require_no_pending(data)
    p = require_pass(data)
    require_budget(p)
    nodes = node_map(data)
    if nid not in nodes:
        raise Usage("nó inexistente: %s" % nid)
    if str(nodes[nid].get("node_type")) == "decision":
        raise Halt("ITEM-E-DECISION: %s é decision — não entra no AUTOMATE" % nid)
    if not is_open(nodes[nid]):
        raise Halt("ITEM-FECHADO: %s já está %s" % (nid, nodes[nid].get("status")))
    tm = tracked_map(p)
    if nid in tm:
        if tm[nid] == str(pr):
            say("JA-VINCULADO\t%s\tPR #%s" % (nid, pr))
            return 0
        raise Halt("PR-TROCADO: %s já está vinculado ao PR #%s nesta passada (pedido: #%s)" % (nid, tm[nid], pr))
    if len(p["tracked"]) >= p["max_nodes"]:
        raise Halt("TETO-DE-NOS: a passada já iniciou %d de %d itens" % (len(p["tracked"]), p["max_nodes"]))
    chain_halts(nodes, nid, data)
    p["tracked"].append("%s:%s" % (nid, pr))
    new = set_node_fields(txt, nid, [("x_drive_pr", ["x_drive_pr: %s" % q(pr)])])
    new = set_meta_pass(new, pass_to_yaml(p))
    commit_text(path, txt, new, lambda d: str(node_map(d)[nid].get("x_drive_pr")) == str(pr))
    say("VINCULADO\t%s\tPR #%s\t(%d/%d)" % (nid, pr, len(p["tracked"]), p["max_nodes"]))
    return 0


def cmd_charge(path, rest):
    toks = as_int(opt(rest, "--tokens"), "--tokens")
    graph_rel_of(path)
    integrity(path)
    txt, data = load(path)
    p = require_pass(data)
    p["spent"] += toks
    new = set_meta_pass(txt, pass_to_yaml(p))
    commit_text(path, txt, new, lambda d: int(meta(d)["x_drive_pass"]["spent"]) == p["spent"])
    say("GASTO\t%d/%d" % (p["spent"], p["budget"]))
    if p["spent"] >= p["budget"]:
        raise Halt("BUDGET-ESGOTADO: gasto %d de %d — a passada para aqui; feche o lote (end)" % (p["spent"], p["budget"]))
    return 0


def cmd_gate(path, rest):
    if len(rest) < 1:
        raise Usage("gate <grafo> <NODE> [--merge]")
    rc, msg, _ = gate(path, rest[0], "--merge" in rest[1:])
    say(msg)
    return rc


def stamp_node(path, nid, judged=None):
    """judged = (oid, runs) do head que o gate julgou, quando o carimbo vem do `merge`: o merge sem CI depois de
    auto-rebase limpo deixa o head NOVO sem checks, e os runs que valem são os do head julgado (Elenxo, achado 8)."""
    txt, data = load(path)
    nodes = node_map(data)
    if nid not in nodes:
        raise Usage("nó inexistente: %s" % nid)
    n = nodes[nid]
    if str(n.get("node_type")) == "decision":
        raise Halt("ITEM-E-DECISION: %s é decision — o carimbo automático nunca fecha decisão" % nid)
    if not is_open(n):
        raise Halt("ITEM-FECHADO: %s já está %s — o carimbo não refaz nem faz flip de verdade" % (nid, n.get("status")))
    kids_open = [c for c, cn in nodes.items() if str(cn.get("x_drive_parent") or "") == nid and is_open(cn)]
    if kids_open:
        raise Halt("PAI-COM-FILHO-ABERTO: %s tem filho(s) aberto(s): %s — o épico não fecha antes" % (nid, ",".join(kids_open)))
    # o carimbo também é passo do laço: sem passada, com checkpoint pendente ou fora do teto, não carimba
    require_no_pending(data)
    p = require_pass(data)
    pr_num = pass_item(p, nid, n)
    pr = pr_view(pr_num)
    if pr.get("state") != "MERGED" or not pr.get("mergedAt") or not (pr.get("mergeCommit") or {}).get("oid"):
        raise Halt("PR-NAO-MERGEADO: o forge diz que o PR #%s está %s (mergedAt=%s) — o carimbo lê o estado, nunca o relato"
                   % (pr_num, pr.get("state"), pr.get("mergedAt")))
    pr_policy(pr, path)
    req = required_checks() or []
    if judged:
        oid, runs = judged
        where = "no head julgado %s" % str(oid)[:12]
    else:
        runs = {}
        for c in pr.get("statusCheckRollup") or []:
            nm = c.get("name") or c.get("context")
            if nm in req and (c.get("conclusion") or "").upper() == "SUCCESS" and run_id(c.get("detailsUrl")):
                runs[nm] = run_id(c.get("detailsUrl"))
        where = "no head %s" % str(pr.get("headRefOid"))[:12]
    if not req or any(not runs.get(r) for r in req):
        raise Halt("CI-SEM-RUN: não li o run de CI SUCCESS de todos os checks exigidos (%s) no PR #%s" % (",".join(req) or "ruleset ilegível", pr_num))
    sha = pr["mergeCommit"]["oid"]
    url = pr.get("url")
    when = str(pr["mergedAt"])[:10]
    runs_txt = ", ".join("%s run %s" % (k, runs[k]) for k in req)
    fields = [
        ("status", ["status: done"]),
        ("verified_at", ["verified_at: %s" % q(when)]),
        ("verified_against", ["verified_against: %s" % q("lido no forge: PR #%s MERGED em %s, merge %s; checks exigidos SUCCESS %s: %s" % (pr_num, pr["mergedAt"], sha[:12], where, runs_txt))]),
        ("provenance", ["provenance:",
                        "  source: %s" % q("estado do forge lido por gh pr view %s (state, mergedAt, mergeCommit, statusCheckRollup)" % pr_num),
                        "  locator: %s" % q("%s · merge %s · %s" % (url, sha, runs_txt)),
                        "  method: %s" % q("leitura: drive-automate.sh stamp lê o estado do forge depois do merge, nunca o que a sessão relata"),
                        "  locality: \"web\""]),
    ]
    new = set_node_fields(txt, nid, fields)
    commit_text(path, txt, new, lambda d: node_map(d)[nid].get("status") == "done")
    say("CARIMBADO\t%s\tPR #%s\tmerge %s\t%s" % (nid, pr_num, sha[:12], runs_txt))
    return 0


def cmd_stamp(path, rest):
    if len(rest) != 1:
        raise Usage("stamp <grafo> <NODE>")
    graph_rel_of(path)
    integrity(path)
    return stamp_node(path, rest[0])


def mark_merged(path, nid):
    txt, data = load(path)
    p = require_pass(data)
    if nid not in p["merged"]:
        p["merged"].append(nid)
        new = set_meta_pass(txt, pass_to_yaml(p))
        commit_text(path, txt, new, lambda d: nid in str(meta(d)["x_drive_pass"].get("merged")))


def cmd_merge(path, rest):
    if len(rest) < 1:
        raise Usage("merge <grafo> <NODE> --merge")
    nid = rest[0]
    if "--merge" not in rest[1:]:
        say("AUDIT: merge sem --merge não acontece — o merge é DESLIGADO por padrão")
        return 3
    rc, msg, ctx = gate(path, nid, True)
    say(msg)
    if rc != 0:
        return rc
    pr, runs = ctx
    num = str(pr.get("number"))
    oid = pr.get("headRefOid")
    mrc, mout, merr = run(["bash", MERGE_SERIAL, num], timeout=MERGE_TIMEOUT)
    sys.stdout.write(mout)
    after = pr_view(num)   # o forge decide se houve merge, nunca o rc (um estouro pode ter mergeado)
    if after.get("state") != "MERGED":
        raise Halt("MERGE-RECUSADO: ops/merge-serial.sh %s saiu rc=%s e o forge diz %s — %s" % (num, mrc, after.get("state"), (merr or "").strip()[-300:]))  # (core-only)
    with graph_lock(path):
        mark_merged(path, nid)   # gravado ANTES do carimbo: o lote nunca mente que um PR mergeado ficou para o humano
    # O head mergeado pode não ser o julgado (rebase, push durante a espera de CI): a política é RELIDA no estado
    # final do PR (Elenxo, achado 2). Divergiu, o merge já aconteceu: PARA nomeado, sem carimbo, para o maestro.
    try:
        pr_policy(after, path)
    except Halt as h:
        raise Halt("POS-MERGE-FORA-DA-POLITICA: o PR #%s mergeado (head %s, julgado %s) não passa mais: %s — NÃO carimbado; leve ao maestro"
                   % (num, str(after.get("headRefOid"))[:12], str(oid)[:12], h))
    with graph_lock(path):
        stamp_node(path, nid, judged=(oid, runs))
    return 0


def cmd_end(path, rest):
    if len(rest) != 1 or not rest[0].strip():
        raise Usage("end <grafo> \"<nota do lote>\"")
    graph_rel_of(path)
    integrity(path)
    txt, data = load(path)
    p = require_pass(data)
    tm = tracked_map(p)
    nodes = node_map(data)
    open_prs, unstamped = [], []
    for k, v in tm.items():
        if k in p["merged"]:
            if k in nodes and is_open(nodes[k]):
                unstamped.append("%s (PR #%s)" % (k, v))
            continue
        try:
            st = pr_view(v).get("state")
        except Halt:
            st = "ILEGIVEL"
        (unstamped if st == "MERGED" else open_prs).append("%s (PR #%s%s)" % (k, v, "" if st in ("OPEN", "MERGED") else ", " + str(st)))
    stamped = [k for k in p["merged"] if k in nodes and not is_open(nodes[k])]
    note = ("%s · AUTOMATE passada %s: merge %s, gasto %d/%d tokens, iniciados %d/%d; mergeados e carimbados pelo forge: %s; "
            "mergeados SEM carimbo (reconciliar): %s; PRs para o lote humano: %s") % (
        rest[0].strip(), p["id"], p["merge"], p["spent"], p["budget"], len(p["tracked"]), p["max_nodes"],
        ", ".join(stamped) or "nenhum", ", ".join(unstamped) or "nenhum", ", ".join(open_prs) or "nenhum")
    new = set_meta_pass(txt, None)
    commit_text(path, txt, new, lambda d: "x_drive_pass" not in meta(d))
    rc, out, err = run(["bash", DRIVE, path, "--close-lot", note])
    if rc != 0:
        write_atomic(path, txt)
        raise Usage("kg-drive-project.sh --close-lot saiu rc=%s (%s) — passada RESTAURADA" % (rc, err.strip()[:200]))
    with contextlib.suppress(OSError):
        os.unlink(_nonce_path(p["id"]))
    say("LOTE-FECHADO\t%s" % note)
    return 0


MUTATING = ("begin", "track", "charge", "merge", "stamp", "end")


def main():
    if not ARGS:
        raise Usage("uso: drive-automate.sh --status | plan|begin|next|track|charge|gate|merge|stamp|end <grafo> …")
    if ARGS[0] == "--status":
        return cmd_status()
    cmd = ARGS[0]
    if len(ARGS) < 2 or not ARGS[1].endswith(".kg.yaml"):
        raise Usage("%s exige o grafo (<arquivo>.kg.yaml) como 2º argumento" % cmd)
    path = os.path.abspath(ARGS[1])
    rest = ARGS[2:]
    table = {"plan": cmd_plan, "begin": cmd_begin, "next": cmd_next, "track": cmd_track,
             "charge": cmd_charge, "gate": cmd_gate, "merge": cmd_merge, "stamp": cmd_stamp, "end": cmd_end}
    if cmd not in table:
        raise Usage("subcomando desconhecido: %s" % cmd)
    # quem escreve o grafo segura a trava pelo comando inteiro (ler-modificar-gravar); o `merge` a segura só na
    # escrita, porque a espera do merge-serial dura horas e não pode travar o `charge` da mesma passada.
    if cmd in MUTATING and cmd != "merge":
        with graph_lock(path):
            return table[cmd](path, rest)
    return table[cmd](path, rest)


try:
    sys.exit(main())
except Halt as h:
    print("PARA — %s" % h)
    sys.exit(1)
except Usage as u:
    print("drive-automate: %s" % u, file=sys.stderr)
    sys.exit(2)
DRIVE_AUTOMATE_PY
