# onion-meta — a META-FÁBRICA do Sistema Onion como plugin: criar comandos, agentes, skills, abstrações
# e KBs, auditar o próprio framework (evolve, dissect) e absorver skills alheias.
#
# POR QUE EXISTE (F4 das portas, SAC-93, 2026-10-10): a matriz das portas (D_MATRIZ_DE_PORTAS_2026_10,
# decisão do maestro de 2026-10-09) diz "plugins = a mesma superfície do standalone", e o standalone LEVA a
# meta-fábrica. A F2 liberou a REGRA 61 (Fronteira de MOAT: manifesto de plugin publicável não vaza adoção,
# federação nem grafo privado) para os create-*/evolve/absorb-skill; o empacotamento ficou para cá.
#
# PLUGIN PRÓPRIO, não dentro do `onion`: a fábrica é de quem ESCREVE o framework, não de todo usuário — no
# marketplace ela fica opt-in, e o núcleo não cresce 13 comandos para quem só usa o ciclo.
#
# ⚠️ O QUE NÃO VIAJA, e por quê (a recomendação mais estreita, declarada):
#   · `/meta:create-vertical` FICA FORA. O caminho `--plugin` dele monta plugin e catálogo com
#     `.claude/utils/marketplace/{assemble-plugin,generate-marketplace}.sh` — o MOTOR do marketplace, que a
#     REGRA 61 segue tratando como moat (a matriz o lista com a adoção). Levá-lo exigiria abrir o moat
#     (decisão do maestro, não desta fase) ou publicar um comando cujo `allowed-tools` aponta um motor que
#     não viaja (a REGRA 74 o chama de NASCIDO MORTO). Fica no core e no standalone; o fio está em
#     "para o final" da F4.
#   · `/meta:forge`, `/meta:forge-guard` e `/meta:cc-update` FICAM FORA. Os motores deles
#     (forge-census.sh, guard-census.sh, cc-delta-census.sh) medem o HARNESS do repo — lint-artifacts.sh e
#     lint-selftest.sh —, e o assembler recusa o bundle porque o grafo de dependências não fecha (medido:
#     "o plugin nasceria morto no adotante"). Quem instala plugin não tem o harness para eles medirem; quem
#     adota o standalone tem, e lá eles viajam.
#   · os WORKFLOWS (.claude/workflows/*.js do /meta:evolve e do /meta:dissect) e as LENTES (.claude/rules/)
#     não têm categoria de manifesto: o comando roda sem eles, no modo sequencial que ele mesmo declara.
PLUGIN_NAME="onion-meta"
PLUGIN_VERSION="0.1.0"
PLUGIN_DESC="Meta-fábrica do Sistema Onion: cria comandos, agentes, skills, abstrações SDAAL e knowledge bases pelos templates do framework, audita o próprio framework (evolve, dissect) e absorve skills de terceiros com proveniência."
KEYWORDS=(onion meta-factory scaffolding agents commands skills self-audit)

COMMANDS=(
  ".claude/commands/meta/absorb-skill.md"
  ".claude/commands/meta/create-abstraction.md"
  ".claude/commands/meta/create-agent.md"
  ".claude/commands/meta/create-agent-express.md"
  ".claude/commands/meta/create-command.md"
  ".claude/commands/meta/create-knowledge-base.md"
  ".claude/commands/meta/create-skill.md"
  ".claude/commands/meta/dissect.md"
  ".claude/commands/meta/evolve.md"
)
AGENTS=(
  ".claude/agents/meta/agent-creator-specialist.md"
  ".claude/agents/meta/agent-skills-specialist.md"
  ".claude/agents/meta/command-creator-specialist.md"
)
SKILLS=()
HOOKS=()
UTILS=()
VALIDATION=(
  ".claude/validation/dissect-census.sh"
  ".claude/validation/evolve-census.sh"
  ".claude/validation/evolve-staleness-check.sh"
)
TEMPLATES=(
  ".claude/commands/common/templates/abstraction-template.md"
  ".claude/commands/common/templates/agent-template.md"
  ".claude/commands/common/templates/command-template.md"
)
DOCS=()
REQUIRES_PLUGINS=(onion)
# A fábrica ESCREVE no `.claude/` do projeto de quem instala (agente novo em .claude/agents/<cat>/,
# comando em .claude/commands/, skill em .claude/skills/, abstração em .claude/utils/<nome>/; o
# evolve-staleness-check lê .claude/hooks/). Ali o caminho nu é DESTINO, não ponteiro morto — a REGRA 74
# (Caminho .claude/ NU dentro de plugin só resolve no core) lê esta lista e reporta as refs isentas num
# SOFT agregado. Medido no 1º bundle: 145 refs, todas desta natureza.
CONSUMER_TARGET_ROOTS=(agents commands skills hooks utils)

CONFORMANCE="bronze"
PROVIDES=(
  "meta-factory"
  "self-audit"
  "skill-absorption"
)
REQUIRES=(
  "skill:onion-patterns"
)
LOADS=()
