#!/usr/bin/env bash
# projection-safety.sh — guarda de SEGURANÇA DE PROJEÇÃO.
#
# Impede que nome comercial de membro privado (ou o marcador de confidencialidade)
# apareça em SUPERFÍCIE PÚBLICA — o que sai do repo privado: o site, e qualquer
# projeção gerada a partir do grafo.
#
# ORIGEM (incidente 2026-07-10): o console público da federação vazou
# "<nome-comercial> — CONFIDENCIAL" verbatim, porque o `name:` do members.yaml
# carrega ANOTAÇÃO INTERNA do maestro entre parênteses. A correção nasceu como
# convenção LOCAL dentro de federation-console.sh (um `.split(' (')[0]` + comentário)
# — cláusula que não alcança o PRÓXIMO mecanismo que projetar para fora.
# Este script é essa regra promovida a guarda compartilhada.
#
# ─────────────────────────────────────────────────────────────────────────────
# 🔒 REGRA DE ADMISSÃO (docs/knowledge-base/concepts/inference-mitigation.md)
# Todo mecanismo que fecha um furo entra PROVANDO-SE — e provando a integridade
# dos seus próprios PRESSUPOSTOS. Enumeração fechada:
#
#  P0 — DE ONDE VEM A LISTA. De docs/evolution/federation/members.yaml, derivada,
#       nunca hardcoded (nome de cliente no script seria o próprio vazamento).
#       Se o arquivo sumir ou não for legível → FALHA ALTO (exit 1). Um guard que
#       fica verde por não achar a fonte é pior que guard nenhum.
#  P1 — VOCABULÁRIO DE MARCADOR, fechado: CONFIDENCIAL | PRIVADO. Marcador novo é
#       invisível a esta guarda — por isso ela IMPRIME os marcadores que procurou,
#       para que a omissão seja visível em vez de silenciosa.
#  P2 — CAIXA: NOME e MARCADOR seguem regras DIFERENTES.
#       · NOME comercial ("Grana.Ai", "Tornak") é sensível em QUALQUER caixa —
#         nenhuma variante dele é pública.
#       · MARCADOR ("CONFIDENCIAL") é literal e só conta em caixa alta: em
#         minúsculo "confidencial" é palavra comum do português, e casar sem caixa
#         produziria falso-positivo em prosa legítima (verificado: o próprio grafo
#         descreve o incidente de 07-10 usando a palavra).
#       O que protege contra falso-positivo no id público não é a caixa, é a
#       EXCLUSÃO EXPLÍCITA dos ids (abaixo) — a caixa nunca foi a defesa certa.
#       ⚠️ ESTE PRESSUPOSTO NASCEU ERRADO: a 1ª versão casava tudo com caixa, e o
#       teste de injeção provou que "post-tornak-x" (vazamento minúsculo dentro de
#       um identificador) ESCAPAVA — P2 contradizia P4. O erro fica registrado, não
#       apagado: guarda que só protege prosa não protege identificador.
#  P3 — SUPERFÍCIES SÃO ENUMERADAS, não inferidas. Só o que está na lista é
#       auditado; superfície pública nova que ninguém acrescentar aqui fica
#       invisível. A guarda imprime o que auditou.
#  P4 — O TERMO CONTA EM QUALQUER POSIÇÃO, inclusive dentro de identificadores.
#       Lição de campo (leva 3 da modelagem): nome de cliente vazou para o `id:`
#       de um nó, não só para o label — scrub que só olha prosa não vê.
#  P5 — LISTA VAZIA É SUSPEITA, não sucesso. Se a derivação não produzir termo
#       algum, a guarda não tem o que proteger e passaria verde para sempre —
#       exatamente o NO-OP silencioso. Zero termos → FALHA ALTO.
# ─────────────────────────────────────────────────────────────────────────────
#
# Uso:
#   projection-safety.sh [<superfície>...]     # default: site/
#   projection-safety.sh --emit-terms          # imprime os termos derivados
#   projection-safety.sh --members <path> ...  # fonte alternativa (fixtures)
#
# Saída: 0 = limpo · 1 = violação HARD ou pressuposto quebrado

set -u

REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MEMBERS="${REPO_DIR}/docs/evolution/federation/members.yaml"
MARKERS='CONFIDENCIAL|PRIVADO'          # P1 — vocabulário fechado
EMIT_ONLY=0
FORMAT=human
SURFACES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --emit-terms) EMIT_ONLY=1; shift ;;
    --members)    MEMBERS="$2"; shift 2 ;;
    --format)     FORMAT="$2"; shift 2 ;;
    -h|--help)    sed -n '1,50p' "$0"; exit 0 ;;
    *)            SURFACES+=("$1"); shift ;;
  esac
done

[ ${#SURFACES[@]} -eq 0 ] && SURFACES=("${REPO_DIR}/site")

# ── P0: a fonte precisa existir e ser legível — senão FALHA ALTO ──────────────
if [ ! -r "${MEMBERS}" ]; then
  if [ "${FORMAT}" = "tsv" ]; then
    printf 'HARD\tSEM-FONTE\tdocs/evolution/federation/members.yaml\tmembers.yaml ausente ou ilegível — a lista de termos é DERIVADA da fonte; sem fonte não há proteção e um verde seria falso (P0)\n'
    exit 1
  fi
  echo "✗ HARD projection-safety: members.yaml ausente ou ilegível em '${MEMBERS}'."
  echo "  (P0) A lista de termos é DERIVADA da fonte; sem fonte não há proteção."
  echo "  Um verde aqui seria falso — por isso reprova."
  exit 1
fi

# ── Derivação dos termos sensíveis (P0/P1/P2) ────────────────────────────────
# Regra: no `name:` do membro, a anotação entre parênteses é interna. Ela só é
# tratada como SENSÍVEL quando carrega um marcador do vocabulário fechado.
# Dela extraímos os nomes comerciais, descartando o próprio marcador, ponteiros
# para documentos ("ver <arquivo>") e qualquer token igual a um id público.
derive_terms() {
  awk -v markers="${MARKERS}" '
    /^[[:space:]]*-?[[:space:]]*id:[[:space:]]/ {
      v = $0; sub(/^[^:]*:[[:space:]]*/, "", v); sub(/[[:space:]]*#.*$/, "", v)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", v); if (v != "") ids[tolower(v)] = 1
      next
    }
    /^[[:space:]]*name:[[:space:]]/ {
      line = $0; sub(/[[:space:]]*#.*$/, "", line)
      # só interessa a anotação entre parênteses
      if (match(line, /\(.*\)/) == 0) next
      ann = substr(line, RSTART + 1, RLENGTH - 2)
      if (ann !~ markers) next                       # P1: sem marcador, não é sensível
      names[++n] = ann
    }
    END {
      for (i = 1; i <= n; i++) {
        ann = names[i]
        sub(/[[:space:]]*ver[[:space:]]+[^,;]*/, "", ann)   # ponteiro p/ doc não é nome
        gsub(markers, "", ann)
        gsub(/[—–\/;,]/, "\n", ann)                          # separadores → tokens
        split(ann, parts, "\n")
        for (j in parts) {
          t = parts[j]
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
          if (t == "") continue
          if (length(t) < 4) continue                        # token curto = ruído
          if (tolower(t) in ids) continue                    # P2: id é público
          if (t !~ /[A-Z]|\./ && t !~ /-/) continue           # nome próprio ou slug
          print t
        }
      }
    }
  ' "${MEMBERS}" | sort -u
}

# Dois conjuntos, por P2:
#   TERMS_CI — nomes comerciais: sensíveis em qualquer caixa (pegam identificador).
#   TERMS_CS — marcadores literais: só em caixa alta (evitam a palavra comum).
TERMS_CI="$(derive_terms)"
TERMS_CS="CONFIDENCIAL"
TERMS="$(printf '%s\n%s\n' "${TERMS_CI}" "${TERMS_CS}" | grep -v '^[[:space:]]*$' | sort -u)"

if [ "${EMIT_ONLY}" = "1" ]; then
  printf '%s\n' "${TERMS}"
  exit 0
fi

# ── P5: lista vazia é NO-OP disfarçado de sucesso ────────────────────────────
n_terms="$(printf '%s\n' "${TERMS}" | grep -c . || true)"
if [ "${n_terms}" -lt 2 ]; then
  if [ "${FORMAT}" = "tsv" ]; then
    printf 'HARD\tNO-OP\tdocs/evolution/federation/members.yaml\tderivação produziu %s termo(s) — sem termos a guarda passaria verde para sempre; é NO-OP, não aprovação (P5). Vocabulário: %s\n' "${n_terms}" "${MARKERS}"
    exit 1
  fi
  echo "✗ HARD projection-safety: derivação produziu ${n_terms} termo(s) — insuficiente."
  echo "  (P5) Sem termos a guarda passaria verde para sempre: é NO-OP, não aprovação."
  echo "  Confira o vocabulário de marcadores (${MARKERS}) contra members.yaml."
  exit 1
fi

if [ "${FORMAT}" = "tsv" ]; then
  for s in "${SURFACES[@]}"; do
    [ -e "${s}" ] || continue
    while IFS= read -r f; do
      [ -n "${f}" ] || continue
      while IFS= read -r term; do
        [ -z "${term}" ] && continue
        if grep -qiF -- "${term}" "${f}" 2>/dev/null; then
          printf 'HARD\tNOME\t%s\tnome comercial de membro privado presente em superfície pública — use o id: público (incidente 2026-07-10)\n' "${f#${REPO_DIR}/}"
        fi
      done <<EOF
${TERMS_CI}
EOF
      while IFS= read -r term; do
        [ -z "${term}" ] && continue
        if grep -qF -- "${term}" "${f}" 2>/dev/null; then
          printf 'HARD\tMARCADOR\t%s\tmarcador de confidencialidade presente em superfície pública — anotação interna do maestro não projeta\n' "${f#${REPO_DIR}/}"
        fi
      done <<EOF
${TERMS_CS}
EOF
    done <<EOF
$(find "${s}" -type f \( -name '*.html' -o -name '*.xml' -o -name '*.md' -o -name '*.json' -o -name '*.yaml' -o -name '*.txt' \) 2>/dev/null | sort)
EOF
  done
  exit 0
fi

echo "=== Segurança de projeção — superfícies públicas ==="
echo "  Fonte dos termos : ${MEMBERS#${REPO_DIR}/}"
echo "  Marcadores (P1)  : ${MARKERS}"
echo "  Termos derivados : ${n_terms} (caixa-sensível; ids públicos excluídos)"

violations=0
scanned=0
for s in "${SURFACES[@]}"; do
  if [ ! -e "${s}" ]; then
    echo "  ⚠️  superfície inexistente, pulada: ${s}"
    continue
  fi
  echo "  Auditando (P3)   : ${s#${REPO_DIR}/}"
  while IFS= read -r f; do
    scanned=$((scanned + 1))
    # NOMES (P2/P4): qualquer caixa, qualquer posição — inclusive dentro de
    # identificadores minúsculos, que é por onde o vazamento real passou.
    while IFS= read -r term; do
      [ -z "${term}" ] && continue
      if grep -qiF -- "${term}" "${f}" 2>/dev/null; then
        hits="$(grep -ciF -- "${term}" "${f}" 2>/dev/null || echo 0)"
        echo "  ✗ HARD  ${f#${REPO_DIR}/}: nome sensível presente (${hits}x)"
        violations=$((violations + 1))
      fi
    done <<EOF
${TERMS_CI}
EOF
    # MARCADORES (P2): literal em caixa alta — minúsculo é palavra comum.
    while IFS= read -r term; do
      [ -z "${term}" ] && continue
      if grep -qF -- "${term}" "${f}" 2>/dev/null; then
        hits="$(grep -cF -- "${term}" "${f}" 2>/dev/null || echo 0)"
        echo "  ✗ HARD  ${f#${REPO_DIR}/}: marcador de confidencialidade presente (${hits}x)"
        violations=$((violations + 1))
      fi
    done <<EOF
${TERMS_CS}
EOF
  done <<EOF
$(find "${s}" -type f \( -name '*.html' -o -name '*.xml' -o -name '*.md' -o -name '*.json' -o -name '*.yaml' -o -name '*.txt' \) 2>/dev/null | sort)
EOF
done

echo "  Arquivos varridos: ${scanned}"
echo ""
if [ "${violations}" -gt 0 ]; then
  echo "✗ REPROVA — ${violations} violação(ões) HARD de projeção."
  echo "  Nome comercial de membro privado não sai do repo privado. Use o \`id:\` público."
  exit 1
fi

echo "OK ✓ — nenhuma projeção pública carrega termo sensível."
exit 0
