#!/usr/bin/env bash
# =============================================================================
# install-onion-githook.sh — Provisiona o pre-commit NATIVO do Onion no adotado
#
# Propósito : Padronizar o hook de pre-commit dos adotantes no MESMO mecanismo
#             que o core Onion usa — git hook NATIVO via `core.hooksPath .githooks`,
#             dependency-free e à prova de worktree (degrada gracioso sem
#             node_modules). Substitui a necessidade de husky (que existe só para
#             REGISTRAR hooks — trabalho que o core.hooksPath faz nativo de graça)
#             e dissolve, na raiz, o atrito ENOENT da adoção legacy
#             (inbox/_processed/2026-06-27-adopt-legacy-husky-precommit-enoent.md).
#             Decisão: ../../../docs/knowledge-base/decisions/onion-adr-native-githooks-standard-2026-06.md
#
# Mecânica  : (1) copia githook-pre-commit-onion.tpl → <DEST>/.githooks/pre-commit
#                 (NEVER-CLOBBER, 3 casos: idêntico → no-op; hook ONION
#                 DESATUALIZADO (--update, o template evoluiu) → REFRESCA/overwrite
#                 (senão o --update deixaria o hook Onion ANTIGO ativo e o novo inerte
#                 como .onion); pre-commit PRÓPRIO do alvo e diferente → sidecar
#                 pre-commit.onion p/ merge manual).
#             (2) detecta husky → AVISA migração (não desinstala — é do adotante).
#             (3) core.hooksPath: seta .githooks SÓ se UNSET (never-clobber). Se já
#                 aponta p/ husky/custom, NÃO sobrescreve — avisa p/ ativar consciente.
#             IDEMPOTENTE: 2ª rodada = no-op.
#
# Uso       : install-onion-githook.sh <dest-dir>   (PATH do repo alvo)
#
# Gracioso  : dest inválido / não-repo / template ausente → exit 2 (erro de uso).
#             Falha de I/O / permissão → aviso STDERR + exit 0 (não aborta a adoção).
#             Sem `set -e` de propósito, p/ controlar o exit gracioso nos I/O.
#
# Determinístico, sem LLM. Consumido por /meta:adopt (Fase 3 + --update) e
# exercitado pelo lint-selftest.sh (run_githook_selftests).
# =============================================================================
set -uo pipefail

DEST="${1:-}"
[ -n "${DEST}" ] || { echo "uso: install-onion-githook.sh <dest-dir>" >&2; exit 2; }
[ -d "${DEST}" ] || { echo "ERRO: dest não é diretório: ${DEST}" >&2; exit 2; }
git -C "${DEST}" rev-parse --git-dir >/dev/null 2>&1 || { echo "ERRO: dest não é repo git: ${DEST}" >&2; exit 2; }

TPL="$(dirname "$0")/githook-pre-commit-onion.tpl"
[ -f "${TPL}" ] || { echo "ERRO: template não encontrado: ${TPL}" >&2; exit 2; }

HOOKDIR="${DEST}/.githooks"
HOOK="${HOOKDIR}/pre-commit"
mkdir -p "${HOOKDIR}" 2>/dev/null || { echo "AVISO: não criou ${HOOKDIR} (permissão?) — hook não provisionado." >&2; exit 0; }

# (1) Provisiona o pre-commit — NEVER-CLOBBER, com REFRESH do hook Onion-autorado.
#
#   Três casos (o do meio nasceu de um sinal de campo de adotante, 2026-07-25):
#     (a) idêntico ao template          -> no-op
#     (b) DIFERENTE mas Onion-AUTORADO  -> REFRESH (sobrescreve): é a NOSSA versão antiga,
#                                          o template evoluiu. Sidecar aqui deixava o hook
#                                          VELHO ativo e o novo parado ao lado — o `--update`
#                                          não atualizava nada (declarado != verificado).
#     (c) DIFERENTE e de TERCEIRO       -> sidecar .onion (never-clobber de verdade)
#   O marcador de autoria é a linha de cabeçalho do template, estável desde a criação.
ONION_MARK='Onion — pre-commit hook NATIVO (provisionado por /meta:adopt)'
if [ -f "${HOOK}" ]; then
  if cmp -s "${TPL}" "${HOOK}" 2>/dev/null; then
    echo "Onion: .githooks/pre-commit já é o template Onion (no-op)." >&2
  elif grep -qF "${ONION_MARK}" "${HOOK}" 2>/dev/null; then
    # (b) hook Onion DESATUALIZADO -> refrescar. Não é clobber: estamos sobrescrevendo
    #     o nosso próprio artefato por uma versão mais nova.
    if cp "${TPL}" "${HOOK}" 2>/dev/null && chmod +x "${HOOK}" 2>/dev/null; then
      echo "Onion: .githooks/pre-commit era Onion-autorado e DESATUALIZADO — REFRESCADO para o template atual." >&2
      # Higiene: sidecar de rodada antiga vira lixo confuso depois do refresh.
      [ -f "${HOOK}.onion" ] && rm -f "${HOOK}.onion" 2>/dev/null \
        && echo "Onion: removido ${HOOK}.onion obsoleto (o hook ativo já é o template atual)." >&2
    else
      echo "AVISO: falha ao refrescar ${HOOK}." >&2
    fi
  else
    # (c) hook de TERCEIRO -> never-clobber (sidecar p/ merge manual).
    if cp "${TPL}" "${HOOK}.onion" 2>/dev/null && chmod +x "${HOOK}.onion" 2>/dev/null; then
      echo "Onion: .githooks/pre-commit já existe (de terceiro) — Onion gravado como pre-commit.onion (merge manual)." >&2
    else
      echo "AVISO: falha ao gravar ${HOOK}.onion." >&2
    fi
  fi
