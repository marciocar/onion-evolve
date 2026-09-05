---
title: 'Jogo da Vida: pedido de adoção (greenfield) + 5 sinais de campo de um repo pré-adoção que já entregou uma feature'
date: 2026-09-05
from: jogo-da-vida (pré-adoção; usa plugins onion-* + kg-radar vendorizado)
to: core (onion-evolve)
type: field-signal
flow: upstream (consumidor→core)
---

## Contexto
Repo novo (`/home/marcio/jogo-da-vida`, privado em `github.com/marciocar/jogo-da-vida`): app de desenvolvimento pessoal
gamificado (MAAGICA), irmão do `portal-gamificacao` (mesmo corpus, produto distinto). Em 2026-09-04/05, SEM adoção,
só com os plugins: business-context, technical-context (9 ADRs), applications do corpus citando nós, worklog completo
(plan→start→work 7 fases→pre-pr com 4 revisores→pr→merge→sync), grafo de domínio, e2e. Funcionou — e mostrou onde a
maquinaria some quando o repo não é adotado.

## Pedido
Adotar: `/meta:adopt /home/marcio/jogo-da-vida --mode greenfield --role adopted --integration-branch develop`.
Já existem e devem ser preservados (never-clobber): `docs/{business,technical}-context`, `docs/knowledge-base/gamification/applications`
(cita grafos do portal por caminho), `docs/onion/graph/jogo-da-vida-domain.kg.yaml`, `docs/evolution/review/`,
`.claude/sessions/archived/`, `.claude/validation/kg-radar.sh` (cópia manual do canônico — pode ser substituída),
`.github/workflows/ci.yml` (check, e2e-web, kg-radar), GitFlow main/develop. Sem `CLAUDE.md` ainda.

## Sinais de campo
1. **`/meta:drive` e `/meta:adopt` não chegam ao consumidor.** Ambos vivem só no core. O consumidor precisa abrir sessão
   no core para se adotar ou para conduzir um plano-grafo. Proposta: portar `adopt --update`/`drive` ao plugin `onion`,
   ou documentar o "salto ao core" como movimento nomeado do wizard.
2. **Dois marketplaces habilitados = comandos duplicados.** `onion-plugins` (GitHub, 8 plugins) e `onion-evolve` (local,
   consolidado 8→5) coexistiam no `settings.json` → `build-tech-docs` aparecia em `onion-docs:` e `onion-product:`.
   Resolvido desabilitando `@onion-plugins`. Proposta: publicar a consolidação no canal público ou fazer o
   `meta:adopt`/onboarding detectar e avisar marketplaces em gerações diferentes.
3. **Hooks pressupõem repo adotado.** Em repo pré-adoção, o `bash-empty-result-guard` avisou "MERGE-SEM-FONTE-LIDA:
   leia `onion-review-verdict`" (check que não existe aqui) e "PR-SEM-PASSADA-ADVERSARIAL / REGRA 56". O texto está
   certo para adotados; para pré-adoção induz a procurar algo inexistente. Proposta: o hook ler `.onion-version` e,
   ausente, dizer "repo não adotado — rode meta:adopt" em vez de citar o check.
4. **kg-radar teve que ser vendorizado à mão** para a conformidade JS↔sh rodar no CI. A porta JS do subset que
   reprova (`packages/kg/src/radar.ts`) + `radar.conformance.test.ts` (6 fixtures) podem interessar ao core como
   padrão "radar no cliente" (o onion-pessoal-app tem `kgRadar.ts` com o mesmo propósito; aqui foi reescrito, não copiado).
5. **Lições reutilizáveis registradas** (candidatas a KB/troubleshooting do core): cache do Metro não inclui `EXPO_PUBLIC_*`
   (`expo export --clear`); testes Node não podem importar `expo-*`; `react-hooks/set-state-in-effect` (React 19.2)
   muda o padrão de hidratação; `vi.mock` exige `vi.hoisted`; arestas `.kg.yaml` em bloco (radar ignora `{}`); nó de grau 0
   reprova até em grafo de 1 nó; save dentro de debounce se perde em reload (flush em `pagehide`/`background`).

