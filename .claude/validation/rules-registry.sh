#!/usr/bin/env bash
# ===========================================================================
# rules-registry.sh — GERA o registro de REGRAS do lint (documento de conhecimento da rede).
#
# Fonte única: os docstrings '# REGRA N — …' de lint-artifacts.sh + o CORPO de cada guarda.
# A severidade NÃO vem do comentário — vem do que a guarda realmente emite (violation "HARD"
# / "SOFT"). Assim o registro reflete o comportamento, não uma promessa que pode ter driftado.
#
# Imprime markdown em stdout; o arquivo .claude/validation/lint-rules.md é a PROJEÇÃO (a guarda
# REGRA 39 regenera e compara). FALHA (exit 2) se houver número de REGRA duplicado ou uma regra
# sem categoria — a catraca de clareza (a colisão 22/23 nunca mais volta silenciosa).
#
# Uso:  bash .claude/validation/rules-registry.sh > .claude/validation/lint-rules.md
# ===========================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# RULES_LINT_SRC: override da fonte (usado só pelo selftest p/ apontar a um fixture).
LINT="${RULES_LINT_SRC:-${SCRIPT_DIR}/lint-artifacts.sh}"
[ -f "${LINT}" ] || { echo "rules-registry: lint-artifacts.sh ausente" >&2; exit 3; }
command -v python3 >/dev/null 2>&1 || { echo "rules-registry: python3 ausente" >&2; exit 3; }

python3 - "${LINT}" <<'PY'
import re, sys

lint = sys.argv[1]
lines = open(lint, encoding='utf-8').read().split('\n')

rx    = re.compile(r'^# REGRA (\d+) [—-] (.+?)\s*$')   # '# REGRA N — Título'
fnrx  = re.compile(r'^([a-z_][a-z0-9_]*)\(\)\s*\{')          # 'check_xxx() {'
sevrx = re.compile(r'violation "(HARD|SOFT)"')
tagrx = re.compile(r'\[([^\]]*)\]\s*$')                       # '… [HARD]'
prevrx = re.compile(r'^#\s*previne:\s*(.+?)\s*$')            # '# previne: <modo-de-falha>'

rules, order, dups = {}, [], []
i, n = 0, len(lines)
while i < n:
    m = rx.match(lines[i])
    if not m:
        i += 1; continue
    num = int(m.group(1))
    raw = m.group(2)
    tagm = tagrx.search(raw)
    declared = tagm.group(1).strip() if tagm else None
    title = tagrx.sub('', raw).strip() if tagm else raw.strip()
    # da guarda até o próximo docstring: acha a função, as severidades que ela emite,
    # e o campo '# previne:' (o modo-de-falha, no bloco de docstring antes da função).
    j = i + 1
    fname, sev, previne = None, set(), None
    while j < n and not rx.match(lines[j]):
        if previne is None:
            pm = prevrx.match(lines[j])
            if pm:
                previne = pm.group(1)
        fm = fnrx.match(lines[j])
        if fm:
            fname = fm.group(1)
            k = j + 1
            while k < n and lines[k] != '}':
                sm = sevrx.search(lines[k])
                if sm:
                    sev.add(sm.group(1))
                k += 1
            break
        j += 1
    if num in rules:
        dups.append(num)
    rules[num] = dict(title=title, declared=declared, sev=sev, fn=fname, previne=previne)
    order.append(num)
    i += 1

if dups:
    sys.stderr.write("ERRO rules-registry: numero(s) de REGRA duplicado(s): %s\n" % sorted(set(dups)))
    sys.exit(2)

# Catraca de CLAREZA (irmã da 'sem categoria'): toda regra declara o MODO-DE-FALHA que
# previne, num '# previne:' logo abaixo do '# REGRA N —'. Sem isso, o registro vira lista
# de nomes; com isso, mapa navegavel. Regra nova sem previne = erro (nao esquece por design).
no_previne = sorted(x for x in rules if not rules[x].get('previne'))
if no_previne:
    sys.stderr.write("ERRO rules-registry: REGRA(S) sem '# previne: <modo-de-falha>' no docstring: %s "
                     "(adicione a linha logo abaixo de '# REGRA N —' em lint-artifacts.sh)\n" % no_previne)
    sys.exit(2)

def sev_label(r):
    # Severidade = o que a guarda EMITE (literais violation "HARD"/"SOFT" no corpo)
    # UNIDO ao que o docstring DECLARA. As guardas de severidade dinamica (violation
    # "${sev}") nao expoem literal — para essas o tag do docstring e o contrato.
    s = set(r['sev'])
    if r['declared']:
        for tok in ('HARD', 'SOFT'):
            if tok in r['declared']:
                s.add(tok)
    if s == {'HARD', 'SOFT'}: return 'HARD + SOFT'
    if s == {'HARD'}:         return 'HARD'
    if s == {'SOFT'}:         return 'SOFT'
    return '—'

