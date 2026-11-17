---
branch: docs/seal-classification-design-1117
pr: pendente
date: 2026-11-17
reviewed_diff_sha256: 56e298a5844bae7a5ce179e6a515df3c80985bae639f4388829ddd4c42ffbf53
reviewed_code_sha256: 1c8d48b17fbf6832a925d2d8a792f9806703d29155f81d4a65015a90afb7ebdb
findings_total: 2
findings_real: 0
findings_blocking: 0
tokens: 0
duration_min: 6
findings_fixed: 0
verdict: NO_FINDINGS
elenxo: false
reviewer: "sessão do core, releitura do diff contra as respostas literais do maestro e contra o estado do Delphi"
nota: "tokens 0 = não medido: a passada foi a releitura do diff pela própria sessão que selou, sem agente separado. PR só de grafo (três arquivos .kg.yaml), sem código nem guarda."
---

# Passada adversarial: `docs/seal-classification-design-1117`

## O que muda

Sela no grafo as decisões do maestro de 2026-11-17: o fecho do desenho da classificação de sensibilidade
(`Q_MA_CLASSIFICATION` vai a `done`), três decisões novas no arquivo de selos (contrato do kg-ssot com a trilha de
rebaixamento e o corte da release; spike do rótulo por nó refeito medindo nível; plano de abertura a quem não é dev
primeiro em documento) e uma pergunta nova, a da finalidade do tratamento no contrato do grafo, com a curadoria como
dona da instrução.

## Achados

Dois pontos examinados, nenhum real:

1. **O texto do selo afirma mais do que o maestro respondeu?** Conferido contra as respostas literais: «Selo o fecho do
   desenho», «Plano em documento primeiro», «Selo e corta a release» e «Refazer o spike medindo nível». O campo
   `chosen` de cada selo traz a opção escolhida; no selo da classificação ele traz também o conteúdo do fecho, que é o
   que a pergunta descrevia. As rejeitadas são as outras opções oferecidas. Não é achado.
2. **O grafo público expõe postura de segurança da produção?** O selo do plano de abertura diz que o servidor de
   produção não lê nível nem teto. O servidor é `ops/mcp-onion-kg/server.py`, que está neste mesmo repo público: a
   afirmação se deriva do código publicado e não nomeia host, cliente nem pessoa. Não é achado.

## Mutantes

Não se aplica: o PR não tem código. O gate de cada selo foi o do selador (radar de integridade e esquema com saída 0,
contrato com saída 0, lint de nomes sem achado novo), e o nó escrito à mão passou no radar com saída 0.

## Limites declarados

- A passada é da própria sessão que selou; não houve refutador separado.
- A afirmação de que a retenção já está no contrato do grafo é relato do kg-ssot, registrada como relato no nó novo.
- O estado do Delphi (as três rodadas) vive fora do git, no estado local da sessão; o grafo guarda a decisão, não as
  posições.
