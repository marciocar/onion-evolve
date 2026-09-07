# Plano — plugins Onion em conformidade TOP PREMIUM e em inglês integral

## Context

O Onion publica 5 plugins em `marciocar/onion-plugins` (materializado hoje, 5 plugins, `22b859f`). O maestro quer
**projeção internacional** e **passar com chave de ouro** no diretório da Anthropic. A pesquisa de 2026-09-07
(3 frentes: nosso retrato medido, a política da Anthropic atual, e o que projetos lusófonos populares fazem)
mostrou que o problema tem duas metades, e a que dói mais **não é idioma**:

1. **Conformidade**: dos 5 requisitos duros do diretório, cumprimos hoje **um e meio**. Três dos cinco plugins
   **reprovam `claude plugin validate --strict`**; o canal de suporte declarado é um **404**; o README afirma
   coisas **falsas** sobre privacidade e sobre o que os hooks fazem; a guarda anti-injeção é **ponteiro morto**.
2. **Idioma**: não existe requisito publicado de inglês — mas o marketplace **oficial tem 291 plugins e ZERO
   descrições não-inglesas**, e o comunitário tem 11 em 2.282 (0,48%). O selo *Anthropic Verified* não é
   solicitável; a escalação é automática e avalia **qualidade e segurança**.

**Decisões do maestro nesta sessão** (2026-09-07), somadas ao selo de 2026-09-04
(`D_PLUGIN_LANGUAGE_POLICY_CANAL_PUBLICO`, opção (i′)):

| # | Decisão |
|---|---|
| 1 | **Converter `onion-plugins` no lugar**, uma identidade pública só, tudo EN (adotantes atuais são de teste) |
| 2 | **Opção 3 — EN integral, corpos inclusive**, faseada por manifesto, com catraca |
| 3 | **L0: exceção nomeada + knob** para o adotante escolher o idioma da própria superfície |
| 4 | **Compliance total, depois submeter** (ao comunitário — o oficial não tem processo) |
| 5 | Executar em **worktree separada, sessão nova** |

---

## 1. O alvo, corrigido

`clau.de/plugin-directory-submission` **não** leva ao diretório oficial. São três alvos distintos:

| alvo | como se entra | o que dá |
|---|---|---|
| `claude-plugins-community` | formulário + review automatizado — **é o submissível** | listagem, pin por SHA, re-scan a cada push |
| `claude-plugins-official` | **sem processo**; curadoria discricionária | auto-registrado em toda instalação + protocolo `plugin-hints` |
| badge *Anthropic Verified* | escalação automática, **não solicitável** | selo de qualidade/segurança |

Requisitos duros (Software Directory Policy, atualizada 2026-04-15): repo público · `claude plugin validate`
limpo · **3.E** ≥3 exemplos funcionais · **3.A** privacy policy (rejeição imediata se ausente/incompleta) ·
**3.B** contato e suporte verificados · **3.C** doc de funcionamento + troubleshooting · **3.D** conta de teste ·
**seção 2** anti-injeção, que vale para `SKILL.md` e agents: *"Describe what the tool does. **Do not tell Claude
how to behave.**"*

---

## 2. O que bloqueia hoje (medido em 2026-09-07)

