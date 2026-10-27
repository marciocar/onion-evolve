---
branch: docs/design-fourth-dimension-direction
pr: 1403
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 9
tokens: 51796
duration_min: 2
findings_fixed: 9
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: code-reviewer (agente novo com brief, sem a conclusão do autor)
nota: "Um refutador leu o 1º commit (3 nós e 4 arestas no grafo de sinais de campo) contra o filesystem, o members.yaml e o nó C_OPCAO_D_QUARTA_DIMENSAO do estudo de infra, e rodou os comandos dos critérios. Achou 9 defeitos (nenhum bloqueante, 4 importantes). Os 9 foram curados no 2º commit. Os tokens e a duração são do refutador."
---

# Passada adversarial: `docs/design-fourth-dimension-direction`

## O que muda

- A decisão do maestro de 2026-10-27 (o design SERÁ a 4ª dimensão, e a doutrina espera o gatilho) vira o nó `D_DESIGN_QUARTA_DIMENSAO_DIRECAO_1027`, criado pelo selador.
- Duas perguntas abertas: o gatilho da doutrina, com seis critérios e um comando para cada, e a construção do design-context de primeira classe.
- Uma aresta CONSTRAINS em `external_edges` para a opção D do estudo de infra da VPS.
- O CLAUDE.md e os docs das três dimensões não mudam.

## Achados

| # | Achado | Sev. | Destino |
|---|---|---|---|
| 1 | O critério 6 dava a entender que só o portal-gamificacao está no members.yaml, mas o jogo-da-vida também está (l.695) | importante | curado: "ambos registrados no members.yaml" |
| 2 | O `lint-design-tokens.sh` sai 0 quando o design-context não existe, e o critério 5 passava sem nada gerado | importante | curado: `test -d <projeto>/docs/design-context/foundations` antes do lint |
| 3 | A narrativa prometia um comando em rc 0 para cada critério, mas o 3 (métrica), o 4, o 5 e o 6 eram só prosa | importante | curado: cada critério ganhou comando; o nome da guarda do 4 entra quando ela nascer no /meta:forge-guard |
| 4 | "deck ou componentes" é mais fraco que a decisão, que diz "identidade, deck e componentes" | importante | curado: o critério 5 pede os três, e o 6 reusa o 5 |
| 5 | O lint já sai 0 nos dois projetos de gamificação, então ele não separa nada no critério 6 | menor | curado: a medida entrou no nó, e o que separa é a saída do ciclo |
| 6 | O nó D descrevia o C_OPCAO_D só pela falta de evidência e omitia o primeiro motivo dele, a doutrina selada com "nem design/ foi promovida" | menor | curado: os dois motivos foram citados, e o que se restringe é aquela premissa |
| 7 | A aresta pergunta→pergunta com SUPPORTS era frouxa: a relação é de dependência | menor | curado: `Q_DESIGN_QUARTA_DIMENSAO_GATILHO_1027 DEPENDS_ON Q_DESIGN_CONTEXT_PRIMEIRA_CLASSE_1027` |
| 8 | A entrada era medida só pela existência do `setup.md`, sem o brief | menor | curado: o critério 1 exige que o setup leia o `brief.md` |
| 9 | DTCG aparecia sem glosa | menor | curado: "o formato de design tokens do W3C" |

## Mutantes

Não se aplica: o PR não tem código executável. O que serve de prova está noutros instrumentos:

- o radar `--integrity --schema` sai com exit 0 no grafo de sinais de campo (76 nós, 77 arestas);
- o `kg-contract-check.sh` sai conforme;
- o lint de nomes (`kg_vocab.py lint`) não tem achado nos nós novos;
- os comandos de critério marcados "hoje rc 1" foram rodados pelo refutador e conferem.

## Limites declarados

- O estudo de setup de design da curadoria não está na origin/main dela (o `peer-ref-check.sh` saiu 1 @ 8d64aef). A ligação é por texto, e quem constrói confere de novo antes de citar.
- A medida dos dois projetos de gamificação foi no disco, não na origin/main deles.
- O 2º commit, com as curas, não voltou ao refutador.
