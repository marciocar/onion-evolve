---
branch: feat/dissect-idea-harvest
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: 60b87cfd294246f7689efb6f04ca7fe161080efc169162b32a2992aacb9b0a65
reviewed_code_sha256: 5f51e444f26d717200791adb4f759e330298d8c2735afdd6bee6e4006385c6b0
findings_total: 4
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 75
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: "o autor (agente de execução da sessão do core), em passada própria sobre o diff; não é independente"
nota: "tokens 0 = não medido (passada na própria sessão, sem subagente; o brief proibia lançar subagentes). Os 2 achados reais vieram do dogfood nos estudos dos peers e foram curados no mesmo PR, cada um com caso e mutante. Os 2 restantes são LIMITE declarado."
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
