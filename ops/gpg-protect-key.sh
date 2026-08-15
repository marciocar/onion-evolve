#!/usr/bin/env bash
# Põe (ou troca) a passphrase da chave GPG raiz do maestro — SEM interação, sem a senha
# passar por argumento, e destruindo o arquivo de senha SEMPRE.
#
# ── POR QUE ISTO EXISTE COMO ARTEFATO VERSIONADO ────────────────────────────────────────
# A v1 deste script nasceu em 2026-08-11, funcionou (a chave FOI protegida) e foi apagada
# na limpeza da mesma sessão, marcada "temporário". Quatro dias depois o maestro repetiu a
# receita de memória: `printf '%s' 'senha' > /tmp/np.txt && bash ~/protege-chave.sh ...`.
# O script não existia mais — e o `shred` que ele fazia no final também não. Resultado
# MEDIDO em 2026-08-15: a senha ficou em `/tmp/np.txt` com modo 0644 (`-rw-rw-r--`) numa
# máquina com CINCO contas com shell — incluindo a conta COMPARTILHADA da equipe de um
# membro da federação (id `granaai`) — por ~1h15, até alguém reparar.
# A lição é a doutrina da casa: conhecimento operacional que fica "temporário" evapora, e o
# que evapora volta como incidente. Procedimento sensível vira ARTEFATO, com guardas.
#
# ── O QUE MUDA EM RELAÇÃO À v1 ──────────────────────────────────────────────────────────
#  1. RECUSA arquivo de senha legível por outros (o defeito exato que causou a exposição).
#  2. É CIENTE DO ESTADO: detecta por COMPORTAMENTO se a chave já tem senha. A v1 assumia
#     senha antiga vazia (`printf '\n%s\n%s\n'`) — rodá-la hoje, com a chave já protegida,
#     falharia em silêncio confuso. Chave protegida exige o arquivo da senha ATUAL.
#  3. `--check` não muda nada: só relata o estado (é o modo seguro de conferir).
#
# ── OPÇÕES REAIS DO GnuPG 2.4 (medido com `gpg --dump-options` em 2026-08-11) ───────────
# `--new-passphrase` NÃO EXISTE (a v0 usou e recebeu "invalid option"). As reais são
# `--passphrase`, `--passphrase-fd`, `--passphrase-file`, `--passphrase-repeat`. Em
# `--change-passphrase` com `--pinentry-mode loopback`, o gpg lê PRIMEIRO a senha antiga e
# DEPOIS a nova, ambas pelo mesmo descritor.
#
# ── USO ─────────────────────────────────────────────────────────────────────────────────
#   bash ops/gpg-protect-key.sh --check
#   umask 077; printf '%s' 'NOVA-SENHA' > /tmp/np.txt        # 0600 desde o nascimento
#   bash ops/gpg-protect-key.sh /tmp/np.txt                  # chave SEM senha  → protege
#   bash ops/gpg-protect-key.sh /tmp/np.txt /tmp/atual.txt   # chave COM senha  → troca
# Os arquivos de senha são destruídos (`shred -u`) ao final, dê certo ou errado.
set -euo pipefail

KEY="${ONION_GPG_KEY:-160D65435B1F12C8}"

