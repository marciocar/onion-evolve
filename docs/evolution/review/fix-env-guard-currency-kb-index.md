---
branch: fix/env-guard-currency-kb-index
pr: 1222
date: 2026-10-20
reviewed_diff_sha256: 0e66987537d468e8ba01f3bde94a4437286d2887c7f8811a7ed27a5e30a6cb7d
reviewed_code_sha256: f3e832397bcb6fe3a0ade06f039fa8e80f43e46b7012e6e259b44848f57e8391
findings_total: 21
findings_real: 18
tokens: 125611
duration_min: 40
findings_fixed: 15
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente refutador (itens 2 e 3, 18 casos) + passada adversarial da sessão no veto (item 1, 58 casos medidos contra a main e a cura)
nota: "o refutador não mediu o item 1 (a resposta dele foi cortada antes da bateria); a passada do veto foi refeita pela sessão, com 58 casos executados no hook"
---

# Passada adversarial: `fix/env-guard-currency-kb-index`

## O que muda

Três curas de sinais de campo de um hub adotante (2026-10-19):

- **U4:** `.claude/hooks/pretooluse-env-guard.sh` passa a distinguir LISTAR, NOMEAR e CITAR de LER VALOR.
- **C8:** a perna `base:` do `currency-census.sh` mede contra a integração do Onion, não contra a padrão do origin.
- **U5:** o índice da KB foi corrigido e ganhou a REGRA 110 (Índice da KB conta o que o disco tem).

## Achados

### Veto do `.env`: passada da sessão

O refutador não chegou a medir este item. A sessão montou 58 casos de ataque e rodou cada um no hook da cura e no da main.

1. **REAL, curado (escape da cura).** Uma opção depois do padrão e do arquivo vale, porque o GNU getopt permuta argumentos: `grep -oE '^[A-Z_]+=' .env -A3` passava. Agora toda opção conta, em qualquer posição antes de `--`. Mutante M18.
2. **REAL, curado (escape da cura).** Um arquivo de dados citando `.env` podia ser executado na mesma linha:
   - `bash -c "$(cat x.md)"`, `eval "$(cat x.md)"`, `cat x.md | bash`, `mv x.md run.sh; bash run.sh`, `chmod +x x.md; ./x.md` e `sh < x.md` passavam.
   - Agora barra quando a linha usa o arquivo como código (`data_used_as_code`).
   - A 1ª redação desta cura barrava qualquer vetor de execução na linha, e isso derrubou o próprio relatório do hub, que roda `bash durable-commit.sh` depois. Medido no replay e estreitado: ler o arquivo como dado segue passando. Mutante M19.
3. **REAL, curado (escape anterior à cura).** `F=.env python3 -I - <<'P'` lia o `.env` por uma variável do prefixo, e a main também deixava passar. Mutante M20.
4. **REAL, curado (escape anterior, achado no caminho).** `echo "$(cat .env)"` passava na main: o shlex entrega a substituição entre aspas duplas como um token só. Mutante M7.
5. **REAL, curado (escape anterior).** `find . -name .env | xargs cat` passava na main. Mutante M9.
6. **REAL, medido antes de afrouxar.** No bash 5, `$(cat <<'E')` fechado na mesma linha EXECUTA o corpo das linhas seguintes. Por isso o `<<` dentro de substituição segue recusado, por dois caminhos: o texto antes do operador e o parêntese aberto. Mutante M8.

### Censo e índice: passada do refutador (18 casos)

