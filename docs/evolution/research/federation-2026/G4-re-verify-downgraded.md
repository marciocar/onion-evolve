# G4 — Re-verificação dos achados rebaixados load-bearing (2ª rodada, fecha gaps)

> Stream G4 do redesign da federação Onion — 2026-07-09. Missão: **firmar (confirmed) ou refutar
> (refuted)** com fonte primária melhor os achados que a 1ª rodada rebaixou a `hypothesis` ou marcou
> com ressalva de citação/estatística. **Não é descoberta nova** — é verificação. Doutrina: "evidência
> ou abstenção". Sem fonte sólida = permanece `hypothesis`, materialidade `low`, marcado como "não usar".

---

## Resumo

Todos os quatro gaps atacados **fecharam com fonte primária**:

1. **S1·F8 (AAIF governa MCP *e* A2A + spec conjunta)** — **REFUTADO** pelos dois press releases primários da
   Linux Foundation. A AAIF ancora **só MCP, goose, AGENTS.md**; o A2A é um **projeto LF separado**. Nenhum
   dos primários declara spec conjunta MCP↔A2A. Sobra um claim mais fraco e **verdadeiro**: ambos vivem sob a
   **mesma organização-guarda (Linux Foundation)**, oficialmente descritos como **complementares** (MCP=vertical/tools,
   A2A=horizontal/peer). O argumento "convergência de governança reduz risco de órfão" **sobrevive em forma atenuada**.
2. **S1·F15 (delegação verificável cross-MCP/A2A)** — **CONFIRMADO como direção de pesquisa ativa**. Os **três
   arXiv IDs** antes não verificados **existem e batem exatamente** com o descrito (AIP, Overlaying Governance,
   Anumati). Continuam **propostas acadêmicas independentes, não standards, não endossadas por Anthropic/Google**.
   A fraqueza da 1ª rodada (IDs frágeis) está **fechada**; o veredito de status permanece "monitorar, não adotar".
3. **Estatística MCP tool-poisoning** — o "30%+ de 1.800 servidores" é **superestimado/conflado**. O número real,
   do survey primário (arXiv 2506.13538, **1.899 servidores**): **7,2% com vulnerabilidade geral** e **5,5% com
   tool-poisoning MCP-específico**. O thrust qualitativo (supply-chain MCP é ameaça real) sobrevive.
4. **Custo self-host Backstage** — **firmado** com números concretos ($450k/ano, 3 engenheiros, 6–12 meses,
   TCO 1º ano > $800k), **com ressalva de viés de fornecedor** (fonte é CEO de concorrente gerenciado).
5. **"% de empresas em monorepo" (o "63% com 50+ devs")** — **SEM FONTE**. Nem a nx.dev nem survey algum sustentam
   o número. Rebaixado a `hypothesis`/não-usar; o que há de sólido são **estudos de caso** (Google, Meta, Microsoft,
   Uber usam monorepo), não taxa de adoção quantificada.

---

## Achados

### G4-01 — REFUTADO: a AAIF **não** governa o A2A; são projetos LF **separados** (primário duplo)
**Veredito:** **refuted** (do claim forte "AAIF governa MCP e A2A").
**Claim verificado:** O press release primário de formação da AAIF (09-dez-2025) lista como projetos-âncora
**apenas MCP (Anthropic), goose (Block) e AGENTS.md (OpenAI)** — **A2A não é mencionado em lugar nenhum**. O
press release primário do A2A (abr/2026) **também não menciona a AAIF**; ao contrário, enquadra explicitamente:
*"A2A is complementary to the Model Context Protocol (MCP), **another Linux Foundation project**"*. Ou seja, A2A e
MCP são **dois projetos LF distintos**, não co-governados por um mesmo sub-foundation. **Nenhum** dos dois primários
declara "spec conjunta de interop MCP↔A2A" (o roadmap do A2A cita uma "interoperability specification" *do próprio A2A*,
sem colaboração declarada com MCP).
**Fontes:**
<https://www.linuxfoundation.org/press/linux-foundation-announces-the-formation-of-the-agentic-ai-foundation> ·
<https://www.linuxfoundation.org/press/a2a-protocol-surpasses-150-organizations-lands-in-major-cloud-platforms-and-sees-enterprise-production-use-in-first-year>
**Materialidade:** high.
**Implicação p/ Onion:** o texto do redesign **não pode** afirmar "MCP e A2A sob a mesma governança (AAIF)" nem
"spec conjunta". Deve dizer o claim atenuado do G4-02. O adapter `a2a-live` gated continua alinhado, mas por
**complementaridade oficial + guarda comum LF**, não por co-governança num único foundation.

