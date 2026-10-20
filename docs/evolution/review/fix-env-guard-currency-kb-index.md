---
branch: fix/env-guard-currency-kb-index
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: f1d45eacf4af40bd6132eaccde2e55e040c99ff32540a9b70e1fd7798d00805b
reviewed_code_sha256: 332226fddf1ae5055a728355745a24a3d9a5d0cc53c273517c6acc89958d9922
findings_total: 20
findings_real: 17
tokens: 125611
duration_min: 40
findings_fixed: 14
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
