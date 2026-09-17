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

# ── (0) LIMPAR A SUPERFÍCIE ANTES DE EXTRAIR — `tar -x` não remove o que saiu do manifesto ───
# Medido 2026-09-17, na SEGUNDA materialização: o core passou a EXCLUIR as chaves nomeadas por
# cliente do transporte, o manifesto novo não as traz — e elas continuavam na porta, porque
# `tar -x` sobrepõe mas não apaga. A porta seguiria publicando o que o core decidiu parar de
# enviar, e nada avisaria. É a classe `exit-code-nao-e-a-verificacao` aplicada ao ESTADO: o rc do
# tar diz que extraiu, não que o destino ESPELHA o bundle.
# A materialização passa a ser AUTORITATIVA: o que não está no bundle não fica na porta.
#
# ⚠️ GUARDA DE DESTINO, porque isto apaga arquivos: só limpa diretório VAZIO ou que já pareça uma
# porta (tem `.claude/`). Um caminho digitado errado não vira `rm -rf` no que quer que estivesse lá.
if [ -n "$(ls -A "${DEST}" 2>/dev/null | grep -v '^\.git$' || true)" ]; then
  if [ ! -d "${DEST}/.claude" ]; then
    echo "ERRO: '${DEST}' não está vazio e não parece uma porta (sem .claude/). Recuse-se a limpar um destino desconhecido." >&2
    exit 3
  fi
  find "${DEST}" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} + || {
    echo "ERRO: falha ao limpar a superfície anterior de ${DEST}" >&2; exit 3; }
  echo "  (0) superfície anterior removida — a materialização é AUTORITATIVA (o que saiu do manifesto sai da porta)"
fi
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

# ── (5) A RAIZ DA PORTA — o que o manifesto não leva porque o adotante não deve receber ──────
# Medido 2026-09-17, na 1ª materialização real: a porta subiu com README, LICENSE, CLAUDE.md e
# AGENTS.md AUSENTES — 4 de 4. Repo público sem README é ruim de receber; sem LICENSE é pior, e
# não por estilo: SEM licença o padrão legal é "todos os direitos reservados", o oposto do que uma
# porta existe para dizer. E sem CLAUDE.md o Onion não se apresenta a quem clona.
#
# ⚠️ AQUI O `LICENSE` NU É CORRETO, e no adotante seria ERRADO — a diferença é de OBJETO. No repo
# do cliente, um `LICENSE` na raiz rege O REPOSITÓRIO INTEIRO, inclusive o código que ele ainda vai
# escrever: por isso o `emit-licenses.sh` entrega `LICENSE-ONION` lá. Na PORTA, o repositório É o
# Onion; um `LICENSE-ONION` ali seria a evasiva, não a proteção.
_slug="$(basename "${DEST}")"
_pin_ph="$(git -C "${REPO_ROOT}" rev-parse --short=12 HEAD)"
cp "${REPO_ROOT}/LICENSE" "${DEST}/LICENSE" 2>/dev/null || echo "  (5) AVISO: LICENSE do core não encontrada" >&2
cp "${REPO_ROOT}/LICENSE-DOCS" "${DEST}/LICENSE-DOCS" 2>/dev/null || true
cat > "${DEST}/README.md" <<README
# 🧅 Onion — a maquinaria

> **Este repositório é uma PROJEÇÃO, não a fonte.** Ele é materializado do core por
> \`ops/materialize-door.sh\` e **não recebe PR** — uma correção feita aqui é sobrescrita na próxima
> materialização. O caminho de contribuição é o canal de sinais descrito em \`docs/evolution/\`.

O Onion é um framework de método executável para Claude Code: comandos invocáveis, agentes
especializados, skills e — o que o distingue — **guardas determinísticas** que reprovam em CI. Ele
cobre três dimensões peer do ciclo: produto, engenharia e compliance.

## O que está aqui, e o que não está

**Está:** a maquinaria completa — \`.claude/\` (comandos, agentes, skills, hooks, utils, validation),
as meta-specs e a knowledge base.

**Não está, e é desenho:** a **biografia** do core — diário, análises, discussões, registro da
federação e materiais. Método viaja; história, não. A allowlist que decide isso é
\`.claude/utils/adopt/vendor-manifest.sh\`, e ela falha FECHADA: o que não está declarado não viaja.

## Como usar

\`\`\`bash
git clone https://github.com/marciocar/${_slug}.git
cd ${_slug} && claude
\`\`\`

Depois, \`/warm-up\` para o contexto e \`/onion\` para a orientação. As guardas rodam com
\`bash .claude/validation/lint-artifacts.sh\`.

## Licenças

**Código** (\`.claude/**\`, scripts): MIT — \`LICENSE\`.
**Documentação e doutrina** (\`docs/**\`): CC BY-NC 4.0 — \`LICENSE-DOCS\`.

---

Materializado do core no pin \`${_pin_ph}\` · papel \`${ROLE}\`.
README

cat > "${DEST}/CLAUDE.md" <<CLAUDEMD
# 🧅 Sistema Onion

Este repositório **é** o Onion: um framework de método executável em \`.claude/\`.

- **Comandos** em \`.claude/commands/\` por categoria · **agentes** em \`.claude/agents/<categoria>/\`
- **Guardas determinísticas** em \`.claude/validation/\` — rode \`bash .claude/validation/lint-artifacts.sh\`
- **Contagens canônicas** vivem em \`docs/onion/inventory.md\` (SSOT gerada do filesystem). Nunca
  edite os números à mão; rode \`/meta:inventory\`.

## Idioma

Chat, comentários, documentação e mensagens: **pt-BR**. Código, variáveis, nomes de arquivo e de
branch, e o prefixo Conventional dos commits: **inglês**.

## O que este repositório NÃO tem

É uma **projeção** do core: a biografia (diário, análises, discussões, registro da federação) não
viaja por desenho. Se um comando citar um documento marcado \`(core-only)\`, ele existe — no core
privado, e não aqui.
CLAUDEMD
echo "  (5) raiz da porta: README.md · CLAUDE.md · LICENSE · LICENSE-DOCS"

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
