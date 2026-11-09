"""Leitor único do canal de sessão (a campainha) no `.mcp.json` de um repo.

Três verbos, sempre com `--repo <raiz>`:
  server   imprime o nome do servidor de canal. rc 0 achou, 3 não há, 2 `.mcp.json` inválido ou ilegível.
  notice   lê o JSON do SessionStart no stdin e imprime a linha de aviso, se a sessão abriu sem o canal.
  pending  imprime "<campainha> <fila>" se há sinal pendente numa sessão sem canal; nada quando zero.

O Claude Code não tem chave de settings nem variável para ligar canal: é `--channels` ou
`--dangerously-load-development-channels` por sessão, e sem a flag o push é descartado em silêncio. Daí o aviso,
que lê o cmdline do processo pai. `notice` e `pending` erram para o lado de CALAR: o que não se mede não vira
afirmação, e rc é sempre 0. `pending` só devolve contagens: nem caminho nem título do sinal saem daqui.
"""
import hashlib
import json
import os
import re
import sqlite3
import sys

# O nome é o que vai na flag (`server:<nome>`). A capacidade `claude/channel` só aparece no handshake do MCP, e um
# hook não o faz; por isso a lista é por nome, e canal novo entra aqui.
CHANNEL_SERVERS = ("doorbell",)
CHANNEL_FLAGS = ("--channels", "--dangerously-load-development-channels")
OPENER = ".claude/utils/co-evolution/open-channel-session.sh"
MAX_ANCESTORS = 16
QUEUE_INBOX = "inbox"  # queue/onion_queue/daemon.py, INBOX


class Invalid(Exception):
    pass


def channel_server(repo):
    """(nome, entrada) do servidor de canal; (None, None) sem servidor; Invalid se o arquivo não se lê."""
    path = os.path.join(repo, ".mcp.json")
    if not os.path.isfile(path):
        return None, None
    try:
        with open(path, encoding="utf-8") as fh:
            servers = json.load(fh)["mcpServers"]
        names = list(servers)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        raise Invalid(type(exc).__name__)
    for name in CHANNEL_SERVERS:
        if name in names and isinstance(servers[name], dict):
            return name, servers[name]
    return None, None


def own_args(argv):
    """Corta o interpretador da frente (node <cli.js> ...), para argv[0] ser sempre o próprio claude."""
    for i, arg in enumerate(argv):
        if os.path.basename(arg) == "claude" or re.search(r"/cli\.[cm]?js$", arg):
            return argv[i:]
    return argv


def ancestors_claude():
    """argv do processo Claude Code mais próximo, ou None se não der para medir.

    Sobe só pela cadeia de ancestrais do próprio hook e para em dono diferente: nenhum processo alheio é lido.
    """
    me = os.getuid()
    declared = os.environ.get("CLAUDE_PID", "")
    pid = os.getppid()
    try:
        for _ in range(MAX_ANCESTORS):
            if pid <= 1 or os.stat(f"/proc/{pid}").st_uid != me:
                return None
            with open(f"/proc/{pid}/stat", encoding="utf-8", errors="replace") as fh:
                stat = fh.read()
            with open(f"/proc/{pid}/cmdline", "rb") as fh:
                argv = [a.decode("utf-8", "replace") for a in fh.read().split(b"\0") if a]
            comm = stat[stat.index("(") + 1 : stat.rindex(")")]
            is_node = comm in ("node", "bun") and any(re.search(r"claude|/cli\.[cm]?js$", a) for a in argv[1:2])
            if comm == "claude" or str(pid) == declared or is_node:
                return own_args(argv)
            pid = int(stat[stat.rindex(")") + 2 :].split()[1])
    except (OSError, ValueError, IndexError):
        return None
    return None


def interactive(argv):
    """Só a sessão de terminal do usuário pode reabrir com a flag."""
    if os.environ.get("CLAUDE_CODE_ENTRYPOINT", "cli") != "cli":
        return False
    args = argv[1:]
    if args and (args[0] == "daemon" or args[0].startswith(("bg-", "--bg"))):
        return False
    return not any(a == "--print" or a.startswith("--print=") or re.fullmatch(r"-[A-Za-z]*p[A-Za-z]*", a) for a in args)


def has_channel(argv, name):
    args = argv[1:]
    for i, arg in enumerate(args):
        if arg in CHANNEL_FLAGS:
            for value in args[i + 1 :]:
                if value.startswith("-"):
                    break
                if f"server:{name}" in re.split(r"[,\s]+", value):
                    return True
        else:
            for flag in CHANNEL_FLAGS:
                if arg.startswith(flag + "=") and f"server:{name}" in re.split(r"[,\s]+", arg.split("=", 1)[1]):
                    return True
    return False


