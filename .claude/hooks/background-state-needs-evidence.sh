#!/usr/bin/env bash
# =============================================================================
# background-state-needs-evidence.sh — hook Stop: afirmar que um shell de fundo
# "está rodando" exige OBSERVAÇÃO no mesmo turno, nunca saída vazia.
#
# POR QUÊ (defeito medido em 2026-10-02, nesta casa, duas vezes no mesmo turno):
#   um `git commit -q -F -` ficou TRAVADO 31 MINUTOS esperando stdin (heredoc mal
#   escrito: a mensagem foi parseada como argumentos). Eu reportei ao maestro
#   "gate ainda rodando (saída vazia)" — DUAS VEZES — e a frase era falsa. Só um
#   `ps` separou os dois casos, e ele só aconteceu porque O MAESTRO PERGUNTOU
#   "tudo ok com os 2 shells?".
#   A RAIZ: **saída vazia é indistinguível de progresso.** Um processo travado, um
#   processo que morreu antes de escrever e um processo que está trabalhando
#   produzem o MESMO arquivo de 0 byte. É a mesma classe de
#   `exit-code-nao-e-a-verificacao`: ausência de sinal não é sinal.
#   E o harness piora: no timeout ele notifica `completed`, que se lê como
#   "terminou" quando significa "foi morto".
#   POR QUE HOOK E NÃO HÁBITO: esta foi a ÚNICA das cinco correções daquele turno
#   que NÃO teve mecanismo — as outras quatro (órfão grau 0, REGRA 58, REGRA 46,
#   REGRA 49) dispararam sozinhas. Gatilho social é cura nula (medido 2026-08-02),
#   e eu já havia escrito a frase falsa duas vezes antes de alguém notar.
#
# COMO: lê a última resposta do assistente E as chamadas de ferramenta do MESMO
#   turno (desde a última mensagem do usuário). Se a prosa AFIRMA estado vivo de
#   processo de fundo e o turno NÃO tem observação (`ps`/`pgrep`/`kill -0`/
#   `jobs`/`gh pr checks`/`gh run`), devolve exit 2.
#
# TETO DECLARADO — e o teto que importa NÃO é o vocabulário, é O QUE ESTA GUARDA
#   ASSUME SOBRE A FORMA DO TRANSCRIPT. Correção do Elenxo (F6): a 1ª redação declarava
#   só a lista de formas, e o defeito que quase matou a guarda estava na outra metade —
#   ela supunha que `type: "user"` fosse mensagem humana, e 85% dessas rows são
#   `tool_result`. Hoje ela assume: (a) `tool_result` aparece em `message.content[].type`;
#   (b) o texto do assistente vem em `content[].text`; (c) `tool_use` traz `name` e
#   `input`. Se o harness mudar qualquer uma, ela degrada em SILÊNCIO — e é por isso que
#   a bancada a exercita por STDIN+TRANSCRIPT, não só pela função pura.
#   O teto secundário, real mas menor: a AFIRMAÇÃO é reconhecida por lista de formas
#   (pt-BR e en), logo redação nova escapa. Ela erra para o lado de CALAR — exonera
#   negação, pergunta, citação e relato de defeito já fechado.
#
# USO: registrado em .claude/settings.json → hooks.Stop. `--selftest` prova os desfechos.
# =============================================================================
set -u

