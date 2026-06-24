# Técnicas de dosagem / controle de admissão e vazão de filas — base de pesquisa

> **Origem.** Síntese de uma pesquisa multi-fonte (deep-research, run `wf_cf08362b-a14`) que
> fez fan-out de busca → fetch de fontes → extração de afirmações falsificáveis → verificação
> adversarial. O run foi **interrompido** (a sessão caiu) antes da fase de síntese; este documento
> **reconstrói a síntese** a partir do trabalho já concluído e salvo no journal (Search + Fetch +
> Verify). Veja "Procedência e confiança" ao final.
>
> **Escopo.** Técnicas organizadas **da mais simples à mais complexa**. Para cada uma: princípio,
> quando se aplica, parâmetros, prós/limites e fonte verificável. Ao final, um **paralelo neutro**
> com a necessidade da fila SLOT→pasta da RHILO — descritivo, **sem prescrever solução**.
>
> **Data:** 2026-06-23.

---

## Mapa rápido (simples → complexo)

| #   | Técnica                          | Família                   | O que controla                              | Sinal de realimentação                 |
| --- | -------------------------------- | ------------------------- | ------------------------------------------- | -------------------------------------- |
| 1   | Token bucket / leaky bucket      | Rate limiting / shaping   | Taxa de **entrada** + rajada tolerada       | Nenhum (malha aberta; crédito = token) |
| 2   | (Weighted) Round Robin / DRR     | Escalonamento justo       | **Repartição** entre filas concorrentes     | Nenhum (proporção fixa por peso)       |
| 3   | WFQ / GPS / WF²Q                 | Escalonamento justo ideal | Repartição + **atraso** garantido           | Nenhum (estado por fluxo)              |
| 4   | Crédito / backpressure           | Controle de admissão      | **In-flight** por origem (sem perda)        | Crédito devolvido ao drenar            |
| 5   | Teoria de filas (Little, M/M/c)  | Dimensionamento           | Relação taxa↔ocupação↔atraso              | — (modelo, não controlador)            |
| 6   | PI/PID em AQM (ex. PIE)          | Controle em malha fechada | Métrica-alvo (atraso/ocupação)              | Erro vs. referência                    |
| 7   | AIMD (TCP)                       | Controle em malha fechada | Taxa de **saída** adaptativa                | Perda = congestionamento               |
| 8   | (s,S) / base-stock / newsvendor  | Pesquisa operacional      | **Quanto liberar** p/ nível de serviço-alvo | Posição de estoque / demanda           |
| 9   | TCI / malha fechada em anestesia | Controle biomédico        | Dose p/ efeito-alvo                         | Medida do efeito (titulação)           |

---

## 1. Token bucket e leaky bucket (rate limiting / traffic shaping) — RFC 2697/2698

**Princípio.** Um "balde de tokens" é reabastecido a uma taxa constante (a taxa permitida) até uma
capacidade máxima (a rajada tolerada). Cada unidade admitida consome tokens; sem tokens, a unidade é
marcada/atrasada/descartada. É o primitivo canônico de **controle de admissão por crédito acumulado**.

- **srTCM (RFC 2697)** — _Single Rate Three Color Marker_. Três parâmetros: **CIR** (Committed
  Information Rate, bytes/s), **CBS** (Committed Burst Size) e **EBS** (Excess Burst Size). Tokens
  enchem o balde C (capacidade CBS) primeiro e o balde de excesso E (EBS) só quando C está cheio.
  Decisão por pacote de tamanho B: **verde** se C cobre B (decrementa Tc); senão **amarelo** se E
  cobre B (decrementa Te); senão **vermelho**. ✔️ _Verificado contra a RFC._
- **trTCM (RFC 2698)** — _Two Rate Three Color Marker_. Dois baldes/duas taxas: **PIR** (Peak) com
  **PBS**, e **CIR** com **CBS**, exigindo `PIR ≥ CIR`. Teste hierárquico: **vermelho** se excede a
  PIR; senão amarelo/verde conforme exceda ou não a CIR. ✔️ _Verificado._

**Quando se aplica.** Limitar a vazão de admissão contra um "contrato" e tolerar rajadas controladas;
classificar em níveis de tratamento (verde/amarelo/vermelho) em vez de aceitar/rejeitar binário.

**Parâmetros.** CIR/PIR (taxa), CBS/PBS/EBS (rajada). Pelo menos um burst > 0.

