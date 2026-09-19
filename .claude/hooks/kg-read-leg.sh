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
case "${payload}" in
  *'"file_path"'*) : ;;
  *.kg.yaml*)      : ;;
  *)               exit 0 ;;
esac

target="$(printf '%s' "${payload}" | python3 -c 'import json,sys,re
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
except Exception:
    pass' 2>/dev/null)"
[ -n "${target}" ] || exit 0

# O índice guarda caminhos RELATIVOS à root; o Read chega com absoluto e o Bash costuma vir relativo.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ⚠️ AGORA O ALVO PODE SER MAIS DE UM (`diff a.kg.yaml b.kg.yaml`), entao o casamento ITERA. A 1a
# redacao tratava `target` como string unica; com multiplos caminhos ela casaria ZERO e o hook
# voltaria a ser mudo — a cura teria trocado um silencio por outro.
rows=""
while IFS= read -r _t; do
  [ -n "${_t}" ] || continue
  _rel="${_t#"${root}/"}"; _rel="${_rel#./}"
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