# A AFIRMAÇÃO: estado VIVO de trabalho de fundo. Exige sujeito de processo perto do verbo —
# "a pesquisa segue em curso" (sem gate/commit/lint/shell) não é afirmação sobre shell.
_PAT_CLAIM='(gate|commit|lint|selftest|bancada|shell|processo|task|merge|job)[^.\n]{0,80}(ainda (est[áa]|segue)? ?rodando|segue rodando|est[áa] rodando|rodando agora|em curso|ainda n[ãa]o (terminou|fechou)|still running|in progress)'
_PAT_CLAIM_REV='(ainda (est[áa]|segue)? ?rodando|segue rodando|est[áa] rodando|rodando agora|em curso|still running)[^.\n]{0,80}(gate|commit|lint|selftest|bancada|shell|processo|task|merge|job)'
# A OBSERVAÇÃO que torna a afirmação legítima.
# ⚠️ REGEX DE PYTHON, NÃO DE GREP — e isto é defeito medido no 1º dogfood deste hook: a 1ª redação
# usava `[[:space:]]`, sintaxe POSIX que o `grep` entende e que o `re` do Python trata como NESTED SET
# (ele avisa `FutureWarning: Possible nested set`). O caso (b) reprovou porque o padrão não via
# `ps -eo` — a guarda nasceria CEGA à observação que ela existe para exigir, acusando turno honesto.
# Mesma classe de `bancada-mede-no-locale-do-hook`: o motor que avalia o padrão decide a sintaxe.
_PAT_EVIDENCE='(\bps\s+-|\bps\s+[aux]|pgrep|pkill -0|kill -0|\bjobs\b|gh pr checks|gh run (list|view|watch)|TaskList|TaskGet|BashOutput|/proc/[0-9]+|tasks/[A-Za-z0-9]+\.output)'

_assess() {   # $1 = arquivo com a PROSA · $2 = arquivo com as CHAMADAS do turno
  python3 - "$1" "$2" "${_PAT_CLAIM}" "${_PAT_CLAIM_REV}" "${_PAT_EVIDENCE}" <<'PY'
import re, sys
# ⚠️ ERRO DO PYTHON != OFENSA (F9 do Elenxo): a 1a versao usava exit 1 para ofensa, e um traceback
# tambem sai 1 — logo regex invalida virava VETO com bullet VAZIO, acusando turno honesto na FALHA,
# contra a clausula 4. Agora: 1 = ofensa provada; qualquer excecao = fail-OPEN (0) com aviso.
try:
    prose = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    calls = open(sys.argv[2], encoding="utf-8", errors="replace").read()
    claim, claim_rev, ev = sys.argv[3], sys.argv[4], sys.argv[5]
    prose = re.sub(r"```.*?```", "", prose, flags=re.S)       # bloco de codigo nao e afirmacao
    prose = re.sub(r"`[^`\n]*`", " ", prose)                  # crase: cita a FORMA, nao afirma
    # ⚠️ EXONERACAO POR SENTENCA (F4/F6 do Elenxo, 6 falsos positivos provados). A 1a versao
    # acusava a redacao CURADA — "o gate NAO esta rodando mais, terminou" — e tambem citacao do
    # usuario, pergunta e relato historico do proprio incidente. A frase que a guarda QUER que a
    # sessao escreva depois de observar era justamente a que ela vetava.
    NEG = re.compile(r"\b(n[ãa]o|nenhum[a]?|nunca|deixou de)\b", re.I)
    DONE = re.compile(r"\b(terminou|terminei|fechou|fechado|morreu|morto|conclu|rc=\d|exit \d)", re.I)
    def exonerated(sent):
        return bool(NEG.search(sent) or DONE.search(sent)
                    or sent.lstrip().startswith(">") or sent.rstrip().endswith("?"))
    hits = []
    for pat in (claim, claim_rev):
        for m in re.finditer(pat, prose, re.I):
            # a SENTENCA do hit, nao a linha: markdown embrulha prosa (licao medida nesta casa)
            a = max(prose.rfind(".", 0, m.start()), prose.rfind("\n", 0, m.start())) + 1
            b = m.end()
            nxt = re.search(r"[.\n]", prose[m.end():])
            if nxt:
                b = m.end() + nxt.end()
            if exonerated(prose[a:b]):
                continue
            frag = m.group(0).strip()
            if frag not in hits:
                hits.append(frag)
    if not hits:
        sys.exit(0)                                            # nada afirmado -> cala
    if re.search(ev, calls, re.I):
        sys.exit(0)                                            # afirmou E observou -> ok
    for h in hits[:3]:
        print(h)
    sys.exit(1)
except SystemExit:
    raise
except Exception as _e:
    sys.stderr.write("background-state-needs-evidence: falhei ao avaliar (%s) — NAO vetei (fail-open).\n" % _e)
    sys.exit(0)
PY
}

