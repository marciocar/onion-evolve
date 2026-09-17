#!/usr/bin/env bash
# regen-ssot-projections.sh — regenera no ALVO as projeções SSOT que o lint vendorizado exige.
#
# Uso: regen-ssot-projections.sh <DEST>
#
# ══ POR QUE EXISTE ════════════════════════════════════════════════════════════════════════════
# `docs/onion/inventory.md` (REGRA 8) e `docs/onion/graph.md` (REGRA 21) são SSOTs GERADAS do
# filesystem, e o hook nativo recém-instalado bloqueia o 1º commit do adotante sem elas. Os
# geradores vendorizados são a autoridade; ROOT = o repo do alvo. Determinístico, sem LLM,
# idempotente.
#
# ⚠️ O `mkdir` NÃO É DETALHE — medido em 2026-09-15. Sem o diretório, o redirecionamento falha com
# "No such file or directory", o `|| true` ENGOLE o rc, e o arquivo NUNCA EXISTE, em silêncio. O
# alvo nascia com HARD da REGRA 8. E o mais instrutivo: o bullet da Fase 3 do adopt TINHA o mkdir,
# o bloco shell da Configuração pós-cópia NÃO tinha — o adotante nascia verde ou vermelho conforme
# QUAL METADE do documento o operador seguisse. Guarda cujo resultado depende de qual parágrafo se
# leu não é guarda. Este helper é a segunda metade da cura: uma implementação, um comportamento.
#
# ⚠️ O `|| true` FICA, e é deliberado: gerador que falha por ambiente do alvo (jq ausente, por ex.)
# não pode abortar a adoção inteira — o lint do alvo cobra depois, com mensagem própria. O que
# mudou é que agora a falha não é MANUFATURADA por diretório ausente.
set -uo pipefail

DEST="${1:?uso: regen-ssot-projections.sh <DEST>}"
[ -d "${DEST}" ] || { echo "ERRO: alvo inexistente: '${DEST}'" >&2; exit 2; }

# ⚠️ FAIL-LOUD, e ele entrou porque a 1ª versão MENTIA VERDE — medido 2026-09-15 na passada
# adversarial: com `docs/onion` existindo como ARQUIVO, ou com os dois geradores ausentes, o helper
# imprimia `✓ 0 projeção(ões)` e saía 0. Anunciava sucesso tendo gerado nada, e o alvo nascia
# vermelho enquanto a adoção reportava verde. É a MESMA classe que o docstring acima diz curar (o
# `|| true` engolindo o rc): a 1ª cura tratou só o caso ENOENT, não a classe.
# O irmão `emit-licenses.sh`, neste mesmo diretório, já fazia o certo (`exit 3` sem emissão).
mkdir -p "${DEST}/docs/onion" || { echo "ERRO: não consegui criar '${DEST}/docs/onion' (existe como arquivo?)" >&2; exit 3; }
[ -d "${DEST}/docs/onion" ] || { echo "ERRO: '${DEST}/docs/onion' não é diretório" >&2; exit 3; }

# O índice de leitura do KG não usa `--markdown` (é TSV) nem vive sob o mesmo molde, então
# sai do laço — mas pertence à mesma lista por natureza: projeção GERADA com catraca no lint.
if [ -f "${DEST}/.claude/validation/kg-trace-resolve.sh" ]; then
  _idx="$(bash "${DEST}/.claude/validation/kg-trace-resolve.sh" "${DEST}" --emit-index 2>/dev/null || true)"
  # Só escreve se veio conteúdo: índice vazio faria o hook da perna de leitura ficar calado
  # para o corpus inteiro, e calado é indistinguível de "não há grafo" (REGRA 84).
  [ -n "${_idx}" ] && printf '%s\n' "${_idx}" > "${DEST}/docs/onion/kg-read-index.tsv"
fi

