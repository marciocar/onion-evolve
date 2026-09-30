#!/usr/bin/env bash
# ===========================================================================
# door-role-parity-check.sh — o `role:` do REGISTRO concorda com o CARIMBO da porta?
#
# ── POR QUE EXISTE (dano medido em 2026-09-30, na porta PÚBLICA) ─────────────────────────
# O `members.yaml` dizia `role: standalone` para a `onion-core`; o carimbo dela
# (`.claude/.onion-version`) dizia `hub`. Eu li o REGISTRO, passei `--role standalone` ao
# `ops/materialize-door.sh`, e a face pública do core perdeu **85 arquivos de meta-fábrica** —
# `adopt`, `create-*`, `federation-*`, `marketplace/`, `wizard/`, `skills/onion-publish/` —, contra o
# que o CLAUDE.md declara dela ("mesma plataforma, mesma MAQUINARIA, sem biografia"). Restaurado em
# `4eb55ac`, mas já publicado. A causa não foi só descuido: **nada cobrava que as duas fontes
# concordassem**, e uma delas é anotada à mão.
#
# ── ONDE ESTA GUARDA MORDE, E ONDE ELA NÃO MORDE (medido, não suposto) ───────────────────
# ⚠️ Uma passada adversarial de 2026-09-30 derrubou a 1ª versão desta explicação, que dizia
# "quem materializa lê o registro, e o corte de papel vem dele". **É FALSO**: `ops/materialize-door.sh`
# nunca lê o `members.yaml` para decidir papel — `ROLE` é argumento com default `hub` (l.34, l.37).
# Quem leu a anotação errada foi um HUMANO, e um lint de PR não fica entre o operador e um comando
# de shell. Logo esta guarda é a SEGUNDA linha: ela impede que a anotação errada continue no repo
# convidando ao mesmo erro. A PRIMEIRA linha é a recusa dentro do materializador — `--role` que
# contradiz o carimbo existente do destino aborta lá, e essa é a cura que fecha o caminho medido.
# Declarar isso é o ponto: guarda que se vende como prevenção do que não previne é pior que nenhuma.
#
# ── O PREDICADO É PARIDADE, e isso é deliberado ──────────────────────────────────────────
# A tentação era embutir aqui a tabela "que papel cada porta deve ter". Recusada: tabela digitada
# é uma TERCEIRA fonte para o mesmo fato, e caduca junto com as outras duas. A guarda compara o
# registro com o carimbo e exige que **concordem** — quem decide QUAL é o certo é a doutrina
# (`docs/knowledge-base/concepts/public-door-vs-private-core.md`) mais o histórico de carimbos, e
# essa decisão é humana. A guarda só impede que as duas fontes contem histórias diferentes.
# TETO DECLARADO: paridade é cega a "ambas erradas do mesmo modo" — se alguém alinhar a fonte errada,
# ela fica verde com a porta mutilada. O predicado que fecharia isso mede o CONTEÚDO da porta contra
# o corte (`vendor-manifest.sh --role`), é viável e fica NOMEADO como sucessor, não escondido.
#
# ── Por que a comparação é legítima nas PORTAS (a objeção medida) ────────────────────────
# O `role:` do registro é projetado como **tier** (`graph.sh:81` imprime `<id> tier <role>`), e o do
# carimbo descreve o **corte de maquinaria**. Parecem dimensões diferentes — e nas portas convergem,
# porque o vocabulário de tier é de CAPACIDADE, não de uso: `members.yaml:73` anota `hub` como
# "central; **pode** ter sub-adotados", e a medição mostra um membro `hub` com ZERO sub-adotados de
# fato (nenhum `parent:` apontando para ele). Quem dá essa capacidade é exatamente a maquinaria que o
# carimbo nomeia. Por isso nas portas os dois campos respondem à mesma pergunta.
#
# ── Fronteira DECLARADA: só `kind: door`, e a razão NÃO é escopo, é SEMÂNTICA ────────────
# Em `kind: adopter` o mesmo par de campos responde a perguntas DIFERENTES, e a casa já escreveu isso
# no próprio registro: o `role:` do members.yaml diz o **TIER na rede** (T3: adota o core direto) e o
# do carimbo diz a **RELAÇÃO com o framework** (este repo vendoriza o Onion) — então `standalone` no
# registro com `adopted` no carimbo é CORRETO, não drift. Aplicar paridade a adotante produziria falso
# positivo em massa. Coberto pelo caso (g) da bancada, para que a fronteira não seja só esta frase.
#
# ── Fronteira DECLARADA: ela só julga o que pode LER ─────────────────────────────────────
# O carimbo vive no CLONE da porta, resolvido por `local_path` do registro. Num runner de CI o
# clone não existe — e aí a guarda **declara NÃO-MEDIDO**, nunca passa em silêncio. Isso é
# assimétrico de propósito: a alternativa (consultar o forge) exigiria rede e credencial dentro do
# lint, que é o oposto de gate determinístico. "Clone ausente" e "clone presente SEM carimbo" são
# estados diferentes e saem com nomes diferentes: o segundo não é caso de CI, é porta quebrada.
#
# Saída: uma linha por achado em stdout, prefixada por `REGRA 92: ` + uma TAG casável.
# Exit: 0 = ok (ou nada legível, com a declaração impressa) · 1 = divergência · 3 = não pude julgar.
# Determinístico, sem LLM. Exercitado por lint-selftest.sh (run_door_role_parity_selftests).
# ===========================================================================
set -uo pipefail

