# Doutrina de Dogfooding do Onion

> **Versão**: 1.0.0 | **Última atualização**: 2026-06-22 | **Categoria**: Conceitos
> O **padrão master** para evoluir o Sistema Onion: toda mudança de core se valida **rodando o
> artefato de verdade** — aprender com o que o uso revela e resolver no **mesmo loop** (fix →
> re-dogfood), com validação adversarial. Irmã da [Doutrina de Modernização](onion-modernization-doctrine.md):
> modernização decide *o que* refatorar; dogfooding decide *como você sabe que ficou certo*.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2026-06-22 |
| **Última Atualização** | 2026-07-17 |
| **Categoria** | Conceitos |
| **Comando relacionado** | `/meta:evolve` (sensor) · gate mecânico em `.claude/validation/` |
| **Padrão-irmão** | [Doutrina de Modernização](onion-modernization-doctrine.md) |
| **Padrão-parente** | [Knowledge Graph SDAAL](knowledge-graph-sdaal.md) — o KG é o SSOT que o loop lê antes e escreve depois (§♻️ e §Onde se encaixa) · [`/meta:diary`](../../../.claude/commands/meta/diary.md) — o re-teste de migalha é o "re-" em outra roupa |

---

## 🎯 Propósito

Evoluir o core do Onion **não termina** quando o plano fecha, o lint passa ou a spec está
coerente. Termina quando o artefato **roda de verdade** e o uso confirma — ou expõe a lacuna.

A premissa: **plano, spec e happy-path dão falsa confiança.** O caminho feliz esconde
exatamente os modos de falha que importam (input ausente, recurso já existe, retomada, colisão,
realidade do runtime ≠ realidade idealizada). Só **executar** revela o que falta.

Por isso o **padrão master** de evolução do Onion é o **dogfooding**: usar o próprio Onion (e
cada artefato alterado) como o primeiro caso de teste real, e **fechar o loop** — o fix vira
nova entrada do dogfood, não o fim.

---

## 🚦 O que a doutrina exige (e nunca dispensa)

1. **Rodar de verdade, não só validar no papel.** Lint verde / plano aprovado **não** é
   "pronto". Um comando se prova sendo **invocado**; um script, sendo **executado** num caso real.
2. **Testar o modo de falha, não o happy-path.** Exercitar input ausente, recurso já existente,
   retomada, colisão — não só o caminho que se sabe que funciona.
