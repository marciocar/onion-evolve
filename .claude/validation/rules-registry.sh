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

# ---------------------------------------------------------------------------
# MODO --counts (2026-09-08): o MESMO parser devolve as contagens em KEY=VALUE.
# EXISTE PARA QUE NÃO EXISTA UM SEGUNDO CONTADOR. O `harness-inventory.sh` precisa do número
# de regras, e a tentação era reparsear `lint-rules.md` — que é markdown e MENTE: o título da
# REGRA 3 (Campo model: restrito à allowlist) contém pipes ESCAPADOS, e qualquer split ingênuo
# por `|` perde essa linha (medido: 77 em vez de 78, e um HARD a menos). Dois contadores para
# uma população é exatamente a divergência que esta onda existe para curar.
# O DEFAULT NÃO MUDA UM BYTE: a catraca da REGRA 62 (Projeção GERADA em sincronia com a fonte)
# compara `lint-rules.md` byte-a-byte, então alterar a saída sem argumento reprovaria o repo.
MODE="${1:---markdown}"
case "${MODE}" in
  --markdown|--counts) : ;;
  *) echo "uso: rules-registry.sh [--markdown|--counts]" >&2; exit 2 ;;
esac

python3 - "${LINT}" "${MODE}" <<'PY'
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

# Catraca de CLAREZA nº5 — toda regra DECLARA o tag [SEV] no header.
#
# A nº4 (abaixo) pega quem não tem tag NEM literal. Esta pega quem OMITE o tag mesmo
# tendo literal no corpo — o caso que valia por disciplina até 2026-08-03, quando 7 das
# 53 regras (1,2,3,5,12,13,14) não declaravam. Elas passavam porque o corpo tinha
# `violation "HARD"` literal; mas isso torna a leitura do header uma aposta ("é HARD ou
# SOFT? vá ler o corpo") e deixa a porta aberta para a próxima guarda DELEGADA nascer
# muda. Os 7 tags foram preenchidos com o que o corpo REALMENTE emitia — o registro
# gerado ficou byte-a-byte idêntico, provando que é padronização, não mudança de contrato.
# Threat models distintos, por isso as duas coexistem:
#   nº5 = "esqueceu de declarar"   ·   nº4 = "declarou algo que não resolve" (ex.: [CRITICO])
sem_tag = sorted(x for x in rules if not rules[x].get('declared'))
if sem_tag:
    sys.stderr.write(
        "ERRO rules-registry: REGRA(S) sem o tag [SEV] no header: %s\n"
        "  Toda regra declara a severidade no fim da linha `# REGRA N — Titulo`: [HARD],\n"
        "  [SOFT] ou [HARD + SOFT]. Use o que a guarda REALMENTE emite no corpo.\n" % sem_tag)
    sys.exit(2)

# Catraca de CLAREZA nº4 — nenhuma regra sai com severidade INDEFINIDA ('—').
#
# Nasceu da pergunta do maestro em 2026-08-03 ("então a tag [SEV] não é cosmético?"). Medição:
#   · REGRAS 43 e 44 têm ZERO `violation "HARD"` literal no corpo (delegam a script externo com
#     `violation "${sev}"`) — para elas o tag [SEV] é a ÚNICA fonte de severidade;
#   · as 7 regras que não declaravam tag (1,2,3,5,12,13,14) têm de 1 a 4 literais — por isso passavam.
# Havia uma regra IMPLÍCITA — "quem delega precisa do tag" — valendo por DISCIPLINA. Uma guarda
# delegada nova sem tag sairia '—' em silêncio, e o registro publicaria uma regra sem dizer se ela
# bloqueia o merge. Threat model distinto da nº5: aqui é "declarou algo que não resolve" (ex.: [CRITICO]).
sem_sev = sorted(x for x in rules if sev_label(rules[x]) == '—')
if sem_sev:
    sys.stderr.write(
        "ERRO rules-registry: REGRA(S) com severidade INDEFINIDA: %s\n"
        "  A guarda nao emite `violation \"HARD\"/\"SOFT\"` literal no corpo (delega a helper ou usa\n"
        "  `violation \"${sev}\"`), e o docstring nao declara o tag. Adicione [HARD] ou [SOFT] ao\n"
        "  final da linha `# REGRA N — Titulo` em lint-artifacts.sh.\n" % sem_sev)
    sys.exit(2)