7. **REAL, curado.** O censo aceitava `integration_branch: "onion/develop"` com aspas: o resolvedor devolve o nome com as aspas, a regex o recusava, e o censo recuava calado para a padrão. Agora sai não medida, com o nome recusado. Caso (h6d).
8. **REAL, curado.** A chave de cache `onion/develop` colidia com `onion_develop`. Agora usa o cksum do nome.
9. **REAL, curado.** O índice acusava HARD falso em link com âncora, título, negrito, `./` e lista numerada. Caso (b2).
10. **REAL, curado.** Uma pasta dividida em duas seções era reprovada nas duas. Agora as seções são agregadas por pasta. Caso (b2).
11. **REAL, curado.** Um `## X (9)` dentro de bloco cercado era lido como seção. Caso (b2).
12. **REAL, curado.** Um cabeçalho `###` ou com texto depois do `(N)` não era reconhecido.
13. **REAL, curado.** Uma entrada só em comentário HTML contava como listada. Caso (b2).
14. **REAL, curado.** A extensão `.MD` e o arquivo solto na raiz da KB ficavam invisíveis.
15. **REAL, não curado, declarado.** Uma estatística em formato diferente não é julgada (verde silencioso). Fica no TETO do script.
16. **REAL, não curado, por desenho.** Uma `develop` só local deixa a perna `base:` não medida, em vez de medir contra a principal. É a escolha "nunca a padrão".
17. **REAL, não curado.** O link morto listado no índice é da REGRA dos links da KB, e o comportamento casa com o limite declarado.
18. **Não real.** Injeção pelo nome da branch: o nome é limitado por regex e vai entre aspas no `ls-remote`.
19. **Não real.** O índice em UTF-8 inválido já vira HARD "a guarda NÃO RODOU".
20. **Não real.** Uma seção de pasta só com README sai SOFT NAO-JULGAVEL, o que é honesto.

## Mutantes

- **Veto:** 20 no caso (u) de `env_exposure`, cada cura revertida numa cópia invertendo o caso dela.
- **Censo:** 2 no (h6), o resolvedor ausente e a cura desligada.
- **Índice:** 2 no `kb_index` (m), sem a comparação de contagem e sem a de listagem.

## Números

- **Replay dos 100 vetos reais (74 comandos distintos):** a main barra 57 e a cura barra 15. Desses 15, 12 leem valor e 3 são o residual declarado em `C_TETO_U4_RESIDUAL`.
- **Bancada:** famílias `env_exposure`, `currency_census`, `kb_index` e `rules_registry` com 94/94.

## Limites declarados

- **Fronteira do veto:** por chamadas separadas, a ferramenta Write grava qualquer script. Por isso o veto julga a linha, e não o que a sessão faz depois.
- **Autorização:** o maestro autorizou por `/meta:decide` em 2026-10-20, e o pedido chegou pela sessão principal.

## Retomada (2026-10-20): o CI vermelho e os dois selos

21. **REAL, curado (CI do #1222, faixa 3).** O caso `r22-kb-links/good-valid-links.md` reprovou: "não esperava
    violação citando a fixture, mas apareceu: REGRA 110 [FORA-DO-INDICE] … concepts/selftest-fixture-probe.md".
    O harness copia a fixture para `concepts/selftest-fixture-probe.md` no SANDBOX (sem git) e roda o lint com
    `--only` nela, e a REGRA 110 respondia sobre o índice. A cura não isenta o nome da sonda (código ciente de
    teste, o que o check das lentes path-scoped já recusou em 2026-09-29). Ela tem duas camadas, cada uma com caso
    e mutante:
    - **Gate por relevância sob `--only`** (o molde da REGRA 109): só o próprio `index.md` e a guarda disparam a
      REGRA 110. O `r22` pergunta sobre os LINKS daquele arquivo, e o índice é outra pergunta. O lint completo (CI,
      pr-finalize) segue julgando o índice. Caso (g): `--only` na KB plantada não emite, `--only` no índice emite,
      e o mutante do gate devolve o falso positivo.
    - **Conjunto rastreado** (o molde do `inventory.sh`, `_tracked_or_find`): conta `git ls-files` (que inclui o
      stageado), e conta o disco só sem git ou sem nada rastreado. Fixture plantada na árvore viva (não rastreada)
      não conta. Caso (f): a sonda não rastreada não reprova, o `.md` real rastreado fora do índice reprova, e o
      mutante `ONION_KB_INDEX_FS=1` devolve o falso positivo.

**Selos do maestro** (`/meta:decide` 2026-10-20, gravados pelo `kg-decide-seal.sh` no grafo deste PR, ligados ao
nó novo `E_U1_SINAL_MIGRACAO_CORPUS_V4`; o sinal de origem foi movido para `docs/evolution/inbox/_processed/`):

- `D_U1_MIGRADOR_NO_KG_SSOT`: escolhida «Migrador no kg-ssot»; descartadas «Generalizar o do core» e «Pesquisar antes».
- `D_U1_CAMADA_SDAAL_NO_UPDATE`: escolhida «Fase no --update»; descartadas «/meta:kg-migrate próprio» e «Os dois».

Os selos registram a decisão. A execução (tirar o `kg-migrate-v3.py` do que viaja e a fase nova do `--update`) é
de outro PR.
