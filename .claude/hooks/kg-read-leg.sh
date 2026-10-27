#!/usr/bin/env bash
# PreToolUse(Read) — A PERNA DE LEITURA DO KG, ligada.
#
# ══ POR QUE ESTE HOOK EXISTE, e o preço que pagou para existir ════════════════════════════════
# A doutrina do KG anuncia a leitura do grafo como MECANISMO há meses. Medido em 2026-09-16:
# `grep -l '\.kg\.yaml' .claude/hooks/*.sh` devolvia ZERO. Era conselho — e conselho que depende
# de lembrar não é forcing function, o que esta casa já sabia e mesmo assim não tinha fiado.
#
# O preço veio de um adotante, em sinal de campo (2026-09-11): uma sessão leu 8.585 rows de
# fonte em quatro frentes e publicou QUATRO teses erradas em sequência — todas derrubadas por
# correção do autor, nenhuma pelo método — num corpus que tinha a resposta em QUATRO NÓS de um
# `.kg.yaml` que ela mesma CITOU no próprio prompt, como checklist de conferência e nunca como
# fonte. Não foi falta de acesso nem de contexto: foi falta de mecanismo. A frase é dele:
#
#     o grafo que não é lido é indistinguível do grafo que não foi escrito.
#
# ══ O QUE ELE FAZ, e o que DELIBERADAMENTE não faz ════════════════════════════════════════════
# Ao abrir um arquivo que algum nó do corpus aponta por `trace:`, avisa QUAIS nós falam dele.
# NÃO BLOQUEIA, e isso é desenho, não timidez: gate que impede trabalho é contornado com
# `--no-verify` na primeira sexta-feira, e aí se perde o mecanismo E a informação. O padrão certo
# da casa é catraca — avisa, e a métrica de saúde é o uso subindo.
#
# ══ POR QUE ÍNDICE COMMITADO, e não varredura ao vivo ═════════════════════════════════════════
# Medido: gerar 7.722 ms · consultar 8 ms. Um hook de PreToolUse que custasse 7,7 s por Read
# seria desligado no primeiro dia — e guarda desligada é pior que guarda ausente, porque o
# desligamento não fica registrado em lugar nenhum.
set -uo pipefail
IDX="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/docs/onion/kg-read-index.tsv"
[ -f "${IDX}" ] || exit 0

payload="$(cat)"

# ⚠️ O CAMPO `file_path` NAO EXISTE NUMA CHAMADA `Bash`, E ERA POR AI QUE 95% DO TRABALHO PASSAVA.
# Medido em 2026-09-19 sobre 29 transcricoes desta base (19.084 chamadas de ferramenta extraidas):
# das 2.457 interacoes que TOCAM um `.kg.yaml`, 2.341 sao `Bash` (95,3%), 83 `Edit`, 16 `Write` e
# apenas 17 `Read` (0,7%). O hook cobria zero-virgula-sete por cento da superficie que ele existe
# para vigiar — e ficava mudo justamente para quem ESCREVE no grafo, que trabalha por
# `sed`/`grep`/heredoc, nao por `Read`.
# O PRECO, medido no dia anterior: uma proposta de desenho foi ao maestro, foi SELADA, e caiu na
# passada adversarial contra DOIS nos `confirmed` do proprio arquivo que estava sendo editado — um
# deles tier 9 e textual. O hook que existe para impedir isso nunca falou.
# ⚠️ E O CUSTO DA CURA E REAL: `Bash` e 16.338 das 19.084 chamadas desta base (86%). Este hook passa
# a rodar em TODAS elas, entao a primeira coisa depois de ler o payload tem de ser a SAIDA MUDA.
# Por isso o filtro `.kg.yaml` vem ANTES de qualquer parse caro: um `case` de shell sobre a string
# crua descarta a esmagadora maioria sem chamar python nenhum.
# ⚠️ O FILTRO BARATO NAO PODE MATAR O CASO PRINCIPAL, e a 1a redacao matou. Este hook avisa sobre
# QUALQUER arquivo que um no aponte por `trace:` — `src/alvo.ts`, um workflow, um script. Filtrar o
# payload so por `.kg.yaml` cortava tudo isso: a bancada reprovou os casos (a) e (b), que existem
# desde o nascimento do hook. Eu teria trocado 95% do valor original pelo caso novo.
# A condicao certa tem DOIS ramos: se ha `file_path` (Read/Edit/Write), segue como sempre, seja qual
# for o arquivo; se NAO ha (Bash), so vale a pena parsear quando o comando cita um `.kg.yaml`.
# ⚠️ E A ESCRITA IN-PLACE POR BASH TAMBÉM É EDIÇÃO (SAC-240, r17 de 2026-10-23). Medido: o mesmo arquivo
# rastreado dava 988 bytes de aviso por Edit e 0 por `sed -i`, que na 2.1.309 é Bash comum — o Edit avisava e o
# `sed -i` passava calado. O 3º ramo do prefiltro deixa passar `sed`/`perl` com um `-` e um `i` adiante; quem
# decide se é in-place é o parser, não o `case`.
case "${payload}" in
  *'"file_path"'*) : ;;
  *.kg.yaml*)      : ;;
  *'sed '*-*i*|*'perl '*-*i*) : ;;
  *)               exit 0 ;;
