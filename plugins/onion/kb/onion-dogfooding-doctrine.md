# Doutrina de Dogfooding do Onion

> **Versão**: 1.0.0 | **Última atualização**: 2026-06-22 | **Categoria**: Conceitos
> O **padrão master** para evoluir o Sistema Onion: toda mudança de core se valida **rodando o
> artefato de verdade** — aprender com o que o uso revela e resolver no **mesmo loop** (fix →
> re-dogfood), com validação adversarial. Irmã da Doutrina de Modernização:
> modernização decide *o que* refatorar; dogfooding decide *como você sabe que ficou certo*.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.1.0 |
| **Data de Criação** | 2026-06-22 |
| **Última Atualização** | 2026-07-17 |
| **Categoria** | Conceitos |
| **Comando relacionado** | `/meta:evolve` (sensor) · gate mecânico em `${CLAUDE_PLUGIN_ROOT}/validation/` |
| **Padrão-irmão** | Doutrina de Modernização |
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
| **Gate mecânico (determinístico)** | `${CLAUDE_PLUGIN_ROOT}/validation/`: [`lint-artifacts.sh`](${CLAUDE_PLUGIN_ROOT}/validation/lint-artifacts.sh) (regras de conformidade), [`lint-selftest.sh`](${CLAUDE_PLUGIN_ROOT}/validation/lint-selftest.sh) (auto-teste das guardas via fixtures), [`inventory.sh`](${CLAUDE_PLUGIN_ROOT}/validation/inventory.sh) (SSOT de contagens). São **dogfood automatizado**: o framework se valida sem LLM, no pre-commit e no CI. | Sempre (hook + CI) |
| **Gate de uso (vivo)** | **Invocar o artefato** que você mudou — o comando, a skill, o adapter — e observar o resultado real (incl. realidade do runtime: ferramentas/MCP que de fato existem). | Toda mudança de core, antes de declarar pronto |

Regra prática: se mudou um **artefato runnable** (comando/skill/script/adapter), o gate mecânico
**não basta** — rode o artefato. Se mudou uma **guarda** (lint/fixtures), o selftest é parte do
dogfood. Se a mudança altera **contagens** (comandos/agentes/skills/KBs), `/meta:inventory`
(que roda `lint-artifacts.sh --fix`) é o dogfood que propaga a SSOT.

---

## 🛰️ Dogfood de fronteira — o adotante como oráculo

Há uma terceira camada, e ela corrige um ponto cego das duas primeiras: **o core é o pior lugar
para testar o que viaja.** Uma guarda pode estar **verde no core e HARD em todo adotante** — porque
o core é o único repositório onde as dependências da própria guarda existem (`members.yaml`,
`docs/INDEX.md`, um baseline versionado). Rodar o gate no core, nesse caso, é rodá-lo no único
ambiente onde ele não pode falhar: uma falsa prova de saúde.

**Regra dura:** guarda ou artefato que **viaja** (mora em `${CLAUDE_PLUGIN_ROOT}/validation/` e entra no manifesto
de vendor) prova-se **rodando UMA VEZ dentro de um clone de adotante**, não só no core.

- **Onde:** o clone de um adotante real (`~/<adotante>`), onde os arquivos que só o core tem **não
  existem**.
- **Quando:** o gatilho natural é `/meta:adopt --update` — toda vez que o framework viaja é a janela
  para rodar o gate no destino. É barato (o clone já existe) e é exatamente quando os bugs de
  "funciona no core, quebra fora" se revelam.
- **Checklist mínimo ao escrever a guarda:** ela depende de algum arquivo que **só o core tem**? Se
  sim, precisa de um caminho de degradação gracioso para o adotante — **e esse caminho precisa de
  fixture própria** (senão a degradação é conselho, não mecanismo).

Isto é o corolário empírico da regra de admissão: o ponto cego "cláusula
local não alcança o próximo mecanismo" recorre **entre arquivos, dentro de um único dia** — não é
teoria. Crumbs: `core-green-adopter-red`, `guard-matches-threat-model`, `verify-before-rewriting-foreign-history`.

---

## 📐 Worked examples (evidência — não asserção)

Casos reais onde o dogfood pegou o que o happy-path escondia:

