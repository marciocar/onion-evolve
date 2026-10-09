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
# Uso : ops/materialize-door.sh <dir-destino> [--role hub|standalone|adopted] [--force-role-change]
#       --role default: hub (a porta leva a maquinaria COMPLETA, meta-fábrica
#       inclusa — decisão do maestro em 2026-09-16, coerente com a liberação da
#       meta-fábrica selada no mesmo dia).
# =============================================================================
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST=""; ROLE="hub"; SRC_REF=""; FORCE_ROLE_CHANGE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --role) ROLE="${2:-hub}"; shift 2 ;;
    --from) SRC_REF="${2:?--from exige uma ref}"; shift 2 ;;
    --from=*) SRC_REF="${1#--from=}"; shift ;;
    --role=*) ROLE="${1#--role=}"; shift ;;
    --force-role-change) FORCE_ROLE_CHANGE=1; shift ;;
    -h|--help) sed -n '1,40p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) DEST="$1"; shift ;;
  esac
done
[ -n "${DEST}" ] || { echo "ERRO: destino obrigatório. Uso: ops/materialize-door.sh <dir> [--role hub]" >&2; exit 2; }

# ── RECUSA: `--role` que CONTRADIZ o carimbo que a porta já tem ──────────────
# ⚠️ Esta é a PRIMEIRA linha de defesa do dano de 2026-09-30, e ela mora aqui porque foi aqui que o
# dano passou. O `members.yaml` dizia `role: standalone` para a `onion-core` enquanto o carimbo dela
# dizia `hub`; o operador leu a ANOTAÇÃO, rodou `--role standalone`, e a face PÚBLICA do core perdeu
# 85 arquivos de meta-fábrica (`adopt`, `create-*`, `federation-*`, `marketplace/`, `wizard/`,
# `skills/onion-publish/`) — publicados mutilados antes de alguém notar.
# A passada adversarial que forjou esta guarda mediu o ponto exato: o `ROLE` deste script é argumento
# com default `hub` e o script NUNCA lê o registro — logo nenhum lint de PR no core fica entre o
# operador e este comando. Só o próprio script pode recusar.
# É RECUSA, não correção automática: trocar o papel de uma porta é ato deliberado (muda o que ela
# distribui), então quem quiser trocar diz isso em voz alta com `--force-role-change`. O default
# protege o caso comum — re-materializar a porta como ela já é.
STAMP_NOW="${DEST}/.claude/.onion-version"
if [ -f "${STAMP_NOW}" ]; then
  ROLE_NOW="$(grep -m1 -E '^[[:space:]]*role:' "${STAMP_NOW}" \
              | sed 's/^[[:space:]]*role:[[:space:]]*//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//' || true)"
  if [ -n "${ROLE_NOW}" ] && [ "${ROLE_NOW}" != "${ROLE}" ] && [ "${FORCE_ROLE_CHANGE}" != "1" ]; then
    echo "ERRO: --role '${ROLE}' CONTRADIZ o carimbo desta porta, que diz '${ROLE_NOW}' (${STAMP_NOW})." >&2
    echo "      Materializar assim MUDA o que a porta distribui: em 2026-09-30 exatamente isto cortou 85" >&2
    echo "      arquivos de meta-fábrica da face PÚBLICA do core, porque o operador leu o members.yaml" >&2
    echo "      (anotado à mão) em vez do carimbo (escrito pela materialização anterior)." >&2
    echo "      · Para re-materializar como ela É:      ops/materialize-door.sh '${DEST}' --role ${ROLE_NOW}" >&2
    echo "      · Para TROCAR o papel de propósito:     ops/materialize-door.sh '${DEST}' --role ${ROLE} --force-role-change" >&2
    echo "      (e então alinhe o \`role:\` da porta no members.yaml, que a REGRA 92 confere)" >&2
    exit 2
  fi
fi

