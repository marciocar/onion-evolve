# 🧠 Company Brain de {{EMPRESA}}: contexto da persona de serviço

> Contexto vivo do Company Brain desta empresa, gerado pelo construtor a partir das **fontes reais** e
> mantido pelo dono ({{DONO_PAPEL}}). O que não estiver aqui é «declarado, não verificado».
> Gerado em {{DATA}} pelo construtor v{{VERSAO_MOTOR}}. Cada item cita a fonte ou o id do nó no grafo.

## 1. Persona de serviço

| Campo | Valor | Fonte |
|---|---|---|
| Nome e assinatura | {{PERSONA_NOME}} — «{{ASSINATURA}}» | {{FONTE}} |
| Conta que publica | {{CONTA}} (própria ou emprestada, e de quem) | {{FONTE}} |
| Runtime | {{RUNTIME}} (onde roda, com que usuário) | {{FONTE}} |
| Regras de voz e conduta | [`voice-conduct.yaml`](voice-conduct.yaml), v{{VERSAO_REGRAS}}, aprovada por {{DONO_PAPEL}} em {{DATA_APROVACAO}} | o próprio arquivo |

## 2. Audiências e papéis

Papel, nunca nome: a lista nominal de pessoas fica fora deste documento.

| Audiência | Papéis | Lê | Escreve | Fonte |
|---|---|---|---|---|
| {{AUDIENCIA}} | {{PAPEIS}} | {{SUPERFICIES_LEITURA}} | {{SUPERFICIES_ESCRITA}} | {{NO_OU_DOC}} |

## 3. Canais

Todo canal entrega ao padrão de atendimento os cinco pontos do contrato de canal. Canal sem os cinco ainda não
usa o padrão; a coluna «Falta» diz o que medir.

| Canal | Hora do pedido | Quem pede e o papel | Contexto do lugar | Fio com assinatura | Quem mais vê | Fase | Falta |
|---|---|---|---|---|---|---|---|
| {{CANAL}} | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ | {{FASE}} (ex.: só comenta) | {{O_QUE_MEDIR}} |

## 4. Fontes que a persona lê

| Fonte | Como | Classificação | Regra | Fonte da regra |
|---|---|---|---|---|
| {{FONTE_LIDA}} | {{COMO}} | {{CLASSE}} | {{REGRA}} | {{NO_OU_DOC}} |

Grafos `.kg.yaml` que a persona consulta: {{LISTA_DE_GRAFOS}}.

## 5. Pedir e aprovar

Pedir não é aprovar. A tabela completa está em `request_vs_approve` do arquivo de regras; aqui vai o resumo.

| Tipo de ato | Quem pede | Quem aprova |
|---|---|---|
| {{ATO}} | {{QUEM_PEDE}} | {{QUEM_APROVA}} |

## 6. Métricas do padrão «exemplo primeiro»

| Métrica | Definição | Último valor | Fonte |
|---|---|---|---|
| Tempo até o 1º exemplo | do **pedido** ao 1º exemplo; a hora em que a persona viu o pedido fica registrada à parte | {{VALOR}} | {{FONTE}} |
| Aceite sem retrabalho em 24 h | retrabalho = trocar formato ou fonte; mudar data, filtro ou recorte é ajuste | {{VALOR}} | {{FONTE}} |
| Silêncio em 24 h | «pendente, sem sinal», nunca aceite; a persona pergunta «serviu?» uma vez, no fim da janela | {{VALOR}} | {{FONTE}} |

## 7. Decisões

| Decisão | Id do nó | Data | Quem decidiu |
|---|---|---|---|
| {{DECISAO}} | {{ID_DO_NO}} | {{DATA}} | {{PAPEL}} |

## 8. Lacunas

O que o construtor não achou nas fontes. Cada lacuna vem com uma sugestão e com como medir.

| Lacuna | Sugestão | Como medir |
|---|---|---|
| {{LACUNA}} | {{SUGESTAO}} | {{MEDIDA}} |
