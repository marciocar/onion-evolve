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
#   `jobs`/`gh pr checks`/`gh run`), devolve exit 2. Desde 2026-10-14 (SAC-137) também contam
#   como observação dois EVENTOS do harness no turno: a `<task-notification>` com status
#   completed, e o lançamento de fundo (tool_result "Command running in background with ID")
#   QUANDO a prosa relata que aguarda a notificação. Ler `tasks/X.output` deixou de contar.
#   Lê só a CAUDA do transcript (lib/transcript-tail.py), com teto e fail-safe.
#   Desde 2026-10-14 (SAC-138) o TÉRMINO também é estado: com lançamento de fundo no turno, afirmar
#   que ele "terminou/passou/foi mergeado/finished" exige a notificação de término ou observação
#   DEPOIS do lançamento. O sujeito tem de vir antes do verbo e ser o fundo (palavra do comando
#   lançado, termo genérico de fundo ou pronome) — senão "o lint passou" de primeiro plano seria veto.
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
# ⚠️ `tasks/X.output` SAIU da lista em 2026-10-14 (SAC-137, rodada r11 do radar E3). Ler o arquivo de
# saída NÃO prova que o processo SEGUE vivo — é a mesma "saída vazia indistinguível de progresso" que
# forjou esta guarda — e a 2.1.300 passou a desestimular a leitura ("do not poll that file or sleep
# while waiting"). A guarda premiava exatamente o hábito que o harness agora pede para largar. Ler o
# arquivo DEPOIS da notificação continua ok; só não conta como observação de estado vivo.
_PAT_EVIDENCE='(\bps\s+-|\bps\s+[aux]|pgrep|pkill -0|kill -0|\bjobs\b|gh pr checks|gh run (list|view|watch)|TaskList|TaskGet|BashOutput|/proc/[0-9]+)'
# O RELATO HONESTO de quem lançou e espera: "aguardo a notificação", "serei notificado". Ele só vale
# junto do LANÇAMENTO de fundo no mesmo turno (o tool_result do harness com o task id) — sem o
# lançamento, a frase é só uma promessa e a afirmação de estado vivo segue vetada.
_PAT_AWAIT='((aguard|esper|wait)\w*[^.\n]{0,40}notifica|notificad[oa] (quando|ao)|will be notified|notified when)'
# A AFIRMAÇÃO DE TÉRMINO (SAC-138, medido 2026-10-14 na passada adversarial do #1127): depois de lançar
# em fundo, "O merge segue rodando e já terminou com sucesso." passava com rc 0 — o "terminou" EXONERAVA
# a afirmação de estado vivo (a exoneração DONE abaixo) e nada exigia prova do término. É a mesma
# mentira com o sinal trocado: afirmar que acabou sem ter visto acabar. Só vale quando houve LANÇAMENTO
# de fundo no turno (BG_LAUNCH) — "o teste terminou" sobre comando de primeiro plano não é desta guarda.
# Só verbo FLEXIONADO no passado/particípio: "quando terminar", "aguardo o término", "once it finishes"
# não casam (são espera, não afirmação). `done` nu ("Done.") não basta: a frase tem de nomear o sujeito.
_PAT_DONE_CLAIM='(\b(j[áa] )?(terminou|terminaram|conclu(iu|[íi]ram|[íi]d[oa]s?)|finaliz(ou|aram|ad[oa]s?)|acab(ou|aram)|mergead[oa]s?|mergeou|mergearam|passou|passaram|ficou verde|ficaram verdes?)\b|\b(completed|finished|succeeded|merged|is done|was done|went green|is green)\b)'
# A PROVA do término: chamada DEPOIS do lançamento que observa o estado (o forge, o processo), ou a
# notificação de término do harness no turno (TASK_DONE). `ps`/`kill -0` provam que MORREU (ausência).
_PAT_DONE_EVIDENCE='(\bps\s+-|\bps\s+[aux]|pgrep|pkill -0|kill -0|\bjobs\b|gh pr (view|checks|status)|gh run (list|view|watch)|gh api|TaskList|TaskGet|TaskOutput|BashOutput|/proc/[0-9]+)'

