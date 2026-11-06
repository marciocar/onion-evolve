# shellcheck shell=bash
# kgssot-tools.sh — o resolver ÚNICO da pasta das ferramentas do KG-SSOT (kg_validate.py, kg_trace.py,
# kg_query.py, kg_gate.py, kg_vocab.py, kg_criterion.py, requirements.txt…). Fonte para `source`, não executável.
#
# Por que existe (2026-11-06). Catorze arquivos de .claude/validation fixavam `vendor/kg-ssot/tools/`. Isso vale
# no core e nos adotantes, que vendorizam o produto, mas NÃO no próprio repo do KG-SSOT: lá as ferramentas
# moram em `tools/` e `vendor/kg-ssot` não existe, então toda dissecação de lá saía rc 3 ("não medi"), sinal de
# campo da sessão do kg-ssot medido pela sessão principal. Dois sítios já tinham remendado o `tools/` à mão
# (kg-decide-seal, kg-projection), cada um do seu jeito; os outros doze não. É CLASSE, e a cura é um lugar só.
#
# A ORDEM (declarada; a proposta do kg-ssot era vendor → tools → variável):
#   1. KG_SSOT_TOOLS, se definida e for uma pasta existente — o override explícito vem PRIMEIRO, como no padrão
#      de mercado (variável de ambiente vence o descoberto: PYTHONPATH, GIT_DIR, CARGO_HOME, os 12 fatores). Na
#      última posição ela nunca valeria onde o vendor existe, e o override que não sobrepõe não é override;
#   2. <raiz>/vendor/kg-ssot/tools — o caminho de hoje (core e adotantes), em 2º para nada mudar onde ele existe;
#   3. <raiz>/tools — só quando <raiz>/spec/release.json declara uma tag `kg-ssot-v*`, isto é, a raiz É o produto.
#      Uma pasta tools/ qualquer não basta: num adotante ela seria de outra coisa.
# Nada casou: devolve VAZIO, e o chamador segue no caminho e no rc de hoje (o "não medi" declarado). Variável
# definida mas inexistente cai para o passo 2, sem calar: KGSSOT_TOOLS_WHY diz que ela foi ignorada.
# O espelho python (kgssot_tools.py, ao lado) implementa a MESMA ordem; a bancada mede os dois contra as mesmas
# fixtures. Os overrides por ferramenta que já existiam (ONION_KG_TRACE, ONION_KG_QUERY,
# ONION_KG_INTEGRITY_VALIDATOR, ONION_KG_DUE_VALIDATOR, KG_CONTRACT_VENDOR) seguem vencendo este resolver.
#
# API:
#   kgssot_tools_resolve <raiz>   preenche KGSSOT_TOOLS (pasta, sem barra final, ou vazio), KGSSOT_TOOLS_KIND
#                                 (env | vendor | source | vazio) e KGSSOT_TOOLS_WHY; rc 0 achou, 1 não achou.
#                                 Roda no shell atual (sem subshell), para o chamador ler o KIND.
#   kgssot_tools_dir <raiz>       imprime só a pasta (ou nada); rc igual. Para `$(…)`.

_kgssot_is_source_root() {  # <raiz>: rc 0 quando spec/release.json da raiz declara "tag": "kg-ssot-v…"
  local rel="$1/spec/release.json"
  [ -f "${rel}" ] || return 1
  LC_ALL=C command grep -Eq '"tag"[[:space:]]*:[[:space:]]*"kg-ssot-v[0-9]' "${rel}" 2>/dev/null
}

kgssot_tools_resolve() {
  local root="${1:-.}"
  KGSSOT_TOOLS=""; KGSSOT_TOOLS_KIND=""; KGSSOT_TOOLS_WHY=""
  root="${root%/}"; [ -n "${root}" ] || root="/"
  if [ -n "${KG_SSOT_TOOLS:-}" ]; then
    if [ -d "${KG_SSOT_TOOLS}" ]; then
      KGSSOT_TOOLS="${KG_SSOT_TOOLS%/}"; KGSSOT_TOOLS_KIND="env"; return 0
    fi
    KGSSOT_TOOLS_WHY="KG_SSOT_TOOLS=${KG_SSOT_TOOLS} não é uma pasta: ignorada"
  fi
  if [ -d "${root}/vendor/kg-ssot/tools" ]; then
    KGSSOT_TOOLS="${root}/vendor/kg-ssot/tools"; KGSSOT_TOOLS_KIND="vendor"; return 0
  fi
  if [ -d "${root}/tools" ] && _kgssot_is_source_root "${root}"; then
    KGSSOT_TOOLS="${root}/tools"; KGSSOT_TOOLS_KIND="source"; return 0
  fi
  KGSSOT_TOOLS_WHY="${KGSSOT_TOOLS_WHY:+${KGSSOT_TOOLS_WHY}; }nem KG_SSOT_TOOLS, nem ${root}/vendor/kg-ssot/tools, nem ${root}/tools com spec/release.json do kg-ssot"
  return 1
}

kgssot_tools_dir() {
  local KGSSOT_TOOLS KGSSOT_TOOLS_KIND KGSSOT_TOOLS_WHY
  kgssot_tools_resolve "$@" || return 1
  printf '%s\n' "${KGSSOT_TOOLS}"
}
