---
branch: feat/dissect-synthesis-required
pr: 1638
date: 2026-11-12
reviewed_diff_sha256: fc364d13d5f5f42819d2a2e621be9035c873c6868b736d80a19161fd226096fb
reviewed_code_sha256: 38e87e980823c27d6a1a344f93ac6379fe399bc0fa18b71842fc97c96d5e0ff5
findings_total: 6
findings_real: 2
findings_blocking: 1
findings_fixed: 2
tokens: 0
duration_min: 30
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "refutador independente (re-revisão do #1638) + agente de execução (claude-opus-5-5) na cura"
nota: "tokens não medidos pelo agente; o harness reporta o uso na notificação final"
---

# Passada adversarial: `feat/dissect-synthesis-required`

## O que muda

- `dissect-object-check.py` ganha o **item 11**: no estágio final (o padrão do checador, ou `--stage final`), o
  estudo traz `<pasta-do-grafo>/SYNTHESIS.md` (senão `synthesis-ausente`, fail-closed, rc 1, nomeando o caminho
  esperado), e ela cita o grafo da mesma pasta no `kg:` do frontmatter ou num link markdown (senão
  `synthesis-nao-cita-o-grafo`). `--stage plan` não cobra. A checagem roda antes dos retornos cedo do item 2, então
  vale também para o modo estudo e para o grafo sem veredito.
- Bancada: a fixture boa passa a nascer com a síntese; 5 casos novos (sem síntese reprova; kg de outra pasta com o mesmo nome reprova; stage plan sem síntese
  passa; síntese citando por link passa; síntese que não cita o grafo reprova). Piso da família `dissect_object`
  sobe de 125 para 130 casos.
- Doutrina §6 e `/meta:dissect` passo 5: uma linha cada dizendo que a síntese é obrigatória no estágio final.

## Medição

- Família `dissect_object` (`run_dissect_object_selftests`): 130 casos + 4 de rc 3 verdes, cobertura dos códigos; piso 130.
- Mutante por código (o da bancada): calar `synthesis-ausente` e `synthesis-nao-cita-o-grafo` faz os dois casos
  deixarem de acusar (rc 0).
- Mutante da regra inteira: o checador da `origin/main` (sem o item 11) sai **rc 0** nas fixtures sem síntese e com
  síntese solta; o novo sai rc 1 com o código certo em cada uma, e rc 0 na fixture boa.

## Achados

1. **REAL, curado** — o frontmatter só era lido com `\n`; síntese gravada com CRLF caía para "só links" e
   reprovava mesmo com `kg:` correto. O regex aceita `\r?\n`.
2. **REAL, BLOQUEIO, curado (refutador independente)** — a 1ª versão comparava só o nome do arquivo: aceitava
   um `kg:` apontando `docs/evolution/dissect/lixo/<grafo>.kg.yaml` e um link inline cujo alvo é `../outra-pasta/<grafo>.kg.yaml`, o ponteiro velho de um
   estudo movido ou renomeado. Cura: o `kg:` resolve da raiz do repo, o link da pasta da síntese, e os dois se
   comparam por `os.path.normpath` com o caminho do grafo medido. Bancada: o caso "kg de outra pasta com o mesmo
   nome" exige `synthesis-nao-cita-o-grafo`, e além do mutante do código ganha o mutante que volta ao nome (rc 0,
   o caso deixa de acusar).
3. **LIMITE declarado** — citação só em prosa, ou em link de referência (`[g][ref]` com `[ref]: caminho`), reprova:
   o checador lê o `kg:` e links inline.
4. **LIMITE declarado** — link dentro de bloco de código ou de comentário HTML passa: o leitor de links não
   conhece a estrutura do markdown.
5. **LIMITE declarado** — não se confere se a SYNTHESIS.md está commitada; basta existir na árvore.
6. **LIMITE declarado** — o checador julga forma, não qualidade: se a síntese projeta o veredito sustentado é
   trabalho do Elenxo, como o resto do TETO DECLARADO do checador.

## Estudos já rastreados

Os dois estudos por família do corpus (`problem-formula-2026-11`, `problem-route-2026-11`) têm a síntese citando o
grafo e não ganham achado novo; já reprovavam antes por itens 2, 5 e 6, sem relação com esta mudança. Os 9 estudos
anteriores à família (sem `x_study_destination`) seguem fora do `--context` por desenho; rodado direto, o checador
agora lista também `synthesis-ausente` em 9 deles (o de `intelligent-ui-2026-10` tem a síntese). Nenhum foi
consertado aqui.