if [ "${1:-}" = "--selftest" ]; then
  fails=0; _p="$(mktemp)"; _c="$(mktemp)"
  record_pass_or_echo() { echo "  ✅ $1"; }
  _fail_e2e() { echo "  ✗ $1 — $2"; fails=$((fails+1)); }
  # (a) AFIRMA sem observar → acusa (o defeito medido, verbatim)
  printf 'gate ainda rodando (saída vazia)\n' > "${_p}"; printf 'cat /tmp/out\nwc -c /tmp/out\n' > "${_c}"
  if ! _assess "${_p}" "${_c}" >/dev/null; then echo "  ✅ (a) afirma estado vivo SEM observação → acusa"; else echo "  ✗ (a) passou com a frase que causou o defeito"; fails=$((fails+1)); fi
  # (b) AFIRMA e OBSERVOU com ps → cala
  printf 'O gate ainda está rodando (2 processos vivos).\n' > "${_p}"; printf 'ps -eo pid,etime,args | grep lint\n' > "${_c}"
  if _assess "${_p}" "${_c}" >/dev/null; then echo "  ✅ (b) afirma COM ps no turno → cala"; else echo "  ✗ (b) falso positivo com observação presente"; fails=$((fails+1)); fi
  # (c) CI por gh pr checks também é observação
  printf 'O merge está em curso no CI.\n' > "${_p}"; printf 'gh pr checks 903\n' > "${_c}"
  if _assess "${_p}" "${_c}" >/dev/null; then echo "  ✅ (c) gh pr checks conta como observação"; else echo "  ✗ (c) rejeitou observação legítima do forge"; fails=$((fails+1)); fi
  # (d) prosa sem afirmação de processo → cala (não vira guarda-de-tudo)
  printf 'A pesquisa segue em curso e o maestro decide.\n' > "${_p}"; : > "${_c}"
  if _assess "${_p}" "${_c}" >/dev/null; then echo "  ✅ (d) 'em curso' sem sujeito de processo não é acusado"; else echo "  ✗ (d) falso positivo em prosa comum"; fails=$((fails+1)); fi
  # (e) bloco de código não é afirmação
  printf 'Veja:\n```\ngate ainda rodando\n```\n' > "${_p}"; : > "${_c}"
  if _assess "${_p}" "${_c}" >/dev/null; then echo "  ✅ (e) bloco de código isento"; else echo "  ✗ (e) acusou dentro de bloco de código"; fails=$((fails+1)); fi
  # (f) ordem invertida da frase também casa
  printf 'Ainda rodando o selftest da bancada.\n' > "${_p}"; : > "${_c}"
  if ! _assess "${_p}" "${_c}" >/dev/null; then echo "  ✅ (f) ordem invertida (verbo antes do sujeito) é vista"; else echo "  ✗ (f) cega à ordem invertida"; fails=$((fails+1)); fi
  rm -f "${_p}" "${_c}"

  # ══ PONTA-A-PONTA: o hook COMO O HARNESS O INVOCA (stdin JSON + transcript) ══════════════
  # ⚠️ ESTES CASOS SAO A CURA ESTRUTURAL DO ELENXO, e sem eles a guarda nasceu INUTIL: os seis
  # casos acima alimentam `_assess`, uma funcao PURA, e TODOS os quatro bloqueadores (F1 a F3, F5)
  # viviam no HARVESTER — a metade que le o transcript e que nenhum caso tocava. Resultado medido:
  # bancada 6/6 verde e a guarda vetando TODO turno honesto em producao (212 vetos em 12.456
  # pontos de parada). E `bancada-espelha-o-runner` violado: a bancada tem de copiar o ARTEFATO e
  # o CAMINHO DE GERACAO do runner, nao um atalho conveniente.
  _d=""; _tp=""; _in=""; _rc=0; _out=""   # sem `local`: este bloco roda no TOP-LEVEL do script, não numa função
  _d="$(mktemp -d)"; _tp="${_d}/t.jsonl"; _in="${_d}/in.json"
  _run_hook() {   # $1 = jsonl do transcript · stdout: saida · retorna rc do hook
    printf '{"transcript_path":"%s","stop_hook_active":false}' "$1" > "${_in}"
    _out="$(bash "${BASH_SOURCE[0]}" < "${_in}" 2>&1)"; return $?
  }

  # (g) TURNO HONESTO — observou com `ps` ANTES do texto, e ha um tool_result no meio (que e row
  #     `type:"user"` e era justamente o que colapsava a janela). Tem de CALAR.
  {
    printf '%s\n' '{"type":"user","message":{"role":"user","content":"como esta o gate?"}}'
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"ps -eo pid,etime,args | grep lint"}}]}}'
    printf '%s\n' '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"2944483 06:10 lint-artifacts.sh"}]}}'
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"O gate ainda esta rodando (1 processo vivo)."}]}}'
  } > "${_tp}"
  _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then record_pass_or_echo "(g) turno honesto com ps ANTES do texto e tool_result no meio → CALA"
  else _fail_e2e "(g) FALSO POSITIVO em turno honesto" "rc=${_rc} saida=[${_out}]"; fi

  # (h) A FRASE FALSA DUAS VEZES no mesmo turno, em blocos de texto distintos — a forma EXATA do
  #     incidente que forjou a guarda. Tem de ACUSAR (a 1a versao via so o ultimo bloco).
  {
    printf '%s\n' '{"type":"user","message":{"role":"user","content":"como estamos?"}}'
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"gate ainda rodando (saida vazia)"}]}}'
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"cat /tmp/out"}}]}}'
    printf '%s\n' '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":""}]}}'
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"Seguindo com o proximo passo."}]}}'
  } > "${_tp}"
  _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 2 ]; then record_pass_or_echo "(h) frase falsa num bloco ANTERIOR ao ultimo → ACUSA"
  else _fail_e2e "(h) a guarda nao pega o PROPRIO defeito de origem" "rc=${_rc} saida=[${_out}]"; fi

  # (i) NEGACAO — a redacao CURADA, que a guarda QUER que a sessao escreva. Tem de CALAR.
  {
    printf '%s\n' '{"type":"user","message":{"role":"user","content":"e o commit?"}}'
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"O commit nao esta rodando mais: terminou com rc=0."}]}}'
  } > "${_tp}"
  _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then record_pass_or_echo "(i) negacao/exoneracao → CALA (nao veta a redacao curada)"
  else _fail_e2e "(i) veta a redacao CURADA" "rc=${_rc} saida=[${_out}]"; fi

  # (j) TaskList como observacao — estava no _PAT_EVIDENCE e era CODIGO MORTO (o harvester nao
  #     colhia o NOME da ferramenta). Tem de CALAR.
  {
    printf '%s\n' '{"type":"user","message":{"role":"user","content":"e a task?"}}'
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"TaskList","input":{}}]}}'
    printf '%s\n' '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"1 running"}]}}'
    printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"A task esta rodando ainda."}]}}'
  } > "${_tp}"
  _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then record_pass_or_echo "(j) observacao por TaskList conta → CALA"
  else _fail_e2e "(j) TaskList no padrao de evidencia e codigo morto" "rc=${_rc} saida=[${_out}]"; fi

  # (k) ANTI-LOOP: stop_hook_active=true nunca veta (senao o turno de correcao e vetado tambem).
  printf '{"transcript_path":"%s","stop_hook_active":true}' "${_tp}" > "${_in}"
  _rc=0; _out="$(bash "${BASH_SOURCE[0]}" < "${_in}" 2>&1)" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then record_pass_or_echo "(k) stop_hook_active=true → nao veta (anti-loop)"
  else _fail_e2e "(k) anti-loop quebrado" "rc=${_rc}"; fi

  rm -rf "${_d}"; unset -f _run_hook
  [ "${fails}" -eq 0 ] && { echo "background-state-needs-evidence selftest: OK"; exit 0; }
  echo "background-state-needs-evidence selftest: ${fails} falha(s)"; exit 1
