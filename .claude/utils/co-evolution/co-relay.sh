#!/usr/bin/env bash
# =============================================================================
# co-relay.sh — Carteiro-LOCAL do doc-bridge de co-evolução (UPSTREAM)
#
# Propósito : Espelho upstream do co-deliver.sh. Entregar um SINAL do adotante
#             (markdown datado em docs/evolution/inbox/) no canal inbox/ do CORE
#             que vive na MESMA máquina, para que o hook "you have mail" o sinale
#             📬 na próxima sessão do core — sem o maestro copiar à mão e sem a
#             sessão do adotante commitar cross-repo (o incidente que originou
#             este sub-protocolo: sinal S2 2026-06-25).
#
# -----------------------------------------------------------------------------
# RECADO PARA A PRÓXIMA INSTÂNCIA (leia antes de mexer) — literate breadcrumb
# -----------------------------------------------------------------------------
# Modelo dos 3 ATOS (ADR onion-adr-comms-transport-vs-execution + sub-protocolo
# do regime manual, onion-adr-manual-relay-subprotocol):
#   Ato 1  TRANSPORTAR  (copiar arquivo)   -> determinístico  -> ESTE script
#   Ato 2  NOTIFICAR    (contar arquivos)  -> determinístico  -> hook SessionStart
#   Ato 3  LER/INTERPRETAR/COMMITAR        -> exige juízo     -> sessão HOME do core
#
# Invariante: ENTREGA-SEM-COMMIT. Escreve o sinal como UNTRACKED no inbox/ do CORE
#             (o hook conta arquivos do dir, não precisa de commit) — assim respeita
#             "um escritor por repo" (I3): a sessão do adotante NUNCA commita no repo
#             alheio. O COMMIT + triagem (git mv p/ inbox/_processed/) é da SESSÃO
#             DO CORE, com contexto. Untracked persiste entre checkouts → entrega
#             branch-agnóstica: como NÃO commita, NÃO existe "commit na branch errada".
#
# Guarda de papel: lê o STAMP .claude/.onion-version (campo role:). Só ADOTANTE
#             (role: adopted) relaya upstream. NUNCA usar onion-version.sh para o papel
#             do REMETENTE: o stamp é a evidência de adoção, e a cópia vendorizada do
#             script, num checkout sem stamp, devolve 'source' (o default) → falso-amigo.
#             No DESTINO o uso é o inverso: sem stamp, o core se PROVA pelo
#             onion-version.sh dele dizendo source (guarda do destino, mais abaixo).
#
# PAPÉIS:     maestro = humano (autoridade final, Ato-3) · maestro principal = core
#             (onion-evolve, rege a evolução). A sessão home do destino commita.
#
# Uso       : co-relay.sh [<signal-file>] --target <path-do-core> [--from <dir>] [--dry-run]
#               <signal-file> : basename OU path. Omitido = todos os .md de 1º nível
#                               da fonte (default docs/evolution/inbox/).
#               --target <p>  : path LOCAL do CORE (OBRIGATÓRIO — o adotante não tem
#                               members.yaml para resolver o alvo), do HUB do adotante
#                               ou do DONO de um vendor (vendor/<x>/.<x>-version prova).
#               --from <dir>  : fonte alternativa do(s) sinal(is) (default: o inbox).
#               --dry-run     : mostra o plano, não escreve nada.
#
# Gracioso  : uso inválido / não-adotante / alvo ausente ou não-git → exit 2 (erro
#             de uso, pt-BR em STDERR). Sinal já presente no inbox/ do core → no-op
#             idempotente (exit 0). DEDUP POR CONTEÚDO: byte-idêntico a arquivo no
#             inbox/ OU no inbox/_processed/ do core → no-op "já entregue/processado"
#             (cura a re-entrega pós-triagem, incidente 2026-07-03); mesmo nome com
#             conteúdo DIFERENTE segue entregando (sinal atualizado, não duplicata).
#             Sem `set -e` p/ controlar os exits graciosos.
#             Determinístico, sem LLM. Espelha .claude/utils/co-evolution/co-deliver.sh.
#
# Consumido por /meta:co-relay. Par simétrico downstream: /meta:co-deliver.
# =============================================================================
set -uo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
STAMP="${REPO_ROOT}/.claude/.onion-version"

