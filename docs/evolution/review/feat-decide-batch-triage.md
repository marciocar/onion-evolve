---
branch: feat/decide-batch-triage
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: 892a1579f5e6c63e5d356906b7cd4196d9b6d57d1235fca1118f789b604ed618
reviewed_code_sha256: fc15524beca23fa22e71346bdb73012784828576960ec4cd2b72006380270150
findings_total: 12
findings_real: 12
findings_fixed: 7
findings_blocking: 3
findings_blocking_fixed: 3
tokens: 0
duration_min: 0
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: refutador independente (agente separado do construtor), duas passadas — 1ª REPROVADO com 3 bloqueios, 2ª APROVADO COM LIMITES
nota: "tokens e duration_min 0 = não medidos. Os 12 achados são os do refutador independente: 3 bloqueantes e 4 limites curados; 5 limites declarados"
---

# Passada adversarial: `feat/decide-batch-triage`

## O que muda

Forja do **modo triagem em lote** do `/meta:decide` (`D_FORGE_DECIDE_BATCH_TRIAGE_MODE_1111`, maestro,
2026-11-11), peças 2, 3, 4 e 7, mais o destino (peça 5) estendido:

- **Doutrina (peça 2):** cláusula 10 da `decide-doctrine`: quem entra, os quatro destinos, quem fecha e o
  que a triagem não promete.
- **Medidor (peça 3):** `.claude/validation/decide-triage.sh` (também por `decide-census.sh --triage`),
  com teto `--max-age-days` (padrão 30), reserva viva do `maestro-ask.sh`, pedido em curso, idade por
  `verified_at` ou pelo último commit do bloco, colunas de superação, `owner`, medível e a dica.
- **Peça 4:** `.claude/workflows/decide-triage.js`, no molde do `meta-evolve-fanout.js`: um worker por
  lote de nós (só leitura), um refutador nas propostas de (b) e (c), e a síntese do rascunho do lote
  feita pelo script. O gatilho que o `decide.md` nomeava para a peça 4 disparou. O forge-census foi de
  6/7 para **7/7** no `decide`.
- **Destino (peça 5):** `kg-decide-seal.sh --batch <lote> --preview | --approve <sha256>`: aprovação pelo
  sha256 do lote, recusa de (a) e (d), o mesmo gate do selo único por grafo, e o desfazer do lote inteiro.
- **Superfície:** seção "Modo triagem" e a peça 4 reescrita no `decide.md`.
- **Bancada (peça 7):** casos (t1) a (t7) na família `decide`, seis com mutante. A família agora roda com
  `ONION_ASK_DIR` isolado num diretório vazio e restaura o valor de fora no fim, o que **cura o SAC-411**
  (os casos (g) e (l) liam o registro real de perguntas da VPS). Medido: com 9 reservas no registro real
  desta VPS, `lint-selftest.sh --families decide` sai rc 0, 45 casos verdes, sem `ONION_ASK_DIR` no ambiente.

## Achados do refutador independente (12, sobre o commit 1f34606db)

**Bloqueantes (3, todos curados):**

1. **B1. Obsoleto com `ref -` nunca gravava no core.** O contrato reprova `integrity.superseded-without-successor`,
   saía rc 3 e o lote inteiro voltava (caso real: `D_PODA_INSTRUCTION_BLOAT_MEDIDA`, cujo sucessor está em
   outro grafo). O (t7) não pegava porque o grafo da bancada não tinha o contrato vendorizado. **Cura:** o
   sucessor passa a ser obrigatório e se recusa já no `--preview`. Se ele está em outro grafo, a ref
   `<grafo>#<ID>` vira `external_edges` SUPERSEDES (contrato v4.3), conferida contra o arquivo e o id. A
   doutrina foi corrigida. **Prova:** o caso real, numa worktree descartável do core, sai rc 0 com
   "contrato rc 0 por vendor kg-ssot" e o lint de nomes verde. A bancada (t10) tem o contrato vendorizado,
   e o mutante sem a `external_edges` (a versão do 1f34606db) reprova.
2. **B2. Prazo e data validados mais frouxos que no selo unitário.** `20261201` entrava (o `fromisoformat`
   do Python 3.11+ o aceita) e virava `x_due` ilegível; `--date 2025-13-45` saía rc 0. **Cura:** `strict_date`
   (regex AAAA-MM-DD e data real) para a data e o prazo, também no `--preview`. **Prova:** (t8), com mutante.
3. **B3. O workflow chaveava só por id.** Dois candidatos de grafos diferentes com o mesmo id se fundiam no
   lote. **Cura:** a chave é `<grafo>#<id>` da entrada à síntese, e o candidato repetido é recusado.
   **Prova:** (t11), um harness em node com agentes simulados, e o mutante "chave = id nu" reprova.

**Limites curados (4):**

