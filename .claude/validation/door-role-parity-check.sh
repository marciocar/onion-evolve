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
# ── ADOTANTE: COMPATIBILIDADE, não paridade — e a razão é SEMÂNTICA ─────────────────────
# Em `kind: adopter` o mesmo par de campos responde a perguntas DIFERENTES: o `role:` do members.yaml
# diz o **TIER na rede** (T3: adota o core direto) e o do carimbo diz a **RELAÇÃO com o framework**
# (este repo vendoriza o Onion) — então `standalone` no registro com `adopted` no carimbo é CORRETO,
# não drift. Paridade ali produziria falso positivo em massa (caso (g) da bancada). Até 2026-10-07 o
# adotante ficava FORA desta guarda, e o custo apareceu: registro e carimbo podiam dizer coisas
# INCOMPATÍVEIS sem nenhum gate avisar (sinal de um adotante, 2026-10-07; medidos: um hub no
# registro com `adopted` no carimbo, e `adopted` no registro de um T3). Agora o adotante é julgado por um MAPA de pares
# permitidos — SOFT, porque a cura pode morar no clone (carimbo) ou aqui (registro):
#     registro hub        → carimbo hub       (a autoridade de adoção É a maquinaria do carimbo)
#     registro standalone → carimbo adopted   (carimbo `standalone` liga o MODO PORTA no lint: medido,
#     registro consumer   → carimbo adopted    dois adotantes medidos: 0→16 e 0→14 HARD)
# O mapa NÃO é a "terceira fonte" recusada acima: ele não diz que papel cada membro TEM, diz que
# pares de vocabulário têm sentido juntos — é a tradução entre as duas dimensões, e muda só se o
# vocabulário mudar.
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
    kind = str(m.get('kind', '')).strip() if isinstance(m, dict) else ''
    if kind not in ('door', 'adopter'):
        continue
    print("%s\x1f%s\x1f%s\x1f%s" % (str(m.get('id', '')).strip(),
                              str(m.get('role', '') or '').strip(),
                              str(m.get('local_path', '') or '').strip(), kind))
PY
)"
py_rc=$?
case "${py_rc}" in
  4) echo "door-role-parity: PyYAML ausente — a guarda RECUSA julgar (o repo lê este arquivo com yaml.safe_load; regex seria um leitor menos fiel)." >&2; exit 3 ;;
  5) echo "door-role-parity: members.yaml não é YAML válido — cobrança é do members-validate.sh." >&2; exit 3 ;;
esac
[ -n "${doors}" ] || { echo "door-role-parity: nenhuma porta nem adotante no registro — nada a medir."; exit 0; }

# Normaliza um valor de papel: tira comentário inline, aspas e espaço. Vale para os DOIS lados —
# comentário inline no carimbo (`role: hub   # carimbado`) produzia falso DIVERGE.
_norm_role() { printf '%s' "$1" | sed 's/[[:space:]]*#.*$//; s/^[[:space:]]*//; s/[[:space:]]*$//; s/^["'"'"']//; s/["'"'"']$//'; }

# O mapa de pares permitidos registro→carimbo do ADOTANTE (ver o cabeçalho).
_compat_ok() {  # $1=registro $2=carimbo
  case "$1:$2" in hub:hub|standalone:adopted|consumer:adopted) return 0 ;; *) return 1 ;; esac; }

