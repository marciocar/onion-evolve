---
title: 'Resíduo — doutrina do estado da peça e a coluna de peças do mapa de interconexão'
branch: feat/adopt-or-vendorize-census
pr: 1578
date: 2026-11-10
reviewed_diff_sha256: pendente
findings_total: 11
findings_real: 11
findings_blocking: 8
tokens: 60000
duration_min: 35
verdict: FIXED
elenxo: false
nota: >-
  Passada adversarial feita pela própria sessão sobre o diff, sem refutador separado: o brief proíbe
  criar agentes, logo elenxo: false. Dois achados que mudariam o que o maestro lê foram curados; três
  são LIMITE declarado. O escopo foi reduzido pelo maestro no meio do trabalho: o medidor, a bancada e o
  grafo próprios da 1ª versão saíram da branch (guardados fora do repo como patch), e ficaram a
  doutrina, a coluna e o selo.
---

# Resíduo — REGRA 56 (Resíduo de revisão por branch)

## Achados que bloqueavam (curados)

1. **`kind: method` não é projeção.** Na 1ª versão (o medidor, hoje fora da branch), quem adota só o
   método aparecia como «escrito pelo core por desenho». A doutrina nova não repete o erro: os estados
   são de peça, não de natureza de membro, e a porta é o único estado que o core escreve por desenho.
2. **O `/meta:adopt` passava de 800 linhas** com a linha que citava a doutrina (REGRA 5 (Limites de
   linhas)). A linha saiu; a doutrina é citada pela `PIECES.md` e pelo nó
   `E_INTERCONNECT_PIECES_COLUMN_1110`.

## Revisão do PR #1578 (revisor separado): quatro curas antes do merge, todas feitas

6. **Postura de segurança no público.** A `PIECES.md` levava o detalhe do modo hub da persona com
   arquivo e linha de um repo privado, o `proto: 1` não conferido com linhas, e a contagem de unidades
   da fila por usuário com o nome antigo. Trocados por «risco nomeado no mapa local», sem arquivo:linha.
7. **Número do custo do kg-ssot.** O «63» saiu de `git log --since=2026-10-10`, que sem hora corta na
   hora atual do dia e por isso muda ao longo do dia (61 às 15:20 UTC). Com a meia-noite explícita
   (`--since='2026-10-10 00:00:00 +0000'`, `origin/main`) são **64**; a doutrina e a `PIECES.md` levam o
   64 com o comando ao lado.
8. **Lacuna da doutrina.** O «se mostrar diferente» do maestro não tinha gatilho próprio: entrou a
   **reclassificação** (evidência medida de que a peça é outra coisa do que se pensava), distinta de
   função nova.
9. **Locator do selo.** O locator de `D_PIECE_STATE_DOCTRINE_1110` passou a ser a pergunta literal feita
   ao maestro: «Sigo com doutrina mais coluna no mapa, nessa forma enxuta, ou você quer outra forma?». A
   resposta verbatim ficou como estava.

## CI do PR #1578: fail-open latente no `vendor-manifest.sh` (curado)

10. **Peça órfã desligava o corte de companheiros.** O merge foi recusado: o caso (r14) da `publish_release`
    viu a `publish-lens` e a `publish-doctrine` viajarem para o standalone. A causa não era citação core-only
    da doutrina nova: **qualquer** `*-doctrine.md` sem citador fazia o mesmo (testado com arquivo vazio e
    três nomes). Em `_emit_companion_excludes`, uma peça órfã não tem entrada em `_refs`, a leitura
    `${_refs[${_z}]}` sem `:-` estourava `set -u` dentro do process substitution, a função morria calada e
    nenhum companheiro de comando cortado saía. Cura: `:-` nas três leituras. Caso novo (m-órfã) na família
    `role_cut`, que reprova contra o manifesto antigo (mutante morto: só ele cai) e passa curado; `role_cut`
    e `publish_release` 77 de 77.

11. **A classe seguia aberta no chamador** (revisão do PR #1578). O manifesto lia os companheiros por
    `< <( … | _emit_companion_excludes)`, que engole o rc: qualquer outro estouro da função voltaria a soltar
    todos os companheiros sem aviso. Cura: o rc é lido como o do corte de comandos (`_comp_out="$(…)" ||
    exit 3`, com mensagem que nomeia a função). Caso (m-rc) na `role_cut`: falha injetada na função ⇒
    manifesto rc 3 e sem pacote; mutante com o rc engolido morto (só ele cai). `role_cut` e
    `publish_release` 78 de 78; o manifesto real do standalone segue sem as duas peças de publicação, e o
    da source com elas.

**Dano em produção, medido pelo revisor:** nenhum pacote publicado desde 2026-11-05 saiu com companheiro
indevido: o standalone e o onion-core deram diff de 0 linhas contra o manifesto curado. O fail-open era
latente: só acendia com uma peça órfã na zona, e a 1ª foi a doutrina deste PR, barrada no CI antes do
merge.

## LIMITE declarado (não bloqueia)

3. Os números da coluna são de uma janela de 30 dias, lidos por git sem fetch: o clone do bridge estava
   em `92079ae` (2026-11-07), anterior ao HEAD remoto que o mapa local cita.
4. A coluna não mede valor estratégico; diz o estado e qual gatilho acendeu.
5. A doutrina não cria guarda. Ninguém reprova uma peça por estado; quem aplica é a decisão do maestro.

## Medido

- Grafo do perfil: `E_INTERCONNECT_PIECES_COLUMN_1110` (trace `PIECES.md`) e
  `D_PIECE_STATE_DOCTRINE_1110` selado pelo `kg-decide-seal.sh` com `--other`; radar exit 0, contrato
  conforme; TETO 12 → 14 com justificativa.
- Gate A2A: blob git idêntico no core e na mensageria (`c4f1e34d…`). Três unidades da fila ativas.
  Bridge: 15 arquivos de operação, 34 de 34; mensageria: 25 de 25.

## Não mudou

- Nenhuma adoção, nenhum vendor e nenhum repo de peça escrito.
