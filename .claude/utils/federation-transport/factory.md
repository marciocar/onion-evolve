# 🏭 factory — federation-transport

> Instância concreta do padrão **SDAAL**. Instancia o adapter de transporte correto p/ um membro, abstraindo
> a via nos comandos `co-*`. O comando não sabe (nem precisa) se o sinal foi por git-async, carteiro-local ou A2A.

## Divergência de default (declarada — mesmo princípio SDAAL, domínio diferente)

- Task Manager: default `transport='api'` (REST sempre disponível). Forge: default `transport='cli'` (`gh` idiomático).
- **federation-transport: default `git-async`** — é o que **sempre funciona** (git + markdown), tem a **menor
  superfície de ataque** (RFC-0004 §3) e é o **system-of-record** (RFC-0001). As outras vias **aceleram**, não
  substituem. `FEDERATION_TRANSPORT` controla a via; a *spec* (interface) define o quê.

## getTransport(memberId) — resolução

Delega ao detector determinístico **`detect-transport.sh <member-id>`** (não reimplementar o parsing à mão).
Precedência (idioma `resolve-integration-branch.sh` — campo → config → detecção → default):

1. **`FEDERATION_TRANSPORT` explícito** (`git-async|local|a2a-live`) → essa via. Valor inválido → exit 3.
2. **`FEDERATION_TRANSPORT=auto`** → `local` se o `local_path` do membro (`members.yaml`) existe nesta máquina;
   senão `git-async`.
3. **default (unset)** → **`git-async`**.

**`a2a-live` NUNCA é auto-selecionado** (gated): só no caso 1 explícito, e o detector **avisa que é stub**
(RFC-0004 fase-2 — sem canal vivo até o F2.2). Fail-safe: qualquer ambiguidade → git-async (nunca "sobe" p/
uma via mais poderosa por conta própria).

```bash
VIA="$(bash .claude/utils/federation-transport/detect-transport.sh "$MEMBER")"
# → carrega adapters/${VIA}.md e executa deliver/receive conforme o contrato (interface.md)
```

## Fallback gracioso

Via resolvida indisponível em runtime (ex.: `local` mas o clone sumiu; `a2a-live` mas o bridge está down) →
**degradar p/ `git-async`** (o fallback universal) + avisar o maestro. Nunca falhar a co-evolução por
indisponibilidade de uma via de aceleração.