**Prós/limites.** Simples, O(1), sem estado de histórico; modos **color-aware** permitem admissão
encadeada/hierárquica (decisão a montante limita a jusante). **Limite:** é **malha aberta** — não
reage a resultado a jusante; só molda a entrada. RFC 2697 é _Informational_ (sem standing
standards-track), RFC 2698 é _Proposed Standard_.

**Distinção citável (Wikipedia, secundária):** _Connection Admission Control_ = verificação **a priori**
(antes); _policing_ = verificação **a posteriori** (durante). E: fontes com realimentação "tipicamente
convergem para uma taxa logo abaixo da taxa policiada" — um paralelo de malha fechada já na literatura
de policing.

**Fontes.** RFC 2697 <https://www.rfc-editor.org/rfc/rfc2697> · RFC 2698
<https://datatracker.ietf.org/doc/html/rfc2698> · Traffic policing (Wikipedia)
<https://en.wikipedia.org/wiki/Traffic_policing_(communications)>

---

## 2. Round Robin ponderado e Deficit Round Robin (DRR) — Shreedhar & Varghese (1995/96)

**Princípio.** Servir filas concorrentes em rodízio, dando a cada fila uma fatia proporcional a um
**peso**. O _plain_ round-robin é injusto quando as unidades têm tamanhos diferentes; o **DRR**
corrige isso mantendo, por fila, um **deficit counter** que mede e compensa a injustiça acumulada
entre rodadas.

**Como funciona (DRR).** Cada fila _i_ recebe um **Quantum_i** (bytes permitidos por rodada). A cada
rodada o contador acumula `Quantum_i − bytes_enviados` e **carrega o crédito não usado** para a
próxima. Invariante provado (Lema 4.1): ao fim de toda rodada, `0 ≤ DeficitCounter_i < Max`
(tamanho máximo do pacote) — o crédito não cresce sem limite. Se a fila esvazia, o contador zera.
✔️ _Verificado contra o paper._

**Ponderação.** A ponderação é configurada **puramente pelo quantum**: `Quantum_i = 2·Quantum_j` ⇒
fila _i_ recebe o dobro da banda de _j_. Taxa mínima garantida de _i_ = `Q_i/ΣQ · R`, e — diferente do
WRR clássico — **independente do tamanho dos pacotes**. ✔️ _Verificado._

**Quando se aplica.** Repartição justa e barata de um recurso entre N concorrentes com pesos
configuráveis, em alta escala.

**Prós/limites.** **O(1)** por pacote (vs. O(log n) do fair-queuing clássico), implementável em
hardware; _consenso_. **Limite (consenso):** DRR básico garante **justiça de throughput mas não dá
garantia de latência** — limites de atraso exigem variante aumentada (Seção 7 do paper). Variantes
modificadas estão em produção (roteadores Cisco/Juniper, que adicionam prioridade a algumas filas).

**Fontes.** Shreedhar & Varghese, _Efficient Fair Queuing using Deficit Round Robin_, SIGCOMM '95 /
IEEE-ACM ToN 4(3) 1996 — <https://dl.acm.org/doi/10.1145/217382.217453> · PDF
<https://courses.cs.duke.edu/fall24/compsci514/readings/drr.pdf>

---

## 3. WFQ / GPS / WF²Q — o ideal de justiça ponderada e seu erro de aproximação

**Princípio.** O **Generalized Processor Sharing (GPS)** (Parekh & Gallager, 1993) é o modelo
**ideal** (fluido) de justiça ponderada: cada sessão continuamente carregada é servida em proporção
ao seu peso `φ_i`, com **taxa mínima garantida** `≥ φ_i/Σφ · r` **independente da demanda das
outras**. É o alvo que WRR/WFQ aproximam.

- **PGPS = WFQ.** O _packet-by-packet GPS_ (Parekh) é idêntico ao **Weighted Fair Queueing** e
  aproxima o GPS fluido com **erro limitado**: um pacote sai no máximo `L_max/r` (uma transmissão de
  pacote máximo) depois do tempo GPS.
- **GPS + Leaky Bucket = garantias de pior caso.** Combinar GPS com admissão por leaky bucket
  permite **garantias determinísticas** (não só médias) de throughput e atraso; se as chegadas são
  `(σ_i, ρ_i)`-limitadas e a taxa garantida excede `ρ_i`, o atraso `≤ σ_i/ρ_i`.