| # | Bloqueio | Evidência |
|---|---|---|
| B1 | **`marciocar/onion-evolve` é PRIVATE** e os 5 plugins apontam `homepage`/`repository`/suporte para lá | `gh repo view --json visibility`; `assemble-plugin.sh:340-341` |
| B2 | **3/5 reprovam `--strict`** (`onion-design`, `onion-engineering`, `onion-product`) | causa única: `commands/README.md` sem frontmatter, copiado por `assemble-plugin.sh:229` |
| B3 | **Zero exemplos de prompt** (exige ≥3), zero privacidade, zero `SUPPORT`/`SECURITY` | `grep -ci exemplo\|privac` = 0 nos 6 READMEs; nenhum `PRIVACY*`/`SUPPORT*`/`SECURITY*` no repo, plugins ou `site/` |
| B4 | **Guarda anti-injeção é ponteiro morto**: 23 refs a `common:prompts:*`, **zero** arquivos `commands/common/` embarcados — inclusive a R15.2 que protege o `co-evolve`, que ingere conteúdo de outro agente | `grep -rn` em `/home/marcio/onion-plugins/plugins` |
| B5 | **Afirmação de privacidade FALSA**: "Nenhum envia dados para fora", mas 6+ comandos declaram `Bash(cat .env*)`, 4 declaram `WebSearch`, adapters instruem chamar ClickUp/Jira/GitHub/Gamma, e `utils/forge/post-review-comment.sh` chama `gh api` | `plugin-readme.sh:92`, `marketplace-readme.sh:57` |
| B6 | **Afirmação FALSA sobre hooks**: o README diz que "podem VETAR uma ação com `exit 2`" — o `PostToolUse` roda **depois** e só anexa aviso. É a auto-descrição mais perigosa possível para um revisor de tool-calling | `bash-empty-result-guard.sh:24-26,409` |
| B7 | **3 `allowed-tools` pedindo scripts inexistentes no consumidor** (`onion-wizard`, `onion-onboarding`, `co-relay`) — comando nasce morto e a permissão é inflada (2.D) | REGRA 74 classe ALLOWED-TOOLS |
| B8 | **README vende `onion-work-tools`, que não existe mais** — e a linha seguinte anuncia a absorção | `marketplace-readme.sh:43,45` |
| B9 | **`category` fora do vocabulário**: emitimos `core`/`vertical`; o oficial usa development(120)/productivity(52)/… | `generate-marketplace.sh:75` |
| B10 | **≥7 descriptions imperativas** ("Ative mesmo sem o usuário mencionar X") — bate de frente com o critério literal de rejeição | skills dos 5 plugins |
| B11 | **`language-standards` reescreve o idioma de resposta do modelo sem o usuário pedir** — pior caso individual da auditoria, e contradiz projeção internacional | `skills/language-standards/SKILL.md:2-10` |

Contexto sempre-ligado medido (`claude plugin details`): `onion` **~5.017 tok** · product ~3.981 ·
engineering ~3.453 · design ~1.262 · compliance ~669. A UI mostra isso **antes** do install.

Achado que muda o desenho: **`claude plugin eval` é nativo** (lê `<plugin>/evals/**/case.yaml`, suporta
`--ablation with-without`, `--threshold`, `scaffold_script`). É a definição mecânica de *working example*.

---

## 3. O mecanismo (o que a Opção 1 constrói e a Opção 3 consome)

**Assento único de idioma** — arquivo versionado, nunca variável de ambiente (a REGRA 19 regenera sem env e
faria a catraca oscilar com o shell de quem commita):

- `.claude/utils/marketplace/lang.conf` — `surface_lang: en`, `companion_langs: pt-BR`
- `.claude/utils/marketplace/lang.local.conf` — **não rastreado no core**, rastreado no adotante; vence
- `.claude/utils/marketplace/lang.sh` — resolver; resolve o conf por `dirname "${BASH_SOURCE[0]}"`, **antes de
  qualquer `cd`** (cicatriz já paga em `assemble-plugin.sh:257` e `identifier-language-check.sh:47`)

Precedência: `ONION_PLUGIN_SURFACE_LANG` (só experimento) → `lang.local.conf` → `lang.conf` → `en`.
O `.local` sobrevive ao `--update` porque `adopt.md:127` usa `git archive HEAD` e ele não existe no HEAD do core
— mesma doutrina never-clobber de `.env.example` (`adopt.md:135-139`).

**Catálogo de mensagens** — os 60 `append` de prosa fixa (`plugin-readme.sh` 26 + `marketplace-readme.sh` 34)
viram chaves: `messages/en.json` (SSOT) + `messages/pt-BR.json` (`{text, src_sha}`) + `lib/messages.py` com
`t(key, **kw)`. Placeholders **nomeados**. Guarda com 4 predicados HARD: chave faltando/sobrando · placeholder
dessincronizado · **`src_sha` divergente** (EN mudou, tradução não acompanhou) · chave morta/inexistente.

**Catracas novas** (a última em uso é a 78, `lint-artifacts.sh:3944`):