VM="${REPO_ROOT}/.claude/utils/adopt/vendor-manifest.sh"
[ -f "${VM}" ] || { echo "ERRO: SSOT do transporte ausente (${VM})" >&2; exit 3; }

# ── A FONTE É `origin/<integração>`, NUNCA O `HEAD` LOCAL ────────────────────
# Defeito medido 2026-09-25, e o raio é PÚBLICO. O script usava `git archive HEAD`
# e `rev-parse HEAD`; rodado a partir de uma branch de trabalho — que é o estado
# normal de quem acabou de abrir um PR — ele montava a porta com o conteúdo NÃO
# MERGEADO dessa branch e carimbava o pin com o SHA dela. Observado ao vivo: pin
# `5b3d30d0a9d3` (topo de um PR aberto) onde `main` estava em `06bc547c268c`.
# A doutrina do CLAUDE.md sempre disse que a porta é "projeção gerada de
# `origin/main`". Declarado ≠ implementado — a classe que esta casa mais persegue,
# aqui com a consequência mais cara: publicar código não revisado num repo público.
# O que impediu o dano foi a OUTRA fronteira, a de que o push é do maestro. Fronteira
# não é desculpa para a guarda faltante; é a razão de esta cura ser barata hoje.
# FAIL-CLOSED: sem conseguir resolver a ref remota, NÃO materializa. Uma porta que
# não sabe de onde nasce não deve nascer. `--from <ref>` existe para o caso
# deliberado (ensaio, bisect), e ele ANUNCIA que não é `origin/<integração>`.
_INTEG="$(bash "${REPO_ROOT}/.claude/validation/resolve-integration-branch.sh" "${REPO_ROOT}" 2>/dev/null || true)"
: "${_INTEG:=main}"
if [ -z "${SRC_REF}" ]; then
  git -C "${REPO_ROOT}" fetch -q origin "${_INTEG}" 2>/dev/null || true
  SRC_REF="origin/${_INTEG}"
  git -C "${REPO_ROOT}" rev-parse --verify --quiet "${SRC_REF}^{commit}" >/dev/null || {
    echo "ERRO: não consegui resolver '${SRC_REF}' — a porta é projeção da INTEGRAÇÃO mergeada, e eu não materializo do HEAD local por conveniência (ele pode ser uma branch de PR aberto, e isso publicaria código não mergeado num repo PÚBLICO). Rode \`git fetch origin ${_INTEG}\`, ou passe --from <ref> deliberadamente." >&2
    exit 3
  }
else
  git -C "${REPO_ROOT}" rev-parse --verify --quiet "${SRC_REF}^{commit}" >/dev/null || {
    echo "ERRO: --from '${SRC_REF}' não resolve para um commit." >&2; exit 3; }
  echo "  ⚠️  --from '${SRC_REF}': NÃO é origin/${_INTEG}. Materialização deliberada fora da integração — não publique sem saber por quê."
fi

echo "══ materialize-door — papel '${ROLE}' → ${DEST}"
echo "  fonte: ${SRC_REF} ($(git -C "${REPO_ROOT}" rev-parse --short=12 "${SRC_REF}"))"

# ── (1) MONTAR pelo manifesto ────────────────────────────────────────────────
# `git archive HEAD`, nunca cópia do disco: untracked e ignored NUNCA viajam,
# nem por engano. É a segunda barreira da allowlist.
mapfile -t SPEC < <(bash "${VM}" --role "${ROLE}" --repo "${REPO_ROOT}" 2>/dev/null)
if [ "${#SPEC[@]}" -eq 0 ]; then
  echo "ERRO: manifesto VAZIO para o papel '${ROLE}' — pathspec ausente significa TODOS para o git; abortando antes de copiar o repositório inteiro." >&2
  exit 3