- **WF²Q (Bennett & Zhang, 1996) — ponto debatido/refinado.** _Contra a crença popular_, a
  aproximação WFQ pode **divergir bastante** do GPS ideal: nunca fica **atrás** por mais de um
  pacote, mas pode correr **muito à frente** (super-serviço em rajada). WF²Q restringe o conjunto
  servível aos pacotes **elegíveis** (que já começaram no sistema fluido GPS) — esse "gate" de
  admissão limita a discrepância a um pacote **nos dois sentidos**.

> ⚠️ **Achado diretamente relevante a medição ruidosa.** O super-serviço "à frente" do WFQ se
> manifesta como **oscilação auto-sustentada** (rajada → silêncio → rajada). Pior: a literatura mostra
> que isso prejudica algoritmos de **controle por realimentação que medem taxa**, porque a estimativa
> oscila entre a velocidade plena e zero e **"o erro de medição NÃO é função estritamente decrescente
> do intervalo de medição"** — ou seja, **simplesmente alongar a janela de amostragem não reduz o
> ruído de forma confiável**. (Bennett & Zhang, INFOCOM 1996.)

**Quando se aplica.** Quando se quer **garantia por fluxo** (piso de serviço) desacoplada da demanda
dos concorrentes, e/ou limites de atraso de pior caso.

**Prós/limites.** Garantias fortes e formais; custo: WFQ é O(log n); a aproximação tem erro limitado
mas pode oscilar (motivo da existência do WF²Q).

**Fontes.** Parekh & Gallager (1993), _A Generalized Processor Sharing Approach…_ — IEEE/ACM ToN
<https://www.cs.ucr.edu/~jiasi/teaching/cs204_spring19/papers/gpsLeakyBucket93.pdf> · Bennett & Zhang
(1996), _WF²Q: Worst-Case Fair Weighted Fair Queueing_
<https://www.academia.edu/4790881/WF2Q_Worst_Case_Fair_Weighted_Fair_Queueing>

---

## 4. Controle de admissão por crédito / backpressure — Kung, Blackwell & Chapman (SIGCOMM 1994)

**Princípio.** O **crédito** é a unidade de admissão. Um emissor **não transmite sem possuir crédito**
para o destino; **1 crédito = 1 slot de buffer livre** no destino. O laço se fecha quando o destino
**devolve um crédito ao drenar** (ler) uma mensagem — reabastecendo a permissão de envio conforme a
capacidade libera. É **backpressure** explícito, hop-a-hop.

**Quando se aplica.** Garantir **zero/baixa perda** sob congestionamento mantendo alta utilização —
especialmente para tráfego em rajada, onde multiplexação estatística não controlada vai mal. Limita
diretamente o número de **mensagens em voo (in-flight)** por origem.

**Parâmetros.** Crédito/buffer por circuito (VC); alocação adaptativa pode **auto-dimensionar** o
buffer conforme o uso real de banda do VC. O buffer necessário escala com `banda × RTT` (usar só o RTT
do enlace local, não o fim-a-fim, reduz muito a memória).

**Prós/limites.** Sem perda + alta utilização; o protocolo de atualização de crédito é robusto **mesmo
quando mensagens de crédito se perdem** (envia periodicamente a _contagem_ de células transmitidas, em
vez de depender de cada mensagem de crédito). **Limite:** exige estado e troca de crédito por
origem/destino; é hop-a-hop, não fim-a-fim.

**Fontes.** Kung, Blackwell & Chapman, _Credit-Based Flow Control for ATM Networks_, SIGCOMM 1994
<https://www.eecs.harvard.edu/~htk/publication/1994-sigcomm-kung-blackwell-chapman.pdf> · _Closed Loop
Credit-Based Flow Control…_ (US patent, primário)
<https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/9571402>

---

## 5. Fundamentos de teoria de filas — Lei de Little, M/M/c, utilização

**Princípio (modelo, não controlador).** Liga taxa, ocupação e atraso.

- **Lei de Little:** `L = λW` (e `Lq = λWq`) — o número médio no sistema = taxa de chegada × tempo
  médio no sistema. Dados `λ, μ` e **qualquer um** de `{W, Wq, L, Lq}`, os demais derivam via
  `W = Wq + 1/μ`.
- **Utilização / intensidade de tráfego:** `ρ ≡ λ/(c·μ)`. **Estado estacionário só existe com `ρ < 1`**;
  em `ρ = 1` a aleatoriedade impede a fila de esvaziar e em `ρ > 1` as chegadas excedem a capacidade.