REPO="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
MEMBERS="${REPO}/docs/evolution/federation/members.yaml"
[ -f "${MEMBERS}" ] || { echo "door-role-parity: members.yaml ausente em ${REPO} — sem registro não há paridade a medir." >&2; exit 3; }
command -v python3 >/dev/null 2>&1 || { echo "door-role-parity: python3 ausente — não parseio YAML com grep." >&2; exit 3; }

# PORTAS + o papel e o caminho que o registro declara, lidos com YAML DE VERDADE.
# ⚠️ A 1ª versão extraía por regex (`^\s+role:`), e a passada adversarial a derrubou com quatro
# entradas YAML-LEGAIS: `kind: "door"` com aspas fazia a porta DESAPARECER (a guarda então afirmava
# "nenhuma porta no registro"), `role: "hub"` acusava DIVERGE contra o carimbo `hub`, `\s` casa `\n`
# então um `role:` aninhado em `trust:` era lido como o da porta, e comentário inline entrava no
# valor. Pior que os defeitos: o repo JÁ tem leitor YAML real deste arquivo (`members-validate.sh`
# usa `yaml.safe_load`) — a regex era um TERCEIRO leitor, menos fiel, exatamente contra o que estas
# linhas pregam. O separador é \x1f (ASCII US) e não tab porque `IFS=$'\t' read` COLAPSA delimitadores
# whitespace consecutivos: com `role` ausente o `path` escorregava para dentro de `role`.
doors="$(python3 - "${MEMBERS}" <<'PY' 2>/dev/null
import sys
try:
    import yaml
except ImportError:
    sys.exit(4)          # sem PyYAML a guarda RECUSA julgar; não cai para regex frouxa
try:
    doc = yaml.safe_load(open(sys.argv[1], encoding='utf-8')) or {}
except Exception:
    sys.exit(5)          # YAML inválido é problema do members-validate.sh, não desta guarda
for m in (doc.get('members') or []):
    if not isinstance(m, dict) or str(m.get('kind', '')).strip() != 'door':
        continue
    print("%s\x1f%s\x1f%s" % (str(m.get('id', '')).strip(),
                              str(m.get('role', '') or '').strip(),
                              str(m.get('local_path', '') or '').strip()))