_n=0 _vazias=""
# ⚠️ A LISTA ERA CURTA DEMAIS, e o preço foi medido em 2026-09-16: `testing-state.md` (REGRA 81)
# ficou de fora e a catraca reprovou o CI QUATRO VEZES no mesmo dia, sempre pela mesma causa — eu
# regenerava o painel numa branch, abria outra a partir de main e ele nascia defasado de novo.
# Quatro repetições da mesma correção é a definição de defeito que devia ser mecanismo: a doutrina
# desta casa diz que erro recorrente vira REGISTRO com cura anexada, não disciplina de quem lembra.
# Toda projeção GERADA que tenha catraca no lint pertence a esta lista — quem acrescentar uma guarda
# de projeção nova e esquecer daqui vai pagar o mesmo pedágio.
# ⚠️ 2ª AMPLIAÇÃO NO MESMO DIA, e a recorrência é o achado. Hoje de manhã acrescentei
# `testing-state.md` depois de a REGRA 81 reprovar QUATRO vezes; à noite a REGRA 80 reprovou pelo
# mesmo motivo com `testing-inventory.md`, que eu também não tinha posto. Curar UM item de uma
# lista que devia ser completa é curar o caso, não a classe — e a classe cobra de novo no mesmo dia.
# ⚠️ 3ª AMPLIAÇÃO — E O CRITÉRIO EM PROSA NÃO IMPEDIU (2026-09-17). A linha abaixo dizia "para não
# haver terceira", e houve: `lint-rules.md` (REGRA 39) é projeção gerada com catraca no lint e não
# estava aqui — a REGRA 86 entrou no registro e o gate reprovou pelo MESMO motivo, terceira vez.
# O que isso ensina não é sobre esta lista, é sobre CRITÉRIO ESCRITO: ele descreve o dever e não o
# executa. A cura de verdade é a bancada `regen_completude`, que DERIVA o conjunto esperado das
# próprias mensagens do lint (toda violação que diz "regenere: bash .claude/validation/<gen>" nomeia
# um par projeção↔gerador) e reprova quando um par não é coberto por este script. Lista conferida
# por máquina, nunca por quem lembrou.
# CRITÉRIO: TODA projeção gerada com catraca no lint pertence a esta lista.
# Hoje são cinco (REGRAS 8, 21, 39, 80, 81) mais o índice de leitura (REGRA 84, fora do laço por ser TSV).
for _pair in "inventory.sh:inventory.md" "graph.sh:graph.md" "testing-state.sh:testing-state.md" "harness-inventory.sh:testing-inventory.md"; do
  _gen="${_pair%%:*}"; _out="${_pair##*:}"
  [ -f "${DEST}/.claude/validation/${_gen}" ] || continue
  bash "${DEST}/.claude/validation/${_gen}" --markdown > "${DEST}/docs/onion/${_out}" 2>/dev/null || true
  if [ -s "${DEST}/docs/onion/${_out}" ]; then
    _n=$((_n + 1))
  else
    # ⚠️ ARQUIVO 0-BYTE NÃO FICA NO DISCO: ele faz o alvo colher HARD da REGRA 8 (inventário
    # desatualizado vs filesystem) enquanto o relatório aqui some com a linha. Remover é honesto —
    # ausente é um estado que a guarda do alvo sabe nomear; vazio, ela lê como drift.
    rm -f "${DEST}/docs/onion/${_out}"
    _vazias="${_vazias} ${_out}"
  fi
done

# `lint-rules.md` fica FORA do laço por duas diferenças de forma, não por ser menos importante:
# ele nasce em `.claude/validation/` (não em `docs/onion/`) e o gerador não toma `--markdown`.
if [ -f "${DEST}/.claude/validation/rules-registry.sh" ]; then
  _lr="$(bash "${DEST}/.claude/validation/rules-registry.sh" 2>/dev/null)" || _lr=""
  if [ -n "${_lr}" ]; then
    printf '%s\n' "${_lr}" > "${DEST}/.claude/validation/lint-rules.md"; _n=$((_n + 1))
  else
    _vazias="${_vazias} lint-rules.md"   # NÃO sobrescreve com vazio: o registro bom vale mais que um 0-byte
  fi
fi

# ⚠️ O `|| true` do laço FICA (gerador que falha por ambiente do alvo não derruba a adoção — o lint
# de lá cobra depois, com mensagem própria). O que NÃO pode é ESTE script declarar sucesso sem ter
# produzido nada: zero projeções com geradores presentes é falha de ambiente, e falha em silêncio é
# o que fez o adotante nascer vermelho com a adoção dizendo verde.
if [ "${_n}" -eq 0 ]; then
  echo "ERRO: nenhuma projeção SSOT gerada em '${DEST}/docs/onion' — o alvo vai nascer com HARD das REGRAS 8/21 (geradores ausentes ou saída vazia:${_vazias:- —})" >&2
  exit 3
fi
[ -z "${_vazias}" ] || echo "  ⚠️ saída VAZIA (arquivo removido, o alvo cobrará):${_vazias}" >&2
echo "  ✓ ${_n} projeção(ões) SSOT regenerada(s) no alvo (docs/onion/)"
