---
branch: chore/ci-review-action-pin-currency
pr: pendente
date: 2026-10-17
reviewed_diff_sha256: pendente
findings_total: 10
findings_real: 9
tokens: 142094
duration_min: 5
findings_fixed: 9
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose, model opus, 1 passada com mandato de refutar
nota: "1 achado declarado sem cura: o sed de subida não põe aspas na lista de arquivos (workflow com espaço no nome); a casa não tem workflow assim"
---

# Passada adversarial: `chore/ci-review-action-pin-currency`

## O que muda

- `.github/workflows/onion-review.yml`: o pin da `anthropics/claude-code-action` sobe da v1.0.183
  (`be7b93b1`, CLI 2.1.220) para a v1.0.252 (`f27be6b6`, CLI 2.1.302), nos dois passos (tentativa e retry).
- `.claude/validation/currency-census.sh`: perna nova `act`, que lê o pin por SHA das actions que instalam
  um CLI nos workflows, compara com a maior tag `vX.Y.Z` e, se estiver defasada, traz o CLI de cada commit
  e o `sed` de subida (SAC-169).
- Bancada `currency_census`: 10 casos novos (aa..aa10).
- Grafo da rodada r13: fecha `Q_PIN_DO_REVISOR_DO_CI_SOBE_OU_ENTRA_NO_CENSO` e abre a prova do revisor no
  PR seguinte. Também sela a decisão do maestro na SAC-168 (pedido da sessão principal) e abre a medição de
  um turno real do fork.
- Textos: a doutrina de atualidade, o `contributing.md` e o comentário do `review-verdict.sh`.

## Achados

Fonte: o refutador opus. Todos medidos por ele, salvo onde está indicado "por inspeção".

1. MÉDIA: pin entre aspas (`uses: "…@sha"`) ficava invisível no censo, e o caminho `…/base-action@sha`
   não casava. **Curado**: o regex aceita aspas e subcaminho. Caso aa10.
2. BAIXA: um pin numa linha comentada entrava no censo. **Curado**: linhas comentadas saem antes. Caso aa10.
3. BAIXA: `for p in ${pins}` expandia glob vindo do conteúdo do workflow. **Curado**: leitura por
   `while read`, e o pin só aceita caracteres de ref.
4. BAIXA: prazo. `ls-remote` mais 2 `curl` em série podiam passar dos 9 s da perna. **Curado**: os dois
   `curl` rodam em paralelo.
5. MÉDIA (mutante sobrevivente, por inspeção): tirar o pin da chave do cache não era pego. **Curado**:
   caso aa9, que troca o pin sem `--fresh`. O mutante 6 agora morre.
6. BAIXA (mutante sobrevivente, por inspeção): processar só o 1º pin. **Curado**: caso aa10. O mutante 7
   morre.
7. BAIXA: o comentário do workflow dava a entender que o teto de turnos derruba o job. Na verdade o
   `review-verdict.sh` lê o `execution_file`, não o outcome da action. **Curado** o texto.
8. BAIXA: o `review-verdict.sh` citava "v0.3.220, a mesma do pin be7b93b". **Curado**: agora cita as duas
   versões, conferidas.
9. BAIXA: a contagem "69 versões". No npm são 70 publicadas em (2.1.220, 2.1.302]; as 69 são seções do
   CHANGELOG. **Curado** no workflow. A v1.0.171 instalava o 2.1.207, não o 2.1.220: **curado** no
   `contributing.md`.
10. BAIXA, **sem cura**: a lista de arquivos do `sed` vai sem aspas. Declarado na `nota`.

O que o refutador não achou: quebra no job. Inputs e outputs usados seguem iguais, o `execution_file`
continua JSON com `is_error`, e a redação de segredos não toca o arquivo. Também não achou citação de
`ops/` nem nome de cliente na superfície que viaja. O grafo saiu com rc 0.

## Mutantes

9 mutantes plantados por `ops/mutate-and-restore.sh`, com `LC_ALL=C`, todos mortos:

| # | Mutante | Casos que reprovaram |
|---|---|---|
| 1 | em-dia sempre falso | aa, aa2, aa5, aa7, aa10 |
| 2 | sem preferir o commit da tag anotada | 7 casos |
| 3 | perna fora do laço | todos |
| 4 | sem a guarda de pin por tag | aa4 |
| 5 | sem o ramo de pin fora de tag | aa5 |
| 6 | cache sem o pin | aa9 |
| 7 | só o 1º pin | aa10 |
| 8 | sem o filtro de comentário | aa10 |
| 9 | sem aspas no regex | aa10 |

Bancada limpa: 59/59.

## Limites declarados

- O revisor no pin novo **não foi provado em execução**. O PR que edita o workflow faz a action se
  auto-pular. Ligar a label `review:ia` gasta crédito da chave do repositório, que está sem crédito por
  decisão. O `onion-review-diagnose.yml` só testa a credencial por `curl` e não exercita a action. A prova
  fica para o PR seguinte com a label, registrada em `Q_REVISOR_NO_PIN_NOVO_PROVADO_NUM_PR_COM_A_LABEL`.
- O censo só julga as actions da lista `ACTIONS` e só pin por SHA. Pin por tag é `nao-medida`. O CLI é lido
  de `src/entrypoints/run.ts`; se o arquivo mudar de lugar, o texto diz "CLI não lido".
- Só o `currency-census.sh` ganhou a superfície. O `cc-delta-census.sh` não mudou: ele compara com o CLI do
  host, e a defasagem contra o publicado é papel do censo de atualidade.
