#!/usr/bin/env bash
# =============================================================================
# ops-citation-travel-check.sh — REGRA 100: superfície que VIAJA não cita `ops/<arquivo>` como se o
# destinatário o tivesse (com catraca)
#
# O QUE   : `ops/` é a oficina do core. NÃO viaja para nenhuma porta (source, hub, standalone,
#           plugins, mini) nem para adotante — o manifesto de transporte
#           (.claude/utils/adopt/vendor-manifest.sh) nunca o inclui. Um arquivo que viaja e cita
#           `ops/<arquivo>` descreve ao destinatário um comportamento que ele não tem.
#
# DEFEITO DATADO (SAC-86, medido em 2026-10-09 na materialização do onion-standalone, pin 947e69ce):
#           a lente `.claude/rules/kg-grammar.md` (linha da provenance, SAC-80) afirmava que o
#           `ops/pr-merge-verified.sh` recusa o rebase e pede `--merge-commit`. A lente carrega
#           SOZINHA no adotante ao tocar um .kg.yaml — e lá o script não existe. A classe já estava
#           publicada antes em `pretooluse-merge-gate.sh` e `onion-orchestration/SKILL.md`. Nenhuma
#           guarda via: a checagem de ponteiro morto não cobre `ops/`, e a REGRA 22/48 olham outros
#           prefixos. Na varredura desta forja (2026-10-11): 203 citações nas raízes que viajam.
#
# 2º VOCABULÁRIO (sinal de campo 2026-10-19, num hub, pin 59ebe7fe1288): o corte de 2026-10-18
#           tirou o `/meta:publish` da adoção, e cinco superfícies que viajam seguiam a citá-lo
#           (`cc-update.md`, `create-vertical.md`, três comentários/mensagens de script). A guarda não
#           via porque o vocabulário dela era SÓ `ops/<arquivo>`, e `/meta:publish` é a face de COMANDO do
#           `ops/publish-door.sh`: a mesma classe sem o token. Agora ela casa também o comando core-only
#           que a adoção corta, derivado de `vendor-manifest.sh --retired-excludes` (cada
#           `.claude/commands/<cat>/<nome>.md` vira `/<cat>:<nome>`), com as MESMAS três declarações.
#           Medido no dia: 19 citações sem declaração em 10 arquivos; todas declaradas no mesmo PR
#           (baseline intocado). TETO: a SKILL cortada (`onion-publish`) não entra — nome de skill não
#           tem forma de invocação que se distinga de prosa, e acusá-lo seria falso positivo.
#
# 3º VOCABULÁRIO (2026-10-20, D_U1_MIGRADOR_NO_KG_SSOT): o `kg-migrate-v3.py` saiu da adoção, e oito linhas que
#           viajam mandavam o adotante rodá-lo — uma delas a DICA impressa pelo `kg-contract-check.sh` a todo grafo
#           com `locality` fora do vocabulário. Mesma classe, sem `ops/` nem `/cmd:`: o SCRIPT core-only cortado.
#           Cada `.py`/`.sh` de `--retired-excludes` fora de `commands/` vira o token do NOME do arquivo (com ou sem
#           o caminho antes), com as MESMAS três declarações. A planta (`vendor-manifest.sh`) não é varrida para
#           ele: cita o nome como DADO do transporte (a mesma razão do `_is_anchor` dela).
#
# A DECISÃO QUE A GUARDA NÃO TOMA SOZINHA — e por que a catraca existe:
#   "a citação descreve o destinatário?" é JUÍZO. Um script não sabe. O que ele sabe fazer é obrigar o
#   autor a DECIDIR na hora de escrever, e deixar a decisão visível. Por isso a regra é: citação de
#   `ops/<arquivo>` num arquivo que viaja é ACUSADA, a menos que se declare. As três declarações:
#     (a) MARCADOR DE LINHA `(core-only)` na MESMA linha — a convenção que esta casa já usa para citar
#         artefato que o destinatário não tem (54 usos em 2026-10-11; é também o que o passo (4) do
#         ops/materialize-door.sh (core-only) pede para documento privado nomeado);
#     (b) TESTE DE PRESENÇA na mesma linha (`[ -f …/ops/x.sh ]`, `-x`, `-e`, `-d`, `-s`) — o código
#         que pergunta se o arquivo existe antes de usá-lo é a forma honesta, não um ponteiro;
#     (c) ARQUIVO QUE SE DECLARA CORE-ONLY no frontmatter (`description:` com "Core-only", a convenção
#         de /meta:publish, /meta:forge, /meta:cc-update…): o arquivo inteiro descreve o core, e ele
#         diz isso no lugar que o destinatário lê primeiro. Exigir o marcador linha a linha ali seria
#         falso positivo — e falso positivo treina a sessão a ignorar o veto.
#   O passivo (citações de antes da guarda) vai para o BASELINE e é TOLERADO (SOFT); citação NOVA fora
#   dele é HARD; o baseline SÓ ENCOLHE (acrescentar linha é HARD, vs origin/<integração>).
#
# FORA DO ESCOPO, de propósito (cada um é TETO declarado, não esquecimento):
#   · lint-selftest.sh e fixtures/ — a bancada EXECUTA o que cita, em sandbox; se `ops/` faltar, o caso
#     falha alto ou pula declarado. Não é prosa que informa mal o destinatário.
#   · *-baseline.txt — dado de catraca, não descrição.
#   · este próprio arquivo — o selftest planta citações de propósito.
#   · `ops/s` (unidade "operações por segundo") e `ops/<palavra>` sem extensão nem subdiretório — a
#     forma exigida é `ops/<nome>.<ext>` ou `ops/<dir>/…`, que é como um arquivo se escreve.
#
# TETO: a guarda vê a FORMA (`ops/<arquivo>` sem declaração), não o SENTIDO. Ela não distingue uma
#   citação que descreve o destinatário de uma que descreve o core sem se marcar — por isso acusa as
#   duas e pede a declaração. E não vê comportamento do core citado SEM o caminho (ex.: "o script de
#   merge verificado recusa…"): a classe sem o token `ops/` passa.
#   Declarados pela passada adversarial de 2026-10-11 (sem cura mecânica, por custo ou por calar):
#   · árvore genérica de projeto em bloco cercado (`└── ops/deploy.sh`) ACUSA — marque a linha;
#   · `.yaml` não tem isenção de arquivo (só .md tem frontmatter): marque a linha;
#   · o marcador `(core-only)` cala a LINHA inteira, inclusive um 2º token nela;
#   · variável de raiz é LISTA FECHADA (R, root, REPO_ROOT, CLAUDE_PROJECT_DIR…): `${outra}/ops/x.sh`
#     cala — erra para calar; `$HOME/ops/x.sh` também cala por isso;
#   · em CÓDIGO, o teste de presença guarda o token no arquivo inteiro, inclusive um `echo` de prosa nele;
#   · `$(…)/ops/x.sh` conta como raiz (é a forma de `$(git rev-parse …)/ops/`), e um `$(mktemp -d)/ops/`
#     acusa — marque a linha;
#   · hook sem extensão não é varrido (não há nenhum hoje);
#   · `--base-ref` cuja ref não tem o baseline deixa a catraca sem referência, e no PR que cria a guarda
#     a catraca compara com o próprio HEAD (bootstrap).
#
# Uso    : ops-citation-travel-check.sh [REPO_DIR] [--format text|tsv] [--summary]
#          ops-citation-travel-check.sh [REPO_DIR] --emit-baseline > <baseline>
#          ops-citation-travel-check.sh --selftest
# Baseline default: <repo>/.claude/validation/ops-citation-travel-baseline.txt
# Exit   : 0 = sem HARD · 1 = ao menos uma HARD · 2 = uso.
# =============================================================================
set -uo pipefail