| regra | o que cobra | baseline |
|---|---|---|
| **79** | `description:`/`argument-hint:` em EN, **só entre os dois `---`** | nasce com 176, **só encolhe** |
| **80** | ≥3 `EXAMPLES` por manifesto + `evals/<slug>/case.yaml` correspondente + orçamento de contexto | sem baseline (nasce cumprindo) |

Reuso direto: `classify()` de `docs/evolution/research/plugin-language-policy-2026-09/data/langcensus.py`
(já rodou contra 2.573 entradas reais do venue) promovido a `.claude/validation/lib/lang-classify.py`; e a
semântica de `frontmatter()` de `plugin-readme.sh:23-38` — julgar por outro parser daria veredito diferente do
artefato publicado. Ambas as regras retornam 0 sob `IS_DERIVED` (o adotante escolhe o idioma dele).

---

## 4. Execução — ondas e PRs

### Onda 0 — abrir a frente e torná-la CONDUZÍVEL pelo drive

```bash
cd /home/marcio/onion-evolve
bash .claude/validation/session-beacon.sh check .        # I3 antes de tudo
git fetch origin && git worktree add -b feat/plugins-en-compliance /caminho/da/worktree origin/main
```
⚠️ **Remover a worktree ANTES do merge verificado** — branch em worktree faz `ops/pr-merge-verified.sh` sair
`rc=1` *depois* de já ter mergeado.

**Este plano vira plano-grafo.** O `/meta:drive` não lê markdown: o censo é `kg-drive-project.sh` sobre um
`.kg.yaml`, e **o status do nó É o progresso**. Primeiro ato na worktree:

`docs/onion/graph/plugins-en-compliance-2026-09.kg.yaml` — **um nó `decision` por PR** das Ondas 1–4
(`drive_kind: execution`), com:
- `DEPENDS_ON` impondo a ordem real (PR 4 antes de 5, 5 antes de 6, 7 antes de qualquer fase da Onda 4);
- `label` com o critério de aceite **executável** (o comando do gate que prova aquele PR);
- `trace:` apontando o arquivo que muda;
- nós `question` separados para as 6 decisões humanas do §6 — o censo os reporta como **BLOQUEADOS**, e é assim
  que o drive não os atropela.

Fechar com `kg-radar.sh <grafo> --integrity --schema` exit 0, senão o P0 do drive **para** antes de começar.

**O que o drive faz sozinho, por passada:**
```
/meta:drive docs/onion/graph/plugins-en-compliance-2026-09.kg.yaml --max-nodes 2 --budget <tokens>
```
P1 censo → P2 lote → P3 por nó (classifica · **beacon** · executa em worktree própria **até PR-verde** ·
Elenxo · veredito de escrita) → P4 dogfood → P5 checkpoint em `STATE.md` → P6 para.

**O que ele NÃO faz — e é por desenho, degrau AUDIT:**

| ato | por quê |
|---|---|
| **merge no `main`** | 100% humano, em lote, no checkpoint |
| **push no `onion-plugins`** | MOAT: repo alheio / superfície outward-facing |
| **emendar a L0 sozinho** | mudança de constituição: ele propõe, `@metaspec-gate-keeper` + maestro selam |
| **o dogfood de roteamento da Onda 4** | exige sessão NOVA, prompt pt-BR digitado por humano, observação verbatim — o instrumento automático não existe (`instructions-loaded.jsonl` só registra `CLAUDE.md`) |
| **auto-iniciar / agendar** | W7 = MOAT: o drive é maestro-invocado, nunca `/loop`/cron sobre si |

E a guarda P0.5 é o que impede corrida: **checkpoint pendente bloqueia passada nova**. Então o ciclo real é
*invocar → drive entrega N PRs verdes → você sela e mergeia → invocar de novo*. Cada fase da Onda 4 completa
automaticamente **até o PR verde**; o selo e o merge continuam seus.

### Onda 1 — mecânica sem decisão humana (destrava o gate)