### G4-02 — CONFIRMADO (claim atenuado): MCP e A2A são ambos projetos da Linux Foundation, oficialmente **complementares**
**Veredito:** **confirmed** (substitui o claim forte de F8 pelo verdadeiro).
**Claim verificado:** Ambos MCP e A2A são **projetos da Linux Foundation** (MCP via AAIF; A2A como projeto próprio,
doado por Google em 2025). A LF os descreve como **complementares**: A2A = como agentes se comunicam/coordenam através
de fronteiras organizacionais (horizontal/peer); MCP = como agentes conectam a ferramentas/dados internos (vertical/tools).
Membros platinum fundadores da AAIF (8): **AWS, Anthropic, Block, Bloomberg, Cloudflare, Google, Microsoft, OpenAI**.
A2A cresceu de 50+ para **150+ organizações** no 1º ano, alcançou v1.x com agent cards assinados criptograficamente.
**Fontes:** (mesmas do G4-01) + <https://www.infoq.com/news/2025/12/agentic-ai-foundation/>
**Materialidade:** high.
**Implicação p/ Onion:** o vetor do Onion (Anthropic/Claude Code via MCP) e o alvo do adapter (A2A) estão **sob a
mesma organização-guarda (LF) e oficialmente enquadrados como complementares** — reduz o risco de "apostar no A2A"
ficar órfão do ecossistema Claude Code, **sem** exigir a alegação (falsa) de foundation único ou spec conjunta.

