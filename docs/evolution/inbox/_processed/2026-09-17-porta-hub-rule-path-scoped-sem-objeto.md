# Sinal ao core — regra path-scoped vendorizada cujo objeto não viaja reprova o lint da PORTA (HARD)

**Data:** 2026-09-17 · **Repo:** onion-core (porta pública, `role: hub`, pin `7a3504e6b121`, HEAD `d8845c91b21f`)
· **Origem:** `/warm-up` numa sessão limpa da porta · **Severidade:** HARD — `lint-artifacts.sh` sai **exit 1**

A porta materializada **não passa no próprio lint**. Um `/warm-up` seguido de
`bash .claude/validation/lint-artifacts.sh` reprova com 1 HARD + 6 SOFT. Quem clona a porta pelo README
(`git clone … && claude`, depois "As guardas rodam com `bash .claude/validation/lint-artifacts.sh`")
encontra um framework que reprova a si mesmo na primeira execução.

## O achado (HARD)

```
VIOLATION: .claude/rules/research-lens.md: nenhum glob de 'paths:' casa arquivo rastreado
(docs/evolution/research/**) — a regra existe no disco e NUNCA carrega
```

Emitido por `lint-artifacts.sh:1056`.

## A causa: a allowlist separa a regra do seu objeto

| | core (`onion-evolve`) | porta (`onion-core`, `hub`) |
|---|---|---|
| `.claude/rules/research-lens.md` | presente | presente (**byte-idêntica**, `diff -q` confirma) |
| `docs/evolution/research/**` (o objeto do glob) | **140 arquivos rastreados** | **0** — `docs/evolution/` não viaja |
| veredito do lint | carrega, regra útil | **HARD**, regra morta |

`.claude/**` viaja inteiro; `docs/evolution/` é excluído **por desenho** — o próprio
`vendor-manifest.sh:91` declara: *"inbox/inbound são infra LOCAL do alvo; copiar clobaria o que está em uso"*.
As duas decisões estão certas isoladamente. Juntas produzem uma regra que **só pode** reprovar no alvo.

Note que a irmã `kg-grammar.md` sobrevive à projeção por acidente feliz: seu glob `**/*.kg.yaml` casa as
fixtures em `.claude/validation/fixtures/`, que viajam. Não é imunidade de desenho — é sorte do glob.

## Por que isto é classe, não caso

A regra "todo glob de `paths:` casa arquivo rastreado" foi escrita com a fonte em mente, onde a árvore é
completa. Num alvo, a árvore é **a allowlist** — e nada hoje impede uma nova rule path-scoped de apontar
para fora dela. Hoje N=1; a cada rule nova o dado é sorteado de novo. O gatilho não é esta regra: é
**qualquer** rule vendorizada cujo prefixo de glob caia em superfície core-only.

## Três saídas (o core decide; nenhuma é pedido)

1. **Guarda papel-consciente** — a regra isenta quando o prefixo do glob é superfície core-only, declarando
   a isenção em vez de passar calada. Há precedente **no mesmo lint**: `door-staleness-check.sh` já emite
   `[papel/SEM-OBJETO] papel 'hub' não recebe o objeto desta guarda`. Seria o mesmo vocabulário, e mantém a
   regra viva onde ela tem objeto.
2. **A rule não viaja** — excluir `research-lens.md` do manifest vendorizado. Barato, mas perde a lente para
   um adotante que venha a ter `research/` próprio.
3. **Glob que casa objeto que viaja** — reapontar. Provavelmente falso: a lente é sobre pesquisa do core.

A (1) parece a única que não escolhe entre "a regra existe" e "o lint passa", e reusa vocabulário já no lint.

---

## Nota secundária — o carteiro upstream não atende `role: hub`

Descoberto **ao tentar entregar este sinal**, e por isso ele chegou à mão.

```
$ bash .claude/utils/co-evolution/co-relay.sh --target /home/marcio/onion-evolve --dry-run
ERRO: role='hub' no stamp — co-relay é só para ADOTANTE (role: adopted).
EXIT=2
```

O helper **se contradiz**: a mensagem de stamp-ausente (`co-relay.sh:80`) diz *"co-relay roda no ADOTANTE
(role: adopted **ou hub**)"*, mas a condição de papel (`:85`) é `[ "${ROLE}" != "adopted" ]` — `hub` cai no
`exit 2`. Uma das duas está errada; a intenção documentada parece ser aceitar `hub`.

Consequência: a porta — o repo que o público clona, e portanto o que mais gera sinal de primeira impressão —
é a única superfície do doc-bridge **sem** carteiro upstream. Este sinal foi copiado à mão (never-clobber,
**sem commit** — I3 respeitado; a sessão do core commita e tria).

O **espelho downstream já decidiu essa questão no sentido oposto**, e isso resolve a ambiguidade:

- `co-deliver.sh:119` valida o stamp do alvo com `role:[[:space:]]*(adopted|hub)` — **aceita `hub`**.
- `co-deliver.sh:82` só entrega a `hub`/`standalone` (T1/T3, RFC-0003 §2.1).

Ou seja: o core **entrega anúncios à porta** por desenho declarado, mas a porta **não pode responder**. O
doc-bridge está mecanizado em mutirão num sentido só. A assimetria é do `co-relay.sh:85`, não do desenho —
a própria mensagem de erro dele (`:80`) já dizia `adopted ou hub`.

---

**O que a porta NÃO fez, de propósito:** nada foi corrigido aqui. Correção na porta é sobrescrita na próxima
materialização — o README diz isso, e esta sessão obedeceu.
