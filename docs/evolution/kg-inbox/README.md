# kg-inbox — fila de propostas de escrita no grafo (write-leg da F4b)

**O que é.** Staging onde agentes EXTERNOS (LibreChat via Bridge-MCP `propose_kg_write`)
depositam propostas de nó/aresta como `.kg.yaml` de proposta — **nunca** no grafo vivo.

**Por que existe (I3 — um escritor por repo).** Um agente de chat não escreve o grafo direto: ele
PROPÕE, e a sessão **do dono deste repo** revisa e sela com o radar. Rima com a federação (quem não é
dono sinaliza, o dono sela) — só muda o transporte. Spec: pesquisa F4b
(`docs/evolution/research/librechat-kg-runtime-2026-08/`).

**Este README é local a este repo, e é o do CORE.** Desde 2026-09-05 o `/meta:kg-inbox` roteia por
papel: num repo adotado ele sela a fila DAQUELE repo, cujo README o starter do `/meta:adopt` escreve
(`docs/evolution/` não viaja na adoção). A fronteira que a I3 impõe é de **repo**, não de **papel** —
o que nenhuma sessão faz é selar proposta cujo alvo vive noutro repo.

**Fluxo.**
1. `propose_kg_write` grava `<slug>-<ts>.proposal.kg.yaml` aqui (+ metadados: quem, quando, de onde).
2. Uma sessão do core roda `kg-radar.sh` na proposta, decide, e — se selar — INTEGRA no grafo
   vivo destino (merge manual auditável), depois `git mv` da proposta para `_sealed/`.
3. Proposta recusada → `git mv` para `_rejected/` com o motivo. Nada se apaga (Aufhebung).

**Invariante.** O radar de uma proposta é ADVISORY aqui (ela ainda não é fonte); o gate real é
a selagem pelo dono. Uma proposta nunca é lida como estado por warm-up/catch-up.

## O MODO PROPOSTA, e por que ele precisou existir

Até 2026-09-11 este README e a INTEGRIDADE do radar se contradiziam, e quem pagava era o primeiro
a usar a fila. O fluxo acima manda propor **um nó**; a INTEGRIDADE exige **grau ≥ 1 com a aresta no
mesmo arquivo**. A proposta documentada, portanto, **nunca passava** — `rc=1`, `nó órfão (grau 0)`.
Não era bug de nenhum dos dois lados: é uma regra de **grafo fechado** cobrada de um **fragmento**,
que por definição só fecha quando aterrissa no destino.

O radar agora reconhece a proposta por **qualquer um** de dois gatilhos e afrouxa **exatamente duas**
cobranças:

| gatilho | `meta.target:` presente · ou o nome termina em `.proposal.kg.yaml` |
|---|---|
| **relaxado** | grau 0 · referência para fora do arquivo — e as duas saem **CONTADAS** na saída |
| **inalterado** | id duplicado · chave repetida · `node_type` · `plane` · `layer` · `status` · `impact` · `confidence` · `edge_type` |

O modo **nunca é silencioso**: ele imprime `◆ MODO PROPOSTA` e diz por qual gatilho entrou, porque
quem lê um `✅` precisa saber que leu o ✅ de um fragmento e não o de um grafo.

### Exemplo que PASSA (copie este)

```yaml
meta:
  id: proposta-exemplo
  schema_version: "1"
  target: docs/onion/graph/fios-abertos.kg.yaml   # ← o gatilho, e o destino da selagem
nodes:
  - id: P_O_QUE_EU_PROPONHO
    node_type: claim
    plane: DEV
    status: open
    impact: 3
    confidence: 0.8
    label: "A afirmação proposta, em uma frase que se possa refutar."
edges: []                                         # vazio é legítimo aqui
```

```
$ bash .claude/validation/kg-radar.sh <proposta> --integrity --schema
  ◆ MODO PROPOSTA (meta.target: docs/onion/graph/fios-abertos.kg.yaml) — este arquivo é FRAGMENTO…
  ℹ relaxado pelo MODO PROPOSTA: 1 nó(s) de grau 0 · 0 referência(s) para fora do arquivo
  ✅ fragmento bem formado (1 nós, 0 arestas) — o gate do grafo fechado é a SELAGEM
```

Ligar o nó novo a um que **já vive no destino** também é legítimo — a referência sai contada como
relaxada, não reprovada:

```yaml
edges:
  - from: P_O_QUE_EU_PROPONHO
    to: C_UM_NO_QUE_JA_EXISTE_NO_TARGET
    edge_type: SUPPORTS
```

**O relaxamento acaba na selagem.** Integrado ao grafo vivo, o fragmento volta a ser cobrado como
grafo fechado: lá o grau 0 e a referência pendurada são erro de novo. Bancada: família
`kg_proposal_mode` (6 casos, com mutante que executa).