# --- classificação (SSOT da categoria; a cobertura é guardada abaixo) --------
CATEGORIES = [
    ("Frontmatter & conformidade de artefato",
     "Campos obrigatórios, válidos e bem-formados no frontmatter de agentes e comandos.",
     [1, 2, 3, 12, 17, 23]),
    ("Higiene de artefato",
     "Tamanho saudável, nomes kebab-case, dialeto puro e links que resolvem.",
     [5, 6, 13, 14, 15, 22]),
    ("Fronteiras & contratos de arquitetura",
     "Proibições estruturais, documentação no lugar certo e os contratos de conformance e de adoção.",
     [4, 7, 18, 20, 40]),
    ("SDAAL — abstração de provider",
     "O consumidor fala com a abstração, nunca com o provider direto.",
     [10, 11]),
    ("SSOT anti-drift",
     "Toda superfície DERIVADA fica em sincronia com a fonte única — contagens, mapas, plugins, topologia.",
     [8, 9, 16, 19, 21, 27, 37, 39, 41]),
    ("KG & proveniência",
     "Conhecimento nasce no grafo e não morre em prosa; proveniência com catraca "
     "(por citação e por marcador autodeclarado); e frescor doutrinário — afirmação "
     "sensível-ao-tempo carimbada e dentro do TTL.",
     [26, 29, 31, 32, 42, 43, 44, 47]),
    ("Federação",
     "Mapa, console, agent-card e canais de membro em sincronia com o SSOT da rede.",
     [24, 25, 28, 38, 46]),
    ("Projeção & privacidade",
     "O que pode sair para superfícies públicas ou vendorizadas — nome de cliente e "
     "deep-link privado nunca vazam.",
     [30, 33, 34, 35, 36, 45]),
]

seen = {}
for _, _, nums in CATEGORIES:
    for x in nums:
        if x in seen:
            sys.stderr.write("ERRO rules-registry: REGRA %d classificada em duas categorias\n" % x)
            sys.exit(2)
        seen[x] = True
# Catraca contra REGRA ORFA: toda regra que existe nos docstrings PRECISA de categoria.
missing = sorted(set(rules) - set(seen))
if missing:
    sys.stderr.write("ERRO rules-registry: REGRA(S) sem categoria: %s "
                     "(classifique em rules-registry.sh, secao CATEGORIES)\n" % missing)
    sys.exit(2)
# Categoria que aponta a um numero ausente nos docstrings NAO e fatal: so nao renderiza
# aquele numero (mantem o gerador testavel com um fixture menor que o conjunto real).

labels = {x: sev_label(rules[x]) for x in rules}
total  = len(rules)
hard   = sum(1 for l in labels.values() if 'HARD' in l)
soft   = sum(1 for l in labels.values() if 'SOFT' in l)

def esc(s):
    return s.replace('|', r'\|')

out = []
out.append("# Registro de REGRAS do lint — Onion")
out.append("")
out.append("> **Documento GERADO** por `.claude/validation/rules-registry.sh` a partir dos docstrings")
out.append("> `# REGRA N — …` de `lint-artifacts.sh`. A **severidade** é derivada do que cada guarda")
out.append("> *realmente emite* (`violation \"HARD\"` / `\"SOFT\"`), não de um comentário que pode ter")
out.append("> driftado. **Não edite à mão** — rode:")
out.append(">")
out.append("> ```bash")
out.append("> bash .claude/validation/rules-registry.sh > .claude/validation/lint-rules.md")
out.append("> ```")
out.append(">")
out.append("> A coluna **O que previne** vem do campo `# previne:` no docstring de cada regra (o")
out.append("> modo-de-falha que ela evita). A REGRA 39 mantém este arquivo em paridade com as guardas")
out.append("> e **falha se houver número duplicado, regra sem categoria ou regra sem `# previne:`** — a")
out.append("> catraca de clareza.")
out.append("")
out.append("São as regras que o gate mecânico do Onion aplica a **todo repo da rede**: o mesmo")
out.append("lint roda no core e em cada adotante. **HARD** bloqueia o merge; **SOFT** avisa, mas não")
out.append("bloqueia o CI.")
out.append("")
out.append("**%d regras** no total — **%d HARD**, **%d SOFT**." % (total, hard, soft))
out.append("")
for title, desc, nums in CATEGORIES:
    present = [x for x in sorted(nums) if x in rules]
    if not present:
        continue   # categoria sem nenhuma regra presente (so ocorre em fixture menor que o real)
    out.append("## %s" % title)
    out.append("")
    out.append(desc)
    out.append("")
    out.append("| Nº | Regra | Severidade | O que previne |")
    out.append("|---:|-------|:----------:|---------------|")
    for x in present:
        out.append("| %d | %s | %s | %s |" % (x, esc(rules[x]['title']), labels[x], esc(rules[x]['previne'])))
    out.append("")

sys.stdout.write('\n'.join(out).rstrip('\n') + '\n')
PY