FORMAT="text"; SUMMARY=0; EMIT_BASELINE=0; SELFTEST=0; BASELINE=""; PREV_BASELINE=""; BASE_REF=""
REPO_DIR=""
SELF_NAME="ops-citation-travel-check.sh"

# AS RAÍZES QUE VIAJAM — derivadas do TRANSPORTE (SSOT: vendor-manifest.sh --emit-scrub-roots, que ignora
# o papel de propósito: varrer mais do que viaja nunca é fail-open; varrer menos é). Fallback explícito
# e nunca vazio: lista vazia zeraria a guarda em silêncio.
VENDORED_ROOTS=()
_VM="$(cd "$(dirname "${BASH_SOURCE[0]}")/../utils/adopt" 2>/dev/null && pwd)/vendor-manifest.sh"
if [ -f "${_VM}" ]; then
  while IFS= read -r _r; do [ -n "${_r}" ] && VENDORED_ROOTS+=("${_r}"); done < <(bash "${_VM}" --emit-scrub-roots 2>/dev/null || true)
fi
if [ "${#VENDORED_ROOTS[@]}" -eq 0 ]; then
  echo "AVISO: vendor-manifest.sh nao respondeu — usando a lista de fallback (pode estar defasada)" >&2
  VENDORED_ROOTS=(.claude/agents .claude/commands .claude/skills .claude/utils .claude/validation
                  .claude/hooks .claude/rules .claude/workflows docs/meta-specs docs/knowledge-base docs/sdaal)
fi

