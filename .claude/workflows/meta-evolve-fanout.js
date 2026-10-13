// meta-evolve-fanout — o fan-out do /meta:evolve como WORKFLOW salvo (peça 4 do comando-com-framework).
// ⚠️ NOME (decisão do maestro, 2026-10-13): até aqui o arquivo era `evolve.js` com `meta.name: 'evolve'`,
//    e o harness o listava como `/evolve` ao lado de `/meta:evolve` — parecia comando ALTERNATIVO, quando
//    é só a peça 4 que o `/meta:evolve` chama no Passo 3. O nome novo diz o que é: peça interna.
//    Arquivo e `meta.name` andam JUNTOS (a bancada cobra): não medimos qual dos dois o harness usa
//    para o nome da lista, então os dois dizem a mesma coisa.
// NASCEU do script que a rodada de 2026-10-04 autorou inline (run wf_9cba4ab5-0ac: 31 agentes,
// 0 erros, 2,1M tokens), persistido aqui porque a rodada achou o defeito que ele cura: o
// `FindingSchema` da superfície NÃO era JSON Schema (`{id:"string"}` como `items:`) — a forma ligada
// ao "0 findings FALSO" de 2026-07-30 — e os quatro símbolos fantasmas do Passo 3 (`runCommand` ×3,
// `sweepSessionMemory`) davam ReferenceError a quem copiasse o molde.
//
// O que ele NÃO faz, por desenho: D4, D5, D9 e D10. São composição (comandos que têm orquestração
// própria) ou exigem o contexto principal (memória de sessão); invocá-los daqui seria orquestração
// aninhada. A superfície os roda como Passo 2.5, no contexto principal, ANTES deste workflow.
//
// Invocação (pela superfície): Workflow({scriptPath: '.claude/workflows/meta-evolve-fanout.js',
//   args: { dims: ['D1','D2','D3','D6','D7','D8','MAQ'], maqTargets: '<seção 7 do raio-X>', cap: 8 }})
// `dims` vazio = todas. `maqTargets` é o CONFRONTO que o raio-X nomeou. Sem ele, uma fase `Census`
// (haiku/low) roda o raio-X e extrai a seção 7 VERBATIM, conferindo o cabeçalho; se a seção não vier
// inteira, a MAQ fica NÃO MEDIDA com o motivo — nunca alvo inventado.
//
// ⚠️ DISPARADO PELO NOME, SEM ARGS, ESTE SCRIPT COBRE 6 DE 10 DIMENSÕES (medido 2026-10-12 no adotante
//    adotante KG-SSOT): `args` vazio virava `{}`, a MAQ caía só com um `log()` no meio do run, D4/D5/D9/D10
//    nem apareciam como puladas, e o retorno não dizia por quê. Agora o retorno carrega
//    `not_measured: [{d, reason}]` com as DEZ dimensões contabilizadas e `complete` (true só com as 10 —
//    logo nunca daqui sozinho: D4/D5/D9/D10 são do Passo 2.5 de /meta:evolve), e o que vai ficar de
//    fora é logado no INÍCIO, antes do primeiro agente.
export const meta = {
  name: 'meta-evolve-fanout',
  description: 'Peça interna do /meta:evolve (Passo 3): 6 dimensões de varredura + confronto de maquinaria, com verificação adversarial dos achados graves',
  whenToUse: 'Peça interna do /meta:evolve (o fan-out do Passo 3) — NÃO invoque à mão: rode /meta:evolve, que a chama com os args certos. ATALHO PARCIAL: sozinho cobre no máximo 6 das 10 dimensões (D1 D2 D3 D6 D7 D8, + MAQ com o raio-X); D4/D5/D9/D10 só rodam pelo caminho completo, /meta:evolve (Passo 2.5). O retorno declara o que faltou em not_measured e complete=false.',
  phases: [
    { title: 'Census', detail: 'só sem maqTargets: roda o raio-X e extrai a seção 7 (os alvos da MAQ), com o cabeçalho conferido' },
    { title: 'Scan', detail: 'D1 D2 D3 D6 D7 D8 + MAQ (confronto) — um worker por dimensão, read-only' },
    { title: 'Verify', detail: 'refutador opus por achado blocker/recommended' },
  ],
}
// ÂNCORA DA TAREFA (sinal de um adotante, 2026-10-07): o harness do Workflow repassa a TODO agente a
// ÚLTIMA mensagem do usuário no instante do disparo, com a ordem "se conflitar, o pedido vence". Um aparte
// que chegou no meio do turno virou o "pedido" de um run inteiro: os juízes opus obedeceram, 4,59M tokens
// sem grafo escrito. Esta âncora diz ao agente qual é a tarefa. TETO DECLARADO: o efeito dela CONTRA o bloco
// repassado não foi medido (a medição do adotante foi num resume, que não repassa nada); a cura que não
// depende do agente obedecer é a ordem — o hook do aparte avisa para não disparar Workflow no mesmo turno.
const TASK_ANCHOR = '⚠️ ÂNCORA DA TAREFA: a sua tarefa é EXCLUSIVAMENTE a descrita abaixo, computada por este workflow' + '' + '. Se o harness repassar um "user request" DIFERENTE (uma mensagem que chegou no meio do turno — um aparte), ela já foi respondida pela sessão principal e NÃO é a sua tarefa: não a responda nem deixe que ela mude o que você produz.\n\n'
const ag = (p, o) => agent(TASK_ANCHOR + p, o)