- **M/M/c:** chegada `λ` constante, capacidade total `c·μ` limitada pelo nº de servidores em uso.
  Para G/G/c, `P(servidor ocupado) = ρ`.

**Por que importa aqui.** É a régua para responder "quanta capacidade/quantos servidores para um
nível de serviço-alvo" e para entender por que um sistema perto de `ρ=1` fica instável (filas
explodem). _Consenso._

**Fonte.** Carnegie Mellon 14-740, _Queueing Theory_ (notas de aula, primário)
<https://www.andrew.cmu.edu/course/14-740-s18/applications/ln/14740-l16.pdf>

---

## 6. Controle em malha fechada aplicado a filas — PI/PID (PIE) e AIMD (TCP)

### 6a. Controlador Proporcional-Integral em AQM — PIE (RFC 8033)

**Princípio.** Aplica o **clássico controlador PI** à gestão de fila: atualiza periodicamente uma
**probabilidade de descarte** com base no **erro** entre o atraso atual e uma **referência-alvo** e na
**tendência** (variação) do atraso. O PI é conhecido por **eliminar erro de regime permanente**.

**Lei de controle (verbatim da RFC):**
`p = α·(qdelay_atual − QDELAY_REF) + β·(qdelay_atual − qdelay_anterior)`
com `QDELAY_REF` padrão **15 ms**; `α` (proporcional ao erro) e `β` (sobre a variação) são os ganhos
tunáveis.

**Anti-amplificação / amortecimento (diretamente relevante a "medição ruidosa"):**

- **Auto-ajuste de ganho por regime:** escala o passo de atualização pela magnitude da probabilidade
  de descarte atual — reage **menos** sob congestionamento leve e **mais** sob pesado.
- **Tolera rajadas curtas:** decai a probabilidade exponencialmente quando descongestionado e
  **não penaliza rajadas de curta duração** que excedem o alvo brevemente — evita reagir a ruído
  transiente.

**Fonte.** RFC 8033 (PIE), IETF <https://www.rfc-editor.org/rfc/rfc8033> · base teórica peer-reviewed:
Hollot, Misra, Towsley & Gong, _Analysis and Design of Controllers for AQM Routers Supporting TCP
Flows_, IEEE Trans. Automatic Control 47(6):945-959, 2002 (DOI 10.1109/tac.2002.1008360).

### 6b. AIMD — Additive Increase / Multiplicative Decrease (TCP, RFC 5681)

**Princípio.** O laço adaptativo canônico guiado por **sinal observado de sucesso/falha**: a janela
cresce **linearmente** (`+~1 segmento por RTT`) enquanto os ACKs chegam no prazo, e é **cortada
multiplicativamente** ao detectar perda/congestionamento. **A perda é o sinal de realimentação** — o
TCP controla a **saída** (load offered), não só a entrada. ✔️ *Mecânica verificada contra a RFC 5681:
incremento `cwnd += SMSS*SMSS/cwnd`; na perda `ssthresh = max(FlightSize/2, 2*SMSS)`; "os algoritmos…
usam perda como o sinal de congestionamento".*

**Clamp/amortecimento.** Na perda, _multiplicative decrease_ (corta ~pela metade via `ssthresh`) —
uma resposta de **clamp** que impede o laço de amplificar sob sinal adverso.

> ⚠️ **Correção de atribuição (achado da verificação adversarial — afirmação REFUTADA 2/3).** A
> propriedade de **convergência para fração justa (igual)** entre múltiplos fluxos **NÃO está na RFC
> 5681** (a RFC não contém as palavras "fair/fairness/converge"; descreve o comportamento de um único
> emissor). Essa propriedade é resultado **de Chiu & Jain (1989)**, citado pela própria RFC apenas como
> background `[CJ89]`. Além disso, a string **"AIMD" não aparece** na RFC 5681 — ela especifica a
> mecânica _additive-increase/multiplicative-decrease_, não o nome nem o equilíbrio. **Atribuir a
> fairness à RFC 5681 era _paraphrase drift_.** Atribuição correta: **mecânica → RFC 5681; convergência
> à justiça/eficiência → Chiu & Jain 1989.**

