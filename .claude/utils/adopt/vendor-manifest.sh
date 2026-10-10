#!/usr/bin/env bash
# vendor-manifest.sh — SSOT do que VIAJA do core para um adotante, por PAPEL.
#
# Uso : vendor-manifest.sh [--role <papel>] [--repo <root>] [--emit-scrub-roots] [--check-bundle <dir>]
#         --role              adopted (default) | source | hub | standalone | plugins | mini
#         --repo              raiz do core (default: git rev-parse --show-toplevel)
#         --list <papel>      imprime o que o papel LEVA: contagem por tipo + a lista de arquivos
#         --diff <papel>      o mesmo, mais o diff contra a publicação anterior (o clone da porta que o
#                             members.yaml registra com aquele papel, via local_path), se existir
#         --emit-scrub-roots  imprime as raízes que a REGRA 36 tem de varrer (= o que viaja)
#         --check-bundle DIR  varre um bundle JÁ EXTRAÍDO e reprova se houver biografia dentro
#         --stub-baselines DIR  reescreve, no bundle, os baselines que citam caminho privado do core
# Saída: um pathspec por linha, filtrado pelo que EXISTE em HEAD (git archive aborta com pathspec vazio).
#
# ══ POR QUE ESTE ARQUIVO EXISTE ═══════════════════════════════════════════════════════════════
# A mesma lista de pathspecs vivia TRÊS vezes: `adopt.md` (o que copia), `vendor-branch.sh` (o que
# vai para onion/vendor) e `lint-artifacts.sh` (as raízes que a REGRA 36 varre). Medido 2026-09-13:
# a terceira já estava DESSINCRONIZADA — `.claude/rules` e `.claude/workflows` viajavam e NÃO eram
# varridos por nome comercial de cliente. Guarda que varre menos do que o transporte emite é
# fail-open com aparência de cobertura. Uma cópia só, e o drift acaba por construção.
#
# ══ ALLOWLIST, NUNCA DENYLIST ═════════════════════════════════════════════════════════════════
# Denylist falha ABERTA: diretório novo de biografia entra no bundle por default. Allowlist falha
# FECHADA: o que não está aqui não viaja. Duas barreiras em série, e a segunda é `git archive HEAD`
# (untracked e ignored nunca viajam, nem por engano).
#
# ══ O PAPEL É O CORTE — e até 2026-09-15 ele NÃO CORTAVA NADA ═════════════════════════════════
# Medido no onion-standalone (pin cd0f847bc39f): 274 arquivos a menos que o core, ZERO a mais — a
# meta-fábrica inteira fora (utils/{adopt,marketplace,wizard,vertical,federation-transport,...},
# validation/federation-*). Aquele corte foi COMPOSIÇÃO MANUAL em 2026-07-19; aqui ele vira
# mecanismo. `roles.yaml` resolve VERTICAIS e WORK_TOOLS (plugins/comandos) — outra granularidade;
# este arquivo resolve PATHSPECS de transporte. Os dois são SSOTs de coisas diferentes.
#
# ⚠️ O QUE ESTE BLOCO PROMETIA E O CÓDIGO NÃO FAZIA (medido 2026-09-15): `--role adopted|hub|standalone`
# devolvia listas IDÊNTICAS. O papel era inicializado, parseado, VALIDADO — e nunca mais lido. E era
# PIOR que o gap anterior: antes não havia papel, e quem publicasse um standalone sabia que precisava
# cortar à mão; com a flag aceitando `standalone` e entregando a meta-fábrica inteira, o gap aberto
# virou gap INVISÍVEL. Guarda decorativa é pior que guarda ausente — ela desliga a desconfiança.
#
# ══ COMO O CORTE É EXPRESSO, e as duas medições que fixaram o desenho ══════════════════════════
# (1) `:(exclude)` SEMPRE VENCE o positivo, em qualquer ordem — `git archive HEAD -- <arquivo>
#     ':(exclude)<dir-pai>'` devolve ZERO arquivos. Logo NÃO se poupa um arquivo dentro de um
#     diretório cortado: o corte tem de ser emitido ARQUIVO A ARQUIVO onde há exceção.
# (2) E ele devolve `rc=0` com o tar VAZIO. Conjunto de corte errado produz bundle vazio EM SILÊNCIO
#     — a classe `exit-code-nao-e-a-verificacao` no transporte. Por isso o modo manifesto CONTA o
#     que sobrou e falha alto em zero (guarda `_assert_nao_vazio`, no fim do modo).
#
# ══ O CORTE É DERIVADO DE HEAD; SÓ O CONTRATO É DECLARADO ═════════════════════════════════════
# A lista de arquivos a cortar NÃO é escrita à mão — ela sai de `git ls-tree` sobre os SUBCAMINHOS
# de papel. Helper de adoção criado amanhã dentro de `.claude/utils/adopt/` já nasce cortado do
# standalone, sem ninguém lembrar de acrescentá-lo. A única lista manual é o CONTRATO
# (`_ROLE_CONTRACT`) — os arquivos que vivem DENTRO de um subcaminho cortado mas que as guardas
# do ALVO leem em runtime. É a distinção que a 1ª tentativa de corte não tinha e que a derrubou:
#
#     a FÁBRICA não viaja; a PLANTA que as guardas do alvo leem, sim.
#
# Medido: cortar `.claude/utils/adopt` inteiro leva junto ESTE arquivo — e `lint-artifacts.sh`
# (REGRA 36) falha FECHADA sem ele (`HARD: a SSOT do manifesto não respondeu`), `vendor-scrub-form-
# check.sh` sai 2 e `kb-vendored-link-check.sh` cai no fallback defasado. O standalone nasceria
# VERMELHO — trocando um gap invisível por outro.
set -uo pipefail

ROLE="adopted"; REPO=""; MODE="manifest"; BUNDLE=""; LIST_DIFF=0
while [ $# -gt 0 ]; do
  # flag que exige valor e veio por último: `shift 2` com um argumento só não anda e o laço não termina
  # (medido pela passada adversarial da F2: `--list` no fim saía por timeout).
  case "$1" in --role|--repo|--check-bundle|--stub-baselines|--list|--diff)
    [ $# -ge 2 ] || { echo "ERRO: $1 exige um valor" >&2; exit 2; } ;;
  esac
  case "$1" in
    --role) ROLE="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --emit-scrub-roots) MODE="scrub"; shift ;;
    --check-bundle) MODE="check"; BUNDLE="${2:-}"; shift 2 ;;
    --stub-baselines) MODE="stub"; BUNDLE="${2:-}"; shift 2 ;;
    --list) MODE="list"; ROLE="${2:-}"; shift 2 ;;
    --diff) MODE="list"; LIST_DIFF=1; ROLE="${2:-}"; shift 2 ;;
    *) echo "ERRO: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done
# Os papéis de PORTA (source, plugins, mini) entraram em 2026-10-10, F2 das portas (SAC-91), pela matriz
# D_MATRIZ_DE_PORTAS_2026_10. `adopted` segue sendo o default de quem ADOTA um projeto.
case "${ROLE}" in adopted|source|hub|standalone|plugins|mini) : ;; *) echo "ERRO: --role desconhecido: '${ROLE}' (adopted|source|hub|standalone|plugins|mini)" >&2; exit 2 ;; esac
[ -n "${REPO}" ] || REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# ── A LISTA, por papel ────────────────────────────────────────────────────────────────────────
# BASE: o que TODO papel recebe. Framework + doutrina; nada de biografia.
_base=(.claude/agents .claude/commands .claude/skills .claude/utils .claude/validation .claude/hooks
       .claude/rules .claude/workflows docs/meta-specs docs/knowledge-base docs/sdaal)
