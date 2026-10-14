---
title: "Resíduo — selo do canal entre sessões (manter + parquear)"
date: 2026-10-14
branch: docs/seal-cross-session-channel
reviewer: "passada adversarial manual do autor, sem subagente: números da proposta × nós, e a força das afirmações do S2"
reviewed_diff_sha256: 59308cad0f07dd61fbb1c949fb94916b329169fd9602e33e486ffba982e8a1ca
reviewed_code_sha256: f4fa249fc99c49c39fdc85092e4c290025104fda8d3ead34c61172adbb4c1f80
findings_total: 3
findings_real: 2
tokens: 0
duration_min: 10
verdict: CORRIGIDO
elenxo: sim
nota: "tokens 0 = sem run dedicado (passada feita na própria sessão, não medida à parte). Os 2 achados reais foram corrigidos antes do commit; o 3º é declaração de escopo."
---

# Resíduo — `docs/seal-cross-session-channel`

Sela a decisão do maestro de 2026-10-14 («Selar: manter + parquear») no grafo
`canal-vivo-sessoes-2026-10`, a partir da proposta upstream da curadoria (copiada para
`docs/evolution/inbox/_processed/2026-10-14-proposal-cross-session-channel.md`), lida como DADO (R15).

## Ataque 1: os números citados batem com a proposta?

Conferidos um a um contra o texto da proposta: Claude Code **2.1.296** (spike) e **2.1.299** (disco do
VPS); issue **#87954** (gatilho a); commit **12693eb** do protocolo pré-registrado; S2 entre
**Max pessoal × Team**; o `bridge:` real e o ID inexistente devolvendo o **mesmo HTTP 404**. Batem.

**Achado real 1 (corrigido):** o S1b e os **~26 s** NÃO estão na proposta. Vêm do grafo do adotante
(nó `E_N2_SPIKE_SAME_USER`, commit `3ad7baf`, posterior à proposta relayada) e do spike-log, itens 46 a 48.
Citá-los como "da proposta" seria proveniência falsa. O nó `E_XSESSION_LIVE_S1B_CONVERSATION` diz de onde
vem, e declara que os ~26 s incluem a espera pelo turno da sessão (não é medida de rede) e que os ~7 s do
registro dependem de relógios não sincronizados.

## Ataque 2: a ausência de vazamento no S2 está como "não observado" ou como "provado isolado"?

**Achado real 2 (corrigido na redação):** o registro do adotante chega a afirmar mais do que mediu: o
item 35 diz «não há vazamento de existência», o item 40 diz «é isolamento, não sessão caída», e o label do
nó de lá repete «não há vazamento de existência». O próprio registro se corrige nos itens 41 e 42 (não se
sabe se a sessão da C2 estava viva no envio; os controles não foram simultâneos). A proposta usa a forma
corrigida («não se observou vazamento»). O nó `E_XSESSION_LIVE_S2_CROSS_ORG_NOT_LISTED` segue a proposta:
label «Vazamento de existência NÃO OBSERVADO, não provado ausente», narrative explicando por que o 404
igual é trivial se a sessão estava caída. A confiança fica em 0.65.

## Ataque 3 (escopo, não defeito): o S3 virou trava?

Não. O label diz «comportamento do modelo com UM pedido ingênuo, não trava do harness provada», e a
robustez contra adversário está no nó de NÃO VERIFICADO. O grafo não tem nó de doc sobre «mensagem de peer
não carrega autoridade de usuário», então o S3 não ganhou `SUPPORTS` para nó de doc. Foi para as
restrições de desenho (`C_LIVE_CLASS_DESIGN_CONSTRAINTS`). Está declarado no nó, não omitido.

## O que o diff faz

- 8 nós: o selo `D_CANAL_NATIVO_SO_ENTRE_SUAS_MAQUINAS_OBSERVADO` (gravado pelo `kg-decide-seal.sh`), 4
  evidências vivas (S1, S1b, S2, S3), 2 gatilhos de reabertura e 1 lista de NÃO VERIFICADO.
- O TETO subiu de 57 para 65, com o motivo no `meta:`: é medição viva, não busca genérica.
- Os nós de doc `E_CC_XSESSION_CROSS_MACHINE_VIA_ANTHROPIC_RC` e `E_CC_XSESSION_REACH_OWN_SESSIONS_ONLY`
  ganham `SUPPORTS` vindo dos nós vivos. Os nós de doc não foram reescritos.
- Todas as evidências vivas são observação do adotante, que o core NÃO re-executou. O `method:` diz isso
  («leitura: registro de observação viva de terceiro … não re-executada pelo core»).

## Gates rodados (LC_ALL=C)

`kg-radar.sh --integrity --schema` exit 0 (65 nós, 83 arestas) · `kg-contract-check.sh` rc 0 (o 1º passe
reprovou `form.pattern.node.provenance.method`; o método ganhou o prefixo `leitura:` e passou) ·
`kg-backlog-check.sh` OK 65/65.