| PR | Conteúdo | Prova |
|---|---|---|
| **1** | `assemble-plugin.sh:229` — pular `README.md` na cópia de `commands/`; regenerar os 5 | `claude plugin validate --strict` **5/5** |
| **2** | Correções de verdade no artefato público: `plugin-readme.sh:92` e `marketplace-readme.sh:57` (o que os hooks fazem, por evento) · `marketplace-readme.sh:43` derivado da lista real (mata o `onion-work-tools` fantasma) · `generate-marketplace.sh:75` vocabulário de `category` + `strict: true` + `$schema` + `renames` | REGRA 19 + REGRA 76 |
| **3** | **REGRA 80 — `claude plugin validate --strict` no gate**: helper `.claude/validation/plugin-cli-validate.sh` (contrato TSV de `plugin-bare-path-check.sh:20`) + 3ª guarda no `materialize-marketplace-repo.sh` **antes da poda** + família na bancada. Sem CLI → `SOFT NO-CLI`, nunca fail-open | família nova reprova fixture inválida |

### Onda 2 — o assento de idioma (CONSTRAIN 1 primeiro)

| PR | Conteúdo | Prova |
|---|---|---|
| **4** | **Emenda da L0** `docs/meta-specs/code-standards.md` (bump de versão, §1.3 nova, quadro `:41-42`) + `skills/language-standards/SKILL.md` reescrita. **Zero linha de gerador** | `@metaspec-gate-keeper` + `/onion:metaspec-validate` |
| **5** | `lang.conf` + `lang.sh` + `lib/messages.py` + `messages/{en,pt-BR}.json`; os 60 `append` viram `t()`. **`surface_lang: pt-BR` neste PR** → saída byte-idêntica | REGRA 19 verde **sem regenerar** = prova de refactor puro |
| **6** | **O flip**: `surface_lang: en`; 5 `PLUGIN_DESC` em EN; `materialize:59` + `generate-marketplace.sh:41` + `--reseed-metadata` (o topo do `marketplace.json` é preservado verbatim — sem isso o flip sai incompleto e ninguém vê); `README.pt-BR.md` companion gerado; regenerar os 5 | REGRA 19 + 76 + `run_marketplace_readmes_selftests` |
| **7** | **REGRA 79** + `plugin-language-check.sh` + `lib/lang-classify.py` + baseline com as 176 + linha em `lint-rules.md` | fixture pt-BR **tem** que falhar |

### Onda 3 — conformidade dura

| PR | Conteúdo |
|---|---|
| **8** | **Fronteira do bundle**: tirar `co-evolve`/`co-relay` (relação core↔adotante + risco 2.F) e `language-standards` (B11); embarcar `utils/wizard` (cura B7). `roles.yaml:44-45` junto, senão a REGRA 37 acusa |
| **9** | **Descriptions imperativas → descritivas** nas ≥7 skills (B10). Cai junto com o orçamento de contexto: descrição estreita é mais curta *e* passa no critério anti-injeção |
| **10** | `legal/` SSOT no core → `PRIVACY.md`/`SUPPORT.md`/`SECURITY.md`/`CODE_OF_CONDUCT.md` na raiz de cada plugin (mesmo ponto do `LICENSE`, `assemble-plugin.sh:364-368`) + raiz do marketplace + `site/src/pages/legal/*` + `site/public/.well-known/security.txt` (prova 3.F). O PRIVACY tem a **tabela gerada** de fluxos para terceiros que o bundle pode originar |
| **11** | `EXAMPLES[]` nos 5 manifestos + seção `## Exemplos` gerada + `evals/<slug>/case.yaml` + `evals/scaffold.sh` + `TESTING.md` (3.D sem backend = repositório-sandbox) |
| **12** | Seções geradas `## Como funciona`, `## Solução de problemas`, `## Limitações conhecidas` (derivada do baseline da REGRA 74) + `CHANGELOG.md` por plugin (do mesmo `_vsrc[]` que já deriva a versão) + `SETUP.md` em `onion`/`onion-product` |

### Onda 4 — Opção 3: os corpos em EN, faseada por manifesto

Ordem por risco de roteamento crescente. Cada fase é **um PR**: frontmatter+corpos da fase · baseline
encolhido · `plugins/` regenerados · **resíduo do dogfood (REGRA 56)**.

