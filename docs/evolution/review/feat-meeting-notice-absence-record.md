---
branch: feat/meeting-notice-absence-record
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: 12e763e32a1f6b2be90b6f64549bf8c5dc59c70837921908f7a182e0c2bdcaf5
reviewed_code_sha256: 9bfe48846618a8b45f712ddea2d9f36f379aa9ee9dd0204392ef1e2d1e154eca
findings_total: 5
findings_real: 5
findings_blocking: 0
tokens: 0
duration_min: 30
findings_fixed: 3
verdict: FIXED
elenxo: false
reviewer: "o próprio agente de execução (passada própria, não independente; o brief proibiu criar agentes). Toca LGPD: sem leitura jurídica."
nota: "tokens 0 = não medido. meeting-graph-check --selftest verde; família meeting_graph com os mutantes novos mordendo."
---

# Passada adversarial: `feat/meeting-notice-absence-record`

## O que muda

- Papel novo `notice_absent` em `meeting-graph-check.sh`. A reunião sem aviso, quando isso se sabe, passa na forma (rc 0)
  e sai como `SOFT:AVISO-AUSENTE` no stdout, com a contagem de pessoas. A linha final deixa de dizer "aviso registrado".
- Quem não registrou nada segue em `SEM-TENTATIVA-DE-AVISO` (HARD).
- O nó fica `status: open`, `impact` 4 ou 5, com o label dizendo "não houve aviso", base escrita e trace na transcrição inteira.
- Com a ausência, cada participante é `nao_avisado` ou `recusou`; a parada por recusa segue valendo.

## Achados

| # | Achado | Veredito | Destino |
|---|---|---|---|
| 1 | SOFT em stderr some em quem filtra `2>/dev/null`, como a própria bancada faz | real | curado: SOFT no stdout |
| 2 | "✅ conforme (aviso registrado…)" sairia numa reunião sem aviso | real | curado: linha própria, caso (c2) |
| 3 | o nó poderia ser lido sozinho como regular: o label é texto livre | real | curado: `AUSENCIA-SEM-DECLARACAO` exige as palavras, caso e mutante |
| 4 | quem nunca procurou o aviso pode escrever `notice_absent`: a base é texto livre | limite | o gate não prova uma ausência fora da transcrição; a doc restringe a quem sabe, e o trace exige a fonte inteira |
| 5 | o label aceita texto que, além das palavras, sugira regularidade | limite | não curado: lista de termos falha pelo vocabulário |

## Teto

- Não é conformidade, e nenhuma análise jurídica foi feita. A pendência da leitura jurídica não tem nó: o grafo da captura está no teto de nós declarado (REGRA 58), e o PR a nomeia para a sessão registrar onde couber.
- O adotante de consultoria só recebe isto no próximo `--update`; a exceção nomeada no gate dele não foi tocada, e migrar é ato da sessão dele.
- A linha final do CLI tem caso (c2), sem mutante próprio.
