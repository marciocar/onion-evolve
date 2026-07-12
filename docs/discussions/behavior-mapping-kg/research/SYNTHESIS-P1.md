---
title: "Síntese P1 — Mapeamento consentido de comportamento vs. vigilância (nota ética)"
category: research-synthesis
responde: "SEED.md — pergunta 1 (ética/legal)"
data: "2026-07-12"
branch: "discuss/behavior-mapping-kg"
fontes_verificadas: 34
metodo: "pesquisa orquestrada em 4 frentes + verificação adversarial na frente 3; 3 frentes re-executadas (ver nota)"
---

# Síntese P1 — Mapeamento consentido de comportamento/atividade vs. vigilância

> **Nota de honestidade metodológica (carimbo: hoje = 2026-07-12).** A 1ª orquestração
> (ferramenta Workflow, 4 workers `research-agent` com schema forçado) rendeu **só 1 frente
> robusta** — *fronteira da vigilância* (15 claims, verificados adversarialmente). As outras 3
> devolveram stub de teste ou estouraram o retry-cap do StructuredOutput. As frentes 1
> (process mining), 2 (consentimento) e 4 (inferência) foram **re-executadas** como agentes
> `general-purpose` diretos, com WebSearch real e sem schema rígido. Datas de fontes são
> reproduzidas como fornecidas; **s/d** = sem data visível. Números de mercado/efeito-inibidor
> sofreram correções na verificação (§ Correções) — **não** os trate como consenso fechado.

---

## 1. Process/Task mining — a disciplina legítima (mapear ≠ vigiar já é canônico nela)

Process mining nasceu formalizado no *Process Mining Manifesto* da IEEE Task Force (2011), que o
define como o campo entre data mining e modelagem de processos cujo objetivo é "descobrir,
monitorar e melhorar processos reais extraindo conhecimento de event logs" — três tipos:
descoberta, conformidade, enriquecimento. A distinção de granularidade importa para um sensor de
comportamento: **process mining** lê event logs do sistema amarrados a um "caso" (a visão de
pássaro do fluxo end-to-end); **task/desktop mining** lê a interação na estação (cliques, teclas,
troca de app) — a visão da formiga de *como* a tarefa é feita. Os usos legítimos são melhoria,
não vigilância: descobrir gargalos/variantes, **padronizar** o "como se faz", documentar
automaticamente e achar candidatos de alto impacto para **automação** (RPA/hyperautomation).
Justamente porque a técnica revela comportamento fino de trabalho, a comunidade construiu
governança de uso responsável — a legitimidade é **desenhada** (agregação + privacy-by-design),
não confiada à boa intenção.