## Evidência
- PR #1 (feature) e PR #2 (sync) mergeados em `develop`; review em `docs/evolution/review/feature-onboarding.md`.
- `.claude/sessions/archived/2026-09-05_0125_onboarding/` (worklog arquivado no formato da SSOT).

---

## Triagem do core — 2026-09-05

**Veredito: ADOTADO + 2 curas na fonte + 2 nós de gatilho + 2 ofertas registradas.**

### Adoção: FEITA (branch `onion/adopt`, pin `7d1abf51ddb4`)

Relatório completo em `docs/evolution/inbound/2026-09-05-adopt-7d1abf51ddb4.md` deste repo. Resumo:
665 arquivos, **zero conflitos** no diff de cópia segura, `onion/vendor` semeada, gate nativo **provado
por execução**, `CLAUDE.md` escrito projeto-primeiro, registro na federação com pin verificado.
Tudo que vocês pediram para preservar foi preservado — e o `kg-radar.sh` que copiaram à mão era
**byte-idêntico** ao canônico.

**Lint deste repo: 9 HARD no dia 1 → 6 HARD** (chegou a 0 com a cópia manual, revertida). As causas estão curadas **na fonte**; a de REGRA 52 chega no `--update`.

### As duas curas que a adoção de vocês forçou no core

> ⚠️ **Estado, para não confundir verbo com entrega:** as curas abaixo estão **no core, em PR** — elas
> chegam ao repo de vocês por `/meta:adopt --update` **depois do merge**, não agora. Eu havia copiado
> os scripts à mão e revertido: o repo tem de ficar no pin que o `members.yaml` declara, senão a
> declaração `pin-ok` fica falsa e o 3-way do próximo update vê a mudança do core como customização
> local de vocês (as duas coisas foram medidas por um refutador nesta mesma sessão).

1. **Sinal 4, virado do avesso.** Vocês ofereceram o radar-JS como padrão — e o que ele **provou** foi
   um defeito nosso: as fixtures de conformidade em `packages/kg/src/__fixtures__/` são
   deliberadamente inválidas (é o teste!) e o `grep -v '/fixtures/'` do core não casa a convenção
   Vitest. Resultado: **5 violações HARD da REGRA 52** no dia 1, cujas únicas saídas eram apagar o
   teste ou desligar a guarda — o modo-de-falha que a catraca existe para evitar. Pior: aquele `grep`
   estava **copiado em seis consumidores**, seis listas com um vocabulário só. Curado com um predicado
   ÚNICO (`.claude/validation/kg-fixture-paths.sh`) que cobre a **classe** de convenções
   (`fixtures/`, `__fixtures__/`, `testdata/`, `__snapshots__/`), **recusa** isenção por substring
   (`docs/mixtures/` e `fixtures-do-produto.kg.yaml` continuam julgados) e é **auditável**
   (`--list-exempt`) — isenção em massa não passa calada. Três mutantes provados na bancada.
2. **Sinal 3, aceito e curado NO CORE (chega por `--update`) — com uma correção no meio do caminho.** O guard mandava ler o check
   `onion-review-verdict` num repo que não o tem. Minha primeira cura leu o **papel** (`.onion-version`)
   e estava errada: o **core não tem stamp** (ele computa `role: source`), então o aviso diria "não é
   adotado" justamente onde o check existe. O predicado certo é o **artefato**, não o papel: existe o
   workflow do revisor? A mensagem agora cobre os três casos (core · adotado-sem-workflow · pré-adoção)
   e diz *"não vá procurá-lo"* em vez de mandar caçar fantasma. Guarda com mutante que reproduz
   exatamente o meu erro.

**E uma terceira cura, que ninguém tinha sinalizado porque só o dogfood a expõe:** o passo do
`/meta:adopt` que regenera baselines **lê `role:`** e rodava **antes** do carimbo — sem stamp o
`onion-version.sh` devolve `role: source` e o helper recusava achando que o alvo era o core. Fail-loud
(rc=2), não silencioso, mas se ninguém re-rodasse depois vocês herdariam **114 chaves de baseline do
core** (`kg-verification` 28 + `plugin-bare-path` 86) e o lint nasceria cobrando nós que este repo
nunca teve. O passo foi movido para a Fase 5.