esac

# O parser de comando é o da guarda do .env, LIDO da fonte e não copiado: o `GUARD_PY` de
# pretooluse-env-guard.sh tem o tokenizador linear (sem o custo quadrático do shlex da stdlib), o corte de
# comentários e de `\;`, e os segmentos da linha (`;`, `&&`, `|`, quebra de linha, padrões de `case`). Ele vive
# inline num veto que viaja SOZINHO no plugin, então extraí-lo para uma lib faria o veto depender de um 2º
# arquivo; aqui o `ast` carrega só as definições (import, def, class e constantes em maiúsculas) e deixa de
# fora o corpo que lê a entrada. Sem a guarda ao lado, ou se ela mudar de forma, o ramo do sed CALA (lembrete
# erra para o silêncio); a família kg_read_leg da bancada cobre a guarda (selftest-covers) e reprova a mudança.
# ⚠️ O ACOPLAMENTO É DECLARADO NOS DOIS LADOS E TESTADO (revisão adversarial do adotante sge, 2026-10-26). O que
# ele custava, medido: (1) o `segments` da guarda é de um VETO, que erra para FECHAR — ele lê o corpo de um heredoc
# como comando. Emprestado a um LEMBRETE, isso virava falso positivo cruzado: `cat > notas.md <<'EOF'` com uma
# linha `sed -i … <arquivo do índice>` no corpo (ou a mensagem de um commit por heredoc) avisava como se fosse
# edição. Por isso o corpo de heredoc sai AQUI, antes do `segments`, com a regra deste lado (calar vence: operador
# sem delimitador legível corta o resto). (2) O `ast` só leva import, def, class e constante em MAIÚSCULAS: uma
# constante da guarda renomeada para minúsculas, ou atribuída em tupla, some do namespace e o ramo cala em
# silêncio, com a bancada da guarda verde. O caso (s) da família kg_read_leg compara o `segments` carregado pelo
# `ast` com o da guarda executada inteira, num corpus de comandos, e o mutante (s-MUT) prova que ele morde.
KG_LEG_PY=$(cat <<'PY'
import ast, json, os, re, sys

def load_segments(guard):
    src = open(guard, encoding="utf-8").read()
    m = re.search(r"GUARD_PY=\$\(cat <<'PY'\n(.*?)\nPY\n\)", src, re.S)
    tree = ast.parse(m.group(1))
    const = re.compile(r"^_?[A-Z][A-Z0-9_]*$")
    keep = [n for n in tree.body
            if isinstance(n, (ast.Import, ast.ImportFrom, ast.FunctionDef, ast.ClassDef))
            or (isinstance(n, ast.Assign) and all(isinstance(t, ast.Name) and const.match(t.id) for t in n.targets))]
    ns = {}
    exec(compile(ast.Module(body=keep, type_ignores=[]), guard, "exec"), ns)
    return ns["segments"], ns.get("WRAPPERS", set())

# O operador de heredoc se acha por VARREDURA da linha, nunca por regex solta (revisão adversarial do adotante sge,
# 2026-10-27, dois falsos negativos medidos na forma por regex): (1) `<<` dentro de ASPAS (`echo "a<<b"`) não é
# operador, e a regex o lia como heredoc de delimitador `b`, engolindo o resto do comando; (2) `<<$X` é heredoc
# de delimitador LITERAL `$X` (o bash não expande a palavra do delimitador), e a regex, sem `$` na classe, o tinha
# por ilegível e cortava o resto. A varredura segue aspas (também as que atravessam a linha, e `$'…'` com
# escape), `\`, comentário, `$((…))`/`((…))`/`$[…]` (o deslocamento `1<<2` não abre corpo) e `<<<`
# (here-string). Fora de aritmética `<<` é SEMPRE heredoc no bash, também `<< 2` e `let x=1<<2` (o bash abre o
# corpo neles). Na dúvida, CALA: delimitador ilegível (vazio ou aspas sem fecho) corta dali ao fim, como antes.
# Teto declarado (passada adversarial, 2026-10-27): aspas aninhadas dentro de `"$(…)"` desalinham a varredura; o
# tokenizador da guarda desalinha igual e o ramo cala, então o efeito medido no hook é silêncio.
_HD_META = " \t;&|<>()"

def heredoc_ops(line, quote):
    """(ops, quote): ops = [(dash, palavra)] dos `<<` FORA de aspas e de aritmética, ou None se um é ilegível;
    quote = a aspa que segue aberta no fim da linha (None se nenhuma)."""
    ops, i, n, arith, brk = [], 0, len(line), 0, 0
    while i < n:
        c = line[i]
        if quote == "$'":
            if c == "\\":
                i += 2; continue
            if c == "'":
                quote = None
            i += 1; continue
        if quote == "'":
            if c == "'":
                quote = None
            i += 1; continue
        if quote == '"':
            if c == "\\":
                i += 2; continue
            if c == '"':
                quote = None
            i += 1; continue
        if c == "\\":
            i += 2; continue
        if line.startswith("$'", i):
            quote = "$'"; i += 2; continue
        if c in "'\"":
            quote = c; i += 1; continue
        if c == "#" and (i == 0 or line[i - 1] in " \t;&|("):
            break                                   # comentário: o resto da linha não é comando
        if line.startswith("((", i):
            arith += 1; i += 2; continue
        if arith and line.startswith("))", i):
            arith -= 1; i += 2; continue
        if line.startswith("$[", i):
            brk += 1; i += 2; continue
        if brk and c == "]":
            brk -= 1; i += 1; continue
        if line.startswith("<<<", i):
            i += 3; continue
        if line.startswith("<<", i) and not arith and not brk:
            j = i + 2
            dash = j < n and line[j] == "-"
            j += 1 if dash else 0
            while j < n and line[j] in " \t":
                j += 1
            word, wq = [], None
            while j < n:
                ch = line[j]
                if wq:
                    if ch == wq:
                        wq = None
                    else:
                        word.append(ch)
                    j += 1; continue
                if ch in "'\"":
                    wq = ch; j += 1; continue
                if ch == "\\" and j + 1 < n:
                    word.append(line[j + 1]); j += 2; continue
                if ch in _HD_META:
                    break
                word.append(ch); j += 1
            if wq or not word:
                return None, quote                  # delimitador ilegível
            ops.append((dash, "".join(word))); i = j; continue
        i += 1
    return ops, quote

def strip_heredoc_bodies(cmd):
    """tira o CORPO de todo heredoc (é dado, não comando). Operador sem delimitador legível: corta dali ao fim."""
    out, pending, quote = [], [], None
    for line in cmd.split("\n"):
        if pending:
            dash, word = pending[0]
            if (line.lstrip("\t") if dash else line) == word:
                pending.pop(0)
            continue
        out.append(line)
        ops, quote = heredoc_ops(line, quote)
        if ops is None:
            break                                   # não sei onde o corpo acaba: o resto não é julgado
        pending = list(ops)
    return "\n".join(out)

def argv_of(seg, wrappers):
    """tira atribuições (`LC_ALL=C sed`) e invólucros (`sudo`, `env`, `timeout 30`) da frente do segmento."""
    i = 0
    while i < len(seg):
        t = seg[i]
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t):
            i += 1; continue
        if t in wrappers:
            i += 1
            while i < len(seg) and seg[i].startswith("-"):
                i += 1
            if t == "timeout" and i < len(seg) and re.match(r"^[0-9.]+[smhd]?$", seg[i]):
                i += 1
            continue
        break
    return seg[i:]

