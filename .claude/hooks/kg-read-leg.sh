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
target="$(printf '%s' "${payload}" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print(d.get("tool_input", {}).get("file_path", "") or "")
except Exception:
    print("")' 2>/dev/null)"
[ -n "${target}" ] || exit 0

# O índice guarda caminhos RELATIVOS à root; o Read chega com absoluto.
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
rel="${target#"${root}/"}"
[ "${rel}" = "${target}" ] && rel="${target}"

# `grep -F` com âncora de campo: o target é a 1ª coluna inteira, nunca um prefixo (senão
# `kg.sh` casaria `kg.sh.bak` e o aviso apontaria nós de outro arquivo).
rows="$(LC_ALL=C grep -F "$(printf '%s\t' "${rel}")" "${IDX}" 2>/dev/null | LC_ALL=C awk -F'\t' -v a="${rel}" '$1 == a' || true)"
[ -n "${rows}" ] || exit 0

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