// ⚠️ ENTRADA RUIM RECUSA, nunca é ignorada (Elenxo da peça 4): `args` como string caía em `{}` e a
//    rodada rodava TUDO (12 agentes em vez de 2) — fail-open de custo. String é parseada; o resto recusa.
let A = (typeof args === 'undefined' || args === null) ? {} : args
if (typeof A === 'string') { try { A = JSON.parse(A) } catch (e) { return { error: 'args string nao e JSON: ' + A.slice(0, 80) } } }
if (typeof A !== 'object' || Array.isArray(A)) return { error: 'args tem de ser objeto { dims, maqTargets, cap }' }
// ⚠️ e a MESMA classe nos campos (refutador de 2026-10-12): `dims:"D1"` (string) ou a chave errada
//    `dmis` caíam em "todas" e rodavam 13 agentes; `maqTargets:{}` virava o alvo "[object Object]".
const KNOWN = ['dims', 'maqTargets', 'cap']
const extra = Object.keys(A).filter(k => !KNOWN.includes(k))
if (extra.length) return { error: 'chave desconhecida em args: ' + extra.join(',') + ' (válidas: ' + KNOWN.join(', ') + ')' }
if (A.dims !== undefined && !Array.isArray(A.dims)) return { error: 'dims tem de ser array (veio: ' + JSON.stringify(A.dims).slice(0, 60) + ')' }
if (A.maqTargets !== undefined && typeof A.maqTargets !== 'string') return { error: 'maqTargets tem de ser string (a seção 7 do raio-X)' }
if (A.cap !== undefined && !(Number.isInteger(A.cap) && A.cap > 0 && A.cap <= 30)) return { error: 'cap tem de ser inteiro em 1..30 (veio: ' + JSON.stringify(A.cap) + ')' }
const CAP = A.cap || 8
const WANT = Array.isArray(A.dims) && A.dims.length ? A.dims.map(d => String(d).toUpperCase()) : null
const MAQ_TARGETS = String(A.maqTargets || '').trim()

const RO = 'REGRA ABSOLUTA: esta é uma AUDITORIA READ-ONLY. NÃO crie, edite, mova nem apague NENHUM arquivo do repositório. Só leia e meça (Read, Grep, Glob, e Bash apenas para comandos de leitura como find, wc, ls, grep, git log). Toda afirmação precisa de evidência arquivo:linha ou de saída de comando que você REALMENTE executou — nunca de memória. Se não conseguir medir algo, diga que não mediu. Devolva no MÁXIMO ' + CAP + ' achados (os de maior severidade) e informe em total_seen quantos achados você viu no total, para o corte ser declarado.'