| fase | alvo | artefatos | por que aqui |
|---|---|---|---|
| A | 8 skills de `onion.manifest.sh:54-63` | 8 | menor conjunto, **maior** sensibilidade (skill ativa por descrição) |
| B | `onion-design` + `onion-compliance` | 13 | menor superfície, sem skill |
| C | resto do `onion` | 24 | inclui `/onion:onion`, `/onion:kg` |
| D | `onion-engineering` | 41 | |
| E | `onion-product` | 49 | maior massa |
| F | 38 não-embarcados (meta-fábrica) | 38 | **baseline zera e é apagado**; REGRA 79 vira HARD pura |

**Dogfood de roteamento por fase** (o instrumento não existe automático — `instructions-loaded.jsonl` só
registra `CLAUDE.md`): corte duro 100% re-testado nos artefatos cuja `description` negocia ativação
(medido: 4 arquivos com "Ative mesmo sem"); amostra de ~19 probes por fase (1 por namespace + 3 agentes +
as 8 skills). **O usuário continua digitando pt-BR**; duas sessões novas, mesma frase-gatilho, antes e depois.
Registrar verbatim: ativou / não ativou / ativou o errado.

**Reverter**: `git revert` da fase + `assemble-plugin.sh` nos 5 manifestos → REGRA 19 verde. Fases são
independentes.

---

## 5. Verificação (fim a fim)

```bash
# 1. o gate da casa
bash .claude/validation/lint-artifacts.sh                       # 0 HARD
bash .claude/validation/lint-selftest.sh --jobs 4               # 0 falhas
# 2. o gate da Anthropic, nos 5
for p in /home/marcio/onion-plugins/plugins/*/; do claude plugin validate "$p" --strict; done
# 3. os exemplos rodam E foi o plugin que os fez rodar
claude plugin eval ./plugins/onion --ablation with-without --threshold 0.7 --runs 3
# 4. custo de contexto caiu
for n in onion onion-product onion-engineering onion-design onion-compliance; do claude plugin details "$n"; done
# 5. ensaio antes de publicar — materializar num descartável e diferenciar
D=$(mktemp -d); bash .claude/utils/marketplace/materialize-marketplace-repo.sh "$D" --no-commit
diff -r -x .git -x provenance.json "$D" /home/marcio/onion-plugins
# 6. só então: materializar de verdade, tag de rollback, push
```

**Zerar antes de submeter**: classe ALLOWED-TOOLS da REGRA 74 (é a única em que a permissão declarada não
corresponde à funcionalidade — 2.D direto). Os outros baselines seguem com catraca, **declarados** em
`## Limitações conhecidas`.

---

## 6. Riscos declarados e o que continua humano

**Riscos que o plano não elimina:**
1. **Nenhuma guarda prova roteamento** — a REGRA 79 prova idioma, jamais que o gatilho dispara. O dogfood é
   amostra; a cauda dos 176 fica não-medida. Irredutível com as ferramentas desta casa.
2. **O risco real não é o idioma, é perder a cláusula de ativação** na tradução ("Use when…"). Mitigação
   parcial: a REGRA 79 pode exigir presença da cláusula — proxy de forma, não de comportamento.
3. **Camada mista residual** no `README.pt-BR.md`: as tabelas imprimem `description:` em EN. Mitigado por nota
   gerada, **não eliminado** — o gate-keeper precisa ver isso por escrito na emenda.
4. **README do marketplace no repo público não tem catraca** (a REGRA 19 varre `plugins/` do core, não o alvo).
5. **`experimental.evals`** — amarrar o gate de "working examples" a superfície experimental é risco declarado;
   o fallback é a camada declarativa sobreviver sozinha.

**Decisões que continuam sendo do maestro:**
- **Abrir `marciocar/onion-evolve` ou desacoplar** (`homepage`→onionevolve.com, suporte→`onion-plugins/issues`).
  Bloqueia 3.B e a exigência de repo público.
- **E-mail de suporte verificado** — `author.email` fica público para sempre.
- **`category` de `onion-compliance`** — não existe categoria "compliance" no vocabulário oficial.
- **Teto de contexto da REGRA 80** — falta o número.
- **Semver da L0** (2.0.0 vs 1.1.0) — chamada do `@metaspec-gate-keeper`; a linha `:42` é **revogada**, não
  ampliada, e 176 artefatos dependiam dela.
- **A submissão em si** — exige org Team/Enterprise ou role no Console.
