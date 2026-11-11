# Automação, catraca e níveis: padrão de mercado em 2026-11-11

Legenda de fonte: [P] primária (doc oficial, spec, paper do autor) · [S] secundária (vendor, consultoria, blog) · [C] opinião de comunidade.
Pesquisa read-only. Citações curtas, tradução minha quando em inglês.

---

## 1. Níveis de autonomia, agendamento no Claude Code, risco x aprovação

### 1.1 Escalas publicadas
- **Feng, McDonald, Zhang (Knight Institute / arXiv 2506.12469)**: cinco níveis definidos pelo PAPEL do humano, não pela capacidade: L1 Operator, L2 Collaborator, L3 Consultant, L4 Approver ("agent operates independently, asking for approval in high-risk or pre-defined cases"), L5 Observer (só monitora e aciona parada de emergência). [P] https://knightcolumbia.org/content/levels-of-autonomy-for-ai-agents-1 e https://arxiv.org/html/2506.12469v2 (detalhe dos papéis lido via resumo de busca [S]: https://www.aigl.blog/levels-of-autonomy-for-ai-agents/)
- Cuidado: existe também uma escala L0-L5 "tecnológica" que alguns agregadores misturam com esta. [S] https://www.emergentmind.com/topics/ai-agency-levels
- **Anthropic, "Measuring AI agent autonomy in practice" (18/02/2026)**: não é uma escala de níveis; pontua risco e autonomia de 1 a 10 por ação, como "indicadores comparativos". Achados: "cerca de 20% das sessões de novos usuários usam full auto-approve, subindo para mais de 40% com a experiência"; usuários experientes interrompem mais; "a supervisão eficaz não exige aprovar cada ação, mas estar em posição de intervir quando importa"; mandatos como "aprovar toda ação" geram "atrito sem necessariamente produzir benefício de segurança". [P] https://www.anthropic.com/research/measuring-agent-autonomy

### 1.2 O que o Claude Code oferece hoje (agendamento e aprovação)
- Três opções, tabela oficial: **Cloud** (nuvem Anthropic, máquina desligada ok, intervalo mínimo 1 h, "Auto mode por padrão" nos prompts de permissão), **Desktop** (local, persiste), **/loop** (sessão, intervalo mínimo 1 min). [P] https://code.claude.com/docs/en/scheduled-tasks
- **/loop é descartável por desenho**: tarefas recorrentes "expiram 7 dias após a criação", disparam só com a sessão aberta e ociosa, sem recuperação de disparos perdidos, com jitter de até 30 min; limite de 50 tarefas por sessão. [P] mesma URL. Para durabilidade a doc aponta cloud, Desktop ou GitHub Actions com `schedule`.
- **Cloud scheduled tasks (ex-routines)**: prompt + repositórios + conectores, gatilhos schedule, API (POST com bearer) e GitHub; "research preview"; planos Pro/Max/Ultra/Team/Enterprise; Claude empurra para branches `claude/` e o controle de branch é por branch protection do GitHub. [P] https://code.claude.com/docs/en/routines
- **Aprovação em camadas já embutida**: em auto mode "um modelo classificador separado revisa as ações antes de rodarem"; "se bloqueia 3 vezes seguidas ou 20 no total, o auto mode pausa e volta a perguntar" (limiares não configuráveis); "não garante segurança". Modos: default, acceptEdits, plan, auto, dontAsk, bypassPermissions ("só containers/VMs isolados"). [P] https://code.claude.com/docs/en/permission-modes
- Em run cloud, regras `ask` ainda geram prompt mesmo em auto mode, e o prompt espera na página do run até alguém responder. [P] https://code.claude.com/docs/en/routines (seção "Permission prompts during a run")
- `CLAUDE_CODE_DISABLE_CRON=1` desliga o agendador de sessão. [P] scheduled-tasks.
- Hooks e `/loop` com Monitor: o Monitor evita polling e é "mais eficiente em tokens". [P] scheduled-tasks. (Detalhe de hooks `exit 2` não pesquisado aqui; já é doutrina do core.)