| Mudança | O que o dogfood fez | O que pegou |
|---|---|---|
| **Self-heal de inventário** (PR #126) | Dogfood do fluxo: adicionar **e remover** um recurso real e rodar `/meta:inventory` | Bug real: o `CLAUDE.md` vive **fora** dos scan-roots do lint (`.claude/`+`docs/`); o `--fix` global não o alcançava. O happy-path (CLAUDE.md já correto) escondia — só a mudança real de contagem expôs. |
| **`/meta:all-tools`** (PR #128) | Rodar o comando reescrito e produzir o catálogo real da sessão | Lacunas: faltava marcar **status de conexão MCP** (conectado vs exige-auth) e tratar **tools deferidas por nome** (sem inventar descrição — o pecado do dialeto-Cursor em outra roupagem). |
| **Limpeza `.claude/docs/`** (PR #127) | Verificação **adversarial** do veredito do explorer | O veredito "deletar os c4" teria **quebrado** os agentes c4 (que os referenciam); a verificação reverteu para "mover" (e o move **reparou** refs já penduradas). |
| **`.env.example`** (fix #89) | Dogfooding do Onion **no adotante** (um adotante, ao vivo) | Bug de campo que virou fix never-clobber no core, via upstream do inbox (`docs/evolution/README.md`, interno do core). |
| **Update de campo** (2026-07-21, um adotante de campo) | **Dogfood de fronteira**: rodar `/meta:adopt --update` num adotante real e rodar o lint DENTRO do clone dele | **Dois** bugs verdes no core: a Segurança de Projeção (REGRA 30) exigia `members.yaml`, que só o core tem → HARD em todo adotante; um índice de KB vendorizado linkava alvos fora do manifesto → link pendurado no adotante. O lint do core **nunca veria** — lá os alvos existem. |
| **Validação de pin** (2026-07-21, vendor-branch) | Auditar os 3 adotantes reais com `--audit-vendor` | 2 de 3 tinham **pin inválido carimbado** (`vnextpin`; uma data). O drift silencioso que o grafo só refutava em abstrato ganhou mecanismo. E: 5 fixtures usavam **pins fictícios** — praticavam o hábito que deixou o lixo real passar. |

A lição comum: **o erro só apareceu ao executar** — e, para o que viaja, só ao executar **fora do
core**. Nenhum foi pego por revisão-no-papel.

---

## ♻️ Onde o dogfooding se encaixa no loop de auto-evolução

O dogfooding é o **fechamento empírico** do loop que a Doutrina de Modernização abre:

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
(`onion-adr-kg-freshness-gate-2026-07.md`, ADR interno do core — *"paralelo direto do
`review_after` do diário; o padrão de TTL já é testado no core"*; institui o campo `verified_at:` + gate
STALE no `kg-radar.sh`, tornando frescor cidadão de 1ª classe no KG SDAAL). E a ponta oposta também se encontra:
o re-teste `dynamic` do diário — *"RODE o artefato de novo; **exit code é evidência, leitura é
hipótese**"* — **é esta doutrina**, em outra roupa.

### Duas assimetrias que este enunciado expõe (trabalho, não retórica)

1. **Só o diário sabe *como* re-testar.** Ele carrega a **estrutura de invalidação** (`conflict_class`:
   `dynamic` → rode o artefato · `static` → confronte a melhor fonte atual · `conditional` → cheque só o
   `valid_when`). O KG só sabe dizer *"STALE, re-verifique"*, sem dirigir o **como**; o re-dogfood não tem
   nem TTL nem sinal. **O diário está à frente.** Levar `conflict_class` ao KG é candidato **gated** — o
   gatilho é um dogfood que prove a falta, não a simetria bonita (`gated-until-trigger`).
2. **Escrever migalha é fácil; ler é o gargalo.** O recall passivo é quase perfeito e **despenca para
   40-60% no uso ativo em decisão** (`onion-work-models-research-2026-07.md`, pesquisa interna do core — deep-research com verificação adversarial 3-votos que confirmou, entre 24 achados, que a **absorção** da migalha na decisão seguinte é o gargalo, não a escrita).
   É por isso que o "re-" precisa de **sinal automático** (⏰/STALE) e não de disciplina: sem forcing
   function, o default é prosa — provado em campo e no próprio core.

---

## 📚 Fontes e referências

- Irmã: Doutrina de Modernização do Onion
- Gate mecânico: [`lint-artifacts.sh`](${CLAUDE_PLUGIN_ROOT}/validation/lint-artifacts.sh) · [`lint-selftest.sh`](${CLAUDE_PLUGIN_ROOT}/validation/lint-selftest.sh) · [`inventory.sh`](${CLAUDE_PLUGIN_ROOT}/validation/inventory.sh)
- Governança: [@metaspec-gate-keeper](../../../.claude/agents/meta/metaspec-gate-keeper.md) (Regra Zero — evidência ou abstenção)
- Co-evolução (upstream = dogfooding de campo): `docs/evolution/README.md` (interno do core) — *dimensão:* fonte canônica do protocolo doc-bridge core↔adotante, sinal bidirecional por markdown commitado (`inbox/` upstream, `inbound/` downstream); maestro humano orquestra e transporta, execução do que chega é gate humano
- Reforço aplicado: `CONTRIBUTING.md` (fluxo de PR) · `${CLAUDE_PLUGIN_ROOT}/skills/onion-validation/SKILL.md` (regra de gerador) · `CLAUDE.md` (recall por sessão no core)
- Evidência (PRs): self-heal de inventário (#126), limpeza `.claude/docs/` (#127), `/meta:all-tools` (#128)
