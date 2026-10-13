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
#       · NOME comercial ("AcmeCorp", "Acme-Brand") é sensível em QUALQUER caixa —
#         nenhuma variante dele é pública.
#       · MARCADOR ("CONFIDENCIAL") é literal e só conta em caixa alta: em
#         minúsculo "confidencial" é palavra comum do português, e casar sem caixa
#         produziria falso-positivo em prosa legítima (verificado: o próprio grafo
#         descreve o incidente de 07-10 usando a palavra).
#       O que protege contra falso-positivo no id público não é a caixa, é a
#       EXCLUSÃO EXPLÍCITA dos ids (abaixo) — a caixa nunca foi a defesa certa.
#       ⚠️ ESTE PRESSUPOSTO NASCEU ERRADO: a 1ª versão casava tudo com caixa, e o
#       teste de injeção provou que "post-acmecorp-x" (vazamento minúsculo dentro de
#       um identificador) ESCAPAVA — P2 contradizia P4. O erro fica registrado, não
#       apagado: guarda que só protege prosa não protege identificador.
#  P3 — SUPERFÍCIES SÃO ENUMERADAS, não inferidas. Só o que está na lista é
#       auditado; superfície pública nova que ninguém acrescentar aqui fica
#       invisível. A guarda imprime o que auditou.
#  P4 — O TERMO CONTA EM QUALQUER POSIÇÃO, inclusive dentro de identificadores.
#       Lição de campo (leva 3 da modelagem): nome de cliente vazou para o `id:`
#       de um nó, não só para o label — scrub que só olha prosa não vê.
#  P7 — ID DE NÓ E CAMINHO DE GRAFO (`--kg-identifiers`, SAC-99, 2026-10-11): o id e o caminho de
#       todo .kg.yaml saem para as projeções geradas, então são varridos no corpus inteiro, com os
#       termos derivados MAIS os da fonte privada (P8). Detalhe e teto no bloco P7, mais abaixo.
#  P5 — LISTA VAZIA É SUSPEITA, não sucesso. Se a derivação não produzir termo
#       algum, a guarda não tem o que proteger e passaria verde para sempre —
#       exatamente o NO-OP silencioso. Zero termos → FALHA ALTO.
#  P8 — A FONTE PRIVADA DE TERMOS MORA FORA DA ÁRVORE (decisão do maestro, 2026-10-13: o core
#       ficou PÚBLICO e a árvore foi limpa). Os nomes comerciais que antes viviam como anotação no
#       `name:` do members.yaml e no `client-terms.txt` versionado eram, num repo público, o próprio
#       vazamento. Agora vêm de `${ONION_CLIENT_TERMS_FILE:-$HOME/.config/onion/client-terms.txt}`
#       (no CI, um secret materializado em arquivo temporário). Formato, um por linha (`#` comenta):
#         `<termo>`                 — termo DECLARADO (REGRA 36 e P7, como o antigo client-terms.txt);
#         `<termo><TAB><id-membro>` — nome comercial DE UM MEMBRO (equivale à antiga anotação
#                                     CONFIDENCIAL/PRIVADO do `name:`: entra nos termos derivados,
#                                     nas superfícies públicas e no modo --federation com o dono).
#       Arquivo LEGÍVEL = fonte presente (inclusive vazio: ato deliberado, é o que a bancada usa para
#       reproduzir o comportamento sem termos). Arquivo AUSENTE = a guarda DECLARA que não verificou
#       (`SOFT NAO-VERIFICADO`), roda com o que tiver, e nunca vira HARD de NO-OP por isso: nem verde
#       mudo, nem reprovar tudo.
#  P9 — O DEFAULT DA FONTE PRIVADA SÓ VALE NA FONTE (2026-10-13, medido no update de um adotante
#       de campo, papel hub, pin bd769f168411): a P8 lia `~/.config/onion/client-terms.txt` em
#       QUALQUER repo da máquina, e a lista é a dos clientes DO CORE. No adotante ela acusou HARD da
#       REGRA 36 (6 no relato do adotante, 5 na cópia medida) em arquivos PRÓPRIOS dele (a KB das
#       integrações dele), onde o nome do parceiro dele é legítimo. Antes da P8 a lista morava dentro do core e não existia no adotante: a P8 mudou o
#       lugar e, sem querer, o ALCANCE. Agora: papel `source` (sem stamp, ou stamp `role: source`) e
#       PORTA (`kind: door`, em qualquer papel) → default `~/.config/...`; qualquer outro → SEM default.
#       A lista só entra fora da fonte se for passada EXPLICITAMENTE (ONION_CLIENT_TERMS_FILE ou --client-terms), e
#       `--ct-state` diz qual dos três estados vigora (source-default | explicit | role-off) para o
#       chamador DECLARAR. Explícita vence o papel em qualquer repo: o CI do core continua protegido
#       mesmo que um stamp falso apareça na árvore.
# ─────────────────────────────────────────────────────────────────────────────
#
# Uso:
#   projection-safety.sh [<superfície>...]     # default: site/
#   projection-safety.sh --emit-terms          # imprime os termos derivados
#   projection-safety.sh --emit-declared       # P8: imprime TODOS os termos da fonte privada (rc 3 = fonte ausente · rc 4 = papel sem default, P9)
#   projection-safety.sh --ct-state            # P9: imprime source-default | explicit | role-off (rc 0)
#   projection-safety.sh --client-terms <path> # P8: fonte privada alternativa (senão ONION_CLIENT_TERMS_FILE / ~/.config)
#   projection-safety.sh --members <path> ...  # fonte alternativa (fixtures)
#   projection-safety.sh --kg-identifiers [<raiz>...]  # P7: ids de nó e caminhos de grafo (default: docs/)
#
# Saída: 0 = limpo (ou NÃO VERIFICADO declarado) · 1 = violação HARD ou pressuposto quebrado · 3 = --emit-declared sem fonte · 4 = --emit-declared em papel sem default (P9)

