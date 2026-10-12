---
branch: docs/reconcile-landscape-seals
date: 2026-10-12
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 25
verdict: REPROVADO_E_CURADO
reviewer: passada própria com medição ao vivo (API do GitHub, censo de dissecação) — gate mecânico: kg-radar + kg-contract-check
---

# O panorama competitivo estava parado em julho, e dois selos estavam só na conversa

## Achados

1. **O panorama L1 de mercado estava defasado em relação à pesquisa do próprio core.** O sinal veio do
   adotante de curadoria. Os números foram re-medidos pela API do GitHub em 2026-10-12, sem copiar os do
   sinal:
   - **Spec Kit:** 140,9k★ (era ~90k).
   - **Ruflo:** 74,4k★ (era ~29k).
   - **Superpowers:** 297,9k★. Estava ausente; entrou como **candidato** a direto, com gatilho nomeado:
     a dissecação.
   - **BMAD:** 54,0k★.
   - **SuperClaude:** 23,9k★.
   - **Agent OS:** 5,5k★.
   - **GSD:** o repo antigo está **arquivado**; o atual é `open-gsd/gsd-core` (10,4k★).
2. **O selo da sub-decisão (3) do SAC-52 só existia na conversa.** O maestro selou por pergunta com
   opções em 2026-10-12: "fechar como proposto". Agora `Q_SUBDECISAO_3_FECHAMENTO_1012` está `done`, com
   proveniência de testemunho.
3. **O degrau 1 do SAC-70 estava em produção sem evidência no grafo.** Entrou
   `E_DEGRAU1_EM_PRODUCAO_1012` (plane PROD), com a medição por comportamento e o achado do deploy: a
   autorização por usuário no servidor, porque "papel no LibreChat" não protegia nada. Na 1ª escrita, o
   `provenance.method` não tinha o prefixo do vocabulário, e o contrato acusou. Corrigido.

## Triagem do inbox

- `2026-10-09-competitive-landscape-behind-own-research.md` → endereçado por este PR (achado 1).
- `2026-10-09-dissect-census-ignores-quoted-dates.md` → **curado no #1033**. Conferido no código, que
  aceita aspa opcional em `baseline` e `review_after`, e no vivo: o censo lê o Conductor com as datas
  entre aspas (2026-10-11 e 2026-11-10).

## O que NÃO cobre

- O capital dos concorrentes (Crunchbase e PitchBook não foram consultados).
- Se o Superpowers é concorrente direto. Fica para a dissecação.