# Prova de COMPORTAMENTO, nunca a saída do comando de mudança (a v1 já era assim, e é o
# ponto: `exit 0` é declaração do comando sobre si; assinar sem senha é fato).
key_is_protected() {
  if echo t | gpg --batch --pinentry-mode error -o /dev/null -s - 2>/dev/null; then
    return 1   # assinou sem pedir nada => DESPROTEGIDA
  fi
  return 0
}
files_protected_count() {
  grep -la 'protected-private-key' "${HOME}"/.gnupg/private-keys-v1.d/*.key 2>/dev/null | wc -l
}
key_files_total() {
  ls -1 "${HOME}"/.gnupg/private-keys-v1.d/*.key 2>/dev/null | wc -l
}

if [ "${1:-}" = "--check" ]; then
  total="$(key_files_total)"
  prot="$(files_protected_count)"
  if [ "$total" -eq 0 ]; then echo "✗ nenhuma chave privada em ~/.gnupg/private-keys-v1.d — nada a conferir"; exit 2; fi
  if key_is_protected; then
    echo "✓ chave ${KEY} PROTEGIDA — recusa assinar sem senha · arquivos protegidos: ${prot}/${total}"
    exit 0
  fi
  echo "✗ chave ${KEY} DESPROTEGIDA — assina sem senha · arquivos protegidos: ${prot}/${total}"
  exit 1
fi

NEWF="${1:?uso: $0 <arquivo-nova-senha> [arquivo-senha-atual]   |   $0 --check}"
CURF="${2:-}"

# Destrói os arquivos SEMPRE — é o que faltou no dia da exposição.
trap 'for f in "$NEWF" "$CURF"; do [ -n "$f" ] && [ -e "$f" ] && { shred -u "$f" 2>/dev/null || rm -f "$f"; }; done' EXIT

# GUARDA 1 — o arquivo não pode ser legível por outros. É o defeito medido em 2026-08-15:
# `printf ... > /tmp/np.txt` sem `umask 077` nasce 0644, e aqui há 5 contas com shell.
for f in "$NEWF" ${CURF:+"$CURF"}; do
  [ -s "$f" ] || { echo "✗ arquivo de senha ausente ou vazio: $f"; exit 1; }
  mode="$(stat -c '%a' "$f")"
  if [ "$((8#$mode & 8#077))" -ne 0 ]; then
    echo "✗ RECUSADO: $f está com modo $mode — legível/gravável por outras contas desta máquina."
    echo "  Crie assim:  umask 077; printf '%s' 'SUA-SENHA' > $f"
    exit 1
  fi
done

NEW="$(cat "$NEWF")"
CUR=""
[ -n "$CURF" ] && CUR="$(cat "$CURF")"

# GUARDA 2 — ciente do estado. Chave já protegida SEM senha atual informada é o caminho
# que a v1 não previa (ela mandaria uma linha vazia como "antiga" e falharia obscuro).
if key_is_protected; then
  if [ -z "$CURF" ]; then
    echo "✗ a chave JÁ tem senha — para TROCAR, informe também o arquivo com a senha atual:"
    echo "    umask 077; printf '%s' 'SENHA-ATUAL' > /tmp/atual.txt"
    echo "    bash $0 $NEWF /tmp/atual.txt"
    exit 1
  fi
  echo "→ chave protegida: TROCANDO a senha"
else
  [ -n "$CURF" ] && { echo "✗ a chave NÃO tem senha, mas você passou um arquivo de senha atual — abortando por segurança"; exit 1; }
  echo "→ chave sem senha: PROTEGENDO pela primeira vez"
fi

gpgconf --kill gpg-agent 2>/dev/null || true
sleep 1

# antiga (vazia quando não há) + nova + confirmação, pelo mesmo descritor
printf '%s\n%s\n%s\n' "$CUR" "$NEW" "$NEW" |
  gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --change-passphrase "$KEY" 2>&1 | tail -3

gpgconf --kill gpg-agent 2>/dev/null || true
sleep 1

# ── VERIFICAÇÃO POR COMPORTAMENTO — duas provas independentes ───────────────────────────
_falhou=0
key_is_protected || { echo "✗ a chave AINDA assina sem senha"; _falhou=1; }
prot="$(files_protected_count)"; total="$(key_files_total)"
[ "$prot" -eq "$total" ] && [ "$total" -gt 0 ] || { echo "✗ arquivos marcados protected: ${prot}/${total}"; _falhou=1; }
[ "$_falhou" -eq 0 ] || exit 1
echo "✓ chave protegida — arquivo E comportamento conferem (${prot}/${total})"
