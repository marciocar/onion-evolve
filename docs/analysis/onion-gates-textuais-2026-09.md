---
title: "Gates do Onion: veto mecânico, aviso textual ou confiança no modelo (auditoria 2026-09-02)"
category: analysis
date: 2026-09-02
status: executada-curas-no-mesmo-pr
kg: docs/evolution/research/audit-textual-gates-2026-09/audit-textual-gates-2026-09.kg.yaml
run_id: "teammates gates-mech · gates-ci · gates-prose (read-only, sonnet/medium) + medição no contexto principal (probes + bancada nova)"
tokens: 1900000
agents: 3
duration_min: 95
verified_at: 2026-09-02
---

# Gates do Onion — o que VETA, o que AVISA, o que CONFIA no modelo

> **Projeção do grafo.** SSOT: [`audit-textual-gates-2026-09.kg.yaml`](../evolution/research/audit-textual-gates-2026-09/audit-textual-gates-2026-09.kg.yaml)
> (radar `--integrity --schema` exit 0; 24 nós). Execução da `D_AUDITAR_GATES_TEXTUAIS`
> (grafo `fable-5-1-superacao-2026-09`), selada pelo maestro em 2026-09-02. Toda linha `arquivo:linha`
> abaixo foi **re-lida no contexto principal** antes de entrar aqui — os workers apontaram, a sessão mediu.
> Régua: *gate em prosa não é gate* (System Card 5.1, S1: o modelo fabrica aprovação em <0,01% dos casos).

## A resposta em uma linha

**Antes desta rodada a sessão tinha UM veto incondicional** (`pretooluse-protect-main.sh`, só force-push) —
e ele tinha um buraco (`HEAD:main`). `gh pr merge N`, `git push origin main` e a REST de merge eram
**prosa** ("PARE" no `/meta:drive`). Os 58 HARD do lint e o `onion-review-verdict` são **AVISO no host**
(repo privado sem Pro → branch protection 403). Seis REGRAs são **catraca de atestação** = confiança no
modelo por construção. **No mesmo PR:** 2º veto (`pretooluse-merge-gate.sh`), lib de normalização única
para os dois hooks (fecha a classe dos invólucros) e bancada de 32 casos que achou 3 buracos que 3 workers
lendo o código não acharam.

## 1. Classificação (o inventário, por corpus)

### 1.1 Hooks da sessão (`.claude/hooks/`, `settings.json`)

| Gate | Linha | Classe | Por quê |
|---|---|---|---|
| `pretooluse-protect-main.sh` (force-push main) | hook inteiro | **VETO-MECANICO** | exit 2 antes da ação; **tinha buraco `HEAD:main`** (E_BURACO_HEAD_MAIN) — curado |
| `pretooluse-merge-gate.sh` (**NOVO**) | hook inteiro | **VETO-MECANICO** | `gh pr merge`, `gh api …/pulls/N/merge`, `git push` com alvo main → exit 2; aponta `ops/pr-merge-verified.sh` |
| `bash-empty-result-guard.sh` (PostToolUse) | l.24-27, 36-37 | AVISO-TEXTUAL | julga **depois** do fato; sem `jq` cala em silêncio deliberado |
| `aside-router.sh` GATE= | l.26 | AVISO-TEXTUAL | string injetada no prompt (UserPromptSubmit) — por desenho |
| `session-beacon.sh` | l.50 | AVISO-TEXTUAL | "INFORMADO, NÃO VERIFICADO" no próprio código |
| `inbox-pull.sh` sha256 | l.45 | VETO-MECANICO | descarta download corrompido — protege dado, não ação do modelo |
| demais 5 hooks (motd/side-effect) | — | AVISO-TEXTUAL | nunca `exit 2` por desenho |

### 1.2 Git local (`.githooks/pre-commit`) — condicional a `core.hooksPath`

| Gate | Linha | Classe |
|---|---|---|
| commit em main/develop | l.30-36 | VETO-MECANICO **condicional** |
| HARD do lint | l.122-127 | VETO-MECANICO condicional |
| schema do kg-freshness | l.110-119 | VETO-MECANICO condicional |
| auto-fix fora do stage (plugin) | l.84-87 | VETO-MECANICO condicional |
| regressão da bancada quando `validation/` muda | l.142-149 | VETO-MECANICO condicional |

Condição: `git config core.hooksPath` **local** (aqui armado, medido; clone fresco nasce sem) e `--no-verify`
(escape documentado no hook). Discrepância entre workers (gates-ci disse "nenhum pre-commit instalado"; leu
`.git/hooks/`) resolvida por **medição**, não por voto.

