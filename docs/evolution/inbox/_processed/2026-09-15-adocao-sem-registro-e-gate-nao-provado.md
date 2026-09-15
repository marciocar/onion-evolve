---
title: 'Adoção entregue sem registro de federação; relatório afirma gate provado contra nó open'
date: 2026-09-15
from: venda-direta-pdi-entrega (consumidor)
to: core (onion-evolve)
type: flow-b-signal
flow: upstream (consumidor→core / sinal de campo)
source_commit: df031ef53683
severity: 1 bug de processo + 1 divergência de geração
---

# Sinal de campo — adoção `df031ef53683` em `venda-direta-pdi-entrega`

Dois achados da primeira sessão pós-adoção deste repo (`/warm-up` + `/meta:co-evolve`). O primeiro é um
**bug de processo com falha silenciosa**; o segundo é uma **divergência entre o texto gerado e o grafo**.

---

## Achado 1 — adoção entregue, membro nunca registrado (falha silenciosa)

**O que se observou.** Este repo foi adotado em 2026-09-15 (pin `df031ef53683`, modo greenfield) e o
relatório de adoção chegou ao `inbound/` pelo carteiro. Mas **nenhuma entrada do `members.yaml` do core
aponta para `/home/marcio/venda-direta-pdi-entrega`**.

Medição (a partir deste repo, leitura no core):

```
grep -n 'venda-direta-pdi-entrega' docs/evolution/federation/members.yaml
  >>> nenhuma ocorrência
grep -n 'local_path:' docs/evolution/federation/members.yaml
  >>> 16 entradas, nenhuma para este path
```

O membro de nome mais próximo — `poc-venda-direta-pdi` (linha 348) — é **outro repo**: `local_path:
/home/marcio/mvp-venda-direta-pdi`, pin `219e9a5f365b`, adotado 2026-08-17. Confirmado com o maestro:
**este repo é um membro NOVO e independente**, não sucessão do `mvp`.

**Por que é grave, e por que nenhum gate acusa.** Sem entrada no `members.yaml`:

- o core não tem `local_path` para resolver o `--target` do `/meta:co-deliver` → anúncios futuros do
  CHANGELOG **não têm destinatário**;
- a reconciliação `outbox×inbound` do `/meta:co-evolve` (Passo 2.1) **nunca acusa nada**, porque ela cruza
  `outbox/<id>/_processed/` contra o `inbound/` do adotante — e não existe `outbox/` para um membro que não
  existe. O `comm -13` compara dois conjuntos vazios e sai limpo;
- o hook `you-have-mail` deste repo continua verde, porque ele conta o que **chegou**, não o que **deveria
  ter chegado**.

Ou seja: a lição de campo 2026-07-21 (7 anúncios no checkout errado) tem uma **irmã não coberta** — o
anúncio que não vai para checkout nenhum. O cruzamento existente detecta *entrega no alvo errado*; não
detecta *membro ausente do registro*.

**O que este sinal PEDE (é pedido, não instrução — a triagem é do core):**

1. `/meta:federation-register` deste repo como membro novo, `local_path:
   /home/marcio/venda-direta-pdi-entrega`, `kind: adopter`, `role: standalone`, pin `df031ef53683`,
   `adopted_at: 2026-09-15`, `mode: greenfield`. Nota de confidencialidade: pela proximidade com
   `poc-venda-direta-pdi` (cliente sob NDA), avaliar se o `name`/`personality_summary` precisa do mesmo
   tratamento de **nome neutro** que aquela entrada documenta nas linhas 349-354.
2. Considerar fechar o buraco na origem: fazer o `/meta:adopt` **registrar o membro como parte da adoção**,
   ou ao menos emitir aviso quando adota sem registrar. Instalar e registrar hoje são passos independentes,
   e o segundo é esquecível sem consequência visível — que é a definição de falha silenciosa.
3. Considerar uma guarda que cruze **adotantes conhecidos no disco × `members.yaml`** (todo repo com
   `.claude/.onion-version` de `role: adopted` sob `/home/marcio/` deveria ter entrada). Hoje o registro é
   afirmado, nunca verificado.

---

## Achado 2 — o relatório de adoção afirma prova que o grafo registra como pendente

**O que se observou.** O relatório gerado (`inbound/2026-09-15-adopt-df031ef53683.md`, seção "Gate local")
afirma, textualmente:

> Provisionado por `core.hooksPath` nativo e **provado vivo por execução** (o hook rodou num commit-sonda).
> Na hora da instalação a prova ficou **adiada** — o repo ainda não tinha `HEAD` — e o grafo registrou isso
> honestamente como `open`; depois do primeiro commit a prova passou.

Mas o nó `DETERMINISTIC_GATE` em `docs/onion/graph/onion-adoption.kg.yaml` segue **`open`**, com atenção
13.5 no radar, e o texto dele pede exatamente o oposto do que o relatório declara:

> Instalar não é sinônimo de proteger: rode `bash ops/verify-adopter-gate.sh <este-repo>` a partir do core,
> ou faça um commit que viole o lint de propósito e confirme que ele é BARRADO.

**Medição contra o vivo (drive-to-verify):**

```
git config core.hooksPath          → .githooks
.githooks/pre-commit               → presente, executável (2590 bytes)
bash .githooks/pre-commit </dev/null; echo $?
                                   → 0   (0 violações HARD, 8 SOFT)
```

O gate **executa**. Ninguém verificou que ele **reprova**. São afirmações diferentes, e é a segunda que o
nó exige: um gate que roda e sempre passa é indistinguível de um gate quebrado até o dia em que precisa
barrar algo.

**Leitura.** O grafo está certo em seguir `open`; quem se adiantou foi a prosa do relatório. O parágrafo
narra uma prova ("depois do primeiro commit a prova passou") que confunde *o hook disparou* com *o hook
reprovou* — e ainda elogia a honestidade do grafo (`registrou isso honestamente como open`) no mesmo
parágrafo em que a contradiz.

**O que este sinal PEDE:** que a seção "Gate local" do gerador do relatório **derive do nó do KG** em vez de
afirmar por conta própria. Enquanto `DETERMINISTIC_GATE` for `open`, o texto deve dizer *instalado, prova
pendente* e repetir o comando de prova — não declarar prova passada. A regra geral: o relatório é projeção
do grafo; onde ele afirma além do grafo, é o relatório que está errado.

---

## Contexto deste repo (para a triagem)

- Papel `adopted`, greenfield, 1 commit (`a8be356`), branches `onion/adopt` e `onion/vendor`.
- **Sem remote configurado** (`git remote -v` vazio) — o próximo passo nº 2 do relatório recebido ("PR para
  a sua branch de integração") não tem forge para onde ir. Não é bug do core; é estado do repo, registrado
  aqui porque afeta que conselhos fazem sentido num adotante recém-nascido.
- Sem código de produto ainda (`scripts/` e `tests/fixtures/` vazios). A `question` de domínio do KG
  (`Q_WHAT_IS_THIS_REPO_DOMAIN`) segue aberta, como esperado.