**Fontes.** Mecânica: **RFC 5681** (TCP Congestion Control, §3.1)
<https://www.rfc-editor.org/rfc/rfc5681.txt> · Convergência à justiça: **Chiu & Jain (1989)**,
_Analysis of the Increase and Decrease Algorithms for Congestion Avoidance in Computer Networks_,
Computer Networks and ISDN Systems · panorama: TCP congestion control (Wikipedia, secundária)
<https://en.wikipedia.org/wiki/TCP_congestion_control>.

> **Princípio de projeto que emerge de 6a+6b:** ganho **adaptativo ao regime** + **clamp/decaimento**
>
> - **tolerância a transientes** são as defesas canônicas contra amplificação por medição ruidosa.
>   O termo de engenharia para a patologia que se evita (integrador acumulando durante saturação) é
>   **anti-windup** — citado na pergunta; é prática consolidada em controle PI/PID, embora as fontes
>   deste run o tenham tratado indiretamente (via auto-ajuste de ganho do PIE), não como item próprio.

---

## 7. Pesquisa operacional — política (s,S), base-stock e newsvendor

**Princípio.** "Quanto liberar para garantir um nível de serviço-alvo." A teoria de reposição de
estoque é o análogo formal mais próximo de **dosar saída** sob demanda incerta.

- **(s,S) — Scarf (1960).** Para o problema dinâmico de estoque com **custo fixo de pedido `K>0`** e
  sem restrição de capacidade, a política **(s,S)** é **ótima** em horizonte finito: quando o estoque
  cai a `≤ s`, pede-se até `S`; senão, não faz nada. `S` minimiza a função de custo `G_t(y)`; `s` é a
  raiz menor onde `K + G_t(S) = G_t(s)`. A prova usa **K-convexidade**.
- **Base-stock como caso de `K=0`.** Quando o custo fixo `K=0`, a política (s,S) **degenera em
  base-stock** (order-up-to-S contínuo). Iglehart (1963) estendeu o resultado ao horizonte infinito.
- **Newsvendor.** O nível base-stock de período único é o **newsvendor com fração crítica**
  (_critical fractile_). ✔️ _Verificado contra fonte aberta (de Treville, HEC Lausanne):_ a quantidade
  ótima é o quantil da demanda dado pela razão crítica
  **`F(Q*) = Cu/(Cu+Co)`**, ou seja `Q* = F⁻¹(Cu/(Cu+Co))`, onde `F` é a CDF da demanda, `Cu` = custo
  de **falta** (margem perdida na ruptura, `Cu = p − c`) e `Co` = custo de **excesso** (perda no item
  não vendido, `Co = c − s`). A regra de parada: aumentar `Q` até o ganho marginal esperado
  `(1−F(Q))·Cu` igualar o custo marginal esperado `F(Q)·Co`. **O nível de serviço que maximiza lucro é
  exatamente a fração crítica.** _(O PDF original UT Dallas deu erro de TLS; usada a alternativa aberta
  de Treville, qualidade secundária — slides de curso, derivação verbatim.)_

**Quando se aplica.** Decidir **lotes/quanto admitir** mirando um nível de serviço (probabilidade de
não faltar), sob demanda estocástica. Mapeia bem a "garantir piso de SAÍDA".

**Prós/limites.** Ótimo sob hipóteses do modelo (custos lineares, K-convexidade); o "fixed cost K"
é o que justifica **limiar** (s,S) vs. reposição contínua. _Consenso_ na literatura de OR.

**Fontes.** Scarf (1960), _The Optimality of (S,s) Policies…_
<https://www.researchgate.net/publication/243780031> · Newsvendor / fração crítica (de Treville, HEC
Lausanne — alternativa aberta verificada) <https://oplab.ch/content/slides2.pdf>.

---

## 8. Paralelo formal — dosagem farmacológica em malha fechada (TCI)

> **Gap fechado.** As URLs originais (ScienceDirect/BJA) deram **403** (bloqueio anti-bot/paywall).
> Substituídas por **fontes abertas peer-reviewed equivalentes** (PubMed/PMC), de onde se extraíram as
> afirmações abaixo com citação verbatim.

**Princípio (verificado).** O _target-controlled infusion_ (TCI) mira uma **concentração-alvo** do
fármaco; a **malha fechada** acrescenta realimentação: titula a dose automaticamente pela **medida do
efeito**. O sinal de realimentação canônico é o **BIS (Bispectral Index)**, medida do EEG da
profundidade anestésica, tipicamente mantido entre **40 e 60** na manutenção.

