export const meta = {
  name: 'onion-census',
  description: 'Censo populacional do backlog: medir nós open contra o vivo (censo+realidade) com juiz fixo',
  phases: [{ title: 'Medir' }, { title: 'Juizo' }],
}
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
const teto = args.teto || 2000000
const price = args.price_per_node || 74000
if (!Array.isArray(targets) || targets.length === 0) throw new Error('census: args.targets vazio — extraia com kg-census-extract.sh primeiro')
const maxNodes = Math.max(1, Math.floor(teto / price))
const ordenados = [...targets].sort((a, b) => b.atencao - a.atencao)
const selecionados = ordenados.slice(0, maxNodes)
const nao_medidos_por_teto = ordenados.slice(maxNodes).map(t => t.id)
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
const JSchema = {
  type: 'object',
  required: ['aprovados','reprovados'],
  properties: {
    aprovados: { type: 'array', items: { type: 'string' } },
    reprovados: { type: 'array', items: { type: 'object', required: ['node_id','motivo'], properties: { node_id: { type: 'string' }, motivo: { type: 'string' } } } },
  },
}
const medidos = await parallel(selecionados.map((a) => () => agent(
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
const vereditos = await parallel(lotes.map((lote,ix) => () => agent(
`JUIZ FIXO do censo (mandato REFUTAR, default REPROVADO na dúvida; calibração 2026-08-29: FP 20%, subserviência 0/7). READ-ONLY no repo.
Audite os desfechos PREGUIÇOSOS (CONFIRMED e GATED-não-disparado): method foi EXECUTADO (re-rode o barato)? mediu no arquivo que o trace aponta? contagem de claims honesta contra o label? CONFIRMED procurou a morte? gatilho MEDIDO ou só declarado?
Devolva aprovados (node_ids) e reprovados (node_id+motivo específico).

LOTE ${ix+1}:
${JSON.stringify(lote.map(r=>({node_id:r.node_id,kg_file:r.kg_file,method:r.method.slice(0,300),observed:r.observed.slice(0,300),verdict:r.verdict,claims:r.claims_measured+'/'+r.claims_total,realidade:r.realidade,gatilho:r.gatilho,gatilho_disparou:r.gatilho_disparou})))}`,
  { label: `juiz:lote${ix+1}`, phase: 'Juizo', model: 'opus', effort: 'high', budget: 70000, schema: JSchema }
)))
return {
  selecionados: selecionados.length,
  nao_medidos_por_teto,
  descartados_medicao: descartados,
  medidos: vivos,
  juizo: vereditos.filter(Boolean),
  parametros: { teto, price_per_node: price, max_nos: maxNodes },
}