### 1.3 Segurança de agentes e governança de IA
- **OWASP Top 10 for Agentic Applications 2026** (9/12/2025, 100+ especialistas), ASI01 a ASI10; confirmados por nome: ASI01 Agent Goal Hijack e ASI02 Tool Misuse; demais temas: identidade/privilégio, supply chain, execução de código, memória, comunicação entre agentes, falha em cascata, confiança humano-agente, agentes rogue. Complementa NIST AI RMF e ISO/IEC 42001. [P] https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/ ; resumo [S] https://paloaltonetworks.com/blog/cloud-security/owasp-agentic-ai-security/ (lista completa dos 10 nomes: NÃO-VERIFICADO, ver seção 6).
- **NIST AI 600-1 (GenAI Profile, jul/2024)**: 12 riscos; o risco "Human-AI Configuration" cobre excesso de confiança e viés de automação; ações GOVERN 3.2 sobre supervisão humana; é genérico, não específico de agentes. [P] https://airc.nist.gov/docs/NIST.AI.600-1.GenAI-Profile.ipd.pdf (versão draft; leitura do conteúdo via [S] https://tagcai.substack.com/p/human-oversight-for-generative-ai)

### 1.4 Como o mercado combina automático e aprovação
- Padrão recorrente: **camadas por reversibilidade/risco**: leitura livre; escrita reversível com escopo; destrutiva/irreversível com aprovação. Variantes: 4 camadas (autônomo, só log, aprovação síncrona, escalonamento por confiança). [S] https://www.decryptiondigest.com/blog/human-in-the-loop-approval-gates-agentic-ai-tool-calls ; https://waxell.ai/blog/human-in-the-loop-vs-human-on-the-loop-ai-agents
- Contra-lição: **fadiga de aprovação** vira carimbo. [C/S] https://waxell.ai/blog/human-in-the-loop-approval-fatigue-policy-fix

**Padrão de mercado em uma frase (tema 1):** a autonomia é escalada por papel do humano (de operador a observador) e por reversibilidade da ação; o automático roda com classificador e regras `ask`, e a aprovação humana fica reservada ao irreversível e ao que o classificador bloqueia repetidamente, sem exigir aprovação de tudo.

---

## 2. Controle contínuo e compliance as code

- **OSCAL (NIST)**: o modelo Assessment Results "é para avaliação e monitoramento contínuo", com formas XML/JSON/YAML; resultados sempre ligados a um Assessment Plan; para monitoramento contínuo cada conjunto de resultados é uma fatia de tempo (exemplo NIST: teste de hora em hora). NIST CSWP 53 (draft dez/2025) trata avaliação contínua. [P] https://pages.nist.gov/OSCAL/learn/concepts/layer/assessment/assessment-results ; https://pages.nist.gov/OSCAL/presentations/oscal-ap-ar-poam-v3.pdf ; https://nvlpubs.nist.gov/nistpubs/CSWP/NIST.CSWP.53.ipd.pdf
- **FedRAMP 20x**: KSIs (Key Security Indicators) são sinais legíveis por máquina de que um controle funciona de forma contínua, substituindo narrativa por validação automatizada. A página oficial diz que o piloto Phase One terminou e aponta as Consolidated Rules 2026. [P] https://www.fedramp.gov/docs/20x/phase1/key-security-indicators/ ; https://fedramp.gov/2026/reference/20x/c/key-security-indicators/ . Contagem de KSIs e datas (46/56/60/61; CR26 em 25/06/2026; 01/01/2027) divergem entre fontes: NÃO-VERIFICADO. [S] https://www.platform28.com/blog/fedramp-20x-complete-guide
- **Vanta/Drata** (referência de mercado de CCM): Vanta afirma testes automatizados de hora em hora; Drata descreve testes diários com alerta. Marketing; profundidade dos testes é contestada. [S] https://www.vanta.com/compare/drata ; https://drata.com/learn/compare/secureframe-vs-vanta-vs-drata
- **Policy as code**: OPA/Rego e Kyverno com modos audit/enforce (ver seção 3). [S] https://www.qovery.com/blog/opa-gatekeeper-kyverno-platform-layer-deployment-policy
- **ISO/IEC 27001:2022 Anexo A** (resumos de consultoria [S]; texto normativo é pago, não lido): 8.15 Logging (gerar, armazenar, proteger logs de atividade, exceções, falhas, eventos de segurança); 8.16 Monitoring activities (controle NOVO em 2022, analisar logs para comportamento anômalo); 5.36 Compliance with policies, rules and standards (funde 18.2.2 e 18.2.3 de 2013; visão top-down de conformidade com políticas e revisão técnica). Guias ligam 5.36 a 8.15/8.16. https://www.isms.online/iso-27001/annex-a-2022/8-16-monitoring-activities-2022/ ; https://www.isms.online/iso-27001/annex-a-2022/5-36-compliance-policies-rules-standards-information-security-2022/
- **SOC 2 Type II**: avalia eficácia operacional ao longo de um período (3 a 12 meses, conforme fonte); CC7.2 (monitoramento de sistema) e CC4.1 (monitoramento de controles) pedem evidência contínua: "cada controle deve ter ao menos um sinal ou teste contínuo"; retenção de logs deve cobrir a janela. [S] https://www.konfirmity.com/blog/soc-2-continuous-monitoring ; https://blog.getagency.com/articles/soc-2-evidence-collection-guide-what-auditors-actually-want . Texto AICPA TSC não lido: NÃO-VERIFICADO.
- **Como a cadência é declarada e cobrada**: no modelo OSCAL/KSI a cadência é parte do artefato (plano de avaliação + fatias de tempo de resultados); em CCM comercial é a frequência do teste (hora/dia) e o alerta de desvio; em SOC 2 é a janela de observação mais a evidência do período.

