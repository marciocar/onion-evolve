#!/usr/bin/env bash
# vendor-manifest.sh — SSOT do que VIAJA do core para um adotante, por PAPEL.
#
# Uso : vendor-manifest.sh [--role <papel>] [--repo <root>] [--emit-scrub-roots] [--check-bundle <dir>]
#         --role              adopted (default) | hub | standalone
#         --repo              raiz do core (default: git rev-parse --show-toplevel)
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

ROLE="adopted"; REPO=""; MODE="manifest"; BUNDLE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --role) ROLE="${2:-}"; shift 2 ;;
    --repo) REPO="${2:-}"; shift 2 ;;
    --emit-scrub-roots) MODE="scrub"; shift ;;
    --check-bundle) MODE="check"; BUNDLE="${2:-}"; shift 2 ;;
    --stub-baselines) MODE="stub"; BUNDLE="${2:-}"; shift 2 ;;
    *) echo "ERRO: argumento desconhecido: $1" >&2; exit 2 ;;
  esac
done
case "${ROLE}" in adopted|hub|standalone) : ;; *) echo "ERRO: --role desconhecido: '${ROLE}' (adopted|hub|standalone)" >&2; exit 2 ;; esac
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
#   standalone → porta PÚBLICA: recebe o método, não a fábrica que o publica. 108 de 685 arquivos
#                saem (medido 2026-09-15); é o corte que o onion-standalone fez à mão em 2026-07-19.
#   hub/adopted→ NADA sai, e isto é DESENHO DECLARADO, não omissão: no eixo de PATHSPEC os dois são
#                idênticos ao core, porque o hub re-distribui para os projetos da empresa e precisa
#                da fábrica. O que separa hub de adopted é `roles.yaml` (VERTICAIS e WORK_TOOLS) —
#                outra granularidade, outro SSOT. Declarar isso aqui é o que impede a próxima
#                leitura de concluir "ainda é decorativo": para dois dos três papéis, não cortar É
#                a resposta medida.
_role_cut() {  # $1=papel → subcaminhos a cortar, um por linha (vazio = nada a cortar)
  case "$1" in
    standalone)
      # PREFIXOS de caminho (não pathspecs): `git ls-tree` recusa magia, e prefixo dispensa
      # distinguir diretório de família de arquivos — `validation/federation-` é a segunda.
      printf '%s\n' \
        .claude/utils/adopt/ \
        .claude/utils/marketplace/ \
        .claude/utils/wizard/ \
        .claude/utils/vertical/ \
        .claude/utils/federation-transport/ \
        .claude/commands/meta/ \
        .claude/validation/federation-
      ;;
    *) : ;;
  esac
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
_emit_role_excludes() {  # $1=REPO $2=papel
  local _repo="$1" _papel="$2" _f _pre _cuts
  _cuts="$(_role_cut "${_papel}")"
  [ -n "${_cuts}" ] || return 0
  while IFS= read -r _f; do
    [ -n "${_f}" ] || continue
    _is_contract "${_f}" && continue
    while IFS= read -r _pre; do
      [ -n "${_pre}" ] || continue
      case "${_f}" in "${_pre}"*) printf ':(exclude)%s\n' "${_f}"; break ;; esac
    done <<< "${_cuts}"
  done < <(git -C "${_repo}" ls-tree -r --name-only HEAD -- "${_base[@]}")
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
if [ "${MODE}" = "scrub" ]; then
  printf '%s\n' "${_base[@]}"
  exit 0
fi

if [ "${MODE}" = "manifest" ]; then
  git -C "${REPO}" rev-parse HEAD >/dev/null 2>&1 || {
    echo "ERRO: '${REPO}' não é repositório git com HEAD — o manifesto de transporte é declarado ∩ HEAD; use --emit-scrub-roots para a superfície declarada" >&2; exit 2; }
  _spec=() local_p=""
  for local_p in "${_base[@]}"; do
    [ -n "$(git -C "${REPO}" ls-tree HEAD -- "${local_p}")" ] && _spec+=("${local_p}")
  done
  while IFS= read -r local_p; do [ -n "${local_p}" ] && _spec+=("${local_p}"); done < <(_emit_role_excludes "${REPO}" "${ROLE}")

  # ⚠️ FAIL-LOUD CONTRA O BUNDLE VAZIO SILENCIOSO — medido 2026-09-15: `git archive` devolve rc=0
  # com tar de ZERO arquivos quando os `:(exclude)` cancelam tudo. Quem consome este manifesto lê o
  # rc do archive e conclui "copiei"; o alvo recebe nada. Contar o que sobra é a única verificação
  # honesta (a mesma lição de `exit-code-nao-e-a-verificacao`, um andar acima).
  # ⚠️ ZERO PATHSPEC É "TODOS", NÃO "NENHUM" — e foi a própria bancada deste corte que expôs o furo
  # (caso (e), 2026-09-15). Um repo sem nenhuma raiz da superfície emitia manifesto VAZIO com rc=0;
  # pior, a contagem abaixo roda `diff-tree -- ` sem pathspec, que casa o REPOSITÓRIO INTEIRO — a
  # guarda nova aprovaria a si mesma. Manifesto vazio é falha de precondição, nunca "nada a copiar".
  if [ "${#_spec[@]}" -eq 0 ]; then
    echo "ERRO: manifesto VAZIO para '${REPO}' — nenhuma raiz da superfície Onion existe em HEAD. Pathspec ausente significa TODOS para o git: seguir daqui copiaria o repositório inteiro." >&2
    exit 3
  fi

  # `git ls-tree` recusa magia de pathspec; `git diff-tree` (comando de diff) a aceita — contra a
  # ÁRVORE VAZIA ele lista exatamente os arquivos que o `git archive` copiaria.
  _ARVORE_VAZIA=4b825dc642cb6eb9a060e54bf8d69288fbee4904
  _sobrou="$(git -C "${REPO}" diff-tree -r --name-only --no-commit-id "${_ARVORE_VAZIA}" HEAD -- "${_spec[@]}")"
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
  if [ -n "$(_role_cut "${ROLE}")" ]; then
    echo "AVISO: papel '${ROLE}' corta $(( ${#_spec[@]} - ${#_base[@]} )) arquivo(s) da meta-fábrica do transporte." >&2
    echo "       Contrato preservado (a guarda do alvo o lê): ${_ROLE_CONTRACT[*]}" >&2
    echo "       RESÍDUO MEDIDO 2026-09-15: o bundle deste papel nasce com ~69 HARD contra ~32 de 'adopted'" >&2
    echo "       — REGRA 22 (link relativo p/ comando cortado) e REGRA 16 (contagem fixa na prosa). NÃO é" >&2
    echo "       defeito do corte: é doutrina vendorizada que cita caminho do core. Fio aberto, declarado." >&2
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
_priv='docs/(discussions|analysis|materials|applying)/|onion-pessoal-marcio'

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
