#!/usr/bin/env bash
# =============================================================================
# materialize-door.sh — materializa a PORTA PÚBLICA a partir do core privado.
#
# ══ POR QUE ESTE SCRIPT EXISTE, e não é conveniência ═════════════════════════
# Publicar a porta são QUATRO passos, e TRÊS deles falham em SILÊNCIO se
# esquecidos. Medido em 2026-09-16, montando o bundle `hub` à mão:
#
#   · o `--role` corta a biografia (analysis/discussions/materials/diary/
#     federation/applying): medido, os seis saem — a allowlist cumpre;
#   · MAS os BASELINES das catracas carregam os caminhos que elas toleram, e
#     esses caminhos são os dos grafos PESSOAIS. Medido no bundle cru:
#         kg-verification-baseline.txt   32 linhas · 26 citam caminho privado
#         kb-vendored-link-baseline.txt  28 linhas ·  7 citam caminho privado
#     Publicar assim expõe a TOPOLOGIA dos grafos do maestro — nomes, quantos
#     são, como se chamam. O `--stub-baselines` zera isso (26 → 0), mas é um
#     passo SEPARADO do `--role`: quem monta à mão e esquece publica, e o
#     `git push` sai rc=0. Nada avisa.
#
# A ordem é a guarda. Este script existe para que ela não dependa de lembrar.
#
# ══ O QUE ELE NÃO FAZ, e é deliberado ════════════════════════════════════════
# NÃO faz `git push`. Publicar é ato outward-facing e é do maestro (I3 — um
# escritor por repo). O script prepara, verifica e PARA, dizendo o comando.
#
# Uso : ops/materialize-door.sh <dir-destino> [--role hub|standalone|adopted]
#       --role default: hub (a porta leva a maquinaria COMPLETA, meta-fábrica
#       inclusa — decisão do maestro em 2026-09-16, coerente com a liberação da
#       meta-fábrica selada no mesmo dia).
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST=""; ROLE="hub"
while [ $# -gt 0 ]; do
  case "$1" in
    --role) ROLE="${2:-hub}"; shift 2 ;;
    --role=*) ROLE="${1#--role=}"; shift ;;
    -h|--help) sed -n '1,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) DEST="$1"; shift ;;
  esac
done
[ -n "${DEST}" ] || { echo "ERRO: destino obrigatório. Uso: ops/materialize-door.sh <dir> [--role hub]" >&2; exit 2; }

VM="${REPO_ROOT}/.claude/utils/adopt/vendor-manifest.sh"
[ -f "${VM}" ] || { echo "ERRO: SSOT do transporte ausente (${VM})" >&2; exit 3; }

echo "══ materialize-door — papel '${ROLE}' → ${DEST}"

# ── (1) MONTAR pelo manifesto ────────────────────────────────────────────────
# `git archive HEAD`, nunca cópia do disco: untracked e ignored NUNCA viajam,
# nem por engano. É a segunda barreira da allowlist.
mapfile -t SPEC < <(bash "${VM}" --role "${ROLE}" --repo "${REPO_ROOT}" 2>/dev/null)
if [ "${#SPEC[@]}" -eq 0 ]; then
  echo "ERRO: manifesto VAZIO para o papel '${ROLE}' — pathspec ausente significa TODOS para o git; abortando antes de copiar o repositório inteiro." >&2
  exit 3
fi
mkdir -p "${DEST}" || { echo "ERRO: não consegui criar ${DEST}" >&2; exit 3; }
git -C "${REPO_ROOT}" archive --format=tar HEAD -- "${SPEC[@]}" | tar -x -C "${DEST}" || {
  echo "ERRO: falha ao extrair o bundle" >&2; exit 3; }
_n="$(find "${DEST}" -type f -not -path '*/.git/*' | wc -l)"
[ "${_n}" -gt 0 ] || { echo "ERRO: bundle extraído com ZERO arquivos" >&2; exit 3; }
echo "  (1) montado: ${_n} arquivo(s)"

# ── (2) ESVAZIAR os índices nominais ─────────────────────────────────────────
# O passo que se esquece. Sem ele a porta publica os caminhos dos grafos
# privados que as catracas do core toleram.
bash "${VM}" --stub-baselines "${DEST}" 2>&1 | sed 's/^/  (2) /'

# ── (3) VERIFICAR o que foi montado, não o que se pretendia montar ───────────
if ! bash "${VM}" --check-bundle "${DEST}" 2>&1 | sed 's/^/  (3) /'; then
  echo "✗ ABORTADO: o bundle carrega biografia. NÃO publique." >&2
  exit 1
fi

# ── (4) PROVA INDEPENDENTE da guarda: nenhum caminho privado sobrou ──────────
# Não confia no rc do passo (3): CONTA. `exit 0` é declaração do script sobre si;
# verificar é contar o que ele produziu.
# ⚠️ A DISTINÇÃO QUE A 1ª REDAÇÃO NÃO FAZIA, e ela é a decisão selada no nó
# Q_LIBERAR_A_META_FABRICA_PARA_O_PLUGIN: citação de DIRETÓRIO NU (`docs/analysis/`) DESCREVE A
# FRONTEIRA — diz o que NÃO viaja, e removê-la apagaria a explicação da própria allowlist. São 153
# ocorrências e todas FICAM. O que vaza é o DOCUMENTO NOMEADO (`docs/analysis/<algo>.md`): ponteiro
# para um doc que o leitor da porta nunca poderá abrir.
# E fixture de bancada NÃO é ponteiro: `foo.md`, `novo.md`, `cliente-sob-nda.md` são dados de teste,
# nomes inventados para exercitar a guarda. Incluí-los faria a porta reprovar por dado de teste —
# guarda que grita no inócuo ensina a ignorar a que importa.
_leak="$(grep -rnoE 'docs/(analysis|discussions|materials|applying)/[A-Za-z0-9_-]+\.(md|yaml)' "${DEST}" 2>/dev/null \
          | grep -v '/.git/' \
          | grep -vE '(lint-selftest|kb-vendored-link-check|kg-provenance-coverage|/fixtures/)' \
          | sed "s|^${DEST}/||" | sort -u || true)"
if [ -n "${_leak}" ]; then
  _n_leak="$(printf '%s\n' "${_leak}" | wc -l | tr -d ' ')"
  echo "✗ ABORTADO: ${_n_leak} ponteiro(s) para DOCUMENTO PRIVADO NOMEADO no bundle." >&2
  echo "  A porta é PÚBLICA: quem a ler não pode abrir nenhum destes. Cite pelo NOME sem caminho," >&2
  echo "  marcado \`(core-only)\`, como a classe C já curada em 2026-09-16." >&2
  printf '%s\n' "${_leak}" | head -20 | sed 's/^/      /' >&2
  exit 1
fi
echo "  (4) varredura independente: nenhum ponteiro a documento privado nomeado"

_pin="$(git -C "${REPO_ROOT}" rev-parse --short=12 HEAD)"
cat <<FIM

✅ Porta materializada em ${DEST} (papel '${ROLE}', pin ${_pin})

   O PUSH É SEU — o script para aqui por desenho (I3: um escritor por repo, e
   publicar é ato outward-facing). No destino:

     cd ${DEST} && git add -A
     git commit -m "chore(door): materializa do core no pin ${_pin}"
     git push

   E lembre do ciclo: porta sem re-materialização envelhece. O gatilho é toda
   leva mergeada em main que toque a superfície que viaja.
FIM