PY
)"
py_rc=$?
case "${py_rc}" in
  4) echo "door-role-parity: PyYAML ausente — a guarda RECUSA julgar (o repo lê este arquivo com yaml.safe_load; regex seria um leitor menos fiel)." >&2; exit 3 ;;
  5) echo "door-role-parity: members.yaml não é YAML válido — cobrança é do members-validate.sh." >&2; exit 3 ;;
esac
[ -n "${doors}" ] || { echo "door-role-parity: nenhuma porta (kind: door) no registro — nada a medir."; exit 0; }

# Normaliza um valor de papel: tira comentário inline, aspas e espaço. Vale para os DOIS lados —
# comentário inline no carimbo (`role: hub   # carimbado`) produzia falso DIVERGE.
_norm_role() { printf '%s' "$1" | sed 's/[[:space:]]*#.*$//; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^["'"'"']//; s/["'"'"']$//'; }

found=0; unreadable=0
while IFS=$'\x1f' read -r mid role path; do
  [ -n "${mid}" ] || continue
  role="$(_norm_role "${role}")"

  # (a) porta SEM `role:` no registro: não é divergência, é lacuna — e ela impede a comparação.
  if [ -z "${role}" ]; then
    echo "REGRA 92: [porta/SEM-ROLE] porta '${mid}' não declara \`role:\` no members.yaml — sem o papel declarado não há paridade a conferir, e o materializador aceita qualquer \`--role\`"
    found=1; continue
  fi

  # (b) sem `local_path`, ou diretório inexistente: NÃO-MEDIDO declarado. É o caso do CI.
  if [ -z "${path}" ] || [ ! -d "${path}" ]; then
    unreadable=$((unreadable + 1)); continue
  fi

  # (c) clone PRESENTE e carimbo AUSENTE não é o caso do CI — é porta quebrada: sem o carimbo ela
  #     se declara a FONTE, e todo guard de adotante desliga (o modo-de-falha da REGRA 40).
  if [ ! -f "${path}/.claude/.onion-version" ]; then
    echo "REGRA 92: [porta/CARIMBO-AUSENTE] porta '${mid}' tem clone em ${path} mas NENHUM \`.claude/.onion-version\` — sem carimbo a porta se declara a FONTE e os guards de adotante desligam; re-materialize (bash ops/materialize-door.sh ${path} --role ${role})"
    found=1; continue
  fi

  stamp="$(_norm_role "$(grep -m1 -E '^[[:space:]]*role:' "${path}/.claude/.onion-version" | sed 's/^[[:space:]]*role:[[:space:]]*//')")"
  if [ -z "${stamp}" ]; then
    echo "REGRA 92: [porta/CARIMBO-INCOMPLETO] porta '${mid}' tem \`.onion-version\` SEM campo \`role:\` em ${path} — carimbo incompleto; a porta não sabe dizer o que é"
    found=1; continue
  fi

  if [ "${stamp}" != "${role}" ]; then
    echo "REGRA 92: [porta/PAPEL-DIVERGE] porta '${mid}' DIVERGE — registro diz \`${role}\`, carimbo diz \`${stamp}\` (${path}/.claude/.onion-version). Em 2026-09-30 esta divergência fez a face pública do core perder 85 arquivos de meta-fábrica, porque o operador leu a anotação. Decida QUAL é o certo pela doutrina (public-door-vs-private-core.md) e pelo histórico de carimbos, e alinhe os dois"
    found=1
  fi
done <<< "${doors}"

# A DECLARAÇÃO do não-medido é impressa SEMPRE que houver — silêncio aqui seria fail-open.
if [ "${unreadable}" -gt 0 ]; then
  echo "door-role-parity: ${unreadable} porta(s) com clone INALCANÇÁVEL (sem local_path, ou diretório ausente) — paridade NÃO MEDIDA nelas. É o caso esperado no CI, onde o clone não existe; medir exigiria rede e credencial dentro do lint." >&2
fi

exit "${found}"
