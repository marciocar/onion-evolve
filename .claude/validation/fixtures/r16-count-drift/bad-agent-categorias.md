# Fixture de drift — caso BAD (Regra 16, categorias de AGENTE)

Este documento afirma __ONION_AGENTS_TOTAL__ agentes de IA especializados em __ONION_AGENT_CATEGORIES_DRIFT__ categorias.
O número de agentes bate com a SSOT, mas a contagem de **categorias de agente** diverge.
Antes do fix, a Regra 16 usava categorias-de-comando para a frase de agentes e este drift
escapava (e o self-heal o reintroduzia). A Regra 16 (SOFT) deve flagrar a divergência.
