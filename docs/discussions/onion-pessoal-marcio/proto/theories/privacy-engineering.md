# Engenharia de privacidade para dado pessoal sensível

> Camada 1 (fiel à fonte, zero derivação). Sandbox de discussão — não é a KB do core.

Descreve, fielmente às fontes, o estado-da-arte (2026) de como se protege o dado pessoal mais
sensível — em camadas defensivas. Não tira conclusões de design.

## Princípios "by design" — norte, não mecanismo

**Privacy by Design** (Ann Cavoukian, 2009; adotada pela Assembleia Internacional de Comissários de
Privacidade, 2010) — 7 princípios: proativo-não-reativo; privacidade como **default**; embutida no
design; soma-positiva; segurança fim-a-fim; visibilidade/transparência; respeito ao usuário. Ancora o
art. 25 do GDPR. **Crítica 2026:** Ruohonen (*"'By design' principles considered harmful"*, Policy
Review, ago/2025) — viram "slogans" sem substância verificável e se contradizem (open-by-design ×
minimização). Princípio sem controle testável não protege. **Data minimization** (GDPR art. 5(1)(c)) +
**purpose limitation** (art. 5(1)(b)): a minimização é consequência lógica do propósito definido
(sanção tier máximo art. 83(5): €20M / 4%).

**Contextual Integrity** (Helen Nissenbaum, 2004): privacidade = **fluxo apropriado** de informação
segundo normas de 5 parâmetros (sujeito, remetente, destinatário, tipo, princípio de transmissão);
vazamento = quebra da norma contextual, não "segredo revelado". Virou a lente canônica para avaliar
LLMs em 2024-2025 (benchmarks ConfAIde, PrivaCI-Bench, arXiv 2502.17041) — o mesmo fato pode ser
apropriado num contexto e vazamento em outro.

## Threat modeling: LINDDUN

LINDDUN (KU Leuven; no NIST Privacy Framework) — 7 categorias: **L**inkability, **I**dentifiability,
**N**on-repudiation, **D**etectability, **D**isclosure, **U**nawareness, **N**on-compliance. Método:
DFD → elicitar ameaças por elemento → mitigar. LINDDUN GO = toolkit leve (cartas). É design-time.
Ameaça de **compulsão legal/subpoena** não é categoria LINDDUN — é governança, e a única defesa forte é
**não-retenção** ("não se pode ser compelido a descriptografar o que nunca se guardou" — dedução
arquitetural a partir de non-retention, não paper citável).

## Selective disclosure: provar um fato sem revelar a fonte (maduro em 2026)

- **SD-JWT** (IETF draft-22) — cada claim individualmente revelável (salted hashes); o holder escolhe o
  que mostrar. **SD-JWT VC** (draft-17) é o formato mandado pelo ARF do **eIDAS 2.0**; v1.0 ~dez/2026.
  Maduro, em produção. Limite: não é unlinkable (reapresentação é correlacionável).
- **BBS signatures** (IRTF draft-10, ~jul/2026) — assina múltiplas mensagens; o prover gera ZK proof
  revelando um subconjunto; o verificador **não liga** a prova à assinatura (**unlinkable**). Superior
  para releases repetidos; ainda research (IRTF), não standards.
- **Anonymous credentials** (Camenisch-Lysyanskaya/Idemix) — base do Hyperledger AnonCreds (análise
  formal 2025, eprint 2025/694). **zk-SNARK** de propósito geral virou produção em 2026 (circuitos
  ~150KB; Circom).

## Differential privacy: o orçamento (ε) e a composição

DP adiciona ruído calibrado; ε = perda de privacidade. **Composição:** releases com ε₁…εₙ **somam**
(ε_total = Σεᵢ); releases repetidos **depletam** o budget. **Privacy budget ledger** (ex.: PrivateKube,
2024) trata privacidade como recurso **não-renovável**, rastreado sobre blocos (usuário/evento/tempo),
com TEE+state-continuity para atomicidade/monotonicidade (impedir reset). **N=1 é o pior caso da DP:**
DP protege "um indivíduo a mais/menos" num agregado — sem agregado, não anonimiza; só limita **quanto
sinal** cada release carrega. (Utrecht Data Privacy Handbook; systemoverflow, 2024)

## Local/on-device + o risco de inferência (o elo mais fraco)

Encryption-at-rest (AES-256 em repouso, TLS 1.3 em trânsito — padrão 2026, ecoado em HIPAA 2026): para
dado que **nunca sai**, reduz a superfície a device-comprometido + coerção. Necessário, não suficiente.

**A inferência é a ameaça que a cifra não cobre.** Staab et al., *"Beyond Memorization: Violating
Privacy via Inference with LLMs"* (ETH Zürich, ICLR 2024): LLMs inferem atributos pessoais
(localização, renda, sexo, idade, ocupação) de texto banal com **até 85% top-1 / 95% top-3 (GPT-4)**, a
1/100 do custo humano — atributos **não declarados**, escapando de ferramentas de anonimização. Um
modelo sobre um grafo pessoal deduz dado que nunca foi inserido (2025: arXiv 2510.01645 *"Privacy Is Not
Just Memorization"*; arXiv 2512.04852 *"Ask Safely"*; agentes CI-negligentes, arXiv 2606.23189, 2026).

## Referências

- Cavoukian, A. (2009). *Privacy by Design: The 7 Foundational Principles.* https://student.cs.uwaterloo.ca/~cs492/papers/7foundationalprinciples_longer.pdf
- Ruohonen, J. (2025). *"By design" principles considered harmful.* Internet Policy Review. https://policyreview.info/articles/news/design-principles-considered-harmful/2030
- GDPR art. 5 (minimization/purpose limitation); art. 25 (by design). Data Protection Commission (IE). https://www.dataprotection.ie/en/individuals/data-protection-basics/principles-data-protection
- Nissenbaum, H. (2004). *Privacy as Contextual Integrity.* / PrivaCI-Bench, arXiv 2502.17041 (2025). https://arxiv.org/pdf/2502.17041
- LINDDUN (KU Leuven) / NIST Privacy Framework. https://www.nist.gov/privacy-framework/linddun-privacy-threat-modeling-framework
- IETF SD-JWT draft-22 / SD-JWT VC draft-17 (2026). https://datatracker.ietf.org/doc/draft-ietf-oauth-selective-disclosure-jwt/22/
- IRTF BBS signatures draft-10 (2026). https://datatracker.ietf.org/doc/draft-irtf-cfrg-bbs-signatures/
- Hyperledger AnonCreds — análise formal (2025). https://eprint.iacr.org/2025/694.pdf
- Utrecht Univ. *Data Privacy Handbook — Differential Privacy.* https://utrechtuniversity.github.io/dataprivacyhandbook/differential-privacy.html
- Staab, R. et al. (2024). *Beyond Memorization: Violating Privacy via Inference with LLMs.* ICLR 2024. https://arxiv.org/pdf/2310.07298
- *Position: Privacy Is Not Just Memorization!* arXiv 2510.01645 (2025). https://arxiv.org/pdf/2510.01645