usage() { echo "uso: co-relay.sh [<signal-file>] --target <path-do-core> [--from <dir>] [--dry-run]" >&2; exit 2; }

SIGNAL_ARG="" ; TARGET="" ; FROM_DIR="" ; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 || usage ;;
    --from)   FROM_DIR="${2:-}"; shift 2 || usage ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage ;;
    -*) echo "ERRO: flag desconhecida: $1" >&2; usage ;;
    *) if [ -z "${SIGNAL_ARG}" ]; then SIGNAL_ARG="$1"; else echo "ERRO: argumento extra: $1" >&2; usage; fi; shift ;;
  esac
done

# --- Guarda de papel: SÓ ADOTANTE (lê o STAMP, nunca onion-version.sh) ---
role_field() {  # extrai 'role:' do stamp (tira comentário inline, aspas, espaços)
  grep -E '^[[:space:]]*role:' "$1" 2>/dev/null | head -1 \
    | sed -E 's/^[[:space:]]*role:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//; s/"//g; s/'\''//g'
}
if [ ! -f "${STAMP}" ]; then
  echo "ERRO: ${STAMP} ausente — co-relay roda no ALVO (role: adopted, hub ou standalone)." >&2
  echo "      Sem stamp = core/fonte ou pré-adoção; o core não relaya upstream (use /meta:co-announce)." >&2
  exit 2
fi
ROLE="$(role_field "${STAMP}")"
# ⚠️ `hub` ENTRA, e a omissão custou um sinal entregue à mão (2026-09-17). A condição antiga era
# `!= "adopted"`, enquanto a mensagem de stamp-ausente logo acima já prometia "adopted ou hub" e o
# espelho downstream `co-deliver.sh` valida `role:(adopted|hub)` e só entrega a hub/standalone
# (T1/T3, RFC-0003 §2.1). Ou seja: o core ENTREGAVA anúncios à porta por desenho declarado, e a
# porta não podia responder — o doc-bridge mecanizado num sentido só, justamente na superfície
# PÚBLICA, que é a que mais gera sinal de primeira impressão. A assimetria era desta linha.
case "${ROLE}" in
  adopted|hub|standalone) : ;;
  *)
    echo "ERRO: role='${ROLE:-vazio}' no stamp — co-relay é só para ALVO (role: adopted, hub ou standalone)." >&2
    echo "      O core (role: source) anuncia downstream via /meta:co-announce, não relaya upstream." >&2
    exit 2 ;;
esac

# --- Resolve alvo (o CORE): --target é sempre obrigatório (sem members.yaml no adotante) ---
[ -n "${TARGET}" ] || { echo "ERRO: --target <path-do-core> é obrigatório (o adotante não tem members.yaml)." >&2; usage; }
[ -d "${TARGET}" ] || { echo "ERRO: --target não é diretório: ${TARGET}" >&2; exit 2; }
[ -e "${TARGET}/.git" ] || { echo "ERRO: --target não parece um repo git: ${TARGET}" >&2; exit 2; }
TARGET="$(cd "${TARGET}" && pwd)"   # normaliza para path absoluto
# O próprio repo nunca é destino: com o canal de vendor, um remetente que tem a tag do vendor (o dono
# relayando para si) reescreveria a própria fonte e empilharia rodapés (achado da passada adversarial).
[ "${TARGET}" != "$(cd "${REPO_ROOT}" && pwd)" ] || { echo "ERRO: --target é este próprio repo — o carteiro relaya para FORA (core, hub ou dono de vendor)." >&2; exit 2; }

