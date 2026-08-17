---
date: 2026-08-17
instance: onion-evolve
type: observation
classification: collective
tags: [ci, schedule, cron, filtro-de-path, ponto-cego, verificacao-pendente]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "Rodar a verificação de uma linha abaixo e fechar (ou reabrir) a rede do filtro de path."
review_after: 2026-08-18
conflict_class: dynamic
significance: "A bancada saiu do gate de todo PR (12 min → 49s) atrás de um filtro de path — e filtro de path já criou TRÊS pontos cegos nesta casa. A rede que o justifica é um cron noturno que AINDA NÃO DISPAROU. Enquanto não disparar, o filtro está nu e eu não sei disso."
---

# O cron que justifica o filtro — e que ainda não provou existir

**O que foi feito (2026-08-17, PR #625).** A bancada (`lint-selftest.sh`, 689 asserções) saiu
do workflow de gate e foi para `onion-selftest.yml`, que roda **só quando a maquinaria muda**
(`.claude/validation|hooks|utils`, `ops/`, `.github/workflows/`). Medição que motivou: a
bancada era **686s de 729s — 94% do CI** — e dos 8 PRs do dia anterior **6 tocaram zero
arquivo de maquinaria**. O gate caiu para **49s**, medido no próprio PR que fez a mudança.

**O risco que isso cria, e não é hipotético.** Filtro de path já produziu **três pontos
cegos** aqui: `plugins/` (#241), `docs/` (#254), `ops/` (#509). Nos três, o defeito não foi
filtrar — foi **filtrar e não ter mais nada**: caminho fora da lista nunca era coberto por
ninguém, e ninguém lê lista de path. Por isso o workflow novo tem `schedule: '17 4 * * *'`
rodando a bancada **inteira** na `main`, sem filtro — a rede debaixo.

**O que está PROVADO hoje:** o workflow está `active` (id 336224267) e o `cron` está no
arquivo **na `main`**, que é de onde o agendador lê. As duas falhas clássicas (workflow não
reconhecido; definição só fora da branch default) estão descartadas.

**O que NÃO está provado:** que ele **dispara**. O `schedule` do GitHub Actions é
*best-effort* — em horário de pico atrasa e pode engolir execuções. O merge foi 13:07 UTC e a
primeira janela é 04:17 UTC do dia seguinte, então "nenhuma execução" hoje é **esperado**, não
defeito. Distinguir os dois é o ponto desta migalha.

**Re-teste (2026-08-18) — uma linha, com o veredito já escrito:**

```bash
gh run list --repo marciocar/onion-evolve --workflow onion-selftest.yml --event schedule --limit 3
```

- **Há execução agendada** → a rede existe; o filtro de path está justificado; fechar esta
  migalha como confirmada.
- **Continua "no runs found"** → a rede **não existe** e o filtro está nu: três pontos cegos
  de precedente dizem o que acontece daí. Aí a decisão é uma destas, e não "prestar atenção":
  reduzir o filtro (voltar a bancada para todo PR e aceitar os 12 min), ou trocar a rede por
  algo que não dependa do agendador do GitHub (cron da própria VPS chamando
  `gh workflow run onion-selftest.yml`, que é disparo e não agendamento).

**A nota de método, porque quase virou relato falso.** Ao conferir isto, meu
`git show origin/main:.github/workflows/onion-selftest.yml` respondeu **"não existe na
origin/main"** — e eu ia reportar ao maestro que o cron não estava na branch default. Era o
meu ref local **desatualizado** (sem `fetch` desde o merge). Um `git fetch` inverteu a
resposta. Terceira vez no mesmo par de dias em que **medir no ref/lugar errado** quase virou
afirmação: `.git/hooks` em vez de `core.hooksPath`, `$?` depois de pipe, e agora `origin/main`
velho. O padrão não é falta de cuidado — é que a leitura errada **responde com confiança**.
