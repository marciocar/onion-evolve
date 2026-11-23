#!/usr/bin/env bash
# ufw-orphan-rules.sh — apaga, por regra exata e com o desfazer guardado, as regras do ufw que liberavam portas de MCP
# no gateway da bridge do LibreChat e que hoje não servem a nada (core-only; o maestro roda os atos).
#
# POR QUE EXISTE (SAC-465, medição só de leitura da vps-ops em 2026-11-23): quatro regras `allow from <rede> to
# <gateway> port N proto tcp` sobraram de MCPs desligados. Nada escuta nessas portas no host e o LibreChat não as
# cita; regra de entrada sem serviço é superfície que alguém pode ocupar depois sem que ninguém perceba.
#
# O QUE FAZ:
#   · plan (padrão, ensaio): para cada porta da lista, diz se a regra existe, se algo escuta na porta e o veredito;
#   · apply --apply: RE-MEDE na hora (nunca confia na medição de ontem). Porta com escuta é PULADA, dita. Antes de
#     apagar, grava a linha exata de `ufw show added` (com o comentário original) num arquivo de desfazer root 600
#     em /var/backups/onion-ufw/, e só então apaga pela regra, nunca pelo número (o número muda a cada delete);
#   · undo --apply [arquivo]: re-adiciona cada regra do arquivo de desfazer (o mais novo, se não disser qual).
#
# O QUE NÃO FAZ: o undo re-adiciona a regra no FIM da lista do ufw, não na posição original (um deny mais amplo
# antes dela a sombrearia; para estas portas, sem serviço, o efeito é nulo). Não decide a lista (ela é a medida, abaixo, e muda por PR); não toca regra fora dela; não lê o
# arquivo de ambiente de nenhum serviço; não roda `ufw reload` nem `ufw disable`. O comentário de cada regra pode
# citar cliente: ele vive no ufw e no arquivo de desfazer (root 600), nunca neste repo.
#
# Uso:
#   ops/ufw-orphan-rules.sh plan                 # ensaio (padrão)
#   ops/ufw-orphan-rules.sh apply --apply        # apaga as órfãs, com o desfazer guardado
#   ops/ufw-orphan-rules.sh undo --apply [arq]   # re-adiciona o que o apply tirou
#   ops/ufw-orphan-rules.sh --selftest           # bancada em sandbox com ufw e ss de mentira
# Saída: 0 ok · 1 algo pulado ou não medido (dito) · 2 recusa/uso.
set -euo pipefail
set -f
export LC_ALL=C

SRC_NET="172.23.0.0/16"   # a rede do compose do LibreChat
GW="172.23.0.1"           # o gateway da bridge, endereço do host nessa rede
PORTS="3031 3032 3034 3036"   # medidas órfãs em 2026-11-23 (3033 e 3037 têm serviço e FICAM)
BACKUP_DIR="/var/backups/onion-ufw"
SUDO_CMD="sudo -n"
UFW="ufw"
SS="ss"
TEE="tee"
[[ "$(id -u)" == 0 ]] && SUDO_CMD=""

die() { echo "✗ RESULTADO: $*" >&2; exit 2; }
rule_of() { echo "allow from $SRC_NET to $GW port $1 proto tcp"; }

# as regras como o ufw as guarda (`ufw show added` imprime «ufw allow ... comment '...'»); falha = não medido
added() { $SUDO_CMD $UFW show added 2>/dev/null || return 1; }
# a linha de `show added` da regra da porta (com o comentário, se houver); vazio = regra ausente
added_line() { grep -E "^ufw $(rule_of "$1" | sed 's/[./]/\\&/g')( comment .*)?\$" <<< "$2" | head -n1 || true; }
# algo escuta na porta (em qualquer endereço do host)? 0 = sim
listening() { $SS -ltnH 2>/dev/null | awk '{print $4}' | grep -qE ":$1\$"; }