fi

input="$(cat)"
command -v python3 >/dev/null 2>&1 || exit 0
active="$(printf '%s' "${input}" | python3 -c 'import json,sys; d=json.load(sys.stdin); print("1" if d.get("stop_hook_active") else "0")' 2>/dev/null || echo 0)"
[ "${active}" = "1" ] && exit 0
tp="$(printf '%s' "${input}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("transcript_path",""))' 2>/dev/null || true)"
[ -n "${tp}" ] && [ -f "${tp}" ] || exit 0

_P="$(mktemp)"; _C="$(mktemp)"
python3 - "${tp}" "${_P}" "${_C}" <<'PY'
import json, sys
tp, pf, cf = sys.argv[1], sys.argv[2], sys.argv[3]
rows = []
for line in open(tp, encoding="utf-8", errors="replace"):
    try: rows.append(json.loads(line))
    except Exception: continue

# ⚠️ F1 DO ELENXO — O BLOQUEADOR, e ele invalidava a guarda INTEIRA: `type == "user"` NAO e
# "mensagem humana". No transcript real os `tool_result` TAMBEM sao rows `user` — medido nesta
# sessao: 1123 de 1327 (85%). Logo a 1a versao comecava a janela no ultimo tool_result, e no
# instante do Stop nao ha `tool_use` depois dele: `calls` saia SEMPRE VAZIO, a metade "observacao"
# era CODIGO MORTO (F2) e a guarda vetava INCONDICIONALMENTE. Medido pelo refutador em 12.456
# pontos de parada reais: 212 vetos (1,7%), incluindo turnos em que a sessao estava ativamente
# polando o CI. E a clausula 4 da propria doutrina invertida — errou para o lado de ACUSAR.
def _is_tool_result(j):
    c = (j.get("message") or {}).get("content")
    return isinstance(c, list) and any(
        isinstance(x, dict) and x.get("type") == "tool_result" for x in c)

