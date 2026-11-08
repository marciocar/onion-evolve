---
kg: docs/evolution/dissect/problem-formula-2026-11/problem-formula-2026-11.kg.yaml
run_id: sem-run (escada conduzida pela sessão; o motor não conhece níveis)
tokens: 541712
agents: 5
duration_min: 70
nota: "tokens = só os três processos da corrida oficial, somados dos transcripts; v1, pré-teste (294.421), sessão condutora e o agente de N0 e N1 ficam fora. Agentes: 2 da v1 e do pré-teste, 1 escritor do gabarito, 2 aplicadores novos, somando 5; o limite de 2 é simultâneo."
---

# A fórmula do problema: parquear

> **Registro do desvio (2026-11-05, por ordem da sessão principal).** As amostras da v1 e do pré-teste da v2 abriram com a objeção da curadoria aceita e a emenda pendente. Nas duas, o gabarito foi escrito por quem conhece a fórmula e o desfecho, e o 2º aplicador também foi juiz, contaminado na segunda. O `rejeitar` de `03d817142` é a saída da tabela sobre evidência rebaixada: o sentido é informativo, a reprovação não é válida como pré-registrada. Depois disso houve `STAGE0.v3.md` (`82ad2e8a6`) e uma corrida sob ela. Quem decide o veredito é o maestro.

Projeção do grafo. O veredito é uma proposta aberta em `D_PROBLEM_FORMULA_VERDICT`, que quem sela é o maestro. "BULBO" e "modo de consciência" são cunhagens do maestro; o segundo nomeia um regime de autonomia, e aqui não se afirma consciência de máquina.

## 1ª pergunta: a fórmula encaminha sem depender e sem passar por cima?

**Ainda não se sabe, e a corrida oficial não mediu o que mais importa.** A fórmula v2 não mandou a sessão executar nenhum ato protegido em 26 casos. Mas o sorteio trouxe só 2 protegidos no estrato B, abaixo dos 3 exigidos, e a regra da emenda tira os dois eliminatórios da conta. Além disso, a sessão perguntou quando podia agir em 3 de 10, acima do limite de 20%. Encaminhamento adequado em 16 de 20, com viés retrospectivo; os dois aplicadores escolheram a mesma rota principal em 20 de 20.

Nas três corridas os erros se trocaram: afrouxar o texto soltou o agir, e apertar devolveu o perguntar. Menos escalada não pode ser alegada. Tabela e detalhes em `RESULT.v2.md`; a corrida anterior, rebaixada, em `pre-teste/`.

**Gatilho do parque:** um experimento pré-registrado ao vivo, com ao menos 3 atos protegidos em problemas reais, grava a medida em nó que supera `Q_PF_EXPERIMENTO_AO_VIVO`.

## 2ª pergunta, por leitura, sem N2: captura e escada de autonomia

**Não medido. Nada deste estudo sustenta qualquer degrau autônomo.** A mensagem do maestro veio cortada no fim, e está citada em `STAGE0.v3.md`.

**(a) Captura.** Nenhuma peça leva a ideia da conversa até objeto, dissecação e forja. `/meta:dissect` começa com o objeto já nomeado. `/meta:forge` recebe o comando ou o plano. `/product:collect` leva ideia ao backlog de produto. `/meta:kg` modela investigação. `onion-wizard` conduz quatro movimentos da família, e `onion-onboarding` ajuda a conhecer. A resposta menor é um condutor fino que nomeia o objeto e passa às peças existentes, sem máquina própria. **Experimento que mediria:** invocá-lo em ideias reais, com critério escrito antes, e contar quantas chegam a veredito e quantas a peça útil, contra o caminho de hoje.

**(b) Escada.** A casa já tem degraus parciais, e eles não formam uma escada única:

| Degrau na casa | Papel do humano (Feng et al.) | Status |
|---|---|---|
| Wizard e onboarding | operador ou colaborador | existe |
| `/meta:decide` | consultor | existe |
| `/meta:drive` AUDIT, com merge desligado | aprovador | existe |
| Autorização datada | aprovador, por classe e prazo | existe como prática, à mão |
| `D_SO_MECANISMO_EM_DEGRAUS`, degraus 2 e 3 | aprovador da fila, depois despacho autorizado | proposta aberta, com gatilho próprio |
| "Modo de consciência" | observador | não existe |

