"""Extrai, com o LEITOR do próprio Mistral Vibe, o registro de cada sessão de uma raiz de sessões.

Emenda R2-3 (PRE-REGISTRO-R2.md). Roda com o Python do ambiente do Vibe (o executável `vibe` não
é chamado); só LÊ o store:
  - `UnifiedSessionStore(root, session_id).load()` (mistralai_vibe_local_harness/vibe/_storage.py:2271
    e :2491), o mesmo leitor que o cliente usa para o filho (_host.py:2113);
  - `checkpoint_messages(stored.checkpoint)` (_storage.py:3854-3862), a transcrição do modelo, onde a
    mensagem `role: "tool"` traz `tool_call_id`, `name`, `outcome` e `content` (protocol.py:814-820);
  - a projeção pública (`stored.projection_state`, _storage.py:1049-1054), despejada inteira em JSON,
    de onde o classify tira os efeitos.

Uso: <python do Vibe> vibe_store_extract.py <raiz: $VIBE_HOME/logs/session> <saída.json>
Saída: {"root_exists": bool, "sessions": [{"session_id", "ok", "error", "projection", "messages"}]}.
Uma sessão que não carrega fica com ok=false e o erro; nunca derruba as outras.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def extract(root: Path) -> dict:
    out: dict = {"root_exists": root.is_dir(), "sessions": []}
    unified = root / "unified"
    if not unified.is_dir():
        return out
    from mistralai_vibe_local_harness.vibe._storage import UnifiedSessionStore, checkpoint_messages

    for d in sorted(p for p in unified.iterdir() if p.is_dir()):
        rec: dict = {"session_id": d.name, "ok": False, "error": None, "projection": None, "messages": None}
        try:
            stored = UnifiedSessionStore(root, d.name).load()
            rec["projection"] = stored.projection_state.model_dump(mode="json", by_alias=True)
            rec["messages"] = checkpoint_messages(stored.checkpoint)
            rec["ok"] = True
        except Exception as e:  # noqa: BLE001 - o erro de uma sessão vira dado, não queda
            rec["error"] = f"{type(e).__name__}: {e}"
        out["sessions"].append(rec)
    return out


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: vibe_store_extract.py <session-root> <out.json>", file=sys.stderr)
        return 64
    data = extract(Path(sys.argv[1]))
    Path(sys.argv[2]).write_text(json.dumps(data, ensure_ascii=False, default=str))
    return 0


if __name__ == "__main__":
    sys.exit(main())