else
  if cp "${TPL}" "${HOOK}" 2>/dev/null && chmod +x "${HOOK}" 2>/dev/null; then
    echo "Onion: .githooks/pre-commit provisionado (hook nativo)." >&2
  else
    echo "AVISO: falha ao gravar ${HOOK}." >&2; exit 0
  fi
fi

# (2) Detecta husky → recomenda migração (não desinstala — decisão do adotante).
if [ -d "${DEST}/.husky" ] || grep -q '"husky"' "${DEST}/package.json" 2>/dev/null; then
  echo "AVISO: husky detectado. O padrão Onion é hook nativo (core.hooksPath). Para migrar:" \
       "remova .husky/ + a dep husky e ative o nativo (passo abaixo). Ver ADR onion-adr-native-githooks-standard." >&2
fi

# (3) core.hooksPath — NEVER-CLOBBER: só seta se UNSET.
CURRENT="$(git -C "${DEST}" config --local --get core.hooksPath 2>/dev/null || true)"
if [ -z "${CURRENT}" ]; then
  git -C "${DEST}" config core.hooksPath .githooks 2>/dev/null \
    && echo "Onion: core.hooksPath → .githooks (hook nativo ativo)." >&2 \
    || echo "AVISO: não setou core.hooksPath (ative à mão: git -C ${DEST} config core.hooksPath .githooks)." >&2
elif [ "${CURRENT}" = ".githooks" ]; then
  echo "Onion: core.hooksPath já = .githooks (no-op)." >&2
else
  echo "AVISO: core.hooksPath já = '${CURRENT}' (husky/custom) — NÃO sobrescrito." \
       "Para ativar o hook nativo Onion: git -C ${DEST} config core.hooksPath .githooks" >&2
fi

# ── (4) PROVA DE VIDA — costurada em 2026-08-16 a pedido do maestro ─────────────────────
# DEFEITO MEDIDO que motivou: este instalador saía 0 mesmo deixando o gate MORTO. O passo
# (3) é NEVER-CLOBBER: se o husky já ocupou o core.hooksPath, ele avisa no stderr e retorna
# SUCESSO — e a adoção reporta "ok". Foi exatamente assim que um adotante ficou com o hook
# do Onion em .githooks/ que o git nunca lê. Medição de 2026-08-16 nos 6 adotantes com
# .claude/: gate INERTE em 4 (husky sombreando · hooksPath para diretório vazio · ausente).
# Instalar e conferir que o arquivo existe declarava 3 desses como instalados.
# Agora o instalador PROVA por comportamento (commit-sonda descartável, índice temporário,
# nunca toca o índice do alvo) e o EXIT CODE passa a significar "o gate está vivo", não
# "eu fiz a minha parte". Fail-closed: quem chama (o /meta:adopt) vê a falha.
# APLICABILIDADE — a bancada pegou isto (2026-08-16): provar gate onde não há gate é
# reprovar o contexto errado. Dois casos em que a prova NÃO se aplica, e ambos declaram
# em vez de falhar: (i) alvo sem `.claude/validation/lint-artifacts.sh` — não há o que
# bloquear ainda (o próprio template do hook degrada gracioso nesse caso); (ii) repo sem
# nenhum commit (greenfield recém-iniciado) — não há HEAD de onde partir o commit-sonda.
if [ ! -f "${DEST}/.claude/validation/lint-artifacts.sh" ]; then
  echo "Onion: alvo ainda sem lint — gate instalado, prova ADIADA (rode ops/verify-adopter-gate.sh após instalar o framework)." >&2
  exit 0
fi
if ! git -C "${DEST}" rev-parse HEAD >/dev/null 2>&1; then
  echo "Onion: alvo sem commits — gate instalado, prova ADIADA (o commit-sonda exige um HEAD)." >&2
  exit 0
fi

VERIFY="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/ops/verify-adopter-gate.sh"
if [ -f "${VERIFY}" ]; then
  echo "" >&2
  echo "Onion: provando o gate por EXECUÇÃO (não por existência de arquivo)…" >&2
  if bash "${VERIFY}" "${DEST}" >&2; then
    exit 0
  fi
  echo "ERRO: o hook foi provisionado mas o gate NÃO está vivo — a adoção não entregou a" \
       "guarda que promete. Corrija os ✗ acima e rode este instalador de novo." >&2
  exit 1
fi
# Sem o verificador ao alcance (ex.: bundle vendorizado sem ops/), diz o que NÃO sabe.
echo "AVISO: verify-adopter-gate.sh não encontrado — gate instalado mas NÃO provado vivo." >&2
exit 0