4. O sha da aprovação cobre também a `--date` e a `--question` (o `--preview` as exige). Prova: (t9).
5. No workflow, o label e as pistas do grafo, e o motivo e a evidência levados ao juiz, entram dentro da
   cerca R15.2 (`untrusted-content-provenance.md`), com nonce e `<<<`/`>>>` desarmados. Prova: (t11).
6. O mutante que tirava a recusa de nó que não está `open` sobrevivia. O (t8) o mata: o lote com um nó
   `done` sai rc 2 nomeando o estado. Para isso, a aprovação passou a ser conferida **depois** da forma e
   do estado dos nós, e toda recusa diz o nome.
7. `verified_at` no futuro vira aviso nomeado na triagem, em vez de sumir como "abaixo do teto". Prova: (t9).

**Limites declarados (5):**

8. A aprovação reaplicada de um lote só de pedidos passa de novo: o pedido não muda o status (o nó segue
   `open`), então o mesmo sha reaplica `owner`/`x_due` e acrescenta outra linha na narrativa.
9. Os caminhos do lote dependem do diretório de onde se roda: os grafos são relativos ao `cwd` (a raiz, como
   o medidor imprime), e só a ref externa é resolvida pela raiz git.
10. O pedido não tem proveniência própria nem as alternativas descartadas: grava `owner:`, `x_due:` e uma
    linha na narrativa.
11. O pedido ao papel `core` (a própria casa) não é recusado pelo selador; só o medidor deixa de dar a dica.
12. O modo por grafo chamado direto aplica um subconjunto do lote aprovado (sem o desfazer do lote inteiro).

## Achados (passada curta da própria sessão, antes do refutador)

1. **Corrigido.** A dica `pedido` tratava `owner: core` como outro papel. Medido no core: 65 nós com
   `owner: core` e 49 com `owner: maestro`. Agora os papéis da casa são lidos (`--own`, o `role:` do
   `.claude/.onion-version`, ou `core` no repo-fonte) e impressos no cabeçalho.
2. **Corrigido.** O nó com pedido vencido sumia até o teto, porque o selo do pedido rejuvenesce o bloco e
   a idade por commit o escondia. O pedido vencido agora volta mesmo abaixo do teto, com a dica
   `pedido-vencido`.
3. **Corrigido.** A bancada (t4) testava o mutante da conferência de sha pelo sinal invertido (o mutante
   que aceita o lote sairia "vivo"). O caso agora reprova quando o mutante **não** aplica o lote mudado.
4. **Corrigido.** O motivo do lote saía colado à frase seguinte ("…de setembro Superado por…"). Agora o
   motivo termina com pontuação.
5. **Corrigido (achado pela bancada, não pela leitura).** No lote com dois grafos, o modo por grafo do 2º
   reconferia o estado de TODOS os itens, inclusive os do 1º, que o modo externo já tinha gravado
   (`superseded`, não mais `open`): todo lote de mais de um grafo saía rc 2 e era desfeito. O teste manual
   com um grafo só não via. Agora o modo por grafo confere a forma e o sha do lote inteiro e o estado só dos
   nós daquele grafo. Os casos (t6) e (t7) cobrem.
6. **Limite declarado.** O modo por grafo (`<grafo> --batch … --approve …`) pode ser chamado direto e
   aplica só os itens daquele grafo de um lote aprovado: é um subconjunto do que o maestro aprovou, não
   um item fora dele, e passa pelo mesmo gate. O desfazer do lote inteiro só vale pelo modo externo.
7. **Limite declarado.** As mensagens que os casos (t4b) e (t5) leem são parte do que eles provam: os
   mutantes que tiram a recusa de (a) ou a falta de `--approve` ainda saem rc 2, por outra regra (destino
   fora da lista, sha diferente). O comportamento seguro se mantém, e o mutante é morto pela mensagem.

## Mutantes (cada um reprova o caso, e o SUT limpo passa no mesmo arranjo)

- (t1) sem o corte do teto, o nó novo entra.
- (t2) sem o filtro da reserva viva, o nó com dona entra.
- (t3) sem a regra da dica de superação, o superado cai em `maestro`.
- (t4a) sem a conferência do sha, o lote com item a mais é gravado. (t4b) sem a falta de `--approve`, a
  mensagem não diz o que falta.
- (t5) sem a recusa do destino (a), a mensagem não manda ao `/meta:kg-freshness`.
- (t6) sem a restauração do lote, o 1º grafo fica escrito quando o 2º reprova.
- (t8a) sem o regex estrito, o prazo `20261201` passa. (t8b) sem a recusa de não-`open`, o nó `done` vira `superseded`.
- (t10) sem a escrita da `external_edges`, o contrato reprova (rc ≠ 0), com o leitor do contrato copiado ao lado.
- (t11) com a chave voltando a ser o id nu, o lote perde um dos dois candidatos.
- (t9) não tem mutante próprio: prova a aprovação ligada à pergunta e o aviso do futuro.
- (t7) não tem mutante: é o caminho feliz (obsoleto, pedido, aresta sem duplicar, radar 0, pedido em curso
  sai da triagem seguinte).

