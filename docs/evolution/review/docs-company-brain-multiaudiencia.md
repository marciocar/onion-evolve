---
reviewed_diff_sha256: pendente
findings_total: 6
findings_real: 6
tokens: 79618
duration_min: 2
verdict: APROVADO
elenxo: nao
nota: >
  Passada adversarial curta por revisor novo, só leitura, sobre o diff antes do commit. Seis achados
  reais, todos curados aqui; o veredito APROVADO é o estado depois das curas. O maior: o sinal verbatim
  do hub carregava dado operacional sensível e ficou fora do repo público.
---

# Resíduo — `docs/company-brain-multiaudiencia`

O grafo de pendências do Company Brain multiaudiência, o anúncio ao hub na staging e a entrada do
CHANGELOG de co-evolução.

## O que o revisor achou e como ficou

1. **O sinal verbatim do hub em `_processed/` publicaria dado operacional** num repo público: nome
   comercial, provedor de nuvem, falta de proteção de branch, contagem de administradores, onde mora a
   chave de admin da wiki, setor regulado. **Curado**: o sinal verbatim não entra no core público; em
   `_processed/` fica só um stub com o pedido em termos genéricos e o slug do grafo. O original segue fora
   do repo até a decisão do maestro.
2. **Postura de segurança do hub no grafo** (colaboradores escrevendo em qualquer caminho, achados de
   pentest). **Curado**: abstraído para «a barreira do servidor não está disponível no plano atual» e
   «conteúdo sensível»; o código HTTP, o nome da wiki e os tamanhos do repo saíram também.
3. **Contradição «em paralelo»**: o texto dizia que o MCP de leitura andava em paralelo, mas o grafo o faz
   esperar a classificação. **Curado**: o texto diz que o MCP já está no ar e que abri-lo à audiência
   espera `Q_MA_CLASSIFICATION`.
4. **Testemunho escrito como medida** (o SendMessage entre contas). **Curado**: «fato por testemunho» no
   grafo, no CHANGELOG e no anúncio.
5. **`locality: repo` em nós de testemunho de sessão.** **Curado**: `pessoa` nos quatro.
6. **Detalhe operacional do host** (nome do servidor MCP, host interno, falta de TTY). **Curado**: cortado.

## Conferido sem achado

Nenhum nome comercial, pessoa, e-mail, IP ou porta nos arquivos que o core escreveu (o id de membro
`brain-granaai` é o registro aceito); zero caminho de máquina (REGRA 99 (Nó de .kg.yaml sem caminho de
máquina, julgado pela classe)); os três alvos de `external_edges` existem; números iguais nos três textos.