**Arquitetura do controlador (verificado, Absalom/Sutcliffe/Kenny, Anesthesiology 2002).** Um sistema
de malha fechada foi construído usando **"BIS como variável de controle, um algoritmo de controle
proporcional-integral-diferencial (PID) e uma infusão de propofol por TCI como atuador"** — ou seja,
**PID + sinal de efeito (BIS) + TCI como atuador de dose**. O controlador manteve o BIS próximo do
_set point_ (erro absoluto mediano ~8%).

**Evidência vs. controle manual (verificado, meta-análise de RCTs, PMC7850716).** Comparado ao controle
manual (malha aberta), a entrega em malha fechada guiada por BIS **reduziu significativamente a dose de
propofol** (MD −0,62; IC95% −1,08 a −0,16; p=0,008) e reduziu eventos adversos — base de **8 RCTs / 879
casos** (450 malha fechada, 429 malha aberta).

**Paralelo (descritivo).** É o análogo biomédico mais limpo de "ajustar a **dose** pela **resposta
observada**" com um atuador que mira um alvo (TCI≈"quanto liberar") e um laço que corrige pela medida —
exatamente a estrutura _atuador-alvo + realimentação por resultado_.

**Fontes (alternativas abertas usadas).** Absalom, Sutcliffe & Kenny (2002), closed-loop c/ BIS+PID+TCI
— PubMed <https://pubmed.ncbi.nlm.nih.gov/11753004/> · revisão sistemática + meta-análise de malha
fechada sob BIS — PMC <https://pmc.ncbi.nlm.nih.gov/articles/PMC7850716/>. _(Originais bloqueados:
Absalom 2003 ScienceDirect S0169260703001639; BJA review — ambos 403.)_

---

## Paralelo neutro com a necessidade (SLOT → pasta), sem prescrever solução

A fila da RHILO distribui **SLOTs (chamadas)** a escritórios, mas o objetivo é a cota de **RESULTADO
(pastas materializadas)**; a materialização depende de sistema externo com **conversão variável e
ruidosa** por nível/firma. Onde a literatura acima toca essa necessidade — em termos **descritivos**:

| Necessidade declarada                                                            | Conceito(s) da literatura que descrevem o mesmo problema                                                                                                                                                                                                                                              |
| -------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| "Controlar a fila pela **taxa de sucesso/conversão observada**"                  | Malha fechada por sinal de resultado: **AIMD** (perda = sinal; controla a saída) e **PI/PIE** (erro vs. referência). A literatura controla por um **sinal a jusante**, não só pela entrada.                                                                                                           |
| "Garantir **piso de SAÍDA** (outcome), não de entrada"                           | **GPS** garante piso de serviço por fluxo independente da demanda alheia; **newsvendor/base-stock** decidem "quanto liberar" para um **nível de serviço-alvo** (probabilidade de atingir a saída).                                                                                                    |
| "Teto de SLOTs em voo por firma = `ceil(1/conversão)`; **crédito de in-flight**" | **Crédito/backpressure** (Kung): crédito = unidade que **limita o in-flight** por origem; laço fecha ao **drenar**. Token bucket: crédito acumulado limita admissão.                                                                                                                                  |
| "Ganho **∝ 1/conversão** + amostra pequena/ruidosa → risco de amplificar"        | **Achado central deste run (Bennett & Zhang):** com serviço oscilante, **alongar a janela de medição NÃO reduz o ruído de forma confiável**. Logo, ganho proporcional a `1/conversão` com poucas amostras é exatamente o regime que a literatura de controle marca como **propenso a instabilidade**. |
| "**Amortecimento/clamp/anti-windup** contra medição ruidosa"                     | **PIE**: ganho **auto-ajustado por regime** + **decaimento** + **tolerância a rajadas curtas**. **AIMD**: **multiplicative decrease** como clamp. **Anti-windup**: prática consolidada de controle PI/PID (limitar a ação integral em saturação).                                                     |
| "Pisos/tetos por nível"                                                          | **(s,S)**: limiares inferior (`s`) e superior (`S`); **token bucket**: CBS/EBS como tetos de rajada; **DRR/GPS**: pesos `φ_i`/quanta como pisos proporcionais por grupo.                                                                                                                              |

**O que a literatura sinaliza como ponto de atenção (sem prescrever):** um ganho `∝ 1/conversão` com
conversão **baixa e ruidosa** = **ganho alto sobre sinal ruidoso**, a combinação que controle clássico
amortece com (i) ganho adaptativo ao regime, (ii) clamp/saturação, (iii) anti-windup e (iv)
filtragem/tolerância a transientes — **e que NÃO se resolve só aumentando o tamanho da amostra** quando
o serviço subjacente oscila.