### 1.3 CI / validação (`.claude/validation/`, `.github/workflows/`)

| Gate | Linha | Classe | Por quê |
|---|---|---|---|
| 52 REGRAs HARD de drift mecânico (contagens, links, ids, hashes) | `lint-artifacts.sh` | AVISO-TEXTUAL (host) → **veto de fato** no caminho da sessão | verdade verificável, mas o host não protege main; `merge-gate → pr-merge-verified` as lê |
| REGRA 29 proveniência · 42 frescor · 49 verificação PROD | `lint-artifacts.sh` (49 ≈ l.2561: "não checa se é VERDADE, só que existe") | **CONFIANCA-NO-MODELO** | catraca de campo que o modelo escreve |
| REGRA 56 resíduo: `findings_*`, `verdict`, `tokens` | `review-artifact-check.sh:205-211` | **CONFIANCA-NO-MODELO** | só numérico/presente; **só `reviewed_diff_sha256` (l.190-198) é cruzado** |
| REGRA 57 kg-seal CONFIRMED/DRIFTED | `kg-seal-check.sh:118-222` | **CONFIANCA-NO-MODELO** | 0 referências a autor/quem-selou (grep medido) |
| REGRA 58 DONE-NU | `kg-backlog-check.sh:60-75` | CONFIANCA-NO-MODELO | presença/formato; TETO editável no mesmo commit |
| `onion-review-verdict` | `onion-review.yml:493` | AVISO-TEXTUAL (host) → veto de fato via `pr-merge-verified` | o próprio workflow declara "vermelho INFORMA; merge segue possível" |
| `ops/pr-merge-verified.sh` | l.1-119 | VETO-MECANICO **quando invocado** | era voluntário; agora é o único caminho que o merge-gate deixa passar |

### 1.4 Scripts operacionais (`ops/*.sh`, `.claude/utils/**`)

Todos com `die()`/exit interno = VETO por **dentro**; **CONFIANCA-NO-MODELO na invocação** — nada força o
wrapper: `rsync`/`systemctl`/`sudo cp` crus passam (deploy-site, update-bridge, bridge-backup, gpg-protect-key).
`onion-untrusted-wrap.sh` (R15) não é chamado por hook nenhum; `a2a-verify/ssrf` só têm chamador no repo do
bridge (fora do corpus); `a2a-accept.sh:34-35` só recusa se invocado.

### 1.5 Prosa (`commands/`, `agents/`, `skills/`) — 29 gates, 1 com mecanismo

107 hits → 19 descartados (menção / "comPARE") → **29 gates distintos**: 21 INTERNA · 9 OUTWARD · 5
IRREVERSÍVEL (3 mistos). **Só** `onion-publish/SKILL.md:22,50,51,71` tem mecanismo por trás (REGRA 61
`check_moat_boundary`). Os 8 IRREVERSÍVEL/OUTWARD sem mecanismo, por consequência:

1. `/meta:drive` MOAT (`drive.md:20,23,86` + réplicas :21,67,90): merge no main · deploy · repo alheio · relógio — **merge curado neste PR**; os outros 3 seguem prosa
2. `common/prompts/untrusted-content-provenance.md:30,33` (R15)
3. `agents/meta/onion.md:767`
4. `gamma-api-specialist.md:115` (chave)
5. `federation-rollback.md`
6. `orchestrate.md:181`
7. `co-announce.md:177` (repo alheio)
8. `onion-publish/SKILL.md:58-59` (push do marketplace, W6)

## 2. Contagem antes → depois

| Classe | Antes | Depois deste PR |
|---|---|---|
| VETO-MECANICO incondicional na sessão | **1** (force-push, com buraco) | **2** (force-push + merge/push main; 32 casos de bancada) |
| VETO-MECANICO condicional (pre-commit) | 5 | 5 (condição inalterada — Q_PRECOMMIT) |
| AVISO-TEXTUAL | ~63 (52 HARD + 11 checagens) | ~63 no host; **viram veto de fato no caminho da sessão** (merge-gate exige pr-merge-verified, que exige CI+revisor) |
| CONFIANCA-NO-MODELO | 6 catracas + invocação de ops/utils + 29 prosa | 6 catracas + invocação + **28** prosa |

A razão VETO:CONFIANCA continua ~1:10. A rodada moveu o item de **maior consequência** (merge), não a massa —
e é isso que a régua pede: cura barata onde a consequência é irreversível.

## 3. Curas executadas (mecanismo + bancada, no mesmo loop)