plan() {
  local all p line
  all="$(added)" || die "não li \`ufw show added\` (sudo sem senha?); nada medido"
  echo "── ensaio: regras órfãs do ufw no gateway $GW (nada muda)"
  for p in $PORTS; do
    line="$(added_line "$p" "$all")"
    if [[ -z "$line" ]]; then echo "   · $p: regra ausente (nada a fazer)"
    elif listening "$p"; then echo "   · $p: regra presente, mas ALGO ESCUTA na porta → o apply PULA"
    else echo "   · $p: regra presente, nada escuta → o apply apaga: ufw delete $(rule_of "$p")"; fi
  done
  echo "✓ RESULTADO: ensaio, nada mudou (o ato é: ops/ufw-orphan-rules.sh apply --apply)"
}

apply_rules() {
  local all p line ts undo skipped=0 done_=0
  all="$(added)" || die "não li \`ufw show added\`; nada mudou"
  ts="$(date +%Y%m%d-%H%M%S)"; undo="$BACKUP_DIR/undo-$ts.txt"
  $SUDO_CMD install -d -m 0700 "$BACKUP_DIR" || die "não criei $BACKUP_DIR; nada mudou"
  for p in $PORTS; do
    line="$(added_line "$p" "$all")"
    [[ -n "$line" ]] || { echo "   · $p: regra ausente, nada a fazer"; continue; }
    if listening "$p"; then echo "   ⚠ $p: algo escuta na porta agora; PULO (re-meça antes de tirar)"; skipped=1; continue; fi
    # o desfazer ANTES do delete: sem ele gravado, a regra não sai
    printf '%s\n' "$line" | $SUDO_CMD $TEE -a "$undo" >/dev/null || die "não gravei o desfazer da $p; parei antes de apagar"
    $SUDO_CMD chmod 600 "$undo"
    $SUDO_CMD $UFW delete $(rule_of "$p") >/dev/null || die "o ufw recusou apagar a $p; o desfazer do que já saiu está em $undo"
    echo "   ✓ $p: regra apagada"; done_=$((done_+1))
  done
  [[ "$done_" -gt 0 ]] && echo "── desfazer: ops/ufw-orphan-rules.sh undo --apply $undo"
  # conferência pelo estado: nenhuma das apagadas pode seguir no ufw
  all="$(added)" || { echo "✗ RESULTADO: apagadas $done_, mas não reli o ufw para conferir"; return 1; }
  for p in $PORTS; do
    if [[ -n "$(added_line "$p" "$all")" ]] && ! listening "$p"; then echo "✗ RESULTADO: a regra da $p segue no ufw"; return 1; fi
  done
  [[ "$skipped" == 0 ]] && echo "✓ RESULTADO: $done_ regra(s) órfã(s) apagada(s), conferido no ufw" \
    || { echo "⚠ RESULTADO: $done_ apagada(s), alguma porta PULADA por ter escuta"; return 1; }
}