# O 2º VOCABULÁRIO — o COMANDO core-only que a adoção corta (sinal de campo 2026-10-19, num hub,
# pin 59ebe7fe1288: o /meta:publish saiu do hub e cinco superfícies que viajam seguiam a citá-lo; a guarda
# não via porque só casava `ops/<arquivo>`, e `/meta:publish` é a face de comando do ops/publish-door.sh).
# SSOT: `vendor-manifest.sh --retired-excludes` (o que o core deixou de mandar à adoção). Cada
# `.claude/commands/<cat>/<nome>.md` dali vira o token `/<cat>:<nome>` (e a grafia `/<cat>/<nome>`); os
# próprios arquivos cortados não são varridos para ESTE vocabulário (são a superfície do comando, e na porta
# source ele existe). Fallback explícito, nunca vazio, pelo mesmo motivo das raízes.
CUT_CMDS=(); CUT_PATHS=(); CUT_FILES=()
if [ -f "${_VM}" ]; then
  while IFS= read -r _x; do
    _x="${_x#:(exclude)}"; [ -n "${_x}" ] || continue
    CUT_PATHS+=("${_x}")
    # 3º vocabulário: o script core-only cortado (nome do arquivo; o `.` vira classe para a regex do awk)
    #   Cada metacaractere de ERE vira classe de um caractere (`.` → `[.]`); nome com `[ ] ^ \` fica de fora,
    #   DITO em stderr (não há classe honesta para eles e a regex quebraria a guarda inteira).
    case "${_x}" in .claude/commands/*) : ;; *.py|*.sh)
      _fb="${_x##*/}"
      case "${_fb}" in *[]\[^\\]*) echo "AVISO: '${_fb}' tem metacaractere sem escape seguro — fora do 3º vocabulário" >&2 ;;
        *) _fe=""; _i=0
           while [ "${_i}" -lt "${#_fb}" ]; do _ch="${_fb:${_i}:1}"
             case "${_ch}" in [.+?\(\)\{\}\|*\$]) _fe="${_fe}[${_ch}]" ;; *) _fe="${_fe}${_ch}" ;; esac; _i=$((_i+1)); done
           CUT_FILES+=("${_fe}") ;;
      esac ;;
    esac
    _c="${_x#.claude/commands/}"
    if [ "${_c}" != "${_x}" ] && [[ "${_c}" == */*.md ]] && [[ "${_c}" != */*/* ]]; then
      _c="${_c%.md}"; CUT_CMDS+=("${_c%%/*}[:/]${_c#*/}")
    fi
  done < <(bash "${_VM}" --retired-excludes 2>/dev/null || true)
fi
_VM_SAID="${#CUT_PATHS[@]}"   # o manifesto respondeu algo? (o fallback dos scripts só vale se NÃO respondeu)
if [ "${#CUT_CMDS[@]}" -eq 0 ]; then
  # ⚠️ Só o comando e a skill, NUNCA a lente e a doutrina por nome: o derivador de companheiros do
  # vendor-manifest.sh mantém viva a peça que um arquivo que viaja cita pelo nome, e este fallback a
  # citava (r14 do publish_release no CI do PR 1221: a doutrina voltou ao standalone). Sem elas, o
  # fallback acusa um pouco mais (a lente e a doutrina citam o comando), o lado seguro.
  CUT_CMDS=("meta[:/]publish"); CUT_PATHS=(.claude/commands/meta/publish.md .claude/skills/onion-publish .claude/utils/kg/kg-migrate-v3.py)
  [ "${_VM_SAID}" -gt 0 ] || CUT_FILES=("kg-migrate-v3[.]py")
fi
_CMDRE="$(IFS='|'; printf '%s' "${CUT_CMDS[*]}")"
_CUTP="$(IFS='|'; printf '%s' "${CUT_PATHS[*]}")"
_FILERE="$(IFS='|'; printf '%s' "${CUT_FILES[*]:-}")"

# Extrai "<rel>|<ops/token>" — UMA LINHA POR OCORRÊNCIA (a contagem por par alimenta a catraca) — de cada
# citação NÃO declarada nas raízes que viajam.
#
# AS FORMAS, curadas pela passada adversarial de 2026-10-11 (achados 1–4, 6, 7, 10–12):
#   · o token é `ops/` do CORE só no início de palavra, ou depois de uma variável de RAIZ (`${R}/ops/`,
#     `$root/ops/`, `$(…)/ops/`). Depois de segmento literal (`src/ops/x.ts`, URL, `./ops/`) é o `ops/` de
#     OUTRO projeto, e depois de variável de sandbox (`${tmp}/ops/`) é fixture de selftest: calam;
#   · nome e extensão começam com letra, e o diretório tem 2+ caracteres (`ops/s/…`, `ops/1.5`, `ops/v1.2` calam);
#   · o teste de presença (`-f -e -x -d -s -r -L`) guarda o TOKEN TESTADO — em CÓDIGO no arquivo inteiro,
#     inclusive pela variável que o recebe (`P="$R/ops/a.sh"` … `[ -f "$P" ]`); em PROSA só na mesma linha.
#     Nunca a linha toda: `[ -f ops/a.sh ] && bash ops/b.sh` acusa o b;
#   · marcador `(core-only)` aceita a caixa e o complemento (`(Core-only)`, `(core only)`, `(core-only, …)`);
#   · frontmatter isenta só se FECHA e se o `description:` declara `Core-only` (`.`, `,` ou `)`) sem negação;
#     CRLF e BOM não escondem o `---`.
collect_violations() { # <repo_dir>
  local repo="$1" r bases=()
  for r in "${VENDORED_ROOTS[@]}"; do [ -d "${repo}/${r}" ] && bases+=("${repo}/${r}"); done
  [ "${#bases[@]}" -gt 0 ] || return 0
  find "${bases[@]}" -type f \
       \( -name '*.md' -o -name '*.sh' -o -name '*.yaml' -o -name '*.yml' -o -name '*.json' \
          -o -name '*.py' -o -name '*.js' -o -name '*.mjs' -o -name '*.ts' -o -name '*.tpl' \
          -o -name '*.txt' -o -name '*.toml' \) \
       ! -name '*baseline.txt' ! -name 'lint-selftest.sh' ! -name "${SELF_NAME}" \
       ! -path '*/fixtures/*' -print0 2>/dev/null \
  | xargs -0 -r awk -v prefix="${repo}/" -v cmdre="${_CMDRE}" -v cutp="${_CUTP}" -v filere="${_FILERE}" '
      function flush(   i) {
        if (rel != "" && !(fmcore && fmclosed)) for (i = 1; i <= nc; i++) if (!(cand[i] in gtok) || (i in cmsg)) print rel "|" cand[i]
        nc = 0; split("", cand); split("", cmsg); split("", gtok); split("", vtok)
      }
      # a variável que precede `/ops/` é de RAIZ? (lista fechada: na dúvida a guarda CALA)
      function rootvar(s) {
        return (s ~ /(\$\{|\$)(R|root|ROOT|repo|REPO|_repo|REPO_ROOT|repo_root|CORE|core|CORE_ROOT|top|TOP|CLAUDE_PROJECT_DIR|PROJECT_DIR)\}?$/ || s ~ /\)$/)
      }
      # extrai os tokens de ops/ do CORE de uma linha; devolve em toks[1..n]
      function tokens(s,   n, off, pre, c, t, nx, p) {
        n = 0; off = 0; split("", toks)
        while (match(substr(s, off + 1), /ops\/([A-Za-z][A-Za-z0-9_-]*\.[A-Za-z][A-Za-z0-9]*|[A-Za-z][A-Za-z0-9_-]+\/[A-Za-z0-9_.*-]*)/)) {
          t = substr(s, off + RSTART, RLENGTH); pre = substr(s, 1, off + RSTART - 1); off = off + RSTART + RLENGTH - 1
          c = substr(pre, length(pre), 1)
          if (c ~ /[A-Za-z0-9_.@-]/) continue                       # devops/, gitops/, foo.ops/
          if (c == "/" && !rootvar(substr(pre, 1, length(pre) - 1))) continue   # src/ops/, URL, ./ops/, ${tmp}/ops/
          sub(/[.*]+$/, "", t); toks[++n] = t
        }
        # 2º vocabulário: o comando core-only cortado da adoção (`/meta:publish`, `/meta/publish`). Cala no
        # caminho (`commands/meta/publish.md`: há caractere de palavra ou `/` antes) e no nome mais longo
        # (`/meta:publish-x`). O token sai normalizado com `:` para a catraca contar as duas grafias juntas.
        if (cmdre != "" && !cutfile) {
          off = 0
          while (match(substr(s, off + 1), "/(" cmdre ")")) {
            t = substr(s, off + RSTART, RLENGTH); pre = substr(s, 1, off + RSTART - 1)
            nx = substr(s, off + RSTART + RLENGTH, 1); off = off + RSTART + RLENGTH - 1
            c = substr(pre, length(pre), 1)
            if (c ~ /[A-Za-z0-9_.\/-]/ || nx ~ /[A-Za-z0-9_-]/) continue
            p = index(substr(t, 2), "/"); if (p > 0) t = substr(t, 1, p) ":" substr(t, p + 2)
            toks[++n] = t
          }
        }
        # 3º vocabulário: o script core-only cortado, pelo NOME (`kg-migrate-v3.py`, com ou sem caminho antes). Cala
        # no nome mais longo dos dois lados (`x-kg-migrate-v3.py`, `kg-migrate-v3.pyc`); a planta não é varrida.
        if (filere != "" && !cutfile && !plant) {
          off = 0
          while (match(substr(s, off + 1), "(" filere ")")) {
            t = substr(s, off + RSTART, RLENGTH); pre = substr(s, 1, off + RSTART - 1)
            nx = substr(s, off + RSTART + RLENGTH, 1); off = off + RSTART + RLENGTH - 1
            c = substr(pre, length(pre), 1)
            if (c ~ /[A-Za-z0-9_.-]/ || nx ~ /[A-Za-z0-9_-]/) continue
            toks[++n] = t
          }
        }
        return n
      }
      FNR == 1 { flush(); rel = FILENAME; if (index(rel, prefix) == 1) rel = substr(rel, length(prefix) + 1)
                 cutfile = 0; ncp = split(cutp, cps, "|")
                 for (i = 1; i <= ncp; i++) if (cps[i] != "" && (rel == cps[i] || index(rel, cps[i] "/") == 1)) cutfile = 1
                 plant = (rel == ".claude/utils/adopt/vendor-manifest.sh")
                 fm = 0; isfm = 0; fmclosed = 0; fmcore = 0; indesc = 0; inpaths = 0
                 code = (FILENAME ~ /\.(sh|py|js|mjs|ts)$/); srconly = 0; indoc = 0 }
      { l = $0; sub(/\r$/, "", l); if (FNR == 1) sub(/^\357\273\277/, "", l) }
      FNR == 1 && l == "---" && FILENAME ~ /\.md$/ { fm = 1; isfm = 1; next }
      fm == 1  { if (l == "---") { fm = 0; fmclosed = 1; next }
                 if (l ~ /^description:/) indesc = 1; else if (l ~ /^[A-Za-z_][A-Za-z0-9_-]*:/) indesc = 0
                 if (l ~ /^paths:/) inpaths = 1; else if (l ~ /^[A-Za-z_][A-Za-z0-9_-]*:/) inpaths = 0
                 if (inpaths) next   # paths: da rule é GATILHO de carga (só casa onde o arquivo existe), não descrição
                 if (indesc && l ~ /[Cc]ore-only[.,)]/ && l !~ /(NÃO|Não|não|NAO|Nao|nao|NOT|Not|not)[^.]*[Cc]ore-only/) fmcore = 1 }
      # (as linhas do frontmatter também são varridas: citação ali, num arquivo que não se declara, acusa;
      #  e frontmatter que nunca fecha não isenta nada — a isenção só vale com o `---` de fechamento)
      l ~ /\([Cc]ore[- ]only[),;[:space:]]/ { next }
      # MENSAGEM DE GUARDA (SAC-149, 2026-10-15): o teste de presença NO ARQUIVO não isenta o ops/ que uma
      # `violation "…"` IMPRIME — a mensagem chega ao adotante sem o teste que a protegia (a da REGRA 85
      # mandava rodar ops/publish-door.sh num adotante comum). Isenta só a regra declarada `# aplica-se: source`:
      # ela não roda fora do core, então a mensagem dela só é lida onde o ops/ existe.
      code && l ~ /^# REGRA [0-9]+ / { srconly = 0; indoc = 1 }
      code && indoc && l ~ /^[a-z_][a-z0-9_]*\(\)[[:space:]]*\{/ { indoc = 0 }
      code && indoc && l ~ /^# aplica-se:[[:space:]]*source[[:space:]]*$/ { srconly = 1 }
      code && l ~ /violation[[:space:]]+"/ && srconly { next }
      { n = tokens(l)
        # atribuição a variável: P="$R/ops/a.sh" → vtok[P]
        if (n > 0 && match(l, /^[[:space:]]*(local[[:space:]]+|export[[:space:]]+|readonly[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=/)) {
          v = substr(l, RSTART, RLENGTH - 1); sub(/^[[:space:]]*(local|export|readonly)?[[:space:]]*/, "", v); vtok[v] = toks[1]
        }
        # teste de presença: guarda o OPERANDO testado (token literal ou variável que o recebeu)
        #   ⚠️ em CÓDIGO o token testado fica guardado no arquivo inteiro (o uso vem depois do teste); em
        #   PROSA só na mesma linha — senão um bloco de exemplo com `[ -f ops/x.sh ]` calaria a frase do
        #   SAC-86 dez linhas acima (falso negativo do defeito verbatim, 2ª passada adversarial).
        s = l; split("", lg)
        while (match(s, /(\[\[?|test)[[:space:]]+(![[:space:]]+)?-[efxsdrL][[:space:]]+[^] ]+/)) {
          op = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
          sub(/^.*-[efxsdrL][[:space:]]+/, "", op); gsub(/"/, "", op)
          if (tokens(op) > 0) lg[toks[1]] = 1
          else if (op ~ /^\$\{?[A-Za-z_][A-Za-z0-9_]*\}?$/) { gsub(/[${}]/, "", op); if (op in vtok) lg[vtok[op]] = 1 }
        }
        for (t in lg) if (code) gtok[t] = 1
        n = tokens(l)
        msg = (code && l ~ /violation[[:space:]]+"/)
        for (i = 1; i <= n; i++) if (!(toks[i] in lg)) { cand[++nc] = toks[i]; if (msg) cmsg[nc] = 1 }
      }
      END { flush() }' 2>/dev/null | LC_ALL=C sort
}

# ---------------------------------------------------------------------------
# SELFTEST (self-contido, à la kb-vendored-link-check.sh) — as polaridades
# ---------------------------------------------------------------------------
run_selftest() {
  local tmp; tmp="$(mktemp -d)"; local fails=0 out total=25
  mkdir -p "${tmp}/.claude/rules" "${tmp}/.claude/hooks" "${tmp}/.claude/validation/fixtures" \
           "${tmp}/.claude/commands/meta" "${tmp}/docs/sdaal" "${tmp}/ops" "${tmp}/docs/evolution/notas"
  local BL="${tmp}/.claude/validation/ops-citation-travel-baseline.txt"
  # captura em VAR e here-string — nunca `produtor | grep -q` (SIGPIPE sob pipefail).
  _run() { out="$(bash "$0" "${tmp}" --format tsv 2>/dev/null)"; }
  _has() { command grep -q -- "$1" <<< "${out}"; }
  _reset() { rm -rf "${tmp}/.claude/rules"/* "${tmp}/.claude/hooks"/* "${tmp}/.claude/commands/meta"/* "${tmp}/.claude/rules"/.??* \
                    "${tmp}/docs/sdaal"/* "${tmp}/docs/evolution/notas"/* "${tmp}/.claude/validation/fixtures"/*
             printf '# baseline vazio\n' > "${BL}"; }

  # (i) o defeito VERBATIM (SAC-86): lente que viaja descreve o ops/ ao destinatário => HARD
  _reset
  printf '| x | y | o rebase reescreve o sha — o `ops/pr-merge-verified.sh` recusa e pede `--merge-commit` (SAC-80) |\n' > "${tmp}/.claude/rules/kg-grammar.md"
  _run
  if _has $'^HARD\tNEW\t.claude/rules/kg-grammar.md'; then echo "  ✅ (i) citação de ops/ em lente que viaja reprova (o defeito verbatim)"; else echo "  ✗ (i)"; fails=$((fails+1)); fi

  # (ii) mesma citação MARCADA (core-only) na linha => cala
  _reset
  printf 'mergeie com merge commit (no core, o `ops/pr-merge-verified.sh` (core-only) recusa o rebase)\n' > "${tmp}/.claude/rules/kg-grammar.md"
  _run
  if _has 'kg-grammar'; then echo "  ✗ (ii) marcador (core-only) deveria calar"; fails=$((fails+1)); else echo "  ✅ (ii) marcador (core-only) na linha cala"; fi

  # (iii) arquivo que NÃO viaja (docs/evolution) => cala. ⚠️ NUNCA um doc NOMEADO de docs/analysis aqui: este
  #       arquivo viaja, e o passo (4) do materialize-door (core-only) aborta a porta por documento privado
  #       nomeado — medido no CI do PR 1017: o caso door (g) parou nesse passo antes do ponto que ele mede.
  _reset
  printf 'rode `bash ops/publish-door.sh --status`\n' > "${tmp}/docs/evolution/notas/nota.md"
  _run
  if _has 'nota.md'; then echo "  ✗ (iii) docs/evolution não viaja, não deveria acusar"; fails=$((fails+1)); else echo "  ✅ (iii) arquivo que não viaja cala"; fi

  # (iv) passivo no baseline => SOFT, sem HARD
  _reset
  printf 'o `ops/pr-merge-verified.sh` recusa\n' > "${tmp}/.claude/rules/kg-grammar.md"
  printf '.claude/rules/kg-grammar.md|ops/pr-merge-verified.sh|1\n' >> "${BL}"
  _run
  if _has '^HARD'; then echo "  ✗ (iv) passivo baselined não deveria dar HARD"; fails=$((fails+1)); else echo "  ✅ (iv) passivo no baseline tolerado (SOFT)"; fi

  # (v) teste de presença na linha (hook honesto) => cala
  _reset
  printf '#!/usr/bin/env bash\n[ -f "${root}/ops/pr-merge-verified.sh" ] || exit 0\n' > "${tmp}/.claude/hooks/gate.sh"
  _run
  if _has 'gate.sh'; then echo "  ✗ (v) teste de presença deveria calar"; fails=$((fails+1)); else echo "  ✅ (v) teste de presença [ -f …ops/… ] cala"; fi

  # (vi) arquivo que se declara Core-only no frontmatter => cala
  _reset
  printf -- '---\nname: publish\ndescription: |\n  Publica uma porta. Core-only.\n---\n\nrode `bash ops/publish-door.sh`\n' > "${tmp}/.claude/commands/meta/publish.md"
  _run
  if _has 'publish.md'; then echo "  ✗ (vi) frontmatter Core-only deveria calar"; fails=$((fails+1)); else echo "  ✅ (vi) arquivo declarado Core-only no frontmatter cala"; fi

  # (vii) `ops/s` (unidade) e fixture de bancada => calam
  _reset
  printf -- '- alto throughput (>1k ops/s por agente); medimos ops/s/core\n' > "${tmp}/docs/sdaal/sdaal.md"
  printf 'bash ops/x.sh\n' > "${tmp}/.claude/validation/fixtures/f.md"
  _run
  if _has 'sdaal.md' || _has 'fixtures'; then echo "  ✗ (vii) ops/s ou fixture não deveriam acusar"; fails=$((fails+1)); else echo "  ✅ (vii) ops/s (unidade) e fixture calam"; fi

  # (viii) CATRACA: baseline que CRESCE vs a versão anterior => HARD
  _reset
  printf 'o `ops/a.sh` faz\n' > "${tmp}/.claude/rules/r.md"
  printf '# scope: %s\n.claude/rules/r.md|ops/a.sh|1\n' "$(_scope_now)" > "${BL}"
  printf '# scope: %s\n' "$(_scope_now)" > "${tmp}/prev.txt"
  out="$(bash "$0" "${tmp}" --format tsv --previous-baseline "${tmp}/prev.txt" 2>/dev/null)"
  if _has $'^HARD\tCATRACA'; then echo "  ✅ (viii) baseline que cresce = CATRACA VIOLADA"; else echo "  ✗ (viii)"; fails=$((fails+1)); fi

  # (ix) sem baseline => HARD acionável, não silêncio
  _reset; rm -f "${BL}"
  printf 'o `ops/a.sh` faz\n' > "${tmp}/.claude/rules/r.md"
  _run
  if _has 'NO-BASELINE'; then echo "  ✅ (ix) baseline ausente = HARD acionável"; else echo "  ✗ (ix)"; fails=$((fails+1)); fi

  # ── casos da passada adversarial de 2026-10-11 (achados 1–4, 6, 9–11) ──
  # (x) o `ops/` de OUTRO projeto (segmento literal antes, URL) e o sandbox de selftest => calam
  _reset
  printf 'handlers vivem em `src/ops/handler.ts`; veja https://github.com/x/y/blob/main/ops/run.md\n' > "${tmp}/.claude/rules/stack.md"
  printf 'printf x > "${tmp}/ops/motor.sh"\n' > "${tmp}/.claude/hooks/st.sh"
  _run
  if _has 'stack.md' || _has 'st.sh'; then echo "  ✗ (x) ops/ de outro projeto ou de sandbox não deveria acusar"; fails=$((fails+1)); else echo "  ✅ (x) src/ops/, URL e \${tmp}/ops/ calam"; fi

  # (xi) teste de presença em OUTRA linha (literal e por variável) => cala; mas guarda só o token TESTADO
  _reset
  printf 'if [ -f "$R/ops/a.sh" ]; then\n  bash "$R/ops/a.sh"\nfi\nP="$R/ops/c.sh"\n[ -f "$P" ] || exit 0\nbash "$P"; echo "$R/ops/c.sh"\n' > "${tmp}/.claude/hooks/h.sh"
  printf '[ -f ops/a.sh ] && bash ops/b.sh\n' > "${tmp}/.claude/hooks/h2.sh"
  _run
  if ! _has $'\th.sh\t' && ! _has 'hooks/h.sh' && _has "h2.sh.*ops/b.sh" && ! _has "h2.sh.*ops/a.sh"; then echo "  ✅ (xi) presença guarda o token testado no arquivo inteiro, e só ele"; else echo "  ✗ (xi)"; fails=$((fails+1)); fi

  # (xii) variações honestas do marcador => calam
  _reset
  printf 'veja ops/deploy.sh (core-only, não viaja)\nveja ops/x.sh (Core-only)\nveja ops/y.sh (core-only; idem)\n' > "${tmp}/.claude/rules/m.md"
  _run
  if _has 'm.md'; then echo "  ✗ (xii) (core-only, …) e (Core-only) deveriam calar"; fails=$((fails+1)); else echo "  ✅ (xii) variações do marcador calam"; fi

  # (xiii) CONTAGEM: 2ª citação do mesmo token num arquivo com 1 no baseline => HARD (cresceu)
  _reset
  printf 'o `ops/a.sh` faz\ne o `ops/a.sh` agora também publica\n' > "${tmp}/.claude/rules/r.md"
  printf '.claude/rules/r.md|ops/a.sh|1\n' >> "${BL}"
  _run
  if _has $'^HARD\tNEW\t.claude/rules/r.md\t.*cresceu de 1 para 2'; then echo "  ✅ (xiii) citação a mais de token tolerado = HARD (cresceu)"; else echo "  ✗ (xiii)"; fails=$((fails+1)); fi

  # (xiv) frontmatter NEGADO acusa; frontmatter com CRLF que declara Core-only cala
  _reset
  printf -- '---\ndescription: Este comando NÃO é Core-only.\n---\nrode `bash ops/x.sh`\n' > "${tmp}/.claude/commands/meta/neg.md"
  printf -- '---\r\ndescription: Publica. Core-only.\r\n---\r\nrode `bash ops/x.sh`\r\n' > "${tmp}/.claude/commands/meta/crlf.md"
  _run
  if _has 'neg.md' && ! _has 'crlf.md'; then echo "  ✅ (xiv) frontmatter negado acusa; CRLF não esconde a declaração"; else echo "  ✗ (xiv)"; fails=$((fails+1)); fi

  # (xv) paths: no frontmatter de uma rule é gatilho de carga, não descrição => cala; corpo da mesma rule acusa
  _reset
  printf -- '---\npaths:\n  - "ops/publish-door.sh"\n---\nrode `bash ops/publish-door.sh`\n' > "${tmp}/.claude/rules/pl.md"
  _run
  if _has $'^HARD\tNEW\t.claude/rules/pl.md\t.*(1 ocorr'; then echo "  ✅ (xv) paths: do frontmatter cala; o corpo acusa"; else echo "  ✗ (xv)"; fails=$((fails+1)); fi

  # (xvi) em PROSA a presença NÃO se propaga: a frase do SAC-86 com um exemplo `[ -f … ]` abaixo => acusa
  _reset
  printf 'O `ops/pr-merge-verified.sh` recusa o rebase.\n\n```bash\n[ -f ops/pr-merge-verified.sh ] || echo sem\n```\n' > "${tmp}/.claude/rules/lente.md"
  _run
  if _has $'^HARD\tNEW\t.claude/rules/lente.md\t.*(1 ocorr'; then echo "  ✅ (xvi) em prosa a presença vale só na linha (a frase do SAC-86 acusa)"; else echo "  ✗ (xvi)"; fails=$((fails+1)); fi

  # (xvii) `-r` antes de `source` é teste de presença honesto => cala
  _reset
  printf '[ -r "$R/ops/j.sh" ] && . "$R/ops/j.sh"\n' > "${tmp}/.claude/hooks/j.sh"
  _run
  if _has 'hooks/j.sh'; then echo "  ✗ (xvii) -r deveria calar"; fails=$((fails+1)); else echo "  ✅ (xvii) [ -r …ops/… ] cala"; fi

  # (xviii) SAC-149: o ops/ que uma `violation "…"` IMPRIME acusa mesmo com teste de presença em OUTRA linha do
  #         arquivo — a mensagem chega ao adotante sem o teste (a da REGRA 85 mandava rodar ops/publish-door.sh)
  _reset
  printf '[ -f "${R}/ops/publish-door.sh" ] && bash "${R}/ops/publish-door.sh"\nviolation "SOFT" "x" "rode bash ops/publish-door.sh --status"\n' > "${tmp}/.claude/hooks/m.sh"
  _run
  if _has 'hooks/m.sh'; then echo "  ✅ (xviii) mensagem de violation com ops/ acusa apesar do teste de presença no arquivo"; else echo "  ✗ (xviii) a mensagem impressa deveria acusar"; fails=$((fails+1)); fi

  # (xix) ... mas na regra declarada `# aplica-se: source` cala: ela não roda fora do core
  _reset
  printf '# REGRA 85 — porta [SOFT]\n# aplica-se: source\ncheck_p() {\n  [ -f "${R}/ops/publish-door.sh" ] || return 0\n  violation "SOFT" "x" "rode bash ops/publish-door.sh --status"\n}\n' > "${tmp}/.claude/hooks/n.sh"
  _run
  if _has 'hooks/n.sh'; then echo "  ✗ (xix) regra source-only deveria calar"; fails=$((fails+1)); else echo "  ✅ (xix) mensagem de regra '# aplica-se: source' cala"; fi

  # ── 2º vocabulário: o comando core-only cortado da adoção (sinal de campo 2026-10-19, num hub) ──
  # (xx) o defeito VERBATIM: comando que viaja manda o hub rodar `/meta:publish onion-plugins` => HARD.
  #      Mutante: com o 2º vocabulário desligado (cmdre vazio), este caso reprova.
  _reset
  printf '# 4b NO CORE: o bundle nasce na\n#        publicação (/meta:publish onion-plugins). Só regenere o catálogo.\n' > "${tmp}/.claude/commands/meta/create-vertical.md"
  _run
  if _has $'^HARD\tNEW\t.claude/commands/meta/create-vertical.md\t.*/meta:publish'; then echo "  ✅ (xx) /meta:publish num comando que viaja reprova (o defeito verbatim do hub)"; else echo "  ✗ (xx)"; fails=$((fails+1)); fi

  # (xxi) marcador (core-only), CAMINHO do arquivo e nome mais longo => calam; a grafia /meta/publish conta junto
  _reset
  printf 'na fonte, rode /meta:publish --status (core-only)\nveja .claude/commands/meta/publish.md\no /meta:publish-door não existe\n' > "${tmp}/.claude/rules/c.md"
  printf 'rode `/meta/publish onion-core` e depois `/meta:publish --status`\n' > "${tmp}/.claude/rules/d.md"
  _run
  if ! _has 'rules/c.md' && _has $'^HARD\tNEW\t.claude/rules/d.md\t.*/meta:publish.*(2 ocorr'; then echo "  ✅ (xxi) marcador, caminho e nome mais longo calam; /meta/publish e /meta:publish contam como um token"; else echo "  ✗ (xxi)"; fails=$((fails+1)); fi

  # (xxii) a própria superfície cortada (o comando, a skill) não é varrida para este vocabulário
  _reset; mkdir -p "${tmp}/.claude/skills/onion-publish"
  printf 'rode /meta:publish onion-core\n' > "${tmp}/.claude/commands/meta/publish.md"
  printf 'conduz o /meta:publish\n' > "${tmp}/.claude/skills/onion-publish/SKILL.md"
  _run
  rm -rf "${tmp}/.claude/skills/onion-publish"
  if _has 'meta/publish.md' || _has 'onion-publish'; then echo "  ✗ (xxii) a superfície cortada não deveria acusar o próprio comando"; fails=$((fails+1)); else echo "  ✅ (xxii) o comando cortado e a skill dele citam /meta:publish sem acusar"; fi

  # ── 3º vocabulário: o script core-only cortado da adoção (2026-10-20, D_U1_MIGRADOR_NO_KG_SSOT) ──
  # (xxiii) o defeito VERBATIM: a dica que o kg-contract-check.sh imprime ao adotante manda rodar o migrador do core
  #         => HARD; e o caminho inteiro também conta. Mutante: com o 3º vocabulário desligado, reprova.
  _reset
  printf '    "form.enum.node.provenance.locality": "use repo, web, host ou pessoa (ou tire a chave; kg-migrate-v3.py --locality a deriva do source)",\n' > "${tmp}/.claude/hooks/hint.py"
  printf 'migre com `python3 .claude/utils/kg/kg-migrate-v3.py --external-edges`\n' > "${tmp}/.claude/rules/g.md"
  _run
  if _has $'^HARD\tNEW\t.claude/hooks/hint.py\t.*kg-migrate-v3.py' && _has $'^HARD\tNEW\t.claude/rules/g.md\t.*kg-migrate-v3.py'; then echo "  ✅ (xxiii) o script core-only cortado, citado pelo nome ou pelo caminho num arquivo que viaja, reprova"; else echo "  ✗ (xxiii)"; fails=$((fails+1)); fi

  # (xxiv) marcador (core-only) e nome mais longo dos dois lados => calam
  _reset
  printf 'no core, kg-migrate-v3.py --locality (core-only) a deriva\no old-kg-migrate-v3.py e o kg-migrate-v3.pyc não são ele\n' > "${tmp}/.claude/rules/h.md"
  _run
  if _has 'rules/h.md'; then echo "  ✗ (xxiv) marcador e nome mais longo deveriam calar"; fails=$((fails+1)); else echo "  ✅ (xxiv) marcador (core-only) e nome mais longo calam"; fi

  # (xxv) o próprio script cortado e a planta do transporte não são varridos para este vocabulário
  _reset; mkdir -p "${tmp}/.claude/utils/kg" "${tmp}/.claude/utils/adopt"
  printf 'print("kg-migrate-v3.py: uso")\n' > "${tmp}/.claude/utils/kg/kg-migrate-v3.py"
  printf "_X=(':(exclude).claude/utils/kg/kg-migrate-v3.py')\n" > "${tmp}/.claude/utils/adopt/vendor-manifest.sh"
  _run
  rm -rf "${tmp}/.claude/utils"
  if _has 'kg-migrate-v3.py' ; then echo "  ✗ (xxv) o script cortado e a planta não deveriam acusar"; fails=$((fails+1)); else echo "  ✅ (xxv) o script cortado e a planta citam o nome sem acusar"; fi

  rm -rf "${tmp}"; echo "  selftest: $((total-fails))/${total} verdes"
  [ "${fails}" -eq 0 ] && return 0 || return 1
}
_scope_now() { printf '%s' "${VENDORED_ROOTS[*]}"; }

# --- args --------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --selftest)           SELFTEST=1; shift ;;
    --format)             FORMAT="${2:-text}"; shift 2 ;;
    --format=*)           FORMAT="${1#--format=}"; shift ;;
    --summary)            SUMMARY=1; shift ;;
    --emit-baseline)      EMIT_BASELINE=1; shift ;;
    --baseline)           BASELINE="${2:-}"; shift 2 ;;
    --baseline=*)         BASELINE="${1#--baseline=}"; shift ;;
    --previous-baseline)  PREV_BASELINE="${2:-}"; shift 2 ;;
    --base-ref)           BASE_REF="${2:-}"; shift 2 ;;
    -h|--help)            sed -n '/^# Uso/,/^# Exit/p' "$0"; exit 0 ;;
    -*)                   printf '❌ flag desconhecida: %s\n' "$1" >&2; exit 2 ;;
    *)                    if [ -z "${REPO_DIR}" ]; then REPO_DIR="$1"; fi; shift ;;
  esac
