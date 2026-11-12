---
branch: feat/dissect-synthesis-required
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: 4e59dc048ac1202f865ba0223647f7a071923bcef6ff2f4f4ef35d106e445c86
reviewed_code_sha256: 0791f145df83e288b342d30f099ec363e7131c2856102b9de1d809c06d7d9bbb
findings_total: 3
findings_real: 1
findings_blocking: 0
findings_fixed: 1
tokens: 0
duration_min: 30
verdict: FIXED
elenxo: false
reviewer: "agente de execução (claude-opus-5-5), passada própria sobre o próprio diff"
nota: "tokens não medidos pelo agente; o harness reporta o uso na notificação final"
---

# Passada adversarial: `feat/dissect-synthesis-required`

## O que muda

- `dissect-object-check.py` ganha o **item 11**: no estágio final (o padrão do checador, ou `--stage final`), o
  estudo traz `<pasta-do-grafo>/SYNTHESIS.md` (senão `synthesis-ausente`, fail-closed, rc 1, nomeando o caminho
  esperado), e ela cita o grafo da mesma pasta no `kg:` do frontmatter ou num link markdown (senão
  `synthesis-nao-cita-o-grafo`). `--stage plan` não cobra. A checagem roda antes dos retornos cedo do item 2, então
  vale também para o modo estudo e para o grafo sem veredito.
- Bancada: a fixture boa passa a nascer com a síntese; 4 casos novos (sem síntese reprova; stage plan sem síntese
  passa; síntese citando por link passa; síntese que não cita o grafo reprova). Piso da família `dissect_object`
  sobe de 125 para 129 casos.
- Doutrina §6 e `/meta:dissect` passo 5: uma linha cada dizendo que a síntese é obrigatória no estágio final.

## Medição

- Família `run_dissect_object_selftests`: 135 pass, 0 fail (129 casos + 4 de rc 3, cobertura dos códigos).
- Mutante por código (o da bancada): calar `synthesis-ausente` e `synthesis-nao-cita-o-grafo` faz os dois casos
  deixarem de acusar (rc 0).
- Mutante da regra inteira: o checador da `origin/main` (sem o item 11) sai **rc 0** nas fixtures sem síntese e com
  síntese solta; o novo sai rc 1 com o código certo em cada uma, e rc 0 na fixture boa.

## Achados

1. **REAL, curado** — o frontmatter só era lido com `\n`; síntese gravada com CRLF caía para "só links" e
   reprovava mesmo com `kg:` correto. O regex aceita `\r?\n`.
2. **LIMITE declarado** — a citação casa pelo nome do arquivo do grafo, não pelo caminho completo: uma síntese que
   cite o grafo homônimo de outra pasta passaria. A convenção do corpus é pasta = nome do grafo, então o homônimo
   só existe por cópia; não bloqueia.
3. **LIMITE declarado** — o checador confere presença e citação, não a qualidade da síntese nem se ela projeta o
   veredito sustentado: trabalho do Elenxo, como o resto do TETO DECLARADO do checador.

## Estudos já rastreados

Os dois estudos por família do corpus (`problem-formula-2026-11`, `problem-route-2026-11`) têm a síntese citando o
grafo e não ganham achado novo; já reprovavam antes por itens 2, 5 e 6, sem relação com esta mudança. Os 9 estudos
anteriores à família (sem `x_study_destination`) seguem fora do `--context` por desenho; rodado direto, o checador
agora lista também `synthesis-ausente` em 9 deles (o de `intelligent-ui-2026-10` tem a síntese). Nenhum foi
consertado aqui.