const FINDINGS = {
  type: 'object',
  properties: {
    total_seen: { type: 'integer' },
    findings: { type: 'array', items: { type: 'object', properties: {
      severity: { type: 'string', enum: ['blocker', 'recommended', 'opportunistic'] },
      finding: { type: 'string' },
      evidence: { type: 'string' },
      doctrine_pattern: { type: 'string' },
      target_artifact: { type: 'string' },
      effort: { type: 'string', enum: ['S', 'M', 'L'] },
      exec_command: { type: 'string' },
    }, required: ['severity', 'finding', 'evidence', 'target_artifact', 'effort', 'exec_command'] } },
  },
  required: ['total_seen', 'findings'],
}

const VERDICT = {
  type: 'object',
  properties: {
    refuted: { type: 'boolean' },
    vetoed_phase_merge: { type: 'boolean' },
    reasoning: { type: 'string' },
  },
  required: ['refuted', 'vetoed_phase_merge', 'reasoning'],
}

const DIMS = [
  { d: 'D1', model: 'haiku', effort: 'low', prompt: 'Dimensão D1 — PESO/TAMANHO. Meça `wc -l` de .claude/agents/**/*.md e .claude/commands/**/*.md contra os limites (agentes: 1200 alerta / 1500 teto; comandos: 500 alerta / 800 teto). Classifique: refactor vs isento (template, README). Reporte os que passam do alerta, com a contagem medida.' },
  { d: 'D2', model: 'sonnet', effort: 'medium', prompt: 'Dimensão D2 — REDUNDÂNCIA/OVERLAP. Compare nomes e `description:` do frontmatter de .claude/commands/** e .claude/agents/**. Ache clusters de artefatos que fazem a mesma coisa (ex.: família branch-*, os três de teste, os meta-creators). Para cada cluster, diga se a distinção é real e declarada (ok) ou se é sobreposição sem razão escrita (achado). NUNCA proponha fundir fases dos workflows faseados engineer/* e product/* — isso é invariante.' },
  { d: 'D3', model: 'haiku', effort: 'low', prompt: 'Dimensão D3 — DUPLICAÇÃO >50 LINHAS. Procure blocos de texto repetidos (≥50 linhas iguais ou quase) entre arquivos de .claude/commands/**, candidatos a virar fragmento em .claude/commands/common/prompts/ ou common/templates/. Meça o tamanho do bloco e os arquivos onde ele aparece.' },
  { d: 'D6', model: 'sonnet', effort: 'medium', prompt: 'Dimensão D6 — MODERNA vs LEGADA + VAZAMENTO SDAAL. (a) Prosa/delegação sequencial em comandos que deveria ser fan-out (Workflow) ou que descreve orquestração que não existe. (b) Resíduo do que foi ABANDONADO em 2026-05-18: `.onion/`, CLI standalone, npm, multi-IDE no core. (c) Vazamento provider-specific: chamada direta a provider (mcp_<provider>_*) ou "MCP como transporte default" FORA de .claude/utils/task-manager/adapters/ e dos agentes especialistas — viola API-first. Evidência arquivo:linha.' },
  { d: 'D7', model: 'haiku', effort: 'low', prompt: 'Dimensão D7 — CROSS-REFS / LINKS. Rode `find .claude -xtype l` (symlinks quebrados) e verifique links relativos markdown `[texto](caminho)` em .claude/commands/** e .claude/agents/** que apontem para arquivo inexistente. Ignore .claude/worktrees/ inteiro. Reporte cada link morto com arquivo:linha e o alvo que não existe.' },
  { d: 'D8', model: 'haiku', effort: 'low', prompt: 'Dimensão D8 — FRONTMATTER + INVENTÁRIO. (a) Verifique frontmatter de comandos e agentes: campos obrigatórios, nomes kebab-case. (b) Rode `bash .claude/validation/inventory.sh --markdown` e compare com docs/onion/inventory.md e com as contagens citadas no CLAUDE.md (comandos, agentes, skills). Divergência = achado, e o atuador é /meta:inventory, nunca edição manual.' },
  { d: 'MAQ', model: 'opus', effort: 'high', prompt: 'Dimensão MAQ — CONFRONTO DE MAQUINARIA (a dimensão que nenhum órgão isolado cobre). O raio-X do framework nomeou os alvos abaixo, cruzando dimensões. Verifique CONTRA O VIVO, um por um, se cada um é REAL e AINDA PRESENTE, e qual a cura mínima. Procure também a classe "texto que cita um comando é lido como invocação viva" por algum mecanismo (lint, harness, extrator da REGRA 59) — e diga quais sítios estão vivos. Severidade blocker só se o defeito engana a sessão ou o gate.\n\nALVOS DO RAIO-X:\n' + MAQ_TARGETS },
]

