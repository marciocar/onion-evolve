---
branch: feat/dissect-idea-harvest
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: 57bafc6f71755034cde6473d385fbc6b9b0379a5811b53b88dd7163756e94dd3
reviewed_code_sha256: 8e39394a6f608c2e128540ae772716c3fda81b1f1926aa8b169b05d2752c32a0
findings_total: 7
findings_real: 4
findings_blocking: 0
tokens: 0
duration_min: 120
findings_fixed: 4
verdict: CORRIGIDO
elenxo: nao
reviewer: "o autor (agente de execução da sessão do core), em passada própria sobre o diff; não é independente"
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente; o brief proibia lançar subagentes). Os 4 achados reais (2 do dogfood nos estudos dos peers, 2 da passada sobre a extensão do destino e da candidata) foram curados no mesmo PR, cada um com caso e mutante. Os 3 restantes são LIMITE declarado."
---

# Passada adversarial: `feat/dissect-idea-harvest`

## O que muda

- `.claude/validation/dissect-object-check.py`: o item 9, o **registro de ideias**. Toda dissecação (estudo, veredito
  positivo, negativo e a que o eliminatório encerra) registra nós `x_dissect_idea` {`kind`, `onion`, `why`, `source`,
  e `candidate` com `value`/`value_why`}, cobrindo funcionalidade, estratégia e decisão de desenho, ou declara a
  lacuna por tipo. Com peças, cada peça tem as suas ideias. Roda antes do item 2, para os retornos cedo não o pularem.
  O `--context` ganha a coluna `ideias`.
- `.claude/validation/dissect-object-bench.py`: 16 casos novos (114 + 4 de rc 3), entre eles a rejeição no eliminatório
  do N0 sem ideias (o caso do quicue-kg) e a peça rejeitada sem ideias (imessage, MCP Agent Mail). O tipo `aviso:`
  passa a servir o item 9. O piso da família `run_dissect_object_selftests` sobe de 98 para 114.
- A doutrina ganha a §1c (veredito de USO ≠ registro de IDEIAS), e o comando (passo 3b) e a lente a citam.
- `dissect-forge-2026-10.kg.yaml`: a evidência medida e o selo `D_DISSECT_VEREDITO_DE_USO_SEPARADO_DAS_IDEIAS_1107`
  (por `kg-decide-seal.sh --new`).

## Achados

1. **REAL, corrigido (dogfood):** o update poria em vermelho os 22 estudos v4 da curadoria. O workflow
   `curation-dissect.yml` confere todos os estudos v4 quando o checador muda, e nenhum tem ideia registrada. Isso
   travaria qualquer update da curadoria, inclusive os que não têm relação com a colheita. Cura: corte por data
   (`IDEAS_SINCE = 2026-11-07`). Estudo com Etapa 0 anterior ao corte recebe a mesma lista como `aviso item 9`, com
   rc 0. Data ilegível não conta como anterior. Os casos "estudo anterior à régua" (aviso) e "registered_at ilegível"
   (achado) reprovam contra o mutante.
2. **REAL, corrigido:** a 1ª versão aceitava a peça com zero ideias quando ela declarava a lacuna nos 3 tipos. Era a
   saída exata que a crítica do maestro mira. Cura: `peca-sem-ideias` passa a valer sempre, e a lacuna cobre um tipo,
   nunca o objeto. O caso usa a lacuna nos 3 tipos e reprova.

## LIMITE declarado (não bloqueia)

3. O corte lê o `registered_at` que o próprio estudo declara. Um estudo novo poderia antedatar a Etapa 0 para receber
   aviso em vez de achado. É o mesmo modelo de confiança do item 5, onde o `registered_at` já é auto-declarado. O git
   prova a ordem dos commits, não o relógio. O Elenxo é quem pega isso.
4. O checador confere a FORMA da fonte (`arquivo:linha` ou URL), não se a linha existe no repo alheio, e não julga o
   mérito da ideia nem o `value`. Os dois limites estão escritos na doutrina (§1c e §5).

## Suspeitas descartadas

- O item 9 reprovar o estudo `--stage plan`: descartada, porque ele roda depois do retorno do stage plan.
- Ideias de peça quebrarem quando `x_dissect_pieces` está mal formado: descartada. As peças inválidas ficam de fora,
  as ideias caem no objeto, e o item 2 já acusa a lista.

## Mutantes e dogfood

