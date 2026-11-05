---
branch: fix/hooks-python-isolated
pr: pendente
date: 2026-11-05
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
findings_fixed: 0
verdict: PREENCHA
elenxo: nao
reviewer: pendente
nota: "PASSADA ADVERSARIAL PENDENTE. O agente que escreveu a cura rodou a família e os mutantes, e isso não é a passada. O verdict segue PREENCHA de propósito: reprova no CI até um revisor independente rodar. Campos numéricos em 0 = não medido."
---

# Resíduo: `fix/hooks-python-isolated` — hooks rodam python em modo isolado

## O que muda

- **Modo isolado:** toda invocação de python no alcance dos hooks da sessão ganhou `-I`, os vetos primeiro. Censo por
  token de shell: 25 sem `-I` em 10 arquivos antes, 0 depois, 33 no total, alvo de 32 arquivos derivado do
  `settings.json`.
- **Falha de análise:** nos vetos, JSON ilegível deixa de virar comando vazio e cai no modo degradado por forma do
  objeto guardado. A guarda de segredo herdou esse modo, com o corte medido no grafo, e não trava mais a sessão inteira
  quando a análise morre. O veto da API direta fecha com python3 quebrado se o texto cita URL do provider ativo.
- **Guarda:** REGRA 115 (Hooks rodam python em modo isolado), `python-isolated-check.sh`, HARD no core e SOFT no
  derivado. O número pula o 114, que outra branch aberta já ocupa.
- **Bancada:** família `hooks_python_isolated`: cada veto real com módulo sombra no diretório de trabalho, em cópia
  fora da árvore viva; cópia limpa provada antes de cada mutante.

## O que uma passada precisa atacar

1. **Falso positivo do modo degradado:** o corte fecha 20,6% do corpus quando a análise morre. Vale fechar menos?
2. **Falso negativo do corte:** forma que o veto inteiro barra e o corte deixa passar, além dos globs já medidos.
3. **Scanner da guarda:** forma real de invocar python que ele não vê, ou caso honesto que ele acusa.
4. **Fechamento do alvo:** script executado por hook que a derivação não alcança.
5. **Famílias vizinhas não rodadas nesta leva**, por limite de carga: `pretooluse_veto`, `env_exposure`, `moat_gate`,
   `premodelswitch_guard`, `direct_provider_api`, `kg_read_leg`, `house_code_gloss`, `rule_title`, `instructions_loaded`.
   O pré-voo do `ops/pr-finalize.sh` as roda. Atenção a caso que prenda o texto antigo da mensagem de "python3 ausente".

## Teto

Grafo `docs/evolution/research/guard-hooks-python-isolated-2026-11/`: executável resolvido pelo PATH e sobrescrita do
próprio script não são cobertos; os scripts que o gate do git executa ficam para depois, com a contagem; o scanner é
léxico; sem python3 nenhum, o veto da API direta segue calado por decisão anterior.

## O que viaja

Hooks, guarda, regra e família viajam às quatro portas e aos adotantes na próxima publicação e atualização. O texto
público descreve só o que muda. A forma de avisar quem está para trás é decisão do maestro.