_assess() {   # $1 = PROSA · $2 = CHAMADAS do turno · $3 (opcional) = EVENTOS do harness no turno
  python3 - "$1" "$2" "${_PAT_CLAIM}" "${_PAT_CLAIM_REV}" "${_PAT_EVIDENCE}" "${_PAT_AWAIT}" "${3:-}" "${_PAT_DONE_CLAIM}" "${_PAT_DONE_EVIDENCE}" <<'PY'
import re, sys
# ⚠️ ERRO DO PYTHON != OFENSA (F9 do Elenxo): a 1a versao usava exit 1 para ofensa, e um traceback
# tambem sai 1 — logo regex invalida virava VETO com bullet VAZIO, acusando turno honesto na FALHA,
# contra a clausula 4. Agora: 1 = ofensa provada; qualquer excecao = fail-OPEN (0) com aviso.
try:
    prose = open(sys.argv[1], encoding="utf-8", errors="replace").read()
    calls = open(sys.argv[2], encoding="utf-8", errors="replace").read()
    claim, claim_rev, ev, await_pat = sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]
    # EVENTOS do harness, colhidos de rows que só o harness escreve (nunca de tool_use nem de saída de
    # ferramenta, onde o literal pode aparecer citado — este próprio hook o cita): BG_LAUNCH <id> e
    # TASK_DONE <id>, um por linha.
    events = ""
    if len(sys.argv) > 7 and sys.argv[7]:
        events = open(sys.argv[7], encoding="utf-8", errors="replace").read()
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
    # ── TÉRMINO afirmado sobre o fundo DESTE turno (SAC-138) ─────────────────────────────────────
    done_claim = sys.argv[8] if len(sys.argv) > 8 else ""
    done_ev = sys.argv[9] if len(sys.argv) > 9 else ""
    launched = bool(re.search(r"^BG_LAUNCH\b", events, re.M))
    if done_claim and launched and not re.search(r"^TASK_DONE\b", events, re.M):
        post = "\n".join(l[len("POST_CALL "):] for l in events.splitlines() if l.startswith("POST_CALL "))
        if not (done_ev and re.search(done_ev, post, re.I)):
            # o SUJEITO tem de ser o fundo: palavra do comando lançado (BG_SUBJ, colhida do input
            # do tool_use com run_in_background), termo genérico de fundo, ou pronome. Sem isso,
            # "o lint passou" sobre o lint de PRIMEIRO plano no mesmo turno seria falso positivo.
            subj = set()
            for l in events.splitlines():
                if l.startswith("BG_SUBJ "):
                    subj.update(w.lower() for w in l.split()[1:])
            generic = r"\b(processo|comando|job|task|shell|fundo|segundo plano|background|PR|it|ele|ela|they)\b"
            DNEG = re.compile(r"\b(n[ãa]o|nenhum[a]?|nunca|not|never)\b|n't\b", re.I)
            for m in re.finditer(done_claim, prose, re.I):
                a = max(prose.rfind(".", 0, m.start()), prose.rfind("\n", 0, m.start()), prose.rfind(";", 0, m.start())) + 1
                nxt = re.search(r"[.;\n]", prose[m.end():])
                b = m.end() + nxt.end() if nxt else len(prose)
                sent = prose[a:b]
                if DNEG.search(sent) or sent.lstrip().startswith(">") or sent.rstrip().endswith("?"):
                    continue
                # o sujeito vem ANTES do verbo (janela de 80): "Os testes passaram e o merge foi lancado"
                # fala dos testes, nao do merge — falso positivo medido na passada adversarial.
                pre = prose[max(a, m.start() - 80):m.start()]
                words = set(re.findall(r"[a-z0-9]{4,}", pre.lower()))
                if not (re.search(generic, pre, re.I) or (words & subj)):
                    continue
                frag = "TÉRMINO sem prova: " + sent.strip()[:120]
                if frag not in hits:
                    hits.append(frag)
            if hits:
                for h in hits[:3]:
                    print(h)
                sys.exit(1)
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
    # A NOTIFICACAO de termino do harness no turno e observacao: e o harness quem diz o estado.
    if re.search(r"^TASK_DONE\b", events, re.M):
        sys.exit(0)
    # LANCOU no turno e RELATA que espera a notificacao: o relato honesto que a 2.1.300 pede
    # (medido 2026-10-14: "segue rodando em segundo plano; aguardo a notificacao" dava rc 2).
    if re.search(r"^BG_LAUNCH\b", events, re.M) and re.search(await_pat, prose, re.I):
        sys.exit(0)
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

  # ══ SAC-137 (rodada r11 do radar E3, 2026-10-14): CAUDA do transcript + eventos do harness ═══════
  _tr="${_d}/trace"
  _gen() {   # $1 = cenario · $2 = arquivo  (fixtures sinteticas; nada do transcript real)
    python3 - "$1" "$2" <<'PY'
import json, sys
kind, out = sys.argv[1], sys.argv[2]
meta = {"k%02d" % i: "v%d" % i for i in range(25)}
U = lambda c, **kw: dict(meta, type="user", message={"role": "user", "content": c}, **kw)
A = lambda *c: dict(meta, type="assistant", message={"content": list(c)})
txt = lambda s: {"type": "text", "text": s}
bash = lambda s: {"type": "tool_use", "name": "Bash", "input": {"command": s}}
res = lambda s: [{"type": "tool_result", "content": s}]
rows = []
if kind == "big":
    # MILHARES de linhas antes do turno, com `ps` e afirmacoes em turnos VELHOS: se a janela vazar
    # para tras do inicio do turno, o `ps` velho exonera e o veredito muda
    for i in range(30000):
        rows += [U("pedido %d" % i), A(bash("ps -eo pid,args | grep lint")), A(txt("O gate segue rodando."))]
    rows += [U("e o gate?"), A(bash("cat /tmp/out")), U(res("")), A(txt("gate ainda rodando (saida vazia)"))]
elif kind in ("long-lie", "long-honest"):
    # TURNO AUTONOMO LONGO: o ultimo user que nao e tool_result fica ~2 MB antes do fim (varios blocos)
    rows += [U("pedido velho"), A(bash("ps -eo pid,args"))]
    rows += [U("vai ate o fim")]
    rows += [A(txt("O gate ainda esta rodando."))] if kind == "long-lie" else [A(bash("ps -eo pid,etime,args | grep lint"))]
    for i in range(3000):
        rows += [A(bash("true " + "z" * 300)), U(res("w" * 300))]
    rows += [A(txt("Seguindo." if kind == "long-lie" else "O gate ainda esta rodando (1 processo vivo)."))]
elif kind == "straddle":
    # a linha que ABRE o turno cortada pela fronteira do 1o bloco lido (1 MiB do fim, o BLOCK do lib):
    # se o pedaco cortado se perder, a cauda passa reto pelo inicio do turno e acha o `ps` do turno velho
    rows += [U("pedido velho"), A(bash("ps -eo pid,args"))]
    head = [U("vai " + "p" * 3000), A(txt("O gate ainda esta rodando."))]
    tail, size = [], len(json.dumps(head[1])) + 1
    while size < (1 << 20) - 1500:
        f = [A(bash("true " + "z" * 300)), U(res("w" * 300))]
        tail += f; size += sum(len(json.dumps(r)) + 1 for r in f)
    rows += head + tail
elif kind in ("launch-await", "await-only", "launch-only"):
    rows += [U("roda o merge")]
    if kind != "await-only":
        rows += [A({"type": "tool_use", "name": "Bash", "input": {"command": "bash merge-serial.sh", "run_in_background": True}}),
                 U(res("Command running in background with ID: b1x2y3. Output is being written to: /tmp/s/tasks/b1x2y3.output. "
                       "You will be notified when it completes — do not poll that file or sleep while waiting."),
                   toolUseResult={"backgroundTaskId": "b1x2y3"})]
    rows += [A(txt("O merge-serial segue rodando em segundo plano." if kind == "launch-only" else
                   "O merge-serial segue rodando em segundo plano; aguardo a notificação de término."))]
elif kind == "output-only":
    rows += [U("e o gate?"), A({"type": "tool_use", "name": "Read", "input": {"file_path": "/tmp/s/tasks/b1x2y3.output"}}),
             U(res("")), A(bash("tail -5 /tmp/s/tasks/b1x2y3.output")), U(res("")), A(txt("O gate ainda esta rodando."))]
elif kind in ("notif-turn", "notif-queued", "notif-quoted"):
    n = ("<task-notification>\n<task-id>b1x2y3</task-id>\n<output-file>/tmp/s/tasks/b1x2y3.output</output-file>\n"
         "<status>completed</status>\n<summary>Background command \"lint\" completed (exit code 0)</summary>\n</task-notification>")
    if kind == "notif-turn":
        rows += [U(n, origin={"kind": "task-notification"})]
    else:
        rows += [U("e o merge?")]
        if kind == "notif-queued":
            rows += [dict(meta, type="attachment", attachment={"type": "queued_command", "prompt": n})]
        else:   # o MESMO literal citado numa saida de ferramenta NAO e evento do harness
            rows += [A(bash("cat hook.sh")), U(res(n))]
    rows += [A(txt("O merge segue em curso no CI."))]
elif kind in ("done-noproof", "done-notif", "done-ghview", "done-en", "done-fgonly", "done-await", "done-mixed", "done-subjafter"):
    # SAC-138: afirmacao de TERMINO sobre o fundo deste turno
    rows += [U("roda o merge")]
    if kind == "done-fgonly":
        rows += [A(bash("bash .claude/validation/lint-selftest.sh --only foo")), U(res("OK"))]
    else:
        rows += [A({"type": "tool_use", "name": "Bash", "input": {"command": "bash merge-serial.sh 1127", "run_in_background": True}}),
                 U(res("Command running in background with ID: b1x2y3. Output is being written to: /tmp/s/tasks/b1x2y3.output. "
                       "You will be notified when it completes — do not poll that file or sleep while waiting."),
                   toolUseResult={"backgroundTaskId": "b1x2y3"})]
    if kind == "done-notif":
        n = ("<task-notification>\n<task-id>b1x2y3</task-id>\n<output-file>/tmp/s/tasks/b1x2y3.output</output-file>\n"
             "<status>completed</status>\n<summary>Background command \"merge\" completed (exit code 0)</summary>\n</task-notification>")
        rows += [dict(meta, type="attachment", attachment={"type": "queued_command", "prompt": n}),
                 A({"type": "tool_use", "name": "Read", "input": {"file_path": "/tmp/s/tasks/b1x2y3.output"}}), U(res("merged"))]
    if kind == "done-ghview":
        rows += [A(bash("gh pr view 1127 --json state -q .state")), U(res("MERGED"))]
    if kind == "done-mixed":   # lint de PRIMEIRO plano no mesmo turno do lancamento de fundo
        rows += [A(bash("bash .claude/validation/lint-artifacts.sh")), U(res("0 HARD"))]
    rows += [A(txt({"done-noproof": "O merge segue rodando e já terminou com sucesso.",
                    "done-notif": "O merge-serial terminou com sucesso (exit 0).",
                    "done-ghview": "O PR 1127 foi mergeado.",
                    "done-en": "The merge job is still being watched; it finished successfully.",
                    "done-fgonly": "O comando de teste terminou e passou.",
                    "done-await": "Lancei o merge-serial em segundo plano e aguardo a notificação de término do merge.",
                    "done-subjafter": "Os testes passaram e o merge-serial foi lançado em segundo plano; aguardo a notificação.",
                    "done-mixed": "O lint de primeiro plano passou com 0 HARD. O merge-serial segue rodando; aguardo a notificação."}[kind]))]
with open(out, "w", encoding="utf-8") as fh:
    for r in rows:
        fh.write(json.dumps(r) + "\n")
PY
  }
  _trace_mode() { sed -n 's/^mode=\([a-z]*\) bytes=\([0-9]*\)$/\1 \2/p' "${_tr}" 2>/dev/null | tail -1; }

  # (l) TRANSCRIPT GRANDE sintetico (90 mil linhas antes do turno): o MESMO veredito (acusa), pelo
  #     caminho da cauda lendo < 2 MiB, e mais rapido que um parse inteiro do arquivo — que e o custo
  #     da versao antiga (~1,0 s em 44,7 MB, medido 2026-10-14).
  _gen big "${_tp}"; : > "${_tr}"
  _t0="$(date +%s%N)"; _rc=0; ONION_TRANSCRIPT_TAIL_TRACE="${_tr}" _run_hook "${_tp}" || _rc=$?; _t1="$(date +%s%N)"
  _hook_ms=$(( (_t1 - _t0) / 1000000 ))
  _f0="$(date +%s%N)"; python3 -c 'import json,sys
