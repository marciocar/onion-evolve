#!/usr/bin/env bash
# Prova, POR COMPORTAMENTO, que o gate determinístico do Onion está VIVO num repo.
#
# ── POR QUE EXISTE (defeito MEDIDO em 2026-08-16, 6 adotantes) ──────────────────────────
# Os adotantes recebem 13–40 scripts de validação. Em 4 de 6, o gate NÃO RODA — e em
# nenhum caso isso é visível olhando arquivos:
#   · metagamify  → hook do Onion PRESENTE, mas `core.hooksPath=.husky`: o husky ganha e o
#                   nosso nunca executa. Guarda INALCANÇÁVEL (a ausência se vê no code
#                   review; a inalcançabilidade dá impressão de cobertura).
#   · pedro/arthur→ `core.hooksPath=.githooks` CONFIGURADO apontando para diretório SEM
#                   hook: gate declarado e inexistente.
#   · onion-dist  → nada.
# Conferir "o arquivo existe?" declararia 3 desses como OK. Por isso a prova é a EXECUÇÃO.
#
# ── O QUE ELE PROVA, e o que ele DECLARA que não provou ─────────────────────────────────
#  1. RESOLUÇÃO — qual caminho de hooks o git usa DE FATO, e se o pre-commit de lá é o do
#     Onion (procura a assinatura do template) ou de outro gestor.
#  2. EXECUÇÃO — faz um commit-sonda descartável e observa se o hook RODOU (a linha
#     "🧅 Onion pre-commit" no stderr/stdout do git). Pega os 4 modos medidos acima.
#  3. BLOQUEIO — roda o lint direto: se ele acusa HARD e mesmo assim o commit passou, o
#     gate é FAIL-OPEN (defeito grave). Se o lint está limpo, o bloqueio NÃO é exercido —
#     e isso fica DECLARADO, nunca contado como aprovado (não há gatilho HARD portátil
#     entre adotantes; inventar um seria testar a sonda, não o gate).
#
# O commit-sonda é sempre desfeito (`reset --soft` + limpeza), nunca empurrado.
#
# Uso: bash ops/verify-adopter-gate.sh [caminho-do-repo]   (default: repo atual)
set -uo pipefail

REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
# ⚠️ `rev-parse --git-dir`, NÃO `[ -d .git ]`. Numa WORKTREE o `.git` é um ARQUIVO (ponteiro para
# o gitdir do repo principal), então o teste de diretório reprovava — e a adoção `legacy`/`regulated`
# SEMPRE instala em worktree (Fase 2a do /meta:adopt). Efeito medido em 2026-09-11, adotando um
# monorepo NX: o passo BLOQUEANTE da prova de vida do gate falhava por 100% dos casos desse modo,
# dizendo "não é um repositório git" sobre uma worktree válida. O próprio install-onion-githook.sh,
# que chama este verificador, já usava a forma correta uma linha acima — as duas pontas discordavam.
# Classe: a checagem perguntava "o .git é diretório?" quando a pergunta é "isto é um repo git?".
git -C "${REPO}" rev-parse --git-dir >/dev/null 2>&1 || { echo "✗ '${REPO}' não é um repositório git"; exit 2; }
cd "$REPO" || exit 2

ok() { printf '  ✓ %s\n' "$*"; }
no() { printf '  ✗ %s\n' "$*"; }
info() { printf '  · %s\n' "$*"; }
FAILED=0

echo "── gate do Onion em ${REPO}"