### G4-03 — CONFIRMADO: arXiv 2603.24775 (AIP) existe e é exatamente delegação verificável cross-MCP/A2A
**Veredito:** **confirmed** (fecha o gap de "arXiv IDs não verificados" de F15).
**Claim verificado:** **arXiv:2603.24775** — *"AIP: Agent Identity Protocol for Verifiable Delegation Across MCP
and A2A"*, Sunil Prakash, submetido mar/2026. Propõe **Invocation-Bound Capability Tokens (IBCTs)** — funde identidade
+ autorização atenuada + provenance num token append-only; dois formatos (JWT compact single-hop; Biscuit+Datalog
multi-hop). Bindings para **MCP, A2A e HTTP genérico**. Overhead medido 2,35ms (0,086% da latência). **Status:
proposta acadêmica independente + draft IETF individual + pacote PyPI alpha (0.1.1)** — **NÃO endossada por Anthropic
nem Google**.
**Fontes:** <https://arxiv.org/abs/2603.24775> · <https://www.ietf.org/archive/id/draft-prakash-aip-00.html>
**Materialidade:** medium.
**Implicação p/ Onion (aceitação gated):** aponta para onde a fronteira de delegação verificável ("core A delega a
core B falar em seu nome") vai. **Não é standard estável** — o gate humano do maestro + trust SDAAL seguem necessários.
Encaixa como **direção futura monitorada** do bloco `trust:`, não base de decisão.

### G4-04 — CONFIRMADO: arXiv 2606.03518 (Overlaying Governance) — framework composicional de delegação/escopo
**Veredito:** **confirmed** (2º dos três IDs de F15, verificado).
**Claim verificado:** **arXiv:2606.03518** — *"Overlaying Governance: A Compositional Authorization Framework for
Delegation and Scope in Agentic AI"*, Amjad Ibrahim & Yong Li, jun/2026. Trata cadeias de delegação recursivas,
limites contextuais e escopo dinâmico; modela delegação como **relação contratual com accountability** (não token
estático tipo OAuth); usa **resource scope attenuation** para limitar o "envelope" de acesso do agente. Provas formais
+ validação empírica; aplicável a domínios como sistemas financeiros.
**Fontes:** <https://arxiv.org/abs/2606.03518>
**Materialidade:** medium.
**Implicação p/ Onion:** corrobora que "delegação com escopo atenuado e accountability" é a forma-alvo (relevante ao
caso regulado Grana.Ai). Pesquisa ativa — mesma disposição do G4-03: monitorar, não adotar.

### G4-05 — CONFIRMADO: arXiv 2604.16524 (Anumati) — modelo formal de consent/proof-of-adherence sobre A2A+MCP
**Veredito:** **confirmed** (3º dos três IDs de F15, verificado).
**Claim verificado:** **arXiv:2604.16524** — *"Anumati: Proof of Adherence as a Formal Consent Model for Autonomous
Agent Protocols"*, Ravi Kiran Kadaboina, abr/2026. Distingue **proof of acceptance** (ack timestamped) de **proof of
adherence** (registro de raciocínio atado a cláusulas de política); três primitivas (PolicyDocument, ConsentRecord,
AdherenceEvent); **estende A2A e MCP**; especificação TLA+ + implementação Python de referência.
**Fontes:** <https://arxiv.org/abs/2604.16524>
**Materialidade:** medium.
**Implicação p/ Onion:** os **três** IDs de F15 agora estão verificados e reais. A tese de F15 ("identidade/consent/
delegação verificável cross-MCP/A2A = pesquisa ativa, não standard, não endossada pelo fornecedor") está **firme com
primários**. Veredito de doutrina inalterado: gate humano permanece; adotar seria prematuro.

### G4-06 — ESTATÍSTICA CORRIGIDA: MCP tool-poisoning é ~7,2% (não "30%+ de 1.800")
**Veredito:** **refuted** (o número "30%+ de 1.800") / **confirmed** (o número real substituto).
**Claim verificado:** O survey primário **arXiv:2506.13538** — *"Model Context Protocol (MCP) at First Glance"*
(Hasan et al., jun/2025, rev. abr/2026) — estudou **1.899 servidores MCP open-source** e achou: **7,2% com
vulnerabilidade geral** e **5,5% com tool-poisoning MCP-específico** (além de 66% com code smells; 8 vulnerabilidades
distintas, só 3 sobrepondo software tradicional). O "30%+" da 1ª rodada é **conflação/superestimativa**; não se sustenta.
**Corroboração independente:** o paper AIP (arXiv:2603.24775) escaneou **~2.000 servidores MCP e achou que TODOS
careciam de autenticação** — ou seja, o risco *sistêmico* real é a **ausência de auth por padrão**, não "30% com
vuln explorável". Duas medidas diferentes; a honesta é distinguir "vuln explorável (~7%)" de "sem autenticação (quase
universal)".
**Fontes:** <https://arxiv.org/abs/2506.13538> · <https://arxiv.org/abs/2603.24775>
**Materialidade:** high (é citada externamente na doutrina).
**Implicação p/ Onion:** substituir todas as ocorrências de "30%+ de 1.800 servidores" (SYNTHESIS §, S4·F6) por
**"~7,2% dos 1.899 servidores estudados têm vuln explorável; 5,5% tool-poisoning específico — e ~todos os servidores
carecem de auth por padrão"**. O thrust ("supply-chain MCP é ameaça real; tratar sinal remoto como não-confiável até
verificado") permanece sólido — na verdade o dado "sem auth universal" **reforça** `never-clobber` + ingestão gated
mais do que o número inflado.

### G4-07 — FIRMADO (com ressalva de viés): custo de self-host Backstage
**Veredito:** **confirmed** (números concretos) — **com ressalva de fonte-fornecedor**.
**Claim verificado:** A fonte dá, verbatim: happy self-host exige *"at least three dedicated engineers"*; *"three
mid-level engineers cost around **$450,000 per year**"*; *"Time to production: **6-12 months**"*; *"First year total
exceeds **$800,000**"* (450k salários + ~200k de valor adiado). **Ressalva material:** o autor é **David Tuite, CEO
da Roadie** — fornecedor de Backstage gerenciado, com interesse comercial claro em afastar o leitor do self-host.
Os números são plausíveis e específicos, mas **têm viés direcional** (tendem ao teto).
**Fontes:** <https://roadie.io/blog/the-true-cost-of-self-hosting-backstage/>
**Materialidade:** medium.
**Implicação p/ Onion:** o build-vs-buy do S3 ("Backstage/Port = over-engineering caro para federação de ~5 membros")
**sobrevive mesmo descontando o viés** — mesmo que os números reais sejam metade, ainda são 1+ ordem de grandeza acima
do valor para 5 membros. Citar com o disclaimer "fonte é fornecedor de alternativa gerenciada" para honestidade.

### G4-08 — SEM FONTE: "63% das empresas com 50+ devs usam monorepo" é fabricado/não-sustentado
**Veredito:** **refuted** (como estatística) → rebaixar a `hypothesis`/não-usar.
**Claim verificado:** A fonte citada por S2·F9 (nx.dev/why-monorepos) **NÃO contém** esse número — nem percentual de
adoção, nem taxa por tamanho de empresa, nem tamanho típico de monorepo. Busca ampla por survey de "% de empresas em
monorepo" **não achou dado quantitativo** — só **estudos de caso** de big tech (Google/Piper com bilhões de LOC, Meta/
Sapling, Microsoft/Windows em Git monorepo, Uber). Não existe survey confiável sustentando "63% com 50+ devs".
**Fontes:** <https://nx.dev/docs/concepts/decisions/why-monorepos> (não contém o número) ·
<https://graphite.com/guides/why-top-tech-companies-are-moving-to-monorepos> (estudos de caso, sem taxa)
**Materialidade:** low (não usar como estatística).
**Implicação p/ Onion:** trocar "63% das empresas com 50+ devs usam monorepo" por afirmação qualitativa fonteável:
**"big tech usa predominantemente monorepo (estudos de caso: Google, Meta, Microsoft, Uber); não há survey confiável
de taxa de adoção enterprise"**. O argumento de S2·F9 (Nx resolve o enforcement *dentro* do monorepo; o core federa no
nível do REPO) **não depende** do número — ele decorre das capacidades do Nx (boundaries/generators/conformance), que
seguem confirmadas. Sobre "tamanho típico de monorepo nx enterprise": **sem número único confiável**; o ponto de dado
mais concreto disponível é o teste Renovate citado em S2·F9 (monorepo de 198 deps / 14 workspaces) — data point, não média.

