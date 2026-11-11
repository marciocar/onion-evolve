---
branch: feat/decide-batch-triage
pr: pendente
date: 2026-11-11
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 7
findings_fixed: 5
findings_blocking: 0
verdict: CORRIGIDO
elenxo: sim
reviewer: "passada adversarial curta da própria sessão de execução; NÃO houve revisor independente"
nota: "o revisor independente fica para o pr-finalize / CI; os dois achados não corrigidos estão declarados como limite"
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

## Achados (passada adversarial da própria sessão)

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
- Modo de falha: `--max-age-days abc` e `-3` → rc 2 com a mensagem; grafo rastreado que não parseia → rc 2
  nomeando o arquivo (bancada t3). O workflow não foi disparado (subagente não orquestra); a síntese
  determinística foi exercitada com agentes simulados sobre os 434 candidatos do core.

## Limites declarados

- A dica é pista: na amostra, errou em 2 de 4 `obsoleto` (aresta de evidência e reversão do maestro).
- Grafos de material didático e propostas rejeitadas em `kg-inbox/_rejected/` entram como no censo
  (só fixtures/ e vendor/ ficam fora).
- A superação entre grafos não vira aresta: fica no motivo.
- O workflow não foi rodado com agentes reais nesta forja; a forma do retorno do harness não foi medida.

## Gate

- `bash .claude/validation/lint-artifacts.sh`: rc 0, **0 HARD**, 26 SOFT (nenhum destes arquivos). A 1ª
  passada deu 1 HARD, a REGRA 80 (Números do harness saem de SSOT gerada, nunca de comentário), por causa
  dos casos novos. Curada com `harness-inventory.sh --markdown > docs/onion/testing-inventory.md`.
- `bash .claude/validation/lint-selftest.sh --families decide`: rc 0, 45 casos verdes, (t1) a (t7) inclusos.
- `bash .claude/validation/forge-census.sh .`: `decide` 7/7.