for l in open(sys.argv[1], encoding="utf-8", errors="replace"):
    try: json.loads(l)
    except Exception: pass' "${_tp}"; _f1="$(date +%s%N)"
  _full_ms=$(( (_f1 - _f0) / 1000000 ))
  read -r _mode _bytes <<< "$(_trace_mode)"
  if [ "${_rc}" -eq 2 ] && [ "${_mode:-}" = "tail" ] && [ "${_bytes:-9999999999}" -lt 2097152 ] && [ "${_hook_ms}" -lt "${_full_ms}" ]; then
    record_pass_or_echo "(l) transcript de $(( $(stat -c %s "${_tp}") / 1048576 )) MiB: mesmo veredito pela CAUDA (${_bytes} bytes, ${_hook_ms} ms < parse inteiro ${_full_ms} ms)"
  else _fail_e2e "(l) cauda em transcript grande" "rc=${_rc} trace=[${_mode:-sem trace} ${_bytes:-}] hook=${_hook_ms}ms parse-inteiro=${_full_ms}ms"; fi

  # (m) TURNO AUTONOMO LONGO — o caso que pode quebrar: o inicio do turno ~2 MB antes do fim.
  #     (m1) afirmacao falsa no COMECO do turno, sem observacao → acusa, pela cauda em varios blocos;
  #     (m2) o mesmo com teto de 64 KiB → o fail-safe rele inteiro (mode=full) e AINDA acusa;
  #     (m3) `ps` no comeco e a afirmacao no fim → cala (a observacao longe do fim continua vista).
  _gen long-lie "${_tp}"; : > "${_tr}"; _rc=0; ONION_TRANSCRIPT_TAIL_TRACE="${_tr}" _run_hook "${_tp}" || _rc=$?
  read -r _mode _bytes <<< "$(_trace_mode)"
  if [ "${_rc}" -eq 2 ] && [ "${_mode:-}" = "tail" ] && [ "${_bytes:-0}" -gt 1048576 ]; then
    record_pass_or_echo "(m1) turno autonomo longo (${_bytes} bytes, varios blocos): a frase falsa no comeco do turno → ACUSA"
  else _fail_e2e "(m1) turno longo pela cauda" "rc=${_rc} trace=[${_mode:-sem trace} ${_bytes:-}] saida=[${_out}]"; fi
  : > "${_tr}"; _rc=0; ONION_STOP_HOOK_TAIL_MAX_BYTES=65536 ONION_TRANSCRIPT_TAIL_TRACE="${_tr}" _run_hook "${_tp}" || _rc=$?
  read -r _mode _bytes <<< "$(_trace_mode)"
  if [ "${_rc}" -eq 2 ] && [ "${_mode:-}" = "full" ]; then
    record_pass_or_echo "(m2) teto de 64 KiB estourado sem achar o inicio do turno → rele inteiro e AINDA acusa (nunca silencio)"
  else _fail_e2e "(m2) fail-safe do teto" "rc=${_rc} trace=[${_mode:-sem trace} ${_bytes:-}]"; fi
  _gen long-honest "${_tp}"; : > "${_tr}"; _rc=0; ONION_TRANSCRIPT_TAIL_TRACE="${_tr}" _run_hook "${_tp}" || _rc=$?
  read -r _mode _bytes <<< "$(_trace_mode)"
  if [ "${_rc}" -eq 0 ] && [ "${_mode:-}" = "tail" ]; then
    record_pass_or_echo "(m3) turno longo honesto (ps no comeco, afirmacao no fim) → CALA pela cauda"
  else _fail_e2e "(m3) turno longo honesto" "rc=${_rc} trace=[${_mode:-sem trace} ${_bytes:-}] saida=[${_out}]"; fi

  # (m4) a linha que ABRE o turno atravessa a fronteira de bloco: o pedaco de linha tem de ser
  #      emendado ao bloco anterior, senao a cauda passa reto e acha o `ps` do turno velho → acusa
  _gen straddle "${_tp}"; : > "${_tr}"; _rc=0; ONION_TRANSCRIPT_TAIL_TRACE="${_tr}" _run_hook "${_tp}" || _rc=$?
  read -r _mode _bytes <<< "$(_trace_mode)"
  if [ "${_rc}" -eq 2 ] && [ "${_mode:-}" = "tail" ]; then
    record_pass_or_echo "(m4) inicio do turno cortado pela fronteira do bloco → emendado, e a frase falsa ACUSA"
  else _fail_e2e "(m4) linha cortada pela fronteira de bloco" "rc=${_rc} trace=[${_mode:-sem trace} ${_bytes:-}]"; fi

  # (n) LANCOU em fundo e relata que AGUARDA A NOTIFICACAO — a frase medida que dava rc 2. Cala.
  _gen launch-await "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then record_pass_or_echo "(n) lancamento de fundo + 'aguardo a notificacao' → CALA"
  else _fail_e2e "(n) veta o relato honesto de esperar a notificacao" "rc=${_rc} saida=[${_out}]"; fi

  # (o) a frase de espera SEM lancamento nem observacao → continua vetado; e o lancamento sem o
  #     relato de espera tambem (afirmar 'segue rodando' so porque lancou nao e observacao).
  _gen await-only "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  _gen launch-only "${_tp}"; _rc2=0; _run_hook "${_tp}" || _rc2=$?
  if [ "${_rc}" -eq 2 ] && [ "${_rc2}" -eq 2 ]; then record_pass_or_echo "(o) 'segue rodando' sem lancamento (ou lancamento sem relato de espera) → ACUSA"
  else _fail_e2e "(o) a espera virou licenca" "await-only rc=${_rc} · launch-only rc=${_rc2}"; fi

  # (p) so LER tasks/X.output (Read e tail) ja nao prova estado vivo → acusa
  _gen output-only "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 2 ]; then record_pass_or_echo "(p) ler tasks/X.output nao e observacao de processo vivo → ACUSA"
  else _fail_e2e "(p) a leitura do arquivo de saida ainda conta como prova" "rc=${_rc}"; fi

  # (q) a NOTIFICACAO de termino do harness no turno e observacao — como row que abre o turno e como
  #     attachment queued_command; o MESMO literal citado numa saida de ferramenta NAO conta.
  _gen notif-turn "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  _gen notif-queued "${_tp}"; _rc2=0; _run_hook "${_tp}" || _rc2=$?
  _gen notif-quoted "${_tp}"; _rc3=0; _run_hook "${_tp}" || _rc3=$?
  if [ "${_rc}" -eq 0 ] && [ "${_rc2}" -eq 0 ] && [ "${_rc3}" -eq 2 ]; then
    record_pass_or_echo "(q) <task-notification> completed no turno → CALA (row e attachment); citada em tool_result → ACUSA"
  else _fail_e2e "(q) notificacao" "turno rc=${_rc} · queued rc=${_rc2} · citada rc=${_rc3} (esperado 0/0/2)"; fi
  # ══ SAC-138 (passada adversarial do #1127, 2026-10-14): TERMINO afirmado sobre o fundo do turno ══
  # (r1) lancou + "ja terminou com sucesso" sem prova → ACUSA (a frase medida, que dava rc 0)
  _gen done-noproof "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 2 ]; then record_pass_or_echo "(r1) lancamento + 'ja terminou com sucesso' sem prova → ACUSA"
  else _fail_e2e "(r1) termino afirmado sem prova passou" "rc=${_rc} saida=[${_out}]"; fi
  # (r2) lancou + notificacao de termino (attachment) + leitura do output DEPOIS + "terminou" → CALA
  _gen done-notif "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then record_pass_or_echo "(r2) lancamento + <task-notification> completed + 'terminou' → CALA"
  else _fail_e2e "(r2) a notificacao de termino nao conta como prova" "rc=${_rc} saida=[${_out}]"; fi
  # (r3) lancou + `gh pr view` DEPOIS + "foi mergeado" → CALA (passado sobre algo observado)
  _gen done-ghview "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then record_pass_or_echo "(r3) lancamento + gh pr view depois + 'foi mergeado' → CALA"
  else _fail_e2e "(r3) a observacao pelo forge nao conta" "rc=${_rc} saida=[${_out}]"; fi
  # (r4) so primeiro plano + "o teste terminou e passou" → CALA (sem lancamento de fundo no turno)
  _gen done-fgonly "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then record_pass_or_echo "(r4) primeiro plano + 'o teste terminou' → CALA (sem fundo no turno)"
  else _fail_e2e "(r4) falso positivo em comando de primeiro plano" "rc=${_rc} saida=[${_out}]"; fi
  # (r5) lancou + "aguardo a notificacao de termino" → continua CALANDO (o substantivo nao e afirmacao)
  _gen done-await "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then record_pass_or_echo "(r5) lancamento + 'aguardo a notificacao de termino do merge' → CALA"
  else _fail_e2e "(r5) a espera honesta virou termino" "rc=${_rc} saida=[${_out}]"; fi
  # (r6) ingles: lancou + "it finished successfully" sem prova → ACUSA
  _gen done-en "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 2 ]; then record_pass_or_echo "(r6) lancamento + 'it finished successfully' sem prova → ACUSA"
  else _fail_e2e "(r6) cego ao termino em ingles" "rc=${_rc} saida=[${_out}]"; fi
  # (r7) FALSO POSITIVO de vocabulario: lancou o merge em fundo E rodou o lint em PRIMEIRO plano; "o lint
  #      passou" fala do primeiro plano (sujeito fora do comando lancado) → CALA
  _gen done-mixed "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then record_pass_or_echo "(r7) fundo + lint de primeiro plano 'passou' no mesmo turno → CALA (sujeito nao e o fundo)"
  else _fail_e2e "(r7) termino do primeiro plano acusado como se fosse do fundo" "rc=${_rc} saida=[${_out}]"; fi
  # (r8) o fundo nomeado DEPOIS do verbo, na mesma sentenca ("Os testes passaram e o merge-serial foi
  #      lancado") — o verbo fala dos testes. Falso positivo medido na passada adversarial → CALA
  _gen done-subjafter "${_tp}"; _rc=0; _run_hook "${_tp}" || _rc=$?
  if [ "${_rc}" -eq 0 ]; then record_pass_or_echo "(r8) sujeito do fundo so DEPOIS do verbo de termino → CALA"
  else _fail_e2e "(r8) o verbo de outro sujeito acusado pelo fundo citado depois" "rc=${_rc} saida=[${_out}]"; fi
  unset -f _gen _trace_mode

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