# --- classificação (SSOT da categoria; a cobertura é guardada abaixo) --------
CATEGORIES = [
    ("Frontmatter & conformidade de artefato",
     "Campos obrigatórios, válidos e bem-formados no frontmatter de agentes e comandos.",
     [1, 2, 3, 12, 17, 23, 51]),
    ("Higiene de artefato",
     "Tamanho saudável, nomes kebab-case, dialeto puro e links que resolvem.",
     [5, 6, 13, 14, 15, 22, 48, 60, 71, 72, 73, 74, 75]),
    ("Fronteiras & contratos de arquitetura",
     "Proibições estruturais, documentação no lugar certo e os contratos de conformance e de adoção.",
     [7, 18, 20, 40, 53, 77]),
    ("SDAAL — abstração de provider",
     "O consumidor fala com a abstração, nunca com o provider direto.",
     [10, 11]),
    ("SSOT anti-drift",
     "Toda superfície DERIVADA fica em sincronia com a fonte única — contagens, mapas, plugins, topologia.",
     [8, 9, 16, 19, 21, 27, 37, 39, 41, 50, 59, 62, 63, 70, 76, 80, 81, 83, 84, 85]),
    ("KG & proveniência",
     "Conhecimento nasce no grafo e não morre em prosa; proveniência com catraca "
     "(por citação e por marcador autodeclarado); e frescor doutrinário — afirmação "
     "sensível-ao-tempo carimbada e dentro do TTL.",
     [26, 29, 31, 32, 42, 43, 47, 49, 52, 55, 57, 58, 67, 68, 69, 78, 82, 87]),
    ("Automação Graduada",
     "Classes de ação (HUMAN→MONITORED→DYNAMIC→AUTO) sobem de degrau com gate de promoção alcançável — nenhum rung-jump forjado.",
     [44, 65]),
    ("Federação",
     "Mapa, console, agent-card e canais de membro em sincronia com o SSOT da rede.",
     [24, 25, 28, 38, 46, 66]),
    ("Projeção & privacidade",
     "O que pode sair para superfícies públicas ou vendorizadas — nome de cliente e "
     "deep-link privado nunca vazam (nem a HOME crua do source privado, num artefato de "
     "plugin); e o compose commitado nunca publica porta em "
     "0.0.0.0 nem sobe com segredo de fallback.",
     [30, 33, 34, 35, 36, 45, 61, 64, 79]),
    ("Processo com resíduo",
     "O trabalho PROPOSTO carrega rastro material de ter sido revisado — o gate cria a cadência, "
     "o worker testa a verdade.",
     [56]),
    ("Integridade do próprio gate",
     "As demais categorias perguntam 'achei violação?'. Esta pergunta 'eu cheguei a "
     "olhar?' — porque varredura cega devolve zero violações, que é indistinguível de "
     "conformidade. Categoria nova em 2026-08-04, quando o lint rodou de dentro de um "
     "worktree de harness e varreu 0 dos 51 agentes sem emitir uma linha de aviso. "
     "A REGRA 86 entrou aqui em 2026-09-17 pelo mesmo motivo, um andar acima: um workflow "
     "que não PARSEIA não é um gate que falhou, é um gate que nunca rodou — e o repo o "
     "contava como existente.",
     [54, 86]),
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
out.append("> `# REGRA N — …` de `lint-artifacts.sh`. A **severidade** é a UNIÃO do que a guarda")
out.append("> *realmente emite* (`violation \"HARD\"` / `\"SOFT\"`) com o tag `[SEV]` declarado no")
out.append("> docstring. **Não edite à mão** — rode:")
out.append(">")
out.append("> ```bash")
out.append("> bash .claude/validation/rules-registry.sh > .claude/validation/lint-rules.md")
out.append("> ```")
out.append(">")
out.append("> A coluna **O que previne** vem do campo `# previne:` no docstring de cada regra (o")
out.append("> modo-de-falha que ela evita). A REGRA 39 mantém este arquivo em paridade com as guardas,")
out.append("> e o gerador **falha (exit 2)** nas **5 catracas de clareza** — número duplicado · regra")
out.append("> sem categoria · regra sem `# previne:` · regra sem o tag `[SEV]` · severidade que não")
out.append("> resolve. Regra nova sem essas quatro declarações não entra: é anti-drift por construção.")
out.append(">")
out.append("> **Limite conhecido da derivação** (medido 2026-08-03, `gated-until-trigger`: sem dano")
out.append("> observado, não vale reescrever o parser): o scan associa a cada regra o **primeiro**")
out.append("> `nome() {` após o header, então em regras cujo header antecede um *helper* — ou que")
out.append("> **delegam** a um script externo com `violation \"${sev}\"` dinâmico — a severidade vem do")
out.append("> tag `[SEV]`, não do corpo. Hoje as duas fontes concordam em **todas** as regras (nenhuma")
out.append("> sai com severidade indefinida). Se um dia divergirem, o tag ganha — por isso ele é o")
out.append("> contrato para as guardas delegadas.")
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

if len(sys.argv) > 2 and sys.argv[2] == '--counts':
    # HARD e SOFT contam por UNIÃO (uma regra HARD+SOFT entra nas duas) — é a mesma definição
    # da linha em prosa que este gerador já publica. Divergir aqui faria a SSOT contradizer o
    # próprio documento que ela cita. `RULES_BOTH` sai explícito para a soma ser AUDITÁVEL:
    # HARD + SOFT - BOTH = TOTAL. Sem ele, 69+21=90 contra 78 parece erro e não é.
    both = sum(1 for l in labels.values() if 'HARD' in l and 'SOFT' in l)
    sys.stdout.write('RULES_TOTAL=%d\nRULES_HARD=%d\nRULES_SOFT=%d\nRULES_BOTH=%d\n'
                     % (total, hard, soft, both))
    sys.exit(0)

sys.stdout.write('\n'.join(out).rstrip('\n') + '\n')
PY