start = 0
for i, j in enumerate(rows):
    if j.get("type") == "user" and not _is_tool_result(j):
        start = i

prose, calls = [], []
for j in rows[start:]:
    if j.get("type") != "assistant": continue
    for c in (j.get("message") or {}).get("content") or []:
        if not isinstance(c, dict): continue
        if c.get("type") == "text":
            # F3: ACUMULA, nao sobrescreve. A 1a versao guardava so o ULTIMO bloco de texto — e o
            # incidente que forjou esta guarda foi a frase falsa DUAS VEZES no mesmo turno. Com
            # qualquer texto depois dela, NENHUMA era vista: a guarda nao pegava o proprio defeito.
            prose.append(c.get("text") or "")
        elif c.get("type") == "tool_use":
            # F5: o NOME da ferramenta entra junto do input. Sem ele, `TaskList` no _PAT_EVIDENCE
            # era codigo morto — observacao legitima nao contava e o turno honesto era vetado.
            calls.append((c.get("name") or "") + " " +
                         json.dumps(c.get("input") or {}, ensure_ascii=False))
open(pf, "w", encoding="utf-8").write("\n".join(prose))
open(cf, "w", encoding="utf-8").write("\n".join(calls))
PY
offenders="$(_assess "${_P}" "${_C}")" && { rm -f "${_P}" "${_C}"; exit 0; }
rm -f "${_P}" "${_C}"
{
  printf '🫀 ESTADO DE SHELL DE FUNDO AFIRMADO SEM OBSERVAÇÃO (defeito medido 2026-10-02: um `git commit -F -`\n'
  printf '   travado 31 min foi reportado DUAS VEZES como "gate ainda rodando" — saída vazia é indistinguível\n'
  printf '   de progresso). Antes de encerrar o turno, OBSERVE e reescreva com o que viu:\n'
  printf '     ps -eo pid,etime,args | grep -E <padrão> | grep -v grep     # processo vivo?\n'
  printf '     gh pr checks <PR>                                           # estado no forge\n'
  printf '   Afirmações sem observação nesta resposta:\n'
  printf '%s\n' "${offenders}" | sed 's/^/     · /'
} >&2
exit 2
