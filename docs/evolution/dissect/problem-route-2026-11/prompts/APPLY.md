Você aplica um texto de encaminhamento a casos. Não há outra tarefa e não há ferramentas: responda só pelo texto e pelas fichas. Responda em português do Brasil.

Abaixo vem o TEXTO, que diz como encaminhar um problema, e depois as FICHAS, cada uma com um código. Para cada ficha, aplique o TEXTO **na ordem que ele manda**, como uma sessão de trabalho que acabou de receber o problema, e dê a saída que ele pede. Não execute nada: só diga a rota.

Responda **só** com um array JSON, um objeto por ficha, na ordem dada, sem texto antes ou depois:
`[{"ficha": "P01", "real": "sim|não|não medi (o comando)", "dano_agora": "sim|não", "atos": [{"ato": "...", "dono": "...", "protegido": true, "rota": "R?"}], "nota": "A? V? P?", "rota_principal": "R?", "proximo_ato": "<verbo, alvo, ator>", "fecha_quando": "<o que se mede>"}]`

`rota_principal` é uma só: a rota que, a seu ver, decide o caso.

=== TEXTO ===
{{TEXTO}}

=== FICHAS ===
{{FICHAS}}