## Dogfood no core (só medição; nenhum lote aplicado: a aprovação é do maestro)

- `decide-census.sh . --triage --markdown`: 613 `decision`/`question` abertos em 259 grafos; 179 abaixo
  do teto de 30 dias; **434 candidatos**; 0 fora por dona viva (8 reservas vivas, nenhuma de candidato);
  dicas **obsoleto 4 · pedido 0 · pedido-vencido 0 · medição 166 · maestro 264**. Idade por
  `verified_at` em 119 e por commit em 315. ~22 s.
- Classificação manual de 5 nós (amostra, a dica errou em 2 dos 4 `obsoleto`):
  - `Q_CENSO_DOS_63_CORTADOS` → (c) obsoleto, superado por `D_C_CENSO_190_JUIZ_EM_CONFIRMED` (mesmo grafo,
    decisão selada pelo maestro em 2026-08-30 sobre o censo em escala).
  - `D_RUNTIME_CONTRACT` → (a) medição, não obsoleto: o `E_MEDIDO_D_RUNTIME_CONTRACT_2026_09` diz que o ADR
    já registra "accepted (degrau AUDIT)". Fecha pelo `/meta:kg-freshness`.
  - `D_PODA_INSTRUCTION_BLOAT_MEDIDA` → (c) obsoleto, superado por `D_PODA_INSTRUCTION_BLOAT_CLAUDE_MD_E_SKILLS`
    de **outro** grafo: ref `-`, superação escrita no motivo.
  - `Q_UPDATE_EXIGE_ADOCAO_INTEGRADA` → (d) maestro, não obsoleto: `D_SELO_DO_MAESTRO_REVERTEU_O_FLIP` diz
    que o maestro reverteu exatamente esse flip para `superseded` em 2026-09-06.
  - `D_DEFINE_CHURN` (dica `medição`) → (d) maestro: é definição de domínio num grafo de material didático
    (`docs/materials/cold-adopter-2026-07/`), e o vizinho PROD é a métrica, não a definição.
- Depois das curas: o lote do refutador com `D_PODA_INSTRUCTION_BLOAT_MEDIDA` e `ref -` sai rc 2 no `--preview`
  (sem sucessor). Com a ref `docs/evolution/research/poda-instruction-bloat-2026-09/poda-instruction-bloat-2026-09.kg.yaml#D_PODA_INSTRUCTION_BLOAT_CLAUDE_MD_E_SKILLS`,
  numa worktree descartável do core, o selo sai rc 0 com o contrato e o lint de nomes julgados. A worktree
  foi removida, e nada foi gravado no core.
- Modo de falha: `--max-age-days abc` e `-3` → rc 2 com a mensagem; grafo rastreado que não parseia → rc 2
  nomeando o arquivo (bancada t3). O workflow não foi disparado (subagente não orquestra); a síntese
  determinística foi exercitada com agentes simulados sobre os 434 candidatos do core.

## Limites declarados

- A dica é pista: na amostra, errou em 2 de 4 `obsoleto` (aresta de evidência e reversão do maestro).
- Grafos de material didático e propostas rejeitadas em `kg-inbox/_rejected/` entram como no censo
  (só fixtures/ e vendor/ ficam fora).
- O workflow não foi rodado com agentes reais nesta forja; a forma do retorno do harness não foi medida.

## Gate

- `bash .claude/validation/lint-artifacts.sh`: rc 0, **0 HARD**, 26 SOFT (nenhum destes arquivos). A 1ª
  passada deu 1 HARD, a REGRA 80 (Números do harness saem de SSOT gerada, nunca de comentário), por causa
  dos casos novos. Curada com `harness-inventory.sh --markdown > docs/onion/testing-inventory.md`.
- `bash .claude/validation/lint-selftest.sh --families decide`: rc 0, **49 casos** verdes, (t1) a (t11), sem
  `ONION_ASK_DIR` no ambiente (a família isola o seu).
- `bash .claude/validation/forge-census.sh .`: `decide` 7/7.

## Refutador independente

- 1ª passada: REPROVADO, com 3 bloqueios (obsoleto sem sucessor derrubava o lote, data e prazo frouxos no lote, chave só por id no workflow) e 9 limites.
- 2ª passada, sobre o commit 834912cbc: APROVADO COM LIMITES. Os 3 bloqueios e 4 limites curados resistiram; a família decide passou 49 de 49 e o lint 0 HARD.
- Limites que sobram: a reaplicação idêntica de um lote só de pedidos grava de novo (item 8), e no prompt do refutador do workflow o `ref`, o `due` e a chave ficam fora da cerca de conteúdo não confiável.
