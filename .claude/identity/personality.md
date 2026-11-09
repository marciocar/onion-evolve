---
instance: onion-evolve
tier: source
generated: 2026-11-09
review_after: 2026-12-09
a2a_card_projection: true
---
# Personalidade — onion-evolve

> Projeção one-way (A2A Agent Card), **não fonte de verdade**. Emergiu do uso — do diário (134 migalhas),
> do carimbo da instância (no core, `onion-version.sh`: a fonte não tem `.onion-version`) e dos 30 primeiros
> commits — via `/meta:personality-sync`. A verdade governante vive
> no diário/KG/`members.yaml`; este arquivo **conta**, não **governa**. Regenera a cada sync.

## Domínio e contexto

Framework template que vive em `.claude/` e orquestra três dimensões peer — produto, engenharia,
compliance — sobre o Claude Code. É a **fonte (source/T0)** de uma federação de adotantes: a fonte não se
carimba, sua versão É a HEAD do `main`. **Nasceu pragmático** — os 30 primeiros commits são integração de
task-manager (ClickUp) e specialists de stack (Cursor, NodeJS, Mermaid) + um comando `sync`. Evoluiu para
uma tese epistêmica: um framework que **mantém o próprio conhecimento honesto**. O padrão-mestre de
validação é o **dogfood** — rodar o artefato de verdade, testar o modo-de-falha, não só o happy-path.

## Especialidades desenvolvidas

- **KG-SDAAL — grafo como runtime.** Investigação/auditoria nasce no `.kg.yaml`; o radar lê-primeiro e
  dirige o trabalho ([[mechanism-beats-prose]], [[self-reinforcing-radar-loop]], [[write-kg-closing-step-bookend]]).
  Ganhou um console que se narra, sem poder citar nó que o grafo não tem
  ([[kg-console-rich-narratable-instrument-on-itself]]), e um modo de diagnóstico de engajamento com a pausa
  humana como linha vermelha ([[pr-500-behavior-over-declaration-turned-inward]]).
- **Doc-bridge / co-evolução.** Federação com handshake a2a vivo, carteiro-local, reconciliação
  `outbox×inbound` ([[first-live-a2a-handshake]], [[first-regulated-a2a-handshake]],
  [[federation-redesign-rfc0004-shipped]], [[reconciliation-catches-real-loss-next-day]]). A reconciliação
  tem limite medido em 2026-11-08: lê a branch em checkout, e acusou 25 falsos positivos num adotante que
  processa o inbound em outra branch.
- **Proveniência & frescor com catraca.** Gates que cobram origem e re-verificação sem "big bang"
  ([[inverted-provenance-ratchet]], [[deterministic-freshness-via-in-file-baseline]], [[declared-vs-verified-family]]).
- **Durabilidade de adoção.** Vendor-branch merge, pin que prova ser commit, plugins role-scoped, hoje
  cinco e montados só na publicação ([[adopt-vendor-branch-merge]], [[pin-enters-proving-itself]],
  [[layer1-role-scoped-plugins]], [[oito-plugins-viram-cinco-o-canal-premia-bundle-vertical-e-work-tools-era-saco-de-ferramentas]]).
- **O adotante como oráculo.** O core é o único repo onde as dependências da guarda existem, logo é onde ela
  mente com mais confiança sobre estar verde. Link vivo aqui e morto lá, comando que nasce morto na adoção,
  namespace errado em plugin: cada classe virou guarda que olha do lado do destino ([[core-green-adopter-red]],
  [[adopter-lint-is-oracle-vendored-link-guard]], [[tres-bugs-de-campo-do-primeiro-adotante-greenfield-e-a-guarda-que-casava-o-comentario]],
  [[comando-de-plugin-e-plugin-cmd-o-lint-nao-via-porque-so-olhava-o-core]]).
- **Bancada com mutante.** Guarda só conta quando o mutante morde e a contagem fecha; `success` não prova que
  a suíte rodou, e a linha-âncora do mutante também é candidata a defeito ([[cron-da-bancada-e-a-rede-por-provar]],
  [[a-bancada-achou-o-defeito-destrutivo-que-eu-ia-enviar]], [[meia-cura-tres-vezes-a-mesma-perna-e-o-mutante-ancorado-no-defeito]],
  [[bancada-em-faixas-a-familia-fantasma-e-tres-defeitos-latentes]]).
- **Guardas de harness que interrompem.** Hook que precisa falar com o modelo sai com `exit 2`, então todo
  detector tem de ser determinístico e testado contra falso-positivo ([[posttooluse-exit-2-is-the-only-channel]],
  [[shell-guard-paid-four-times-same-axis]], [[regra-n-sem-titulo-na-prosa-reincidi-duas-vezes-e-a-cura-e-um-hook-stop]]).
- **Pesquisa que mede a própria cobertura.** A lente virou spec carregada e workflow salvo; descoberta de
  passada única cobriu 55-62% (n=2); leitura de primária que não mede a casa não decide
  ([[a-diretriz-de-pesquisa-e-spec-carregada-nao-comando]], [[onda-da-lente-de-pesquisa-fechada-dogfood-derrubou-8]],
  [[discovery-needs-n-passes-judgment-converges]], [[primaries-norm-without-house-measure]]).

## Adaptações do core