**Padrão de mercado em uma frase (tema 2):** controles viram testes automatizados com cadência declarada e resultado legível por máquina (OSCAL, KSIs, CCM), e a auditoria passa a verificar a série de evidências no período, não um documento pontual.

---

## 3. Catraca, error budget, gates progressivos e níveis de enforcement

- **Ratchet (catraca)**: contagem de violações por regra num baseline versionado que só pode descer; subir exige justificativa. Ferramentas: `ratchets` (orçamento por regra e diretório, "aumentar o orçamento exige justificativa na mensagem de commit", merge driver que mantém o menor), `code-baseline`, `eslint-ratchet`, `eslint-formatter-ratchet`. Origem citada: post do qntm. [S/C, código aberto] https://docs.rs/crate/ratchets/0.2.4/source/DESIGN.md ; https://docs.rs/crate/code-baseline/1.5.0 ; https://hn.jakechampion.name/item/47114984 (discussão HN do imbue-ai/ratchets)
- **Error budget (SRE)**: política de exemplo do Google: se o serviço estoura o orçamento da janela de quatro semanas, "pararemos todas as mudanças e releases exceto P0 ou correções de segurança até voltar ao SLO"; divergência escala ao CTO. [P] https://sre.google/workbook/error-budget-policy/
- **Sentinel (HashiCorp)**: advisory (pode falhar, só avisa/loga), soft mandatory (bloqueia, mas aceita override com não-repúdio), hard mandatory (bloqueia sem override). O nível é definido no deploy da política, não no código dela. [P] https://developer.hashicorp.com/sentinel/docs/concepts/enforcement-levels
- **Gatekeeper**: `enforcementAction` = `deny` (default), `warn`, `dryrun`; rollout dryrun -> warn -> deny, explícito em manifest versionado. **Kyverno**: Audit (registra em PolicyReport) vs Enforce (rejeita), com override por namespace; omitido = Audit. [S, docs de terceiros; campo mudou entre versões] https://oneuptime.com/blog/post/2026-07-25-gatekeeper-enforcement-actions/markdown ; https://release-1-13-0.kyverno.io/docs/writing-policies/validate/
- **Mapa de equivalência**: advisory = dryrun = Audit; warn = soft mandatory sem override; deny/Enforce = hard mandatory; soft mandatory = bloqueio com override registrado.

**Padrão de mercado em uma frase (tema 3):** toda regra nasce em modo observar (advisory/dryrun/audit), sobe para avisar e depois para bloquear, com o nível declarado fora da regra, e o baseline de violações só desce (catraca) ou o orçamento estourado congela mudanças.

---

## 4. Organização segurança x compliance x FinOps

