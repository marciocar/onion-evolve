---
branch: feat/chat-channel-contract
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: pendente
findings_total: 19
findings_real: 19
findings_blocking: 6
tokens: 317279
duration_min: 8
findings_fixed: 11
verdict: REJECTED_AND_FIXED
elenxo: false
reviewer: general-purpose (opus), isolado
nota: "duas passadas do mesmo revisor isolado (14 achados na 1ª, 5 novos na 2ª, sobre as curas); revisor isolado com mandato de refutar, sem ver o raciocínio da sessão; tokens e duração são os do agente revisor. Os 6 que bloqueavam foram curados; dos 8 limites, 3 foram curados (nomes privados, pontos do Delphi, fonte do nó de origem) e 5 ficam declarados no README e abaixo."
---

# Passada adversarial: `feat/chat-channel-contract`

## O que muda

O contrato SDAAL de canal de conversa (`onion.chat/v1`) nasce em `.claude/utils/chat/`, no molde do task-manager:
schema da mensagem normalizada com os 5 campos e da resposta, vocabulário fechado de 22 capacidades, o juiz
`conformance.py` (rc 0 conforme · 1 viola · 2 não mediu), a declaração do adapter WAHA (que roda na peça de mensageria,
fora do core), o `enforcement.tsv` da REGRA 107 (Adapter SDAAL declara onde o seu contrato é cobrado) e o README com a
síntese do Delphi. Grafo novo `chat-channel-contract-2026-11` (origem do pedido, construção, medida do WAHA e a
pergunta aberta da peça), e no arquivo de selos a aresta do nó do contrato sai da sombra da AWS e vai para a origem.
Bancada: família `run_chat_conformance_selftests` em `.claude/validation/lint-selftest.sh` (guarda: o merge é do maestro).

## Achados

Revisor isolado, 14 achados, 14 reais, 6 bloqueavam. Todos os 6 curados.

1. **B1 — `[]` saía conforme (rc 0).** Cura: nenhuma mensagem é rc 2 (não mediu); caso (o) com a lista vazia.
2. **B2 — telefone no formato brasileiro passava** (`(11) 98765-4321`), e data e hora no texto reprovavam. Cura: até 3
   separadores entre dígitos, datas e horas retiradas antes da busca; casos (l2) e (a) com data no texto.
3. **B3 — data impossível passava no pattern e desligava as checagens de ordem.** Cura: toda hora do contrato tem de se
   ler; senão é FORMA. Caso (l8).
4. **B4 — a resposta não era cruzada com a mensagem respondida** (outro lugar, outro fio, em nome de outra pessoa).
   Cura: com o evento no fluxo, lugar, fio, `on_behalf_of` e as horas do pedido têm de ser os da mensagem respondida.
   Casos (l9) a (l12).
5. **B5 — o README prometia mais que a bancada.** Cura: um caso para cada código de falta (LATENCIA no evento e na
   resposta, RETENCAO, papel sem pessoa, NAO-E-JSON, kind desconhecido) e mutantes do próprio juiz (abaixo).
6. **B6 — a declaração do WAHA inflava a contagem.** Guarda de vazamento, teto e segredo fora da saída passam a
   `partial`, pelas notas das próprias linhas e pelo log do vigia não medido: de 6 para 3 de 17 obrigatórias.
7. **L6 — nomes de repos privados na superfície que viaja.** Curado: `.claude/` nomeia a peça pelo papel
   («peça de mensageria»), a fonte vira `piece:messaging/…`, o README tira os nomes das sessões do Delphi e a
   biografia do PR anterior.
8. **L7 — três pontos do Delphi faltavam.** Curado: retenção «na conta da empresa quando for Brain» no vocabulário; a
   chave para o credstore no passo 0 do que falta no `waha.md`. O eliminatório da bancada com provedor simulado segue
   em prosa nas regras invariantes (não há como o core medir a bancada da peça).
9. **L8 — fonte do nó de origem fora do repo e «com mutantes» impreciso.** Curado: confiança 0.7 e a frase que diz
   que as duas fontes vivem fora do git; «mutantes plantados no próprio juiz».