# ⚠️ A LICENÇA NÃO ESTÁ AQUI, E AGORA ISSO É DESENHO — não mais um defeito aberto (curado 2026-09-15).
#
# Ela chega ao alvo pelo `emit-licenses.sh`, com NOME PRÓPRIO: `LICENSE-ONION` e `LICENSE-ONION-DOCS`.
# Duas razões, as duas medidas:
#   · `LICENSE` na raiz rege o REPOSITÓRIO INTEIRO por convenção — entregar o MIT do core sob esse
#     nome declararia a titularidade do autor do core sobre o código que o adotante ainda vai
#     escrever. Imagem espelhada da catástrofe de 2026-09-14 (lá o cliente PERDIA o dele).
#   · pôr a licença NESTA lista foi tentado e revertido no mesmo dia: ela cairia no `$TMP` e o
#     `cp -R` do passo (d) sobrescreveria o LICENSE do alvo.
# Com nome próprio não há colisão, logo não há never-clobber — e o emissor é chamado da Configuração
# pós-cópia, o único bloco que a Fase 3 E o `--update` invocam (a 1ª cura vivia na cópia segura e
# não alcançava adotante NENHUM que já existisse).
#   .env.example                  → específico do alvo (never-clobber, Fase 3 do adopt)
#   docs/evolution/               → inbox/inbound são infra LOCAL do alvo; copiar clobaria o que está em uso
#   .claude/diary, sessions,      → BIOGRAFIA: 127 arquivos de diário, beacons, farol, worktrees
#     beacons, identity,             e a memória local desta casa
#     scratchpad, worktrees
#   docs/{analysis,materials,     → análises de adotante (incl. achados de segurança), material de
#     applying,discussions,onion}    cliente sob NDA, discussões pessoais, grafos da vida do maestro

# ── O CORTE POR PAPEL ─────────────────────────────────────────────────────────────────────────
# SUBCAMINHOS da meta-fábrica que cada papel NÃO recebe. Pathspecs de `git ls-tree` (o `:(glob)`
# cobre o prefixo `federation-`, que é família de arquivos e não diretório).
#
#   standalone → MATRIZ DAS PORTAS (2026-10-09, D_MATRIZ_DE_PORTAS_2026_10; F2 = SAC-91): o core MENOS
#                adoção e federação. Saem utils/adopt (menos o contrato), utils/co-evolution,
#   plugins      utils/federation-transport, validation/federation-*, a skill onion-publish com o motor
#                de publicação do marketplace e o hook do inbox; os comandos saem pelo roles.yaml
#                (conjuntos `federation`, `adoption` e `pending`). A META-FÁBRICA VOLTA: utils/wizard,
#                utils/vertical, utils/marketplace (o create-vertical a usa) e os comandos create-*,
#                forge, forge-guard, dissect, evolve, cc-update, absorb-skill.
#                ⚠️ ATÉ 2026-10-10 o standalone cortava a meta-fábrica ("recebe o método, não a fábrica
#                que o publica", 108 de 685 arquivos, medido 2026-09-15). A matriz inverteu o critério:
#                o que distingue uma porta individual não é a fábrica, é a ADOÇÃO de outros repos e a
#                FEDERAÇÃO com eles. `plugins` é a mesma superfície, empacotada.
#   source     → NADA sai (= hub). É a porta onion-core e o próprio core: toda a maquinaria; a biografia
#                fica fora pela ALLOWLIST (`_base`) e pelo `--stub-baselines`, não por corte de papel.
#   mini       → não corta: INCLUI. Allowlist didática do roles.yaml (`roles.mini.allowlist`), no lugar
#                de `_base` — ver `_mini_positives`, logo abaixo.
#   hub       → NADA sai, e isto é INVARIANTE, não default. Ordem do maestro (2026-09-15): *"vamos
#                mandar tudo incluindo meta fábrica, temos que ter um que tenha tudo do core para
#                trabalhar como o core"*. O hub é esse papel: ele re-distribui para os projetos da
#                empresa, então precisa da fábrica INTEIRA — adopt, marketplace, wizard, vertical,
#                federation-transport e os 43 comandos de meta/. Medido: 685 arquivos, ZERO excludes,
#                byte a byte a superfície do core. A bancada trava isso no caso (b3), porque um corte
#                acrescentado aqui por simetria transformaria, em silêncio, o papel de fidelidade
#                total num core mutilado.
#   adopted   → NADA sai, e isto é DESENHO DECLARADO, não omissão: no eixo de PATHSPEC os dois são
#                idênticos ao core, porque o hub re-distribui para os projetos da empresa e precisa
#                da fábrica. O que separa hub de adopted é `roles.yaml` (VERTICAIS e WORK_TOOLS) —
#                outra granularidade, outro SSOT. Declarar isso aqui é o que impede a próxima
#                leitura de concluir "ainda é decorativo": para dois dos três papéis, não cortar É
#                a resposta medida.
# ⚠️ O CONDUTOR VIAJA COM O MOTOR, OU NENHUM DOS DOIS VIAJA — e esta lista nao tinha os condutores.
# Medido em 2026-09-18, materializando o `onion-standalone` para decidir se valia re-materializa-lo:
# a lista cortava os MOTORES da meta-fabrica (`utils/marketplace/`, `utils/wizard/`, e o
# `commands/meta/adopt.md` pelo corte do `roles.yaml`) e deixava viajar as SKILLS QUE OS CONDUZEM.
# Resultado: `onion-publish/SKILL.md:71` apontava para `utils/marketplace/materialize-marketplace-repo.sh`
# e `onion-wizard/SKILL.md:50` para `commands/meta/adopt.md` — os dois caminhos EXPLICITAMENTE
# cortados por esta mesma funcao. O comando nasce MORTO no consumidor: a skill esta la, o motor nao.
# E `onion-publish` e declarada core-only na propria doutrina do repo (CLAUDE.md), o que torna a
# omissao ainda mais clara — nao era duvida de desenho, era item que ninguem lembrou de acrescentar.
# ⚠️ SO `onion-publish` SAI — E A 1a REDACAO CORTAVA TRES. A passada adversarial derrubou o corte de
# `onion-wizard` e `onion-onboarding`, e o argumento e melhor que o meu: elas sao o CONDUTOR e o
# ENSINO do papel, e cortá-las para calar um lint e trocar capacidade por verde. Provas que ela
# trouxe: (1) QUATRO arquivos que viajam continuam citando as duas em PROSA — entre eles
# `onion-guided-lifecycle.md`, que descreve a vertical de conducao inteira em termos delas —, entao
# a porta ganharia uma KB ensinando um caminho de entrada que ela nao tem; (2) o lint NAO pega isso
# (nao sao caminhos em backtick), logo "0 HARD" ali NAO era evidencia de ausencia; (3) ao contrario
# de `onion-publish`, `onion-onboarding` NAO e declarada core-only em doutrina nenhuma.
# O ponteiro morto de `onion-wizard/SKILL.md:50` volta, e a cura dele e ROLE-AWARE no texto da skill
# (dizer que a transicao `adopt` so existe onde a meta-fabrica existe), nao deletar a skill.
# A LICAO DE FORMA: lista de exclusao escrita A MAO envelhece pelo que se ACRESCENTA depois dela.
# Os motores foram cortados quando existiam; as skills nasceram depois e ninguem voltou aqui. Uma
# derivacao (cortar a skill cujo `trace`/allowed-tools aponta para caminho cortado) seria imune a
# isso — fica NOMEADO como o proximo passo, nao feito aqui, porque exige extrair o grafo de
# dependencia skill→motor que hoje so existe em prosa dentro de cada SKILL.md.
_role_cut() {  # $1=papel → subcaminhos a cortar, um por linha (vazio = nada a cortar)
  case "$1" in
    standalone|plugins)
      # PREFIXOS de caminho (não pathspecs): `git ls-tree` recusa magia, e prefixo dispensa
      # distinguir diretório de família de arquivos — `validation/federation-` é a segunda.
      # ADOÇÃO: utils/adopt (o contrato sobrevive), a skill onion-publish e o MOTOR dela
      #   (materialize-marketplace-repo.sh — o resto de utils/marketplace é do create-vertical, que fica).
      # FEDERAÇÃO: utils/co-evolution (carteiros co-relay/co-deliver e o receptor de correio),
      #   utils/federation-transport, validation/federation-* e o hook que avisa o inbox.
      # ⚠️ utils/wizard e utils/vertical SAÍRAM DESTA LISTA em 2026-10-10: são meta-fábrica e condução,
      #   e a matriz as devolve. O wizard ficou sensível ao papel (topology-projection.sh).
      printf '%s\n' \
        .claude/utils/adopt/ \
        .claude/utils/marketplace/materialize-marketplace-repo.sh \
        .claude/skills/onion-publish/ \
        .claude/utils/co-evolution/ \
        .claude/utils/federation-transport/ \
        .claude/validation/federation- \
        .claude/hooks/co-evolution-inbox-check.sh
      ;;
    *) : ;;
  esac
}

