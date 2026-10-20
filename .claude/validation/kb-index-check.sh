#!/usr/bin/env bash
# =============================================================================
# kb-index-check.sh — o índice da KB (docs/knowledge-base/index.md) conta o que o disco tem (REGRA 110)
#
# DEFEITO DATADO (2026-10-19, sinal de campo de um hub adotante no --update 59ebe7fe1288): o índice dizia
#   "Conceitos Fundamentais (42)", listava 44 e havia 53 arquivos em concepts/. Foi o ÚNICO conflito do merge do
#   update: o hub não listava 4 conceitos que tinha em disco. O índice é escrito pelo /docs:build-index, que manda
#   "contar no scan, nunca de memória" — e a prosa não impede ninguém de esquecer. Medido no core no mesmo dia:
#   35 arquivos de conteúdo fora do índice (9 conceitos, 2 ferramentas, 2 plataformas, 1 padrão, 2 agentic e a
#   pasta decisions/ inteira, 13 ADRs sem seção). Nenhuma guarda comparava a contagem declarada com o disco.
#
# O QUE MEDE (a convenção é a do próprio índice: conteúdo = .md exceto index.md e README.md de (sub)categoria):
#   · SEÇÃO `## … (N)` ou `## … (N + M README)`: a pasta é a 1ª componente dos links da seção; N tem de ser o
#     conteúdo em disco da pasta, e a seção tem de LISTAR cada um deles (o que falta sai nomeado); M, se
#     declarado, tem de ser o número de READMEs;
#   · PASTA de docs/knowledge-base/ com conteúdo e SEM seção no índice;
#   · ESTATÍSTICAS: `**N documentos de conteúdo**` (o total) e cada `**N** em \`pasta/\``;
#   · ÁRVORE: o `# N` de cada pasta de 1º nível no bloco da estrutura.
# CONJUNTO CONTADO: os arquivos RASTREADOS (git ls-files, que inclui o stageado); sem git ou sem nada rastreado,
#   o disco. ONION_KB_INDEX_FS=1 força o disco (a bancada o usa como mutante).
# Severidade: HARD no core; SOFT no derivado (adotante/porta), onde a KB vendorizada pode ganhar KB local e o
#   índice é do core — avisa, não trava o lint de quem não o escreve.
#
# Uso: kb-index-check.sh [REPO_DIR] [--format tsv|text] [--derived]
#   tsv: severidade · código · caminho · mensagem (uma linha por achado; nada = em dia)
# Exit: 0 mediu (os achados estão na saída) · 2 erro de uso/ambiente.
# TETO: não julga o TEXTO de cada entrada (descrição desatualizada, título errado) nem link morto (é da REGRA dos
#   links da KB); seção cujos links apontam para mais de uma pasta não é julgada e sai como SOFT NAO-JULGAVEL.
# Exercitado por lint-selftest.sh (run_kb_index_selftests).
# =============================================================================
set -uo pipefail
export LC_ALL=C
REPO="."; FMT="text"; DERIVED=0
while [ $# -gt 0 ]; do
  case "$1" in
    --format) FMT="${2:-text}"; shift ;;
    --format=*) FMT="${1#--format=}" ;;
    --derived) DERIVED=1 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    --*) echo "kb-index-check: opção desconhecida: $1" >&2; exit 2 ;;
    *) REPO="$1" ;;
  esac
  shift
done
command -v python3 >/dev/null 2>&1 || { echo "kb-index-check: python3 ausente" >&2; exit 2; }
[ -f "${REPO}/docs/knowledge-base/index.md" ] || exit 0
python3 -I - "${REPO}" "${FMT}" "${DERIVED}" <<'PY'
import os, re, sys
repo, fmt, derived = sys.argv[1], sys.argv[2], sys.argv[3] == '1'
kb = os.path.join(repo, 'docs', 'knowledge-base')
idx_rel = 'docs/knowledge-base/index.md'
text = open(os.path.join(kb, 'index.md'), encoding='utf-8').read()
# o que não renderiza não é índice: comentário HTML e bloco cercado saem antes (a árvore da estrutura vive num
# bloco cercado e é lida à parte, do texto original)
raw = text
text = re.sub(r'<!--.*?-->', '', text, flags=re.S)
text = re.sub(r'^```.*?^```[^\n]*$', '', text, flags=re.S | re.M)
SEV = 'SOFT' if derived else 'HARD'
out = []
def add(sev, code, msg):
    out.append((sev, code, idx_rel, msg))

# ENUMERAÇÃO RASTREADA — o molde do inventory.sh (_tracked_or_find): `git ls-files` vê o MESMO conjunto que o
# CI (o índice inclui o que está stageado); sem git, ou com a listagem VAZIA num diretório com arquivos (adoção
# greenfield antes do 1º add), cai na varredura do disco. Medido no CI do PR #1222 (2026-10-20): a bancada planta
# `concepts/selftest-fixture-probe.md` na árvore viva para testar o lint, e a varredura do disco a contava como KB
# fora do índice (HARD no caso r22-kb-links). Arquivo não rastreado não viaja nem entra no merge: não é do índice.
import subprocess
def _tracked():
    try:
        out = subprocess.run(['git', '-C', repo, 'ls-files', '-z', '--', 'docs/knowledge-base'],
                             capture_output=True, text=True, timeout=30)
    except Exception:
        return None
    if out.returncode != 0:
        return None
    rels = [os.path.relpath(x, 'docs/knowledge-base') for x in out.stdout.split('\0') if x]
    return rels or None
