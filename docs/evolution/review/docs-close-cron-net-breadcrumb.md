---
branch: docs/close-cron-net-breadcrumb
pr: 631
date: 2026-08-18
reviewed_diff_sha256: 77d593d5cb1926c71ad246ba228808fd420db7aa974a32f90946ea445b88b25e
findings_total: 4
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 15
verdict: CONFORME-COM-UM-ACHADO-DE-TITULO-STALE-CURADO
reviewer: passada adversarial manual (3 ataques dirigidos) + medição contra o vivo; sem subagentes por restrição da sessão
REVISOU: true
---

# Resíduo — `docs/close-cron-net-breadcrumb`

**Origem:** o maestro pediu para eu avisar quando o cron terminasse. Ao medir, ele **tinha
disparado** — e a migalha que prescrevia essa exata verificação (`next_recommended`, `review_after`
de hoje) precisava ser **fechada**, não só reportada. Colher é parte da cura.

## Limite do método, declarado antes dos achados

Passada **manual** (3 ataques dirigidos), não orquestrada — restrição da sessão quanto a subagentes.
Diff pequeno (1 arquivo de diário + índice), mas o histórico recente desta casa é claro: **na semana
passada a minha passada manual perdeu 3 defeitos que o revisor do CI achou**. Trato o veredito abaixo
como hipótese até o CI opinar.

## Achado 1 — o título da migalha ficou afirmando algo falso (REAL, curado)

Ao anexar a seção de re-teste, atualizei frontmatter e `significance`, mas a **H1** seguia:
*"O cron que justifica o filtro — e que **ainda não provou existir**"*. Como enunciado isolado — e
título é exatamente o que se lê isolado, ao varrer o diário — passou a ser **falso**.

**Curado pelo padrão que este próprio ciclo já usou** no rascunho graduado: prefixo de estado, sem
apagar o enunciado original (`[FECHADO em 2026-08-18 — o cron disparou] O cron que justifica o filtro
— e que ainda não provou existir`). *Aufhebung*: cancela, **preserva**, eleva. Reescrever a H1 como se
ela nunca tivesse duvidado apagaria justamente a dúvida que o relógio de 1 dia existia para resolver.

## Os três ataques que não acharam nada (e por isso valem)

**(a) Li o log do run certo?** Sim, e a confusão era plausível: dois runs da mesma suíte em menos de
5h. O medido é `32100701318` (`event=schedule`, 04:52Z); o da véspera era `32085963821`
(`workflow_dispatch`, 00:49Z). Ids distintos, evento distinto, confirmado por `gh run view --json`.

**(b) O corpo da migalha ficou contraditório?** Não. Toda a prosa original é narrativa **datada**
(*"O que foi feito (2026-08-17, PR #625)"*), então lê como snapshot histórico, que é o correto. Só a
H1 escapava — o Achado 1.

**(c) O "689 asserções" driftou?** Parecia deriva de 19,6% (real: **824**), e **não é**. Os dois
sítios são snapshots **explicitamente datados** — o cabeçalho do workflow diz *"(medido em
2026-08-16)"* e a migalha diz *"(2026-08-17, PR #625)"* — e o próprio comentário do workflow declara
que *"a suíte CRESCE por desenho"*, com folga no teto por causa disso. **Número datado que envelheceu
não é deriva; é o que um snapshot faz.** Registro o ataque porque a conclusão oposta era tentadora e
teria gerado uma "cura" que destruía a datação.

## Prova

- Cron: run `32100701318` · `event=schedule` · `main` · 2026-08-18T04:52:01Z · 11m44s ·
  **824 passaram / 0 pularam / 0 falharam** — fechado por **contagem**, não por `success`.
- Relógio verificado contra **fonte independente**: header `Date` da API do GitHub
  (`Tue, 18 Aug 2026 13:06:01 GMT`) bate com o relógio local no mesmo segundo.
- Lint: **0 HARD / 4 SOFT** (linha de base; as 4 são por desenho).
- Diário: **102 entradas, 0 stale**; a migalha vira `static`, `retested_at: 2026-08-18`,
  `review_after: 2026-11-18`.
- Push confirmado pelo **estado** (`git rev-parse` local == remoto), não pelo `rc` — a guarda de shell
  me pegou lendo `$?` depois de pipe, pela segunda vez nesta sessão, e estava certa nas duas.

## Ressalva declarada (não é achado, é limite)

O que ficou provado é que **o agendador acorda** e **a suíte passa na `main`**. O que **não** fica
provado por uma execução é *regularidade*: um cron que dispara hoje pode ser silenciosamente
desativado pelo GitHub depois de 60 dias de repositório parado. Não há alarme para essa ausência —
ninguém é avisado quando um agendado **deixa** de rodar. Fica registrado como fio, sem cura: alarme
de ausência é mecanismo novo, não pedido.

**E o atraso importa para quem for verificar depois:** disparou às **04:52Z** para uma janela de
**04:17Z** — 35 minutos. Checar no minuto exato e concluir "não disparou" seria falso negativo por
desenho do instrumento.