set -u

REPO_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
MEMBERS="${REPO_DIR}/docs/evolution/federation/members.yaml"
MARKERS='CONFIDENCIAL|PRIVADO'          # P1 — vocabulário fechado
EMIT_ONLY=0
FEDERATION=0
KG_IDS=0
FORMAT=human
TERMS_FILE=""                           # #7 do relay: lista de termos DECLARADA (client-safe do adotante)
EMIT_DECLARED=0
# P8 + P9: a fonte privada. Explícita (env) vale em qualquer papel; o default `~/.config` SÓ na fonte.
# O papel é lido do stamp do repo onde a guarda roda (o mesmo REPO_DIR do members.yaml), com a mesma
# leitura do onion-version.sh: sem stamp = source; stamp sem `role:` = adopted; `decoupled_from:` = não-fonte.
_ps_stamp="${REPO_DIR}/.claude/.onion-version"
PS_ROLE="source"
if [ -f "${_ps_stamp}" ]; then
  PS_ROLE="$(awk '/^role:/{print $2; exit}' "${_ps_stamp}" 2>/dev/null)"
  [ -n "${PS_ROLE}" ] || PS_ROLE="adopted"
  grep -qE '^[[:space:]]*decoupled_from:' "${_ps_stamp}" 2>/dev/null && PS_ROLE="decoupled"
  # PORTA (`kind: door`, só o materializador escreve), em QUALQUER papel: é projeção do core, nenhum
  # arquivo ali é próprio de outro dono — a lista do core vale nela como na fonte.
  grep -qE '^[[:space:]]*kind:[[:space:]]*door([[:space:]]|$)' "${_ps_stamp}" 2>/dev/null && PS_ROLE="source"
fi
if [ -n "${ONION_CLIENT_TERMS_FILE:-}" ]; then
  CLIENT_TERMS_FILE="${ONION_CLIENT_TERMS_FILE}"; CT_STATE="explicit"
elif [ "${PS_ROLE}" = "source" ]; then
  CLIENT_TERMS_FILE="${HOME:-/nonexistent}/.config/onion/client-terms.txt"; CT_STATE="source-default"
else
  CLIENT_TERMS_FILE=""; CT_STATE="role-off"
fi
EMIT_CT_STATE=0
SURFACES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --emit-terms) EMIT_ONLY=1; shift ;;
    --federation) FEDERATION=1; shift ;;
    --kg-identifiers) KG_IDS=1; shift ;;      # SAC-99: ids de nó e nomes de grafo (ver bloco P7)
    --members)    MEMBERS="$2"; shift 2 ;;
    --terms)      TERMS_FILE="$2"; shift 2 ;;   # gate client-safe genérico: o adotante declara os PRÓPRIOS termos (nomes de cliente)
    --emit-declared) EMIT_DECLARED=1; shift ;;  # P8: os termos da fonte privada (rc 3 sem fonte)
    --client-terms)  CLIENT_TERMS_FILE="$2"; CT_STATE="explicit"; shift 2 ;;
    --ct-state)      EMIT_CT_STATE=1; shift ;;   # P9: qual fonte vigora (o chamador declara)
    --format)     FORMAT="$2"; shift 2 ;;
    -h|--help)    sed -n '1,50p' "$0"; exit 0 ;;
    *)            SURFACES+=("$1"); shift ;;
  esac
done

