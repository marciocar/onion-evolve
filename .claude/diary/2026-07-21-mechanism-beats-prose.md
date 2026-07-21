---
date: 2026-07-21
instance: onion-evolve
type: learning
classification: collective
tags: [knowledge-graph, backlog, decision-durability, identity, dogfood, provenance]
affects: [meta, product, engineering, compliance]
breadcrumb_for: []
share_with: []
next_recommended: "Ao FECHAR qualquer decisão que deva durar (identidade, fronteira, invariante), perguntar antes de encerrar: 'que mecanismo carrega isto?' — guarda de lint, campo de frontmatter, SSOT gerada, proibição normativa citável ou critério de auditoria. Decisão que só existe em documento datado tem meia-vida curta MESMO ESTANDO CERTA. E o inverso é o teste barato: para saber se uma decisão antiga ainda vale, não releia o documento — procure o mecanismo. Se não houver, ela já morreu e ninguém avisou."
review_after: 2026-10-19
conflict_class: static
significance: "Modelar 92 documentos de 14 meses no grafo revelou a lei que governa a durabilidade de decisões neste core — e ela não é sobre qualidade de argumento, é sobre onde a decisão foi parar."
---

## Signal
**Decisão que virou mecanismo derrota decisão que virou prosa — mesmo quando a prosa é mais recente e mais
bem argumentada.** A durabilidade de uma decisão neste core não é função da sua qualidade, e sim de ter ou
não encarnado em guarda de lint, SSOT gerada, campo de frontmatter, helper de shell ou proibição normativa
citável. O resto tem meia-vida de semanas.

## Evidence
- **O contra-exemplo que fecha a lei:** a identidade canônica de 2026-05-18 (framework template em
  `.claude/`, tri-dimensional peer, abandono de `.onion/` + CLI standalone + multi-IDE) **resistiu a uma
  tentativa formal e bem-argumentada de reversão**. Junho decidiu, num documento inteiro de estratégia,
  "Onion é produto, migra para BSL, ICP orgs reguladas". **Nada disso foi executado.** A licença segue MIT
  treze meses após a decisão de migrar. O ADR de reposicionamento nunca foi escrito — entre 39 ADRs.
- **O motivo é estrutural, não conservadorismo:** a identidade de maio tinha virado **proibição normativa**
  (`architecture.md` §7) e **critério de auditoria** (`kb-freshness` critério #3, `evolve` D6). O
  reposicionamento de junho tinha **só um documento**.
- **Nada abandonado ressuscitou** — o A2A voltou como transporte *gated* com aceitação humana, não como a
  autonomia contínua que fora descartada. A assimetria operou exatamente como projetada.
- **~2/3 do passivo de 92 documentos já tinha morrido em código sem ninguém marcar:** vazamento MCP-first
  fechado na fonte, drift de contagem virado SSOT gerada com guardas de lint, herança de escopo entregue
  como `compose-settings.sh`/`resolve-scope-layers.sh`, cinco sementes de pesquisa já entregues. O core
  carregava dívida quitada nos livros.
- **Corolário achado ao modelar (não visível em leitura individual):** decisões de caso-específico não
  sobrevivem como decisões, sobrevivem como **generalizações**. As três perguntas de topologia do adotante
  morreram como perguntas e viveram como `resolve-integration-branch.sh`; o parecer de um caso de cliente
  morreu como caso e viveu como princípio de fronteira do template.
- **Três pesquisas de método**, partindo de literaturas totalmente distintas, desembocaram no **mesmo
  artefato**: um campo de frontmatter mais uma guarda.
- **A pergunta comercial não foi respondida nem abandonada — foi re-formulada de plano para topologia de
  repositórios** (porta pública ≠ core privado, `onion-mini` como entrada). Este core não decide por
  licença; decide por estrutura de arquivos.

## Next crumb
Ver `next_recommended`. O uso mais barato desta migalha é diagnóstico: diante de um documento de decisão
antigo, **procure o mecanismo antes de reabrir o mérito**. Se existe mecanismo, a decisão está viva e
discutir é caro; se não existe, ela já está morta e o documento é arqueologia — o que importa é decidir de
novo, agora com mecanismo. Ver também [[inverted-provenance-ratchet]] (o instrumento que tornou esta lei
visível) e a doutrina destilada na leva 2: *backlog em prosa datada renasce todo dia e só morre quando vira
guarda de lint ou SSOT gerada*.