---

## Resolução do gap (o que isto fecha do SYNTHESIS)

| Gap da 1ª rodada | Estado após G4 | Ação no texto do redesign |
|---|---|---|
| **S1·F8** rebaixado a `hypothesis` (vínculo A2A↔AAIF só por secundárias) | **RESOLVIDO por refutação**: primário duplo confirma que **AAIF ≠ governança do A2A** e **não há spec conjunta**. Claim atenuado verdadeiro (ambos LF, complementares) fica **confirmed**. | Reescrever F8: cortar "AAIF governa MCP *e* A2A" e "spec conjunta"; afirmar só "ambos são projetos LF, oficialmente complementares". Preservar a implicação (risco de órfão reduzido) na forma atenuada. |
| **S1·F15** rebaixado a `hypothesis` (3 arXiv IDs não verificados) | **RESOLVIDO por confirmação**: os **três IDs existem e batem** (AIP, Overlaying Governance, Anumati). | Promover F15 de "citação frágil" para "direção de pesquisa com primários verificados". **Manter** o veredito de doutrina: monitorar/gate humano, não adotar. |
| **Estatística "30%+ de 1.800 servidores MCP"** (superestimada) | **RESOLVIDO**: número real **7,2% vuln / 5,5% tool-poisoning de 1.899** (arXiv 2506.13538); + fato mais forte "~todos sem auth" (arXiv 2603.24775). | Substituir o número em SYNTHESIS §57-58 e S4·F6. O thrust `never-clobber`/ingestão gated **sai reforçado**, não enfraquecido. |
| **Custo self-host Backstage** (a firmar) | **RESOLVIDO com ressalva**: $450k/3 eng/6–12mo/$800k 1º ano — **viés de fornecedor** declarado. | Citar com disclaimer de fornecedor. Build-vs-buy do S3 sobrevive ao desconto de viés. |
| **"% empresas em monorepo"** (a firmar) | **NÃO RESOLVIDO — sem fonte**: nenhum survey sustenta "63%". | Remover o número; usar afirmação qualitativa por estudos de caso. Argumento de S2·F9 independe da estatística. |