### Os dois sinais que viraram nó com gatilho (grafo `onion-plugin-publication-2026-08`)

- **Sinal 1** → `Q_PLUGIN_SEM_DRIVE_NEM_ADOPT`. Medido: `plugins/onion/commands/` tem 20 comandos e
  **não** tem `drive.md` nem `adopt.md`. Você está certo no diagnóstico, e a razão de não ser simples
  é mais forte que no `kg-inbox`: o `/meta:adopt` **escreve repo alheio** a partir da fonte (I3/MOAT) e
  o `/meta:drive` conduz o plano-grafo do repo que o hospeda — distribuí-los criaria a expectativa de
  rodar o que só a fonte pode rodar. Três desenhos ficaram escritos no nó, **nenhum decidido**: portar
  só `adopt --update`; nomear o "salto ao core" como movimento explícito do wizard; ou manter e
  documentar a fronteira. **GATILHO: o próximo adotante que pedir `--update` sem sessão do core, ou a
  decisão do maestro.**
- **Sinal 2** → `Q_MARKETPLACE_PUBLICO_EM_GERACAO_ANTIGA`. Isto é **dívida nossa**, não defeito de
  plugin: o repo público está na geração pré-consolidação (8 plugins) e o core consolidou 8→5, então o
  `build-tech-docs` aparecia em dois namespaces. Duas metades: publicar a consolidação (rotina do
  próximo ciclo) e — a que **sobrevive** — o onboarding **detectar** marketplaces em gerações
  diferentes e avisar, porque a defasagem vai acontecer de novo por construção (o push é humano).

### Sinais 4 e 5: oferta REGISTRADA, não código copiado

- **Radar-JS**: o `kgRadar.ts` do app pessoal e o seu `packages/kg/src/radar.ts` foram **escritos
  independentemente** para o mesmo propósito — o que é evidência de que "radar no cliente" é padrão
  real, e não de que o core deva vendorizar uma implementação JS. O que o core aproveita agora é o
  **teste de conformidade JS↔sh** como forma; vendorizar o código exige antes decidir de quem é a
  autoridade do subset. Não puxei nada: N=2 implementações independentes é sinal, não mandato.
- **As 7 lições** (Metro/`EXPO_PUBLIC_*`, `vi.hoisted`, testes Node × `expo-*`,
  `react-hooks/set-state-in-effect` no React 19.2, arestas `.kg.yaml` em bloco, nó grau 0 em grafo de
  1 nó, save em debounce perdido no reload) são boas e **específicas de stack Expo/Vitest** — o core
  não tem KB de Expo, e criar uma para hospedar 7 lições de um adotante seria catedral. **Duas delas
  não são de stack e essas sim interessam ao core:** "arestas em bloco `{}` o radar ignora" e "nó de
  grau 0 reprova até em grafo de 1 nó" são sobre o **radar**, que é nosso. Se vocês abrirem um sinal só
  com essas duas, elas entram na KB do KG. As de stack ficam melhor no
  `docs/technical-context/` de vocês, onde quem precisa vai olhar.

### Uma coisa que ficou para vocês decidirem

**CI do Onion.** A oferta agora diz `✓ APLICÁVEL` (forge GitHub, lint verde, sem workflow prévio) e
criaria `.github/workflows/onion-validate.yml` — o gate deixa de ser pulável com `--no-verify`. Custa
minutos de CI da conta de vocês, então a decisão é do dono:
`bash .claude/utils/adopt/offer-onion-ci.sh . --apply`.

E o **teto dos dois grafos**: vocês declararam `# kg-backlog-guard: on` sem o teto, e o fail-loud da
REGRA 58 estava correto. Pus valores iniciais com folga (36→50, 42→60) marcados como **para ajustar** —
o teto é decisão de quem é dono do grafo.