---

## Acoplamento operacional — o custo de RODAR o laço (não-neutro)

> As seções acima são "paralelo neutro": tratam cada técnica como uma **função matemática isolada**.
> Mas a dose **não roda no vácuo** — ela roda dentro de um sistema que já quebrou em produção (88MB
> TOAST → 503; sync acumulando). Esta seção fecha a transição **"paralelo neutro" → "restrição de
> projeto"**: o mesmo princípio de controle reaparece em **quatro laços reais do código**, e em todos
> falta a guarda que a literatura prescreve. Verificado por 4 explorações read-only do código
> (rhilo-metagamify + rhilo-app), 2026-06-24.

**A tese unificadora:** todo laço que **realimenta** (dose), **acumula estado** (snapshot) ou
**re-tenta** (sync/eventos) precisa de uma **guarda** — clamp, estado-mínimo, cap-de-profundidade,
dead-letter/anti-windup. Um laço de **alto ganho sobre sinal/estado sem amortecimento** é a patologia
canônica que controle clássico resolve. Hoje os quatro laços rodam **sem** essa guarda.

| Laço                                                             | Onde (arquivo:linha)                                                                                                                                                                                                                                                                                                                                                                                                                                                                    | Patologia                                                                                                                                                     | Guarda que a literatura prescreve                                                                                                                                                                                                                           |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Motor de eventos BullMQ** _(o mais provável de "travar tudo")_ | 7 filas ativas em prod, workers sobem no boot `apps/api/src/main.ts:312-335` **sem flag de kill**; `event-processing`/`notification` concorrência **10**, **no mesmo processo da API** (container 0.5vCPU/1GB); cascata `ELEMENT_EARNED` **sem cap de profundidade** (`element-assigner.service.ts:153` — recompensas têm cap 3, eventos **não**); **sem dead-letter** (failed lingam 7d); Bull Board off em prod = **sem visibilidade**; `WRRComparator` definido mas **nunca ligado** | Workers saturam CPU/conn-pool → `getNext`/admin enfileiram atrás → **503**. Cascata recursiva = **amplificação ilimitada**                                    | **§4 Crédito/backpressure (Kung):** isolar/creditar o recurso para o efeito-colateral **não faminta o plano de servir**; **cap de profundidade** = limite de laço                                                                                           |
| **Dose** (matemática do teto)                                    | `apps/api/src/wrr/conversion/estimator.ts:174` `deriveDoseMaxByLevel = ceil(1/conv)` — **SEM CLAMP** (só o schema garante ≥1). Conversão medida sem filtro numérico; `minCalls=10` é **guarda de amostra**, não amortecimento                                                                                                                                                                                                                                                           | Ganho `∝ 1/conv` sobre conversão **ruidosa**, recalculado a cada `getNext`, cache 5 min → explode níveis de baixa conversão (MESTRE/CHAMPION por ruído-Urano) | **§3 WF²Q** (alongar janela **não** tira o ruído) + **§6a PIE** (clamp + ganho adaptativo ao regime + tolerar transiente) + anti-windup                                                                                                                     |
| **Snapshots de decisão** (estado)                                | `WRRSelectionDecision`: 1 row por `getNext` (~947/dia), `candidateContext` ~90KB (**94% do peso**). Retenção §R1/R2/R3 **implementada** (commit be8a886) mas **DESLIGADA** por padrão (`WRR_DECISION_CONTEXT_RETENTION_DAYS` ausente = no-op)                                                                                                                                                                                                                                           | Estado de observabilidade do laço **sem limite** → TOAST 88MB → 503 sob carga (`wrr-decisions.routes.ts` listando payloads grandes + container pequeno)       | **§4 Crédito/backpressure (Kung):** **estado mínimo é requisito de projeto** ("usar RTT local, não fim-a-fim → muito menos memória"). A dose **aumenta** o valor de auditar o snapshot (por que C1 excluiu X) — logo a poda vira pré-condição, não opcional |
| **Sync / Outbox** (retry)                                        | `rhilo-app .../shared/outbox/outbox.processor.ts`: eventos FAILED **"kept indefinitely"** (alerta só se >10); fila `METAGAMIFY_SYNC` 5 retries exp. Casa com o sync blind-spot conhecido (mg-create-participant falha 5× e some)                                                                                                                                                                                                                                                        | Acúmulo de retry **sem teto/dead-letter eficaz** = **windup** (o integrador satura)                                                                           | **§6b AIMD / anti-windup:** backoff multiplicativo (já há) **+ teto + dead-letter** para drenar o acúmulo                                                                                                                                                   |

