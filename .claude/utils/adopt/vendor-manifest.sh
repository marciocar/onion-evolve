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
        .claude/validation/federation-
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
  local _repo="$1" _papel="$2" _f _base_nome _tools _resolver
  [ -n "$(_role_cut "${_papel}")" ] || return 0   # papel que não corta nada também não corta comando
  _resolver="${_repo}/.claude/utils/marketplace/resolve-role-bundle.sh"
  [ -f "${_resolver}" ] || return 0               # sem a SSOT não se adivinha: o corte de comando não acontece
  _tools="$(bash "${_resolver}" "${_papel}" --tools 2>/dev/null)" || return 0
  [ -n "${_tools}" ] || return 0                  # papel sem work_tools declarados → não corta comando
  while IFS= read -r -d '' _f; do
    [ -n "${_f}" ] || continue
    _base_nome="$(basename "${_f}" .md)"
    grep -qxF "${_base_nome}" <<< "${_tools}" || printf ':(exclude)%s\n' "${_f}"
  done < <(git -C "${_repo}" -c core.quotePath=false ls-tree -r -z --name-only HEAD -- .claude/commands/meta)
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
  local _repo="$1" _papel="$2" _f _pre _cuts
  _cuts="$(_role_cut "${_papel}")"
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
  for local_p in "${_base[@]}"; do
    [ -n "$(git -C "${REPO}" ls-tree HEAD -- "${local_p}")" ] && _spec+=("${local_p}")
  done
  while IFS= read -r local_p; do [ -n "${local_p}" ] && _spec+=("${local_p}"); done < <(_emit_role_excludes "${REPO}" "${ROLE}")
  while IFS= read -r local_p; do [ -n "${local_p}" ] && _spec+=("${local_p}"); done < <(_emit_command_excludes "${REPO}" "${ROLE}")
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