_norm_remote() {  # https://h/o/r(.git) · git@h:o/r(.git) · ssh://git@h/o/r → h/o/r
  printf '%s' "$1" | sed -E 's#^[a-zA-Z+]+://##; s#^[^@/]+@##; s#:#/#; s#\.git/?$##; s#/+$##'
}

# --- Canal UPSTREAM DE VENDOR (D_CANAL_UPSTREAM_POR_VENDOR, decisão do maestro de 2026-10-20) ---------------
# O adotante que vendoriza um produto (vendor/<x>/, ex. vendor/kg-ssot/) tem DOIS upstreams: o core e o dono
# do vendor. O dono pode ser, ele mesmo, um adotante (o repo de dev do kg-ssot carimba `adopted`), e a guarda de
# canal lateral abaixo o recusava, então o sinal de campo ao kg-ssot só chegava pelo core (sinal de 2026-10-20,
# §3 item 8). A exceção é ESTREITA e se DERIVA do carimbo, nunca de lista de nomes:
#   · o remetente tem `vendor/<x>/.<x>-version` (o JSON que o vendorizador do produto grava) com `tag` e `files`
#     (caminho → sha256 de cada arquivo da release);
#   · o destino PROVA ser a origem: a árvore de `refs/tags/<tag>` DELE reproduz, byte a byte, todo arquivo do
#     carimbo. Um par lateral que só vendoriza o mesmo produto tem os arquivos, mas não a tag na história;
#   · o destino tem `docs/evolution/inbox/` (o dono precisa ter caixa; aqui não se cria canal no repo alheio).
# Por que CONTEÚDO, e não URL nem commit (medido em 2026-10-20 contra o carimbo real do hub e o repo do dono):
# o carimbo não grava URL nenhuma (o kg_vendor.py grava tag, commit e os sha256), e a release vendorizada vem do
# ESPELHO público (marciocar/kg-ssot). O commit 172c62a do carimbo não existe no repo do dono, cuja tag
# kg-ssot-v4.12.0 resolve para 2a69199 e cujo origin é outro repo. URL ou commit recusariam
# o dono real; os sha256 do carimbo batem com a tag dele, 444 de 444. O remote não entra na prova.
# Qualquer outro caso cai na guarda de papel abaixo, inalterada. A autorização viaja no sinal entregue.
VENDOR_AUTH="" ; VENDOR_NAME="" ; VENDOR_TAG="" ; VENDOR_NFILES="" ; VENDOR_REFUSALS="" ; VENDOR_OWNER_NO_BOX=""
# $1 = carimbo, $2 = destino → stdout "ok<TAB>tag<TAB>N" se a tag do destino reproduz os N arquivos;
# senão rc 1 e o motivo (pt-BR) no stdout.
_vendor_proof() {
  python3 -I -c '
import hashlib, json, subprocess, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    print("carimbo ilegível como JSON"); sys.exit(1)
tag, files = d.get("tag"), d.get("files")
if not (isinstance(tag, str) and tag and isinstance(files, dict) and files):
    print("carimbo fora do formato (sem tag ou files)"); sys.exit(1)
def run(*a, data=None):
    return subprocess.run(["git", "-C", sys.argv[2], *a], input=data, capture_output=True)
if run("rev-parse", "--verify", "--quiet", "refs/tags/" + tag + "^{tree}").returncode != 0:
    print("o destino não tem a tag " + tag + " (se é o dono, falta git fetch --tags lá)"); sys.exit(1)
names = sorted(files)
out = run("cat-file", "--batch", data="".join("refs/tags/%s:%s\n" % (tag, n) for n in names).encode()).stdout
i, bad = 0, []
for n in names:
    nl = out.index(b"\n", i); head = out[i:nl].split(); i = nl + 1
    if head[-1] == b"missing":
        bad.append(n); continue
    size = int(head[2]); blob = out[i:i + size]; i += size + 1
    if hashlib.sha256(blob).hexdigest() != files[n]:
        bad.append(n)
if bad:
    print("a tag %s do destino diverge do carimbo em %d de %d arquivo(s), ex.: %s" % (tag, len(bad), len(names), bad[0]))
    sys.exit(1)
print("ok", tag, len(names), sep="\t")
' "$1" "$2" 2>/dev/null
}
if [ -d "${REPO_ROOT}/vendor" ] && ! command -v python3 >/dev/null 2>&1; then
  VENDOR_REFUSALS="python3 ausente: a prova do canal de vendor não roda neste host. "