_P="$(mktemp)"; _C="$(mktemp)"; _E="$(mktemp)"
python3 - "${tp}" "${_P}" "${_C}" "${_E}" "$(dirname "${BASH_SOURCE[0]}")/lib/transcript-tail.py" <<'PY'
import json, re, sys
tp, pf, cf, ef, lib = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]

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

def _is_turn_start(j):
    return j.get("type") == "user" and not _is_tool_result(j)

# A CAUDA (SAC-137, 2026-10-14): so o ultimo turno, lido de tras para frente pelo lib, com teto e
# fail-safe (estourou o teto sem achar o inicio do turno -> rele o arquivo inteiro, como antes). Antes
# o arquivo INTEIRO ia para uma lista a cada turno: ~1,0 s em 44,7 MB, sem timeout. Sem o lib (copia
# parcial do .claude/), cai na leitura inteira de antes — nunca em silencio.
try:
    import importlib.util
    _spec = importlib.util.spec_from_file_location("transcript_tail", lib)
    _tt = importlib.util.module_from_spec(_spec); _spec.loader.exec_module(_tt)
except Exception:
    _tt = None
if _tt is not None:
    turn = _tt.tail_until(tp, _is_turn_start)
else:
    rows = []
    for line in open(tp, encoding="utf-8", errors="replace"):
        try: rows.append(json.loads(line))
        except Exception: continue
    start = 0
    for i, j in enumerate(rows):
        if _is_turn_start(j):
            start = i
    turn = rows[start:]