10. **L1, L2, L3, L5 — dedupe exata, coerência quem pede × audiência, frescor da audiência, schema aberto.**
    Declarados no README como limite do juiz.
11. **L4 — resposta sozinha no fluxo não cruza com o evento.** Já declarado; reforçado no README.
12. **(c) e (d) passam pelo mesmo `const`.** Real, não bloqueia: os dois ficam porque nomeiam os dois desvios que o
    Delphi proíbe (texto e nome exibido); o mutante M02 morde os dois.

### 2ª passada (sobre as curas, commit c4f2e8940): APROVADO COM LIMITES, 0 bloqueiam

13. **N5 — só a comparação de `provider_id` estava testada no cruzamento.** Curado: casos (l14) papel e (l15) pessoa,
    mutante M28.
14. **N3 — o cruzamento guardava só o 1º evento de cada id do provedor.** Curado: com o mesmo id em dois lugares, vale o
    evento do lugar da resposta; o caso (a) leva esse fluxo, mutante M29.
15. **N1 — telefone escrito com `:` ou `/` ou com traço tipográfico passa** (a retirada de horas e datas abre o desvio).
    Limite declarado no README.
16. **N2 — lista de números curtos no texto pode reprovar como VAZAMENTO.** Limite declarado no README.
17. **N4 — `piece:messaging/…` não diz qual repo é a quem lê a declaração.** Limite: o repo da peça é privado (REGRA 36
    (Superfície VENDORIZADA sem nome comercial de cliente) e REGRA 121 (Grafo novo ou tocado não cita repositório não
    conferível por terceiro)); a ligação fica no grafo do core.

## Mutantes

29 mutantes plantados no próprio juiz (`conformance.py` e `message.schema.json`) por `ops/mutate-and-restore.sh`, com
`LC_ALL=C`: **29 mortos, 0 sobreviventes**, e cada um morto pelo caso que o nomeia (conferido no log de cada um):
M01 schema sem `provider_message_id` → (b); M02 `resolved_by` livre → (c) e (d); M03 schema sem `audience` → (e);
M04 dedupe desligada → (f); M05 quem pede fora da audiência → (g); M06 veredito da guarda ignorado → (h); M07
telefone com um separador só → (l2); M08 data contada como número → (a); M09 audiência depois da resposta → (j);
M10 «serviu?» → (k); M11 resposta órfã → (l); M12 e M13 latência no evento e na resposta → (l3) e (l4); M14 retenção
→ (l5); M15 papel sem pessoa → (l6); M16 kind desconhecido → (l7); M17 data impossível → (l8); M18 a M21 cruzamento
com a mensagem respondida (lugar, fio, em nome de quem, horas) → (l9) a (l12); M22 não é JSON → (l13); M23 lista
vazia → (o); M24 a M26 declaração (ausente, requisito, sem fonte) → (n); M27 `--strict` → (m); M28 cruzamento só por `provider_id` → (l14) e (l15); M29 resposta casada com o 1º evento do id, sem olhar o lugar → (a).

Equivalente declarado (não plantado): tirar o `if not raw.strip()` do arquivo vazio cai no «nenhuma mensagem», que
também é rc 2; o comportamento é o mesmo.

## Limites declarados

- O juiz confere forma e regras que cruzam campos; não sabe se o id do provedor é verdadeiro, se a identidade resolvida
  é a pessoa certa, nem se a guarda de vazamento da peça funciona. Isso é da bancada da peça.
- A declaração do WAHA foi medida por LEITURA do código da peça (a origin/main de 2026-11-22); nada rodou contra o WAHA.
- O adapter WAHA fica com `none:` no `enforcement.tsv` (passivo SOFT da REGRA 107 sobe de 7 para 8 de 19): o
  executável roda fora do core; gatilho declarado.
- A origem do contrato (`E_CHAT_ORIGIN_MAESTRO_ASK_1121`) tem fonte fora do git deste repo; o lugar do pedido (o canal
  com os sócios) vem do brief, não foi medido.
- Mutantes rodados com a família extraída do `lint-selftest.sh` num harness mínimo (mesmo código da função, sem o
  resto da bancada), por causa da carga da máquina; a bancada completa roda no pr-finalize e no CI.
