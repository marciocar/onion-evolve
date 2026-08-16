---
branch: docs/close-g3-gate
pr: 615
date: 2026-08-16
reviewed_diff_sha256: c1fcd15747a894d7965d71fb22e3bbe13723366ad266a8879819c71f4cb1fde5
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 6
verdict: CONFORME
reviewer: passada sobre o próprio ato de fechar um gate — a pergunta revisada não é "o G3 pode fechar?" mas "o que este fechamento apagaria do radar sem ninguém decidir?"
REVISOU: true
---

# Resíduo — `docs/close-g3-gate`

Fechar gate é ato de baixa reversibilidade no grafo: um `done` sai do ESTADO do radar
e deixa de ser visto. Por isso a revisão foi sobre o fechamento, não sobre o roteiro.

**Achado 1 — o gate carregava decisões vivas.** O `Q_G3` misturava *prova humana*
(roteiro) com *três decisões abertas* (multi-device last-write-wins com cura 409
desenhada; bordas dark; splash). Fechar como estava apagaria as três do radar **sem
ninguém decidir nada** — e a de multi-device tem modo de falha silencioso (dois
aparelhos na mesma conversa, o último salva e o outro perde sem aviso). Extraídas
para `Q_F3_DECISOES_DE_ACABAMENTO`, com a aresta `CONSTRAINS` migrando junto; o G3
fechado passa a `SUPPORTS`.

**Achado 2 — dois itens do roteiro sem rastro, e um deles quase virou falso positivo.**
A primeira varredura de anexos casou 5 arquivos usando um padrão frouxo (`.md`), que
pega prosa. Refeita com o marcador exato que o servidor injeta — e **validado que esse
marcador existe no `chat.ts`** antes de afirmar ausência (vazio ≠ ausência; sem esse
controle eu teria "provado" ausência procurando fantasma). Resultado honesto: anexo de
ARQUIVO nunca foi exercido em produção; anexo de IMAGEM foi (o bug do prompt
obrigatório nasceu dali). Busca idem: rota existe, uso não registra.

Os 6 itens restantes têm evidência real — três medidos agora (thread-store com 11
conversas, deep-link 200, PWA servida) e três por rastro de campo com correção
associada (mobile, dark, comandos).
