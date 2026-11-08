---
branch: chore/diary-review-2026-11-08
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: 8276f5660ec91eed229d7e11896199e381e960e6e828680c2e54cd909260ec9a
reviewed_code_sha256: 7907cf09a0f55d5e1efeff9a616c731fc74cfcef969ce3d391cbe429048b1e8c
findings_total: 3
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: autor (releitura contra o vivo, sem agente separado)
nota: >-
  Passada do próprio autor, sem agente isolado (o brief desta rodada proíbe criar agentes), por isso
  elenxo: nao. Reli as afirmações do diff que eu ainda não tinha medido direto e medi cada uma. As três
  se sustentaram: os 5 runs mais recentes do onion-review saem run=false (modo off), lidos um a um no
  log; a guarda me interrompeu 3 vezes na rodada; o diário tem 133 migalhas. tokens e duration_min não
  foram medidos (0).
---

# Passada adversarial: `chore/diary-review-2026-11-08`

O diff são 31 migalhas re-testadas e o índice regenerado. O risco desta classe de PR é **reflexão falsa
persistida**: um re-teste que afirma o que não mediu. Por isso a releitura foi contra o vivo, não
contra o texto.

## O que a releitura conferiu

- **"Os 5 runs mais recentes são `run=false (modo off)`"** — eu tinha lido o log de um só. Li os cinco
  (`gh run view --log`, `review-mode-decide: run=false (modo off)` em todos). Sustentou.
- **"A guarda me interrompeu três vezes"** — duas `EXIT-CODE-DE-PIPE` e uma `ERRO-ENGOLIDO-VIRANDO-NÚMERO`
  nesta sessão. Sustentou.
- **"133 migalhas"** — `ls .claude/diary/*.md` sem o `index.md`. Sustentou.

## Defeito evitado antes do diff (não conta como achado do diff)

Minha 1ª comparação dos templates SMTP deu `DIFF-VAZIO` entre **dois arquivos vazios**: a query filtrava
`connector_id ilike '%smtp%'`, e o id real é `simple-mail-transfer-protocol`. Só a contagem de linhas
(0) mostrou o vazio-por-ausência. Refeita com 5 linhas de cada lado, o `diff` vazio passou a valer. O
caso entrou como evidência na migalha `2026-08-02-reproduce-not-recreate-provisioners`.

## Limite

Sem agente separado, a releitura tem o viés de quem escreveu. Os vereditos que dependem de busca
externa (Company Brain, prefixos de steering) usaram uma busca `standard` cada, e o que ela não
confirmou ficou declarado como NÃO re-confirmado no próprio re-teste.
