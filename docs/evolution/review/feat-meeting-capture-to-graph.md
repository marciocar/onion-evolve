---
branch: feat/meeting-capture-to-graph
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: dcea26f8494541cc35cf504cfe14e7fca84158b68124e101ee1c245bdffacb4b
reviewed_code_sha256: 831a3f2004239df7d629d895e98c4793bd37590d879217c67c361c98101a2152
findings_total: 23
findings_real: 23
tokens: 303066
duration_min: 63
findings_fixed: 22
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: opus (subagente general-purpose, 2 passadas com mandato de refutar)
nota: "tokens e duração somam as duas passadas, lidos do harness (153133 + 149933 tokens; ~13 min + ~50 min, a 2ª com a máquina em load ~21). O achado 5 da 2ª passada fica declarado, sem cura."
---

# Passada adversarial: `feat/meeting-capture-to-graph`

## O que muda

- `/product:extract-meeting` grava também `docs/meetings/<nome>.kg.yaml` a partir de transcrição em texto
  (pessoas, aviso, decisões, ações, riscos, com trace ao trecho), e o gate novo
  `.claude/validation/meeting-graph-check.sh` cobra o modelo aviso ≠ consentimento (absorvido por reescrita do
  anarlog): reunião sem tentativa de aviso registrada reprova, a recusa para a captura, o grafo nunca declara
  consentimento. Roda o radar e o contrato por cima.
- Diretório único: `docs/meetings/` (29 linhas com `docs/meet` migradas em 7 arquivos).
- Plugin onion-product empacota o gate, o radar, o contrato e `utils/kg`.
- Sela D_VEXA_2610, D_ANARLOG_2610 e P_CONSENT_EVIDENCE_REWRITE pelo `kg-decide-seal.sh`; o Q da máquina de
  captura fica aberto (SAC-164).

## Achados

**1ª passada (12):**
1. ALTO: comentário na coluna 0 abria seção e cegava o leitor. **Curado** (comentário nunca abre seção).
2. ALTO: nó sem `x_meeting_role` (e `- id:` com outra indentação) escapava. **Curado** (PAPEL-AUSENTE; leitor por indentação relativa).
3. ALTO: parada não amarrada à recusa (faixa atravessando e parada além do EOF passavam). **Curado** (PARADA-DEPOIS-DA-RECUSA; compara o fim da faixa).
4. ALTO: o plugin onion-product não montava (o gate chama o contrato). **Curado** (manifesto).
5. MÉDIO: fonte absoluta ou `..`. **Curado** (FONTE-FORA-DA-RAIZ).
6. MÉDIO: reunião sem participante. **Curado** (SEM-PARTICIPANTE).
7. MÉDIO: consentimento em outras grafias. **Curado** (e, na 2ª passada, vocabulário fechado).
8. MÉDIO: aviso só com espaço, fora do trecho, depois dos fatos. **Curado**.
9. MÉDIO: a bancada não exercia o contrato. **Curado** (caso com o vendor, e mutante).
10. MÉDIO: o comando se contradizia sobre o grafo reprovado. **Curado** (fica gravado, não vale).
11. BAIXO: números errados nos grafos (31 contra 29; 19 polaridades). **Curado**.
12. BAIXO: o sinal segue no inbox do checkout principal. **Curado** depois do push (apagado lá).

**2ª passada (11):**
1. ALTO: item de lista dentro do nó sombreava a chave real. **Curado** (lista no nó não é chave; CHAVE-DUPLICADA).
2. MÉDIO: nó em estilo fluxo invisível. **Curado** (NO-FORA-DA-FORMA).
3. MÉDIO: caminho relativo pulava o contrato com causa falsa. **Curado** (realpath antes do `cd`).
4. MÉDIO: aviso de uma palavra satisfazia a cobrança. **Curado** (AVISO-FRAGMENTO: ≥ 20 caracteres e ≥ metade do trecho).
5. MÉDIO: a linha do trace do participante não é conferida como fala dele. **Declarado, sem cura**: depende do
   formato da transcrição (falante por linha), que o comando não fixa.
6. MÉDIO/BAIXO: consentimento fora do nome da chave. **Curado em parte**: chaves `x_` em vocabulário fechado
   (CHAVE-X-DESCONHECIDA). Consentimento afirmado em VALOR ou em `label` fica declarado.
7. MÉDIO/BAIXO: só fatos eram cobrados depois da parada. **Curado** (todo nó menos a reunião).
8. BAIXO: falsos positivos. **Curado em parte**: NFC dos dois lados, aspas escapadas, `./` na fonte, bloco
   literal, recusa no fim da faixa do participante. `x_notice_text` em bloco `>-` segue reprovando (o comando
   pede string de uma linha).
9. BAIXO: 17 mutantes do refutador sobreviviam. **Curado**: a família tem 50 mutantes, um por cura, cada um
   com o caso que o isola.
10. BAIXO: o caso de indentação usava YAML inválido. **Curado** (reindenta o bloco inteiro).
11. BAIXO: deriva de números. **Curado**.

## Mutantes

- Bancada: `bash .claude/validation/lint-selftest.sh --families meeting_graph` → 55 ✓, 0 ✗, em 32 s:
  (a) `--selftest` com 55 polaridades e o contrato julgado; (b) a fixture boa dá rc 0; (c) a reunião sem
  aviso, gerada pelo próprio comando no dogfood, dá rc 1 só com SEM-TENTATIVA-DE-AVISO; (d) sem radar dá
  rc 2; (e) caso inexistente dá rc 1; e 50 mutantes na cópia, cada um mordendo o caso que nomeia.
- Mutante vivo por `ops/mutate-and-restore.sh` (`if not notices:` → `if 0:`): a família reprovou nos casos
  (a) e (c), e o arquivo foi restaurado (hash conferido, 0 marcadores).

## Limites declarados

- O gate só roda quando o comando o chama: não está no lint do repo que guarda as reuniões
  (Q_MEETING_CONSOLIDATION_GRAPH).
- O dogfood foi por agente de contexto limpo seguindo o arquivo do comando da worktree, porque a skill
  carregou a versão do checkout principal. Duas transcrições fictícias, duas rodadas: a 1ª achou o furo do
  `confidence: high`.
- A pergunta do P_CONSENT_EVIDENCE_REWRITE foi reconstruída do tema (o texto literal não chegou ao agente),
  e o selo diz isso.
- Nenhuma ferramenta de captura (Vexa, anarlog) foi executada; os vereditos são da leitura da curadoria.