undo_rules() {
  local f="${1:-}" line
  # o mais novo pelo find (o script roda com set -f: um glob aqui não expandiria)
  if [[ -z "$f" ]]; then f="$($SUDO_CMD find "$BACKUP_DIR" -maxdepth 1 -name 'undo-*.txt' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n1 | cut -d' ' -f2- || true)"; fi
  [[ -n "$f" ]] && $SUDO_CMD test -f "$f" || die "sem arquivo de desfazer (${f:-nenhum em $BACKUP_DIR})"
  # o arquivo INTEIRO é conferido antes da 1ª regra: nunca um desfazer pela metade
  local content; content="$($SUDO_CMD cat "$f")" || die "não li $f"
  while IFS= read -r line; do
    [[ "$line" =~ ^ufw\ allow\ from\ [0-9./]+\ to\ [0-9.]+\ port\ [0-9]+\ proto\ tcp( comment\ \'[^\']*\')?$ ]] \
      || die "linha fora da forma esperada no desfazer: «$line»; nada re-adicionado"
  done <<< "$content"
  while IFS= read -r line; do
    # re-adiciona pela forma gravada; o comentário vai como um argumento só
    local cmt="" spec="${line#ufw }"
    if [[ "$spec" == *" comment '"* ]]; then cmt="${spec#* comment \'}"; cmt="${cmt%\'}"; spec="${spec%% comment *}"; fi
    if [[ -n "$cmt" ]]; then $SUDO_CMD $UFW $spec comment "$cmt" >/dev/null; else $SUDO_CMD $UFW $spec >/dev/null; fi
    echo "   ✓ re-adicionada: $spec"
  done <<< "$content"
  echo "✓ RESULTADO: desfeito a partir de $f"
}

selftest() {
  local pass=0 fail=0 out rc
  SB="$(mktemp -d)"; trap 'rm -rf -- "${SB:-}"' EXIT
  SUDO_CMD=""; BACKUP_DIR="$SB/backups"; export UFWDB="$SB/ufw.db" SSDB="$SB/ss.db"
  for p in 3031 3032 3033 3034 3036 3037; do echo "ufw allow from 172.23.0.0/16 to 172.23.0.1 port $p proto tcp comment 'mcp $p'"; done > "$UFWDB"
  printf 'LISTEN 0 5 172.23.0.1:3033 0.0.0.0:*\nLISTEN 0 5 0.0.0.0:3037 0.0.0.0:*\n' > "$SSDB"
  cat > "$SB/ufw" <<'STUB'
#!/usr/bin/env bash
[ -n "${STUB_SHOW_FAIL:-}" ] && [ "$1" = show ] && exit 1
case "$1" in
  show) cat "$UFWDB" ;;
  delete) shift; l="ufw $*"; grep -vE "^$(printf '%s' "$l" | sed 's/[./]/\\&/g')( comment .*)?$" "$UFWDB" > "$UFWDB.t" || true; mv "$UFWDB.t" "$UFWDB" ;;
  allow) l="ufw $1"; shift; while [ $# -gt 0 ]; do if [ "$1" = comment ]; then l="$l comment '$2'"; shift 2; else l="$l $1"; shift; fi; done; echo "$l" >> "$UFWDB" ;;
esac
STUB
  printf '#!/usr/bin/env bash\ncat "$SSDB"\n' > "$SB/ss"
  chmod +x "$SB/ufw" "$SB/ss"; UFW="$SB/ufw"; SS="$SB/ss"
  t() { local name="$1" want="$2"; shift 2
    set +e; out="$( set -e; "$@" 2>&1 )"; rc=$?; set -e
    if [[ "$rc" -eq "$want" ]]; then pass=$((pass+1)); echo "  ✓ $name"; else fail=$((fail+1)); echo "  ✗ $name (rc=$rc, esperado=$want)"; printf '%s\n' "$out" | sed 's/^/      | /'; fi; }
  ok() { if eval "$2"; then pass=$((pass+1)); echo "  ✓ $1"; else fail=$((fail+1)); echo "  ✗ $1"; fi; }
  echo "── selftest (sandbox: $SB) ──"
  cp "$UFWDB" "$SB/before"
  t "plan: ensaio sai 0" 0 plan
  ok "plan: nada mudou" 'cmp -s "$UFWDB" "$SB/before"'
  t "apply: apaga as 4 órfãs" 0 apply_rules
  ok "apply: 3031/3032/3034/3036 saíram" '! grep -qE "port (3031|3032|3034|3036) " "$UFWDB"'
  ok "apply: 3033 e 3037 ficaram (fora da lista)" 'grep -q "port 3033 " "$UFWDB" && grep -q "port 3037 " "$UFWDB"'
  local uf; uf="$(find "$BACKUP_DIR" -name 'undo-*.txt' | head -n1)"
  ok "apply: desfazer gravado com os 4 comentários, modo 600" '[[ -n "$uf" && "$(grep -c "comment '"'"'mcp " "$uf")" == 4 && "$(stat -c %a "$uf")" == 600 ]]'
  t "apply 2x: idempotente (nada a fazer)" 0 apply_rules
  t "undo: re-adiciona (sem dizer o arquivo: pega o mais novo)" 0 undo_rules
  ok "undo: as 4 voltaram com o comentário original" '[[ "$(grep -cE "port (3031|3032|3034|3036) proto tcp comment '"'"'mcp " "$UFWDB")" == 4 ]]'
  # porta que passou a ter escuta: pulada, dita, regra fica
  echo "LISTEN 0 5 0.0.0.0:3032 0.0.0.0:*" >> "$SSDB"; rm -rf "$BACKUP_DIR"
  t "apply: porta com escuta → pula e sai 1" 1 apply_rules
  ok "apply com escuta: a regra da 3032 ficou, as outras saíram" 'grep -q "port 3032 " "$UFWDB" && ! grep -qE "port (3031|3034|3036) " "$UFWDB"'
  # ufw ilegível: recusa sem mexer
  cp "$UFWDB" "$SB/b2"
  STUB_SHOW_FAIL=1 t "apply: ufw ilegível → recusa" 2 apply_rules
  ok "ufw ilegível: nada mudou" 'cmp -s "$UFWDB" "$SB/b2"'
  # desfazer adulterado: recusa a linha fora da forma
  # desfazer com uma linha boa e uma adulterada: recusa ANTES de re-adicionar a boa
  cp "$UFWDB" "$SB/b3"
  printf "%s\n%s\n" "ufw allow from 172.23.0.0/16 to 172.23.0.1 port 3036 proto tcp comment 'mcp 3036'" "ufw default allow incoming" > "$SB/bad.txt"
  t "undo: linha fora da forma → recusa" 2 undo_rules "$SB/bad.txt"
  ok "undo adulterado: nada re-adicionado (nem a linha boa)" 'cmp -s "$UFWDB" "$SB/b3"'
  # o desfazer vem ANTES do apagar: sem conseguir gravá-lo, nenhuma regra sai
  rm -f "$SSDB"; touch "$SSDB"
  for p in 3031 3034; do echo "ufw allow from 172.23.0.0/16 to 172.23.0.1 port $p proto tcp comment 'mcp $p'" >> "$UFWDB"; done
  cp "$UFWDB" "$SB/b4"
  printf '#!/usr/bin/env bash\nexit 1\n' > "$SB/tee-falha"; chmod +x "$SB/tee-falha"
  TEE="$SB/tee-falha" t "apply: desfazer não grava → recusa antes de apagar" 2 apply_rules
  ok "desfazer falho: nenhuma regra saiu" 'cmp -s "$UFWDB" "$SB/b4"'
  # dois arquivos de desfazer: o undo sem argumento pega o mais novo
  mkdir -p "$BACKUP_DIR"; echo "ufw allow from 172.23.0.0/16 to 172.23.0.1 port 3099 proto tcp comment 'velho'" > "$BACKUP_DIR/undo-1.txt"; touch -d "2020-01-01" "$BACKUP_DIR/undo-1.txt"
  echo "ufw allow from 172.23.0.0/16 to 172.23.0.1 port 3098 proto tcp comment 'novo'" > "$BACKUP_DIR/undo-2.txt"
  t "undo sem arquivo: pega o mais novo" 0 undo_rules
  ok "undo: re-adicionou o do arquivo mais novo e não o velho" 'grep -q "port 3098 " "$UFWDB" && ! grep -q "port 3099 " "$UFWDB"'
  t "apply sem --apply → recusa" 2 main apply
  echo "── selftest: ${pass} pass / ${fail} fail ──"
  [[ "$fail" -eq 0 ]]
}

main() {
  local cmd="${1:-plan}" apply=0 arg=""
  shift || true
  while [[ $# -gt 0 ]]; do case "$1" in --apply) apply=1 ;; -*) die "argumento desconhecido: $1" ;; *) arg="$1" ;; esac; shift; done
  case "$cmd" in
    --selftest) selftest ;;
    plan) plan ;;
    apply) [[ "$apply" == 1 ]] || die "apply sem --apply: rode o ensaio (plan) ou acrescente --apply"; apply_rules ;;
    undo) [[ "$apply" == 1 ]] || die "undo sem --apply"; undo_rules "$arg" ;;
    *) die "modo desconhecido: $cmd" ;;
  esac
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && main "$@"
