## Veredito por cenário

**(A) Grana.Ai — fintech brasileira regulada: NÃO use Evolution API. Nem qualquer lib não-oficial.**
Vá para o canal **oficial** (WhatsApp Cloud API), preferencialmente **via BSP que declare adequação regulatória** — a **Zenvia** declara em fonte primária (site oficial, segmento Finanças) conformidade formal com as Resoluções BACEN 4.658/2018 e 4.893/2021 [S2-F12]. Alternativa igualmente oficial: Cloud API **direto** como Tech Provider [S1-F8], somada a um BSP de camada fina e barata (360dialog é pass-through com **zero markup** sobre as tarifas da Meta, assinatura €49/canal [S2-F3]) — mas aí a due diligence de compliance corre por conta da Grana.Ai.
Por quê: qualquer cliente não-oficial (Evolution incluído) **viola os Termos Business da Meta** — proibição explícita de engenharia reversa, scraping e automação sem consentimento [S4-F1] — e a central de ajuda oficial trata isso como violação que escala de throttling a **banimento permanente** [S4-F3], com banimentos de números Baileys **documentados e ativos** em 2024-2026 [S4-F4]. Nenhum dos seis projetos é suportado/endossado pela Meta [S3-F8]. Para uma entidade regulada que usa o canal em cobrança, onboarding e atendimento, "conta banida sem aviso" é risco material inaceitável.

**(B) Dogfood interno do Onion: Evolution API também NÃO é a melhor — mas por razões diferentes.**
Se o objetivo é exercitar uma lib **não-oficial self-hosted**, há opções com licença mais limpa e menos atrito operacional: **Baileys** (MIT puro, sem cláusulas, base de facto do ecossistema [S3-F3][S5-F1]), **whatsapp-web.js** (Apache-2.0, mais estrelas do conjunto, ativo em 2026 [S3-F6][S5-F3]) e **WAHA** (Apache-2.0, que **descontinuou o modelo pago** em 2026.6.1 — tudo grátis, sem login Docker [S3-F4]). A Evolution carrega um defeito específico que as outras não têm: seu FAQ diz "sem cláusulas adicionais" enquanto o próprio LICENSE impõe **Apache-2.0 COM condições adicionais** (Usage Notification obrigatória mesmo em sistema fechado, gatilho de licença comercial) — **contradição confirmada em duas primárias vivas** [S3-F2] — mais a fricção de ativação/heartbeat headless desde a v2.4.0 [S3-F1]. Se o dogfood tolera o canal oficial, a **Cloud API tem tier de acesso gratuito** (sem taxa de acesso; free-form grátis na janela de 24h; limite inicial de 250 contatos/24h) [S2-F7][S1-F4][S1-F5] — suficiente para teste interno e sem risco de ban.

**Divergência explicada:** o cenário A é governado por **durabilidade regulatória/contratual** (não pode arriscar ban, precisa de postura de compliance) — isso mata a Evolution e todo o não-oficial. O cenário B é governado por **limpeza de licença + atrito operacional** com stakes de ban baixos (número descartável) — aqui o não-oficial é defensável, mas a Evolution perde para WAHA/Baileys.

## Matriz de opções

| Opção | Custo | Risco ToS/ban | Licença | Esforço de operar | Fit fintech (A) | Fit dogfood (B) |
|---|---|---|---|---|---|---|
| **Evolution API** (Baileys) | Infra só; tier community grátis [S3-F1] | **Alto** — viola ToS [S4-F1], bans ativos [S4-F4] | Apache **+ condições adicionais**; FAQ contradiz LICENSE [S3-F2] | Médio-alto + ativação/heartbeat headless [S3-F1] | ❌ Proibitivo | ⚠️ Funciona, mas pior licença do grupo |
| **Baileys** direto | Infra só | **Alto** [S4-F1][S4-F4] | **MIT puro** [S3-F3] | Alto (você constrói tudo) | ❌ | ✅ Mais limpo |
| **whatsapp-web.js** | Infra só | **Alto** [S4-F1][S4-F4] | Apache-2.0 [S3-F6] | Médio (Puppeteer) | ❌ | ✅ Ativo, popular |
| **WAHA** | Infra só; **100% grátis** desde 2026.6.1 [S3-F4] | **Alto** [S4-F1][S4-F4] | Apache-2.0 [S3-F4] | Médio | ❌ | ✅ Sem paywall/login |
| **Cloud API oficial (direto)** | Per-message; sem taxa de acesso [S2-F7]; service/utility grátis na janela até out/2026 [S5-F4] | **Nenhum** (canal oficial) | Termos comerciais Meta | Onboarding + verificação de negócio [S1-F8] | ✅ com compliance próprio | ✅ (tier grátis) |
| **Cloud API via BSP** | Meta per-message + markup (markup = *hypothesis* [S2-F2]); 360dialog €49/canal zero-markup [S2-F3]; Zenvia assinatura USD [S2-F5] | **Nenhum** | Termos comerciais | **Menor** (gerenciado) | ✅✅ Zenvia declara BACEN [S2-F12] | ✅ (overkill p/ teste) |

## O que decide (o eixo)