found=0; unreadable=0; adopter_unreadable=0; mini_pending=0
while IFS=$'\x1f' read -r mid role path kind; do
  [ -n "${mid}" ] || continue
  role="$(_norm_role "${role}")"

  if [ "${kind}" = "adopter" ]; then
    # Sem clone (CI) → não-medido, contado e declarado; sem papel no registro é cobrança do
    # members-validate.sh, não desta guarda.
    [ -n "${role}" ] || continue
    if [ -z "${path}" ] || [ ! -d "${path}" ]; then adopter_unreadable=$((adopter_unreadable + 1)); continue; fi
    if [ ! -f "${path}/.claude/.onion-version" ]; then
      echo "REGRA 92: [adotante/CARIMBO-AUSENTE] adotante '${mid}' tem clone em ${path} mas NENHUM \`.claude/.onion-version\` — o registro diz que ele vendoriza o Onion e o clone não confirma; o clone está em outro checkout, desacoplou, ou o \`local_path\` envelheceu"
      found=1; continue
    fi
    astamp="$(_norm_role "$(grep -m1 -E '^[[:space:]]*role:' "${path}/.claude/.onion-version" | sed 's/^[[:space:]]*role:[[:space:]]*//')")"
    if ! _compat_ok "${role}" "${astamp}"; then
      echo "REGRA 92: [adotante/PAPEL-INCOMPATIVEL] adotante '${mid}': registro \`${role}\` (tier) com carimbo \`${astamp:-<vazio>}\` (relação/corte) não é par permitido — o mapa é hub→hub e standalone|consumer→adopted. Decida qual lado está errado: promover/rebaixar o carimbo é ato da sessão DELE (\`/meta:adopt --update --role …\`); o registro se alinha aqui"
      found=1
    fi
    continue
  fi

  # (a) porta SEM `role:` no registro: não é divergência, é lacuna — e ela impede a comparação.
  if [ -z "${role}" ]; then
    echo "REGRA 92: [porta/SEM-ROLE] porta '${mid}' não declara \`role:\` no members.yaml — sem o papel declarado não há paridade a conferir, e o materializador aceita qualquer \`--role\`"
    found=1; continue
  fi

  # (b) sem `local_path`, ou diretório inexistente: NÃO-MEDIDO declarado. É o caso do CI.
  if [ -z "${path}" ] || [ ! -d "${path}" ]; then
    unreadable=$((unreadable + 1)); continue
  fi

  # (b2) PORTAS SEM ÁRVORE `.claude/` (F1.5 das portas, 2026-10-09). Duas portas da matriz
  #      (D_MATRIZ_DE_PORTAS_2026_10) não carregam `.claude/.onion-version`, e por razões diferentes:
  #   · `plugins` é MARKETPLACE: o carimbo dela é o `provenance.json` de cada plugin
  #     (`plugins/<p>/.claude-plugin/provenance.json`, campo `ref`). Ele não tem campo `role:` — o
  #     papel se reconhece pela FORMA do repo. Medido no clone em 2026-10-09: 5 plugins, nenhum
  #     `.claude/`. Sem este ramo a guarda acusaria CARIMBO-AUSENTE e mandaria rodar o
  #     materialize-door.sh, que monta uma árvore `.claude/` — a cura ERRADA para essa porta.
  #   · `mini` ainda NÃO foi PUBLICADA pelo carimbo: a 1ª materialização por allowlist tem caminho
  #     desde a F5 (SAC-94, `publish-door.sh --replace-foreign`), e a publicação é ato do maestro (F6).
  #     Até ela o clone é a destilação antiga, sem carimbo. A guarda DECLARA não-medido, como no CI;
  #     depois da publicação o carimbo existe e cai na comparação normal abaixo.
  #   Se uma dessas portas tiver `.onion-version`, NENHUM ramo especial vale: compara como as outras.
  #   TETO DECLARADO: para `plugins` esta guarda mede só a PRESENÇA da proveniência (a forma), não
  #   compara o `ref` com o `onion_version` do registro — isso é pin, e o pin é da REGRA 85 e do
  #   `/meta:publish` (F3). Papel e pin são perguntas diferentes; misturá-las aqui criaria um 2º dono.
  if [ ! -f "${path}/.claude/.onion-version" ]; then
    if [ "${role}" = "plugins" ]; then
      if compgen -G "${path}/plugins/*/.claude-plugin/provenance.json" >/dev/null; then continue; fi
      echo "REGRA 92: [porta/CARIMBO-AUSENTE] porta '${mid}' (role plugins) tem clone em ${path} mas NENHUM \`plugins/*/.claude-plugin/provenance.json\` — sem proveniência o marketplace não diz de que commit do core saiu; re-publique pelo assemble-plugin.sh (não pelo materialize-door.sh, que monta árvore .claude/)"
      found=1; continue
    fi
    if [ "${role}" = "mini" ]; then
      mini_pending=$((mini_pending + 1)); continue
    fi
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
if [ "${adopter_unreadable}" -gt 0 ]; then
  echo "door-role-parity: ${adopter_unreadable} adotante(s) com clone INALCANÇÁVEL — compatibilidade registro×carimbo NÃO MEDIDA neles." >&2
fi
if [ "${mini_pending}" -gt 0 ]; then
  echo "door-role-parity: ${mini_pending} porta(s) \`mini\` ainda sem carimbo (a 1ª publicação por allowlist é do maestro: /meta:publish onion-mini --replace-foreign) — paridade NÃO MEDIDA nelas." >&2
fi
if [ "${unreadable}" -gt 0 ]; then
  echo "door-role-parity: ${unreadable} porta(s) com clone INALCANÇÁVEL (sem local_path, ou diretório ausente) — paridade NÃO MEDIDA nelas. É o caso esperado no CI, onde o clone não existe; medir exigiria rede e credencial dentro do lint." >&2
fi

exit "${found}"