# ── O CORTE DE COMANDOS SAI DO `roles.yaml`, A SSOT QUE JÁ EXISTIA ────────────────────────────
# ⚠️ DUAS VERSÕES ANTERIORES DESTE BLOCO ESTAVAM ERRADAS, e a passada adversarial (2026-09-15)
# derrubou as duas:
#
#   (1) cortar `.claude/commands/meta/` INTEIRO por prefixo. Medido contra o precedente que o
#       cabeçalho afirma mecanizar — o repo PÚBLICO onion-standalone, cortado à mão em 2026-07-19 —
#       isso está INVERTIDO: o corte manual MANTEVE os 14 comandos de `meta/` e removeu a
#       meta-fábrica arquivo a arquivo. O corte por prefixo levava junto o norte NS1 (`/meta:kg`,
#       citado por 31 sobreviventes) e o fallback que o próprio CLAUDE.md manda sugerir
#       (`/meta:setup-integration`). Magnitude: manual −274 arquivos; o meu, −107, do lado errado.
#
#   (2) declarar `travels:` no frontmatter de cada comando. Estruturalmente melhor que a lista, e
#       ainda assim errado: seria uma SEGUNDA SSOT do mesmo fato. `roles.yaml` JÁ declara o escopo
#       por papel, e `resolve-role-bundle.sh <papel> --tools` JÁ devolve exatamente os 14 comandos do
#       precedente. Criar o campo era repetir, uma camada acima, a duplicação que o PR #826 curou
#       ("a mesma lista vivia TRÊS vezes, e uma já tinha driftado").
#
# O que vale: **o transporte CONSOME a SSOT do escopo por papel**, não a reimplementa. A REGRA 37
# (Mapa role→bundle (roles.yaml) consistente com os verticais) já guarda esse arquivo contra drift,
# então o corte herda uma guarda que existe em vez de pedir uma nova.
_emit_command_excludes() {  # $1=REPO $2=papel → :(exclude) dos comandos de meta/ fora do escopo do papel
  local _repo="$1" _role="$2" _f _base_name _tools _resolver
  [ -n "$(_role_cut "${_role}")" ] || return 0   # papel que não corta nada também não corta comando
  _resolver="${_repo}/.claude/utils/marketplace/resolve-role-bundle.sh"
  # ⚠️ FAIL-CLOSED desde 2026-10-10 (passada adversarial da F2): as três linhas abaixo faziam `return 0`
  # quando a SSOT não respondia — resolvedor ausente, PyYAML ausente, conjunto inexistente no roles.yaml
  # (rc 2). Medido: sem PyYAML o `--list standalone` saía rc 0, stderr vazio, com os 12 comandos de
  # adoção e federação DE VOLTA, e o aviso ainda dizia "corta N arquivos". Papel que corta e não sabe
  # o que cortar não emite manifesto: rc 3, como o mini.
  [ -f "${_resolver}" ] || { echo "ERRO: o papel '${_role}' corta comandos pelo roles.yaml, e o resolvedor não existe em '${_repo}'" >&2; return 3; }
  _tools="$(bash "${_resolver}" "${_role}" --tools 2>/dev/null)" || { echo "ERRO: o resolvedor não devolveu os work_tools do papel '${_role}' (PyYAML ausente? conjunto inexistente?) — sem eles o corte de comandos falharia aberto" >&2; return 3; }
  [ -n "${_tools}" ] || { echo "ERRO: o papel '${_role}' corta, mas o roles.yaml não lhe dá nenhum work_tool — o corte tiraria TODOS os comandos de meta/ ou nenhum" >&2; return 3; }
  while IFS= read -r -d '' _f; do
    [ -n "${_f}" ] || continue
    _base_name="$(basename "${_f}" .md)"
    grep -qxF "${_base_name}" <<< "${_tools}" || printf ':(exclude)%s\n' "${_f}"
  done < <(git -C "${_repo}" -c core.quotePath=false ls-tree -r -z --name-only HEAD -- .claude/commands/meta)
}