def sed_files(args):
    """operandos de arquivo de um `sed` IN-PLACE (`-i`, `-i.bak`, `-Ei`, `--in-place[=SUF]`); vazio se não é."""
    inplace, script, files, i, opts = False, False, [], 0, True
    while i < len(args):
        a = args[i]
        if opts and a == "--":
            opts = False
        elif opts and a.startswith("--"):
            name = a.split("=", 1)[0]
            if name == "--in-place":
                inplace = True
            elif name in ("--expression", "--file", "--line-length"):
                script = script or name != "--line-length"
                if "=" not in a:
                    i += 1
        elif opts and a.startswith("-") and len(a) > 1:
            for j, c in enumerate(a[1:], 1):
                if c == "i":
                    inplace = True; break           # o resto do cluster é o sufixo do backup
                if c in "efl":
                    script = script or c != "l"
                    if j == len(a) - 1:
                        i += 1                      # o argumento vem no token seguinte
                    break
        elif not script:
            script = True                           # 1º operando sem -e/-f é o script
        else:
            files.append(a)
        i += 1
    return files if inplace else []

def perl_files(args):
    """operandos de arquivo de um `perl -i`/`-pi`; o perl para de ler chaves no 1º operando."""
    inplace, code, i = False, False, 0
    while i < len(args):
        a = args[i]
        if a == "--":
            i += 1; break
        if not a.startswith("-") or len(a) == 1:
            break
        for j, c in enumerate(a[1:], 1):
            if c == "i":
                inplace = True; break
            if c in "eE":
                code = True
                if j == len(a) - 1:
                    i += 1
                break
            if c in "IMmxCdD":
                break
        i += 1
    rest = args[i:]
    if not code:
        rest = rest[1:]                             # sem -e, o 1º operando é o arquivo do programa
    return rest if inplace else []