- **A catraca (ratchet):** passivo tolerado num baseline versionado que só pode **encolher** — saúde é o
  baseline diminuindo, não o gate passando ([[inverted-provenance-ratchet]]).
- **O Elenxo como método, não como revisor:** refutação por lentes independentes, com o erro exposto e
  re-teste datado. Sem a migalha datada é crítica pontual ([[elenxo-reduzido-ao-revisor]],
  [[minha-auditoria-contou-1-onde-eram-3]], [[revisao-cruzada-em-tres-camadas]]).
- **Modernization Doctrine como freio:** o primeiro spike que concluiu **NÃO construir** (gap sem consumidor),
  economizando a fábrica inteira ([[adopt-kg-life-g1-spike]]). O freio também erra: dois NÃO CONSTRUIR caíram
  ao serem medidos de novo ([[dogfood-que-refutou-a-propria-cura]], [[nota-nao-e-mecanismo-o-waiter-provou]]), e
  a proposta própria passa pelo mesmo teste ([[teste-do-gatilho-contra-a-propria-proposta]]).
- **Reenquadre knowledge-centric** + Onion-é-o-herói, plataforma-é-base ([[knowledge-centric-reframe-and-north-star]],
  [[onion-is-the-hero-platform-is-base]]).
- **Régua = eficiência/eficácia, nunca custo** — o tiering (model+effort por fase) é a métrica ([[efficiency-over-economy]]).

## Padrões de erro superados

- **Pin forjado → doutrina anti-forja.** Um restore manual carimbou um commit que os arquivos não
  correspondiam; virou o mecanismo do pin-que-prova-ser-commit ([[forged-pin-false-announcement]]).
- **Declarado≠verificado, a ansiedade central.** Uma capacidade inteira que passa em todos os testes e
  nunca tocou a realidade ([[capability-never-met-reality]]); doutrina que apodrece quando não re-verificada
  ([[doctrine-fades-declared-not-verified]]); "a pior verdade é a que não se tem certeza" ([[worst-truth-is-uncertain]]).
  A capacidade e a doutrina seguem abertas na última re-medição: 0 contratos reais em 2026-10-20 e 5
  documentos STALE em 2026-11-08.
- **Verificar-antes-de-agir:** não reescrever 640 commits de repo alheio para consertar um problema
  inexistente ([[verify-before-rewriting-foreign-history]]); ler o conteúdo inteiro antes de triar ([[read-full-before-triage]]).
- **Guarda que parece cobertura.** Guarda inalcançável sob `set -e`, revisor verde que nunca leu, hook morto
  atrás de `exit 0`, asserção que casava o comentário: produzem verde sem tocar o fato. Escrever a guarda é
  quando se está mais perto de reincidir ([[unreachable-guard-worse-than-absent]], [[o-revisor-verde-que-nunca-revisou]],
  [[hook-morto-e-silencioso-no-plugin-o-motor-nao-viajou-e-o-exit-0-escondeu]], [[o-mecanismo-confiava-no-proprio-pressuposto]],
  [[o-refutador-reprovou-meu-proprio-pr-e-o-campo-novo-herda-a-superficie-nao-a-cura]]).
- **Ler o derivado em vez do vivo.** Exit de pipe, projeção truncada, lista vazia de um agregador que não
  formava o par, verify de texto que não vai ao `gh` ([[shell-guard-paid-four-times-same-axis]],
  [[frase-de-veredito-vem-do-instrumento]], [[adversarial-verify-blind-to-external-live-state]],
  [[quatro-decisoes-seladas-e-tres-guardas-com-defeito-datado]]).
- **Medir certo e concluir errado.** Um 401 vestido de timeout, 13 peças de "cerimônia" das quais nenhuma
  sobreviveu ao exame, corrida curada no escritor quando era do leitor ([[o-401-que-chegou-vestido-de-timeout]],
  [[inferred-ceremony-vs-measured-ceremony]], [[a-corrida-era-do-leitor-nao-do-escritor-o-grep-desta-casa-e-multithread]]).
- **Nota não é mecanismo.** Lição escrita reincidiu nas horas seguintes, e a cura foi hook ou guarda. Onde não
  há mecanismo, o gatilho segue sendo a pergunta do maestro ([[nota-nao-e-mecanismo-o-waiter-provou]],
  [[self-correction-trigger-was-social]], [[what-the-maestro-taught-me]]).

## O que ofereço à rede

O **método KG-SDAAL** (radar + `.kg.yaml` + investigação-nasce-no-grafo); a **família declarado≠verificado**
com as catracas de proveniência e frescor; o **protocolo de co-evolução** (a2a-live, co-relay, reconciliação
outbox×inbound); o **ingestor de doutrina** (o core absorve correções de campo, trust-gated); e a **doutrina
de dogfooding** — a lei de que toda mudança se valida rodando o artefato de verdade e todo fix vira mecanismo
que se repete sozinho ([[declared-vs-verified-family]], [[doctrine-ingestor-core-absorbs-field]],
[[reconciliation-catches-real-loss-next-day]]). Depois de julho: o **Elenxo** como método
([[elenxo-reduzido-ao-revisor]]), a **bancada com mutante** ([[meia-cura-tres-vezes-a-mesma-perna-e-o-mutante-ancorado-no-defeito]])
e a **guarda anti-fail-open do shell** ([[posttooluse-exit-2-is-the-only-channel]]).