- Bancada: 114 casos e 4 de rc 3 verdes, com cobertura de todos os 58 códigos. Cada caso reprova contra o mutante do
  seu código, e o aviso do item 9 some com o `note(9` calado.
- Rodado nos estudos reais dos peers com o checador do ramo: `quicue-kg-2026-11` (kg-ssot, Etapa 0 de 2026-11-07) sai
  rc 1 `sem-registro-de-ideias`, e `claude-code-channels-2026-11` (curadoria, de 2026-11-06) sai rc 0 com o aviso.
  Com o checador da `main`, os dois saem 0 achado.
- Um grafo com o nó de ideia (`x_dissect_idea`) passa no `kg_validate` do contrato vendorizado.

## Re-revisão (2º commit, `fix(kg)`)

O `pr-finalize` reprovou no contrato. O lint de nomes acusou os códigos curtos dos eliminatórios sem termo na prosa
da evidência `E_ELIMINATORIO_APAGA_A_COLHEITA_1107`, e o `label` dela passava de 280 caracteres. O 2º commit escreve
os eliminatórios por extenso e encurta o `label`. Ele só mexe na prosa desse nó, e o código não muda. Conferido de
novo: `kg-vocab-ci.sh` rc 0 (0 códigos novos), `kg-contract-check.sh` rc 0, `kg-radar.sh --integrity --schema` rc 0.
Nenhum achado novo.

## Extensão: o destino da ideia e a candidata órfã (3º lote, pedido da sessão principal)

O censo dos objetos barrados nos três repos (2026-11-07) mediu duas coisas. Não há chave de colheita em nenhum grafo.
E o padrão dominante não é "barrado sem ler": é "lido até o N2, ideia citada no rótulo do veredito e nunca entregue".
Daí:

- **item 9, `ideia-sem-destino`**: toda ideia declara `destination` (`<repo>:<caminho>#<ID>`, issue `SAC-123` ou
  URL) ou `nenhum` com `destination_why`. O `--context` mostra `ideias/com destino` por estudo, e o marcador contável
  são os próprios nós (`git grep -c 'x_dissect_idea:'`). Uma lista no `meta:` seria declaração paralela aos nós.
- **item 10**: o parque declara a candidata como ponteiro (`x_dissect_candidate`). Se a candidata foi rejeitada ou
  refutada depois, sai `gatilho-orfao`: achado no parque aberto, aviso no parque já selado. Ponteiro mal formado ou
  que não existe reprova. Ponteiro para outro repo sai como aviso `candidata-fora-do-repo`.

Achados desta passada:

5. **REAL, corrigido:** o leitor de cobertura da bancada lia `add\((\d),`, um dígito só. Os códigos do item 10 ficavam
   invisíveis à cobertura (ela dizia "59 códigos têm caso" e saía verde), e o mutante não os achava. Cura: `\d+` no
   leitor e no mutante. Agora são 62 códigos, e os casos do item 10 reprovam contra o mutante.
6. **REAL, corrigido:** `x_dissect_candidate` com caminho absoluto ou com `..` fazia o checador ler um arquivo fora
   do repo. Cura: esses caminhos saem `candidata-mal-formada`, com caso próprio.
7. **LIMITE:** a candidata em outro repo não é lida (o checador não lê repo alheio, como no selo). Ela sai como aviso
   e não é medida. Repo e caminho "dele mesmo" se reconhecem pelo nome do `origin` e da pasta raiz.

Dogfood do item 10 num clone descartável da curadoria (nada escrito no repo dela). Pus no
`D_AGENT_NEUTRAL_CHANNEL_VERDICT` o ponteiro `onion-curation:…/claude-code-channels-2026-11.kg.yaml#D_PIECE_CH_AGENT_MAIL`
e rodei o checador do ramo: saiu `aviso item 10 gatilho-orfao`, rc 0 (o parque é selado). Saiu também o
`aviso item 7 gatilho-disparou-depois-do-selo`, que já existia ali. Bancada: 125 casos + 4 de rc 3 verdes, 62
códigos cobertos, cada caso contra o mutante do seu código.

Re-revisão do 4º commit (`fix(dissect)`): o lint do commit acusou a REGRA 106 (Superfície que viaja passa pela
varredura de vazamento da publicação) em dois exemplos, um na doutrina e um na bancada, que nomeavam um repo de
adotante. Os dois viram placeholders (`<repo>:`, `outro-repo:`). A semântica não muda: o caso da bancada segue
exigindo o aviso `candidata-fora-do-repo`.