try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input", {}) or {}
    # Read/Edit/Write trazem o alvo em `file_path`; Bash o traz DENTRO do comando, e ali pode haver
    # mais de um caminho (`diff a.kg.yaml b.kg.yaml`). Emite todos: o consumidor deduplica.
    fp = ti.get("file_path") or ""
    if fp:
        print(fp)
    else:
        cmd = ti.get("command") or ""
        # caminho plausivel terminando em .kg.yaml, sem aspas/espacos no meio
        for m in re.findall(r"[A-Za-z0-9_./~-]+\.kg\.yaml", cmd):
            print(m)
        # o ramo do Bash in-place: `sed -i`, `sed --in-place`, `perl -pi` sobre arquivo que o índice conheça
        guard = os.environ.get("KG_LEG_ENV_GUARD") or ""
        # o parse da guarda custa ~0,1 s: só se paga quando há o programa E uma chave com `i` (ou --in-place)
        if (re.search(r"\b(g?sed|perl)\b", cmd) and re.search(r"(^|\s)-[^\s-]*i|--in-place", cmd)
                and os.path.isfile(guard)):
            try:
                segments, wrappers = load_segments(guard)
                cwd, moved = str(d.get("cwd") or ""), False
                for seg in segments(strip_heredoc_bodies(cmd)):
                    argv = argv_of(seg, wrappers)
                    if not argv:
                        continue
                    prog = os.path.basename(argv[0])
                    if prog in ("cd", "pushd", "popd"):
                        moved = True                # a pasta mudou e o hook não a segue: relativo cala
                        continue
                    files = sed_files(argv[1:]) if prog in ("sed", "gsed") else perl_files(argv[1:]) if prog == "perl" else []
                    for f in files:
                        if not f or re.search(r"[*?\[$`]", f):
                            continue                # glob e variável: o hook não expande, cala
                        if moved and not os.path.isabs(f):
                            continue
                        if cwd and not os.path.isabs(f):
                            f = os.path.normpath(os.path.join(cwd, f))
                        print(f)
            except Exception:
                pass                                # guarda ausente ou de outra forma: o ramo cala
except Exception:
    pass
PY
)
target="$(printf '%s' "${payload}" | KG_LEG_ENV_GUARD="$(dirname "${BASH_SOURCE[0]}")/pretooluse-env-guard.sh" python3 -c "${KG_LEG_PY}" 2>/dev/null)"
[ -n "${target}" ] || exit 0