- Definição fundadora + os três tipos (discovery/conformance/enhancement): descobrir, monitorar e
  melhorar processos reais a partir de event logs — [Process Mining Manifesto (IEEE Task Force)](https://www.tf-pm.org/upload/1580737614108.pdf), 2011.
- Process mining vs. task mining — granularidade e fonte de dado (sistema/caso vs. desktop/interação) — [Process Mining vs. Task Mining (SAP Signavio)](https://www.signavio.com/wiki/process-discovery/process-mining-vs-task-mining/), s/d; [What Is Task Mining? (IBM)](https://www.ibm.com/think/topics/task-mining), s/d.
- Uso para padronização e automação (RPA/hyperautomation): capturar ações → agrupar variantes →
  auto-gerar documentação e candidatos a bot — [Hyperautomation Starts Here (EJCSIT)](https://eajournals.org/ejcsit/vol13-issue48-2025/hyperautomation-starts-here-combining-task-capture-process-mining-and-rpa-in-a-unified-framework/), 2025.
- **FACT** (Fairness, Accuracy, Confidentiality, Transparency) de van der Aalst — *Responsible
  Process Mining*: confidencialidade = proteger dado sensível do event log — [Responsible Process Mining (TU/e)](https://pa.win.tue.nl/responsible-process-mining/), 2022; base em [Responsible Data Science (BISE)](https://link.springer.com/article/10.1007/s12599-017-0487-z), 2017.
- **Ethical charter** que exclui avaliação de desempenho individual como objetivo declarado do
  projeto — [Privacy, Security and Ethics in Process Mining (Fluxicon)](https://files.fluxicon.com/Articles/PMNews/Privacy-Security-and-Ethics-In-Process-Mining.pdf), 2017.
- Processo (agregado) ≠ pessoa (indivíduo), do lado do fornecedor: task mining para otimizar a
  *tarefa*, não avaliar desempenho, com privacy-by-design — [Task Mining & Privacy by Design (Celonis)](https://www.celonis.com/whitepaper/privacy-task-mining/), abr/2024.
- Privacy-preserving process mining na prática (pseudonimização/anonimização de logs) — [PC4PM (arXiv)](https://arxiv.org/abs/2107.14499), 2021.
- A crítica externa que motiva a governança: task mining pode escorregar para monitoramento
  desproporcional e ampliar o desequilíbrio de poder — [Process Mining: The Next Stage in Workplace Surveillance (PIA)](https://www.privateinternetaccess.com/blog/process-mining-workplace-surveillance/), s/d.

**Tensão:** a mesma capacidade que acha um gargalo expõe o comportamento de uma pessoa. Academia
(FACT, PC4PM) e fornecedores (charter, privacy-by-design) tratam como problema de governança
resolvível por agregação; críticos externos dizem que o desequilíbrio de poder persiste **apesar**
das salvaguardas técnicas — a linha "processo, não pessoa" depende de *enforcement organizacional*,
não só de tooling.

---

## 2. Consentimento & autorização — deliberado, revogável, dual

Sob o GDPR, consentimento não é caixa pré-marcada: o Art. 4(11) exige indicação "livre, específica,
informada e inequívoca", por ação afirmativa clara — silêncio e inatividade não valem, e todos os
elementos precisam ser cumulativamente satisfeitos. O Art. 7 acrescenta que o responsável deve
**provar** o consentimento e que **retirá-lo tem de ser tão fácil quanto concedê-lo, a qualquer
momento** — revogabilidade por desenho. Isso casa com dois princípios do Art. 5: limitação de
finalidade e minimização. No trabalho, porém, o próprio consentimento é frágil: EDPB e o antigo
Article 29 WP sustentam que, dada a assimetria empregador↔empregado, o consentimento quase nunca é
"livre". Daí o peso de mecanismos **positivos e coletivos**: na Alemanha, monitoramento tecnológico
do comportamento só entra com aprovação do **Betriebsrat** — um direito de **veto**, não
consultivo. O resultado é um modelo efetivamente **dual**: mesmo com base legal individual, é
preciso a autorização coletiva do órgão de representação — nem imposto unilateralmente, nem ligado
por default.

- Consentimento GDPR = livre, específico, informado, inequívoco; sem caixas pré-marcadas — [Art. 4(11) GDPR](https://www.gdprcommentary.eu/article-411-gdpr-consent/), 2018.
- Revogabilidade é condição, não cortesia: retirar tão fácil quanto dar, a qualquer momento — [Art. 7 GDPR](https://gdpr-info.eu/art-7-gdpr/), 2018.
- Limitação de finalidade + minimização; reuso secundário exige nova base — [Art. 5 GDPR](https://gdpr-info.eu/art-5-gdpr/), 2018.
- "Livre" cai sob desequilíbrio de poder, condicionalidade ou detrimento por recusar — [EDPB Guidelines 05/2020 on Consent](https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-052020-consent-under-regulation-2016679_en), 2020.
- No trabalho, o desequilíbrio torna o consentimento "improvável" como base legal — [Article 29 WP, Opinion 2/2017 on data processing at work (wp249)](https://ec.europa.eu/newsroom/article29/item-detail.cfm?item_id=610169), jun/2017.
- Autorização coletiva positiva: §87(1)(6) BetrVG — dispositivo capaz de monitorar comportamento
  exige acordo do Betriebsrat (veto, fixando finalidade/dados/acessos/retenção) — [Germany Employee Monitoring Laws 2026: BetrVG & GDPR](https://www.employee-monitoring.net/compliance/employee-monitoring-laws-germany), 2026.
- Contra default-on: Privacy by Default (Art. 25) — configuração mais protetiva por padrão — [Privacy by Design & Default (Securiti)](https://securiti.ai/blog/privacy-by-design-privacy-by-default/), s/d.
- Contra scope creep/uso secundário: escopo estreito; granularidade excessiva (rastreio ao segundo)
  como função-creep — [Ethical issues with employee monitoring (MiHCM)](https://mihcm.com/resources/blog/ethical-issues-with-employee-monitoring-best-practices-and-compliance/), s/d.

**Tensão:** o GDPR trata o consentimento individual como base plena, mas EDPB/WP29 o **desqualificam
na prática** no trabalho — a "autorização" migra do indivíduo para o coletivo (works council),
invertendo a intuição de que consentir é ato pessoal. A co-determinação forte (veto do Betriebsrat)
é um traço alemão; "boas práticas" de mercado que ainda pregam "consentimento explícito do
empregado" colidem com a leitura europeia.

---

## 3. Fronteira da vigilância — os quatro eixos que fazem um mapa virar vigilância

Existe uma fronteira **operacional bem documentada** — não só intuitiva — entre mapear
comportamento/processo para melhorar uma atividade transversal e vigiar indivíduos. Do lado do
dano, há sinal direcional (2024–2026) de que "bossware" produz efeito inibidor, queda de confiança
e turnover sem ganho real de produtividade, tratado por *policy research* como anti-padrão — mas os
**números pontuais têm proveniência frágil** (ver § Correções); o argumento forte apoia-se nos
eixos qualitativos, não nas porcentagens. Do lado teórico, a **Integridade Contextual** de Helen
Nissenbaum dá o vocabulário exato: privacidade é "fluxo apropriado de informação", avaliado por
cinco parâmetros e violado quando o dado sai da norma do contexto onde foi gerado.

- **Integridade Contextual (CI):** privacidade não é sigilo absoluto, mas direito ao fluxo
  apropriado; resistência surge quando normas informacionais de um contexto são violadas — [Contextual integrity (Wikipedia)](https://en.wikipedia.org/wiki/Contextual_integrity), s/d (consult. 2026-07-12).
- Os **cinco parâmetros** da CI: emissor, receptor, sujeito, tipo de informação e **princípio de
  transmissão** (as condições sob as quais a informação pode fluir — consentimento,
  confidencialidade, reciprocidade) — mesma fonte CI.
- Aplicação recente da CI a monitoramento remoto/gestão algorítmica: a severidade da violação
  cresce sem transparência/consentimento/influência do trabalhador, e é **maior para cargos de alta
  autonomia** — [Digital Panopticon (MDPI 6(1))](https://www.mdpi.com/2673-7116/6/1/6), 2026.
- Deliberação **CDT/Coworker** (mar/2025, 186 participantes): forte apoio a **transparência**;
  oposição a rastreio fora do expediente, a monitoramento nocivo à saúde e a IA para decisões de
  desempenho — [What Do Workers Want? (CDT)](https://cdt.org/insights/what-do-workers-want-a-cdt-coworker-deliberative-poll-on-workplace-surveillance-and-datafication/), mar/2025. *(Verificado; dois subitens — IA de contratação/demissão e "desk presence" — não foram diretamente corroborados na busca; checar no PDF antes de citar literal.)*
- **NELP**, *When Bossware Manages Workers* (jul/2025): vigilância + decisão automatizada
  intensificam disciplina nociva, precariedade, perda de autonomia, discriminação e supressão da
  ação coletiva; pede regulação direta — [NELP](https://www.nelp.org/insights-research/when-bossware-manages-workers-digital-surveillance-automated-decision-system-abuses/), jul/2025. *(Verificado — boa fidelidade ao original.)*
- **Agregação** obscurece o indivíduo preservando valor coletivo; **k-anonimato** garante que cada
  combinação de atributos cubra ≥ k pessoas (trade-off anonimato × granularidade) — [Privacy-Preserving Analytics: Aggregation, Noise, K-Anonymity](https://unicode-oman.org/privacy-preserving-analytics-aggregation-noise-and-k-anonymity), s/d.
- **Os quatro eixos** que separam mapa-consentido de vigilância: **(1) finalidade** (otimizar o
  fluxo transversal vs. avaliar/punir); **(2) transparência** (o titular sabe o quê/como/quem vê);
  **(3) nível de agregação** (agregado/k-anonimizado vs. rastreio nominal); **(4) controle do
  titular** (consentimento atualizado, contestação, limites fora do expediente) — [Employee Monitoring Ethics (Apploye)](https://apploye.com/blog/employee-monitoring-ethics/), s/d.
- Escala do fenômeno (direcional, **corrigido** abaixo): mercado de "bossware" ~US$ 587,8 mi em
  2024 — [Employee Monitoring Statistics (High5)](https://high5test.com/employee-monitoring-statistics/), 2024–2025.

**Tensão:** fontes vendor-adjacent tratam a adoção de bossware como tendência neutra e inevitável;
policy/academia documentam dano e pedem regulação. Não há ainda uma aplicação acadêmica amplamente
citada da CI *especificamente* a "mapeamento consentido vs. vigilância" — a síntese dos 4 eixos é
**construção própria** por convergência entre literaturas adjacentes, não citação única de consenso.

---

## 4. Inferência & privacy engineering — o que o consentimento na captura NÃO cobre

O ponto cego do consentimento clássico: ele governa a **coleta**, não a **derivação** de atributos
nunca fornecidos. Staab et al. mostraram que LLMs inferem localização, renda, sexo e idade de posts
do Reddit com **até ~85% top-1 / 95% top-3**, a uma fração do custo humano — deslocando o risco da
*memorização* de PII para a *inferência*. Por isso **redigir strings de PII não protege**: o modelo
reconstrói o atributo pelo estilo e contexto residual, não pela string apagada. A engenharia de
privacidade responde não com anonimização (frágil — Sweeney reidentificou 87% dos americanos com
CEP+nascimento+sexo), mas com garantias **quantificadas e composicionais** (ε) e com revelação de
**predicados** em vez de valores. A lição para um sistema que agrega dados consentidos: o gate não
pode ser só "havia consentimento na captura?", mas "esta agregação **infere** algo novo, e com que
orçamento?".

- LLMs inferem atributos pessoais de texto livre com **85% top-1 / 95% top-3**, ~100× mais barato
  que humanos (dataset PersonalReddit) — a inferência, não a memorização, é o vetor dominante — [Beyond Memorization: Violating Privacy via Inference with LLMs](https://arxiv.org/abs/2310.07298), 2024 (ICLR 2024).
- Escala de texto para **comportamento/agentes**: agentes LLM constroem perfis a partir de
  atividade pseudônima, via *prompts benignos* que não disparam recusa — [Automated Profile Inference with Language Model Agents](https://arxiv.org/pdf/2505.12402), 2025.
- Gap regulatório: a lei protege inputs mas falha diante de inferências "não intuitivas e não
  verificáveis" — daí o **direito a inferências razoáveis** — [A Right to Reasonable Inferences (Wachter & Mittelstadt)](https://journals.library.columbia.edu/index.php/CBLR/article/view/3424), 2019 (Columbia Business Law Review).
- **ε (privacy budget):** quantifica a perda máxima de privacidade; ε menor = mais forte; um
  **ledger/accountant** rastreia o gasto acumulado — [Understanding the Privacy Budget in DP](https://medium.com/@entiovi.research/understanding-the-privacy-budget-in-differential-privacy-a-technical-perspective-3664185042e6), s/d.
- **Composição** é o coração do orçamento: sequencial sobre o mesmo dado os custos **somam**
  (ε = Σεᵢ); paralela sobre subconjuntos disjuntos o custo é o **máximo** (ε = max εᵢ) — [Properties of Differential Privacy (Programming DP)](https://programming-dp.com/chapter4.html), s/d.
- De-identificação é frágil por design: CEP + nascimento + sexo identificam **87% dos EUA** — [Sweeney's Privacy Research](https://www.johndcook.com/blog/2018/12/07/no-funding-for-unwanted-news/), 2018 (estudo Sweeney ~2000; demo Weld 1997).
- **Selective disclosure** resolve "compor sem expor": SD-JWT VC guarda hashes salgados e revela só
  os *disclosures* pedidos; predicado `age_equal_or_over:18` prova maior-de-18 sem a data — [SD-JWT VC Explained](https://docs.walt.id/concepts/digital-credentials/sd-jwt-vc), 2026.
- **ZKP** generaliza: provas de predicado (pertence-a-conjunto, faixa numérica) e derivação de
  claims — data-minimization criptográfica — [General-Purpose ZKPs for Verifiable Credentials (ETH Zürich)](https://ethz.ch/content/dam/ethz/special-interest/infk/inst-infsec/appliedcrypto/education/theses/masters-thesis_damiano-mombelli.pdf), s/d.

**Tensão:** DP dá garantia matemática mas cobra em **utilidade**, e seu accountant assume que todo
acesso passa pelo mecanismo — inferência **externa** por LLM sobre dado já publicado fica **fora do
orçamento**. O "direito a inferências razoáveis" é doutrina, não lei consolidada.

---

## Convergências (o que as 4 frentes dizem em uníssono)

1. **A linha "processo/agregado, não pessoa/nominal" é o divisor** — aparece de forma independente
   no charter de process mining (§1), no princípio de finalidade do GDPR (§2), no eixo (1)+(3) da
   fronteira (§3) e na lógica de agregação/DP (§4).
2. **Consentimento é necessário mas frágil e insuficiente** — frágil sob assimetria (§2), e
   insuficiente porque não cobre a inferência (§4). Nas duas pontas, a resposta é o **coletivo/
   quantificado** (works council; orçamento ε), não o aceite individual.
3. **A legitimidade é desenhada, não intencional** — FACT, charter, privacy-by-default, k-anonimato,
   ε: todas as frentes tratam a proteção como **propriedade de arquitetura**, não como promessa de
   bom uso.
4. **Transparência + controle do titular + revogabilidade** são condição, não enfeite (§2 Art. 7,
   §3 eixos 2 e 4, §1 charter).

## Divergências / tensões cruzadas

- **Tooling vs. poder:** §1 e §3 divergem sobre se salvaguardas técnicas bastam — a crítica externa
  diz que o desequilíbrio de poder sobrevive à anonimização. Enforcement organizacional > tooling.
- **Consentir individual vs. autorizar coletivo:** §2 mostra a autoridade migrando do indivíduo
  para o órgão coletivo — o que reforça o princípio do maestro (**a pessoa E a organização**), mas
  alerta que "a org autoriza" não pode *substituir* o consentimento da pessoa (nem vice-versa).
- **Orçamento fechado vs. inferência aberta:** §4 mostra que mesmo um sistema com ε perfeito não
  contém a inferência externa — o gate de captura **não fecha** o gate de inferência.

## Correções da verificação adversarial (honestidade, sem inflar)

- **Mercado de bossware:** o correto é ~**US$ 587,8 mi em 2024** (Fortune Business Insights,
  abr/2025) → projeção ~**US$ 1,47 bi até 2032** (CAGR 12,3%), **não** "US$ 1,4 bi até 2031"
  (blogs secundários arredondam mal). Os "78%" e a razão 6/10→7/10 são **projeção/expectativa
  Gartner**, não fato consumado.
- **Números de moral (59% confiança / 42% vs 23% saída / 72% "não ajuda"):** todos remontam a **uma
  única** pesquisa ExpressVPN/Pollfish de **2021** (fornecedor de VPN, interesse na narrativa), não
  replicada — tratar como **direcional e datada**, não como múltiplas evidências correntes.
- **"Turnover triplicado em pequenas empresas":** **refutado** como dado — rastreável só a blog
  corporativo sem estudo/amostra/ano. O fenômeno de *productivity theater* ("jogar o sistema") é
  real e documentado; o **número** não é. Remover ou rotular como não verificado.
- **CDT/Coworker e NELP:** **sustentados** (boa fidelidade). Dois subitens do CDT (IA de
  contratação/demissão; "desk presence") não foram diretamente corroborados — verificar no PDF.

## Implicações para a nota ética (os 4 movimentos)

1. **Mapeamento consentido ≠ vigilância** — a técnica é a mesma; o que a separa é **finalidade +
   agregação + transparência + controle do titular** (§1 charter, §3 quatro eixos). A nota fica
   **atrás** dessa linha: mapear o *processo transversal*, nunca escrutinar a *pessoa*.
2. **Inversão intake↔execução** — o KB `authorization-layers` diz "guardar é livre, agir é gated";
   para um sensor de comportamento **a permissão de observar é o gate**. Captura ≠ intake autônomo:
   exige autorização prévia, opt-in, revogável (§2 Art. 4(11)/7; §3 eixo 4).
3. **Dupla autorização deliberada** — a pessoa autoriza a própria captura **e** a organização
   escopa o propósito; a composição entre pessoas é ela mesma consentida (§2 modelo dual +
   Betriebsrat; §3 agregação/k-anon). **Não imposto** = revogável, VETO-não-SKIP; **não acidental**
   = privacy-by-default, minimização, sem scope-creep. Ressalva de §2: nem a org substitui a pessoa,
   nem a pessoa sozinha legitima a composição coletiva.
4. **A lacuna da inferência** — consentir a **captura** não protege da **inferência** (§4 Staab; o
   accountant ε não cobre inferência externa). É a fronteira aberta (ecoa o P4 de
   `onion-pessoal-marcio`). Mitigações **parciais**: minimização de propósito, não-retenção do
   bruto, predicados/selective disclosure em vez de valores, e um **ledger de ε** que trate cada
   agregação como gasto. A nota deve ser honesta: **dupla-consentida na captura ≠ protegida na
   inferência.**
