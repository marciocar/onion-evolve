# 🔐 trust — abstração SDAAL de confiança (eixo = **tier**, não provider)

Abstração **SDAAL** que resolve **o que a instância local pode fazer** em relação a outra instância da
federação. O consumidor chama `getTrustManager()` e a interface; **nunca** ramifica por tier na prosa.

**Formato: SDAAL-papel** ([abstraction-doctrine](../../../docs/knowledge-base/concepts/onion-abstraction-doctrine.md)) —
o eixo do adapter é um **papel/tier interno** (RFC-0003 §2.5), não um provider externo trocável. A
anatomia do contrato é a mesma; o que muda é o eixo.

## Adapters (tiers)

| Adapter | Tier | Papel |
|---|---|---|
| `source.md` | **T0** | o core — origem do framework |
| `hub.md` | **T1** | hub de linhagem (ex.: um adotante multi-linhagem) |
| `consumer.md` | **T2** | adotante downstream |
| `standalone.md` | **T3** | instância isolada — **sem federação** |

- **Interface:** [`interface.md`](interface.md) (`ITrustManager`) · **Tipos:** [`types.md`](types.md)
- **Factory:** [`factory.md`](factory.md) · **Detecção:** [`detector.md`](detector.md)

## Dispensa declarada — por que não há `adapters/none.md`

A doutrina exige o **Null Object** (`none`) como fallback funcional, e exige que qualquer dispensa seja
**declarada, não silenciosa** (precedente: a divergência `cli`-default do forge, `integrations.md` §1.0).

Aqui a dispensa é deliberada: **`standalone` (T3) já É o Null Object deste eixo.** Ele é o fallback
total e funcional — instância sem federação, sem peers, sem trust externo. Um `none.md` seria um
segundo nome para o mesmo comportamento, e "sem tier" não existe: toda instância **tem** um tier, nem
que seja o isolado.

Diferente do task-manager, onde `none` significa *"não há provider"* (um estado real e distinto de
`jira`/`clickup`), aqui não há o estado "não há tier" — só há "o tier é o isolado".

## Fallback gracioso

Tier indetectável → assumir **`standalone`** (o mais restritivo). **Nunca** assumir `source`/`hub` por
omissão: errar para menos privilégio é seguro; errar para mais, não.