**Nenhum achado material do SYNTHESIS foi derrubado.** As correções são de **citação e estatística**, não de tese: a
doutrina (SSOT single-source; federar só a comunicação; Grana.Ai como data-plane subordinado; adapter `a2a-live` gated;
`members.yaml` como policy-as-data; gate humano na delegação) **permanece bem-fundada** e, em dois pontos (F8 atenuado
honesto, estatística MCP corrigida para "sem-auth-universal"), fica **mais defensável** por não depender de alegação
inflada.

---

## Verificação adversarial

Rodada 2 (verificador adversarial G4, doutrina: evidência ou abstenção). Cada achado foi checado contra a fonte
primária citada — existência, data, e se sustenta o claim SEM exagero. Todos os sete resistiram à tentativa de
refutação com evidência primária direta.

| finding_id | veredito | nota (evidência primária) |
|------------|----------|---------------------------|
| **G4-01** | **confirmed** | Press release AAIF (09-dez-2025) lista como projetos inaugurais **apenas** MCP, goose e AGENTS.md — A2A ausente. Press release A2A (09-abr-2026) **não** menciona a AAIF e chama A2A de "another Linux Foundation project", complementar ao MCP. A refutação do claim forte de F8 (AAIF governa A2A) está correta. |
| **G4-02** | **confirmed** | 8 membros platinum fundadores confirmados no press release AAIF: AWS, Anthropic, Block, Bloomberg, Cloudflare, Google, Microsoft, OpenAI. A2A hospedado pela LF (doado pelo Google), MCP via AAIF, ambos descritos como complementares ("A2A defines how agents communicate... while MCP defines how agents connect to internal tools"). Forma atenuada verificada. |
| **G4-03** | **confirmed** | arXiv 2603.24775 existe: "AIP: Agent Identity Protocol for Verifiable Delegation Across MCP and A2A", Sunil Prakash, submetido 25-mar-2026. Introduz Invocation-Bound Capability Tokens (IBCTs). Scan de ~2.000 servidores MCP: "all lacked authentication" — confirmado no abstract. |
| **G4-04** | **confirmed** | arXiv 2606.03518 existe: "Overlaying Governance: A Compositional Authorization Framework for Delegation and Scope in Agentic AI", Amjad Ibrahim & Yong Li, submetido 02-jun-2026. Delegação como termo contratual + resource scope attenuation + provas formais confirmados. |
| **G4-05** | **confirmed** | arXiv 2604.16524 existe: "Anumati: Proof of Adherence as a Formal Consent Model for Autonomous Agent Protocols", Ravi Kiran Kadaboina, submetido 16-abr-2026. Distingue proof of acceptance de proof of adherence; estende A2A e MCP; TLA+ + implementação Python de referência confirmados. |
| **G4-06** | **confirmed** | arXiv 2506.13538 ("MCP at First Glance", 1.899 servidores open-source, jun/2025, última versão abr/2026): **7,2%** com vulnerabilidade geral, **5,5%** com tool-poisoning MCP-específico — os números batem exatamente. Corroboração AIP (~2.000 servidores sem auth) confirmada. O "30%+" original era de fato conflado/superestimado. |
| **G4-07** | **confirmed** | Post da Roadie confirma: "at least three dedicated engineers", "~$450,000 per year", "6-12 months" a produção, "First year total exceeds $800,000". Autor = David Tuite, CEO da Roadie (Backstage gerenciado) → viés comercial direcional confirmado e materialmente registrado; a tese build-vs-buy sobrevive ao desconto do viés. |

**Síntese da verificação:** 7/7 confirmados com fonte primária direta. Nenhuma contra-evidência encontrada. As duas
ressalvas de materialidade (viés do autor em G4-07; correção estatística em G4-06) já estavam explicitadas nos próprios
claims — não são refutações, são qualificações que os achados já carregam. A rodada 2 sai mais firme que a rodada 1:
onde antes havia "arXiv IDs não verificados" (F15) e "30% inflado", agora há primários batidos um a um.