elif [ -d "${REPO_ROOT}/vendor" ]; then
  for vdir in "${REPO_ROOT}"/vendor/*/; do
    vname="$(basename "${vdir}")"
    vstamp="${vdir}.${vname}-version"
    [ -f "${vstamp}" ] || continue
    proof="$(_vendor_proof "${vstamp}" "${TARGET}")"
    case "${proof}" in
      ok$'\t'*) : ;;
      *) VENDOR_REFUSALS="${VENDOR_REFUSALS}vendor/${vname}: ${proof:-a prova não rodou}. "; continue ;;
    esac
    if [ ! -d "${TARGET}/docs/evolution/inbox" ]; then
      VENDOR_REFUSALS="${VENDOR_REFUSALS}vendor/${vname}: o destino é a origem do carimbo, mas não tem docs/evolution/inbox/ (o dono não abriu caixa; não crio canal no repo alheio). "
      VENDOR_OWNER_NO_BOX="vendor/${vname}"
      continue
    fi
    IFS=$'\t' read -r _ok VENDOR_TAG VENDOR_NFILES <<< "${proof}"
    VENDOR_NAME="${vname}"; VENDOR_AUTH="vendor/${vname}/.${vname}-version"
    break
  done
fi

# --- Guarda do DESTINO (F3 do configurador A2A, 2026-10-15): upstream é o core OU o hub do adotante ------
# A rede do hub nasce junto com a do core: o filho de um hub (T2, carimbo `adopted`) manda sinal ao PRÓPRIO
# hub, que vive na mesma máquina. Até aqui o destino só precisava ser um repo git, e o carteiro relayava
# para qualquer checkout, inclusive o de outro adotante: um canal lateral que a topologia proíbe
# (standalone não tem canal lateral; consumer só fala com o seu hub). O destino agora se prova:
#   · sem carimbo .claude/.onion-version = candidato a core, que PROVA o papel pelo onion-version.sh (abaixo);
#   · carimbo role: hub = um hub, e só o carimbo `adopted` (quem pode ser filho de hub) relaya para ele;
#   · qualquer outro carimbo (adopted, standalone, porta) = par lateral → recusa.
# QUAL hub é o pai: o carimbo `adopted` não distingue o filho de um hub do standalone do core (os dois
# carimbam `adopted`; achado do refutador da F3, medido em adotantes reais desta máquina). Sem o registro, a
# prova que o carteiro tem é o `adopted_from` do carimbo do remetente: tem de ser o remote `origin` do hub ou
# o caminho dele. Quem adotou o core (adopted_from = o core) não relaya para hub nenhum.
# --- Prova do CORE (destino sem carimbo) -----------------------------------------------------------------------
# $1 = destino → rc 0 se o onion-version.sh dele diz role: source; senão rc 1 e o motivo (pt-BR) no stdout.
# LÊ o script, não o EXECUTA. Executar seria rodar código de outro repo, com os privilégios desta sessão, só para
# decidir para onde copiar um markdown; e a pergunta tem resposta estática: o script deriva o papel de um default
# no nível do arquivo (`role="source"`), que só um carimbo sobrescreve (em linha indentada, dentro do if), e este
# destino não tem carimbo (o ramo de cima já o tratou). As duas formas de saída que o script já teve são aceitas:
# `role: ${role}` (desde FED-3-1) e a antiga `role: source` literal. Default ou saída com outro papel recusa;
# script que não se deixa ler assim também, com o motivo (sem prova, não se presume).
# LIMITE DECLARADO (passada adversarial de 2026-10-21): a leitura confere a FORMA do script de hoje, não a
# semântica de qualquer bash. Um script ADULTERADO que reatribua o papel em linha indentada (`  export role=hub`,
# `declare role=hub`) ou imprima por `echo` passa; e uma cópia byte-idêntica sem carimbo (o `cp -r .claude` à
# mão, um symlink) passa também, porque pela definição do próprio script ela computa source. Executar não
# curaria nenhum dos dois (a cópia executada mente igual). O que a prova barra é o caso medido: o repo git
# qualquer, sem o script, que antes virava o core.
_core_proof() {
  local ovs="$1/.claude/validation/onion-version.sh" defaults outs d o
  if [ ! -f "${ovs}" ]; then
    echo "não tem .claude/validation/onion-version.sh (sem carimbo e sem o script que o computa, não é o core)"
    return 1
  fi
  # o corte do espaço final (que inclui o \r) nos DOIS: um checkout em CRLF (core.autocrlf) não pode virar
  # "computa source, não source" (achado da passada adversarial de 2026-10-21)
  defaults="$(LC_ALL=C grep -E '^role=' "${ovs}" | sed -E 's/^role=//; s/[[:space:]]*#.*$//; s/["'\'']//g; s/[[:space:]]*$//' | LC_ALL=C sort -u)"
  outs="$(LC_ALL=C grep -E '^role:[[:space:]]' "${ovs}" | sed -E 's/^role:[[:space:]]*//; s/[[:space:]]*$//' | LC_ALL=C sort -u)"
  if [ -z "${outs}" ]; then
    echo "o onion-version.sh dele não emite a linha role: (não sei ler o papel sem executá-lo)"
    return 1
  fi
  while IFS= read -r o; do
    case "${o}" in
      source) : ;;
      '${role}'|'$role')
        if [ -z "${defaults}" ]; then
          echo "o onion-version.sh dele emite role: \${role} sem default no nível do arquivo"
          return 1
        fi
        while IFS= read -r d; do
          if [ "${d}" != "source" ]; then echo "o onion-version.sh dele computa role: ${d}, não source"; return 1; fi
        done <<< "${defaults}" ;;
      *) echo "o onion-version.sh dele diz role: ${o}, não source"; return 1 ;;
    esac
  done <<< "${outs}"
  return 0
}