const COMPOSED = ['D4', 'D5', 'D9', 'D10']
const ALL_DIMS = ['D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8', 'D9', 'D10', 'MAQ']
const COMPOSED_REASON = 'composição — só via /meta:evolve (Passo 2.5, contexto principal); este workflow não a mede'
// not_measured: o motivo por dimensão, NUNCA uma lista nua (a 1ª versão misturava "não pedida" com
// "sem alvo" em `skipped`, e o retorno não dizia qual das duas).
const NOT = new Map(COMPOSED.map(d => [d, COMPOSED_REASON]))
const unknown = (WANT || []).filter(d => !DIMS.some(x => x.d === d))
if (unknown.length) return { error: unknown.some(d => COMPOSED.includes(d))
  ? 'dimensão ' + unknown.join(',') + ' é composição: D4/D5/D9/D10 rodam no contexto principal (Passo 2.5), nunca aqui'
  : 'dimensão desconhecida: ' + unknown.join(',') + ' (válidas aqui: ' + DIMS.map(x => x.d).join(' ') + ')' }
for (const x of DIMS) if (WANT && !WANT.includes(x.d)) NOT.set(x.d, 'não pedida (dims=' + WANT.join(',') + ')')
const wantMaq = !WANT || WANT.includes('MAQ')
// O que fica de fora é declarado AGORA, antes do primeiro agente — e não no meio do run, onde a 1ª
// versão logava a MAQ caindo e ninguém lia.
log('FORA desta rodada (antes de rodar): ' + [...NOT.entries()].map(([d, r]) => d + ' (' + r + ')').join('; ') +
  (wantMaq && !MAQ_TARGETS ? '; MAQ depende da fase Census (sem maqTargets)' : ''))

