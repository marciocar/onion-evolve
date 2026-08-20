# kg-inbox — fila de propostas de escrita no grafo (write-leg da F4b)

**O que é.** Staging onde agentes EXTERNOS (LibreChat via Bridge-MCP `propose_kg_write`)
depositam propostas de nó/aresta como `.kg.yaml` de proposta — **nunca** no grafo vivo.

**Por que existe (I3 — um escritor por repo).** Um agente de chat não escreve o grafo do core
direto: ele PROPÕE, e uma sessão do core (o dono) revisa e sela com o radar. Rima com a
federação (adotante sinaliza, core sela) — só muda o transporte. Spec: pesquisa F4b
(`docs/evolution/research/librechat-kg-runtime-2026-08/`).

**Fluxo.**
1. `propose_kg_write` grava `<slug>-<ts>.proposal.kg.yaml` aqui (+ metadados: quem, quando, de onde).
2. Uma sessão do core roda `kg-radar.sh` na proposta, decide, e — se selar — INTEGRA no grafo
   vivo destino (merge manual auditável), depois `git mv` da proposta para `_sealed/`.
3. Proposta recusada → `git mv` para `_rejected/` com o motivo. Nada se apaga (Aufhebung).

**Invariante.** O radar de uma proposta é ADVISORY aqui (ela ainda não é fonte); o gate real é
a selagem pelo dono. Uma proposta nunca é lida como estado por warm-up/catch-up.
