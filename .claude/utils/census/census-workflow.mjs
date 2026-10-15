export const meta = {
  name: 'onion-census',
  description: 'Censo populacional do backlog: medir nós open contra o vivo (censo+realidade) com juiz fixo',
  phases: [{ title: 'Medir' }, { title: 'Juizo' }],
}
// ÂNCORA DA TAREFA (sinal de um adotante, 2026-10-07): o harness do Workflow repassa a TODO agente a
// ÚLTIMA mensagem do usuário no instante do disparo, com a ordem "se conflitar, o pedido vence". Um aparte
// que chegou no meio do turno virou o "pedido" de um run inteiro: os juízes opus obedeceram, 4,59M tokens
// sem grafo escrito. Esta âncora diz ao agente qual é a tarefa. TETO DECLARADO: o efeito dela CONTRA o bloco
// repassado não foi medido (a medição do adotante foi num resume, que não repassa nada); a cura que não
// depende do agente obedecer é a ordem — o hook do aparte avisa para não disparar Workflow no mesmo turno.
const TASK_ANCHOR = '⚠️ ÂNCORA DA TAREFA: a sua tarefa é EXCLUSIVAMENTE a descrita abaixo, computada por este workflow' + '' + '. Se o harness repassar um "user request" DIFERENTE (uma mensagem que chegou no meio do turno — um aparte), ela já foi respondida pela sessão principal e NÃO é a sua tarefa: não a responda nem deixe que ela mude o que você produz.\n\n'
const ag = (p, o) => agent(TASK_ANCHOR + p, o)
// ============================================================================
// Molde EXECUTÁVEL do /meta:census — versionado porque a forma rodou 2x renascendo em /tmp
// (censo-190 2026-08-30 · revisão-99 2026-09-01, wf_2944480c: 5,39M tokens, 76 agentes).
//
// ENTRADA (Workflow args): { targets: [{id,path,atencao,label}...], teto: <tokens>,
//                            price_per_node: <tokens/nó, default 74000 — o preço REAL medido
//                            na rodada de 2026-09-01 (5.388.890/72≈74k; o budget declarado de
//                            45k foi aspiração: o campo budget do agent() não é teto duro)> }
//
// DISCIPLINA DE CUSTO (exigência do maestro, 2026-09-01):
//   O JS NÃO observa tokens reais (usage chega na notificação, fora do script). O teto é
//   ENFORÇADO por contagem: max_nos = floor(teto / price_per_node); alvos além disso saem
//   como NAO_MEDIDO_POR_TETO **nomeados** — nunca silêncio, nunca "declarado e estourado".
//   Recalibre price_per_node a cada rodada com o usage da notificação (seção valeu-a-pena).
// ============================================================================
const targets = args.targets
const budgetCap = args.teto || 2000000   // `args.teto` e chave de CONTRATO (o /meta:census a passa); a variavel local segue o padrao de idioma
const price = args.price_per_node || 74000
if (!Array.isArray(targets) || targets.length === 0) throw new Error('census: args.targets vazio — extraia com kg-census-extract.sh primeiro')
const maxNodes = Math.max(1, Math.floor(budgetCap / price))
const ordenados = [...targets].sort((a, b) => b.atencao - a.atencao)
const selecionados = ordenados.slice(0, maxNodes)
// a CHAVE `nao_medidos_por_teto` e contrato (census-seal.py a le); a variavel segue o idioma do codigo
const unmeasuredByCap = ordenados.slice(maxNodes).map(t => t.id)
const WSchema = {
  type: 'object',
  required: ['node_id','kg_file','method','observed','verdict','divergence','blocked_by','claims_total','claims_measured','coverage','realidade','proximo_passo','gatilho','gatilho_disparou'],
  properties: {
    node_id: { type: 'string', minLength: 1 },
    kg_file: { type: 'string', minLength: 1 },
    method: { type: 'string', minLength: 1 },
    observed: { type: 'string', minLength: 1 },
    verdict: { enum: ['CONFIRMED','DRIFTED','REFUTED','UNVERIFIABLE'] },
    divergence: { type: 'string' },
    blocked_by: { type: 'string' },
    proposed_write: { type: 'string' },
    claims_total: { type: 'integer', minimum: 1 },
    claims_measured: { type: 'integer', minimum: 0 },
    coverage: { enum: ['TOTAL','PARCIAL'] },
    realidade: { enum: ['REAL-ACIONAVEL','GATED','MORTO-CANDIDATO','FORA-DO-CORE'] },
    proximo_passo: { type: 'string' },
    gatilho: { type: 'string' },
    gatilho_disparou: { enum: ['SIM','NAO','N/A'] },
  },
  if: { required: ['coverage'], properties: { coverage: { const: 'PARCIAL' } } },
  then: { required: ['verdict','blocked_by'], properties: { verdict: { const: 'UNVERIFIABLE' }, blocked_by: { type: 'string', minLength: 1 } } },
  else: {
    if: { required: ['verdict'], properties: { verdict: { const: 'UNVERIFIABLE' } } },
    then: { required: ['blocked_by'], properties: { blocked_by: { type: 'string', minLength: 1 } } },
    else: { required: ['blocked_by'], properties: { blocked_by: { const: '' } } },
  },
}
// >>> overcoming-gate — O JUIZ QUE REPROVA BUSCA O QUE SUPERA (SAC-151). SSOT: este bloco; o
// census-workflow.mjs carrega cópia BYTE A BYTE (a bancada confere) e o judge-verdict-check.sh o EXECUTA
// para os juízes conduzidos pela sessão (/meta:cc-update, /meta:radar, /meta:dissect).
// Maestro, 2026-10-15 (verbatim): "um juiz de sim ou não sem tentar superação em uma pesquisa pode restringir
// possibilidades de crescimento e inovação; é preciso ter medição e critérios claros". Duas metades:
// (a) veredito NEGATIVO carrega `superacao: {classe, achada, o_que, medida}` — a peça, variante ou caminho que
//     entregaria o valor que o objeto prometia; `achada:false` exige a razão MEDIDA (o que se procurou e onde);
// (b) o critério de reprovação é PRÉ-REGISTRADO (args ou o default do juiz) e o veredito cita o `id` e o
//     `comando` que o checa. Negativo sem as duas metades é RECUSADO aqui, no motor (fail-closed, contado):
//     não vale como reprovação NEM como aprovação — o objeto fica não-julgado, nunca liberado.
// Evidência que motivou: a dissecação do markitdown num adotante de curadoria (PR #26, merge a2f8a5aef524) fechou em
// REJEITAR COM superação medida (o tesseract local lê o PDF escaneado em que a ferramenta sai vazia), e o
// critério 1 do teste da régua deu INCONCLUSIVO porque o desenho não apontava o que superaria o teste.
// TETO DECLARADO: o motor confere FORMA e PERTENÇA (o id está no registro, o comando não é vazio); se o
// comando citado de fato reprova o objeto é trabalho de quem re-roda — o comando fica no grafo para isso.
// ── SUPERAÇÃO DE CONSOLO (SAC-151, 2ª leva, 2026-10-15) ── achado de campo de um adotante de curadoria (PR #30,
// DADO): ao pagar a dívida, a 1ª versão preencheu 4 superações que o gate aceitou e só o Elenxo dela reprovou —
// (a) carimbo ou condição FUTURA, (b) peça ainda EM CURA, (c) o STATUS QUO dado como superação, (d) costura
// CIRCULAR (a superação é parte do próprio veredito). É Goodhart: preencher o campo para passar. O que a máquina
// consegue ver aqui, ela recusa: `classe` ausente ou incoerente com `achada`; `o_que` IGUAL ao próprio objeto
// (circular); `medida` que É o comando do critério da reprovação, sem mais nada (mede a reprovação, não a
// entrega — a forma medida dos 4 consolos). Só IGUALDADE, de propósito (refutador, 2026-10-15): a variante do
// objeto ("o markitdown com OCR") e o critério aplicado à variante são as formas mais fortes de superação, e a
// inclusão as recusaria. O resto (status quo, condição futura em prosa, `o_que` que só parafraseia o objeto)
// a máquina NÃO vê sem palavra-chave frágil: vai como PERGUNTA OBRIGATÓRIA ao juiz (CONSOLO_QUESTION),
// respondida no campo `classe`. TETO: o voto do Verify não carrega alvo no schema, então lá a recusa circular
// não roda (só a da âncora e a da classe).
const CONSOLO_QUESTION = 'a superação está MEDIDA e ENTREGA o valor que o objeto prometia, ou é status quo, condição futura ou parte do próprio veredito?'
const OVERCOMING_PROPS = {
  superacao: { type: 'object', required: ['classe', 'achada', 'o_que', 'medida'], properties: {
    classe: { enum: ['entrega', 'nenhuma'] }, achada: { type: 'boolean' }, o_que: { type: 'string' }, medida: { type: 'string' } } },
  criterio: { type: 'object', required: ['id', 'comando'], properties: { id: { type: 'string' }, comando: { type: 'string' } } } }