# ── 1. RESOLUÇÃO ────────────────────────────────────────────────────────────────────────
HP="$(git config core.hooksPath || true)"
DIR="${HP:-.git/hooks}"
case "$DIR" in /*) ABS="$DIR" ;; *) ABS="${REPO}/${DIR}" ;; esac
info "core.hooksPath = ${HP:-<não definido, usa .git/hooks>}"
if [ ! -f "${ABS}/pre-commit" ]; then
  no "não há pre-commit em '${DIR}' — o git não tem o que executar"
  FAILED=1
else
  if grep -q "Onion pre-commit" "${ABS}/pre-commit" 2>/dev/null; then
    ok "pre-commit em '${DIR}' é o do Onion"
  else
    no "pre-commit em '${DIR}' NÃO é o do Onion (outro gestor ocupou o caminho — ex.: husky)"
    FAILED=1
  fi
  [ -x "${ABS}/pre-commit" ] || { no "pre-commit existe mas NÃO é executável"; FAILED=1; }
fi
# o caso metagamify: hook do Onion existe noutro diretório, mas o git não olha para lá.
#
# ⚠️ COMPARAÇÃO POR IDENTIDADE (`-ef`), NUNCA POR STRING — medido 2026-09-15, e o defeito ABORTAVA
# ADOÇÃO LEGÍTIMA. O teste era `[ "${DIR}" != ".githooks" ]`, e um alvo com
# `core.hooksPath=/home/<user>/<repo>/.githooks` (forma ABSOLUTA, que o git aceita e resolve igual)
# reprovava: mesmo diretório, string diferente. Pior, o veredito saía CONTRADIZENDO as próprias
# linhas seguintes deste script — "✗ o git IGNORA o hook" logo acima de "✓ o hook EXECUTOU" e
# "✓ o commit foi BARRADO, bloqueio provado". Um verificador cuja razão de existir é provar
# COMPORTAMENTO decidindo por DECLARAÇÃO de path.
# O `ABS` já era calculado 15 linhas acima exatamente para isto; esta checagem é que não o usava.
_ONION_HOOKS="${REPO}/.githooks"
if [ -f "${_ONION_HOOKS}/pre-commit" ] && ! [ "${ABS}" -ef "${_ONION_HOOKS}" ]; then
  no "há hook do Onion em .githooks/ que o git IGNORA (hooksPath aponta para '${DIR}')"
  FAILED=1
fi

# ── 2. EXECUÇÃO (commit-sonda descartável) ──────────────────────────────────────────────
PROBE=".onion-gate-probe.tmp"
CRIOU_COMMIT=0
# ÍNDICE TEMPORÁRIO — a sonda NUNCA toca o índice de quem está adotando. Sem isto, um
# `git add` do usuário pendente entraria no commit-sonda e seria commitado junto (e depois
# "desfeito" por um reset que ele não pediu). Esta sonda vai rodar DENTRO do /meta:adopt:
# ferramenta de verificação que altera o estado de quem verifica não é verificação, é dano.
TMPIDX="$(mktemp -t onion-gate-idx.XXXXXX)"
export GIT_INDEX_FILE="$TMPIDX"
cleanup() {
  [ "$CRIOU_COMMIT" -eq 1 ] && git reset --soft HEAD~1 >/dev/null 2>&1
  rm -f "$PROBE" "$TMPIDX"
}
trap cleanup EXIT

git read-tree HEAD >/dev/null 2>&1 || true   # índice temporário parte do HEAD
printf 'sonda do gate — apagada automaticamente\n' > "$PROBE"
git add "$PROBE" >/dev/null 2>&1
# ⚠️ IDENTIDADE EXPLÍCITA no commit-sonda — medido no CI em 2026-09-15. Sem `user.email`/`user.name`
# o git RECUSA o commit antes de chamar o hook, e o verificador conclui "o hook não executou" quando
# o que faltou foi CONFIGURAÇÃO. Num runner de CI limpo (sem git global) isso torna o passo de
# BLOQUEIO ineludível: ele nunca é alcançado, e o caso da bancada que o exercita PULA — o que, em
# modo STRICT, reprova (e reprova certo: guarda que não roda no CI é guarda que não existe).
# A identidade é do SONDA e morre com ele (`-c`, não `config`): não toca a configuração do alvo.
OUTPUT="$(git -c commit.gpgsign=false -c user.email=onion-gate-probe@local -c user.name='Onion Gate Probe' commit -m "chore: onion gate probe (descartável)" 2>&1)"
RC=$?
[ "$RC" -eq 0 ] && CRIOU_COMMIT=1

EXECUTOU=0
if printf '%s' "$OUTPUT" | grep -q "Onion pre-commit"; then
  ok "o hook EXECUTOU no commit (assinatura observada)"
  EXECUTOU=1
else
  no "o hook NÃO executou — gate INERTE (nenhum sinal do lint no commit)"
  FAILED=1
fi

# ── 3. BLOQUEIO (só afirma o que der para provar) ───────────────────────────────────────
LINT="${REPO}/.claude/validation/lint-artifacts.sh"
if [ ! -f "$LINT" ]; then
  info "sem .claude/validation/lint-artifacts.sh — nada a bloquear (repo não adotou o gate)"
else
  bash "$LINT" >/dev/null 2>&1
  LRC=$?
  # ⚠️ FALSO POSITIVO CORRIGIDO na 1ª execução real (metagamify, 2026-08-16): a versão
  # anterior declarava "bloqueio provado" só porque lint reprovava E o commit falhou — mas
  # ali quem barrou foi o HUSKY, não o gate do Onion, que nem chegou a rodar. Atribuir a
  # outro o mérito de barrar é a mesma classe que esta sonda existe para pegar. Agora só
  # se afirma bloqueio quando o NOSSO hook comprovadamente executou.
  if [ "$EXECUTOU" -eq 0 ]; then
    info "bloqueio NÃO avaliado: o hook do Onion não executou (o que barrou, se barrou, foi outro)"
  elif [ "$LRC" -ne 0 ] && [ "$RC" -eq 0 ]; then
    no "FAIL-OPEN: o lint reprova (rc=${LRC}) e o commit PASSOU mesmo assim"
    FAILED=1
  elif [ "$LRC" -ne 0 ] && [ "$RC" -ne 0 ]; then
    ok "o commit foi BARRADO pelo gate do Onion com o lint reprovando — bloqueio provado"
    BLOQUEIO_PROVADO=1
  else
    info "lint limpo agora: o BLOQUEIO não foi exercido (só a execução) — declarado, não aprovado"
  fi
fi

echo
# ⚠️ O VEREDITO DISTINGUE EXECUTAR de BARRAR — sinal de campo de um adotante, 2026-09-15. Até então a
# linha final dizia "GATE VIVO — provado por execução" nos DOIS casos, e o `info` logo acima já dizia
# o contrário com todas as letras: "o BLOQUEIO não foi exercido — declarado, não aprovado". O script
# sabia a diferença e o veredito a apagava.
#
# E o estrago não parava no texto: o `install-onion-githook.sh` faz `grep 'GATE VIVO'` para carimbar
# `--gate-proven` na semente do KG do adotante. O grafo passava a AFIRMAR PROVA QUE NINGUÉM FEZ —
# exatamente o defeito que aquele passo existe para não repetir ("só afirma prova quem VÊ a prova").
# Mantendo a string `GATE VIVO` apenas no caso provado, o consumidor fica correto POR CONSTRUÇÃO.
#
# Um gate que roda e sempre passa é indistinguível de um gate quebrado até o dia em que precisa barrar.
# ⚠️ DEFAULT 0 — FAIL-CLOSED, e o CI pegou a 1ª versão com default 1. Com `:-1` o ramo "bloqueio NÃO
# avaliado" (o hook nem executou, comum em ambiente sem identidade git configurada) caía no veredito
# de PROVADO, porque eu só zerava a flag no ramo do lint-limpo. Prova é o que se OBSERVA: o default
# de "provei" nunca pode ser sim. Só o ramo que VÊ o commit ser barrado carimba 1.
if [ "$FAILED" -eq 0 ] && [ "${BLOQUEIO_PROVADO:-0}" -eq 1 ]; then
  echo "✓ GATE VIVO — bloqueio PROVADO por execução, não por existência de arquivo"
  exit 0
fi
if [ "$FAILED" -eq 0 ]; then
  echo "⚠️ GATE INSTALADO E EXECUTANDO — mas o BLOQUEIO não foi exercido (o lint do alvo está limpo)."
  echo "   Isto é DECLARAÇÃO, não prova: rode de novo com uma violação HARD plantada, ou aguarde o"
  echo "   primeiro commit que reprove. O grafo do alvo deve registrar isto como 'open', não 'confirmed'."
  exit 0
fi
echo "✗ GATE INERTE OU PARCIAL — os pontos com ✗ acima são o que o git realmente faz"
echo "  conserto usual: git config core.hooksPath .githooks  ·  e reinstalar com"
echo "  bash .claude/utils/adopt/install-onion-githook.sh (ou /meta:adopt --update)"
exit 1