// ── Census: os alvos da MAQ vêm do raio-X, nunca da cabeça do worker ──────────────────────────
// O agente só EXECUTA e devolve o stdout; a extração da seção 7 é deste script, determinística, e
// exige os DOIS cabeçalhos — o da seção 7 e o do não-medido que a fecha — para provar que a saída
// veio inteira e não um resumo do agente.
let maqTargets = MAQ_TARGETS
if (wantMaq && !maqTargets) {
  phase('Census')
  const cen = await ag('Rode EXATAMENTE este comando na raiz do repositório e devolva o stdout INTEIRO, verbatim, sem resumir, sem reformatar, sem comentar: `bash .claude/validation/evolve-census.sh . --markdown`. Devolva também o exit code. NÃO modifique nenhum arquivo.', {
    label: 'census', phase: 'Census', model: 'haiku', effort: 'low',
    schema: { type: 'object', properties: { stdout: { type: 'string' }, rc: { type: 'integer' } }, required: ['stdout', 'rc'] },
  }).catch(() => null)
  const out7 = (cen && typeof cen.stdout === 'string') ? cen.stdout : ''
  const i7 = out7.indexOf('## 7. CONFRONTO')
  const iEnd = out7.indexOf('## O QUE NÃO FOI MEDIDO', i7 + 1)
  if (!cen) NOT.set('MAQ', 'Census: o agente não devolveu (morreu ou lançou) — alvos não levantados')
  else if (i7 < 0 || iEnd < 0) NOT.set('MAQ', 'Census: a saída não trouxe a seção 7 inteira (cabeçalhos "## 7. CONFRONTO" e "## O QUE NÃO FOI MEDIDO") — recusada, nunca alvo inventado')
  else if (cen.rc !== 0) NOT.set('MAQ', 'Census: evolve-census.sh saiu rc=' + cen.rc + ' — alvos não levantados')
  // seção 7 SEM ALVO (peças não medidas, ou corpo vazio) não é alvo: rodar a MAQ sobre ela seria
  // "medida" sem nada a medir (refutador de 2026-10-12)
  else if (!out7.slice(i7 + '## 7. CONFRONTO'.length, iEnd).replace(/^[^\n]*\n/, '').trim() || /peças NÃO MEDIDAS/.test(out7.slice(i7, iEnd)))
    NOT.set('MAQ', 'Census: a seção 7 veio sem alvos (peças não medidas ou corpo vazio) — nada a confrontar')
  else maqTargets = out7.slice(i7).trim()
  if (NOT.has('MAQ')) log('MAQ: ' + NOT.get('MAQ') + ' — NÃO MEDIDA')
}
const RUN = DIMS.filter(x => !NOT.has(x.d)).map(x => x.d === 'MAQ'
  // slice, nunca `.replace` com string: `$&`/`$1` dentro dos alvos seriam interpretados como padrão
  ? { ...x, prompt: x.prompt.slice(0, x.prompt.indexOf('ALVOS DO RAIO-X:\n')) + 'ALVOS DO RAIO-X:\n' + maqTargets } : x)
if (!RUN.length) return { error: 'nada a rodar (dims vazias após filtro)', not_measured: [...NOT.entries()].map(([d, reason]) => ({ d, reason })), complete: false }

phase('Scan')
const results = await pipeline(
  RUN,
  (dim) => ag(RO + '\n\n' + dim.prompt, {
    label: 'scan:' + dim.d, phase: 'Scan', schema: FINDINGS, model: dim.model, effort: dim.effort,
  }),
  (scan, dim) => {
    if (!scan) { log(dim.d + ': worker morreu — dimensão NÃO MEDIDA'); return { d: dim.d, dead: true, total_seen: 0, findings: [] } }
    // findings ausente ou não-array é worker que não devolveu a forma: dead, nunca "mediu e achou zero"
    if (!Array.isArray(scan.findings)) { log(dim.d + ': worker devolveu sem findings[] — dimensão NÃO MEDIDA'); return { d: dim.d, dead: true, total_seen: 0, findings: [] } }
    const fs = scan.findings.map((f, i) => ({ ...f, id: dim.d + '-' + i, dimension: dim.d }))
    if ((scan.total_seen || 0) > fs.length) log(dim.d + ': ' + scan.total_seen + ' vistos, ' + fs.length + ' devolvidos (corte declarado)')
    // julga blocker/recommended E todo achado que toque o invariante de fase — inclusive opportunistic
    // (Elenxo: um opportunistic que propõe fundir fases escapava do veto, e a superfície prometia o oposto)
    const touchesPhases = f => /(engineer|product)\/|fund|consolid|merge/i.test((f.target_artifact || '') + ' ' + (f.exec_command || '') + ' ' + (f.finding || ''))
    const toVerify = fs.filter(f => f.severity !== 'opportunistic' || touchesPhases(f))
    return parallel(toVerify.map(f => () => ag(
      'Você é um refutador. Mandato: REFUTAR este achado de auditoria do Sistema Onion. Default: refuted=true na dúvida. ' +
      'Abra o arquivo citado e confira a evidência você mesmo — não aceite a palavra do auditor. ' +
      'Marque vetoed_phase_merge=true se a proposta fundir fases dos workflows faseados engineer/* ou product/* (invariante do framework). ' +
      'NÃO modifique nenhum arquivo.\n\nACHADO [' + f.id + '] (' + f.severity + '):\n' + f.finding +
      '\nEVIDÊNCIA: ' + f.evidence + '\nALVO: ' + f.target_artifact + '\nPROPOSTA: ' + f.exec_command,
      { label: 'verify:' + f.id, phase: 'Verify', schema: VERDICT, model: 'opus', effort: 'high' }
    // ⚠️ a entrada de veredito existe SEMPRE, inclusive quando o juiz devolve null ou lança: a 1a versão
    //    deixava o achado em `survived` sem juiz e ainda contava como "verificado" (Elenxo, blocker 1).
    ).then(v => ({ id: f.id, verdict: v || null }), () => ({ id: f.id, verdict: null })))).then(vs => ({
      d: dim.d, dead: false, total_seen: scan.total_seen, findings: fs,
      verdicts: toVerify.map((f, i) => vs[i] || { id: f.id, verdict: null }),
    }))
  },
)

