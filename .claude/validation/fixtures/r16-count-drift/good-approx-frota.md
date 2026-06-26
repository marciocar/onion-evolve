# Fixture de drift — caso GOOD (Regra 16, GUARDA ANTI-FROTA)

Carga cognitiva de um humano supervisionando 8-16+ agentes paralelos numa frota.

A linha acima é métrica de EXECUÇÃO (carga de runtime), não inventário do catálogo.
A guarda anti-frota (range 'A-B+' + termos paralel/frota/supervision) deve fazer a
Regra 16 IGNORAR essa linha. Teste de regressão: NÃO pode flagrar (senão o falso-positivo
da KB agent-orchestration-landscape volta). Esta prosa explicativa evita de propósito
repetir o padrão de contagem, para que a linha-alvo seja a única candidata.