**O eixo é um só: a natureza oficial × não-oficial do canal e sua durabilidade contra os Termos da Meta.**
Para a fintech (A) esse fator **decide sozinho** e encerra o debate: o não-oficial viola o ToS [S4-F1], a Meta pune com ban permanente [S4-F3] e há banimento real documentado [S4-F4]. Custo, licença ou esforço são irrelevantes quando o canal pode sumir sem aviso sob uma entidade regulada — a régua é eficácia/durabilidade, não economia.
Para o dogfood (B), como o não-oficial é aceitável, o eixo desce um nível para **limpeza de licença e atrito de operação** — e aí a Evolution perde para WAHA/Baileys/wwebjs pela contradição confirmada do seu licenciamento [S3-F2]. Em nenhum dos dois cenários a Evolution é a melhor.

## Contra-argumento honesto

O melhor argumento **contra** minha recomendação vale só para o dogfood (B): o propósito declarado do dogfood é justamente **testar a Evolution API que o maestro trouxe**. Non-oficial dá custo marginal zero, liberdade técnica total e **zero fricção de onboarding/verificação de negócio** [S1-F8] — exatamente o que iteração interna rápida quer. Ban em dogfood é baixo risco (número descartável). Sob essa lente, rodar a Evolution para *aprender onde ela quebra* é dogfood legítimo (é a própria doutrina da casa: invocar o artefato e observar o modo-de-falha). **Concessão:** esse argumento justifica *experimentar* a Evolution como exercício, mas **não** a elege como "melhor opção" — mesmo aceitando não-oficial, WAHA/Baileys entregam o mesmo com licença íntegra e sem o heartbeat obrigatório [S3-F2][S3-F4]. Para a fintech (A) **não há contra-argumento honesto**: nenhum ganho de custo/liberdade compensa banimento de canal regulado.

## Confiança e gaps

**Sustentam a decisão (confirmed):** migração para per-message desde jul/2025 [S1-F1]; billing em BRL/Brasil obrigatório até jun/2027 [S1-F2] (planejar para Grana.Ai); janela de 24h e limites de mensageria [S1-F4][S1-F5]; inexistência de trilha fintech dedicada [S1-F9]; proibições de ToS [S4-F1][S4-F2]; enforcement até ban [S4-F3]; bans Baileys documentados [S4-F4]; licenças de Baileys/wwebjs/WAHA/WPPConnect/venom [S3-F3 a S3-F7]; contradição de licença da Evolution [S3-F2]; não-oficialidade dos seis [S3-F8]; Zenvia declarando BACEN [S2-F12]; 360dialog zero-markup [S2-F3]; cobranças novas de out/2026 e ago/2026 [S5-F4].

**Ficou hypothesis (não sustenta decisão, só contexto):** markup típico de BSP 20-40% / US$0,003-0,010 [S2-F2][S2-F4]; preço marketing Brasil ~US$0,0625 [S1-F3] (só secundária); Evolution "mais adotada em no-code" [S3-F1]; "onda de bans como nova normalidade em 2026" [S5-F5]; bifurcação de mercado e "não-oficial crescendo em volume" [S5-F9]; multiplicador de custo utility→marketing 5x-7x [S1-F6]; risco de compliance BACEN por canal não-oficial como sistema-de-registro — **a norma citada (Res. Conj. 6) foi refutada como inaplicável** [S4-F7].

**Não foi possível verificar / exige parecer jurídico:**
- Se a adequação BACEN **declarada** pela Zenvia [S2-F12] cobre as obrigações específicas da Grana.Ai (é declaração de fornecedor, não certificação auditada — BACEN não certifica BSP).
- Aplicabilidade de LGPD/BACEN a canal não-oficial servindo de sistema de registro/retenção [S4-F7, corrigido — norma correta em aberto] e a exigência de rastreabilidade por autoria [S4-F8].
- Se telemetria de lib não-oficial (IP do servidor) configura transferência internacional sob LGPD [S4-F9] — depende de verificação técnica de código **e** parecer.
- Postura PCI-DSS ao evitar dados de cartão em template [S1-F10] — boa prática inferida, não política publicada pela Meta.
## Revisita 2026-09-03 (apêndice datado — 1º dogfood do `--revisit` do `/onion-research`)

Cadência forçada de 30 d (`cadenceDays: 30`); 6 nós vencidos re-medidos pela mesma votação adversarial (3 votos,
2 refutam), verificador **re-buscando a fonte** em vez de julgar citação antiga. Resultado: **1 reconfirmado**
(lock-in estrutural entre BSPs — o número porta, o histórico/fluxos não) e **5 superados** por `SUPERSEDES` com
nós datados `E_*_REVISITA_20260903` (preço de template BR, cálculo do quality rating, regras de 550 chars/10
emojis, lista de BSPs no Brasil, markup da 360dialog) — todos apoiados em **blog tier 4**; a fonte não sustenta
a afirmação hoje. Leitura honesta: *refutado* = "não sustentado pela fonte apresentada", não "o oposto é
verdade". Nenhum dos 5 eixos da pergunta (preço, limites, política, versão, banimento) teve mudança **verificada**
em fonte primária nesta passada — ausência de medição, não estabilidade. `meta.review_after` → 2026-10-03.
Achado de método: o corpus de julho carregava fatos de mercado/preço selados sobre blog — o gate de tier (REGRA 68)
teria barrado. Custo: 21 agentes, 1,32 M tokens (mais 1,37 M de uma rodada anterior invalidada pelo placeholder de
citação, corrigido no mesmo loop). SSOT: o grafo; run `wf_9487391f-594`.