T_STAMP="${TARGET}/.claude/.onion-version"
if [ -n "${VENDOR_AUTH}" ]; then
  T_LABEL="UPSTREAM DO VENDOR ${VENDOR_NAME}"
elif [ -n "${VENDOR_OWNER_NO_BOX}" ]; then
  # O destino PROVOU ser o dono de um vendor e não tem caixa. Sem esta recusa, um dono sem carimbo do Onion
  # (o espelho público, por exemplo) cairia em "sem carimbo = o core" abaixo, e o carteiro criaria a caixa lá.
  echo "ERRO: o destino '${TARGET}' é o dono de ${VENDOR_OWNER_NO_BOX} (a tag do carimbo confere), mas não tem docs/evolution/inbox/ — o carteiro não abre caixa no repo alheio; o dono cria a dele, ou o sinal vai pelo core." >&2
  exit 2
elif [ -f "${T_STAMP}" ]; then
  T_ROLE="$(role_field "${T_STAMP}")"
  if [ "${T_ROLE}" != "hub" ]; then
    echo "ERRO: o destino '${TARGET}' tem carimbo role='${T_ROLE:-vazio}' — não é o core nem um hub. Upstream é o core ou o seu hub; relayar para outro adotante é canal lateral." >&2
    [ ! -d "${REPO_ROOT}/vendor" ] || echo "      Upstream de VENDOR: nenhum carimbo vendor/<x>/.<x>-version deste repo tem a origem provada no destino (a árvore da tag do carimbo, lá, reproduz os sha256 dele).${VENDOR_REFUSALS:+ ${VENDOR_REFUSALS}}" >&2
    exit 2
  fi
  if [ "${ROLE}" != "adopted" ]; then
    echo "ERRO: o destino é um hub, e este repo tem carimbo role='${ROLE}'. Só o filho de um hub (carimbo adopted) relaya para o hub; ${ROLE} fala com o core." >&2
    exit 2
  fi
  SRC_FROM="$(grep -E '^[[:space:]]*adopted_from:' "${STAMP}" 2>/dev/null | head -1 | sed -E 's/^[[:space:]]*adopted_from:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//; s/"//g; s/'\''//g')"
  HUB_REMOTE="$(git -C "${TARGET}" remote get-url origin 2>/dev/null || true)"
  if [ -z "${SRC_FROM}" ] || { [ "${SRC_FROM%/}" != "${TARGET}" ] && { [ -z "${HUB_REMOTE}" ] || [ "$(_norm_remote "${SRC_FROM}")" != "$(_norm_remote "${HUB_REMOTE}")" ]; }; }; then
    echo "ERRO: o destino é um hub, mas este repo não o adota: adopted_from='${SRC_FROM:-ausente}' não é o remote nem o caminho do hub (${HUB_REMOTE:-sem origin}). Quem adota o core relaya para o core; relayar para um hub que não é o seu é canal lateral." >&2
    exit 2
  fi
  T_LABEL="HUB"
