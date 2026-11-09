# Lê o estado da campainha (servidor doorbell, repo onion-messaging) e diz o que ficou sem ack.
#
# O estado mora FORA do repo, um arquivo por repo: <XDG_STATE_HOME>/onion-doorbell/<sha256(repo)[:16]>.v2.json.
# A resolução aqui é a do doorbell/server.ts: DOORBELL_STATE_DIR; senão a pasta antiga, só quando ela tem o
# estado e a nova não; dentro dela, o .v2.json antes do .json. Medido em 2026-11-09: o estado deste repo, nesta
# máquina, ainda estava na pasta antiga e no .json.
#
# Saída: 1ª linha `state=<read|absent|unreadable> expired=N held=N unacked=N`; com --list, depois dela uma linha
# por sinal `<expired|held>\t<iso>\t<path>`. Sempre exit 0: quem chama é hook de início de sessão e radar.
# "Não processado" segue sendo o arquivo na caixa. O sinal cujo arquivo já saiu não conta: a campainha só o
# apaga do estado na próxima varredura, e sem ela rodando o estado envelhece.
import hashlib
import json
import os
import re
import sys

SAFE_PATH = re.compile(r"^[A-Za-z0-9._/-]+$")  # o alfabeto do doorbell; caminho fora dele não é impresso
CURRENT_DIR = "onion-doorbell"
OLD_DIR = "onion-campainha"


def candidates(repo):
    digest = hashlib.sha256(repo.encode("utf-8")).hexdigest()[:16]
    names = (digest + ".v2.json", digest + ".json")
    xdg = os.environ.get("XDG_STATE_HOME") or os.path.join(os.path.expanduser("~"), ".local", "state")
    explicit = os.environ.get("DOORBELL_STATE_DIR")
    if explicit:
        root = explicit
    else:
        has = lambda d: any(os.path.exists(os.path.join(xdg, d, n)) for n in names)
        root = os.path.join(xdg, OLD_DIR if not has(CURRENT_DIR) and has(OLD_DIR) else CURRENT_DIR)
    return [os.path.join(root, n) for n in names]


def load(repo):
    broken = False
    for path in candidates(repo):
        if not os.path.exists(path):
            continue
        try:
            with open(path, encoding="utf-8") as handle:
                state = json.load(handle)
        except (OSError, ValueError):
            broken = True
            continue
        if isinstance(state, dict) and state.get("repo") == repo and isinstance(state.get("signals"), dict):
            return "read", state["signals"]
        broken = True
    return ("unreadable" if broken else "absent"), {}


def main(argv):
    repo = os.path.abspath(argv[argv.index("--repo") + 1])
    status, signals = load(repo)
    expired, held, unacked = [], [], 0
    for sig in signals.values():
        if not isinstance(sig, dict) or sig.get("acked_at"):
            continue
        rel = sig.get("path")
        if not isinstance(rel, str) or not SAFE_PATH.match(rel) or ".." in rel.split("/"):
            rel = "<nome inseguro>"
        elif not os.path.isfile(os.path.join(repo, rel)):
            continue
        unacked += 1
        if sig.get("expired_at"):
            expired.append((str(sig["expired_at"]), rel))
        elif sig.get("held"):
            held.append((str(sig.get("first_seen", "")), rel))
    print(f"state={status} expired={len(expired)} held={len(held)} unacked={unacked}")
    if "--list" in argv:
        for label, rows in (("expired", expired), ("held", held)):
            for when, rel in sorted(rows):
                print(f"{label}\t{when if SAFE_PATH.match(when.replace(':', '')) else '?'}\t{rel}")


if __name__ == "__main__":
    try:
        main(sys.argv)
    except Exception:  # hook e radar nunca morrem por causa deste leitor
        print("state=unreadable expired=0 held=0 unacked=0")
    sys.exit(0)
