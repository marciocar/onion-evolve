# Soberania de dado pessoal: federar, local, ou híbrido

> Camada 1 (fiel à fonte, zero derivação). Sandbox de discussão — não é a KB do core.

Descreve, fielmente às fontes, o estado-da-arte (2026) de como um sistema de dados pessoais
sensíveis se posiciona entre **federar** (participar de rede que troca dado), **local-only** e
**híbrido** (bruto local + destilado compartilhado). Não tira conclusões de design.

## Federar dado pessoal: spec madura, adoção travada

**Solid** (Berners-Lee — pods/WebID, separar dado de aplicação) segue promovido (livro *This Is For
Everyone*, 2025) mas a adoção é lenta: "pilotos promissores, mas efeitos de rede difíceis"; sem
hosting de Pod não-experimental (Wikipedia/Solid, 2025; The New Stack, 2024). A crítica mais afiada:
o problema **não é técnico, é social/econômico** — RDF é "imposto de complexidade" e "não há
incentivo para megaplataformas adotarem protocolos interoperáveis" (repolex.ai, 2025).

**Personal Data Stores (PDS)** — HAT, Mydex, openPDS, Databox, Solid, Digi.me — "ainda não
alcançaram adoção ampla" por barreiras legais/técnicas/sociais: exportar dado é penoso, o dado
**perde contexto** fora da origem (algoritmos não conseguem mais compará-lo), e há medo de
privacidade justamente por ser sensível (Fallatah, Barhamgi & Perera, *Sensors*, 2023).

**MyData / cooperativas de dados** — princípios fortes (controle humano-cêntrico, governança
democrática) mas "desafios de coordenação, escalabilidade e engajamento" — falta massa crítica, não
princípio (MyData, 2024; arXiv 2504.10058, 2025).

## Local-first: o vetor que amadureceu

Os 7 ideais (Ink & Switch, 2019 — sem spinners, multi-device, offline, colaboração, longevidade,
privacidade, controle) seguem canônicos. O substrato (CRDTs) amadureceu: **Automerge 3.0** (mai/2025,
~10× menos memória, core Rust); **Loro 1.0** (2024); Yjs (PowerSync, 2025; Smashing, 2026). Ainda
imaturo em produto ("local-first em 2024 ≈ React em 2013"; termo diluído por sistemas
server-authoritative — Heavybit, 2024). O argumento de soberania que ficou concreto em 2026: dado no
próprio disco é **irrevogável e incoercível** — "um modelo no seu próprio disco não pode ser
revogado" (após a diretriz de export-control de jun/2026 que desabilitou Claude para estrangeiros —
MindStudio/XDA, 2026).

## "Share distilled, keep raw local": padrão vencedor, mas poroso

**Federated learning** treina "sem centralizar o dado bruto — só parâmetros/gradientes trocados",
combinado com **differential privacy** (ruído calibrado nas atualizações; local-DP adiciona ruído no
cliente) — tema de 1ª ordem para o regulador europeu (EDPS TechDispatch #1/2025). O **mecanismo
maduro de destilado verificável** é o **W3C Verifiable Credentials Data Model v2.0** (Recommendation,
mai/2025): provar um atributo derivado com *selective disclosure*, sem contatar o emissor nem
entregar a fonte; empurrão regulatório real via eIDAS 2.0 (arXiv 2601.19837, 2026).

**O alerta:** "destilado" **não é** sinônimo de "seguro". Ataques de *gradient/model inversion*
(2024-2026) reconstroem o dado bruto de treino a partir de gradientes compartilhados; com priors
generativos/difusão, a reconstrução ficou mais fiel. Defesas (DP, sparsification, clipping) custam
acurácia e **não sabem quais gradientes vazam** (USENIX Security 2025, *SoK: Gradient Inversion*;
arXiv 2505.20026). Corolário: um resumo/embedding rico pode ser tão reconstruível quanto o original.

## O trade-off em 2026: soberania venceu a retórica dos efeitos de rede

Soberania de dados virou "prioridade de infraestrutura", puxada por regulação/geopolítica (EU Data
Act aplicável 12/set/2025; ~75% da população sob lei de privacidade — Gartner). A síntese pragmática
da literatura: treinar "entre jurisdições sem mover o dado bruto" + "federação de dado pessoal com
políticas definidas pelo sujeito" como o compromisso entre rede e soberania (FPF, 2026; Springer,
2026). Quem defende o quê: *federar* → MyData/Solid (sem massa comprovada); *local-only* → local-first
+ IA local (irrevogabilidade); *veredito 2026* → **híbrido destilado**, nomeado pela própria
literatura como "o compromisso prático".

## Referências

- Ink & Switch (2019). *Local-first software: You own your data, in spite of the cloud.* https://www.inkandswitch.com/essay/local-first/
- PowerSync (2025). *Local-First Software: Origins and Evolution.* https://powersync.com/blog/local-first-software-origins-and-evolution
- Wikipedia (2025). *Solid (web decentralization project).* https://en.wikipedia.org/wiki/Solid_(web_decentralization_project)
- repolex.ai (2025). *Everything You Should Know about Solid Pods.* https://repolex.ai/blog/2025/11/08/EVERYTHING-YOU-SHOULD-KNOW-ABOUT-SOLID-PODS/
- Fallatah, Barhamgi & Perera (2023). *Personal Data Stores (PDS): A Review.* Sensors. https://doi.org/10.3390/s23031477
- arXiv 2504.10058 (2025). *Data Cooperatives: Democratic Models for Ethical Data Stewardship.* https://arxiv.org/pdf/2504.10058
- W3C (2025). *Verifiable Credentials Data Model v2.0* (Recommendation). / arXiv 2601.19837 (2026). *SSI and eIDAS 2.0.* https://arxiv.org/pdf/2601.19837
- EDPS (2025). *TechDispatch #1/2025 — Federated Learning.* https://www.edps.europa.eu/data-protection/our-work/publications/techdispatch/2025-06-10-techdispatch-12025-federated-learning_en
- USENIX Security (2025). *SoK: Gradient Inversion Attacks in Federated Learning.* https://www.usenix.org/system/files/usenixsecurity25-carletti.pdf
- FPF (2026). *2026: A Year at the Crossroads for Global Data Protection.* https://fpf.org/blog/2026-a-year-at-the-crossroads-for-global-data-protection-and-privacy/
- Springer (2026). *Extending Personal Data Sovereignty… Governance of AI Training on Personal Data.* https://link.springer.com/chapter/10.1007/978-3-032-05673-3_2
