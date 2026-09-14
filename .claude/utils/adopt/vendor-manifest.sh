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
# ══ O PAPEL É O CORTE ═════════════════════════════════════════════════════════════════════════
# Medido no onion-standalone (pin cd0f847bc39f): 274 arquivos a menos que o core, ZERO a mais — a
# meta-fábrica inteira fora (utils/{adopt,marketplace,wizard,vertical,federation-transport,...},
# validation/federation-*). Aquele corte foi COMPOSIÇÃO MANUAL em 2026-07-19; aqui ele vira
# mecanismo. `roles.yaml` resolve VERTICAIS e WORK_TOOLS (plugins/comandos) — outra granularidade;
# este arquivo resolve PATHSPECS de transporte. Os dois são SSOTs de coisas diferentes.
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
# ⚠️ A LICENÇA NÃO ESTÁ AQUI, E A AUSÊNCIA É UM DEFEITO ABERTO — não um desenho.
#
# O problema é real e medido: QUATRO destas raízes (.claude/rules, docs/meta-specs,
# docs/knowledge-base, docs/sdaal) são exatamente o material que o `LICENSE-DOCS` declara CC BY-NC,
# e nenhuma licença as acompanha. Os adotantes recebem ~104 arquivos de método sem uma linha de
# licença, e o commit deles cai num repo que carrega o LICENSE do próprio dono. A CC BY-NC 4.0 §3.a
# exige o aviso na redistribuição; quem redistribui é este script.
#
# ⚠️ E POR QUE A CURA ÓBVIA ESTÁ ERRADA — medido em 2026-09-14, e o teste foi executado: pôr
# `LICENSE LICENSE-DOCS` nesta lista faz o transporte SOBRESCREVER o LICENSE do alvo. O passo (d)
# da cópia segura é `cp -R "$TMP"/. "$DEST"/`, e o único never-clobber por-arquivo é o
# `.env.example` (`grep -c LICENSE` no adopt.md dava ZERO). Um aviso proprietário na raiz do repo
# do cliente viraria MIT no nome do autor do core — relicenciamento silencioso na direção MAIS
# GRAVE, feito pela cura que existia para impedir relicenciamento silencioso.
#
# A CURA CERTA tem duas pernas e NENHUMA cabe aqui:
#   (1) never-clobber por-arquivo no adopt, no molde do `.env.example` (alvo que já tem LICENSE
#       recebe `LICENSE.onion`, e o merge é do maestro);
#   (2) a QUINTA CÓPIA da lista: `.claude/utils/adopt/durable-commit.sh:43` tem um `ONION_PATHS`
#       hardcoded e independente desta SSOT — no caminho `--update` a licença não viajaria mesmo
#       estando aqui. O PR #826 criou esta SSOT para matar "quatro cópias da mesma lista"; havia
#       uma quinta, e só a passada adversarial a achou.
# Fio próprio, com gatilho: a primeira consultoria que forkar. Ver o resíduo de
# `feat/public-distribution-decisions`.
# NÃO entram, e o motivo de cada um:
#   .env.example                  → específico do alvo (never-clobber, Fase 3 do adopt)
#   docs/evolution/               → inbox/inbound são infra LOCAL do alvo; copiar clobaria o que está em uso
#   .claude/diary, sessions,      → BIOGRAFIA: 127 arquivos de diário, beacons, farol, worktrees
#     beacons, identity,             e a memória local desta casa
#     scratchpad, worktrees
#   docs/{analysis,materials,     → análises de adotante (incl. achados de segurança), material de
#     applying,discussions,onion}    cliente sob NDA, discussões pessoais, grafos da vida do maestro

# ── DOIS MODOS, e a diferença é DELIBERADA ────────────────────────────────────────────────────
# `--emit-scrub-roots` = a SUPERFÍCIE DECLARADA (o que viajaria). NÃO consulta git: as guardas que a
#   consomem rodam em SANDBOX SEM REPOSITÓRIO, e ali `git ls-tree HEAD` devolve vazio. Medido
#   2026-09-14, na 1ª bancada completa depois da SSOT: a lista vinha vazia, o fail-closed da REGRA 36
#   disparava e o lint do sandbox saía com 43 HARD — a minha guarda nova reprovando o repo inteiro por
#   um detalhe de ambiente. Guarda que depende de git para saber O QUE VARRER é guarda que não roda
#   onde mais precisa rodar.
# `--role/manifest`  = a superfície declarada ∩ HEAD (o transporte real; `git archive` aborta com
#   pathspec que não casa nada). Sem git, FALHA ALTO — transporte que não sabe o que existe não copia.
if [ "${MODE}" = "scrub" ]; then
  printf '%s\n' "${_base[@]}"
  exit 0
fi

if [ "${MODE}" = "manifest" ]; then
  git -C "${REPO}" rev-parse HEAD >/dev/null 2>&1 || {
    echo "ERRO: '${REPO}' não é repositório git com HEAD — o manifesto de transporte é declarado ∩ HEAD; use --emit-scrub-roots para a superfície declarada" >&2; exit 2; }
  local_p=""
  for local_p in "${_base[@]}"; do
    [ -n "$(git -C "${REPO}" ls-tree HEAD -- "${local_p}")" ] && printf '%s\n' "${local_p}"
  done
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
