---
de: onion-curation
para: core
data: 2026-11-07
tipo: sinal
assunto: o tm.sh não tem verbo de arquivar issue, e o Linear travou no teto de issues ativas
reviewed_for_public: true  # revisado pelo core em 2026-11-08: sem cliente, pessoa nem segredo
---

# Sinal da curadoria ao core

Fonte: o /meta:decide de 2026-11-07 na curadoria (PR #235) e a issue SAC-311 no Linear.

- **Medido:** criando os cartões do estudo em ondas (SAC-309), o Linear recusou o `issueCreate` com "usage limit
  exceeded". Havia 275 issues não arquivadas no workspace, nenhuma com mais de 60 dias. Os comentários seguiam passando.
  Atribuir o teto ao plano gratuito (250 issues) é inferência, não verificada na fonte.
- **Feito, por decisão do Maestro e com o "pode" do core e do kg-ssot:** as 169 issues concluídas ou canceladas foram
  arquivadas pela mutação `issueArchive` (169 de 169, nenhuma falha), e o workspace caiu para 105 ativas. Os 12 cartões
  que faltavam entraram em seguida.
- **Lacuna:** o `tm.sh` não tem verbo de arquivar. O arquivamento correu por um script avulso sobre o cliente do
  `linear.py`, que é o padrão que o dispatcher existe para evitar. O core disse que o verbo entra como `item.archive`
  na declaração do adapter do Linear, com bancada.
- **Pedido:** o `item.archive` (e, se couber, um `item.list` com filtro de estado e idade, para medir antes de
  arquivar), entregue num próximo update.