| Cura | Artefato | Prova |
|---|---|---|
| 2º veto: merge/push em main só pelo caminho verificado | `.claude/hooks/pretooluse-merge-gate.sh` + `settings.json` | veto **ao vivo** nesta sessão (`gh pr merge 0` → GUARDA-PRETOOLUSE, sem reiniciar); se desarma sem `ops/pr-merge-verified.sh` |
| refspec `HEAD:main`/`x:main` no protect-main | `pretooluse-protect-main.sh` | caso de bancada verde |
| lib única de linhas de invocação (heredoc fora; split por `&& \|\| ; \| $( \` <( >(`; desembrulha `sh -c`; tira `\ command exec env nohup time sudo -u builtin VAR=`; colapsa `git -C/-c`) | `.claude/hooks/lib/invocation-lines.sh` | probes: 8 invólucros rc=0 → rc=2 |
| família `run_pretooluse_veto_selftests` | `lint-selftest.sh` | **32/32** no runner com `set -euo pipefail`; pre-commit :142-149 a roda quando `validation/` muda |

**Buracos achados só pela bancada** (não pela leitura de 3 workers): `HEAD:main` · `sudo -u x git push` ·
`out=$(gh pr merge 1)`. Dois deles apareceram na **2ª rodada**, depois da 1ª cura. Classificar um gate como
VETO-MECANICO sem bancada de bypass é declará-lo, não medi-lo.

## 4. O que fica CONFIANCA sem cura barata — e o gatilho de cada um

| Nó | Por que não há cura barata | Gatilho |
|---|---|---|
| `C_ATESTACAO_NAO_TEM_CURA_DETERMINISTICA` (R56 campos, R57 quem-selou, catracas) | mesma autoria git; assinatura por campo é catedral; `findings_real>0` pune revisão limpa. A fonte externa que existe é o **revisor** — e o merge-gate o pôs no caminho crítico | — (fechado por desenho; residual declarado) |
| `D_MOAT_DEPLOY_E_RELOGIO_VIRAM_MECANISMO` | assinatura por ALVO (path servido/remote alheio/timer), não por vocabulário | 1º dogfood em que a sessão executa deploy/cron/push-alheio fora do wrapper, OU próxima onda de guardas |
| `Q_PRECOMMIT_ARMADO_EM_CLONE_FRESCO` | `core.hooksPath` é config do humano; SessionStart pode AVISAR, não vetar | próximo clone fresco do core / commit em main sem o hook disparar |
| `Q_R15_WRAP_NO_CAMINHO_CRITICO` | custo (latência/falso-positivo) não medido | 1ª injeção observada em sessão de drive OU R15 sair de PROTÓTIPO |
| `Q_REGRA56_VERACIDADE_DOS_ACHADOS` | sem número: precisa do experimento `Q_EXP_AUTO_REVISAO_5_1` | próximo PR com resíduo ≥ 4 achados |

## 5. Fronteiras declaradas do mecanismo novo

- O PreToolUse só vê a **string do modelo**: 2º nível de `-c`, `eval`, script em arquivo, função/alias,
  subprocess de outra linguagem são invisíveis — teto de **plataforma**, não da lib.
- `ops/pr-merge-verified.sh` chama `gh pr merge` por dentro e passa — é o desejado.
- Escape deliberado = o maestro fora da sessão. Sem flag de bypass, por desenho.
- Heredoc/`echo`/prosa que **cita** `gh pr merge` não veta (classe guarda-por-vocabulário, medida em 09-01).

## 6. Lacunas

1. Bancada completa (`lint-selftest.sh` inteira) estourou 10 min na VPS carregada — a família dos vetos foi
   provada em runner isolado com as mesmas opções de shell; o CI a roda inteira.
2. Contagens de AVISO (~63) e prosa (29) vêm dos relatórios dos workers com **amostra** re-medida, não censo
   linha a linha pela sessão.
3. `PreModelSwitch` (D_HOOK_PREMODELSWITCH_GUARDA) segue gated — não medido aqui.
4. Adotantes: `/meta:adopt` copia `.claude/hooks/` (incl. a lib e o merge-gate) mas não `ops/` → o merge-gate
   se desarma no adotante por desenho. Não medido num clone de adotante nesta rodada.

## valeu-a-pena

~1,9M tokens (3 workers read-only ≈ 0,9M + contexto principal ≈ 1,0M) por: 1 veto novo + 1 buraco fechado no
veto existente + 1 classe de bypass fechada (8 invólucros) + 32 casos de bancada + 24 nós. Comparação: a
onda de 09-01 gastou ~5,4M para re-medir 99 nós sem mudar mecanismo nenhum. Aqui o custo por **veto real
entregue** é ~1M — e vetos são a única categoria que o System Card não consegue falsificar.
