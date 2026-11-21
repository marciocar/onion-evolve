---
branch: docs/kg-ssot-queue-parked-1121
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 6
findings_blocking: 0
tokens: 101256
duration_min: 2
findings_fixed: 5
verdict: APPROVED
elenxo: true
reviewer: "agente revisor isolado (general-purpose), que não escreveu a mudança"
nota: "tokens e duração medidos pelo harness do agente revisor (101256 tokens, 92 s)"
---

# Passada adversarial: `docs/kg-ssot-queue-parked-1121`

## O que muda

Dois nós de pendência do kg-ssot (Q_COORD_KGSSOT_ARESTA_ENTRE_REPOS_URL_FIXADA e Q_MA_CROSS_REPO) passam a dizer
que estão parqueados com gatilho pela D_CROSS_REPO_CONTRACT_1104 do onion-kg-ssot (selada em 2026-11-05), com
verified_at e verified_against novos e x_review_after 2026-12-04. Seguem open: a gramática não tem status de parque.

## Achados

1. LIMITE, corrigido: o nó de coordenação perdeu o fato de que o gatilho da superfície de escrita disparou em
   2026-11-04, e a narrativa antiga ainda o dava como futuro. Agora diz «disparado em 2026-11-04».
2. LIMITE, corrigido: Q_MA_CROSS_REPO abria com «Só abre de fato se…» depois de a condição se cumprir. Agora está no passado.
3. Cosmético, corrigido: o comentário da external_edge de 2026-10-31 dizia que a aresta estava parada na superfície
   de escrita. Ganhou carimbo de 2026-11-21 com o parque atual.
4. Cosmético, corrigido: o label de Q_MA_CROSS_REPO seguia condicional. Agora reflete a superfície decidida.
5. Cosmético, corrigido: a data de reavaliação só aparecia na prosa. Os dois nós ganharam `x_review_after: "2026-12-04"`, como o grafo já usa.
6. Fonte contraditória no par, falso-positivo para este diff: no kg-ssot, o verified_against e o source do nó dizem
   «decisão do maestro», e a narrativa e o SYNTHESIS dizem «decidido pela sessão, sob a autonomia». O diff segue o
   SYNTHESIS. Fica como aviso ao kg-ssot.
7. Nomes e caminhos: nada encontrado. O onion-kg-ssot é público (public-repos.tsv), e a REGRA 121 (Grafo novo ou
   tocado não cita repositório não conferível por terceiro) não se aplica.

## Mutantes

Não se aplica: o PR é só grafo, e não há guarda nova. A verificação foi feita contra a fonte primária
(peer-ref-check rc 0 @ 80bc3956), o radar saiu 0 nos dois grafos e o contrato ficou conforme nos dois.

## Limites declarados

- O gatilho que o pedido original citava, «3 ou mais casos de perda de citação medidos e julgados por agente
  separado», é a régua que JÁ disparou (5 casos) e abriu a pesquisa. O gatilho que reabre o parque, pela fonte
  primária, é outro: uma objeção perdida confirmada (tipo 2) ou um adotante externo que precise validar a forma. Os
  nós citam os dois e dizem qual é qual.
