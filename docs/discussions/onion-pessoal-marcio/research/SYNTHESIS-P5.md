# Síntese de pesquisa P5 — Mitigação de inferência (Onion pessoal)

> Data: 2026-07-12 · Branch `discuss/onion-pessoal-marcio` · 3 dimensões verificadas
> (ataques+defesas de inferência · enforcement query/output · defesas arquiteturais+cripto)
> · ~40 fontes primárias, cada dimensão passou por verificação adversarial · Âncoras:
> **Aristóteles** (a régua: igual→transfere / diferente→desenha) + **Hegel** (o motor:
> contradição, sem telos) · **Constrói sobre a [P4](SYNTHESIS-P4.md)** — que nomeou a
> inferência como o **elo sem cifra** (gap #1). A P5 desenha a mitigação — ou prova, com
> honestidade, que ela é só **parcial**.
>
> **Convenção de rebaixamento:** cada claim leva `[conf X.X]`. Onde a verificação adversarial
> cortou, inflou ou não-confirmou algo, o corte aparece inline com **⤓ rebaixa:** — nunca escondido.

---

## 0. Sumário executivo (o veredito de design)

1. **A P4 estava certa e o estado-da-arte de 2026 a endurece:** contra a inferência do próprio
   motor **não existe cifra nem defesa completa** — só mitigação parcial, sempre com custo de
   utilidade, sempre quebrável por atacante mais forte ou adaptativo. [conf 0.9]
2. **A verdade governante, agora com prova empírica:** para o **usuário legítimo** (a própria
   pessoa), a inferência **é a feature** — é o valor do cérebro pessoal. Deng et al. (2026) mede:
   conforto 3.75/5 quando a inferência serve o dono vs 2.34/5 quando vai a terceiros; o "creepy
   corner" (intrusivo+surpreendente) despenca a 1.74/5. **O perigo é o cruzamento da fronteira,
   não a dedução.** [conf 0.85]
3. **Logo a mitigação NÃO é impedir o motor de inferir** — capar o raciocínio destrói a feature
   (relação inversa explícita: mais privacidade → menos capacidade). A mitigação é **governar a
   fronteira de saída e o escopo de cada consulta.**
4. **Onde a defesa é desenhável, ela é NEGATIVA e em camadas:** acesso-mínimo (só o schema/só a
   fatia da vertical que o propósito exige) + propósito-vinculado + filtro-de-saída-por-composição
   + juiz-de-CI separado do motor + ε-ledger. Cada camada reduz o vazamento **literal e por-composição** —
   nenhuma zera a inferência de conclusão nova.
5. **Regra-mãe atravessando tudo:** como o motor É local mas ainda infere, **a defesa começa no
   ACESSO** (não dar o material de que a dedução precisa) — porque a **saída não consegue filtrar
   uma conclusão que nunca foi string.**
6. **O irredutível:** a inferência do motor legítimo sobre o próprio grafo, para o dono, **não se
   impede** — nenhum paper trata essa topologia. Declarar o Onion pessoal "privado via ofuscação"
   seria falsa distinção às avessas. Só se pode garantir **não-EMISSÃO** (o destilado não cruza) e
   **fronteira de acesso** — a inferência interna permanece indefesa **por construção**, e isso é
   limite fundamental, não bug a corrigir.

---

## 1. Ataques e defesas de inferência — o que reduz de fato vs mascaramento de PII

O achado transversal mais forte, e o mais duro: **scrubbing de PII é comprovadamente insuficiente.**
Após filtro NER + filtro LLM de self-disclosure (todo PII literal removido), um Llama-3.3-70B
off-the-shelf recuperou idade/gênero/país com F1 ponderado 0.84/0.90/0.88 — a inferência opera sobre
**estilo e tópico** que o filtro nunca toca. [conf 0.88 · verificação: **confirmado**, números batem
com a fonte, estudo de 1.057 usuários]. Isto é a prova empírica dos gaps #1/#2 da P4: o
`de-identification` (regex/NER) do Onion **não protege** um life-KG; a redação tem de ser
*whole-graph aware*, não migalha-a-migalha.

O que cada família de defesa **de fato** entrega — e onde para:

| Família | Reduz? | Custo / limite honesto | Verificação |
|---|---|---|---|
| **FgAA** — anonimização adversarial (LLM-atacante guia o anonimizador; supera Azure em utilidade+privacidade) | **reduz, não zera** | depende de atacante GPT-4-class; padrão empírico, **não teorema** [conf 0.9] | **confirmado** — caveats honestos, sem overstatement |
| **INTACT** — sanitização verdadeira guiada por ataque | ganho **modesto** | re-id residual ~10.9% vs ~8.7% da supressão total; utilidade 0.88 vs 0.92; recai a rótulo genérico em 22%; ataque custa 15–20× o compute da geração [conf 0.83] | **confirmado** ⤓ **rebaixa:** a P5-fonte disse "8.5%" de supressão; o paper diz **8.7%** (nit de arredondamento) |
| **TRACE-RPS** — perturbação proativa orientada a recusa | 50%→<5% em modelos open | exige **white-box aos logits**; cai a ~45% em modelos fechados (GPT/Gemini) [conf 0.82] | **plausível** ⤓ **rebaixa:** a sub-claim "parcialmente revertida por *suffix-dropping* adaptativo" **NÃO foi verificável** (apêndice inacessível) — tratar como inferência não-confirmada, possivelmente inflada. As três métricas principais checam |
| **DP** (atributo) | protege *membership*, **não** correlação | inferência de atributo é essencialmente **imputação**: baseline ingênuo (valor mais comum) bate 3 ataques SOTA [conf 0.85] | **confirmado** ⤓ **nuance:** o mesmo paper mostra que um ataque white-box de ativação **supera** imputação em regime *data-constrained* — há sinal residual que DP tocaria; mas a tese central (correlação populacional não é o que DP previne) mantém |
| **DP-GNN** (GAP, node-level DP) — forma-KG | mitigação com custo | perturbar embedding/aresta **não impede** link/attribute inference; queda material de acurácia [conf 0.72] | (não re-verificado no passe adversarial) |
| **k-anonymity / l-diversity / t-closeness** | **falha em grafo denso** | composição não preserva k; quase-identificadores estruturais (grau/vizinhança) re-identificam; maldição da dimensionalidade → cada nó quase-único [conf 0.8] | **confirmado** — síntese fiel de resultados canônicos (Ganta 2008, Narayanan-Shmatikov 2009, Aggarwal 2005) |

**O veredito da dimensão, declarado na literatura de 2025 como IRRECONCILIÁVEL** [conf 0.8, confirmado]:
raciocínio rico e minimização de superfície de inferência conflitam diretamente — não se maximiza
raciocínio e se minimiza vulnerabilidade sem degradação significativa. **Nenhuma solução completa
existe; privacidade em tempo de inferência segue fundamentalmente não-resolvida em sistemas
implantados.** Para o Onion — cujo motor É o "atacante" e cujo grafo **deve** permanecer legível —
ofuscar é auto-derrotante. A única alavanca é **não-emissão / fronteira de acesso.**

> **Onde NÃO há defesa completa:** todas — FgAA/INTACT/TRACE-RPS só reduzem e quebram sob atacante mais
> forte ou adaptativo; DP não fecha inferência por correlação e **N=1 é o pior caso** (sem multidão onde
> se esconder, correlação intra-vida densa); as defesas fortes exigem condições **indisponíveis no caso
> Onion** (white-box logits, 15–20× compute por span, atacante dedicado GPT-4-class). E a lacuna crítica:
> **toda a literatura assume defender um RELEASE** (texto/dataset/embedding publicado). O cenário do
> Onion — o próprio LLM inferindo sobre um KG que **deve continuar legível para o dono** — **não tem
> defesa publicada**, porque ofuscar o que você quer reconciliar é autocontraditório.

---

## 2. Enforcement em query/output — a fronteira runtime já tem dois lados

O estado-da-arte de 2026 já partiu o problema em **duas fronteiras runtime**, e é exatamente onde a
mitigação do Onion pessoal é desenhável.

### 2.1 Fronteira de ACESSO / consulta — *need-to-know*

- **Passar ao motor só o SCHEMA mascarado do KG, nunca os valores de instância.** **AskSafely**
  (RCIS 2026) extrai o schema, NER distingue entidade sensível (mascarada `NODE_VALUE`/`AD_HOC`) de
  entidade-chave (labels, preservadas), e só então gera NL→Cypher; **RBAC embutido** garante que a query
  nunca aponta para fora do direito de acesso. [conf 0.85 · **confirmado** verbatim]. É o exemplar quase
  perfeito para o Onion: um KG + um LLM que gera query.
- **O próprio AskSafely admite o limite** [conf 0.85 · **confirmado**]: *"não podemos garantir plenamente
  que nenhuma informação sensível seja inferida das perguntas mascaradas"*; acurácia cai em multi-hop
  (73.3% em 3-hop vs 86.9%); e **se o SCHEMA em si é sensível** (um label que revela uma condição) o método
  *"não pode ser usado por design"*. **Num KG de vida a topologia É sensível** — a existência de uma aresta
  (uma vertical de saúde, uma relação) já vaza. Logo schema-masking é **necessário mas insuficiente**:
  precisa de classificação **por-inferência** no nível de aresta/vertical, não só nos valores.
- **O controle de acesso tem de viver na CAMADA DE RECUPERAÇÃO**, não depois. Permission-aware RAG filtra
  por identidade/permissão/metadados **antes** de o conteúdo chegar ao modelo; o defeito de governança é a
  suposição de que "todo conteúdo recuperado é igualmente acessível". [conf 0.8 · **confirmado com caveat**]
  ⤓ **rebaixa:** o detalhe "funde RBAC+ABAC" é **contradito pelo próprio paper** cujo insight ("equally
  accessible") a fonte cita — esse paper **rejeita** fundir RBAC+ABAC (faz IAM em tempo real). A tese central
  (enforcement na camada de recuperação) mantém; a "fusão" é do campo, não daquele paper.
- **Agentes violam contexto por DESCUIDO, não por ataque** [conf 0.8 · **overstated**]: sobre-leem por
  default, vazam de um contexto a outro. ⤓ **rebaixa:** o AgentCIBench **não** mede "acesso quando
  desnecessário" — mede **adequação da DIVULGAÇÃO sob acesso legítimo** (o agente vê estado com itens
  requeridos+proibidos e escolhe o subconjunto); e a mitigação testada é **prompt-level** (−33 a −36pt),
  **não** "barreiras de acesso no nível de sistema" como a fonte creditou. Ainda assim descreve a topologia
  do Onion pessoal: o motor local **não é atacante — é descuidado**, e o antídoto (least-info por tarefa)
  reforça que o gate deve ser **purpose-scoped**, não "todo o grafo disponível".

### 2.2 Fronteira de SAÍDA — *output guardrails* e propósito

- **Filtro de saída de duas camadas** [conf 0.82 · **confirmado** verbatim, AUROC 0.971–0.995 in-distribution]:
  (1) regex/NER rejeita identificadores literais; (2) estimador de densidade one-class detecta **CLUSTERS de
  quase-identificadores**. Insight-mãe: *"a violação não é uma string; é uma composição de quase-identificadores"*
  (ex.: "litigante mulher de 52 anos de Omaha, dois filhos, disputa de guarda recente" re-identifica sem nenhum
  token sensível isolado). **Valida a regra-mãe da P4:** o destilado herda a sensibilidade do que permite INFERIR.
- **Mas esse mesmo filtro colapsa sob confusão de estilo** [conf 0.78 · confirmado como caveat]: AUROC
  0.94–1.00 → **0.72–0.79** em texto seguro que imita a voz do inseguro — "latia para o registro, não o
  conteúdo"; finanças mantém 36% de falso-positivo. **Métricas in-distribution escondem a fragilidade.**
  Reforça **fail-safe > fail-open**: na dúvida, **abster** (revisão humana), nunca deixar passar.
- **Contextual Integrity vira executável em runtime por raciocínio (CI-CoT/CI-RL)**: o modelo avalia, antes
  de responder, se cada atributo é necessário/útil/opcional/inapropriado de revelar; reduz vazamento **~40%**.
  [conf 0.80 · **overstated**] ⤓ **rebaixa:** o número **"ConfAIde theory-of-mind 0.80→0.30" é fabricado/
  mal-atribuído** — não aparece no paper (que reporta ConfAIde como correlações de Pearson, *maior é melhor*,
  ex. 0.58→0.67); o valor citado aponta a **direção errada**. O mecanismo, o "−40%" e o Qwen2.5-7B
  50.3%→33.7% no PrivacyLens **checam**; a recompensa é "grosseira" por keyword e o teste é só ≤14B. Transfere
  como **camada probabilística, jamais garantia** — casa com "declarado ≠ verificado".
- **Purpose limitation vira monitor de runtime — C-Trace** [conf 0.72]: expressa consentimento, limitação de
  propósito, minimização e apagamento como **predicados formais sobre o traço de execução**; um monitor
  intercepta cada chamada de ferramenta e cada saída e **rejeita a ação não-conforme**, mapeando a um traço
  tipado (data-category × purpose). É o "propósito declarado fixa o escopo" **feito executável** — e casa com
  o SDAAL (o adapter intercepta) e o fail-safe (rejeita, não degrada).
- **Separar o motor do juiz — 1-2-3 Check** [conf 0.75]: Extractor→Checker→Executor; um **juiz de privacidade
  distinto do gerador** pega o que o gerador (otimizado para ajudar) deixa passar (−18/−19pt). Lição de design:
  **o mesmo LLM não deve ser motor E porteiro** (conflito de objetivo: ajudar vs proteger).
- **IDP-Bench** [conf 0.78] mede **dado de TERCEIROS não-consentidos** — a vertical "relações/vínculo" que a P4
  marcou como sensibilidade máxima. Dá ao Onion uma régua para o modo-de-falha "dado de outros"; e o achado
  "dar ground-truth de CI melhora compliance" sugere **alimentar o motor com os níveis de classificação
  explícitos como contexto**, não deixá-lo adivinhar.

**O que ESCAPA a todo guardrail de saída** [conf 0.8 · confirmado]: inferência implícita multi-turno,
memorização de treino, e ataque de atributo que "mantém eficácia mesmo sob anonimização e DP". **O motor
que raciocina sobre o KG produz conclusões novas que nunca são strings a filtrar** — por isso a defesa não
pode ser só no fim; começa no acesso.

---

## 3. Defesas arquiteturais / cripto — cada uma protege uma fronteira DIFERENTE da nossa

O ponto duro desta dimensão: os quatro grandes arranjos estruturais protegem, **cada um, uma fronteira
diferente da que o Onion pessoal enfrenta.** Eles impedem que um modelo **externo/não-confiável**, o
**operador do host**, ou um **adversário de extração** vejam o bruto — **nenhum** impede que o motor
**legítimo e local**, agindo para o dono, deduza o dado sensível. Porque, para o dono, a inferência é a feature.

| Arranjo | Contra quem protege | Contra o motor-para-o-dono? | Verificação |
|---|---|---|---|
| **Capability-split reasoner↔store** (UUID-only KG; AskSafely: 0 tokens vazados, −71% MI, 86.9% acurácia) | modelo **externo** nunca vê o bruto | **NÃO** — o reasoner É o motor local do dono [conf 0.8] | **overstated** ⤓ **rebaixa:** AskSafely é demonstrado, mas acurácia **geral é 80.7%** (86.9% é subconjunto manual — cherry-pick leve; baseline sem-restrição 94.0%); e a metade "UUID-only KG" apoia num **blog Medium**, não em peer-review. "Maduro/demonstrado" **infla** |
| **SLM pequeno/capado** (on-device; 85–90% em domínio a 10–25% do custo) | exposição de dados + menor poder inferencial | parcial — **mas capar o motor sacrifica a feature**; serve como **menor-privilégio-por-passo** [conf 0.75] | (não re-verificado) — trade-off inverso explícito e honesto |
| **DP inference-time** (DP-Fusion token-level (ε,δ); DP-ICL) | extração por adversário via saídas | **NÃO** — não impede inferência legítima; **N=1 é o pior caso da DP** [conf 0.75] | (não re-verificado) — ancora o ε-ledger da P4 |
| **Confidential computing / GPU TEE** (Hopper roda 70B em enclave, <7% overhead) | o **operador** do host / nuvem | **NÃO — ao contrário, GARANTE a entrega** ao dono autorizado [conf 0.8] | **confirmado** — <7% é fiel ao caso 70B (workload-dependente) |
| **Machine unlearning** (a única técnica que tocaria o fato no modelo) | — | **NÃO** — imaturo E contornável [conf 0.85] | **confirmado** — supressão, não deleção; reacende com fine-tuning leve; benchmarks "não-confiáveis a ativamente enganosos" |

**Duas fundações confirmam a P4 pela raiz:**

- **A inferência explora a CAPACIDADE de raciocínio emergente, não a memorização** [conf 0.95 · **overstated**]:
  Staab et al. mostra até 85% top-1, e que *"anonimização de texto e alinhamento são atualmente ineficazes"*.
  ⤓ **rebaixa:** a frase entre aspas — publicadores "não podem despotencializar o raciocínio sem minar a
  utilidade" — **NÃO é citação real** de Staab nem do position paper; é síntese defensável **vestida de quote**.
  Os fatos-base (ineficácia de anonimização+alinhamento; risco é raciocinar, não lembrar) **confirmam**.
- **O position paper "Privacy Is Not Just Memorization!" (2025)** argumenta que memorização é ~8% da superfície
  real e que supervisão humana é "largamente ineficaz" — logo **governança de output é insuficiente sozinha**.
  [conf 0.85 · **overstated**] ⤓ **rebaixa:** a taxonomia tripartite limpa é **imposta pela fonte**; o paper
  **não** endereça DP para inferência-em-uso especificamente, e **não** afirma que "reforçar privacidade reduz
  capacidade" — essa última frase é **não-suportada** pelo source.

**A prova da conclusão dura — a fronteira é empírica** (Deng et al. 2026) [conf 0.85 · **confirmado**, todos os
números batem]: conforto por destinatário — 3.75/5 plataforma própria, 2.58 anunciantes, 2.34 terceiros;
"creepy corner" 1.74. Para o dono, inferir é feature (conforto correlaciona com utilidade ρ=0.613). **O dano
é o CRUZAMENTO.** E o controle desejado é exatamente D2: aprovação **por-destinatário/por-propósito no ponto
de TRANSMISSÃO** — em três estágios (geração, retenção, **transmissão**) — **não** impedir a dedução.

**O store também vaza por re-consulta** (GraphSteal 2026, [conf 0.6]): reconstrói conhecimento estrutural de um
Graph-RAG por traversal, **sem tocar o modelo** — o que fecha o argumento contra unlearning como solução: o fato
vive no store **re-consultável**, apagar do parâmetro não apaga do índice. A defesa tem de estar na **fronteira**,
não em apagar o fato.

---

## 4. Spec de MITIGAÇÃO (derivada)

### A tese: **feature dentro, perigo na fronteira**

A mitigação de inferência do Onion pessoal **não é uma cifra no reasoner** — não existe, e capar o motor mata a
feature. É uma **pilha de camadas na fronteira**, com a defesa começando no **acesso** (regra-mãe: a saída não
filtra o que nunca foi string). Hegel: a contradição "raciocínio rico ⊥ mínima superfície de inferência" **não se
resolve — se contorna**, movendo a defesa da REDAÇÃO INTERNA para a FRONTEIRA DE SAÍDA. Não há síntese que dissolva
a tensão; há um deslocamento do lugar onde ela é gerida.

### As camadas que de fato ajudam (escopo-de-consulta + governança-de-saída + budget)

| Camada | Mecanismo (fonte) | O que reduz | O que NÃO fecha |
|---|---|---|---|
| **L1 — Escopo de consulta** | schema-masking + fatia-da-vertical por propósito (AskSafely); permission-aware retrieval | dá ao motor **só o material que o propósito exige** | inferência sobre o que foi legitimamente liberado; topologia sensível |
| **L2 — Propósito vinculado** | monitor de traço tipado data-category×purpose (C-Trace); purpose = "identidade" ABAC no N=1 | rejeita ação/saída **fora do propósito declarado** | inferência **dentro** de um propósito permitido (saúde deduzida de dados de carreira liberados p/ "coaching") |
| **L3 — Filtro de saída por composição** | Camada-2 QI-cluster (density estimator) + CI-CoT | vazamento **por-composição** e literal | conclusão nova nunca-string; colapsa sob confusão de estilo |
| **L4 — Juiz-de-CI separado** | gerador ≠ porteiro (1-2-3 Check); subagente juiz no fan-out | o que o gerador otimizado-para-ajudar deixa passar | é probabilístico (−18/−19pt, não zero); regras por-vertical handcrafted |
| **L5 — Self-red-team** | rodar o **próprio motor como atacante** contra o destilado antes do release (doutrina FgAA); se deduz o oculto, **não emite** | vazamento detectável **pré-emissão** | atacante mais forte que o self-red-team; custo de compute |
| **L6 — ε-ledger de composição** | débito monotônico por release (DP-Fusion/DP-ICL ancoram o mecanismo) | **reconstrução do grafo por repetição** no tempo | N=1 é o pior caso — garantia degrada, custo de utilidade morde forte |

### O que o Onion JÁ tem que se REAPROVEITA — régua Aristóteles

| Peça Onion existente | Encaixe na spec P5 | IGUAL / DIFERENTE |
|---|---|---|
| **`query-gate`** (gate de consulta) | base do **L1** — mas hoje recupera "tudo disponível"; AskSafely mostra recuperar o **mínimo** | **IGUAL** como gesto / **DIFERENTE** — falta o schema-masking + fatia-por-propósito |
| **`responder-gated`** (resposta gated) | é o **L4** — o padrão gerador≠porteiro já está na doutrina; falta o **juiz-de-CI** como subagente separado no fan-out | **IGUAL** (padrão) / **DIFERENTE** (o juiz de CI é peça nova) |
| **`de-identification`** (SDAAL, `none` fail-safe) | entra no **L3**, mas só pega **formato-fixo por regex**; scrubbing é comprovadamente insuficiente (F1 0.84–0.90) | **IGUAL** (transporte need-to-know) / **DIFERENTE** — precisa Camada-2 por-composição, whole-graph-aware |
| **`verify-before-act`** | é o **L2/L5** — o monitor de propósito que intercepta antes de agir (C-Trace) e o self-red-team ("veredito como hipótese a verificar") | **IGUAL** — já é a postura; C-Trace dá o nome externo |
| **ε-budget (nomeado na P4)** | é o **L6** — DP-Fusion/DP-ICL dão o mecanismo concreto | **IGUAL** (a P4 já pediu) / **DIFERENTE** — N=1 não tem tratamento publicado |
| **fail-safe `none` / abstain** | atravessa L3/L4 — o "abster para revisão humana" dos guardrails **é** o `none` fail-safe | **IGUAL** — mesmo gesto (recusar, não degradar) |
| **`exposes:` allow-list + níveis RFC-0003** | aplicados **no adapter de recuperação** (L1), não pós-hoc = permission-aware retrieval | **IGUAL** — já é a postura, agora com nome externo |
| **disclosure-como-predicado** (SD-JWT/BBS/ZKP, P3) | o release do L5/L6 sai como **predicado provado**, não payload | **DIFERENTE / novo** — a arquitetura não o entrega; peça a desenhar |

**Desenhar fresco (DIFERENTE — não há peça Onion hoje):** (a) o gate query-scoped com schema-masking /
fatia-por-propósito; (b) purpose-binding **tipado** (cada consulta carrega propósito que fixa
vertical×nível×o-que-pode-inferir); (c) filtro de saída Camada-2 por composição com **taxonomia de QI por
vertical**; (d) o **juiz-de-CI** separado do motor; (e) rótulo/taint de fluxo (IFC estilo CaMeL; GIF com
soundness Lean4 local) — **horizonte, não pronto** ("explosão de rótulos", exige gradiente, só soundness local).

### O que continua IRREDUTÍVEL

**A inferência pelo usuário legítimo não se impede.** Não há paper que trate o motor confiável inferindo,
para o dono, sobre um KG que **deve** permanecer legível. Todo o corpus (capability-split, DP, TEE, unlearning,
defesas proativas) assume um adversário, um operador não-confiável, ou um modelo externo. **Essa é exatamente a
topologia do Onion pessoal e ela não tem defesa publicada.** A P4 estava certa: o gap é **nomeado, não
resolvido**. A honestidade obriga: o Onion pessoal **não pode ser declarado à prova de inferência** — só pode
garantir **não-EMISSÃO** (o destilado não cruza a fronteira) e **fronteira de acesso**. A inferência interna é
indefesa **por construção**, e isso é a feature.

---

## 5. Decisões de design ABERTAS

1. **Taxonomia de QI por vertical:** o filtro de composição (L3) é **domínio-dependente** — cada vertical do
   life-KG (saúde, relações, finanças, `ipse`) precisa da sua taxonomia de quase-identificadores, handcrafted.
   Quem a mantém, e como evita o 36% de falso-positivo visto em finanças?
2. **Granularidade do purpose-binding:** um propósito muito largo ("coaching de carreira") **legitimamente
   libera** dados de que o motor infere saúde. Quão fino o propósito precisa ser para o L2 morder — e a que
   custo de usabilidade para o dono?
3. **ε-ledger em N=1:** não há tratamento publicado de DP para KG pessoal N=1. O budget é por-destinatário?
   por-vertical? global? Reset quando? Sem agregado onde se esconder, qual ε ainda preserva utilidade?
4. **Custo do self-red-team (L5):** rodar o próprio motor como atacante antes de cada release é caro
   (INTACT: ataque custa 15–20× a geração). Roda por-release? por-destinatário? Amostrado?
5. **O juiz-de-CI (L4) usa o mesmo modelo ou um SLM capado?** Um SLM infere menos (bom p/ porteiro) mas erra
   mais o julgamento fino. Trade-off aberto.
6. **SSOT único ausente:** ninguém integrou "classificação por pior-caso-de-inferência" + "gate
   por-destinatário/propósito" + "ε-ledger" num só mecanismo executável para um life-KG lido pelo próprio LLM.
   **É engenharia a desenhar, não achado a citar.**

---

## 6. Ameaças à validade / o que a verificação derrubou

### 6.1 O que a verificação adversarial cortou (rebaixamentos, por dimensão)

- **D1 (ataques+defesas):** 5 claims **confirmadas**, 1 **plausível**. Derrubado: a reversão de TRACE-RPS por
  *suffix-dropping* adaptativo é **não-verificável** (apêndice inacessível) — possivelmente inflada. Nit: INTACT
  supressão re-id é **8.7%**, não 8.5%. As defesas **não** foram super-vendidas — cada uma declara seu limite.
- **D2 (enforcement query/output):** 3 confirmadas, 1 com caveat, **2 overstated**. Derrubado: (i) o número
  **"ConfAIde 0.80→0.30" do CI-RL é fabricado/mal-atribuído** e aponta a direção errada — **descartar**; o
  mecanismo e o −40%/Qwen mantêm. (ii) O **AgentCIBench** foi mal-caracterizado (mede divulgação sob acesso
  legítimo, não acesso-desnecessário) e creditado com "barreiras de sistema" que o paper **não propõe**
  (defesas prompt-level). (iii) "funde RBAC+ABAC" é contradito pelo paper que a fonte cita.
- **D3 (arquitetura+cripto):** 3 confirmadas, **3 overstated**, 0 refutadas. Derrubado: (i) a "citação" de Staab
  ("não podem despotencializar o raciocínio…") **não é quote real** — é síntese vestida de aspas. (ii) O position
  paper **não** afirma "reforçar privacidade reduz capacidade" nem endereça DP para inferência-em-uso. (iii)
  "maduro/demonstrado" do capability-split infla — metade apoia num blog Medium; AskSafely é 80.7% geral (86.9% é
  subconjunto manual). **Padrão dos overstatements:** uma métrica/citação precisa fabricada, aparafusada a um
  achado sólido — a retrieval factual das fontes é forte; a inflação está no editorializar e na generalização.

### 6.2 Caveat intra-órbita herdado

**Inalterado desde P1 §11 / P3 §6 / P4 §5:** o Onion pessoal do Marcio é o **centro da órbita** — prova de mercado
**zero** (`Q_COLD_ADOPTER`). A P5 decide o *mecanismo de mitigação*; **não** move o north-star. É dogfood legítimo
do método (rodar o próprio motor como atacante É a doutrina de dogfood aplicada à privacidade), não evidência de
pull externo.

### 6.3 A honestidade dura — a inferência NÃO tem defesa completa

Não vou inventar solução. **A inferência do motor legítimo, local, sobre o próprio grafo, para o dono, não tem
defesa publicada e não se impede.** Todas as defesas fortes pressupõem um cenário de RELEASE (texto/embedding
publicado) ou um adversário externo/operador — não o dono lendo o próprio KG. Ofuscar o que se quer reconciliar é
autocontraditório: **o único freio de inferência conhecido é NEGATIVO — não dar ao motor o material de que a
dedução precisa** — e ele colide de frente com a utilidade que se quer de um cérebro pessoal. O que se pode
prometer, com rigor, é: **empilhar camadas (acesso-mínimo + propósito-vinculado + filtro-de-composição +
juiz-separado + self-red-team + ε-ledger) que reduzem drasticamente o vazamento literal e por-composição, e um gate
humano por-destinatário/por-propósito no ponto de transmissão.** A inferência de conclusão nova pelo motor local é
**gerenciada, não zerada.** Declarar o Onion pessoal "privado" **exige nomear esse resíduo, não escondê-lo.**

---

## Fontes

_Data: 2026-07-12. As três dimensões passaram por verificação adversarial contra fontes primárias
(veredictos e rebaixamentos incorporados acima)._

**D1 — Ataques e defesas de inferência:** Staab, Vero, Balunović, Vechev, *LLMs are Advanced Anonymizers (FgAA)*,
ICLR 2025 (arXiv 2402.13846) · *Inferential Privacy Leakage in Anonymized Conversational AI Logs*, 2026 (arXiv
2605.23820) · Jayaraman & Evans, *Are Attribute Inference Attacks Just Imputation?*, 2022 (arXiv 2209.01292) ·
*Stop Tracking Me! (TRACE-RPS)*, ICLR 2026 (arXiv 2602.11528) · *Truthful Text Sanitization Guided by Inference
Attacks (INTACT)*, 2024 (arXiv 2412.12928v2) · FPF, *The Curse of Dimensionality* (2024) + *k-anonymous social
network data* (arXiv 2407.02290) · Sajadmanesh et al., *GAP: DP-GNN* (arXiv 2210.04442) + *Network Embedding vs
Link Inference* (arXiv 2205.14440) · *Beyond Data Privacy: New Privacy Risks for LLMs* (survey, arXiv 2509.14278).

**D2 — Enforcement query/output:** *Ask Safely* (RCIS 2026, arXiv 2512.04852) · *Integrating Access Control with
RAG* (ACM SAC 2025) + *Permission-Aware RAG* (IEEE Access 2025) · *Contextual Integrity via Reasoning and RL
(CI-CoT/CI-RL)* (arXiv 2506.04245) · *Capable but Careless (AgentCIBench)* (arXiv 2606.23189) · *Privacy Policy
Enforcement Guardrails for Data-Sensitive RAG* (arXiv 2605.17034) · *Deploying Privacy Guardrails* (arXiv
2501.12456) + *Bypassing LLM Guardrails* (arXiv 2504.11168) · *Ghost in the Agent* (arXiv 2604.23374) + *GIF:
Geometric Information Flow Control* (arXiv 2606.23277) + CaMeL (review) · *Runtime Compliance Verification
(C-Trace)* (arXiv 2606.19242) + *Operationalizing Data Minimization* (ICLR 2026) · *1-2-3 Check* (arXiv
2508.07667) · *PrivaCI-Bench* (ACL 2025) + *IDP-Bench* (arXiv 2606.09908).

**D3 — Defesas arquiteturais/cripto:** Staab et al., *Beyond Memorization* (arXiv 2310.07298) + *Position: Privacy
Is Not Just Memorization!* (arXiv 2510.01645) · Rehmer, *Privacy by Architecture: UUID-only KG* (Medium, 2025) +
*Ask Safely* (arXiv 2512.04852) · Dikici et al., *Small Language Models: A Systematic Review* (Expert Systems,
Wiley, 2026) · *DP-Fusion: Token-Level DP Inference* (arXiv 2507.04531) + *DP-ICL* (arXiv 2509.13625) · *TEEs for
AI 2026* + Phala/DeepSeek GPU TEE (2025) + Red Hat confidential computing (2025) · *Unlearning Isn't Deletion*
(arXiv 2505.16831) + CMU ML Blog (2025) + *Does Unlearning Truly Remove Knowledge?* (arXiv 2505.23270) · Deng et
al., *When Are LLM Inferences Acceptable?* (arXiv 2605.10013) · *Stop Tracking Me!* (arXiv 2602.11528) + *You Only
Anonymize What Is Not Intent-Relevant* (arXiv 2601.04265) · *GraphSteal* (arXiv 2605.28645).

**Base:** P1 ([SYNTHESIS.md](SYNTHESIS.md)) · P2 ([SYNTHESIS-P2.md](SYNTHESIS-P2.md)) · P3
([SYNTHESIS-P3.md](SYNTHESIS-P3.md)) · **P4 ([SYNTHESIS-P4.md](SYNTHESIS-P4.md)) — a inferência = elo sem cifra.**
