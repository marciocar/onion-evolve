---
title: "Sinal técnico — o MCP assistente-pdi não está enforçando auth (X-Api-Key)"
date: 2026-08-22
from: onion-evolve (core / maestro principal)
to: poc-venda-direta-pdi (adotante de campo — PoC)
re: AUTENTICACAO_DO_MCP_PENDENTE (item de backlog com dono "Onion Core")
type: downstream-announce
classe: COORDENAÇÃO — ação recomendada (segurança/defesa-em-profundidade)
status: transportado ao inbound/ da PoC (2026-08-22; commit no repo da PoC pendente do lado deles)
---

# 🔐 Sinal técnico — o MCP `assistente-pdi` não enforça auth

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. O core não roda nada no repo
> de vocês (I3). Este sinal corrige a premissa do item `AUTENTICACAO_DO_MCP_PENDENTE`: medi o
> comportamento do server antes de fechar o lado do core, e o resultado move parte da bola para o lado
> de vocês.

## 1. O que medi (comportamento, não declaração)

Antes de adicionar os `headers` no `librechat.yaml` do core, verifiquei o teu MCP por comportamento:

```
curl -s -X POST http://172.23.0.1:3031/mcp \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
→ HTTP 200 + a lista COMPLETA de tools (ingerir_caso, …), SEM nenhum X-Api-Key
```

Ou seja: o `pdi-mcp.service` (ativo, `172.23.0.1:3031`) **responde a qualquer chamada sem chave** — ele
**não está enforçando** o token. O item dizia "meu lado está pronto (PDI_MCP_TOKEN na unit)", mas o
comportamento não bate: **`PDI_MCP_TOKEN` na unit é necessário, mas não suficiente** — o *server*
precisa ler esse token e conferir o header, fail-closed.

## 2. O fix é do lado de vocês (I3) — e é pequeno

Espelha o que os MCPs do core (`onion-kg`/`onion-exec`/`onion-framework`) já fazem:

```python
import hmac, os
TOKEN = os.environ.get('PDI_MCP_TOKEN', '')
if not TOKEN:
    raise SystemExit('PDI_MCP_TOKEN ausente — fail-closed, não subo sem auth')
# no handler HTTP, ANTES de responder qualquer método:
if not hmac.compare_digest(self.headers.get('X-Api-Key', ''), TOKEN):
    return self._json({'jsonrpc':'2.0','id':None,
        'error':{'code':-32001,'message':'unauthorized'}}, code=401)
```

**Prova de que fechou** (o teste que vale): o mesmo `curl` sem chave deve devolver **401**, não 200.

> ⚠️ Hoje o bind é `172.23.0.1` (rede docker, **não** público) — então não há exposição à internet.
> Mas qualquer container nessa rede chama o teu MCP sem auth; a defesa-em-profundidade só liga quando o
> server enforça. `hmac.compare_digest` (não `==`) evita timing-attack no header.

## 3. O handoff — a cadeia fecha em três passos

1. **(vocês)** server enforça → `curl` sem chave devolve **401**.
2. **(handoff)** o **valor** do `PDI_MCP_TOKEN` chega ao `.env` do core (canal seguro; o core é o
   *cliente* que precisa mandar a chave). Me passem o token, ou confirmem que posso lê-lo da unit.
3. **(core)** eu costuro `headers: X-Api-Key: ${LIBRECHAT_PDI_MCP_TOKEN}` no bloco `assistente-pdi` do
   `librechat.yaml` — trivial, no mesmo movimento.

O item sai do backlog quando os três caírem. Enquanto o passo 1 não fechar, adicionar os `headers` no
core só mandaria uma chave que o server ignora — por isso não fiz ainda.

## Ação esperada no adotante
- Aplicar o fail-closed no `mcp_server.py` da PoC (passo 1) e provar com o `curl` → 401.
- Combinar o handoff do token (passo 2) com o core.
- Tratado → mover este arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** revise e copie para o `inbound/` da PoC:
> `cp docs/evolution/federation/outbox/poc-venda-direta-pdi/2026-08-22-mcp-auth-enforcement.md /home/marcio/poc-venda-direta-pdi/docs/evolution/inbound/`
> e commite **no repo da PoC** (a sessão do core não pusha repo alheio — I3).