# O índice guarda caminhos RELATIVOS à root; o Read chega com absoluto e o Bash costuma vir relativo.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ⚠️ AGORA O ALVO PODE SER MAIS DE UM (`diff a.kg.yaml b.kg.yaml`), entao o casamento ITERA. A 1a
# redacao tratava `target` como string unica; com multiplos caminhos ela casaria ZERO e o hook
# voltaria a ser mudo — a cura teria trocado um silencio por outro.
rows=""
while IFS= read -r _t; do
  [ -n "${_t}" ] || continue
  # `./X` (um ou mais) normaliza para `X` — o MESMO corte que o gerador aplica ao índice
  # (kg-trace.sh --emit-index, SAC-81). Os dois lados têm de concordar, senão nada casa.
  _rel="${_t#"${root}/"}"
  while :; do case "${_rel}" in ./*) _rel="${_rel#./}" ;; *) break ;; esac; done
  # A barra final sai pelo mesmo motivo: desde a kg-ssot 4.25.1 o índice vem do `resolved_targets` do produto, cujo
  # `path` NUNCA termina em barra (diretório inclusive), e quem consulta escreve `ls .claude/skills/` e
  # `.claude/skills`. Só o sufixo: o casamento continua por igualdade de campo, então não abre prefixo.
  while :; do case "${_rel}" in ?*/) _rel="${_rel%/}" ;; *) break ;; esac; done
  # `grep -F` com âncora de campo: o target é a 1ª coluna inteira, nunca um prefixo (senão
  # `kg.sh` casaria `kg.sh.bak` e o aviso apontaria nós de outro arquivo).
  _r="$(LC_ALL=C grep -F "$(printf '%s\t' "${_rel}")" "${IDX}" 2>/dev/null | LC_ALL=C awk -F'\t' -v a="${_rel}" '$1 == a' || true)"
  [ -n "${_r}" ] && rows="${rows}${_r}
"
done <<< "${target}"
rows="$(printf '%s' "${rows}" | LC_ALL=C sort -u || true)"
[ -n "${rows}" ] || exit 0

# ⚠️ O NOME DO ARQUIVO PARA A MENSAGEM SAI DAS LINHAS CASADAS, nao da variavel do laco. A 1a
# redacao desta cura deixou um `$rel` solto na mensagem final — sob `set -u` o hook morria com
# `unbound variable` EXATAMENTE no caso que a cura veio habilitar. Renomear pela metade quebra o
# lado que sobra, e aqui o lado que sobrava era o unico que interessava.
rel="$(printf '%s\n' "${rows}" | cut -f1 | LC_ALL=C sort -u | sed -n '1,2p' | awk '{ printf "%s%s", (NR>1 ? " + " : ""), $0 }')"

# ⚠️ `sed -n '1,Np'` em vez de `head -N`: o head FECHA O PIPE ao atingir a conta, o produtor
# a montante toma EPIPE e, sob `pipefail`, o status do comando inteiro vira 141. `sed` DRENA a
# entrada até o fim — mesma saída, sem corrida. É a classe `pipefail-epipe-early-closer`, e este
# é o terceiro sítio dela que eu escrevo no mesmo dia.
ids="$(printf '%s\n' "${rows}" | cut -f2 | LC_ALL=C sort -u | sed -n '1,8p' | tr '\n' ' ')"
# ⚠️ `paste -sd' · '` NÃO junta com " · ": o -d é um CONJUNTO de delimitadores e o paste usa um
# caractere por junção, ciclando — a saída sai com bytes soltos no meio dos nomes. Medido no 1º
# teste deste hook. `awk` junta com a string inteira, que é o que se queria.
graphs="$(printf '%s\n' "${rows}" | cut -f3 | LC_ALL=C sort -u | sed -n '1,3p' | awk '{ printf "%s%s", (NR>1 ? " · " : ""), $0 }')"
n="$(printf '%s\n' "${rows}" | wc -l | tr -d ' ')"

python3 - "$rel" "$ids" "$graphs" "$n" <<'PY'
import json, sys
rel, ids, graphs, n = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
msg = (f"🗺️ O CORPUS JÁ FALA DESTE ARQUIVO — {n} nó(s) o apontam por `trace:`.\n"
       f"   arquivo: {rel}\n"
       f"   nós: {ids}\n"
       f"   grafo(s): {graphs}\n"
       "   Leia o nó ANTES de concluir da fonte: o grafo é SSOT de estado, acima do código. "
       "Se o que você concluir divergir do nó, isso é drift a reconciliar — não detalhe a ignorar.")
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": msg}}))
PY
exit 0