done

[ "${SELFTEST}" -eq 1 ] && { run_selftest; exit $?; }
case "${FORMAT}" in text|tsv) ;; *) printf '❌ --format inválido: %s\n' "${FORMAT}" >&2; exit 2 ;; esac
REPO_DIR="${REPO_DIR:-.}"
[ -d "${REPO_DIR}" ] || { printf '❌ ops-citation-travel-check: "%s" não é diretório.\n' "${REPO_DIR}" >&2; exit 2; }
REPO_DIR="$(cd "${REPO_DIR}" && pwd)"

BASELINE_REL=".claude/validation/ops-citation-travel-baseline.txt"
[ -n "${BASELINE}" ] || BASELINE="${REPO_DIR}/${BASELINE_REL}"

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
# Contagem por par (achado 9 da passada adversarial): com `arquivo|token` puro, a 2ª citação de um token já
# tolerado no MESMO arquivo passava calada. O baseline guarda `arquivo|token|N` e a catraca cobra o N.
collect_violations "${REPO_DIR}" | awk '{ n[$0]++ } END { for (k in n) print k "|" n[k] }' | LC_ALL=C sort > "${TMP}/current"

# --emit-baseline: bootstrap operado À MÃO (o script nunca ESCREVE o baseline — desarmaria a catraca).
if [ "${EMIT_BASELINE}" -eq 1 ]; then
  printf '# Baseline de citações de ops/<arquivo> em superfície que VIAJA — PASSIVO TOLERADO (REGRA 100).\n'
  printf '# Gerado por: bash .claude/validation/%s --emit-baseline > %s\n' "${SELF_NAME}" "${BASELINE_REL}"
  printf '# formato: <rel>|<ops/token>|<ocorrências>. SÓ PODE ENCOLHER: reescreva para o que o destinatário tem, ou marque (core-only), e remova a linha.\n'
  printf '# scope: %s\n' "${VENDORED_ROOTS[*]}"
  cat "${TMP}/current"
  exit 0