else
  # Sem carimbo, o destino ainda não provou nada: a falta de carimbo é também a de todo repo git que não
  # é do Onion (Q_CO_RELAY_SEM_CARIMBO_E_O_CORE, medido em 2026-10-20: um clone defasado do espelho do
  # kg-ssot, sem carimbo e sem docs/evolution/, passava em --dry-run como o core, e a entrega abriria a
  # caixa lá). O core não tem carimbo estático: ele o COMPUTA pelo .claude/validation/onion-version.sh,
  # que, sem o carimbo, devolve role: source. É essa a prova exigida.
  if ! CORE_WHY="$(_core_proof "${TARGET}")"; then
    echo "ERRO: o destino '${TARGET}' não tem carimbo .claude/.onion-version e não prova ser o core: ${CORE_WHY}." >&2
    echo "      Upstream é o core (o onion-version.sh dele diz role: source), o seu hub (carimbo role: hub) ou o dono provado de um vendor." >&2
    [ -z "${VENDOR_REFUSALS}" ] || echo "      Upstream de VENDOR não provado: ${VENDOR_REFUSALS}" >&2
    exit 2
  fi
  T_LABEL="CORE"
fi

# --- Resolve a fonte do(s) sinal(is) ---
[ -n "${FROM_DIR}" ] || FROM_DIR="${REPO_ROOT}/docs/evolution/inbox"

FILES=()
if [ -n "${SIGNAL_ARG}" ]; then
  if [ -f "${SIGNAL_ARG}" ]; then FILES+=("${SIGNAL_ARG}")
  elif [ -f "${FROM_DIR}/${SIGNAL_ARG}" ]; then FILES+=("${FROM_DIR}/${SIGNAL_ARG}")
  else echo "ERRO: signal-file não encontrado: '${SIGNAL_ARG}' (nem em ${FROM_DIR}/)." >&2; exit 2; fi
else
  [ -d "${FROM_DIR}" ] || { echo "ERRO: fonte de sinais não existe: ${FROM_DIR}" >&2; exit 2; }
  while IFS= read -r f; do FILES+=("$f"); done < <(find "${FROM_DIR}" -maxdepth 1 -type f -name '*.md' ! -iname 'readme.md' 2>/dev/null | sort)
  [ "${#FILES[@]}" -gt 0 ] || { echo "ERRO: ${FROM_DIR}/ não tem sinais a relayar (1º nível)." >&2; exit 2; }
fi
ORIGS=("${FILES[@]}")   # o sinal como o autor escreveu (no canal de vendor, FILES passa a ser a cópia com rodapé)