TRACKED = None if os.environ.get('ONION_KB_INDEX_FS') == '1' else _tracked()
if TRACKED is None:
    TRACKED = []
    for root, _, fs in os.walk(kb):
        TRACKED += [os.path.relpath(os.path.join(root, f), kb) for f in fs]
TRACKED = [t for t in TRACKED if os.path.isfile(os.path.join(kb, t))]

def content(d):
    c, r = [], 0
    for rel in TRACKED:
        if not rel.startswith(d + '/'):
            continue
        f = os.path.basename(rel)
        if not f.lower().endswith('.md') or f == 'index.md':
            continue
        if f.lower() == 'readme.md':
            r += 1
        else:
            c.append(rel)
    return sorted(c), r

dirs = sorted({t.split('/', 1)[0] for t in TRACKED if '/' in t and not t.startswith('.')})
disk = {d: content(d) for d in dirs}
disk = {d: v for d, v in disk.items() if v[0] or v[1]}
solto = sorted(f for f in TRACKED if '/' not in f and f.lower().endswith('.md') and f != 'index.md')
if solto:
    add(SEV, 'ARQUIVO-NA-RAIZ', '%d arquivo(s) de conteúdo na raiz da KB, fora de categoria: %s' % (len(solto), ', '.join(solto)))

HEAD = re.compile(r'^#{2,3} (.+?)\((\d+)(?:\s*\+\s*(\d+)\s*READMEs?)?\)[^\n(]*$', re.M)
heads = list(HEAD.finditer(text))
covered = set()
groups = {}
for i, m in enumerate(heads):
    nx = re.compile(r'^#{2,3} ', re.M).search(text, m.end())
    end = nx.start() if nx else -1
    body = text[m.end():end if end >= 0 else len(text)]
    # só os links de ITEM de lista (`- [x](pasta/y.md)`): a prosa da seção cita outras pastas (a Education cita
    # um conceito no parágrafo de abertura) e não é entrada do índice
    items = '\n'.join(l for l in body.split('\n') if re.match(r'^\s*(?:[-*+]|\d+[.)])\s', l))
    links = [os.path.normpath(l) for l in re.findall(r'\]\(<?([^)#\s>]+\.md)>?(?:#[^)\s]*)?(?:\s+"[^"]*")?\)', items, re.I)
             if not l.startswith(('../', '/', 'http'))]
    links = [l for l in links if not l.startswith('..')]
    tops = {l.split('/', 1)[0] for l in links if '/' in l}
    title, n, m_readme = m.group(1).strip(), int(m.group(2)), m.group(3)
    if len(tops) != 1:
        add('SOFT', 'NAO-JULGAVEL', 'seção "%s (%d)": os links apontam para %s pasta(s) (%s) — a guarda não sabe qual contar' % (title, n, len(tops), ', '.join(sorted(tops)) or 'nenhuma'))
        continue
    d = tops.pop()
    covered.add(d)
    g = groups.setdefault(d, {'titles': [], 'n': 0, 'listed': set(), 'readme': None})
    g['titles'].append(title); g['n'] += n
    g['listed'] |= {l for l in links if l.startswith(d + '/') and os.path.basename(l).lower() != 'readme.md'}
    if m_readme is not None:
        g['readme'] = (g['readme'] or 0) + int(m_readme)
for d, g in sorted(groups.items()):
    files, readmes = disk.get(d, ([], 0))
    title = ' + '.join(g['titles'])
    if g['n'] != len(files):
        add(SEV, 'CONTAGEM', 'seção "%s" declara %d, e %s/ tem %d arquivo(s) de conteúdo em disco (exceto README) — /docs:build-index knowledge-base' % (title, g['n'], d, len(files)))
    falta = [f for f in files if f not in g['listed']]
    if falta:
        add(SEV, 'FORA-DO-INDICE', 'seção "%s": %d arquivo(s) de %s/ em disco sem entrada: %s' % (title, len(falta), d, ', '.join(falta)))
    if g['readme'] is not None and g['readme'] != readmes:
        add(SEV, 'CONTAGEM-README', 'seção "%s" declara %s README(s), e %s/ tem %d' % (title, g['readme'], d, readmes))
for d in sorted(x for x in set(disk) - covered if disk[x][0]):
    add(SEV, 'PASTA-SEM-SECAO', '%s/ tem %d arquivo(s) de conteúdo e nenhuma seção "## … (N)" no índice' % (d, len(disk[d][0])))

total = sum(len(v[0]) for v in disk.values())
for mm in re.finditer(r'\*\*(\d+) documentos de conteúdo\*\*', text):
    if int(mm.group(1)) != total:
        add(SEV, 'ESTATISTICA', 'as estatísticas dizem %s documentos de conteúdo, e o disco tem %d' % (mm.group(1), total))
for mm in re.finditer(r'\*\*(\d+)\*\* em `([a-z0-9-]+)/`', text):
    d = mm.group(2)
    if d in disk and int(mm.group(1)) != len(disk[d][0]):
        add(SEV, 'ESTATISTICA', 'as estatísticas dizem %s em %s/, e o disco tem %d' % (mm.group(1), d, len(disk[d][0])))
for mm in re.finditer(r'^[├└]── ([a-z0-9-]+)/\s+#\s*(\d+)\b', raw, re.M):
    d = mm.group(1)
    if d in disk and int(mm.group(2)) != len(disk[d][0]):
        add(SEV, 'ARVORE', 'a árvore da estrutura diz %s em %s/, e o disco tem %d' % (mm.group(2), d, len(disk[d][0])))

for sev, code, path, msg in out:
    if fmt == 'tsv':
        print('%s\t%s\t%s\t%s' % (sev, code, path, msg))
    else:
        print('%s [%s] %s: %s' % (sev, code, path, msg))
PY