const out = results.filter(Boolean)
// ⚠️ dimensão cujo stage LANÇOU some do pipeline (vira null e o filter a apaga) — a 1a versão a perdia
//    sem log nenhum (Elenxo, blocker 2). `lost` = o que devia rodar e não voltou: lacuna, nunca zero.
const lost = RUN.map(x => x.d).filter(d => !out.some(r => r.d === d))
for (const d of lost) log(d + ': o worker LANÇOU — dimensão NÃO MEDIDA (lost)')
const all = out.flatMap(r => r.findings)
const verdicts = out.flatMap(r => r.verdicts || [])
const judged = verdicts.filter(v => v.verdict)
const killed = new Set(judged.filter(v => v.verdict.refuted || v.verdict.vetoed_phase_merge).map(v => v.id))
const unjudgedIds = new Set(verdicts.filter(v => !v.verdict).map(v => v.id))
const survived = all.filter(f => !killed.has(f.id) && !unjudgedIds.has(f.id))
const unjudged = all.filter(f => unjudgedIds.has(f.id))
log('achados: ' + all.length + ' · julgados: ' + judged.length + ' · SEM JUIZ: ' + unjudged.length + ' · refutados/vetados: ' + killed.size + ' · sobreviventes: ' + survived.length)
const skipped = DIMS.filter(x => !RUN.some(r => r.d === x.d)).map(x => x.d)
for (const d of lost) NOT.set(d, 'lost: o worker lançou')
for (const r of out) if (r.dead) NOT.set(r.d, 'dead: o worker morreu sem devolver')
// as DEZ dimensões (+ MAQ) contabilizadas: ou mediu, ou está aqui com motivo. Sem terceira via.
const not_measured = ALL_DIMS.filter(d => NOT.has(d)).map(d => ({ d, reason: NOT.get(d) }))
const measured = ALL_DIMS.filter(d => !NOT.has(d))
const complete = ALL_DIMS.filter(d => d !== 'MAQ').every(d => measured.includes(d))
log('cobertura: ' + measured.filter(d => d !== 'MAQ').length + '/10 dimensões' + (measured.includes('MAQ') ? ' + MAQ' : '') +
  ' · complete=' + complete + (complete ? '' : ' (o caminho completo é /meta:evolve)'))
return {
  complete,
  measured,
  not_measured,
  skipped,
  lost,
  unjudged,
  dims: out.map(r => ({ d: r.d, dead: r.dead, total_seen: r.total_seen, returned: r.findings.length })),
  survived,
  refuted: all.filter(f => killed.has(f.id)).map(f => ({ id: f.id, finding: f.finding, reason: (verdicts.find(v => v.id === f.id) || {}).verdict })),
  verdicts,
}
