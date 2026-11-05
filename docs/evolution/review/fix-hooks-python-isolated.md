---
branch: fix/hooks-python-isolated
pr: pendente
date: 2026-11-05
reviewed_diff_sha256: pendente
findings_total: 12
findings_real: 12
tokens: 0
duration_min: 0
findings_fixed: 11
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "refutador independente (agente separado, com corpus, mutantes e laboratório próprios)"
nota: "tokens e duração em 0 = não medidos. O refutador reprovou 76461b38d, e a 2ª passada, sobre 26a54bfa4, achou o bloqueio 12; os dois estão curados nos commits seguintes. Um achado segue aberto de propósito: o achado 2, em parte, declarado como teto."
---

# Resíduo: `fix/hooks-python-isolated` — hooks rodam python em modo isolado

## O que muda

- **Modo isolado:** toda invocação de python no alcance dos hooks da sessão ganhou `-I`, os vetos primeiro. Censo por
  token de shell: 25 sem `-I` em 10 arquivos antes, 0 depois, alvo derivado do `settings.json`.
- **Falha de análise:** três regimes. Python vivo com analisador morto fecha tudo, com a razão. JSON ilegível e python3
  ausente ou quebrado fecham pela forma do objeto guardado.
- **O que vem do diretório de trabalho é dado:** o script do farol vem do projeto da sessão, do arquivo de ambiente só
  entram as chaves da federação, e a leitura de índice no veto do MOAT isola a config do repo.
- **Guarda:** REGRA 115 (Hooks rodam python em modo isolado), HARD no core e SOFT no derivado. O número pula o 114, que
  outra branch aberta já ocupa.
- **Bancada:** família `hooks_python_isolated`, em cópia fora da árvore viva, com a cópia limpa provada antes de cada mutante.

## Achados da passada adversarial sobre 76461b38d

| # | Achado | Grau | Destino |
|---|---|---|---|
| 1 | Analisador morto com python vivo e JSON válido soltava num veto em que a main fechava | barra o merge | curado: `try` em volta do juízo, sonda de python vivo, forma só para JSON ilegível e python ausente |
| 2 | O grafo dizia "todos glob sem ponto": no corpus inteiro, o veto barra 68 e a forma solta 13 (7 glob sem ponto, 5 padrão duplo em texto de heredoc, 1 nome montado em execução), e a leitura por padrão sem ponto não estava coberta | barra o merge | corrigido no grafo; o padrão sem ponto entrou na forma, com 0 fechamentos a mais no corpus; o glob sem ponto ficou como teto, porque fechá-lo travaria comandos comuns |
| 3 | Script do farol resolvido pelo diretório de trabalho | barra o merge | curado |
| 4 | Leitura do arquivo de ambiente sem filtro de chaves | barra o merge | curado |
| 5 | Leitura de índice no veto do MOAT sem isolar a config do repo; os outros `git -C` dos vetos foram medidos e não precisam | barra o merge | curado |
| 6 | Expansão de chaves sem teto | anterior à cura | curado: 256 alternativas, passou fecha; 0 de 2.067 comandos reais com chave e vírgula chegam lá, e nenhum rc mudou |
| 7 | A guarda não varria o texto do comando no `settings.json` nem hook fora de `.claude/` | lacuna da guarda | curado |
| 8 | 5 mutantes vivos na forma do segredo | caso decorativo | curado: caso e mutante para cada um |
| 9 | 2 mutantes vivos no veto da API | caso decorativo | curado, e `none` deixou de contar como provider ativo |
| 10 | Veto de force-push soltava quando o texto longo cortava o verbo da linha de inanalisável | mesma classe do 1 | curado: o verbo não some no corte |
| 11 | O teto do executável omitia os caminhos dos achados 3 a 5 | texto | corrigido no grafo |
| 12 | 2ª passada: a leitura do arquivo de ambiente errava a forma documentada (comentário no fim da linha, última linha sem quebra), e a federação do adotante parava sem aviso | barra o merge | curado, com caso e mutante por forma; dois mutantes da família que morriam pelo arranjo agora morrem por caso real |

## O que ficou de fora, por decisão

`PYTHONSAFEPATH` no lint e no pre-commit e a forma maiúscula do escape: PR seguinte, pelo pedido.

## Para o PR seguinte

O teto de 256 alternativas fecha comando legítimo em formas raras, com 0 casos em 3.100 do corpus. A alternativa tem
custo, e a decisão é do maestro: nó `C_TETO_DE_CHAVES_FECHA_LEGITIMO`.

## Teto

Grafo `docs/evolution/research/guard-hooks-python-isolated-2026-11/`: executável resolvido pelo PATH e sobrescrita do
próprio script não são cobertos; os scripts que o gate do git executa ficam para depois, com a contagem; o scanner é
léxico; sem python3 nenhum, o veto da API direta segue calado por decisão anterior.

## O que viaja

Hooks, guarda, regra e família viajam às quatro portas e aos adotantes na próxima publicação e atualização. O hook do
inbox não viaja às portas. O texto público descreve só o que muda. A forma de avisar quem está para trás é decisão do maestro.
