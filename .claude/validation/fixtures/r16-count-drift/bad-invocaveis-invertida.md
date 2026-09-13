# Fixture de drift — caso BAD (Regra 16, forma INVERTIDA com separador + 'invocáveis')

## 2. Comandos — __ONION_COMMANDS_DRIFT__ invocáveis em dez categorias

O feeder canônico exige `[0-9]+ comandos invocáveis` (número ANTES do substantivo).
Aqui o travessão inverte a ordem — `Comandos — N invocáveis` — e a forma escapava.
Foi assim que `docs/technical-context/02-ai-context/codebase-guide.md` afirmou 99
comandos por semanas com a SSOT em 102, sem nenhum feeder disparar.

⚠️ 'dez categorias' POR EXTENSO, e isso é load-bearing: a 1a versão escrevia
'10 categorias', que casa o pré-filtro ANTIGO — a fixture continuava citada mesmo
removendo a alternativa NOVA do pré-filtro, logo não testava a alternativa que veio
com ela. É o mesmo mascaramento do 'getting-started' já documentado na Regra 16.
Sem nenhum outro numeral+substantivo aqui, o arquivo só alcança o feeder pela
alternativa `comandos[[:space:]]*(—|–|:|-)[[:space:]]*[0-9]` — alternância, não conjunto: em locale C um conjunto `[—…]` casa um BYTE do travessão (2026-09-13).