# ── OS COMPANHEIROS DO COMANDO CORTADO SAEM COM ELE — derivados por REFERÊNCIA, não por nome ────
# ⚠️ O DEFEITO, MEDIDO E DATADO (2026-10-09): materializando o `onion-standalone` de `origin/main`
# (98cc49e2), o corte acima tirou `/meta:evolve`, `/meta:forge-guard`, `/meta:dissect`,
# `/meta:cc-update` e `/meta:forge` — e deixou viajar 14 arquivos que SÓ eles usam: a doutrina
# (`common/prompts/<x>-doctrine.md`), a lente (`rules/<x>-lens.md`), o censo (`validation/<x>-census.sh`)
# e o workflow (`workflows/evolve.js`). Dois nasciam com PONTEIRO MORTO na porta pública:
# `evolve-lens.md` cita `commands/meta/evolve.md` e `guard-lens.md` cita `commands/meta/forge-guard.md`.
# É a LIÇÃO DE FORMA do bloco acima repetida ao pé da letra: as peças do comando-com-framework
# nasceram DEPOIS do corte (forja de 2026-09-29 em diante), em diretórios que o corte não olha.
#
# POR QUE REFERÊNCIA, E NÃO CONVENÇÃO DE NOME: a convenção `<cmd>-doctrine/-lens/-census` já tem dois
# desvios medidos — `forge-guard` → `guard-*` e `cc-update` → `cc-delta-census.sh` — e o próximo
# comando inventa o terceiro. O grafo de citação é o que o `forge-census.sh` já usa para descobrir
# as peças ("descoberta por citação — o artefato nomeia as suas"), e é imune a nome.
#
# O ALGORITMO, e cada passo tem razão nomeada:
#   ZONA      = só as quatro formas de PEÇA da forja: `common/prompts/*-doctrine.md`, `rules/*.md`,
#               `validation/*-census.sh`, `workflows/*.js`. Fora dela nada é derivado: um script de
#               lint citado só por um comando cortado pode ser chamado por glob, e cortá-lo por
#               inferência é trocar ponteiro morto por guarda morta.
#   ÂNCORA    = todo arquivo que VIAJA e não é peça da zona — comando mantido, skill, agente, hook, KB.
#               A BANCADA não é âncora (`lint-selftest.sh` e `fixtures/`): ela TESTA a maquinaria, não
#               a consome; se contasse, todo censo ficaria vivo porque a bancada o exercita.
#               Nem esta planta, que cita nomes como dado (`_is_anchor`, logo abaixo, tem a medição).
#   VIVA      = peça citada por uma âncora, ou por outra peça viva (fecho transitivo — a doutrina
#               cita a lente que cita o censo, e o ciclo doutrina↔lente não se salva sozinho).
#   CORTADA   = peça NÃO viva que é citada por um arquivo cortado (comando, prefixo de papel) ou por
#               outra peça cortada. Peça órfã de todos os lados não é assunto deste corte — fica.
#   LENTE FORÇADA = lente (`rules/*.md`) que cita comando cortado sai MESMO viva: a lente carrega por
#               `paths:` e manda ler um comando que a porta não tem. Se alguma âncora a cita, o
#               ponteiro morto passa para ela — e isso é DITO em stderr, nunca calado.
# Citação = o NOME DO ARQUIVO com extensão, delimitado (`evolve.js` não casa `onion-evolve.js`). Nome
# sem extensão é prosa ("cláusula 1 da guard-doctrine") e não conta — medido: três guardas mantidas
# citam `guard-doctrine` assim, e contá-las manteria viva a doutrina de um comando ausente.
# Quem pode ANCORAR (manter viva) uma peça. Fora: a bancada (testa, não consome) e ESTE arquivo.
# ⚠️ ESTE ARQUIVO SAIU POR MEDIÇÃO, não por cautela (2026-10-09): o comentário acima, ao documentar o
# defeito, nomeia `cc-delta-census`, `forge-census` e o workflow do evolve COM extensão — e a planta
# viaja como contrato. No primeiro commit da cura, o manifesto cortava 14 peças com a árvore antiga e
# 11 com a nova: a própria explicação mantinha vivas 3 das peças que explicava. A planta cita nomes
# como DADO sobre o transporte; quem a lê não executa nada do que ela nomeia.
_is_anchor() {  # $1=path → 0 se a citação dele mantém viva uma peça
  case "$1" in
    .claude/validation/lint-selftest.sh|.claude/validation/fixtures/*|.claude/utils/adopt/vendor-manifest.sh) return 1 ;;
  esac
  return 0
}
_emit_companion_excludes() {  # $1=REPO $2=papel, stdin = caminhos já cortados → :(exclude) das peças órfãs
  local _repo="$1" _role="$2" _f _z _r _b _re _changed
  [ -n "$(_role_cut "${_role}")" ] || { cat >/dev/null; return 0; }
  local -A _cut=() _zone=() _alive=() _gone=() _forced=()
  while IFS= read -r _f; do [ -n "${_f}" ] && _cut["${_f}"]=1; done
  [ "${#_cut[@]}" -gt 0 ] || return 0
  while IFS= read -r -d '' _f; do
    [ -n "${_f}" ] || continue
    [ -n "${_cut[${_f}]:-}" ] && continue
    case "${_f}" in
      .claude/commands/common/prompts/*-doctrine.md|.claude/rules/*.md|.claude/validation/*-census.sh|.claude/workflows/*.js)
        _zone["${_f}"]=1 ;;
    esac
  done < <(git -C "${_repo}" -c core.quotePath=false ls-tree -r -z --name-only HEAD -- "${_base[@]}")
  [ "${#_zone[@]}" -gt 0 ] || return 0

  # Quem cita cada peça (em HEAD, a mesma árvore do transporte). UM `git grep -o` para a zona inteira:
  # a 1a redação fazia um por peça (e um por lente×comando) e levava o manifesto de 1,8s a 8,5s,
  # medido — custo pago em todo `adopt`, todo `vendor-branch` e toda faixa da bancada que o chama.
  # O casamento é por TOKEN inteiro: o grep devolve o token maximal em volta do nome, e só o token
  # IGUAL ao nome conta (`onion-evolve.js` e `evolve.json` não são `evolve.js`). A forma por
  # delimitador consumia o separador e perdia a 2a citação colada ("a.sh b.sh").
  local -A _refs=() _byname=()
  local _alt="" _line _path _tok
  for _z in "${!_zone[@]}"; do
    _b="$(basename "${_z}")"
    _byname["${_b}"]="${_byname[${_b}]:-}${_z}"$'\n'
  done
  for _b in "${!_byname[@]}"; do _alt="${_alt:+${_alt}|}${_b//./\\.}"; done
  while IFS= read -r _line; do
    _line="${_line#HEAD:}"; _path="${_line%:*}"; _tok="${_line##*:}"
    [ -n "${_byname[${_tok}]:-}" ] || continue
    while IFS= read -r _z; do
      [ -n "${_z}" ] && [ "${_z}" != "${_path}" ] || continue
      case $'\n'"${_refs[${_z}]:-}" in *$'\n'"${_path}"$'\n'*) continue ;; esac
      _refs["${_z}"]="${_refs[${_z}]:-}${_path}"$'\n'
    done <<< "${_byname[${_tok}]}"
  done < <(git -C "${_repo}" -c core.quotePath=false grep -o -E "[A-Za-z0-9_-]*(${_alt})[A-Za-z0-9_-]*" HEAD -- "${_base[@]}" 2>/dev/null || true)

  # Lente forçada: cita, por caminho ou por nome de comando, um comando que o papel não recebe.
  local -A _cmds=()
  for _f in "${!_cut[@]}"; do
    case "${_f}" in .claude/commands/meta/*.md) _cmds["$(basename "${_f}" .md)"]=1 ;; esac
  done
  local _lenses=()
  for _z in "${!_zone[@]}"; do case "${_z}" in .claude/rules/*.md) _lenses+=("${_z}") ;; esac; done
  if [ "${#_lenses[@]}" -gt 0 ] && [ "${#_cmds[@]}" -gt 0 ]; then
    while IFS= read -r _line; do
      _line="${_line#HEAD:}"; _path="${_line%%:*}"; _tok="${_line#*:}"
      _tok="${_tok#commands/meta/}"; _tok="${_tok%.md}"; _tok="${_tok#/meta:}"
      [ -n "${_cmds[${_tok}]:-}" ] && _forced["${_path}"]=1
    done < <(git -C "${_repo}" -c core.quotePath=false grep -o -E "commands/meta/[a-z0-9-]+\.md|/meta:[a-z0-9-]+" HEAD -- "${_lenses[@]}" 2>/dev/null || true)
  fi

  # VIVA: fecho transitivo a partir das âncoras. A lente forçada nunca é viva (nem empresta vida).
  _changed=1
  while [ "${_changed}" -eq 1 ]; do
    _changed=0
    for _z in "${!_zone[@]}"; do
      [ -n "${_alive[${_z}]:-}" ] || [ -n "${_forced[${_z}]:-}" ] && continue
      while IFS= read -r _r; do
        [ -n "${_r}" ] || continue
        [ -n "${_cut[${_r}]:-}" ] && continue
        [ -n "${_forced[${_r}]:-}" ] && continue
        _is_anchor "${_r}" || continue
        if [ -z "${_zone[${_r}]:-}" ] || [ -n "${_alive[${_r}]:-}" ]; then
          _alive["${_z}"]=1; _changed=1; break
        fi
      done <<< "${_refs[${_z}]}"
    done
  done

  # CORTADA: fecho transitivo a partir do que já saiu (e das lentes forçadas).
  for _z in "${!_forced[@]}"; do _gone["${_z}"]=1; done
  _changed=1
  while [ "${_changed}" -eq 1 ]; do
    _changed=0
    for _z in "${!_zone[@]}"; do
      [ -n "${_gone[${_z}]:-}" ] || [ -n "${_alive[${_z}]:-}" ] && continue
      while IFS= read -r _r; do
        [ -n "${_r}" ] || continue
        if [ -n "${_cut[${_r}]:-}" ] || [ -n "${_gone[${_r}]:-}" ]; then
          _gone["${_z}"]=1; _changed=1; break
        fi
      done <<< "${_refs[${_z}]}"
    done
  done

  # A lente forçada que uma âncora cita deixa um ponteiro morto NELA — dito, não calado.
  for _z in "${!_forced[@]}"; do
    while IFS= read -r _r; do
      [ -n "${_r}" ] || continue
      [ -n "${_cut[${_r}]:-}" ] || [ -n "${_gone[${_r}]:-}" ] && continue
      _is_anchor "${_r}" || continue
      echo "AVISO: a lente '${_z}' sai do papel '${_role}' (cita comando cortado), mas '${_r}' a cita e viaja — ponteiro morto." >&2
    done <<< "${_refs[${_z}]}"
  done

  for _z in "${!_gone[@]}"; do printf ':(exclude)%s\n' "${_z}"; done | LC_ALL=C sort
}

# ── O MINI NÃO CORTA: INCLUI (2026-10-10, F2 das portas) ──────────────────────────────────────
# A porta didática é o inverso das outras: em vez de `_base` menos o corte, ela leva SÓ o que a
# allowlist do roles.yaml nomeia (`roles.mini.allowlist`: comandos, agentes, skill e a base mínima de
# suporte). É o desenho do cabeçalho levado ao extremo — allowlist falha FECHADA —, e por isso sem a
# SSOT o modo FALHA ALTO em vez de cair em `_base` (cair no default entregaria o core inteiro ao
# iniciante, em silêncio). Os caminhos do roles.yaml são relativos a `.claude/`.
_mini_positives() {  # $1=REPO → pathspecs positivos do mini, um por linha; rc 3 se a SSOT não responde
  local _repo="$1" _resolver _al _p
  _resolver="${_repo}/.claude/utils/marketplace/resolve-role-bundle.sh"
  [ -f "${_resolver}" ] || { echo "ERRO: --role mini exige a allowlist do roles.yaml, e o resolvedor não existe em '${_repo}'" >&2; return 3; }
  _al="$(bash "${_resolver}" mini --allowlist 2>/dev/null)" || { echo "ERRO: o resolvedor não devolveu a allowlist do mini" >&2; return 3; }
  [ -n "${_al}" ] || { echo "ERRO: allowlist do mini VAZIA no roles.yaml — sem ela o mini não tem o que levar" >&2; return 3; }
  while IFS= read -r _p; do
    [ -n "${_p}" ] || continue
    _p=".claude/${_p%/}"
    if [ -n "$(git -C "${_repo}" ls-tree HEAD -- "${_p}")" ]; then printf '%s\n' "${_p}"
    else echo "AVISO: a allowlist do mini nomeia '${_p}', que não existe em HEAD — não viaja." >&2; fi
  done <<< "${_al}"
}

# CONTRATO — arquivos que vivem DENTRO de um subcaminho cortado e AINDA ASSIM viajam, porque uma
# guarda do ALVO os lê em runtime. Lista curta e manual de propósito: cada entrada custa uma
# justificativa nomeada, e a bancada prova que ela está COMPLETA (nenhum consumidor sobrevivente
# resolve um caminho cortado que não esteja aqui).
#
#   vendor-manifest.sh — a SSOT da superfície que a REGRA 36 varre. Sem ela `lint-artifacts.sh`
#     emite HARD por FAIL-CLOSED deliberado ("sem saber o que viaja, varrer é teatro"),
#     `vendor-scrub-form-check.sh` sai 2 e `kb-vendored-link-check.sh` cai no fallback defasado.
#     Ela não é um passo da adoção — é a PLANTA do transporte, e o alvo a lê sobre si mesmo.
_ROLE_CONTRACT=(.claude/utils/adopt/vendor-manifest.sh)

_is_contract() {  # $1=path → 0 se o arquivo é contrato (viaja apesar do corte)
  local _c
  for _c in "${_ROLE_CONTRACT[@]}"; do [ "$1" = "${_c}" ] && return 0; done
  return 1
}

# Emite os `:(exclude)` do papel, ARQUIVO A ARQUIVO. Duas razões, as duas medidas:
#   · `git ls-tree` NÃO aceita magia de pathspec (`fatal: pathspec magic not supported`), então a
#     enumeração é por PREFIXO de caminho — o que também dispensa distinguir diretório de família
#     de arquivos (`.claude/validation/federation-` é prefixo, não diretório).
#   · exclude vence positivo (medição (1) do cabeçalho), logo poupar o contrato exige NÃO excluí-lo
#     — e isso só é expressável enumerando.
# Derivado de HEAD: helper novo dentro de um subcaminho cortado nasce cortado, sem lista a manter.
# ⚠️ `-c core.quotePath=false` E `-z` NÃO SÃO ESTILO — medido 2026-09-15 pela passada adversarial.
# `git ls-tree -r --name-only` aplica C-quoting: um caminho com acento sai como
# `".claude/utils/adopt/acentua\303\247\303\243o.sh"`, com aspas e escapes. O `case` por prefixo então
# NÃO casa, nenhum `:(exclude)` é emitido, e o arquivo VAZA — em silêncio, para uma porta PÚBLICA,
# num repo escrito em pt-BR. Pior: o resultado dependia de `core.quotePath`, config PESSOAL do
# operador — o mesmo comando cortava ou vazava conforme quem rodasse. `-z` remove o quoting de vez
# (separador NUL), e `read -r -d ''` o consome. Hoje o repo tem 0 caminhos assim; a guarda é para o
# dia em que tiver, e esse dia não avisa.
_emit_role_excludes() {  # $1=REPO $2=papel
  local _repo="$1" _role="$2" _f _pre _cuts
  _cuts="$(_role_cut "${_role}")"
  [ -n "${_cuts}" ] || return 0
  while IFS= read -r -d '' _f; do
    [ -n "${_f}" ] || continue
    _is_contract "${_f}" && continue
    while IFS= read -r _pre; do
      [ -n "${_pre}" ] || continue
      case "${_f}" in "${_pre}"*) printf ':(exclude)%s\n' "${_f}"; break ;; esac
    done <<< "${_cuts}"
  done < <(git -C "${_repo}" -c core.quotePath=false ls-tree -r -z --name-only HEAD -- "${_base[@]}")
}

# ── DOIS MODOS, e a diferença é DELIBERADA ────────────────────────────────────────────────────
# `--emit-scrub-roots` = a SUPERFÍCIE DECLARADA (o que viajaria). NÃO consulta git: as guardas que a
#   consomem rodam em SANDBOX SEM REPOSITÓRIO, e ali `git ls-tree HEAD` devolve vazio. Medido
#   2026-09-14, na 1ª bancada completa depois da SSOT: a lista vinha vazia, o fail-closed da REGRA 36
#   disparava e o lint do sandbox saía com 43 HARD — a minha guarda nova reprovando o repo inteiro por
#   um detalhe de ambiente. Guarda que depende de git para saber O QUE VARRER é guarda que não roda
#   onde mais precisa rodar.
#   ⚠️ E ELE IGNORA O `--role`, de propósito (decidido 2026-09-15 junto com o corte). As guardas que o
#   consomem varrem DIRETÓRIOS; um `:(exclude)` aqui as faria varrer MENOS. Varrer mais do que viaja
#   nunca é fail-open — varrer menos é. O papel corta o TRANSPORTE; a varredura fica na superfície
#   inteira, e a assimetria é o lado seguro dos dois modos.
# `--role/manifest`  = a superfície declarada ∩ HEAD (o transporte real; `git archive` aborta com
#   pathspec que não casa nada). Sem git, FALHA ALTO — transporte que não sabe o que existe não copia.
# ── A VARREDURA COBRE ALÉM DO TRANSPORTE — e o `plugins/` é o motivo ─────────────────────────
# Medido 2026-09-16, por refutador adversarial: `plugins/` NÃO era raiz de varredura, e é o transporte
# MAIS PÚBLICO que existe nesta casa (o marketplace publica aquele diretório para qualquer um). O
# conteúdo estava limpo na medição — e essa é exatamente a frase perigosa: limpo era o CONTEÚDO, não
# a COBERTURA. É a tese do cabeçalho deste arquivo aplicada a si mesmo, "guarda que varre menos do que
# o transporte emite é fail-open com cara de cobertura", um andar acima: `plugins/` não estava nem no
# transporte que esta SSOT descreve, então nenhuma guarda o olhava.
#
# ⚠️ POR QUE ISTO É UMA LISTA SEPARADA, e não uma entrada em `_base`: `_base` é o MANIFESTO — o que
# `git archive` copia para o adotante. Um `plugins` ali faria o plugin montado VIAJAR dentro do bundle,
# que é outra coisa e está errada. A assimetria é o desenho declarado dez linhas acima: varrer mais do
# que viaja nunca é fail-open; varrer menos é. Portanto o extra só sai no modo `scrub`.
_SCRUB_EXTRA=(plugins)

if [ "${MODE}" = "scrub" ]; then
  printf '%s\n' "${_base[@]}" "${_SCRUB_EXTRA[@]}"
  exit 0
fi

# ── --list / --diff: O QUE CADA PORTA LEVA, contado do transporte REAL (2026-10-10, F2 das portas) ──
# Não é uma segunda lista: roda o PRÓPRIO modo manifesto (recursão sobre este arquivo) e conta o que o
# `git archive` copiaria — `diff-tree` contra a árvore vazia, a mesma medição da guarda de bundle vazio.
# Contar à parte seria abrir a duplicação que este arquivo existe para impedir.
# O `--diff` compara com a PUBLICAÇÃO ANTERIOR: o clone que o members.yaml registra (kind door, mesmo
# papel) em `local_path`. Só lê; nunca escreve na porta (I3). Clone ausente ou sem árvore .claude/ é DITO.
if [ "${MODE}" = "list" ]; then
  git -C "${REPO}" rev-parse HEAD >/dev/null 2>&1 || { echo "ERRO: --list exige repositório git com HEAD em '${REPO}'" >&2; exit 2; }
  _lerr="$(mktemp)"; _lrc=0
  _lout="$(bash "${BASH_SOURCE[0]}" --role "${ROLE}" --repo "${REPO}" 2>"${_lerr}")" || _lrc=$?
  # o stderr do manifesto vai junto mesmo com rc 0: é lá que moram os avisos de lente forçada e de
  # ponteiro morto, e o `--list` que os descartava escondia exatamente o que existe para ser visto.
  cat "${_lerr}" >&2; rm -f "${_lerr}"
  [ "${_lrc}" -eq 0 ] || exit "${_lrc}"
  _lspec=(); mapfile -t _lspec <<< "${_lout}"
  _lfiles="$(git -C "${REPO}" -c core.quotePath=false diff-tree -r --name-only --no-commit-id \
              4b825dc642cb6eb9a060e54bf8d69288fbee4904 HEAD -- "${_lspec[@]}" | LC_ALL=C sort)"
  _count() { grep -cE "$1" <<< "${_lfiles}" || true; }
  echo "papel: ${ROLE} · fonte: HEAD $(git -C "${REPO}" rev-parse --short=12 HEAD)"
  printf '  %-11s %5s\n' \
    comandos   "$(grep -E '^\.claude/commands/.+\.md$' <<< "${_lfiles}" | grep -vE '/README\.md$|^\.claude/commands/common/' | grep -c . || true)" \
    agentes    "$(grep -E '^\.claude/agents/.+\.md$' <<< "${_lfiles}" | grep -vE '/README\.md$' | grep -c . || true)" \
    skills     "$(grep -oE '^\.claude/skills/[^/]+/' <<< "${_lfiles}" | LC_ALL=C sort -u | grep -c . || true)" \
    utils      "$(_count '^\.claude/utils/')" \
    validation "$(_count '^\.claude/validation/')" \
    hooks      "$(_count '^\.claude/hooks/')" \
    rules      "$(_count '^\.claude/rules/')" \
    workflows  "$(_count '^\.claude/workflows/')" \
    docs       "$(_count '^docs/')" \
    total      "$(grep -c . <<< "${_lfiles}" || true)"
  # O MINI É ALLOWLIST: o que os arquivos dele citam e não viaja é ponteiro morto na porta didática.
  # Dito aqui, contado, e nunca calado — a cura (simplificar a skill onion, decidir cada citação) é da F5.
  if [ "${ROLE}" = "mini" ]; then
    _dang=""; _f=""; _c=""
    while IFS= read -r _f; do
      case "${_f}" in *.md|*.sh) : ;; *) continue ;; esac
      while IFS= read -r _c; do
        _c="${_c%[.,;:)]}"; _c="${_c%/}"
        [ -n "${_c}" ] || continue
        case "${_c}" in .claude/sessions*|.claude/.onion-version|.claude/projects*|.claude/settings*) continue ;; esac
        grep -qxF "${_c}" <<< "${_lfiles}" && continue
        grep -qF "${_c}/" <<< "${_lfiles}" && continue
        grep -qxF "${_c}.md" <<< "${_lfiles}" && continue   # citação sem extensão de um .md que viaja
        [ "$(tr -cd '/' <<< "${_c}" | wc -c)" -ge 2 ] || continue   # `.claude/utils` genérico não é ponteiro
        _dang="${_dang}${_c} (citado por ${_f})"$'\n'
      done < <(git -C "${REPO}" show "HEAD:${_f}" 2>/dev/null | grep -oE '\.claude/[A-Za-z0-9_./-]+' | LC_ALL=C sort -u)
      # ⚠️ E O COMANDO CITADO POR NOME (`/categoria:comando`), que a 1a redação não contava: ela via 6
      # caminhos e a passada adversarial achou ~30 comandos ausentes (inclusive /meta:setup-integration,
      # o fallback que o CLAUDE.md manda sugerir). Nome de comando é a citação que mais viaja.
      while IFS= read -r _c; do
        [ -n "${_c}" ] || continue
        _cp=".claude/commands/${_c#/}"; _cp="${_cp//://}.md"
        grep -qxF "${_cp}" <<< "${_lfiles}" && continue
        git -C "${REPO}" cat-file -e "HEAD:${_cp}" 2>/dev/null || continue   # só comando que EXISTE no core
        _dangc="${_dangc:-}${_c} (citado por ${_f})"$'\n'
      done < <(git -C "${REPO}" show "HEAD:${_f}" 2>/dev/null | grep -oE '/[a-z]+:[a-z][a-z0-9-]*(:[a-z][a-z0-9-]*)?' | LC_ALL=C sort -u)
    done <<< "${_lfiles}"
    if [ -n "${_dang}" ]; then
      echo "AVISO: o mini cita $(printf '%s' "${_dang}" | grep -c .) caminho(s) que a allowlist NÃO leva (ponteiro morto na porta didática; a cura é da F5):" >&2
      printf '%s' "${_dang}" | LC_ALL=C sort -u | sed 's/^/  /' >&2
    fi
    if [ -n "${_dangc:-}" ]; then
      echo "AVISO: o mini cita $(printf '%s' "${_dangc}" | cut -d' ' -f1 | LC_ALL=C sort -u | grep -c .) comando(s) por nome que a allowlist NÃO leva ($(printf '%s' "${_dangc}" | grep -c .) citações; a cura é da F5):" >&2
      printf '%s' "${_dangc}" | LC_ALL=C sort -u | sed 's/^/  /' >&2
    fi
  fi
  if [ "${LIST_DIFF}" -eq 1 ]; then
    _mem="${REPO}/docs/evolution/federation/members.yaml"
    _prev=""
    if [ -f "${_mem}" ] && command -v python3 >/dev/null 2>&1; then
      _prev="$(python3 - "${_mem}" "${ROLE}" <<'PY' 2>/dev/null
import sys, yaml
d = yaml.safe_load(open(sys.argv[1])) or {}
for m in (d.get("members") or []):
    if (m or {}).get("kind") == "door" and str(m.get("role", "")) == sys.argv[2] and m.get("local_path"):
        print("%s\t%s" % (m.get("id", "?"), m["local_path"])); break
PY
)"
    fi
    if [ -z "${_prev}" ]; then
      echo "── diff: nenhuma porta registrada com role '${ROLE}' e local_path no members.yaml — sem publicação anterior a comparar"
    else
      _pid="${_prev%%$'\t'*}"; _ppath="${_prev#*$'\t'}"
      if [ ! -d "${_ppath}/.claude" ]; then
        echo "── diff: a porta '${_pid}' (${_ppath}) não tem árvore .claude/ neste disco — sem lista anterior comparável (porta de marketplace ou clone ausente)"
      else
        _old="$(git -C "${_ppath}" -c core.quotePath=false ls-files -- .claude docs/meta-specs docs/knowledge-base docs/sdaal 2>/dev/null \
                | grep -vE '^\.claude/(\.onion-version|settings\.json)$' | LC_ALL=C sort)"   # o materializador os escreve FORA do manifesto
        _now="$(grep -E '^(\.claude/|docs/(meta-specs|knowledge-base|sdaal)/)' <<< "${_lfiles}" || true)"
        _add="$(LC_ALL=C comm -13 <(printf '%s\n' "${_old}") <(printf '%s\n' "${_now}") | grep . || true)"
        _rem="$(LC_ALL=C comm -23 <(printf '%s\n' "${_old}") <(printf '%s\n' "${_now}") | grep . || true)"
        echo "── diff contra a publicação anterior: porta '${_pid}' (${_ppath}, pin $(awk '/^(source_commit|onion_version|commit):/{print $2; exit}' "${_ppath}/.claude/.onion-version" 2>/dev/null))"
        echo "   + $(grep -c . <<< "${_add}" || true) a mais · - $(grep -c . <<< "${_rem}" || true) a menos"
        [ -n "${_add}" ] && sed 's/^/   + /' <<< "${_add}"
        [ -n "${_rem}" ] && sed 's/^/   - /' <<< "${_rem}"
      fi
    fi
  fi
  echo "── arquivos ($(grep -c . <<< "${_lfiles}" || true))"
  printf '%s\n' "${_lfiles}"
  exit 0
fi

# ── EXCLUSÃO UNIVERSAL: chave de membro nunca viaja, em NENHUM papel ─────────────────────────
# Não é corte de papel — é fronteira de identidade. `jwks/<membro>-N.pem` é chave PÚBLICA (não há
# segredo a proteger), mas o NOME DO ARQUIVO é o nome do cliente, e ele viajava para todo adotante
# e para a porta pública. Medido 2026-09-17 na 1ª materialização real: duas chaves no bundle,
# salvas de subir só por um `.gitignore` do destino — acidente, não desenho.
# Fica fora do `_role_cut` de propósito: o corte por papel é sobre QUANTA fábrica o alvo recebe;
# este é sobre QUEM o bundle nomeia, e a resposta é a mesma nos três papéis.
_IDENTITY_EXCLUDES=(':(exclude).claude/utils/federation-transport/jwks/*.pem')

if [ "${MODE}" = "manifest" ]; then
  git -C "${REPO}" rev-parse HEAD >/dev/null 2>&1 || {
    echo "ERRO: '${REPO}' não é repositório git com HEAD — o manifesto de transporte é declarado ∩ HEAD; use --emit-scrub-roots para a superfície declarada" >&2; exit 2; }
  _spec=() local_p=""
  if [ "${ROLE}" = "mini" ]; then
    _mini_out="$(_mini_positives "${REPO}")" || exit 3
    while IFS= read -r local_p; do [ -n "${local_p}" ] && _spec+=("${local_p}"); done <<< "${_mini_out}"
  else
    for local_p in "${_base[@]}"; do
      [ -n "$(git -C "${REPO}" ls-tree HEAD -- "${local_p}")" ] && _spec+=("${local_p}")
    done
  fi
  while IFS= read -r local_p; do [ -n "${local_p}" ] && _spec+=("${local_p}"); done < <(_emit_role_excludes "${REPO}" "${ROLE}")
  # o rc do corte de comandos É LIDO: `< <(…)` o engolia, e foi assim que o fail-open passou calado.
  _cmd_out="$(_emit_command_excludes "${REPO}" "${ROLE}")" || exit 3
  while IFS= read -r local_p; do [ -n "${local_p}" ] && _spec+=("${local_p}"); done <<< "${_cmd_out}"
  # Os companheiros SÓ podem ser derivados DEPOIS dos dois cortes acima: eles são definidos pelo que
  # já saiu. Ordem invertida = nenhum comando cortado ainda = nenhum companheiro achado, em silêncio.
  while IFS= read -r local_p; do [ -n "${local_p}" ] && _spec+=("${local_p}"); done < <(
    for local_p in "${_spec[@]}"; do case "${local_p}" in ':(exclude)'*) printf '%s\n' "${local_p#:(exclude)}" ;; esac; done \
      | _emit_companion_excludes "${REPO}" "${ROLE}")
  # A exclusão de IDENTIDADE vale nos três papéis: quem o bundle NOMEIA não é assunto de quanta
  # fábrica ele leva. Mas a POSIÇÃO dela não é estética — ela entra DEPOIS da guarda de
  # precondição abaixo, e a razão é um fail-open que a bancada pegou em 2026-09-17.

  # ⚠️ FAIL-LOUD CONTRA O BUNDLE VAZIO SILENCIOSO — medido 2026-09-15: `git archive` devolve rc=0
  # com tar de ZERO arquivos quando os `:(exclude)` cancelam tudo. Quem consome este manifesto lê o
  # rc do archive e conclui "copiei"; o alvo recebe nada. Contar o que sobra é a única verificação
  # honesta (a mesma lição de `exit-code-nao-e-a-verificacao`, um andar acima).
  # ⚠️ ZERO PATHSPEC É "TODOS", NÃO "NENHUM" — e foi a própria bancada deste corte que expôs o furo
  # (caso (e), 2026-09-15). Um repo sem nenhuma raiz da superfície emitia manifesto VAZIO com rc=0;
  # pior, a contagem abaixo roda `diff-tree -- ` sem pathspec, que casa o REPOSITÓRIO INTEIRO — a
  # guarda nova aprovaria a si mesma. Manifesto vazio é falha de precondição, nunca "nada a copiar".
  # ⚠️ CONTA SÓ O QUE É POSITIVO — e esta linha é a cura de um fail-open MEDIDO. A forma anterior
  # testava `${#_spec[@]}` depois de já ter apendado `_IDENTITY_EXCLUDES`, então o array NUNCA era
  # vazio e esta guarda estava MORTA. Pior: a segunda guarda (`_n_sobrou`) também caía, porque um
  # spec composto SÓ de `:(exclude)` casa TUDO MENOS aquilo — num repo alheio o manifesto saía
  # rc=0 mandando copiar o repositório inteiro, biografia e segredos junto, exatamente o desastre
  # que o comentário acima descreve. Quem achou foi a bancada (role-cut (e2)), não uma leitura.
  # A lição é de forma, não de lógica: guarda de PRECONDIÇÃO tem de rodar antes de qualquer coisa
  # que engorde o que ela mede — [[bancada-espelha-o-runner]] um andar acima.
  _n_pos=0; for local_p in "${_spec[@]:-}"; do case "${local_p}" in ':('*) : ;; '') : ;; *) _n_pos=$((_n_pos+1)) ;; esac; done
  if [ "${_n_pos}" -eq 0 ]; then
    echo "ERRO: manifesto VAZIO para '${REPO}' — nenhuma raiz da superfície Onion existe em HEAD. Pathspec ausente significa TODOS para o git: seguir daqui copiaria o repositório inteiro." >&2
    exit 3
  fi

  # Só AGORA a exclusão de identidade entra: ela subtrai superfície, e subtrair de um conjunto
  # vazio de positivos é o que produzia o "copia tudo".
  _spec+=("${_IDENTITY_EXCLUDES[@]}")

  # `git ls-tree` recusa magia de pathspec; `git diff-tree` (comando de diff) a aceita — contra a
  # ÁRVORE VAZIA ele lista exatamente os arquivos que o `git archive` copiaria.
  _EMPTY_TREE=4b825dc642cb6eb9a060e54bf8d69288fbee4904
  _sobrou="$(git -C "${REPO}" diff-tree -r --name-only --no-commit-id "${_EMPTY_TREE}" HEAD -- "${_spec[@]}")"
  _n_sobrou="$(printf '%s' "${_sobrou}" | grep -c . || true)"
  if [ "${_n_sobrou}" -eq 0 ]; then
    echo "ERRO: o manifesto do papel '${ROLE}' não casa arquivo NENHUM em HEAD — o bundle nasceria vazio e o 'git archive' sairia 0 (silencioso). Confira _role_cut/_ROLE_CONTRACT." >&2
    exit 3
  fi
  # ⚠️ O CORTE FALA, e fala o PREÇO MEDIDO — não uma promessa. Medido 2026-09-15, bundle extraído e
  # lintado com a Configuração pós-cópia aplicada: `adopted` nasce com 32 HARD, `standalone` com 69.
  # As duas classes do delta são DA DOUTRINA QUE VIAJA, não do corte em si:
  #   · REGRA 22 (27×) — KB vendorizada linka `../../../.claude/commands/meta/<cmd>.md`, que o papel
  #     não recebe. Link RELATIVO para comando é a forma errada; o nome do comando (`/meta:kg`) viaja
  #     para todo papel, o caminho no disco não.
  #   · REGRA 16 (14×) — prosa com contagem fixa ("109 comandos") num bundle de 67.
  # Dizer isto em voz alta é o ponto: o gap anterior não era a ausência do corte, era o corte ser
  # INVISÍVEL. Silenciar o resíduo o reintroduziria uma camada acima.
  # ⚠️ A 1a redação deste aviso dizia "corta N arquivo(s) da meta-fábrica" e citava um resíduo de ~69
  # HARD medido em 2026-09-15. Desde a matriz (2026-10-10) o standalone LEVA a meta-fábrica, e o número
  # velho virou declaração sem medição; o resíduo atual se mede com `--list` e com o lint da porta.
  if [ -n "$(_role_cut "${ROLE}")" ]; then
    # conta ARQUIVOS pela diferença real contra a superfície sem corte, não pathspecs (a 1a redação
    # contava pathspecs e dizia 72 onde a diferença era 70 — passada adversarial da F2).
    _sem_corte="$(git -C "${REPO}" diff-tree -r --name-only --no-commit-id "${_EMPTY_TREE}" HEAD -- "${_base[@]}" "${_IDENTITY_EXCLUDES[@]}" | grep -c . || true)"
    echo "AVISO: papel '${ROLE}' corta $(( _sem_corte - _n_sobrou )) arquivo(s) do transporte (adoção, federação, comandos fora do papel e os companheiros deles)." >&2
    echo "       Contrato preservado (a guarda do alvo o lê): ${_ROLE_CONTRACT[*]}" >&2
  fi
  printf '%s\n' "${_spec[@]}"
  exit 0
fi

# ── --check-bundle: a classe que a REGRA 45 NÃO cobre ─────────────────────────────────────────
# A biografia que ainda vaza hoje vaza DENTRO de diretório permitido, e em dois formatos distintos:
#   (a) LINK em superfície vendorizada para caminho core-privado → já é a REGRA 45 (Link vendorizado
#       não aponta caminho core-privado, com catraca), com catraca própria. Não duplico aqui.
#   (b) ÍNDICE NOMINAL: os `*-baseline.txt` de .claude/validation/ listam paths do core como DADO,
#       não como link — a REGRA 45 não os vê. Medido 2026-09-13: 32 paths privados únicos, entre eles
#       5 arquivos do grafo pessoal do maestro, e eles JÁ CHEGARAM a 5 adotantes (24-25 linhas cada).
#       O único repo limpo é o onion-standalone, que não passou pelo caminho padrão.
# Esta guarda cobre (b), por FORMA: qualquer baseline emitido que cite caminho privado reprova.
# A cura correta é EMITIR STUB — o baseline do adotante nasce do corpus DELE (regen-baselines.sh
# --ensure-from já faz isso); o passivo do core não é dívida do cliente.
[ -d "${BUNDLE}" ] || { echo "ERRO: ${MODE} exige diretório existente: '${BUNDLE}'" >&2; exit 2; }
# ⚠️ O padrão anterior fixava UM nome completo do vertical pessoal, e era ESTREITO DEMAIS (medido
# 2026-09-16, refutador adversarial): a família tem mais de um repo, e o irmão passava batido —
# inclusive para dentro do plugin PÚBLICO. Guarda por lista falha pelo VOCABULÁRIO, não pela lógica;
# o PREFIXO cobre a família inteira, inclusive o repo que ninguém criou ainda.
_priv='docs/(discussions|analysis|materials|applying)/|onion-pessoal'

# --stub-baselines: a CURA, aplicada na EMISSÃO e não no destino. O cabeçalho é o MESMO que o
# `regen-baselines.sh --ensure-from` semeia, de propósito: os dois mecanismos têm de concordar sobre
# o que é um baseline ainda-não-emitido, senão um desfaz o outro.
if [ "${MODE}" = "stub" ]; then
  _n=0
  for _b in "${BUNDLE}"/.claude/validation/*baseline*.txt; do
    [ -f "${_b}" ] || continue
    grep -qE "${_priv}" "${_b}" || continue
    printf '# Baseline semeado por regen-baselines --ensure-from (sera emitido do corpus do alvo).\n' > "${_b}"
    _n=$(( _n + 1 ))
  done
  echo "stub aplicado em ${_n} baseline(s) — o passivo do core não viaja como dívida do cliente"
  exit 0
fi

# ── (c) ARQUIVO NOMEADO POR MEMBRO — a forma que quase passou, e passou por SORTE ─────────────
# Medido 2026-09-17, na PRIMEIRA materialização real da porta pública: o bundle carregava
#   .claude/utils/federation-transport/jwks/<membro>-1.pem   (duas, nomeando dois adotantes)
# Não são segredo — chave PÚBLICA de JWKS —, mas o NOME DO ARQUIVO é o nome do cliente, e ele viaja
# num repo público. Não subiram só porque o alvo tinha um `jwks/.gitignore` com `*.pem`; sem esse
# acidente, teriam. Guarda que depende do .gitignore do DESTINO não é guarda.
# A derivação é do `members.yaml` (mesma fonte da REGRA 36), e ela é FAIL-OPEN por desenho: sem o
# registro não há o que derivar, e o silêncio é declarado — porque um bundle montado fora do core
# legitimamente não tem o registro à mão.
_members="${REPO}/docs/evolution/federation/members.yaml"
if [ -f "${_members}" ]; then
  _named=""
  while IFS= read -r _id; do
    [ -n "${_id}" ] || continue
    case "${_id}" in onion-*|marcio*|"") continue ;; esac   # prefixo da própria casa não é cliente
    while IFS= read -r _f; do
      [ -n "${_f}" ] && _named="${_named}${_f#"${BUNDLE}/"} (nomeia '${_id}')
"
    done < <(find "${BUNDLE}" -type f -name "*${_id}*" -not -path '*/.git/*' 2>/dev/null)
  done < <(grep -E '^\s+- id:' "${_members}" | sed 's/.*- id:[[:space:]]*//' | tr -d '"' | tr -d "'")
  if [ -n "${_named}" ]; then
    echo "✗ bundle carrega arquivo NOMEADO POR MEMBRO do registro (o nome do cliente viaja no nome do arquivo):" >&2
    printf '%s' "${_named}" | sed 's|^|  |' >&2
    echo "  Remova do transporte (o manifesto não deve levá-los) ou renomeie sem o id do membro." >&2
    exit 1
  fi
fi

_hits=""
for _b in "${BUNDLE}"/.claude/validation/*baseline*.txt; do
  [ -f "${_b}" ] || continue
  if grep -qE "${_priv}" "${_b}" 2>/dev/null; then
    _hits="${_hits}${_b} ($(grep -cE "${_priv}" "${_b}") linha(s))
"
  fi
done
if [ -n "${_hits}" ]; then
  echo "BIOGRAFIA-NO-BUNDLE: baseline(s) emitido(s) citam caminho PRIVADO do core:" >&2
  printf '%s' "${_hits}" | sed 's|^|  |' >&2
  echo "  cura: emitir STUB (cabeçalho + vazio); o regen-baselines.sh preenche do corpus do ALVO." >&2
  exit 1
fi
echo "bundle limpo: nenhum baseline emitido cita caminho privado do core"