const _ogFilled = (s, min) => typeof s === 'string' && s.trim().length >= min
// critérios do chamador (args) substituem o default SÓ quando bem formados: {id, when, check}
function criteriaFrom(override, defaults) {
  const list = Array.isArray(override) ? override.filter(c => c && _ogFilled(String(c.id || ''), 1) && _ogFilled(String(c.check || ''), 3))
    .map(c => ({ id: String(c.id).trim(), when: String(c.when || '').trim(), check: String(c.check).trim() })) : []
  return list.length ? list : defaults
}
const criteriaBlock = (criteria) => '\n\n## Critérios de reprovação PRÉ-REGISTRADOS (reprovar fora deles é preferência, não medida)\n' +
  criteria.map(c => '- `' + c.id + '` — ' + c.when + ' · checa: `' + c.check + '`').join('\n') +
  '\n\n## Todo veredito NEGATIVO leva as duas metades (o motor RECUSA e conta o que vier sem elas)\n' +
  '- `criterio: {id, comando}` — o `id` de UM critério acima e o comando concreto (com os argumentos deste caso) que qualquer um re-roda para ver a reprovação.\n' +
  '- `superacao: {classe, achada, o_que, medida}` — antes de reprovar, PROCURE o que supera: a peça, variante, fonte ou caminho que entregaria o valor que o objeto prometia. `achada:true` → `o_que` nomeia e `medida` diz como se mediu; `achada:false` → `medida` diz o que se procurou e onde (comando ou fonte), nunca "não encontrei" seco.\n' +
  '- PERGUNTA OBRIGATÓRIA antes de preencher `classe`: ' + CONSOLO_QUESTION + ' Só `classe: "entrega"` (com `achada:true`) quando a superação JÁ foi medida entregando aquele valor; status quo, carimbo ou condição futura, peça ainda em cura e costura que é parte do próprio veredito são CONSOLO e vão como `classe: "nenhuma"` (com `achada:false`) e a razão medida. `nenhuma` honesta é veredito válido; consolo preenchido para passar é o que o Elenxo reprova.'
