---
branch: feat/meeting-notice-absence-record
pr: pendente
date: 2026-11-09
reviewed_diff_sha256: pendente
findings_total: 18
findings_real: 17
findings_blocking: 2
tokens: 0
duration_min: 30
findings_fixed: 9
verdict: FIXED
elenxo: false
reviewer: "1ª passada: o próprio agente de execução. 2ª passada: revisão técnica da curadoria, que não escreveu o diff, com 2 bloqueios e 11 não bloqueantes; não é parecer jurídico."
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

## Revisão da curadoria (2026-11-09)

| Achado | Destino |
|---|---|
| bloqueio: o rc 0 liberava a consolidação | curado: `--for-use` sai rc 3 e a consolidação retém; entra só por decisão explícita, com a marca |
| bloqueio: o relatório só tinha `✅ conforme` ou `✗` | curado: estado `⚠️ NÃO HOUVE AVISO`, título e linha SOFT; a linha final do gate não diz "conforme" |
| nó sem dono, prazo ou saída | curado: `x_owner`, `x_due` opcional e `x_notice_remediation`, sem valor que declare licitude; o rc 3 não muda |
| a linha SOFT não pedia providência | curado: diz que não libera o uso e o que cabe ao controlador |
| a contagem só vê participantes | curado na redação da linha |
| ausência na reunião não prova ausência em contrato | curado no comando |
| o nó citava depois da parada | curado: o trace vai até a parada, sem exceção em `CAPTURA-APOS-RECUSA` |
| pendência jurídica sem nó | curado: `Q_MN_LEGAL_READING_1109`, SAC-386 |
| dado sensível ou de criança | instrução no comando e na consolidação; o gate não distingue |
| prazo e eliminação, inclusive histórico git | uma linha no comando; rota não construída |
| operador e transferência internacional | não tratado; fica com o controlador e declarado no nó |
| o incentivo premia declarar: rc 0 contra rc 1 | não curado; a base segue texto livre, e o uso retido reduz o ganho |
| elogio ao desenho | sem ação |

## Teto

- Registra o fato e não supre a transparência; não é conformidade, e nenhuma análise jurídica foi feita. A pendência da leitura jurídica está em `Q_MN_LEGAL_READING_1109` (SAC-386).
- O adotante de consultoria só recebe isto no próximo `--update`; a exceção nomeada no gate dele não foi tocada, e migrar é ato da sessão dele.
- A linha final do CLI tem caso (c2), sem mutante próprio.
