---
branch: feat/decide-panel-kit
pr: pendente
date: 2026-11-26
reviewed_diff_sha256: pendente
reviewed_code_sha256: pendente
findings_total: 10
findings_real: 10
findings_blocking: 0
tokens: 0
duration_min: 0
findings_fixed: 10
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "revisor isolado (general-purpose, opus, sem ver o raciocínio da forja, mandato refutar), 3 rodadas. Rodada 1: sem bloqueio, 2 importantes (card do ato fora do round_id; rodada anterior ao kit deixava de selar) e 6 menores, curados. Rodada 2: FIXES_NEEDED, a contagem de abertos da página ainda erra (o envio decidia antes do estado) e o custo numérico passou a ser recusado; curados, com a contagem sob a bancada (pn6). Rodada 3: APPROVE."
nota: "tokens e duration_min = 0: não medidos aqui. Insumo do hub (sinal 2026-11-26-signal-review-page-kit e o pacote no checkout do hub) lido como dado; nada do gerador do hub foi executado nem copiado."
---

# Passada adversarial: `feat/decide-panel-kit`

## O que muda

O modo `/meta:decide --painel` absorve o kit de página de revisão do hub (tarefa #22): o hub mediu 111 respostas em
duas noites com decisor não técnico.

- **`decide-panel.sh`**: `cite_id` estável; `kind: verify` (Confere sela pelo `kg-decide-seal.sh` com destino
  design; Ainda não não sela e devolve a nota); `resolved_by` (recolhido, não é pergunta, não conta no teto);
  bloco `view` de apresentação (explicação, por quê, prints PNG/JPEG/WebP até 96 KiB embutidos ou `/_blob/` do
  asset store, `annotate`, link de envio https com prazo e sem query, `source_url`); `panel_only` (até 6 opções;
  o `--ask` recusa nomeando a pergunta acima de 4); recusa de `[A CONFIRMAR]`; teto de 240 KiB do round (o
  documento do db tem 256 KiB). O `round_id` cobre o que sela ou vira ato (pergunta, opções, selo, classe, card e
  origem do ato, data, nonce); fica fora só a apresentação (cabeçalho, `cite_id`, `view`). O seal aceita também o
  hash legado (a pergunta inteira), com condição de remoção declarada.
- **`decide-panel.html`**: id citável, prints, marcação no print pelo marker.js 2 (`markerjs2@2.32.7` do
  jsdelivr com SRI; Linkware, o link de volta fica), link de envio, `verify` com nota, bloco «Já resolvido pelas
  suas regras», contador só dos abertos e «Pendências limpas». A anotação e a nota vão ao db como dado.
- **Doutrina** (cláusula 9) e **`decide.md`**: as três decisões do core e os tipos novos.
- **Bancada**: pn5 (kit, 10 mutantes) e pn6 (contagem da página no node, 1 mutante); `_pn_forge` recalcula o hash
  como o script.

Decisões do core aplicadas: (1) a sugestão é a 1ª opção com «(Recomendado)»; (2) o `round_id` cobre só o que sela;
(3) só-painel até 6 opções, `--ask` com teto 4 e recusa nomeada.

## Achados

| id | achado | cura | caso / mutante |
|---|---|---|---|
| 1 (importante) | o hash deixou o `card`/`actor` do ato de fora: trocar o comando do "executar" no round local passava | `actor`, `card` e `origin` voltam ao hash | pn5 `card-do-ato-trocado`, MUT hash-sem-card |
| 2 (importante) | rodada emitida antes do kit deixava de selar no merge | seal aceita o hash legado (cobre mais); remoção após 2026-12-26 | pn5 `rodada-legada`, MUT sem-legado |
| 3 | `[A CONFIRMAR]` escapava no custo, com invisível ou hífen | custo passa pelo `clean`; invisíveis tirados; regex `[\s_-]*` | pn5 c-dcost, c-dzw, c-dhy |
| 4 | «Pendências limpas» com item em «não confere» (rodada 1: FINAL; rodada 2: o envio decidia antes do estado) | `openCount` isolada, estado antes do envio; chip «não confere» | pn6, MUT envio-antes-do-estado |
| 5 | anotar imagem https de outra origem contamina o canvas | `annotate` exige 1ª imagem `data:` ou `/_blob/` | pn5 c-anhttps |
| 6 | resolvido carregava imagens que a página não mostra; mensagem de erro do envio enganava; teto da marcação em UTF-16 | resolvido só texto; mensagem cobre o teto; teto em bytes | pn5 c-resg |
| 7 | `expires` impossível aceito; `source_url` com query | `date.fromisoformat`; mesma regra sem query | pn5 c-date, c-srcq |
| 8 | resolvido aceitava campo de pergunta em silêncio; `--ask` vazio rc 0; capabilities divergentes | recusa nomeada; `--ask` sem pergunta rc 2; comentário com `assets` | pn5 c-resg |
| 9 | custo numérico passou a derrubar a rodada (regressão da cura 3) | `str()` antes do `clean` | dogfood |
| 10 | nenhum caso cobria a contagem da página | pn6 roda o trecho no node | pn6 |

Tentado e não refutado (revisor): divergência entre a função do round e a do seal (idênticas), recomendada em 1º,
teto de opções, verify, resolvido, symlink e traversal de imagem, poliglota PNG+script (vira `data:image/png` em
`<img>`, inerte), XSS na página (tudo por `textContent`, `href`/`src` só https ou `data:` de imagem), SRI do marker.js,
o painel nunca escreve no grafo, e a brecha do hash legado (quem edita o round local já recalculava qualquer hash).

## Rodada 3

**APPROVE** sobre da9c72839. A contagem roda no node com `2 0 3`; o mutante da bancada dá `0 0 3`, e três mutantes
do revisor (FINAL antigo, enviado sem estado aberto, estado ignorando o round_id) também reprovam pela saída. Sem o
marcador do trecho a pn6 reprova. Custo `5` e `0` aceitos, `[A CONFIRMAR]` no custo segue recusado. Nits sem ação:
custo booleano ou objeto vira texto (o custo nunca vira argumento do selador).

## Fora deste PR (declarado)

- `history/<cite_id>` e `feedback/<cite_id>` (respostas e sinal de retreino entre rodadas) — ordem 2 e 3 do mapa
  do hub; o `cite_id` já viaja na resposta.
- Fila longa: o teto de 4 perguntas por rodada continua também no só-painel (só o de opções subiu).
- Imagens empilhadas numa só e conversão para WebP (o gerador do hub usa Pillow).
- Criar o link de envio (File Request) pelo `ops/gokapi-upload.sh`: o script de hoje só sobe arquivo para download;
  o link de envio é criado fora e só exibido.
- Conversor da fila do hub (`fila.schema.json`, chaves em português) para a composição do core.

## Dogfood

Fila de exemplo do hub recomposta (DEMO-P01 decisão com 6 opções, DEMO-S01 tela com print anotável e link de envio,
DEMO-C01 correção, DEMO-P02 resolvido) num repo descartável: `round` rc 0 (29 KiB), `--ask` rc 2 nomeando
`Q_DEMO_P01 (6)`, `seal` com o selador de produção selou os três nós e o radar aceitou; troca de print no round não
invalidou a resposta; «Ainda não» saiu «não confere» com a nota. A página renderizada no Chromium headless a 390 px
mostrou cites, prints, link com prazo, verify, «3 em aberto» e, com tudo selado, «Pendências limpas».