const _ogNorm = (x) => String(x == null ? '' : x).toLowerCase().replace(/[`'"]/g, '').replace(/\s+/g, ' ').trim()
const _ogSquash = (x) => _ogNorm(x).replace(/\s+/g, '')
function overcomingWhy(v, criteria) {
  const s = v && v.superacao
  if (!s || typeof s !== 'object' || typeof s.achada !== 'boolean') return 'veredito negativo sem superacao {classe, achada, o_que, medida}'
  if (s.classe !== 'entrega' && s.classe !== 'nenhuma') return 'superacao sem classe (entrega|nenhuma): responda a pergunta do consolo'
  if ((s.classe === 'entrega') !== s.achada) return 'superacao com classe ' + s.classe + ' contradiz achada:' + s.achada
  if (s.achada && !_ogFilled(s.o_que, 8)) return 'superacao achada sem o_que (a peca, variante ou caminho que supera)'
  if (!_ogFilled(s.medida, 8)) return s.achada ? 'superacao achada sem a medida que a sustenta' : 'superacao nao achada sem a razao MEDIDA (achada:false exige medida)'
  const c = v.criterio
  if (!c || typeof c !== 'object' || !_ogFilled(c.id, 1)) return 'veredito negativo sem criterio pre-registrado citado'
  if (!criteria.some(k => k.id === String(c.id).trim())) return 'criterio ' + JSON.stringify(String(c.id)) + ' NAO esta pre-registrado (' + criteria.map(k => k.id).join(', ') + ')'
  if (!_ogFilled(c.comando, 3)) return 'criterio citado sem o comando que o checa'
  if (s.classe === 'entrega') {
    const objTarget = _ogNorm(v.alvo || v.target || v.node_id || v.id || v.claim)
    if (objTarget && _ogNorm(s.o_que) === objTarget) return 'superacao CIRCULAR: o_que e o proprio objeto julgado (consolo)'
    const cmd = _ogSquash(c.comando)
    if (cmd.length >= 8 && _ogSquash(s.medida) === cmd) return 'superacao ancorada no criterio da reprovacao: a medida e o comando que reprova, nao o que entrega (consolo)'
  }
  return ''
}
// separa o que VALE do que o motor recusa: { kept, recused: [{ verdict, why }] }
function gateNegatives(list, isNegative, criteria) {
  const kept = [], recused = []
  for (const v of (list || [])) { if (!v) continue; const why = isNegative(v) ? overcomingWhy(v, criteria) : ''; if (why) recused.push({ verdict: v, why }); else kept.push(v) }
  return { kept, recused }
}
const overcomingsFound = (list) => (list || []).filter(v => v && v.superacao && v.superacao.achada === true && v.superacao.classe === 'entrega')
// <<< overcoming-gate

// critérios PRÉ-REGISTRADOS do juiz fixo (default; `args.rejectionCriteria` substitui) — SAC-151
const JUDGE_CRITERIA = criteriaFrom(args.rejectionCriteria, [
  { id: 'J1_METHOD_NAO_EXECUTADO', when: 'o method não foi executado de fato', check: 're-rodar o comando de method e comparar a saída com observed' },
  { id: 'J2_ARQUIVO_ERRADO', when: 'mediu num arquivo/ambiente que não é o que o trace aponta', check: "grep -n 'trace:' <kg_file> no bloco do nó e comparar com o caminho medido em method" },
  { id: 'J3_CONTAGEM_DESONESTA', when: 'claims_total não bate com as afirmações do label', check: 'contar as afirmações do label do nó em <kg_file> contra claims_total' },
  { id: 'J4_SEM_PROCURA_DA_MORTE', when: 'CONFIRMED sem comando de procura da morte', check: 'method sem git log -S/grep/ls que procure o que superaria o nó' },
  { id: 'J5_GATILHO_DECLARADO', when: 'GATED com gatilho declarado e não medido', check: 'method sem o comando que mede o gatilho' }])
const JSchema = {
  type: 'object',
  required: ['aprovados','reprovados'],
  properties: {
    aprovados: { type: 'array', items: { type: 'string' } },
    reprovados: { type: 'array', items: { type: 'object', required: ['node_id','motivo','superacao','criterio'], properties: { node_id: { type: 'string' }, motivo: { type: 'string' }, ...OVERCOMING_PROPS } } },
  },
}
const medidos = await parallel(selecionados.map((a) => () => ag(
`Censo de backlog do Onion. Repo: raiz do projeto atual. READ-ONLY absoluto (sudo só para LER).
Contexto: censos anteriores mataram metade do backlog — muito "aberto" antigo JÁ FOI entregue ou superado. DRIFTED/MORTO honesto vale mais que CONFIRMED preguiçoso (o juiz reprova CONFIRMED sem procura-da-morte).

NÓ: ${a.id}
ARQUIVO: ${a.path}
ATENÇÃO: ${a.atencao}

1. Leia o nó inteiro (label/trace/verified_against). CONTE as afirmações (claims_total) ANTES de medir.
2. PROCURE A MORTE: o que o nó pede já existe? já respondido/decidido/superado? Meça contra o vivo (git log, arquivos, comandos — verbatim em method/observed). Meça no ARQUIVO/AMBIENTE que o trace aponta, não no vizinho.
3. Vereditos: CONFIRMED=vivo-após-procurar-a-morte · DRIFTED=morto (divergence diz o que o superou) · REFUTED=o nó estava errado · UNVERIFIABLE (blocked_by SEMPRE presente; '' quando nada bloqueou).
4. REALIDADE: REAL-ACIONAVEL (proximo_passo executável de 1 linha) · GATED (gatilho nomeado E MEDIDO → gatilho_disparou SIM/NAO — gatilho declarado-sem-medir é reprovação certa) · MORTO-CANDIDATO · FORA-DO-CORE. gatilho='' e gatilho_disparou='N/A' quando não-GATED.
5. NUNCA escreva. SANITIZE nomes de membros/adotantes/clientes nos textos (<adotante>/<membro>/<cliente> — a guarda de projeção reprova nome comercial).
6. Nó composto: mediu N<M ⇒ UNVERIFIABLE.`,
  { label: `censo:${a.id}`, phase: 'Medir', model: 'sonnet', effort: 'medium', budget: 35000, schema: WSchema }
)))
const vivos = medidos.filter(Boolean)
const descartados = selecionados.length - vivos.length
for (const r of vivos) {
  if (r.claims_measured > r.claims_total) throw new Error(`${r.node_id}: contagem impossível`)
  const real = r.claims_measured < r.claims_total ? 'PARCIAL' : 'TOTAL'
  if (real === 'PARCIAL' && r.verdict !== 'UNVERIFIABLE') { r.verdict='UNVERIFIABLE'; r.blocked_by ||= `cobertura ${r.claims_measured}/${r.claims_total}` }
}
const auditaveis = vivos.filter(r => r.verdict==='CONFIRMED' || (r.realidade==='GATED' && r.gatilho_disparou==='NAO'))
const lotes = []
for (let i=0;i<auditaveis.length;i+=15) lotes.push(auditaveis.slice(i,i+15))
const verdicts = await parallel(lotes.map((lote,ix) => () => ag(
`JUIZ FIXO do censo (mandato REFUTAR, default REPROVADO na dúvida; calibração 2026-08-29: FP 20%, subserviência 0/7). READ-ONLY no repo.
Audite os desfechos PREGUIÇOSOS (CONFIRMED e GATED-não-disparado): method foi EXECUTADO (re-rode o barato)? mediu no arquivo que o trace aponta? contagem de claims honesta contra o label? CONFIRMED procurou a morte? gatilho MEDIDO ou só declarado?
Devolva aprovados (node_ids) e reprovados (node_id+motivo específico).
Reprovar NÃO basta: cada reprovado leva o critério e a superação. Se você MEDIU o que de fato superou o nó (a entrega já existe, com a medida), é "classe: entrega"; se só sabe qual seria a medida certa que o worker devia ter feito, ainda não medida, é "classe: nenhuma", com essa medida como a razão.${criteriaBlock(JUDGE_CRITERIA)}

LOTE ${ix+1}:
${JSON.stringify(lote.map(r=>({node_id:r.node_id,kg_file:r.kg_file,method:r.method.slice(0,300),observed:r.observed.slice(0,300),verdict:r.verdict,claims:r.claims_measured+'/'+r.claims_total,realidade:r.realidade,gatilho:r.gatilho,gatilho_disparou:r.gatilho_disparou})))}`,
  { label: `juiz:lote${ix+1}`, phase: 'Juizo', model: 'opus', effort: 'high', budget: 70000, schema: JSchema }
)))
// SAC-151: reprovação sem critério pré-registrado/superação é RECUSADA pelo motor. FAIL-CLOSED: ela SEGUE em
// `reprovados` (o census-seal.py pula todo reprovado — o nó fica NÃO-JULGADO, nunca carimbado como aprovado por
// omissão, que é o que aconteceria se saísse da lista: o seal trata ausência como juiz N/A e carimba), com o
// motivo prefixado e a contagem em `reprovacoes_recusadas`.
let recusadas = 0
for (const v of verdicts.filter(Boolean)) {
  const g = gateNegatives(v.reprovados, () => true, JUDGE_CRITERIA)
  for (const r of g.recused) { r.verdict.motivo = 'RECUSADA-SEM-SUPERACAO (' + r.why + '): ' + String(r.verdict.motivo || ''); r.verdict.recusada = true; recusadas++ }
}
return {
  reprovacoes_recusadas: recusadas,
  selecionados: selecionados.length,
  nao_medidos_por_teto: unmeasuredByCap,
  descartados_medicao: descartados,
  medidos: vivos,
  juizo: verdicts.filter(Boolean),
  parametros: { teto: budgetCap, price_per_node: price, max_nos: maxNodes },
}
