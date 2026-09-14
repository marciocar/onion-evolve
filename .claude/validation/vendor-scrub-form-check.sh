#!/usr/bin/env bash
# vendor-scrub-form-check.sh — nome comercial na superfície vendorizada, detectado por FORMA.
#
# Uso : vendor-scrub-form-check.sh [REPO] | --emit-baseline | --selftest
# Saída: <rel>|<termo> por candidato, um por linha. Exit 0 sempre (quem julga é a REGRA 36).
#
# ══ O BURACO QUE ESTE SCRIPT FECHA ════════════════════════════════════════════════════════════
# A REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) deriva os termos do
# `members.yaml` — e isso é certo, porque nome hardcoded num script É o próprio vazamento. Mas tem
# um preço medido: **cliente que nunca foi registrado é invisível para ela**. Em 2026-09-14 a
# medição achou o nome de um cliente real de PoC em DOIS arquivos que viajam para todo adotante, e a guarda
# nunca cobrou — o termo jamais foi derivado porque o cliente não está no `members.yaml`.
# É a classe `guarda-por-lista-falha-pelo-vocabulário`: em guarda de lista, o defeito dominante é o
# VOCABULÁRIO, não a lógica. A cura é a mesma de sempre — **assere a FORMA, não a lista**.
#
# ══ AS DUAS FORMAS, E POR QUE SÓ ESTAS ════════════════════════════════════════════════════════
# (A) AMPERSAND CORPORATIVO: `Acme&Co`, `Baker&Sons`. Empresa usa `&` no nome; prosa técnica quase não.
#     As siglas legítimas do ofício (M&A, Q&A, V&V, R&D) são 1 letra de cada lado — o padrão exige
#     pelo menos um lado com 2+ caracteres, e isso sozinho elimina o grosso do ruído.
# (B) ÂNCORA DE CONTEXTO: `PoC <Nome>`, `cliente <Nome>`, `adotante <Nome>`. A palavra que antecede
#     é que denuncia — nome próprio ali é quase sempre cliente real.
# Fora daqui é campo aberto demais: qualquer palavra capitalizada viraria candidata e a guarda
# morreria de falso-positivo. Teto declarado: nome comercial SEM `&` e SEM âncora não é visto.
#
# ══ CATRACA, PORQUE FORMA GERA CANDIDATO, NÃO VEREDITO ════════════════════════════════════════
# Candidato legítimo existe (sigla do ofício, nome fictício de exemplo, citação acadêmica). Vai para
# o baseline, que SÓ ENCOLHE. Candidato novo = HARD. É o mesmo idioma das REGRAS 45 e 49.
set -uo pipefail

MODE="${1:-scan}"
case "${MODE}" in --emit-baseline|--selftest) ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)" ;;
  *) ROOT="$([ -d "${MODE}" ] && (cd "${MODE}" && pwd) || (git rev-parse --show-toplevel 2>/dev/null || pwd))"; MODE=scan ;; esac

_vm="${ROOT}/.claude/utils/adopt/vendor-manifest.sh"
_roots=()
if [ -f "${_vm}" ]; then
  while IFS= read -r _r; do [ -n "${_r}" ] && _roots+=("${_r}"); done < <(bash "${_vm}" --emit-scrub-roots 2>/dev/null || true)
fi
[ "${#_roots[@]}" -gt 0 ] || { echo "ERRO: superfície vendorizada não resolvida (vendor-manifest.sh)" >&2; exit 2; }

_targets=(); for _r in "${_roots[@]}"; do [ -e "${ROOT}/${_r}" ] && _targets+=("${ROOT}/${_r}"); done
[ "${#_targets[@]}" -gt 0 ] || exit 0