DEST_DIR="${TARGET}/docs/evolution/inbox"

# --- Aviso honesto: o core pode não ter o canal nesta árvore (branch atual) ---
if [ ! -d "${TARGET}/docs/evolution" ]; then
  echo "AVISO: ${TARGET} não tem docs/evolution/ nesta árvore (branch atual)." >&2
  echo "       A entrega cria inbox/ como untracked; o 📬 dispara se o core tiver" >&2
  echo "       o hook co-evolution-inbox-check.sh provisionado." >&2
fi

if [ "${DRY}" -eq 1 ]; then
  echo "── DRY-RUN — Carteiro-local upstream (nada escrito) ──"
  echo "  fonte    : ${FROM_DIR}/"
  echo "  alvo     : ${TARGET}  (${T_LABEL})"
  echo "  destino  : ${DEST_DIR}/"
  [ -z "${VENDOR_AUTH}" ] || echo "  autoriza : ${VENDOR_AUTH} (a tag ${VENDOR_TAG} do destino reproduz os ${VENDOR_NFILES} arquivos do carimbo)"
  for f in "${FILES[@]}"; do echo "  relayar  : $(basename "$f")"; done
  exit 0
fi

# --- Canal de vendor: a autorização VIAJA no sinal entregue ---------------------------------------------------
# O dono do vendor recebe de um repo que não é o core nem o seu filho; sem dizer por que a entrega passou, a
# sessão de lá não tem como conferir o canal. O rodapé é determinístico (sem data), então o dedup por conteúdo
# continua valendo: a mesma entrega, de novo, é byte-idêntica ao que já está no inbox/ ou no _processed/ de lá.
if [ -n "${VENDOR_AUTH}" ]; then
  STAGE="$(mktemp -d)" || { echo "ERRO: mktemp falhou." >&2; exit 2; }
  trap 'rm -rf "${STAGE}"' EXIT
  # normalizado: a URL crua do origin pode trazer `usuário:token@`, e o sinal vai para o repo alheio, que o commita
  SENDER="$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || true)"
  SENDER="$([ -n "${SENDER}" ] && _norm_remote "${SENDER}" || basename "${REPO_ROOT}")"
  STAGED=()
  for f in "${FILES[@]}"; do
    out="${STAGE}/$(basename "$f")"
    {
      cat "$f"
      # >>> rodape-vendor
      printf '\n---\n\n<!-- co-relay: canal upstream de vendor -->\n'
      printf '> 📨 **Canal upstream de vendor** (co-relay, D_CANAL_UPSTREAM_POR_VENDOR): entregue por `%s`, cujo carimbo\n' "${SENDER}"
      printf '> `%s` vendoriza a tag `%s`: a árvore dessa tag aqui reproduz os %s arquivos do carimbo (sha256).\n' "${VENDOR_AUTH}" "${VENDOR_TAG}" "${VENDOR_NFILES}"
      # <<< rodape-vendor
    } > "${out}"
    STAGED+=("${out}")
  done
  FILES=("${STAGED[@]}")
fi

# Mesmo sinal = mesmo CORPO. No canal de vendor o rodapé muda quando o vendor sobe de tag ou o origin do
# remetente muda; comparar o arquivo inteiro faria voltar um sinal já triado (o 📬 fantasma de 2026-07-03).
_strip_vendor_footer() {
  local n; n="$(grep -n -m1 -F '<!-- co-relay: canal upstream de vendor -->' "$1" 2>/dev/null | cut -d: -f1)"
  if [ -n "${n}" ] && [ "${n}" -ge 4 ]; then head -n "$((n - 4))" "$1"; else cat "$1"; fi
}
_same_signal() {  # $1 = entrega, $2 = original, $3 = arquivo já no destino
  cmp -s "$1" "$3" && return 0
  [ -n "${VENDOR_AUTH}" ] || return 1
  cmp -s "$2" <(_strip_vendor_footer "$3")
}

