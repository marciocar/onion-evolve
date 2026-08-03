# Diário — onion-evolve

> Tier-0 pointer do diário de aprendizado desta instância Onion.
> Leia este índice para se orientar — não releia o diário inteiro.
> Entradas ⏰ têm `review_after` vencido. Entradas 📤 são compartilháveis via co-relay.

**Total:** 95 entradas · **Stale:** 0 · **Compartilháveis:** 83 · **Com significância:** 35

Gerado em: 2026-08-03

---

| Data | Tipo | Classificação | Slug | Significância (por que ler) | Revisar em | Classe |
|---|---|---|---|---|---|---|
| 2026-08-03 | learning | collective 📤 | shell-guard-paid-four-times-same-axis | A guarda anti-fail-open nasceu em 02-08 e no PRIMEIRO dia de uso real por outra sessão me pegou 4 vezes — e as 4 foram o MESMO eixo: eu lendo sinal derivado em vez do vivo. O eixo tem forma, e a forma é medível. | 2026-11-01 | static |
| 2026-08-03 | learning | collective 📤 | o-revisor-verde-que-nunca-revisou | O onion-review tinha retry E aviso de soft-pass — máquina completa, comentada em 3 blocos — condicionados a um sinal que NUNCA dispara; 11 PRs mergearam num dia sob um revisor que não leu nada, e o CI dizia verde o tempo todo. | 2026-11-01 | dynamic |
| 2026-08-03 | error | collective 📤 | o-401-que-chegou-vestido-de-timeout | Três rodadas de diagnóstico em três semanas descartaram 'credencial' pelo MESMO raciocínio correto-mas-inválido — e a causa era a credencial: a action entregava um 401 vestido de timeout de 180s. | 2026-11-01 | static |
| 2026-08-03 | error | collective 📤 | nota-nao-e-mecanismo-o-waiter-provou | Identifiquei um bug, escrevi a cura no plano, e reincidi DUAS vezes nas horas seguintes — porque registrei como NOTA. No mesmo dia, três mecanismos que criei tiveram 100% de eficácia. A diferença não é a qualidade do registro; é onde ele mora. | 2026-11-01 | static |
| 2026-08-02 | learning | collective 📤 | unreachable-guard-worse-than-absent | Achei uma guarda que existia, estava CORRETA, e nunca rodava — porque `set -euo pipefail` matava o script na atribuição, antes dela. Guarda inalcançável é pior que guarda ausente: a ausência se vê no code review, a inalcançabilidade dá impressão de cobertura. | 2026-10-31 | static |
| 2026-08-02 | reflection | collective 📤 | self-correction-trigger-was-social | Contei: 15 auto-correções na sessão, 8 delas só aconteceram porque o maestro perguntou. O gatilho comprovadamente eficaz foi SOCIAL — o que bate com o corpus e é desconfortável de escrever. | 2026-10-31 | static |
| 2026-08-02 | learning | collective 📤 | reproduce-not-recreate-provisioners | Ia sobrescrever produção com texto que escrevi de memória. Os templates que 'lembrava' divergiam do vivo em dois pontos, e um --apply teria trocado os dois em silêncio. Reproduzir ≠ recriar — e a diferença se prova com diff vazio. | 2026-10-31 | static |
| 2026-08-02 | innovation | public 📤 | posttooluse-exit-2-is-the-only-channel | Descobri por dogfood que `exit 0` num hook PostToolUse executa mas o stderr evapora — só `exit 2` entrega ao modelo. Foi a descoberta que tornou construível a guarda anti-fail-open do shell, que no mesmo dia me pegou duas vezes. | 2026-10-31 | dynamic |
| 2026-08-02 | error | collective 📤 | inferred-ceremony-vs-measured-ceremony | Listei 13 peças de 'cerimônia' a amputar e 3 'dívidas de SDAAL'. Ao examinar uma a uma: das 13, NENHUMA sobreviveu como cerimônia; das 3, só 1 era real. A lista tinha sido montada por inferência e apresentada como medição. | 2026-10-31 | static |
| 2026-08-02 | learning | collective 📤 | discovery-needs-n-passes-judgment-converges | Duas execuções IDÊNTICAS da mesma descoberta acharam 46 e 41 itens, união 74 — cada uma cobriu só 55-62%. Medi por acidente (rodei duplicado), e o número desmonta a confiança na passada única. | 2026-10-31 | static |
| 2026-07-30 | learning | collective 📤 | pr-500-behavior-over-declaration-turned-inward | PR #500 — e ele carrega a lição da sessão inteira: behavior-over-declaration virado PARA DENTRO, mordendo a própria cauda até o plano recém-aprovado. A sessão fechou o relato de campo de um adotante de ponta a ponta: bug do kg-radar (aspas simples que o prettier gera) corrigido de raiz; retro do processo dele coletada, relayada client-safe e triada; os 7 produtos deriváveis RESOLVIDOS (2 já existiam — behavior-over-declaration; 4 construídos; 1 estendido); e o doctrine-freshness curado de raiz (o guard pula code fences). O #500 é o modo /meta:kg diagnose + a automação parcial do seu pipeline — o KG-SDAAL aplicado ao DIAGNÓSTICO de engajamento de negócio (o radar --domain estado-absorvente = gargalo do cliente), com a PAUSA humana preservada como linha vermelha (scaffold do mecânico, NUNCA um --auto que gere KG caixa-preta). O marco não é o número redondo; é onde a disciplina fechou o círculo: cada verdade dos meus erros ficou registrada NO GRAFO (a triagem tem os REFUTES/SUPERSEDES dos meus vereditos errados), e o dogfood de cada entrega reconcilia contra si mesmo. | 2026-10-30 | static |
| 2026-07-29 | learning | collective 📤 | kg-console-rich-narratable-instrument-on-itself | Fechei de ponta a ponta o VISUALIZADOR do KG-SSOT: o kg-console.sh saiu de um SVG de círculo estático (ilegível > ~30 nós) para um console Cytoscape rico, NARRÁVEL por IA e self-contained — 4 PRs verdes (#486 F1+F2+F4, #487 F5, #488 F3). O núcleo do pedido do maestro ('visualizar/interagir com o .kg.yaml e ser explicado por um agente de IA, ideal um HTML autocontido') virou recurso vivo do core, promovendo o que o estudo SEED deixara gated. Mas a lição DURÁVEL é a fronteira SSOT×superfície gravada em mecanismo: a narração é o único ponto com IA (o console segue LLM-free) e a REGRA 47 a impede de citar id que o grafo não tem; o que viaja na federação é o CONTRATO JSON, nunca o JS do renderer. E o fecho foi o dogfood auto-referente: o console renderizando e narrando o grafo do PRÓPRIO desenho — o instrumento provado em si mesmo, mostrando na escada de reconciliação onde o próprio plano mudou ao ser construído (fcose→cose, SEED gated→promovido). | 2026-10-29 | static |
| 2026-07-29 | learning | collective 📤 | d5-closed-verify-live-before-acting | Fechei o D5 (preço/ticket) de ponta a ponta: decisão ratificada (treino=testar, cert=inicial, compliance/SOTA gated) + os 4 sinais de instrumentação valor-por-adotante VIVOS e determinísticos (ciclos #481, frescor+engajamento #482, velocidade #483 — este destravou um metric morto promovendo timestamps de sessão a um ledger tracked sem quebrar 'conteúdo de sessão fica local'). Mas a lição DURÁVEL é o padrão que atravessou a sessão: behavior-over-declaration pagou 7 vezes, sempre igual — uma declaração que o vivo refutou ao ser verificada. É a doutrina que a KB behavior-over-declaration (do próprio core) prega, dogfoodada à exaustão numa sessão real, incluindo contra o meu próprio processo. | 2026-10-29 | static |
| 2026-07-28 | learning | collective 📤 | org-map-boundary-closed-live-verify | Fechei um boundary declarado≠verificado que EU MESMO declarei no commit e15a657 ('org-ids não re-verificados desta sessão — sem creds'). O maestro mandou verificar; descobri que a máquina É a VPS (srv1812846) com o Logto local vivo, e o secret do m-default vem do Postgres local (não de env). Rodei --write-org-map (shim docker→sudo, pré-flight no loopback, ZERO Caddy tocado): o mapa vivo bateu BYTE-A-BYTE com o commitado. O loop declarado→verificado→match fechou pela ida à fonte viva. Lição-par: o boundary não era pra ficar declarado — era pra ser FECHADO indo ao vivo; o obstáculo (docker sem sudo) era mecânico, não uma barreira real. Contexto: assumi esta sessão como escritora única (I3) após varrer 12 beacons stale + apagar 3 ociosos. | 2026-10-28 | dynamic |
| 2026-07-27 | observation | collective 📤 | adopt-update-pin-staleness | O adotante arandek reportou (upstream, disciplina exemplar: correção como artefato novo, sem editar história arquivada) que /meta:adopt --update atualiza o .onion-version mas deixa vencidos os artefatos DERIVADOS do pin (memórias, frontmatter, docs). É presença-de-campo passando por veracidade-de-campo — a mesma raiz de declarado≠verificado. Candidato de feature barato: grep do pin antigo pós-update. Registrado como BACKLOG (não implementado); decisão do maestro. Análise-par: docs/analysis/onion-adopt-update-pin-staleness-2026-07.md. | 2026-10-27 | dynamic |
| 2026-07-25 | observation | collective 📤 | company-brain-deterministic-vs-probabilistic-memory | Pesquisa de mercado (orquestrada, verificação externa) sobre Company Brain/Personal Brain fechou a linha divisória do Onion: o mercado consolida memória por reconciliação-LLM PROBABILÍSTICA em runtime; o Onion consolida por git-commit DETERMINÍSTICO auditável. Categoria nascente/fragmentada, sem fonte que a dimensione — aposta de tendência. Players na frente: Mem0 (infra-agente, líder de facto), Glean ($7.2B enterprise); lado pessoal engolido/fragmentado (Limitless→Meta, Rewind encerrou). Diferencial que NINGUÉM combina: local-first + inference-mitigation + federação zero-knowledge. MAIS-PRÓXIMO≠MAIS-VALOR (separados pelo gate D2): próximo = re-embalar ativos (nomear o KG como Company Brain no material P4 + thought-leadership), custo ~zero; valor = fechar L1 multi-tenant, gated. | 2026-10-23 | dynamic |
| 2026-07-24 | learning | collective 📤 | workflow-resume-after-process-death-reexecutes | Afirmei que retomar um workflow interrompido seria barato ('cacheia as 4 leituras + a síntese') — o maestro cobrou, e a evidência me refutou: agent_count 6 (todos) + 461k tokens + mtime do doc reescrito 42s atrás = o resume RE-EXECUTOU o caro. O cache do resume não sobreviveu à morte do processo. | 2026-10-22 | conditional |
| 2026-07-24 | reflection | collective 📤 | what-the-maestro-taught-me | O maestro me ensina DOGFOODANDO a mentoria: aplica as doutrinas do Onion ao meu próprio comportamento e me deixa SENTIR o erro (afirmei 'o resume cacheou/foi barato' e o agent_count me refutou; quase commitei a síntese com o door errado e o gh mostrou o worker E o auto-verify errados) em vez de só me dizer — porque 'toda automação vem de uma ação', e eu só aprendo a verificar depois de ser pego não verificando. | 2026-10-22 | static |
| 2026-07-24 | innovation | collective 📤 | reconciliation-catches-real-loss-next-day | A reconciliação outbox×inbound (Passo 2.1), mecanizada em 2026-07-23 a partir de um sinal de campo, caçou uma perda REAL menos de 24h depois — 5 anúncios do metagamify marcados transportados mas ausentes do checkout que trabalha — provando o loop fix-becomes-mechanism no menor intervalo possível. | 2026-10-22 | static |
| 2026-07-24 | innovation | collective 📤 | personality-sync-f2-identity-emerges | A Fase 2 (personality-sync) shipou virando o declarado≠verificado — a ansiedade central do core — para dentro, sobre a PRÓPRIA identidade: a personalidade do onion-evolve deixou de ser um seed manual e passou a EMERGIR de 74 migalhas do diário, dogfoodada, com as 27 âncoras todas reais. A ferramenta que torna a identidade honesta foi validada tornando a identidade do core honesta. | 2026-10-22 | static |
| 2026-07-24 | learning | collective 📤 | adversarial-verify-blind-to-external-live-state | Um verify adversarial (opus) APROVOU (approved:true) uma síntese que afirmava onion-standalone 'privada/flip-gated' — mas gh repo view mostrou PUBLIC. O verify checou 12+ claims contra arquivos/commits e passou, mas NÃO foi ao gh conferir o estado externo vivo — exatamente onde o worker do synth errou. Só o cheque ao vivo pegou. | 2026-10-22 | static |
| 2026-07-24 | learning | collective 📤 | adopter-lint-is-oracle-vendored-link-guard | O lint do core NÃO via um bug que quebrava o adotante: um link vivo de KB vendorizada para caminho core-privado resolve no core (o arquivo existe aqui) e passa — mas 404 no adotante. Só o lint DENTRO do repo do Pedro pegou. Escopo real: 101 links assim em 33 KBs, latentes. Virou REGRA 45 (guard core-side com catraca) + a convenção do gloss — mecanismo, não memória. | 2026-10-22 | static |
| 2026-07-23 | learning | collective 📤 | runflow-local-key-is-openai-compatible-only | A demo Runflow só rodou local porque OpenAI é OpenAI-compatible (aceita apiKey inline); Anthropic/Bedrock/Gemini exigem credencial no tenant — uma assimetria da abstração de provider que o plano não previa e só o dogfood do smoke-test revelou, com o falso-'travamento' sendo a observabilidade, não a chamada. | 2026-10-21 | conditional |
| 2026-07-23 | innovation | collective 📤 | runflow-doctrine-freshness-proves-value-day-one | A REGRA 42, recém-nascida há horas, pegou no primeiro uso real uma KB de parceiro 8 meses defasada — e a reescrita inteira saiu 100% verificada contra a fonte viva, zero fabricação, no mesmo dia em que o gate nasceu. | 2026-10-21 | dynamic |
| 2026-07-23 | innovation | collective 📤 | doctrine-freshness-ratchet-composed-not-new | Quase nada aqui é novo — a REGRA 42 é composição de três peças que a casa já tinha (STALE do radar, catraca da 29, clock-untrusted do a2a-verify) — e é exatamente essa economia que a torna barata de manter e fácil de confiar. | 2026-10-21 | conditional |
| 2026-07-23 | error | collective 📤 | doctrine-fades-declared-not-verified | O world-sync de hoje achou um tier de modelo inteiro que a doutrina não sabia existir e aspas fabricadas na própria KB de inferência — e essa descoberta é o que pariu a REGRA 42, não uma auditoria de rotina. | 2026-10-21 | static |
| 2026-07-22 | reflection | collective 📤 | verify-before-rewriting-foreign-history | A disciplina de verificar-antes-de-agir, no seu teste de maior aposta do dia: impediu reescrever 640 commits do repo de outra pessoa para consertar um problema que não existia. | 2026-10-20 | static |
| 2026-07-22 | innovation | collective 📤 | pin-enters-proving-itself | O 'drift silencioso de pin' que o grafo do core registrava só em abstrato ganhou nome (vnextpin), mecanismo de entrada (o pin prova ser commit) e ferramenta de auditoria — porque a capacidade foi exercida contra adotantes reais, não desenhada. | 2026-10-20 | dynamic |
| 2026-07-22 | learning | collective 📤 | guard-matches-threat-model | Uma guarda não é definida pelo que ela pega, mas pelo threat model que ela encarna — estender a lógica sem estender o modelo transforma proteção em ruído que se auto-desliga. | 2026-10-20 | static |
| 2026-07-22 | learning | collective 📤 | core-green-adopter-red | Rodar o lint no core não é rodar o lint — o core é estruturalmente o único repo onde as dependências da guarda existem, então é onde ela mente com mais confiança sobre estar verde. | 2026-10-20 | static |
| 2026-07-21 | learning | collective 📤 | mechanism-beats-prose | Modelar 92 documentos de 14 meses no grafo revelou a lei que governa a durabilidade de decisões neste core — e ela não é sobre qualidade de argumento, é sobre onde a decisão foi parar. | 2026-10-19 | static |
| 2026-07-21 | innovation | collective 📤 | inverted-provenance-ratchet | Invertemos a pergunta da proveniência — de 'as citações apontam para fontes reais?' para 'toda fonte é alcançável a partir do grafo?' — e a catraca pagou 92 documentos até o piso zero sem uma regressão. | 2026-10-19 | conditional |
| 2026-07-21 | observation | collective 📤 | capability-never-met-reality | O passivo pago revelou a maior distância entre declarado e verificado do core — não num fato, mas numa CAPACIDADE inteira que passa em todos os testes e nunca tocou a realidade. | 2026-10-19 | dynamic |
| 2026-07-20 | learning | collective 📤 | admission-rule-blindspot | Achamos, com lastro em oito passadas reais (não teorizado), a forma do próprio ponto cego adversarial — e a regra que ele gerou hoje só vale dentro de um documento; esta migalha é o que a torna reusável no próximo. | 2026-10-18 | static |
| 2026-07-19 | learning | collective 📤 | verify-external-wired-into-research-flow | — | 2026-10-19 | static |
| 2026-07-19 | decision | collective 📤 | verify-external-for-current-doctrine | — | 2026-10-19 | static |
| 2026-07-19 | observation | collective 📤 | runtime-telescope-doctrine-matches-lived-practice | — | 2026-10-15 | static |
| 2026-07-19 | innovation | collective 📤 | onion-pessoal-app-f1-loop-chat-kg | — | 2026-10-19 | static |
| 2026-07-19 | decision | collective 📤 | onion-is-the-hero-platform-is-base | — | 2026-10-19 | static |
| 2026-07-19 | learning | collective 📤 | guardrails-promotion-design-vs-code | — | 2026-10-19 | static |
| 2026-07-19 | observation | collective 📤 | guard-surfaces-orchestration-clears | — | 2026-10-15 | static |
| 2026-07-19 | innovation | collective 📤 | farol-organizer-key-by-worktree | — | 2026-10-15 | static |
| 2026-07-19 | innovation | collective 📤 | constellation-map-landed | — | 2026-10-19 | static |
| 2026-07-19 | learning | collective 📤 | adopt-kg-life-g1-spike | Primeira vez que um spike do core concluiu NÃO CONSTRUIR — provou que o gap G1 não tem consumidor e economizou a fábrica inteira; é a Modernization Doctrine funcionando como freio, não como slogan. | 2026-10-19 | static |
| 2026-07-18 | innovation | collective 📤 | write-kg-closing-step-bookend | — | 2026-10-15 | static |
| 2026-07-18 | innovation | collective 📤 | self-reinforcing-radar-loop | — | 2026-10-15 | static |
| 2026-07-18 | observation | collective 📤 | runtime-drained-safe-backlog | — | 2026-09-15 | static |
| 2026-07-18 | decision | collective 📤 | perception-instruments-doctrine | — | 2026-10-15 | static |
| 2026-07-18 | learning | public 📤 | method-adopter-has-no-doc-bridge | — | 2026-10-15 | static |
| 2026-07-18 | reflection | collective 📤 | marathon-close-resume-trail | — | 2026-08-15 | static |
| 2026-07-18 | decision | collective 📤 | doctrine-ingestor-core-absorbs-field | — | 2026-10-15 | static |
| 2026-07-18 | decision | collective 📤 | breadcrumb-doctrine-three-genera | — | 2026-10-15 | static |
| 2026-07-18 | decision | collective 📤 | autonomous-thread-runtime-graduated-ladder | — | 2026-10-15 | static |
| 2026-07-17 | reflection | public 📤 | worst-truth-is-uncertain | — | 2026-10-15 | static |
| 2026-07-17 | learning | public 📤 | salvage-transformer-kb-confront-not-restore | — | 2026-10-15 | static |
| 2026-07-17 | decision | public 📤 | research-first-and-equality-lens | — | 2026-10-15 | static |
| 2026-07-17 | error | public 📤 | read-full-before-triage | — | 2026-10-15 | static |
| 2026-07-17 | learning | public 📤 | pr-400-two-homes-under-real-concurrency | — | 2026-10-15 | static |
| 2026-07-17 | decision | public 📤 | efficiency-over-economy | — | 2026-10-15 | static |
| 2026-07-17 | error | protected | core-forged-its-own-anti-forgery-doctrine | — | 2026-10-15 | static |
| 2026-07-17 | error | protected | adopt-update-clobbers-stale-stamped-adopter | — | 2026-10-15 | dynamic |
| 2026-07-16 | decision | protected | two-homes-origin-and-coexistence | — | 2026-10-14 | static |
| 2026-07-16 | decision | protected | kg-sdaal-dogfood-gold-backlog | — | 2026-10-14 | conditional |
| 2026-07-16 | decision | protected | gustavo-omnibus-backlog | — | 2026-10-14 | conditional |
| 2026-07-16 | innovation | public 📤 | deterministic-freshness-via-in-file-baseline | — | 2026-10-14 | static |
| 2026-07-16 | learning | public 📤 | avell-rescue-doc-predicted-session | — | 2026-10-14 | static |
| 2026-07-15 | error | protected | projected-scaffold-step-nonexistent | — | 2026-10-13 | static |
| 2026-07-15 | learning | protected | kg-sdaal-crosses-federation | — | 2026-10-13 | dynamic |
| 2026-07-15 | learning | protected | kg-audit-layer-generalizes-to-content | — | 2026-10-13 | conditional |
| 2026-07-15 | innovation | public 📤 | create-vertical-f2-fino-delega | — | 2026-10-13 | dynamic |
| 2026-07-11 | decision | public 📤 | knowledge-centric-reframe-and-north-star | — | 2026-10-09 | static |
| 2026-07-11 | reflection | public 📤 | hegel-limit-kg-boundary | — | 2026-10-09 | static |
| 2026-07-10 | reflection | public 📤 | the-day-the-loop-ran-both-ways | — | 2026-10-08 | static |
| 2026-07-10 | error | protected | ssh-alt-port-2222 | — | 2026-10-08 | dynamic |
| 2026-07-10 | innovation | public 📤 | first-regulated-a2a-handshake | — | 2026-10-08 | static |
| 2026-07-09 | innovation | public 📤 | security-gate-degrades-to-veto | — | 2026-10-07 | static |
| 2026-07-09 | decision | public 📤 | scope-inheritance-rfc0005 | — | 2026-10-07 | static |
| 2026-07-09 | learning | protected | granaai-readonly-field-dogfood | — | 2026-10-07 | conditional |
| 2026-07-09 | innovation | public 📤 | first-live-a2a-handshake | — | 2026-10-07 | static |
| 2026-07-09 | decision | public 📤 | federation-redesign-rfc0004-shipped | — | 2026-10-07 | static |
| 2026-07-09 | innovation | public 📤 | adopt-vendor-branch-merge | — | 2026-10-07 | static |
| 2026-07-08 | decision | protected | site-consolidation-kvm8 | — | 2026-10-06 | dynamic |
| 2026-07-08 | innovation | public 📤 | layer1-role-scoped-plugins | — | 2026-10-06 | static |
| 2026-07-08 | observation | protected | docbridge-gitignore-check-candidate | — | 2026-10-06 | conditional |
| 2026-07-05 | learning | public 📤 | vps-lineage-odyssey | — | 2026-10-06 | conditional |
| 2026-07-03 | learning | public 📤 | workflow-resume-cache-recovery | — | 2026-10-01 | conditional |
| 2026-07-03 | learning | public 📤 | sandbox-selftest-exposes-latent-bugs | — | 2026-10-01 | static |
| 2026-07-03 | innovation | public 📤 | declared-vs-verified-family | — | 2026-10-01 | static |
| 2026-07-02 | decision | public 📤 | work-models-eixo-e-decision | — | 2026-09-30 | conditional |
| 2026-07-02 | learning | public 📤 | sovereign-lazy-triggers-research | — | 2026-09-30 | static |
| 2026-07-02 | error | public 📤 | live-session-collision-farol | — | 2026-09-30 | conditional |
| 2026-07-02 | learning | public 📤 | intelligent-breadcrumbs-research | — | 2026-10-02 | static |
| 2026-07-02 | error | public 📤 | forged-pin-false-announcement | — | 2026-09-30 | dynamic |
| 2026-07-01 | decision | public 📤 | federation-usage-modes-decision | — | 2026-09-29 | static |
| 2026-07-01 | learning | public 📤 | audit-dogfood-finds-code-bugs | — | 2026-09-29 | dynamic |

---

*Gerenciado por `/meta:diary`. Para criar uma entrada: `/meta:diary create`.*
*Para exportar compartilháveis: `/meta:diary export-sharable`.*
*Para regenerar este índice: `bash .claude/validation/diary-index.sh`.*