fi

read_baseline() { command grep -vE '^[[:space:]]*(#|$)' "$1" 2>/dev/null | sed 's/[[:space:]]*$//' | LC_ALL=C sort -u || true; }
HARD=0; SOFT=0; : > "${TMP}/out"
say() { printf '%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "$4" >> "${TMP}/out"; if [ "$1" = "HARD" ]; then HARD=$((HARD+1)); else SOFT=$((SOFT+1)); fi; }
FIX="reescreva para o que o destinatário de fato tem, ou marque a linha com (core-only) se ela descreve o core"

if [ ! -f "${BASELINE}" ]; then
  say "HARD" "NO-BASELINE" "${BASELINE_REL}" "baseline AUSENTE — catraca desarmada; nenhuma citação nova pode ser distinguida do passivo. Gere: bash .claude/validation/${SELF_NAME} --emit-baseline > ${BASELINE_REL}"
  while IFS= read -r p; do [ -n "${p}" ] && say "SOFT" "NO-BASELINE-CITE" "${p%%|*}" "cita '${p#*|}' (severidade rebaixada: sem baseline)"; done < "${TMP}/current"
else
  read_baseline "${BASELINE}" > "${TMP}/baseline"
  # join por `arquivo|token`: o último campo é a contagem
  awk -F'|' '
    function key(   k, i) { k = $1; for (i = 2; i < NF; i++) k = k "|" $i; return k }
    FILENAME == ARGV[1] { b[key()] = $NF; next }   # nunca FNR==NR: com 1º arquivo VAZIO ele casa o 2º
    { k = key(); c = $NF; seen[k] = 1
      if (!(k in b))              print "HARD\tNEW\t" $1 "\t" k "\t" c " ocorrência(s), fora do baseline"
      else if (c + 0 > b[k] + 0)  print "HARD\tNEW\t" $1 "\t" k "\tcresceu de " b[k] " para " c " ocorrência(s)"
      else { print "SOFT\tPASSIVO\t" $1 "\t" k "\t" c " ocorrência(s)"
             if (c + 0 < b[k] + 0) print "SOFT\tBASELINE-OBSOLETA\t" $1 "\t" k "\tencolheu de " b[k] " para " c " — atualize a contagem no baseline (só encolhe)" } }
    END { for (k in b) if (!(k in seen)) print "SOFT\tBASELINE-OBSOLETA\t" k "\t" k "\tjá não existe — remova do baseline (só encolhe)" }
  ' "${TMP}/baseline" "${TMP}/current" | LC_ALL=C sort > "${TMP}/join"
  while IFS=$'\t' read -r sev tag path k detail; do
    [ -n "${sev}" ] || continue
    case "${tag}" in
      NEW)     case "${k#*|}" in
                 ops/*) _why="ops/ não vai a nenhuma porta nem adotante" ;;
                 /*)    _why="o comando é core-only e a adoção o corta (vendor-manifest.sh --retired-excludes)" ;;
                 *)     _why="o script é core-only e a adoção o corta (vendor-manifest.sh --retired-excludes)" ;;
               esac
               say "HARD" "NEW" "${path}" "cita '${k#*|}' (${detail}) num arquivo que VIAJA — ${_why}, e lá a frase descreve um comportamento que o destinatário não tem: ${FIX}" ;;
      PASSIVO) say "SOFT" "PASSIVO" "${path}" "passivo: cita '${k#*|}' (${detail}) — ${FIX}, e remova do baseline" ;;
      *)       say "SOFT" "BASELINE-OBSOLETA" "${BASELINE_REL}" "entrada '${k}': ${detail}" ;;
    esac
  done < "${TMP}/join"
  # CATRACA — baseline SÓ ENCOLHE (vs origin/integração > HEAD), escopo-ciente (molde kb-vendored-link-check)
  : > "${TMP}/prev"; PREV_SOURCE=""; PREV_RAW=""
  if [ -n "${PREV_BASELINE}" ] && [ -f "${PREV_BASELINE}" ]; then
    read_baseline "${PREV_BASELINE}" > "${TMP}/prev"; PREV_SOURCE="arquivo"; PREV_RAW="${PREV_BASELINE}"
  elif git -C "${REPO_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
    refs="${BASE_REF}"; if [ -z "${refs}" ]; then
      _sib="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/resolve-integration-branch.sh"
      integ=""; [ -x "${_sib}" ] && integ="$("${_sib}" "${REPO_DIR}" 2>/dev/null || true)"
      [ -n "${integ}" ] && refs="origin/${integ} ${integ}"; refs="${refs} HEAD"
    fi
    for r in ${refs}; do
      if git -C "${REPO_DIR}" show "${r}:${BASELINE_REL}" >"${TMP}/prev.raw" 2>/dev/null; then
        read_baseline "${TMP}/prev.raw" > "${TMP}/prev"; PREV_SOURCE="git ${r}"; PREV_RAW="${TMP}/prev.raw"
        case "${r}" in origin/*) : ;; *) [ -n "${BASE_REF}" ] || say "SOFT" "CATRACA-FRACA" "${BASELINE_REL}" "catraca vs '${r}' (ref LOCAL): crescimento já commitado aqui não é detectado — só origin/<integração> é referência forte"; esac
        break
      fi
    done
  fi
  _scope_of() { command grep -m1 '^# scope:' "$1" 2>/dev/null | sed 's/^# scope:[[:space:]]*//' || true; }
  CUR_SCOPE="$(_scope_of "${BASELINE}")"; PREV_SCOPE=""
  [ -n "${PREV_RAW}" ] && [ -f "${PREV_RAW}" ] && PREV_SCOPE="$(_scope_of "${PREV_RAW}")"
  if [ -n "${PREV_SOURCE}" ]; then
    if [ "${CUR_SCOPE}" != "${PREV_SCOPE}" ]; then
      say "SOFT" "ESCOPO-EXPANDIDO" "${BASELINE_REL}" "escopo MUDOU ('${PREV_SCOPE:-<ausente>}' → '${CUR_SCOPE}') — catraca de crescimento SUSPENSA nesta rodada (passivos de escopos distintos não são comparáveis)."
    else
      # cresceu = par novo OU contagem maior que a da referência
      awk -F'|' '
        function key(   k, i) { k = $1; for (i = 2; i < NF; i++) k = k "|" $i; return k }
        FILENAME == ARGV[1] { p[key()] = $NF; next }
        { k = key(); if (!(k in p) || $NF + 0 > p[k] + 0) print k "|" $NF }
      ' "${TMP}/prev" "${TMP}/baseline" > "${TMP}/added"
      while IFS= read -r p; do [ -n "${p}" ] && say "HARD" "CATRACA" "${BASELINE_REL}" "CATRACA VIOLADA: '${p}' ACRESCENTADO ou AUMENTADO no baseline (vs ${PREV_SOURCE}) — só pode ENCOLHER. Citação nova se declara (core-only) ou se reescreve; não se amplia a tolerância"; done < "${TMP}/added"
    fi
  fi
fi

if [ "${FORMAT}" = "tsv" ]; then
  cat "${TMP}/out"
else
  printf '=== Citações de ops/<arquivo> em superfície que viaja (REGRA 100) ===\n'
  printf '  Citações não declaradas: %s · Baseline: %s\n\n' "$(wc -l < "${TMP}/current" | tr -d ' ')" "$([ -f "${BASELINE}" ] && printf '%s entrada(s)' "$(wc -l < "${TMP}/baseline" | tr -d ' ')" || printf 'AUSENTE')"
  while IFS=$'\t' read -r sev tag path msg; do [ -n "${sev}" ] && printf '%s [%s] %s: %s\n' "$([ "${sev}" = "HARD" ] && printf '❌ HARD' || printf '⚠️  SOFT')" "${tag}" "${path}" "${msg}"; done < "${TMP}/out"
fi
[ "${SUMMARY}" -eq 1 ] && printf 'SUMMARY\tHARD=%s\tSOFT=%s\n' "${HARD}" "${SOFT}"
[ "${HARD}" -eq 0 ] || exit 1
exit 0