# EVENTOS DO HARNESS no turno — so de rows que o HARNESS escreve, nunca de tool_use nem de saida de
# ferramenta (la o literal aparece citado: `cat` deste hook o imprime).
#   BG_LAUNCH: o tool_result de lancamento de fundo ("Command running in background with ID: X",
#              ou o campo toolUseResult.backgroundTaskId);
#   TASK_DONE: a <task-notification> com <status>completed</status>, que chega como row `user` de
#              conteudo string (abre um turno) ou como attachment queued_command (no meio do turno).
_LAUNCH = re.compile(r"\s*Command running in background with ID:\s*([A-Za-z0-9_-]+)")
_NOTIF = re.compile(r"\s*<task-notification>.*?<task-id>([^<]*)</task-id>.*?<status>completed</status>", re.S)
events = []
# SAC-138: as chamadas DEPOIS do 1o lancamento (POST_CALL — a prova de termino tem de vir depois dele) e
# as palavras do comando lancado (BG_SUBJ — o sujeito que uma afirmacao de termino tem de nomear).
_STOP = {"bash", "python", "python3", "true", "null", "home", "marcio", "claude", "with", "from", "into",
         "then", "tail", "head", "grep", "this", "that", "para", "rodar", "roda", "run", "runs", "sh"}
_launched = False
for j in turn:
    t = j.get("type")
    if t == "assistant":
        for c in (j.get("message") or {}).get("content") or []:
            if not (isinstance(c, dict) and c.get("type") == "tool_use"): continue
            inp = c.get("input") or {}
            if _launched:
                events.append("POST_CALL " + (c.get("name") or "") + " " + json.dumps(inp, ensure_ascii=False))
            if isinstance(inp, dict) and inp.get("run_in_background"):
                src = " ".join(str(inp.get(k) or "") for k in ("command", "description"))
                ws = sorted({w for w in re.findall(r"[a-z0-9]{4,}", src.lower()) if w not in _STOP})
                if ws: events.append("BG_SUBJ " + " ".join(ws[:40]))
    elif t == "user":
        c = (j.get("message") or {}).get("content")
        if isinstance(c, str):
            m = _NOTIF.match(c)
            if m: events.append("TASK_DONE " + m.group(1))
        elif isinstance(c, list):
            bid = (j.get("toolUseResult") or {}).get("backgroundTaskId") if isinstance(j.get("toolUseResult"), dict) else None
            for x in c:
                if not (isinstance(x, dict) and x.get("type") == "tool_result"): continue
                body = x.get("content")
                if isinstance(body, list):
                    body = "\n".join(y.get("text", "") for y in body if isinstance(y, dict))
                m = _LAUNCH.match(body or "") if isinstance(body, str) else None
                if m or bid:
                    events.append("BG_LAUNCH " + (m.group(1) if m else str(bid)))
                    _launched = True
    elif t == "attachment":
        a = j.get("attachment") or {}
        if a.get("type") == "queued_command" and isinstance(a.get("prompt"), str):
            m = _NOTIF.match(a["prompt"])
            if m: events.append("TASK_DONE " + m.group(1))