mkdir -p "${DEST_DIR}" 2>/dev/null || { echo "ERRO: não foi possível criar ${DEST_DIR} (permissão?)." >&2; exit 2; }

relayed=0 ; skipped=0
for i in "${!FILES[@]}"; do
  f="${FILES[$i]}"; orig="${ORIGS[$i]}"
  base="$(basename "$f")"
  # COLISÃO DE NOME decide por CONTEÚDO, não pela existência (sinal de um adotante, 2026-10-07):
  # esta checagem saía "já relayado" ANTES do dedup abaixo, e a versão atualizada de um sinal nunca
  # chegava (medido: `cmp` diferiu no byte 2871 e o carteiro calou) — o contrário do que o cabeçalho
  # promete. Idêntico → no-op. Diferente e o destino UNTRACKED (o core ainda não triou) → entrega por
  # cima: é a mesma entrega-sem-commit, atualizada. Diferente e o destino TRACKED → o core já commitou
  # aquela versão; sobrescrever mexeria na árvore dele (I3), então recusa e diz como seguir.
  if [ -e "${DEST_DIR}/${base}" ]; then
    if _same_signal "$f" "${orig}" "${DEST_DIR}/${base}"; then
      echo "Onion: já relayado, conteúdo idêntico (no-op): ${base}" >&2
      skipped=$((skipped + 1))
      continue
    fi
    if git -C "${TARGET}" ls-files --error-unmatch "docs/evolution/inbox/${base}" >/dev/null 2>&1; then
      echo "AVISO: ${base} mudou, mas o destino (${T_LABEL}) JÁ COMMITOU a versão anterior — não sobrescrevo a árvore dele. Entregue a atualização com nome novo (ex.: ${base%.md}-v2.md)." >&2
      skipped=$((skipped + 1))
      continue
    fi
    if cp "$f" "${DEST_DIR}/${base}" 2>/dev/null; then
      echo "Onion: 📬 ATUALIZADO (o destino era a entrega anterior, ainda não triada) → ${TARGET}/docs/evolution/inbox/${base}" >&2
      relayed=$((relayed + 1))
    else
      echo "AVISO: falha ao atualizar ${base} em ${DEST_DIR} (permissão?)." >&2
    fi
    continue
  fi
  # Dedup por CONTEÚDO vs inbox/ E _processed/ do core — cura da corrida do assíncrono
  # (incidente 2026-07-03: 3 sinais re-entregues pelo carteiro depois de o core já tê-los
  # triado por outro caminho → 📬 fantasma a cada boot). Byte-idêntico = já entregue/
  # processado → no-op. Mesmo NOME com conteúdo DIFERENTE segue entregando: é sinal
  # ATUALIZADO (nova rodada), não duplicata.
  dup=""
  for existing in "${DEST_DIR}"/*.md "${DEST_DIR}/_processed"/*.md; do
    [ -f "${existing}" ] || continue
    if _same_signal "$f" "${orig}" "${existing}"; then dup="${existing}"; break; fi
  done
  if [ -n "${dup}" ]; then
    echo "Onion: já entregue/processado no destino (conteúdo idêntico a $(basename "${dup}")) — no-op: ${base}" >&2
    skipped=$((skipped + 1))
    continue
  fi
  if cp "$f" "${DEST_DIR}/${base}" 2>/dev/null; then
    echo "Onion: 📬 relayado → ${TARGET}/docs/evolution/inbox/${base}" >&2
    relayed=$((relayed + 1))
  else
    echo "AVISO: falha ao copiar ${base} para ${DEST_DIR} (permissão?)." >&2
  fi
done

echo "Onion: Carteiro-local upstream concluído — ${relayed} relayado(s), ${skipped} no-op." >&2
echo "       Próximo (sessão do destino, ${T_LABEL}): ler 📬, commitar + triar (git mv p/ inbox/_processed/)." >&2
echo "       (entrega-sem-commit: o adotante NÃO commitou no repo alheio — invariante I3)." >&2
exit 0