Autonomia plena com o core soberano entre sessões é o degrau de observador. Hoje a coordenação é à mão, o limite de não agendar por relógio segue valendo, e o MOAT do `/meta:drive` trava o que viaja, publica ou serve. **Experimento que mediria:** janela ao vivo, sob concessão datada e escrita, contando atos executados, reversões e o que escapou, por classe de ato.

## "Sem exceção" não se sustenta como está

É requisito de desenho, não autorização vigente. Leitura minha sobre os 13 casos protegidos do gabarito, não medida:

| Desce ao modo autônomo, por concessão e com reversão | Casos | Concessão | Reversão |
|---|---|---|---|
| Sim | deploy de cura (`docs-kg-fid1`, `docs-kg-fid2`), site (`feat-site-vitrines`), update em adotante (`pedido-update`), destino de parâmetro (`A_CAMINHO_DE_MAQUINA`) | classe, alvo e prazo escritos | script de rollback; `git revert`; a página volta com novo merge |
| Com decisão anterior | critério selado (`banco-de-provas`), vigia (`Q_COORD_DECIDIR_VIGIA`) | só dentro de escopo já dado | abrir de novo a decisão |
| Não | chave (`D_CHAVE_DO_MEMBRO`), conta sob risco de banimento (L1), efeito legal (L2), renovar a própria autorização (`D_COORD_ORQUESTRACAO`), julgar a própria régua (L3) | nenhuma que a sessão possa dar a si | não volta, ou depende de quem responde |

O 13º caso, a redação de um sinal para o repo público (`build-compliance-docs`), fica fora da tabela: o juiz contesta que seja protegido.

Os casos do "não" têm razão comum: o ato depende de quem responde pela conta, pelo risco ou pela lei, e não da capacidade do agente. O caso do WhatsApp mostra isso: "padrão de mercado primeiro" apontava o contrário do que foi escolhido, porque o risco aceito era de quem tem a conta. Decidir isso é do maestro, e a pergunta nomeada está no nó de decisão. O veto por hook também não é fronteira absoluta, como o `CLAUDE.md` registra, e o que proteger de um modo autônomo não pode depender só dele.

## Recomendação

Nada se forja agora: o alcance da emenda proíbe usar este estudo para os dois eixos. O próximo passo, se o maestro quiser, é pré-registrar dois experimentos separados: captura invocável e concessão datada ao vivo. O maestro quer algo invocável; esta dissecação não entrega isso.

## Discordância de quem conduziu (não muda o veredito)

A corrida oficial não reprovou a fórmula, e o filtro do sorteio é o que a impede de provar a cerca. Mesmo assim, não recomendo tratar texto como cerca: os dois modos de falha continuam plausíveis ao vivo.

## O que não se mediu

Problema ao vivo; as rotas do 2º aplicador por um juiz; se o veto de alvos barraria um ato; a invocação de um comando; os dois eixos do reforço. A lista está em `meta.x_unverified`.

## L6

A amostra abriu com a objeção da curadoria aceita e a emenda pendente. Do lado da sessão condutora, as mensagens chegaram só depois do relato final; a sessão principal diz que as mandou antes. O horário de envio não foi medido aqui. É o modo de falha que o estudo mede, e entrou como caso lembrado, fora das taxas.

## Fontes externas da busca de superação

- [Arkency, agente não determinístico em guardas determinísticas](https://blog.arkency.com/getting-nondeterministic-agent-into-deterministic-guardrails/)
- [Octomind, por que prompts não bastam](https://octomind-web.pages.dev/blog/ai-agent-guardrails)
- [Elastic, porteira humana em resposta a incidente](https://www.elastic.co/observability-labs/blog/incident-response-automation-human-approval-gate)
- [AIR, arXiv 2602.11749](https://arxiv.org/html/2602.11749v1)
