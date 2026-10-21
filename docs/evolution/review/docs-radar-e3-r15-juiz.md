---
branch: docs/radar-e3-r15-juiz
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
tokens: 201105
duration_min: 20
findings_fixed: 2
verdict: CORRIGIDO
elenxo: sim
reviewer: 2º juiz da r15 (subagente opus/high da sessão interativa; modelo declarado)
nota: "a r15 foi feita em paralelo por duas cópias da mesma conversa; esta é a correção do 2º juiz sobre o grafo já mergeado no #1276"
---

# Passada adversarial: `docs/radar-e3-r15-juiz`

## O que muda

- O rótulo do nó do teto do WebSearch passa de "espírito" para "letra".
- Entra um nó novo, sobre a sonda de tarefas de fundo, e o veredito do 2º juiz vai para `data/`.
- A pergunta da memória (SAC-185) fica selada como "Reescrever".

## Achados

1. **O nó do teto REPROVA.** Desde a 2.1.304 o aviso tem a cláusula "Continue with the information already
   gathered instead of searching again". Curado: o rótulo agora diz letra.
2. **Omissão de impacto 2, a sonda de fundo.** Curada com o nó `E_SONDA_DE_FUNDO_NAO_FECHAVA_TAREFA_PARADA_ATE_2_1_306`.

## Mutantes

Não se aplica.

## Limites declarados

- O caso de bancada da sonda, nas duas formas da notificação, fica como proposta: não foi criado aqui.
- Os 3 EXAGERA restantes do 2º juiz (o recorte do alcance do SDK do bridge, a pergunta e a superação já
  respondidas pela letra) estão no `data/` e ficam para a próxima revisita.