# (A) ampersand corporativo — pelo menos um lado com 2+ caracteres
_PAT_AMP='[A-Za-z0-9]{2,}&[A-Za-z0-9]+|[A-Za-z0-9]+&[A-Za-z0-9]{2,}'
# (B) âncora de contexto seguida de nome próprio.
#
# ⚠️ A 1ª REDAÇÃO PERDIA METADE DO VAZAMENTO QUE A MOTIVOU, e só a passada adversarial viu.
# O texto real tinha DUAS partes: uma sigla com ampersand e um nome em CAIXA ALTA mais um
# substantivo — algo com a forma `PoC XY&Z / ABC Nome`. O ampersand pegava a primeira; a âncora
# NÃO pegava a segunda, na mesma frase e no mesmo identificador, porque o padrão exigia
# `[A-Z][a-z]` e a sigla é toda maiúscula. Se o cliente se chamasse só pela segunda metade, a
# guarda nasceria cega para o próprio caso que a criou. Junto caíam: `cliente da Xyz` (preposição
# entre âncora e nome), `adotante: Xyz` (dois-pontos), e `PoC Itaú` — onde o acento truncava a
# chave em `Ita` sob LC_ALL=C, e tolerar `Ita` passa a tolerar `Itamar` no mesmo arquivo.
# Fixture de 8 linhas: 1 pega.
# (o identificador do cliente NÃO se repete aqui — este arquivo VIAJA, e a guarda cobra isto de
#  si mesma: a 1ª versão deste comentário citava o nome real e o próprio detector o acusou)
#
# O que mudou, e o preço de cada mudança:
#   · CONECTOR OPCIONAL (`da|de|do|:|-`) entre a âncora e o nome — cobre `cliente da Acme`.
#   · CAIXA ALTA só com SEGUNDO TOKEN em forma de nome (`HPE Autos`, `IBM Brasil`). A 1ª tentativa
#     de cura aceitou caixa alta SOZINHA e o repo saltou de 9 para 36 candidatos — 27 deles ênfase
#     de prosa desta casa (`adotante NÃO registrado`, `cliente NUNCA`, `empresa SEM`).
#     Baseline inchado é catraca sem sinal, então o segundo token é o que separa sigla comercial
#     de grito de prosa: `HPE Autos` passa, `NÃO REGISTRADO` não (o 2º token também é caixa alta).
#   · SEGUNDO TOKEN opcional depois de um nome normal (`Prodfiel Sistemas`), para não cortar o
#     sobrenome comercial ao meio.
#   · `[[:alpha:]]` em vez de `[A-Za-z]` no corpo do nome; com `LC_ALL=C` isso não resolve acento
#     sozinho, então o scan roda em UTF-8 (ver `_scan`) e `Itaú` chega inteiro.
# TETO QUE PERMANECE, e agora está medido em vez de suposto:
#   · nome comercial SEM ampersand e SEM âncora nenhuma continua invisível;
#   · SIGLA SOZINHA depois da âncora (`cliente IBM`) NÃO é vista — ela é
#     indistinguível de ênfase de prosa, e admiti-la custou 27 falsos-positivos numa medição real.
#     Quem escrever `cliente IBM` num arquivo que viaja passa; quem escrever `cliente IBM Brasil`
#     não. É um furo consciente, e o preço de fechá-lo era matar a guarda de ruído.
_PAT_NOME='[A-Z][[:lower:]][[:alnum:]]*([[:space:]]+[A-Z][[:lower:]][[:alnum:]]*)?'
_PAT_SIGLA='[A-Z][A-Z0-9]+[[:space:]]+[A-Z][[:lower:]][[:alnum:]]*'
_PAT_CTX="(PoC|POC|[Cc]liente|[Aa]dotante|[Ee]mpresa)[[:space:]]*(:|-)?[[:space:]]*(da|de|do|das|dos)?[[:space:]]*(${_PAT_SIGLA}|${_PAT_NOME})"

_scan() {
  # ⚠️ LOCALE UTF-8, E ISTO É DELIBERADO — a casa roda tudo em LC_ALL=C, esta guarda é a exceção.
  # Medido 2026-09-14: sob C, `[[:alnum:]]` casa BYTE, então `PoC Itaú` virava o candidato `Ita` —
  # e tolerar `Ita` no baseline passa a tolerar `Itamar`/`Itaipu` no mesmo arquivo, que é catraca
  # furada. Nome comercial brasileiro tem acento; a guarda tem de ler caractere, não byte.
  local _LC=C.UTF-8; locale -a 2>/dev/null | grep -qix 'C.utf-\?8' || _LC=en_US.UTF-8
  # entidade HTML, URL e operador de shell NÃO são nome de empresa — e o `docs/sdaal/index.html`
  # sozinho traria centenas de `&quot;` se isto faltasse.
  # O PRÓPRIO BASELINE está sob .claude/validation e, portanto, dentro da superfície varrida — sem
  # esta exclusão ele se cita e todo termo tolerado renasce como candidato NOVO num caminho diferente
  # (medido na 1ª execução: 8 HARD, todas o baseline acusando a si mesmo).
  # ⚠️ A exclusão casa o BASENAME em qualquer diretório, então um arquivo plantado como
  # `.claude/skills/vendor-scrub-form-baseline.txt` seria um ponto cego. Ancorada no caminho real.
  LC_ALL="${_LC}" grep -rInIE "${_PAT_AMP}|${_PAT_CTX}" "${_targets[@]}" 2>/dev/null \
    | grep -v "^${ROOT}/\.claude/validation/vendor-scrub-form-baseline\.txt:" \
    | grep -vE '&(quot|amp|lt|gt|nbsp|apos|#[0-9]+);|https?://|&&|\|\||\$\{' \
    | while IFS= read -r line; do
        local_file="${line%%:*}"; rest="${line#*:}"; rest="${rest#*:}"
        while IFS= read -r t; do
          [ -n "${t}" ] || continue
          printf '%s|%s\n' "${local_file#${ROOT}/}" "${t}"
        done < <(LC_ALL="${_LC}" grep -oE "${_PAT_AMP}" <<< "${rest}" || true)
        # só o NOME, nunca a âncora: `cliente da Acme` reporta `Acme`. O `sed` acompanha o padrão
        # (conector e pontuação opcionais) — se ele ficar para trás, a âncora entra na chave da
        # catraca e o mesmo nome em duas frases vira dois candidatos distintos.
        while IFS= read -r t; do
          [ -n "${t}" ] || continue
          printf '%s|%s\n' "${local_file#${ROOT}/}" "${t}"
        done < <(LC_ALL="${_LC}" grep -oE "${_PAT_CTX}" <<< "${rest}" 2>/dev/null \
                 | sed -E 's/^(PoC|POC|[Cc]liente|[Aa]dotante|[Ee]mpresa)[[:space:]]*(:|-)?[[:space:]]*(da|de|do|das|dos)?[[:space:]]*//' || true)
      done | sort -u
  # CONTRATO: exit 0 SEMPRE (quem julga é a REGRA 36). Sob `pipefail`, um `grep` sem casamento
  # devolveria 1 e o script sairia 1 com saída vazia — medido, e hoje mascarado só porque o
  # cabeçalho deste arquivo se auto-incrimina com os exemplos. Limpar os exemplos armaria a bomba.
  return 0
}

