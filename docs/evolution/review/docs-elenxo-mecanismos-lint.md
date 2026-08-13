---
branch: docs/elenxo-mecanismos-lint
pr: 588
date: 2026-08-13
reviewed_diff_sha256: 01ef2bfbad7fb5bb1c796066742264285a0e91ba5a918b5604af73684a7c72e2
findings_total: 27
findings_real: 27
findings_fixed: 24
tokens: 665726
duration_min: 30
verdict: CORRIGIDO-E-RE-REVISADO
reviewer: 4 lentes sonnet/high (diagnóstico) + code-reviewer opus (patch), adversariais
---

# Passada adversarial — `docs/elenxo-mecanismos-lint`

## Estrutura da revisão — dois Elenxos, papéis distintos

**1º Elenxo (diagnóstico):** 4 lentes `sonnet`/`high` em paralelo, sem se verem, com perguntas
diferentes — custo do `--only`, anatomia da bancada, sobreposição do parque de 47 scripts,
arqueologia da regressão 16s→86s. **19 achados**, 241 tool-calls, e o sinal de robustez: as quatro
convergiram no mesmo vilão (`check_plugins_sync`) por caminhos independentes.

**2º Elenxo (o patch):** 1 revisor `opus` atacando **a cura**, com instrução explícita de atacar o
que não fora provado. **8 achados**, e três derrubaram a v1.

## Achados do 2º Elenxo sobre a cura (o que este resíduo existe para registrar)

| # | sev | achado | status |
|---|---|---|---|
| A1 | **ALTA** | gate por prefixo deixava **108 paths de fonte bundlada** fora — drift em comando bundlado via `--only` engolia 2 HARD | corrigido (pertencimento ao manifesto, `grep -qF`) |
| A2 | MÉDIA | rename/delete de `work_tool` invisível à R37 | corrigido (`commands/meta/` no gate) |
| A3 | MÉDIA-ALTA | `--only` absoluto não-canônico (`/./`, `//`) **desligava a R20 inteira** — filtro era string-compare | corrigido (**inode-compare `-ef`**) |
| A4 | MÉDIA | `cd` da normalização = morte-silenciosa sob `set -e` (classe documentada 4× no próprio arquivo) | corrigido (o `-ef` elimina o `cd`) |
| A5 | BAIXA-MÉDIA | o patch refutava o nó "piso irredutível" da refinaria **sem reconciliar o grafo** | corrigido (superseded nos dois lados) |
| A6 | BAIXA | "nenhuma violação perdida" generalizava dois cenários | corrigido (label qualificado) |
| A7 | BAIXA | cosméticos (`61%%`, `wf_` em .sh vendorizado, ordem dos gates) | corrigidos |
| A8 | MÉDIA | gates sem catraca no selftest | corrigido (**2 casos novos**) |

**Não corrigidos, por escopo declarado** (vivem no grafo com dono): P3 (`sha1sum` em lote), P4
(hook declara 44s), P5 (6 scripts sem consumidor — decisão do maestro). E o achado adjacente
pré-existente do revisor (assemble falho mata o lint rc=2 sem violation) fica nomeado para PR
próprio — não é desta cura.

## A catraca pagou no primeiro uso

O caso "drift em fonte bundlada" **falhou na bancada** — não porque o gate regrediu, mas porque o
sandbox não copia `plugins/`: lá a R19 acusa **"plugin ausente"**, não "fora de sincronia". A
guarda rodou nos dois ambientes; o **assert** conhecia uma só das duas formas da prova de vida.
`bancada-espelha-o-runner` na direção inversa — e o assert agora aceita as duas, com o porquê
comentado no próprio caso.

## Verificação final

- `--only`: **4,9–5,2s** em 3 rodadas (baseline 15,1–16,4s no mesmo ambiente)
- bancada: **800/0/0** (798 + 2 da catraca), duas vezes — na mão e no pre-commit hook
- os 3 repros do 2º Elenxo re-provados um a um após a cura final
- `kg-radar --integrity` exit 0 nos dois grafos tocados (o desta análise e o da refinaria)
- lint completo: 0 HARD, veredito idêntico ao baseline

## Teto declarado

A bancada A/B (1487,6→1227,8s) foi medida **uma vez em cada estado** no mesmo ambiente — não é
média de N rodadas; a variância da VPS sob carga de sessão não foi caracterizada. O ganho por
invocação do `--only` (3 rodadas em cada estado) é o número mais confiável. E três asserts de
edição falharam durante a reconciliação de grafos — cada falha derrubou uma suposição minha
(id inexistente, duplicata imaginada, indentação lida de output formatado); os erros não chegaram
aos arquivos precisamente porque os scripts morriam no assert em vez de aplicar em cima de
suposição.