# P3 na prática: a superfície default era SÓ `site/` — e o incidente que criou esta guarda foi o
# vazamento do CONSOLE, que é projeção gerada e publicada. Medido em 2026-08-17: o console e o mapa
# ficavam FORA da auditoria default, então a guarda nasceu cega justamente para a superfície do seu
# próprio incidente de origem. Agora entram por padrão (ambos estavam limpos ao serem incluídos —
# ampliar cobertura aqui não trocou verde por vermelho, só deixou de ser cego).
N_USER_SURFACES=${#SURFACES[@]}   # o P7 (--kg-identifiers) tem raiz default própria: docs/
if [ ${#SURFACES[@]} -eq 0 ]; then
  SURFACES=("${REPO_DIR}/site")
  for extra in "${REPO_DIR}/docs/onion/federation-console.html" "${REPO_DIR}/docs/onion/federation-map.md"; do
    [ -e "${extra}" ] && SURFACES+=("${extra}")
  done
fi

# ── P8: a fonte privada de termos (fora da árvore) ───────────────────────────
# ct_present: o arquivo é LEGÍVEL (vazio conta como presente — ato deliberado).
# ct_lines: linhas úteis. ct_declared: a 1ª coluna de toda linha (o termo). ct_owned: `<id>\t<termo>`
# das linhas com dono. NENHUMA destas imprime o termo em log: quem as chama só varre.
ct_present() { [ -n "${CLIENT_TERMS_FILE}" ] && [ -r "${CLIENT_TERMS_FILE}" ] && [ -f "${CLIENT_TERMS_FILE}" ]; }
ct_lines() {
  ct_present || return 0
  grep -vE '^[[:space:]]*(#|$)' "${CLIENT_TERMS_FILE}" 2>/dev/null | tr -d '\r' || true
}
ct_declared() {
  ct_lines | awk -F'\t' '{ t=$1; gsub(/^[[:space:]]+|[[:space:]]+$/,"",t); if (t!="") print t }' | sort -u
}
ct_owned() {
  ct_lines | awk -F'\t' 'NF>=2 { t=$1; o=$2; gsub(/^[[:space:]]+|[[:space:]]+$/,"",t); gsub(/^[[:space:]]+|[[:space:]]+$/,"",o)
                                 if (t!="" && o!="") print o "\t" t }' | sort -u
}
# A declaração de NÃO VERIFICADO, uma linha por chamada (tsv: o lint a vira SOFT; humano: aviso alto).
# `$1` = o que ficou sem verificar. O caminho NÃO é o arquivo (que não existe): é o registro ao lado do qual
# a fonte morava, para o aviso ter âncora estável.
ct_declare_unverified() {
  # P9: fora da fonte, sem lista explícita, a lista do core NÃO É O OBJETO deste repo — não há o que
  # "não verificar". Declarar NAO-VERIFICADO aqui seria cobrar do adotante a lista de clientes de OUTRO
  # repo. O estado fica legível por `--ct-state` (e o lint o declara uma vez, na REGRA 36).
  [ "${CT_STATE}" = "role-off" ] && return 0
  if [ "${FORMAT}" = "tsv" ]; then
    printf 'SOFT\tNAO-VERIFICADO\tdocs/evolution/federation/members.yaml\tfonte privada de termos AUSENTE (ONION_CLIENT_TERMS_FILE ou ~/.config/onion/client-terms.txt; no CI, o secret ONION_CLIENT_TERMS) — %s NÃO foi verificado contra os nomes privados; a guarda declara que não sabe, em vez de verde mudo (P8)\n' "$1"
  else
    echo "  ⚠️  NÃO VERIFICADO (P8): fonte privada de termos ausente — ${1} não foi verificado contra os nomes privados."
    echo "      Defina ONION_CLIENT_TERMS_FILE ou crie ~/.config/onion/client-terms.txt (0600)."
  fi
}
if [ "${EMIT_CT_STATE}" = "1" ]; then
  printf '%s\n' "${CT_STATE}"
  exit 0
fi
if [ "${EMIT_DECLARED}" = "1" ]; then
  [ "${CT_STATE}" = "role-off" ] && exit 4
  ct_present || exit 3
  ct_declared
  exit 0
fi

# ── run_audit — auditoria compartilhada (P2/P3/P4) ───────────────────────────
# Varre as SURFACES contra TERMS_CI (nomes, caixa-insensível — pegam identificador)
# e TERMS_CS (marcadores, caixa-sensível). Uma verdade só: tanto o gate de membro
# (members.yaml) quanto o gate client-safe declarado (--terms) chamam ESTA função —
# evita dois-parsers/duas-verdades numa guarda de segurança.
run_audit() {
  local violations=0 scanned=0 s f term hits
  for s in "${SURFACES[@]}"; do
    if [ ! -e "${s}" ]; then echo "  ⚠️  superfície inexistente, pulada: ${s}"; continue; fi
    echo "  Auditando (P3)   : ${s#${REPO_DIR}/}"
    while IFS= read -r f; do
      scanned=$((scanned + 1))
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
$(find "${s}" -type f -not -path '*/dist*/*' \( -name '*.html' -o -name '*.xml' -o -name '*.md' -o -name '*.json' -o -name '*.yaml' -o -name '*.txt' -o -name '*.astro' \) 2>/dev/null | sort)
EOF
  done
  echo "  Arquivos varridos: ${scanned}"
  echo ""
  if [ "${violations}" -gt 0 ]; then
    echo "✗ REPROVA — ${violations} violação(ões) HARD de projeção."
    echo "  Termo sensível não sai por esta fronteira. Use o \`id:\` público / a projeção client-safe."
    return 1
  fi
  echo "OK ✓ — nenhuma superfície carrega termo sensível."
  return 0
}

# ── #7 do relay — GATE CLIENT-SAFE GENÉRICO (`--terms <arquivo>`) ─────────────
# O core deriva os termos de members.yaml (nomes de MEMBRO). Mas um adotante quer
# gatear os PRÓPRIOS nomes de cliente antes de um artefato cruzar a fronteira
# (doc pro cliente, sinal pro core) — "SSOT com partição de visibilidade" (Sinal 6
# do relay do adotante 2026-07). Com `--terms`, a fonte é a lista DECLARADA: um
# termo sensível por linha (`#`/vazio ignorados). MESMA disciplina P0 do
# members.yaml: se o arquivo de termos sumir/for ilegível → FALHA ALTO (um verde
# por ausência de fonte seria falso). Curto-circuita a derivação de federação —
# um adotante não precisa de members.yaml para gatear os próprios clientes.
if [ -n "${TERMS_FILE}" ]; then
  if [ ! -r "${TERMS_FILE}" ]; then
    if [ "${FORMAT}" = "tsv" ]; then
      printf 'HARD\tSEM-FONTE\t%s\tlista de termos declarada ausente/ilegível — sem fonte não há proteção; verde seria falso (P0)\n' "${TERMS_FILE}"
    else
      echo "✗ HARD projection-safety: lista de termos '--terms ${TERMS_FILE}' ausente ou ilegível."
      echo "  (P0) A proteção é DERIVADA da lista declarada; sem fonte, um verde seria falso."
    fi
    exit 1
  fi
  # termos DECLARADOS = linhas não-comentário/não-vazias. Nome de cliente é sensível
  # em qualquer caixa (como o nome de membro) → todos entram em TERMS_CI; sem marcadores.
  TERMS_CI="$(grep -vE '^[[:space:]]*(#|$)' "${TERMS_FILE}" | sed 's/[[:space:]]*$//' | grep -v '^$' | sort -u)"
  TERMS_CS=""
  if [ "${EMIT_ONLY}" = "1" ]; then printf '%s\n' "${TERMS_CI}"; exit 0; fi
  if [ -z "${TERMS_CI}" ]; then
    if [ "${FORMAT}" = "tsv" ]; then
      printf 'HARD\tSEM-TERMOS\t%s\tlista de termos declarada vazia — nada a proteger seria proteção nenhuma (P0)\n' "${TERMS_FILE}"
    else
      echo "✗ HARD projection-safety: lista de termos '${TERMS_FILE}' está vazia — nada a proteger é proteção nenhuma."
    fi
    exit 1
  fi
  if [ "${FORMAT}" != "tsv" ]; then
    echo "=== Gate client-safe — termos declarados ==="
    echo "  Fonte dos termos : ${TERMS_FILE} (lista declarada — #7 do relay)"
    echo "  Termos           : $(printf '%s\n' "${TERMS_CI}" | grep -c .)"
  fi
  run_audit   # função compartilhada (definida acima): audita as SURFACES contra TERMS_CI/TERMS_CS
  exit $?
fi

# ── P0-bis: ESTE REPO TEM FEDERAÇÃO? ─────────────────────────────────────────
# Só o CORE mantém registro de membros. Um adotante não tem — e para ele a
# ausência é NORMAL, não protuguesa quebrada. A 1ª versão não fazia essa
# distinção e reprovava HARD em todo adotante que atualizasse, travando o
# pre-commit dele (achado em campo no update de 2026-07-21, ao aplicar o
# framework num adotante real). É a MESMA classe do baseline de cobertura, que
# também teria viajado e explodido o gate do adotante — a lição não alcançou
# esta guarda porque ela foi escrita depois, noutro arquivo.
# Regra: sem diretório de federação ⇒ nada a proteger ⇒ silêncio (exit 0).
#        COM diretório e SEM members.yaml ⇒ registro quebrado ⇒ HARD (P0).
FED_DIR="$(dirname "${MEMBERS}")"
if [ ! -d "${FED_DIR}" ]; then
  [ "${FORMAT}" = "tsv" ] && exit 0
  [ "${EMIT_ONLY}" = "1" ] && exit 0
  echo "=== Segurança de projeção ==="
  echo "  Este repositório não mantém registro de federação (${FED_DIR#${REPO_DIR}/} ausente)."
  echo "  Nada a proteger — a guarda vale no core, que é quem carrega nomes de membros."
  exit 0
fi

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
        gsub(/—|–|\/|;|,/, "\n", ann)                          # separadores → tokens
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
# P8: os nomes comerciais DE MEMBRO que moram na fonte privada (`<termo>\t<id>`) somam-se aos derivados,
# com o mesmo filtro de P2 (token igual a id público não é nome) e o mesmo piso de comprimento.
derive_owned() {
  local _ids
  _ids="$(awk '/^[[:space:]]*-?[[:space:]]*id:[[:space:]]/{v=$0; sub(/^[^:]*:[[:space:]]*/,"",v); sub(/[[:space:]]*#.*$/,"",v); gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); if (v!="") print tolower(v)}' "${MEMBERS}" 2>/dev/null || true)"
  ct_owned | awk -F'\t' -v ids="${_ids}" 'BEGIN{n=split(ids,I,"\n"); for(i=1;i<=n;i++) if(I[i]!="") pub[I[i]]=1}
    { t=$2; if (length(t)<4) next; if (tolower(t) in pub) next; print t }'
}
TERMS_CI="$( { derive_terms; derive_owned; } | grep -v '^[[:space:]]*$' | sort -u || true)"
CT_ABSENT=0; ct_present || CT_ABSENT=1
TERMS_CS="CONFIDENCIAL"
TERMS="$(printf '%s\n%s\n' "${TERMS_CI}" "${TERMS_CS}" | grep -v '^[[:space:]]*$' | sort -u)"

if [ "${EMIT_ONLY}" = "1" ]; then
  printf '%s\n' "${TERMS}"
  exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# --federation: auditoria MAILBOX-AWARE do histórico de coordenação.
#
# O REGRA-30 padrão (superfícies públicas) é CHAPADO: nenhum nome comercial, ponto.
# O histórico de federação NÃO pode ser auditado assim — 20 dos 22 aparecimentos são
# o nome do PRÓPRIO membro no PRÓPRIO mailbox (outbox/<adotante>/ com o próprio nome-empresa),
# que não vaza para ninguém: um adotante regulado já sabe que é ele mesmo. Guarda que grita lobo 20×
# é desligada no 1º dia — o modo de falha que esta casa mais paga.
#
# Modelo de AMEAÇA (o que de fato vaza):
#   · CRUZADO   — nome comercial de UM membro no mailbox de OUTRO (adotante B aprende
#                 o nome confidencial do adotante A). É o vazamento real.
#   · COMPARTILHADO — nome comercial em artefato lido por TODOS (CHANGELOG, README).
#   · PRÓPRIO   — nome do membro no seu próprio mailbox: PERMITIDO (não vaza).
#
# FRONTEIRA (o que NÃO se gateia, e por quê):
#   · members.yaml  — é a FONTE dos termos; auto-flag seria absurdo.
#   · _processed/   — histórico ENTREGUE. A prevenção acontece no ATIVO, antes da
#                     entrega; reescrever registro entregue para esconder vazamento
#                     é o anti-padrão "reescreve o passado" que a casa rejeita
#                     ("história reconcilia, não apaga"). Se um _processed for um dia
#                     re-projetado numa superfície pública, é a REGRA 30 que pega, no
#                     ponto de projeção — não aqui, no armazenamento.
# Origem: achado de campo 2026-07-21 — a própria REGRA 30, ao escanear o outbox,
# pegou o nome comercial de um adotante numa mensagem entregue a OUTRO adotante (cross-tenant real).
# ─────────────────────────────────────────────────────────────────────────────
if [ "${FEDERATION}" = "1" ]; then
  # Mapa member_id → nome(s) comercial(is). Mesma lógica de marcador/token do
  # derive_terms, mas preservando de QUEM é cada nome (o que o mailbox-aware exige).
  MEMBER_TERMS="$(awk -v markers="${MARKERS}" '
    /^[[:space:]]*-[[:space:]]*id:[[:space:]]/ {
      v=$0; sub(/^[^:]*:[[:space:]]*/,"",v); sub(/[[:space:]]*#.*$/,"",v)
      gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); cur=v; next
    }
    /^[[:space:]]*name:[[:space:]]/ {
      line=$0; sub(/[[:space:]]*#.*$/,"",line)
      if (match(line,/\(.*\)/)==0) next
      ann=substr(line,RSTART+1,RLENGTH-2)
      if (ann !~ markers) next
      sub(/[[:space:]]*ver[[:space:]]+[^,;]*/,"",ann)
      gsub(markers,"",ann); gsub(/—|–|\/|;|,/,"\n",ann)
      nn=split(ann,parts,"\n")
      for (j=1;j<=nn;j++){ t=parts[j]; gsub(/^[[:space:]]+|[[:space:]]+$/,"",t)
        if (t=="") continue; if (length(t)<4) continue
        if (t !~ /[A-Z]|\./ && t !~ /-/) continue
        print cur "\t" t }
    }' "${MEMBERS}" | sort -u)"
  # P8: os nomes de membro da fonte privada, com o DONO (o que o mailbox-aware exige).
  MEMBER_TERMS="$(printf '%s\n%s\n' "${MEMBER_TERMS}" "$(ct_owned)" | grep -v '^[[:space:]]*$' | sort -u || true)"
  [ "${CT_ABSENT}" = "1" ] && ct_declare_unverified "o histórico de federação (REGRA 33)"

  FED_ROOT="${SURFACES[0]:-${FED_DIR}}"
  viol=0; scanned=0
  while IFS= read -r f; do
    [ -n "${f}" ] || continue
    rel="${f#${REPO_DIR}/}"
    case "${rel}" in
      */members.yaml)   continue ;;   # fonte
      */_processed/*)   continue ;;   # entregue — fora do gate (ver FRONTEIRA)
    esac
    # De quem é este mailbox? outbox/<member>/... → owner=<member>; senão compartilhado.
    owner=""
    case "${rel}" in
      */outbox/*) owner="${rel##*/outbox/}"; owner="${owner%%/*}" ;;
    esac
    scanned=$((scanned+1))
    while IFS="$(printf '\t')" read -r mid term; do
      [ -n "${term}" ] || continue
      [ "${mid}" = "${owner}" ] && continue      # PRÓPRIO: permitido
      if grep -qiF -- "${term}" "${f}" 2>/dev/null; then
        kind="CRUZADO"; [ -z "${owner}" ] && kind="COMPARTILHADO"
        if [ "${FORMAT}" = "tsv" ]; then
          printf 'HARD\t%s\t%s\tnome comercial de "%s" em artefato de federação alheio/compartilhado — use o id público\n' "${kind}" "${rel}" "${mid}"
        else
          printf '  ✗ HARD [%s] %s: nome de "%s" presente — use o id público\n' "${kind}" "${rel}" "${mid}"
        fi
        viol=$((viol+1))
      fi
    done <<EOF
${MEMBER_TERMS}
EOF
  done <<EOF
$(find "${FED_ROOT}" -type f \( -name '*.md' -o -name '*.yaml' \) 2>/dev/null | sort)
EOF

  if [ "${FORMAT}" = "tsv" ]; then exit 0; fi
  echo "=== Segurança de projeção — histórico de federação (mailbox-aware) ==="
  echo "  Auditados : ${scanned} artefatos ativos (exclui members.yaml e _processed/)"
  if [ "${viol}" -gt 0 ]; then
    echo ""; echo "✗ REPROVA — ${viol} vazamento(s) cross-tenant/compartilhado."; exit 1
  fi
  echo "  ✓ nenhum nome comercial cruza mailbox nem entra em artefato compartilhado."
  exit 0
fi

# ── P5: lista vazia é NO-OP disfarçado de sucesso ────────────────────────────
n_terms="$(printf '%s\n' "${TERMS}" | grep -c . || true)"
# P8: sem a fonte privada, a guarda DECLARA o que não verificou (uma linha por modo) e o P5 não vira HARD
# por isso — a lista curta é consequência da fonte ausente, já declarada, e reprovar tudo por ela seria
# trocar o verde mudo pelo vermelho que ninguém consegue curar no PR. Com a fonte presente, o P5 vale inteiro.
if [ "${CT_ABSENT}" = "1" ]; then
  if [ "${KG_IDS}" = "1" ]; then ct_declare_unverified "os ids de nó e caminhos de grafo (REGRA 30, P7)"
  else ct_declare_unverified "as superfícies públicas (REGRA 30)"; fi
fi
if [ "${n_terms}" -lt 2 ] && [ "${CT_ABSENT}" = "0" ]; then
  if [ "${FORMAT}" = "tsv" ]; then
    printf 'HARD\tNO-OP\tdocs/evolution/federation/members.yaml\tderivação produziu %s termo(s) — sem termos a guarda passaria verde para sempre; é NO-OP, não aprovação (P5). Vocabulário: %s\n' "${n_terms}" "${MARKERS}"
    exit 1
  fi
  echo "✗ HARD projection-safety: derivação produziu ${n_terms} termo(s) — insuficiente."
  echo "  (P5) Sem termos a guarda passaria verde para sempre: é NO-OP, não aprovação."
  echo "  Confira o vocabulário de marcadores (${MARKERS}) contra members.yaml."
  exit 1
fi

# ── P7: IDS DE NÓ e NOMES DE GRAFO (`--kg-identifiers`, SAC-99) ──────────────
#
# O PONTO CEGO (medido 2026-10-10, onda O4 da migração de provenance; renomeado em 2026-10-11): o `id:` de
# quatro nós e o caminho de um grafo carregavam o nome da PASTA PRIVADA de um hub cujo `id` público é slug
# neutro. Nada acusava, por DOIS motivos que se somavam:
#   (1) a varredura de conteúdo só olha as superfícies públicas enumeradas — e grafo de pesquisa não é
#       uma delas, embora o id e o caminho dele SAIAM para as projeções geradas (o índice de leitura do KG,
#       o backlog projetado), que copiam exatamente estas duas coisas: id e caminho;
#   (2) o nome privado não estava nos termos DERIVADOS do members.yaml — morava só no `client-terms.txt`,
#       a fonte declarada que a REGRA 36 já lê e esta guarda não lia. Slug neutro fecha a vitrine e, no
#       mesmo movimento, desliga a busca (a lição já registrada no próprio client-terms.txt).
# ESCOPO DELIBERADO — id e caminho, não label: label tem trilha própria (as ondas da migração trocam o nome
# privado pelo id com juiz linha a linha), e o selo do maestro na O7 manteve verbatim o DOMÍNIO e o ARQUIVO
# DE DEPLOY. Varrer label aqui acusaria o que o selo manteve — falso positivo, que treina a ignorar o veto.
# TERMOS: os derivados (P0–P2) + TODOS os da fonte privada (P8, fora da árvore desde 2026-10-13; antes era o
# `client-terms.txt` ao lado do members.yaml — ausente, a guarda declara NAO-VERIFICADO),
# MENOS o termo cuja forma normalizada É um id de membro — id é público por P2 (`acme-adopter` no id de nó é
# o id, não o nome comercial). NORMALIZAÇÃO: caixa baixa e `-` `.` espaço → `_`, porque o id de nó usa `_` e
# o caminho usa `-` (`Acme Corp` tem de achar `ACME_CORP` e `acme-corp`).
# A saída NÃO imprime o id casado: diz a LINHA (o log do lint não pode ser o vazamento novo). O CAMINHO do
# grafo SUJO é impresso, sim, porque é o próprio artefato a renomear e o lint precisa apontá-lo; ele já está
# no histórico do core, que não sai (correção da 1ª redação deste comentário, que afirmava o contrário).
# TETO declarado: só o estilo de bloco (`- id:` / `id:` numa linha) — o radar, que é awk, também só lê
# esse; id em estilo flow (`{id: X}`) ou com acento (id só aceita [A-Za-z0-9_]) não é id para o corpus.
# Não olha o alvo de `trace:` nem o label: o índice de leitura copia o caminho do `trace:` e o backlog
# copia o label, e o nome privado pode chegar por ali (resíduo nomeado no grafo do SAC-99).
kg_ids_audit() {
  local files=() f r terms pubids out
  local roots=()
  if [ "${N_USER_SURFACES}" -gt 0 ]; then roots=("${SURFACES[@]}"); else roots=("${REPO_DIR}/docs"); fi
  terms="${TERMS_CI}
$(ct_declared)"
  pubids="$(awk '/^[[:space:]]*-[[:space:]]*id:[[:space:]]/{v=$0; sub(/^[^:]*:[[:space:]]*/,"",v); sub(/[[:space:]]*#.*$/,"",v); gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); if (v!="") print v}' "${MEMBERS}" 2>/dev/null || true)"
  for r in "${roots[@]}"; do
    [ -e "${r}" ] || continue
    while IFS= read -r f; do [ -n "${f}" ] && files+=("${f}"); done <<EOF
$(find "${r}" -type f -name '*.kg.yaml' -not -path '*/fixtures/*' -not -path '*/kg-inbox/_rejected/*' -not -path '*/kg-inbox/_sealed/*' 2>/dev/null | sort)
EOF
  done
  out="$(awk -v terms="${terms}" -v pubids="${pubids}" -v repo="${REPO_DIR}/" '
    function norm(s) { s=tolower(s); gsub(/[-. \/]/,"_",s); return s }
    function sq(s) { s=tolower(s); gsub(/[^a-z0-9]/,"",s); return s }
    # termo CURTO (<=4 depois de espremido) so casa como TOKEN inteiro (entre _ ou borda): substring de
    # sigla acha dentro de palavra alheia (termo Qux em E_QUXE_ORDER — o refutador de 2026-10-11 mediu a forma com siglas reais).
    # termo LONGO casa por substring na forma normalizada OU na espremida (sem separador nenhum), que
    # e a que acha o nome comercial partido em tokens (E_FOO_BAR_X para FooBar).
    function hit(s, j,   ns) {
      ns=norm(s)
      if (short[j]) return index("_" ns "_", "_" term[j] "_") > 0
      return index(ns, term[j]) > 0 || index(sq(s), tsq[j]) > 0
    }
    BEGIN {
      np=split(pubids, P, "\n"); for (i=1;i<=np;i++) if (P[i]!="") { pub[norm(P[i])]=1; pubsq[sq(P[i])]=1 }
      nt=split(terms, T, "\n"); k=0
      for (i=1;i<=nt;i++) { t=T[i]; gsub(/^[[:space:]]+|[[:space:]]+$/,"",t)
        if (length(t)<3) continue; if ((norm(t) in pub) || (sq(t) in pubsq)) continue
        if (norm(t) in seen) continue
        seen[norm(t)]=1; k++; term[k]=norm(t); tsq[k]=sq(t); short[k]=(length(tsq[k])<=4) }
      if (k==0) { print "NOTERMS"; exit }
    }
    # bloco escalar (`narrative: |`): as linhas mais indentadas que a chave são TEXTO, não chave — um
    # `id:` citado ali não é id (falso positivo medido pelo refutador de 2026-10-11).
    FNR==1 { blk=-1 }
    {
      match($0, /^[ ]*/); ind=RLENGTH
      if (blk >= 0) { if ($0 ~ /^[[:space:]]*$/ || ind > blk) next; blk=-1 }
      if ($0 ~ /:[[:space:]]*[|>][-+0-9]*[[:space:]]*$/) blk=ind
    }
    FNR==1 {
      rel=FILENAME; if (index(rel,repo)==1) rel=substr(rel,length(repo)+1)
      for (j=1;j<=k;j++) if (hit(rel,j)) { print "NOME\t" rel "\t0"; break }
    }
    /^[[:space:]]*(-[[:space:]]+)?id:[[:space:]]*/ {
      v=$0; sub(/^[^:]*:[[:space:]]*/,"",v); sub(/[[:space:]]+#.*$/,"",v); gsub(/["'"'"']/,"",v)
      for (j=1;j<=k;j++) if (hit(v,j)) { print "ID\t" rel "\t" FNR; break }
    }
  ' "${files[@]}" /dev/null)"
  if [ "${out}" = "NOTERMS" ]; then
    [ "${CT_ABSENT}" = "1" ] && return 0   # P8: a ausência da fonte já foi declarada acima (NAO-VERIFICADO)
    if [ "${FORMAT}" = "tsv" ]; then
      printf 'HARD\tNO-OP\tdocs/evolution/federation/members.yaml\tP7 sem termo algum depois de excluir os ids públicos — a varredura de ids e nomes de grafo passaria verde para sempre (P5)\n'
    else echo "✗ HARD projection-safety (P7): nenhum termo para varrer ids e nomes de grafo — NO-OP não é aprovação."; fi
    return 1
  fi
  local viol=0 kind path line
  while IFS="$(printf '\t')" read -r kind path line; do
    [ -n "${kind}" ] || continue
    viol=$((viol+1))
    if [ "${kind}" = "NOME" ]; then
      if [ "${FORMAT}" = "tsv" ]; then
        printf 'HARD\tNOME-GRAFO\t%s\to CAMINHO do grafo carrega nome comercial de membro privado — o caminho sai para o índice de leitura do KG e o backlog projetado; renomeie usando o id do members.yaml (git mv + referências)\n' "${path}"
      else echo "  ✗ HARD [NOME-GRAFO] ${path}: o caminho do grafo carrega nome comercial de membro privado — renomeie pelo id do members.yaml"; fi
    else
      if [ "${FORMAT}" = "tsv" ]; then
        printf 'HARD\tID-NO\t%s\tid na linha %s carrega nome comercial de membro privado — o id sai para as projeções do KG; troque pelo id do members.yaml e reescreva as arestas (selo O7: labels e ids usam o id)\n' "${path}" "${line}"
      else echo "  ✗ HARD [ID-NO] ${path}:${line}: id carrega nome comercial de membro privado — troque pelo id do members.yaml"; fi
    fi
  done <<EOF
${out}
EOF
  if [ "${FORMAT}" != "tsv" ]; then
    echo "=== Segurança de projeção — ids de nó e nomes de grafo (P7) ==="
    echo "  Grafos varridos : ${#files[@]}"
    if [ "${viol}" -gt 0 ]; then echo "✗ REPROVA — ${viol} id(s)/caminho(s) com nome comercial."; return 1; fi
    echo "OK ✓ — nenhum id de nó nem caminho de grafo carrega nome comercial."
  fi
  return 0
}
if [ "${KG_IDS}" = "1" ]; then
  kg_ids_audit
  rc=$?
  [ "${FORMAT}" = "tsv" ] && [ "${rc}" -ne 0 ] && exit 0   # tsv: a linha HARD já saiu; o lint decide pelo conteúdo
  exit "${rc}"
fi

# ── P6: o TRECHO PROJETADO do `name:` tem de ser o próprio slug ──────────────
#
# O PONTO CEGO QUE ESTE BLOCO FECHA (medido 2026-08-17, e é o pressuposto da guarda, não um caso):
# a convenção do console é publicar só o que vem ANTES de " (" no `name:` — o parêntese é anotação
# interna. Toda a força desta guarda mira a ANOTAÇÃO; o trecho anterior era tratado como seguro
# POR CONSTRUÇÃO. E foi ali que um nome de cliente sob NDA entrou e APARECEU no console publicado,
# com a guarda verde: o termo não era derivado (o próprio membro o introduzia) e a metade "segura"
# não era conferida por ninguém.
#
# ⚠️ POLARIDADE, que é o que faz esta guarda funcionar: NÃO é lista de nomes proibidos — essas falham
# pelo VOCABULÁRIO (o nome novo nunca está nela; 4 ocorrências dessa classe nesta casa). É a
# INVARIANTE "projetado == slug" com allowlist de ids ISENTOS, que falha FECHADA: membro novo tem de
# cumprir, e a isenção é ato deliberado com motivo escrito. O modo-de-falha vira excesso de bloqueio,
# que é visível, em vez de vazamento, que não é.
#
# Normalização: minúsculas, só alfanumérico — variação de CAIXA do próprio slug é o mesmo nome, não
# nome de terceiro, então passa sem precisar de isenção.
#
# A ISENÇÃO SE DECLARA NO DADO, NÃO NO CÓDIGO: `projection_name_exempt: true` no membro. A 1ª versão
# trazia a allowlist como variável AQUI e a REGRA 36 (vendor-scrub) a reprovou com razão — este script
# é VENDORIZADO e viaja para todo adotante, então id de adotante escrito nele é vazamento cross-tenant
# por adoção. Declarar no members.yaml é melhor por dois motivos, não um: não há id em código vendorizado,
# e a isenção fica visível na revisão do próprio membro que ela isenta.
p6_bad="$(awk '
  function norm(s) { s=tolower(s); gsub(/[^a-z0-9]/,"",s); return s }
  /^[[:space:]]*-[[:space:]]*id:[[:space:]]*/ {
    if (cur_id != "") check()
    cur_id=$0; sub(/^[[:space:]]*-[[:space:]]*id:[[:space:]]*/,"",cur_id); sub(/[[:space:]]*(#.*)?$/,"",cur_id)
    cur_name=""; cur_exempt=0; next
  }
  /^[[:space:]]+projection_name_exempt:[[:space:]]*true[[:space:]]*(#.*)?$/ { if (cur_id != "") cur_exempt=1; next }
  /^[[:space:]]+name:[[:space:]]*/ {
    if (cur_id != "" && cur_name == "") {
      cur_name=$0; sub(/^[[:space:]]+name:[[:space:]]*/,"",cur_name)
      # ⚠️ COMENTÁRIO DE FIM DE LINHA sai ANTES de qualquer coisa. O gerador do console lê o YAML
      # com parser (que descarta o comentário), então comentário NÃO é projetado — e a 1ª versão
      # desta checagem, que não o descartava, acusou FALSO-POSITIVO num membro cujo `name:` traz
      # justamente a anotação "# id/name públicos = SÓ <slug>". Guarda que discorda do gerador
      # sobre o que é projetado mede outra coisa que não a superfície.
      sub(/[[:space:]]+#.*$/,"",cur_name)
      sub(/[[:space:]]+$/,"",cur_name)
      gsub(/^["'"'"']|["'"'"']$/,"",cur_name)
    }
    next
  }
  END { if (cur_id != "") check() }
  function check() {
    if (cur_name == "") return
    if (cur_exempt) return
    short=cur_name; sub(/ \(.*$/,"",short)
    if (norm(short) != norm(cur_id)) printf "%s\t%s\n", cur_id, short
  }
' "${MEMBERS}" 2>/dev/null || true)"

if [ -n "${p6_bad}" ]; then
  while IFS="$(printf '\t')" read -r bid bshort; do
    [ -n "${bid}" ] || continue
    if [ "${FORMAT}" = "tsv" ]; then
      printf 'HARD\tNOME-PROJETADO\tdocs/evolution/federation/members.yaml\tmembro %s projeta "%s" (trecho antes do parêntese) em vez do slug — esse trecho VAI para o console/mapa publicados; use o id e deixe o rótulo humano DENTRO do parêntese (P6)\n' "${bid}" "${bshort}"
    else
      echo "✗ HARD projection-safety (P6): membro '${bid}' projeta \"${bshort}\", não o slug."
      echo "  O trecho antes de \" (\" é o que o console/mapa PUBLICAM. Nome de terceiro ali vaza com a guarda verde."
      echo "  Corrija em members.yaml:  name: ${bid} (<rótulo humano aqui dentro>)"
    fi
  done <<EOF
${p6_bad}
EOF
  [ "${FORMAT}" = "tsv" ] || exit 1
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
$(find "${s}" -type f -not -path '*/dist*/*' \( -name '*.html' -o -name '*.xml' -o -name '*.md' -o -name '*.json' -o -name '*.yaml' -o -name '*.txt' -o -name '*.astro' \) 2>/dev/null | sort)
EOF
  done
  exit 0
fi

echo "=== Segurança de projeção — superfícies públicas ==="
echo "  Fonte dos termos : ${MEMBERS#${REPO_DIR}/}"
echo "  Marcadores (P1)  : ${MARKERS}"
echo "  Termos derivados : ${n_terms} (caixa-sensível; ids públicos excluídos)"

# Caminho members: a auditoria compartilhada (run_audit) contra TERMS_CI/TERMS_CS derivados.
run_audit
exit $?