if [ "${MODE}" = "--selftest" ]; then
  # ⚠️ ESTE SELFTEST CHAMA `_scan`, e a 1ª versão NÃO chamava — ela re-implementava o `grep` inline.
  # Medido na passada adversarial de 2026-09-14: substituir o corpo de `_scan` por `return 0`
  # deixava a PRODUÇÃO CEGA e o selftest VERDE. Teste que mede uma réplica não mede o artefato;
  # classe [[bancada-espelha-o-runner]]. Agora ele redireciona os alvos para o sandbox e exerce o
  # caminho real — inclusive o `sed` da âncora e o locale UTF-8.
  d="$(mktemp -d)"; mkdir -p "${d}/x"
  printf 'nada aqui\nM&A e Q&A sao siglas\nQ&A e V&V tambem\n' > "${d}/x/ok.md"
  printf 'a PoC Acme&Co foi medida\n' > "${d}/x/leak.md"
  # o caso que a 1ª redação PERDIA: caixa alta, segundo token, conector e acento
  printf 'MEDIDO na PoC HPE Autos em campo\ncliente da Zelda\nadotante: Prodfiel Sistemas\nPoC Itau Digital\nadotante NAO registrado\ncliente NUNCA visto\n' > "${d}/x/hard.md"
  ROOT="${d}"; _targets=("${d}/x")
  out="$(_scan)"
  _miss=""
  for _w in 'Acme&Co' 'HPE Autos' 'Zelda' 'Prodfiel Sistemas' 'Itau Digital'; do
    grep -qF "|${_w}" <<< "${out}" || _miss="${_miss} ${_w}"
  done
  _false=""; grep -q 'ok\.md' <<< "${out}" && _false="ok.md (sigla do ofício virou candidato)"
  rm -rf "${d}"
  if [ -z "${_miss}" ] && [ -z "${_false}" ]; then
    echo "vendor-scrub-form selftest: OK (pega ampersand, caixa alta, 2º token, conector e acento; cala em M&A/Q&A/V&V)"; exit 0
  fi
  echo "vendor-scrub-form selftest: FALHOU — não pegou:${_miss:-(nada)} · falso-positivo: ${_false:-(nenhum)}" >&2
  echo "saída do _scan: [${out}]" >&2; exit 1
fi

if [ "${MODE}" = "--emit-baseline" ]; then
  printf '# Baseline de CANDIDATOS por forma na superfície vendorizada — PASSIVO TOLERADO.\n'
  printf '# Gerado por: bash .claude/validation/vendor-scrub-form-check.sh --emit-baseline > .claude/validation/vendor-scrub-form-baseline.txt\n'
  printf '# formato: <rel>|<termo>. SÓ PODE ENCOLHER. Candidato NOVO = HARD.\n'
  printf '# Legítimos aqui: sigla do ofício (M&A, Q&A, V&V), nome FICTÍCIO de exemplo, citação acadêmica.\n'
  printf '# Nome de cliente REAL não se tolera: remove-se do texto.\n'
  _scan
  exit 0
fi

_scan
