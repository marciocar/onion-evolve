---
branch: docs/breadcrumb-cron-net
pr: 626
date: 2026-08-17
reviewed_diff_sha256: 7d5ef778229f648af881ed1f223f43a772faf1decc55abc2d3e5f679b9efebab
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 8
verdict: CONFORME
reviewer: re-teste de migalha vencida com MEDIÇÃO dos três itens que ela apontava (não re-carimbo), + a rede do filtro de path registrada com veredito escrito para os dois desfechos
REVISOU: true
---

# Resíduo — `docs/breadcrumb-cron-net`

Duas migalhas: uma nova (a rede do filtro de path, por provar) e uma vencida, re-testada.

**Achado — o `next_recommended` de uma migalha vencida vira instrução obsoleta.** A migalha
de 2026-07-18 apontava três itens para a sessão seguinte; medidos hoje, **os três estão
feitos** (warn de Proveniência no radar, exercitado em campo nesta própria sessão;
`onion-orchestration` no `/meta:kg`; Trilha-no-KG em 2 grafos). Mas o `next_recommended` do
frontmatter ainda manda agir sobre eles — e quem lê o índice sem abrir o arquivo agiria sobre
trabalho pronto. Registrei a correção **no corpo**, não no frontmatter: reescrever o que ela
recomendou *na época* apagaria a vitrine, que é o mecanismo inteiro.

**Por que a vencida não foi fechada:** o corpo dela é o inventário da máquina epistêmica e a
lista de GATED, que segue gated. Fechar apagaria o mapa; re-carimbar sem medir seria a
desonestidade que o gatilho proíbe. Nova data: 2026-11-17. Fila de reflexão: 1 → 0.

**Nota de verificação:** este PR é docs-only e serve de medição — é o primeiro depois da
divisão do CI, então o tempo do gate aqui **prova ou refuta** os ~49s que eu só havia
projetado. Se a bancada rodar neste PR, meu filtro de path está errado.