3. **Fechar o loop: fix → re-dogfood.** Todo fix é re-exercitado (o fix pode introduzir
   regressão). O loop só fecha quando o re-dogfood passa.
   > **Dois sentidos de "re-dogfood" — ambos legítimos, não confundir:** (a) **re-dogfood do fix**
   > (este item) — re-exercitar o artefato depois de consertar, dentro do mesmo loop; (b) **rodada de
   > dogfood de um padrão** — o campo exercita o mesmo padrão de novo, semanas depois, e o que ele
   > revela **supersede** o que a rodada anterior concluiu (*"2º dogfood de campo"*, *"re-dogfood
   > geral do KG SDAAL"*). (a) fecha um loop; (b) **abre** um — é a instância de campo do "re-" (§♻️).
4. **Validação adversarial é insumo, não ordem.** Veredito de revisor/subagente é hipótese a
   **verificar com evidência** — rejeitável com prova (ver [@metaspec-gate-keeper](../../../.claude/agents/meta/metaspec-gate-keeper.md), Regra Zero: "evidência ou abstenção").
5. **Findings do uso são trabalho de agora**, não follow-up vago. Aprender e resolver no mesmo loop.

---

## 🧭 Gate mecânico vs gate de uso

O dogfood do Onion tem duas camadas que se complementam:

| Camada | O que é | Quando roda |
|---|---|---|
| **Gate mecânico (determinístico)** | `.claude/validation/`: [`lint-artifacts.sh`](../../../.claude/validation/lint-artifacts.sh) (regras de conformidade), [`lint-selftest.sh`](../../../.claude/validation/lint-selftest.sh) (auto-teste das guardas via fixtures), [`inventory.sh`](../../../.claude/validation/inventory.sh) (SSOT de contagens). São **dogfood automatizado**: o framework se valida sem LLM, no pre-commit e no CI. | Sempre (hook + CI) |
| **Gate de uso (vivo)** | **Invocar o artefato** que você mudou — o comando, a skill, o adapter — e observar o resultado real (incl. realidade do runtime: ferramentas/MCP que de fato existem). | Toda mudança de core, antes de declarar pronto |

Regra prática: se mudou um **artefato runnable** (comando/skill/script/adapter), o gate mecânico
**não basta** — rode o artefato. Se mudou uma **guarda** (lint/fixtures), o selftest é parte do
dogfood. Se a mudança altera **contagens** (comandos/agentes/skills/KBs), `/meta:inventory`
(que roda `lint-artifacts.sh --fix`) é o dogfood que propaga a SSOT.

---

## 📐 Worked examples (evidência — não asserção)

Casos reais onde o dogfood pegou o que o happy-path escondia:

| Mudança | O que o dogfood fez | O que pegou |
|---|---|---|
| **Self-heal de inventário** (PR #126) | Dogfood do fluxo: adicionar **e remover** um recurso real e rodar `/meta:inventory` | Bug real: o `CLAUDE.md` vive **fora** dos scan-roots do lint (`.claude/`+`docs/`); o `--fix` global não o alcançava. O happy-path (CLAUDE.md já correto) escondia — só a mudança real de contagem expôs. |
| **`/meta:all-tools`** (PR #128) | Rodar o comando reescrito e produzir o catálogo real da sessão | Lacunas: faltava marcar **status de conexão MCP** (conectado vs exige-auth) e tratar **tools deferidas por nome** (sem inventar descrição — o pecado do dialeto-Cursor em outra roupagem). |
| **Limpeza `.claude/docs/`** (PR #127) | Verificação **adversarial** do veredito do explorer | O veredito "deletar os c4" teria **quebrado** os agentes c4 (que os referenciam); a verificação reverteu para "mover" (e o move **reparou** refs já penduradas). |
| **`.env.example`** (fix #89) | Dogfooding do Onion **no adotante** (um adotante, ao vivo) | Bug de campo que virou fix never-clobber no core, via [upstream do inbox](../../evolution/README.md). |

A lição comum: **o erro só apareceu ao executar.** Nenhum foi pego por revisão-no-papel.

---

## ♻️ Onde o dogfooding se encaixa no loop de auto-evolução

O dogfooding é o **fechamento empírico** do loop que a [Doutrina de Modernização](onion-modernization-doctrine.md) abre:

```
KG-first (se houver .kg.yaml)→ read(KG): o grafo é o SSOT de estado, ACIMA do git/memória
        ↓ drive-to-verify: claim PROD de alto impacto → cruzar contra o vivo antes de agir
/meta:evolve (sensor)        → audita, propõe backlog (read-only)
        ↓ cada item cita uma regra de DECISÃO (modernization-doctrine)
/meta:create-* (atuadores)   → geram/enxugam o artefato
        ↓
@metaspec-gate-keeper        → governa conformidade (evidência ou abstenção)
        ↓
DOGFOOD (esta doutrina)      → roda de verdade → aprende → resolve no mesmo loop
   ├─ gate mecânico: lint + selftest + inventory (determinístico)
   └─ gate de uso: invoca o artefato; testa modo-de-falha; verificação adversarial
        ↓ write(KG): o que o dogfood descobriu volta como nó/aresta (REFUTES/SUPERSEDES)
        ↺ fix → re-dogfood até passar; findings de campo (upstream) realimentam /meta:evolve
```

**O KG fecha o loop nas duas pontas** ([knowledge-graph-sdaal §SSOT-as-runtime](knowledge-graph-sdaal.md#ssot-as-runtime--o-kg-é-o-primeiro-ato-mecanismo-não-conselho)):
`read(KG)` **antes** de auditar (senão o sensor re-deriva o que a SSOT já sabia — falha medida em campo,
≥4× com o próprio autor da doutrina) e `write(KG)` **depois** de dogfoodar (senão o achado morre na prosa).
Sem as duas pernas, o ciclo é leitura, não runtime. O par é **KG-first + drive-to-verify** — nenhum
sozinho basta: o KG stale engana; o git sozinho esquece o que a SSOT já sabia.

**Modernização decide o padrão; dogfooding prova que funcionou.** Um sem o outro é metade do loop:
modernizar sem dogfoodar entrega forma-bonita-não-validada; dogfoodar sem doutrina de
modernização é tentativa-e-erro sem critério.

---

## ♻️ O "re-" — toda verdade tem TTL (o invariante que une três mecanismos)

**Re-dogfood, re-teste de migalha e re-verificação de frescor são o mesmo invariante em três roupas:**

> **Toda verdade tem prazo. Declarado ≠ verificado. Re-testar, nunca re-carimbar.**

Nenhum dos três é opcional, e nenhum é novo — o que faltava era dizer que são **um só**:

| Instância | Onde vive (SSOT) | TTL | Sinal de vencimento | Reconciliação |
|---|---|---|---|---|
| **re-dogfood** do fix | esta doutrina (§🚦 item 3) | — | o fix existe | re-exercitar até passar |
| **re-teste** de migalha | [`/meta:diary review`](../../../.claude/commands/meta/diary.md) | `review_after` (90d) | ⏰ no boot (hook) | `superseded: true` (nunca apagar) |
| **re-verificação** do KG | [knowledge-graph-sdaal §Frescor](knowledge-graph-sdaal.md#frescor-e-versão-de-schema--o-radar-recusaavisa-quando-a-ssot-driftou) | `verified_at` × `meta.baseline` | ⚠ STALE (radar `--freshness`) | `REFUTES`/`SUPERSEDES` (append-mostly) |

O parentesco é **declarado, não analogia**: o gate de frescor do KG é filho do `review_after` do diário
([ADR kg-freshness-gate](../../analysis/onion-adr-kg-freshness-gate-2026-07.md) — *"paralelo direto do
`review_after` do diário; o padrão de TTL já é testado no core"*). E a ponta oposta também se encontra:
o re-teste `dynamic` do diário — *"RODE o artefato de novo; **exit code é evidência, leitura é
hipótese**"* — **é esta doutrina**, em outra roupa.

### Duas assimetrias que este enunciado expõe (trabalho, não retórica)

1. **Só o diário sabe *como* re-testar.** Ele carrega a **estrutura de invalidação** (`conflict_class`:
   `dynamic` → rode o artefato · `static` → confronte a melhor fonte atual · `conditional` → cheque só o
   `valid_when`). O KG só sabe dizer *"STALE, re-verifique"*, sem dirigir o **como**; o re-dogfood não tem
   nem TTL nem sinal. **O diário está à frente.** Levar `conflict_class` ao KG é candidato **gated** — o
   gatilho é um dogfood que prove a falta, não a simetria bonita (`gated-until-trigger`).
2. **Escrever migalha é fácil; ler é o gargalo.** O recall passivo é quase perfeito e **despenca para
   40-60% no uso ativo em decisão** ([work-models-research](../../analysis/onion-work-models-research-2026-07.md)).
   É por isso que o "re-" precisa de **sinal automático** (⏰/STALE) e não de disciplina: sem forcing
   function, o default é prosa — provado em campo e no próprio core.

---

## 📚 Fontes e referências

- Irmã: [Doutrina de Modernização do Onion](onion-modernization-doctrine.md)
- Gate mecânico: [`lint-artifacts.sh`](../../../.claude/validation/lint-artifacts.sh) · [`lint-selftest.sh`](../../../.claude/validation/lint-selftest.sh) · [`inventory.sh`](../../../.claude/validation/inventory.sh)
- Governança: [@metaspec-gate-keeper](../../../.claude/agents/meta/metaspec-gate-keeper.md) (Regra Zero — evidência ou abstenção)
- Co-evolução (upstream = dogfooding de campo): [docs/evolution/README.md](../../evolution/README.md)
- Reforço aplicado: `CONTRIBUTING.md` (fluxo de PR) · `.claude/skills/onion-validation/SKILL.md` (regra de gerador) · `CLAUDE.md` (recall por sessão no core)
- Evidência (PRs): self-heal de inventário (#126), limpeza `.claude/docs/` (#127), `/meta:all-tools` (#128)