- **FinOps Foundation Framework 2026**: estrutura Domains, Capabilities, Scopes e Personas; a versão 2026 adiciona a capability "Executive Strategy Alignment" e explica como definir Scopes. Quatro domínios (contagem de seis em um blog é tida como não confiável). Segurança aparece como parceiro/persona, não como domínio do FinOps. [P parcial] https://www.finops.org/insights/2026-finops-framework/ ; https://finops.org/framework/scopes ; [S] https://virtasant.com/blog/finops-framework-2026
- **Microsoft Cloud Adoption Framework (Secure)**: funções de segurança (arquitetura, postura, operações, GRC etc.) podem ser acumuladas por poucas pessoas, mas são funções distintas. [P] https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/secure/teams-roles
- **Mercado**: funções separadas com dono claro, coordenadas por fórum comum (Cloud Center of Excellence com FinOps, plataforma e GRC); alerta de que alinhar GRC e SecOps demais aumenta overhead de processo; existe a tese minoritária de "FinSecOps". [S] https://www.cortex.io/post/platform-sre-and-security-merge ; https://nhimg.org/faq/what-breaks-when-organisations-use-separate-maps-for-grc-and-security-operations/ ; https://www.techtarget.com/cybersecurity/tip/Unifying-FinOps-and-SecOps-The-case-for-FinSecOps
- **Observabilidade e segurança operacional x compliance**: na prática o mesmo dado serve a dois fins (logs/monitoramento: ISO 8.15/8.16 são controles de SEGURANÇA que alimentam COMPLIANCE via 5.36 e CC7.2). Não achei fonte primária que trate observabilidade como domínio separado de compliance; trata-se como insumo comum. Inferência minha, marcada como tal.
- **Implicação para o Onion (inferência, não fato de mercado)**: o padrão sugere três eixos de EXECUÇÃO distintos (segurança operacional, compliance/GRC, custo/FinOps) sobre uma camada comum de checagem periódica; segurança como sub-parte de compliance é o arranjo menos comum nas fontes lidas (ISO 27001 é, ela própria, um SGSI de segurança, o que mostra que os dois conceitos se interpenetram nos frameworks).

**Padrão de mercado em uma frase (tema 4):** SecOps, GRC e FinOps são funções distintas com dono próprio, coordenadas por um fórum e alimentadas pelos mesmos dados de log, custo e configuração, sem fusão em um único domínio.

---

## 5. Comunidades (2026)

Evidência fina: busca devolveu espelhos de Reddit e blogs de vendor, não threads primárias. Tudo [C/S], direcional.
- Rodadas noturnas funcionam para tarefas estreitas e bem protegidas (refactors repetitivos, bump de dependências). https://reddit.sentinel-team.org/posts/1tpwt5k/snapshots/2026-05-30T02%3A41%3A26.708778Z (espelho)
- Tarefas agendadas herdam as permissões do usuário, cujo default "não foi desenhado para operação autônoma"; sugestão: rodar manualmente antes para ver se pede mais acesso. Loop sem teto de custo pode drenar a janela de uso numa noite. Mesmo espelho/ https://www.mindstudio.ai/blog/claude-code-routines-scheduled-cloud-tasks
- Agente que posta ou envia sem revisão "está pedindo problema"; há quem recomende `--dangerously-skip-permissions` (contraindicado pela própria doc: só em ambiente isolado).
- Fadiga de aprovação e aprovação como carimbo (thread HN citada de segunda mão): https://waxell.ai/blog/human-in-the-loop-approval-fatigue-policy-fix
- Reversibilidade como linha divisória: irreversível exige pré-aprovação; alto volume recuperável usa monitoramento assíncrono. https://www.decryptiondigest.com/blog/human-in-the-loop-approval-gates-agentic-ai-tool-calls

**Padrão de mercado em uma frase (tema 5):** a comunidade converge em agentes autônomos com escopo estreito, permissões mínimas, teto de custo e aprovação humana só para o irreversível, e reclama de fadiga de aprovação quando tudo pede confirmação.

---

## 6. NÃO-VERIFICADOS

1. Lista completa de ASI03 a ASI10 do OWASP (nomes exatos): só temas via resumos.
2. Contagem de KSIs do FedRAMP 20x (46/56/60/61) e datas de CR26 e de obrigatoriedade (01/01/2027).
3. Texto normativo de ISO 27001:2022 (8.15, 8.16, 5.36) e de SOC 2 TSC (CC4.1, CC7.2): só resumos de consultoria.
4. "Auto Mode lançado em 24/03/2026" e "usuários aprovam 93% dos prompts" (atribuído à Anthropic): vistos só em blogs; a doc oficial confirma a existência do auto mode e dos limiares 3/20, mas não a data nem o 93%.
5. Limites diários de runs de cloud scheduled tasks: fontes divergem; não li o número oficial.
6. Existência de perfil NIST específico para agentes em 2026: não encontrado.
7. Datas do EU AI Act (art. 50 em 02/08/2026 vs. Anexo III em 02/12/2027 via Regulamento 2026/1744): fontes conflitantes; não usar sem texto oficial.
8. Número de domínios do FinOps (4 vs. 6) e eventual tratamento formal de segurança como Scope: página do Foundation não lida em profundidade.
9. Comunidades: nenhum thread primário de reddit.com/HN lido; só espelhos e vendors. Hooks `exit 2` e GitHub Actions não pesquisados nesta rodada.
10. Cadência real de Vanta/Drata (hora vs. dia): só marketing.