fi
# ⚠️ DESTINO ANINHADO EM OUTRO REPO ⇒ RECUSA, **antes** de criar diretório ou extrair bundle.
# O passo (6-pre) staja o destino (`git add -A`) para que os geradores de projeção enxerguem a árvore
# materializada. Num destino DENTRO de outro repo o `rev-parse` resolve para o índice de FORA, e esse
# staging levaria a porta inteira para o índice do hospedeiro — efeito silencioso e caro. A recusa
# vem aqui, e não junto do staging, por uma razão medida em 2026-09-28: abortar depois do `mkdir`
# deixava um diretório untracked no hospedeiro, ou seja, a recusa já tinha sujado o que protegia.
# Porta legítima é clone PRÓPRIO — destino dentro de outro repo nunca é uma delas.
# ⚠️ A COMPARAÇÃO É CONTRA O CAMINHO ABSOLUTO DE **DEST**, nunca contra o do probe — e a 1ª versão
# errou exatamente isto: com DEST inexistente o probe cai no PAI, e comparar o toplevel do pai com o
# próprio pai dá igual SEMPRE, então a guarda nunca disparava no caso mais comum (destino novo dentro
# de um repo). Medido pelo mutante num hospedeiro SEM exclude de `.claude/worktrees/`: 630 arquivos
# da porta stajados no índice dele, com a guarda calada. O ambiente importa e está dito de propósito —
# a 1ª versão do caso de bancada citava este número medido num ambiente que ele não habitava.
_dest_parent="$(dirname "${DEST}")"
[ -d "${_dest_parent}" ] || { echo "ERRO: o diretório pai de ${DEST} não existe." >&2; exit 3; }
_dest_abs="$(cd "${_dest_parent}" && pwd -P)/$(basename "${DEST}")"
_dest_probe="${DEST}"; [ -d "${_dest_probe}" ] || _dest_probe="${_dest_parent}"
_host_top="$(git -C "${_dest_probe}" rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "${_host_top}" ] && [ "${_host_top}" != "${_dest_abs}" ]; then
  echo "ERRO: ${DEST} está DENTRO do repo ${_host_top} — a porta compartilharia o índice dele e o staging do passo (6) iria para o repo errado. Materialize a porta num clone próprio." >&2
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
git -C "${REPO_ROOT}" archive --format=tar "${SRC_REF}" -- "${SPEC[@]}" | tar -x -C "${DEST}" || {
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
_pin_ph="$(git -C "${REPO_ROOT}" rev-parse --short=12 "${SRC_REF}")"
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

# ── (6) A PORTA PRECISA SABER QUEM É, E TER AS PROJEÇÕES QUE AS PRÓPRIAS GUARDAS COBRAM ──────
# Os três achados vieram da 1ª sessão REAL dentro da porta (`/warm-up`, 2026-09-17) — não de mim:
#
#  (a) `onion-version.sh` respondia `role: source` NA PORTA. O fallback sem stamp é `source` por
#      desenho (repo-fonte não carrega stamp), e a porta não tinha stamp — então ela se
#      APRESENTAVA COMO A FONTE, contradizendo o próprio README que diz "PROJEÇÃO, não a fonte".
#      Identidade errada não é cosmética: comandos que decidem por papel (co-relay, adopt, publish)
#      passam a decidir errado.
#  (b) LINT DA PORTA: 41 HARD, 22 deles REGRA 45 (Link vendorizado não aponta caminho core-privado,
#      com catraca). O `--stub-baselines` esvazia o baseline — que é certo, o passivo do core não é
#      dívida do alvo — mas NINGUÉM o re-emitia do corpus da porta. Metade da cura entregue é cura
#      nenhuma: a porta nascia vermelha no próprio gate que ela distribui.
#  (c) `docs/onion/` não viaja (é biografia+projeção do core), mas as REGRAS 8 e 21 cobram
#      `inventory.md` e `graph.md` — e o CLAUDE.md que este script escreve MANDAVA lê-los. A porta
#      apontava para um arquivo que ela não tinha.
#
# Os três se curam com helpers que JÁ EXISTEM. Escrever um quarto seria a quarta cópia.
mkdir -p "${DEST}/.claude"
# ⚠️ STAMP ÚNICO (F1 das portas, SAC-89, 2026-10-09): aqui havia um heredoc PRÓPRIO, com outra
# gramática (`onion_version`/`materialized_at`) que a do `write-stamp.sh` (`source_commit`/
# `source_commit_date`/`framework`). Dois escritores do mesmo arquivo: o `pin-integrity-check` lia
# `pin-untrusted unknown` em toda porta (procura `source_commit`), e cada leitor novo tinha de saber
# qual dialeto a porta falava. O escritor é um só; `--kind door` diz que é projeção (role explícito,
# nada se herda, `materialized_at` em vez de `adopted_at`). Os leitores do campo antigo
# (`door-seal-pin.sh`) leem `source_commit` com fallback a `onion_version`, para as portas já
# publicadas no dialeto velho até a próxima materialização.
# `framework` = o NOME DA PORTA, não o do core: o core é privado e a porta é "sem biografia"; e é o que o
# `onion-version.sh` da própria porta responde (deriva do remote dela). Elenxo do PR da F1, O5.
_fw="${_slug}"
_pin_date="$(git -C "${REPO_ROOT}" log -1 --format=%cd --date=short "${SRC_REF}")"
bash "${REPO_ROOT}/.claude/utils/adopt/write-stamp.sh" "${DEST}" --kind door --role "${ROLE}" \
  --framework "${_fw}" --commit "${_pin_ph}" --commit-date "${_pin_date}" --adopted-from "${_slug}" >/dev/null \
  || { echo "ERRO: o write-stamp recusou o carimbo da porta (papel '${ROLE}')." >&2; exit 3; }
echo "  (6) carimbo de identidade: role=${ROLE}, kind=door, source_commit=${_pin_ph} (sem ele a porta se declara 'source')"

# `settings.json` NÃO está no manifesto — e é deliberado: ele carrega hooks e permissões da
# INSTÂNCIA, e um adotante não deve herdar as do core. Mas TRÊS docs que viajam o citam em
# backtick, e a REGRA 48 (Referência de caminho `.claude/…` em backtick (prosa) que não resolve)
# reprova ponteiro morto. O `/meta:adopt` resolve isso no passo (1) da Configuração pós-cópia, com
# MERGE never-clobber; a porta não tinha passo equivalente e nascia com 3 HARD.
# Aqui a cópia é DIRETA, e a diferença é de objeto: a porta não tem instância prévia a preservar —
# ela É a materialização. Never-clobber protegeria um estado que não existe.
if [ ! -f "${DEST}/.claude/settings.json" ] && [ -f "${REPO_ROOT}/.claude/settings.json" ]; then
  cp "${REPO_ROOT}/.claude/settings.json" "${DEST}/.claude/settings.json"
  echo "  (6) settings.json copiado (3 docs que viajam o citam; sem ele a REGRA 48 reprova ponteiro morto)"
fi

# ⚠️ O REGENERADOR PODE NAO TER VIAJADO — e procura-lo SO no destino era FAIL-OPEN SILENCIOSO.
# Medido em 2026-09-18 pela passada adversarial do PR #848: o manifesto do papel `standalone`
# EXCLUI `regen-ssot-projections.sh` e `regen-baselines.sh` (sao ferramenta core-only, e a exclusao
# esta CERTA — elas nao devem viajar). Mas o teste era `[ -f "${DEST}/..." ]`: no papel `standalone`
# o arquivo nunca esta la, o `if` falha, o `|| true` cala, o script sai rc=0 dizendo materializado —
# e a porta nasce PUBLICADA com 8 HARD em vez de 4. O papel `hub` escapava por acidente de manifesto
# (la o arquivo viaja), que e a pior forma de um gate funcionar: por coincidencia, num caminho so.
# A CURA NAO E FAZER A FERRAMENTA VIAJAR — e roda-la do CORE contra o DESTINO, que e o que ela
# sempre soube fazer (ela recebe o alvo como argumento). E se nao houver nenhuma das duas, a guarda
# DECLARA em vez de seguir calada: materializacao que nao regenerou projecao entrega porta que
# reprova no proprio lint, e quem publica precisa saber disso ANTES do push.
_regen() {                                        # _regen <nome-do-script> <como-cortar-a-saida>
  local _n="$1" _cut="${2:-cat}" _src=""
  if   [ -f "${DEST}/.claude/utils/adopt/${_n}" ];      then _src="${DEST}/.claude/utils/adopt/${_n}"
  elif [ -f "${REPO_ROOT}/.claude/utils/adopt/${_n}" ]; then _src="${REPO_ROOT}/.claude/utils/adopt/${_n}"
  else
    echo "  (6) ⚠️ ${_n} AUSENTE no destino E no core — projecoes NAO regeneradas." >&2
    echo "  (6)    A porta vai nascer reprovando no proprio lint. Isto NAO e 'pulado': e nao-medido." >&2
    return 1
  fi
  bash "${_src}" "${DEST}" 2>&1 | ${_cut} | sed 's/^/  (6) /'
  return 0
}
# ⚠️ (6-pre) O ÍNDICE DO DESTINO TEM DE REFLETIR A ÁRVORE MATERIALIZADA — **antes** de regenerar.
# Dois dos geradores de projeção SSOT (`harness-inventory.sh` → testing-inventory.md, e
# `testing-state.sh`, que depende dele) enumeram o conjunto RASTREADO (`git ls-files`), não o disco.
# Isso é deliberado e é a cura de um defeito anterior: contar o disco enumeraria um conjunto
# diferente do que o CI vê. Mas o corolário nunca foi cumprido aqui — eles precisam de um índice
# que já contenha o que acabou de ser materializado, e o único `git add -A` deste script era uma
# INSTRUÇÃO impressa ao humano, executada DEPOIS.
# Duas quebras, ambas medidas em 2026-09-28:
#   · num clone real (o caminho de produção) eles contavam a versão ANTERIOR da porta — projeção
#     nasce defasada e CALADA, porque não-vazia;
#   · num destino que ainda não é repo eles RECUSAM (corretamente: "zero NÃO é resultado"), e o
#     regenerador segue e sai 0 com 3 de 5, apenas IMPRIMINDO "saída VAZIA" — a porta sai com 2
#     projeções faltando e rc=0 dizendo
#     "Porta materializada". `onion-standalone` está publicada assim, sem testing-inventory.md nem
#     testing-state.md, e o caso de bancada `door: (f)` ficou vermelho ao expor isto.
# A cura é de ORDEM, não de tolerância: stajar aqui, e o `git add -A` do humano segue existindo
# (idempotente) para capturar as projeções que ESTE passo acabou de escrever.
# O aninhamento já foi recusado lá atrás, antes de existir diretório — aqui só resta o caso legítimo:
# destino que é (ou passa a ser) repo próprio. `init -b main` porque o remoto da porta é `main` e o
# `init.defaultBranch` desta máquina não está setado: sem `-b`, o caminho greenfield — justamente o
# que este `init` existe para cobrir — nasceria em `master`.
# ⚠️ FAIL-CLOSED nos dois: `set -e` não está ligado neste script, então um `add -A` que falha (índice
# travado, permissão, disco) deixaria os geradores contarem o índice DEFASADO e o script declararia
# "Porta materializada" com rc=0. Medido pela passada adversarial de 2026-09-28 com um `index.lock`
# plantado: `testing-inventory.md` saiu dizendo 75 scripts com 74 no disco, e rc=0. É
# `exit-code-nao-e-a-verificacao` aplicado à própria cura — por isso a recusa é explícita.
if ! git -C "${DEST}" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "${DEST}" init -q -b main \
    || { echo "ERRO: 'git init' no destino FALHOU — sem índice, as projeções SSOT não podem ser geradas." >&2; exit 3; }
fi
# ÍNDICE DO DONO: o passo (0) já apaga do disco, mas o índice do destino era a última rede de um
# trabalho stajado-e-não-commitado de quem publica a porta. Avisar é o mínimo honesto.
_dono_stajado="$(git -C "${DEST}" diff --cached --name-only 2>/dev/null | grep -c . || true)"
if [ "${_dono_stajado}" -gt 0 ]; then
  echo "  (6) ⚠️ o índice do destino já tinha ${_dono_stajado} caminho(s) stajado(s) vs HEAD — a materialização vai reescrevê-lo." >&2
fi
git -C "${DEST}" add -A \
  || { echo "ERRO: 'git add -A' no destino FALHOU — as projeções contariam o índice DEFASADO. Recusa antes de gerar." >&2; exit 3; }

_regen regen-ssot-projections.sh || true
# As catracas do core foram esvaziadas no passo (2); aqui elas renascem do corpus DA PORTA.
_regen regen-baselines.sh 'tail -2' || true

# ── (6-pos) RE-STAJAR, e CONFERIR O EFEITO — as duas metades que faltavam ────────────────────────
# (i) O `add -A` de cima roda logo depois de o passo (0) apagar `docs/onion/` (que não viaja no
#     manifesto), então ele staja a REMOÇÃO das 5 projeções; os geradores as reescrevem DEPOIS, como
#     untracked. Quem publica com `git add -A; git commit` (o caminho impresso abaixo) não sente. Quem
#     usa `git commit -am` — plausível em 18 re-materializações — publicaria a porta com ZERO
#     projeções. Medido em 2026-09-28: de "2 faltando" para "5 faltando", e MUDO, porque os arquivos
#     estão no disco. Estritamente pior que o defeito curado, e introduzido pela cura.
# (ii) `exit 0` do regenerador é declaração dele sobre si: ele sai 0 com 3 de 5 projeções e apenas
#      IMPRIME "saída VAZIA". Não há `|| true` engolindo nada — o defeito original foi um aviso
#      IGNORADO, não engolido. Verificar é CONTAR o que ele produziu.
git -C "${DEST}" add -A \
  || { echo "ERRO: 'git add -A' final FALHOU — as projeções regeneradas ficariam FORA do commit da porta." >&2; exit 3; }
_faltam=""
for _proj in docs/onion/inventory.md docs/onion/graph.md docs/onion/kg-read-index.tsv \
             docs/onion/testing-inventory.md docs/onion/testing-state.md; do
  [ -s "${DEST}/${_proj}" ] || _faltam="${_faltam} ${_proj}"
done
if [ -n "${_faltam}" ]; then
  echo "ERRO: a porta ficaria SEM projeção SSOT:${_faltam}" >&2
  echo "       Publicá-la assim entrega porta que reprova no próprio lint (REGRAS 8/21/39/80/81)." >&2
  exit 3
fi

_pin="$(git -C "${REPO_ROOT}" rev-parse --short=12 "${SRC_REF}")"
cat <<FIM

✅ Porta materializada em ${DEST} (papel '${ROLE}', pin ${_pin})

   O PUSH É SEU — o script para aqui por desenho (I3: um escritor por repo, e
   publicar é ato outward-facing). No destino:

     cd ${DEST} && git add -A
     git commit -m "chore(door): materializa do core no pin ${_pin}"
     git push

   E DEPOIS DO PUSH, carimbe o registro — é o passo que faltava até 2026-09-26:

     bash ops/door-seal-pin.sh ${_slug}

   Ele confere o REMOTO pelo forge e só carimba se bater; sem isso o
   \`onion_version\` do members.yaml fica atrás, e a REGRA 85 passa a medir a
   MEMÓRIA em vez da porta (aconteceu duas vezes num dia). O baseline de
   defasagem segue manual, por decisão do maestro.

   E lembre do ciclo: porta sem re-materialização envelhece. O gatilho é toda
   leva mergeada em main que toque a superfície que viaja.
FIM
