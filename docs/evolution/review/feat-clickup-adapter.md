---
branch: feat/clickup-adapter
pr: pendente
date: 2026-11-06
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_blocking: 0
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
reviewer: passada da sessão da forja (forge-clickup-adapter) sobre o próprio diff + leitura do diferencial 08bb290a1 pelo team-lead — as duas NÃO são independentes
nota: >
  Duas leituras, nenhuma independente: a da própria sessão que escreveu o código (motivo de cada mutante lido
  um a um) e a do team-lead sobre o diferencial 08bb290a1, que aprovou sem achado. Os 3 achados reais são
  da 1ª: três mutantes mordiam pelo motivo errado; os casos foram reforçados e os três passaram a morder
  pelo defeito real (rc 0 sob o mutante). Nenhum bloqueava: a cura de produção estava certa, a bancada é que
  provava menos do que dizia. O ao vivo NÃO foi medido (LIMITE declarado). tokens e duration_min não medidos (0).
---

# Passada adversarial: `feat/clickup-adapter`

## As duas leituras, declaradas não independentes

1. **A da sessão da forja**, sobre o próprio diff. Depois da 1ª corrida verde da bancada (27 casos e 22
   mutantes), li POR QUE cada mutante reprovava, e não só se reprovava. Uma âncora de mutante que reprova pelo
   motivo errado é candidata a defeito da bancada.
2. **A do team-lead**, sobre o diferencial 08bb290a1. Aprovou, sem achado: a divisão
   implemented/unverified/not_implemented está honesta, o token chega igual ao linear.py, a bancada é
   offline, e a troca no CLAUDE.md cabe na catraca da REGRA 109 (Catraca de tamanho do CLAUDE.md).

Nenhuma das duas é independente: a 1ª é do autor, e a 2ª é de quem encomendou e leu o relato do autor. Nenhum
refutador separado rodou.

## Achados (3 reais, 0 bloqueantes, 3 curados)

| # | mutante | mordia por | cura do caso | agora morde por |
|---|---|---|---|---|
| 1 | `update_tags`: tira a recusa de `item.update --tags` | `item.update sem campo` (rc 2 por outro motivo; a mensagem não citava o label.set) | o caso passa `--title` junto com `--tags` | rc 0 com 2 requisições: o título é gravado e a tag é descartada em silêncio, que é o defeito real |
| 2 | `comment_flags`: aceita qualquer `--flag` | rc 2 de "texto com espaços vai entre aspas" (a flag engolia o único posicional) | o caso passa `--corpo x "texto real"` | rc 0 com o comentário publicado: a flag desconhecida passa calada |
| 3 | `err_in_200`: não lê o `err` do corpo | "task não encontrada" (o corpo forçado não tinha `id`) | o corpo forçado tem cara de task válida (`id`, `name`) junto do `err` | rc 0: o erro sai como sucesso |

Os três foram achados porque a sessão leu o motivo impresso de cada mutante; a contagem "22/22 mordem", que já
estava verde, não os mostrava. Nenhum bloqueava: o código de produção curava os três casos, e o defeito era a
bancada provar menos do que o rótulo dizia.

## Limite declarado (não é achado)

- **Ao vivo NÃO medido.** Nenhuma chamada foi feita ao ClickUp real: a conta e o token são do projeto que usa.
  O falso em loopback é a medição de 2026-10-02 posta em código, e não prova que o ClickUp real se comporta
  igual. Por isso todo verbo novo está `unverified` no tsv. O roteiro de 5 passos fica em
  `.claude/utils/task-manager/adapters/clickup-executavel.md`, para a sessão do projeto que usa ClickUp ou para
  o maestro.
- A busca é local, sobre `GET /team/{id}/task`, com teto de 20 páginas declarado em `truncated`.
- `attachment.read`, `attachment.add`, `inline.refs` e `activity.list` ficam `not_implemented`.

## Gate, para registro

- Bancada: 27/27 casos, cópia limpa verde nos 16 casos-alvo e 22/22 mutantes, cada um pelo motivo da sua cura.
- Famílias tocadas (8): 143 passaram, 0 falharam.
- `lint-artifacts.sh`: 0 HARD. A 1ª corrida acusou a REGRA 80 (Números do harness saem de SSOT gerada, nunca
  de comentário) porque a família nova mudou a contagem; regenerei `testing-inventory.md`.