def notice(repo):
    try:
        name, _ = channel_server(repo)
    except Invalid:
        return
    if not name or sys.stdin.isatty():
        return
    try:
        payload = json.loads(sys.stdin.read())
    except ValueError:
        return
    if not isinstance(payload, dict):
        return
    source = payload.get("source")
    if source not in ("startup", "resume"):  # /clear e compactação seguem no mesmo processo: já avisou
        return
    argv = ancestors_claude()
    if argv is None or not interactive(argv) or has_channel(argv, name):
        return
    line = f"bash {OPENER}"
    session = payload.get("session_id")
    if source == "resume" and isinstance(session, str) and re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]*", session):
        line += f" --resume {session}"
    print(f"🔔 Esta sessão abriu sem o canal da campainha ({name}): os avisos de outras sessões são descartados. "
          f"Para reabrir com o canal, saia e rode na raiz do repo: {line}")


def server_env(entry, name, legacy):
    env = entry.get("env")
    if not isinstance(env, dict):
        return None
    # A mesma regra do server.ts: vazio conta como ausente, e o nome novo vence o antigo.
    return env.get(f"DOORBELL_{name}") or env.get(legacy) or None


def counts(signal, repo):
    """Sinal que ainda pede atenção. O expirado esgotou os avisos e sairia em todo prompt; o `pending_signals` segue
    listando. O arquivo que saiu é estado morto: sem campainha rodando, ninguém o tiraria da lista."""
    if not isinstance(signal, dict) or signal.get("acked_at") or signal.get("expired_at"):
        return False
    path = signal.get("path")
    return (isinstance(path, str) and path.startswith(("docs/evolution/inbox/", "docs/evolution/inbound/"))
            and os.path.isfile(os.path.join(repo, path)))


def doorbell_pending(repo, entry):
    target = os.path.abspath(server_env(entry, "REPO", "CAMPAINHA_REPO") or repo)  # legacy-name
    digest = hashlib.sha256(target.encode()).hexdigest()[:16]
    names = (f"{digest}.v2.json", f"{digest}.json")
    xdg = os.environ.get("XDG_STATE_HOME") or os.path.join(os.path.expanduser("~"), ".local", "state")
    current, legacy = os.path.join(xdg, "onion-doorbell"), os.path.join(xdg, "onion-campainha")  # legacy-name
    has = lambda d: any(os.path.exists(os.path.join(d, n)) for n in names)
    root = server_env(entry, "STATE_DIR", "CAMPAINHA_STATE_DIR") or (  # legacy-name
        legacy if not has(current) and has(legacy) else current
    )
    for name in names:
        try:
            with open(os.path.join(root, name), encoding="utf-8") as fh:
                state = json.load(fh)
        except (OSError, ValueError):
            continue
        if isinstance(state, dict) and state.get("repo") == target and isinstance(state.get("signals"), dict):
            return sum(1 for s in state["signals"].values() if counts(s, target))
    return 0


def queue_pending(entry):
    sock = server_env(entry, "QUEUE_SOCK", "CAMPAINHA_FILA_SOCK")  # legacy-name
    if not sock:
        return 0
    db = os.path.splitext(os.path.abspath(sock))[0] + ".db"  # o daemon nomeia o par pelo mesmo radical
    if not os.path.isfile(db):
        return 0
    try:
        conn = sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=0.05)
        try:
            return int(conn.execute("SELECT COUNT(*) FROM _honker_live WHERE queue=?", (QUEUE_INBOX,)).fetchone()[0])
        finally:
            conn.close()
    except sqlite3.Error:
        return 0


def pending(repo):
    try:
        name, entry = channel_server(repo)
    except Invalid:
        return
    if not entry:
        return
    argv = ancestors_claude()  # com canal a campainha já toca; processo que não se mede fica em silêncio
    if argv is None or has_channel(argv, name):
        return
    bell, queue = doorbell_pending(repo, entry), queue_pending(entry)
    if bell + queue > 0:
        print(bell, queue)


def main():
    if len(sys.argv) != 4 or sys.argv[2] != "--repo" or sys.argv[1] not in ("server", "notice", "pending"):
        print("usage: channel-session.py server|notice|pending --repo <root>", file=sys.stderr)
        return 2
    verb, repo = sys.argv[1], sys.argv[3]
    if verb == "server":
        try:
            name, _ = channel_server(repo)
        except Invalid as exc:
            print(f".mcp.json inválido: {exc}", file=sys.stderr)
            return 2
        if not name:
            return 3
        print(name)
        return 0
    try:
        (notice if verb == "notice" else pending)(repo)
    except Exception as exc:  # hook nunca derruba sessão nem afirma o que não mediu
        print(f"channel-session {verb}: {type(exc).__name__}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
