# 🏷️ types — federation-transport

> Tipos base da abstração de transporte de co-evolução (SDAAL). Consumidos por `interface.md`/`factory.md`.

```typescript
/** As três vias de transporte. */
type TransportKind =
  | 'git-async'   // default — doc-bridge (CHANGELOG + outbox + entrega-sem-commit); assíncrono, maestro transporta
  | 'local'       // carteiro same-machine (co-deliver/co-relay) — untracked no repo vizinho
  | 'a2a-live';   // 🔒 gated (RFC-0004 fase-2, stub) — endpoint A2A SSE+webhook sobre o onion-bridge

/** Valor de FEDERATION_TRANSPORT (.env). 'auto' resolve local-se-same-machine, senão git-async. */
type TransportConfig = TransportKind | 'auto';   // default (unset) = 'git-async'

/** Disponibilidade de uma via p/ um par (core, membro) — o detector computa. */
interface TransportAvailability {
  kind: TransportKind;
  available: boolean;      // git-async: sempre; local: same-machine (local_path existe); a2a-live: gated+bridge up
  reason: string;
}
```

## Semântica

- **`git-async`** — sempre disponível (é git + markdown). Menor superfície de ataque → **default** (RFC-0004 §3).
- **`local`** — disponível quando o `local_path` do membro (`members.yaml`) existe nesta máquina. Acelera a
  frota local sem rede. Reusa `co-deliver.sh`/`co-relay.sh` (entrega-sem-commit).
- **`a2a-live`** — **nunca auto-selecionado**. Só via `FEDERATION_TRANSPORT=a2a-live` explícito, e mesmo assim
  o adapter é **stub gated** até o F2.2 (endpoint no bridge + validação anti-replay/SSRF + gate humano).

`Classification` (o que pode viajar por via) reusa `trust/types.md` (private→collective) — a via não amplia
visibilidade; a política de trust decide **o quê**, o transporte decide **por onde**.
