---
branch: docs/onion-kb-rag-proven
pr: 639
date: 2026-08-20
reviewed_diff_sha256: c42fec43f74ed6293d57eaeda999e71c7381d4e35bf7a4da7db270cba0f330d5
findings_total: 3
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: CONFORME-RAG-PROVADO-COM-DISCRIMINADOR-ANTI-TREINO
reviewer: passada adversarial manual (2 ataques, um deles contra a validade do próprio teste); sem subagentes
REVISOU: true
---

# Resíduo — `docs/onion-kb-rag-proven`

**Origem:** F6.2 entregue — o agente Onion-KB provou a via RAG que ontem ficou honesta como
não-exercitada.

## Achado 1 — sonnet-5 quebra thinking+tool-use no v0.8.7 (REAL, contornado e registrado)

O 1º teste de aceitação falhou com `messages.1.content.0.thinking: Field required` — o agente
CHAMOU o file_search (a via RAG funcionou) e a continuação quebrou na serialização do thinking
do claude-sonnet-5, que é modelo DESCONHECIDO no v0.8.7. Contorno: agente em claude-fable-5 (o
perfil que o 0.8.7 conhece). Registro nos nós; o v0.8.8 traz os perfis da família completa.

## Os 2 ataques (o 2º contra a validade do PRÓPRIO teste)

- **(a) os 793 embeddings são deste agente?** 4 coleções no pgvector ≈ os 4 bundles; contagem
  distinta de arquivos consistente.
- **(b) a resposta veio do RAG ou do TREINO do modelo?** O discriminador que decide: a resposta
  incluiu a MEDIÇÃO da etapa 5 ("2026-08-02, de 6 corridas, 2 com grafo vazio") — fato interno
  desta casa, nascido em 08/2026, impossível de vir de treino; e citou onion-kb-conceitos-1.md,
  nome que só existe no bundle gerado ontem. Teste válido, não teatro.

## O fecho do círculo (registro, não achado)

O sinal que abriu a sequência #630 era "o adotante não sabia o que é o Elenxo — a definição era
inalcançável". O teste que fecha a semana é o agente respondendo AS 5 ETAPAS com citação, para
qualquer pessoa da casa, por chat. A mesma doutrina, três alcances: vendorizada (adotantes),
plugin (doors), e agora consultável (LibreChat/RAG).