open(ef, "w", encoding="utf-8").write("\n".join(events))

prose, calls = [], []
for j in turn:
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
offenders="$(_assess "${_P}" "${_C}" "${_E}")" && { rm -f "${_P}" "${_C}" "${_E}"; exit 0; }
rm -f "${_P}" "${_C}" "${_E}"
{
  printf '🫀 ESTADO DE SHELL DE FUNDO AFIRMADO SEM OBSERVAÇÃO (defeito medido 2026-10-02: um `git commit -F -`\n'
  printf '   travado 31 min foi reportado DUAS VEZES como "gate ainda rodando" — saída vazia é indistinguível\n'
  printf '   de progresso). Antes de encerrar o turno, OBSERVE e reescreva com o que viu:\n'
  printf '     ps -eo pid,etime,args | grep -E <padrão> | grep -v grep     # processo vivo?\n'
  printf '     gh pr checks <PR>                                           # estado no forge\n'
  printf '   Se LANÇOU o comando em fundo neste turno, o relato honesto é dizer que aguarda a notificação\n'
  printf '   do harness. Ler tasks/<id>.output NÃO prova que o processo segue vivo.\n'
  printf '   E TÉRMINO também é estado (SAC-138): afirmar que o fundo deste turno "terminou/passou/foi\n'
  printf '   mergeado" exige a <task-notification> de término ou uma observação DEPOIS do lançamento\n'
  printf '   (gh pr view/checks, ps, kill -0). Observe ou espere a notificação antes de afirmar que terminou.\n'
  printf '   Afirmações sem observação nesta resposta:\n'
  printf '%s\n' "${offenders}" | sed 's/^/     · /'
} >&2
exit 2