### Duas correções de premissa (o que NÃO é o culpado)

1. **Os alertas não travam nada.** O feed de alertas (`wrr/alerts/alerts.aggregator.ts` — 5 triggers:
   Gini, saturação de nível, risco de floor, override expirando, monopólio/I-1) é **on-read, cache 60s,
   query-only**. Sem fila, sem CRON, sem listener que reaja. Risco de "alert storm" ≈ 0. Se algo
   "travou", **não foi o feed de alertas.**
2. **Não existe CRON de burst-control reescrevendo overrides.** Overrides (cap/floor) são **100%
   manuais** (CRUD com confirmação na UI). `grep @Cron` no rhilo-app retorna apenas o outbox
   (30s/2min/5min/3AM) e `fix-orphan-actions` (5min, reparo de ações AT — não-relacionado). **Zero**
   ocorrências de `burst`. _(Isto corrige uma anotação anterior que atribuía a pilha de overrides a um
   CRON automático.)_

### Guardas como PRÉ-CONDIÇÕES do rollout da dose

Ligar `measured_conversion` **sem** as guardas abaixo = ligar **quatro integradores sem anti-windup ao
mesmo tempo**, no mesmo container pequeno. Tratar como **bloqueadores**, não como tuning posterior:

1. **Dose:** clamp em `deriveDoseMaxByLevel` (PIE/WF²Q justificam como **defesa canônica**, não ajuste fino).
2. **Snapshot:** ligar `WRR_DECISION_CONTEXT_RETENTION_DAYS` **antes** de rodar o laço quente (machinery pronta).
3. **BullMQ:** cap de profundidade na cascata de eventos + dead-letter + kill-switch/flag por worker;
   idealmente mover workers para **fora do processo da API**.
4. **Sync:** teto + dead-letter para FAILED do outbox.

> Triagem completa de "o que travou prod" (ranqueada, com evidência por laço): ver
> [`freeze-triage-4-lacos.md`](./freeze-triage-4-lacos.md).

---

## Procedência e confiança

**Verificado adversarialmente (3 votos, ≥2 para refutar) — 18 afirmações:**

- _Run original_ (12 afirmações, **todas sobreviveram**, conf. alta): **token bucket (RFC 2697/2698)**
  e **DRR (Shreedhar-Varghese)** — técnicas 1 e 2.
- _Run de gap-fill_ `wf_27a8d66c-fcb` (7 afirmações load-bearing das técnicas 3–6 e 8): **6
  sobreviveram** (WF²Q/ruído-de-medição, GPS, crédito/backpressure, Little/M-M-c, PIE, (s,S)) e **1 foi
  REFUTADA** — a atribuição da **convergência-à-justiça do AIMD** à RFC 5681 (correta é **Chiu & Jain
  1989**; a mecânica permanece corretamente na RFC 5681). Correção já aplicada na §6b.

**Gaps fechados** (originais bloqueados por 403/TLS; usadas alternativas abertas peer-reviewed,
qualidade indicada na seção): **newsvendor/fração crítica** (de Treville/HEC, §7) e **TCI farmacológico
em malha fechada** (Absalom 2002 + meta-análise PMC, §8) — ambos com citação verbatim.

**Não verificado pelo gate:** demais afirmações _supporting/tangential_ das técnicas 3–8 permanecem
"extraído de fonte primária com quote", sem os 3 votos.

**Consenso vs. debatido:** tudo marcado "✔️" é verificado/consenso; o **ponto debatido** é a divergência
WFQ↔GPS (resolvida por WF²Q) — fonte do achado-chave sobre **ruído de medição**. O **ponto corrigido**
é a atribuição do AIMD (mecânica RFC 5681 ✔️ / fairness Chiu-Jain).

**Runs de origem:** `wf_cf08362b-a14` (deep-research: Scope→Search 5 ângulos→Fetch 22 fontes/~80
afirmações→Verify ~12) + `wf_27a8d66c-fcb` (gap-fill: 24 agentes, 3 re-fetch + 21 votos). Síntese
reconstruída e enriquecida em 2026-06-24.
