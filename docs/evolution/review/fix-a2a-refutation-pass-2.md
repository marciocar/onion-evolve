---
branch: fix/a2a-refutation-pass-2
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: pendente
findings_total: 8
findings_real: 8
tokens: 149861
duration_min: 10
findings_fixed: 7
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "subagente general-purpose, opus, mandato de refutar"
nota: "1 bloqueante, 3 graves e 4 menores; o bloqueante foi curado em parte e o resto depende do N2 (decisão OPEN do maestro); o menor 6 (falso negativo de borda) ficou declarado, sem cura. O bridge teve refutador próprio (1 grave e 2 menores, todos curados), no PR marciocar/onion-bridge#71"
---

# Passada adversarial: `fix/a2a-refutation-pass-2`

## O que muda

Cura da 2ª passada de refutação do A2A (SAC-150), lado do core:

- **N1:** o `a2a-accept.sh` reverifica o envelope preservado pelo gate (`a2a-verify.sh --reverify-at <receivedAt>`), confere o registro contra o envelope e monta o frontmatter do veredito reverificado.
- **N3:** o corpo entra no doc do inbox como DADO, dentro da moldura R15.2.
- **N4:** o `from` tem forma fechada antes do trust-check, e o veto entra no trust-log rotulado como declarado.
- **N5:** o kid revogado derruba a reverificação, e o convite revogado ou vencido é conferido com `--invites`.
- **N6:** o doc tem o nome do jti assinado, há razão de aceites, e colisão é erro.
- **N7 e N8:** teto de corpo de 8192 bytes no gate; MAX_TTL e skew com teto duro; a medição do relógio vence o atestado.
- **N10:** prosa corrigida.
- **N2:** medido e proposto como decisão OPEN no grafo.

## Achados

O refutador do core encontrou oito achados. Cada um com a cura e o caso de bancada que o cobre:

1. **Bloqueante — envelope genuíno ressuscita.** Como o `receivedAt` não é assinado, um envelope genuíno pode ser reapresentado. **Curado em parte:**
   - o aceite recusa envelope com `iat` assinado de mais de 7 dias, e o env só aperta essa idade;
   - um razão de aceites por jti no repo de quem aceita impede o mesmo jti de entrar duas vezes;
   - a testemunha do recebimento fora do UID do serviço depende de `D_N2_SEPARAR_A_ESCRITA_DO_CHAT_DA_CONFIANCA_DO_A2A`.

   Casos: "envelope assinado há 8 dias…", "doc apagado do inbox…", "mesmo envelope, outro taskId, OUTRO inbox".
2. **Grave — o dedupe por grep casava o corpo.** Agora o dedupe é pelo nome (o sha do jti) mais o razão, e o taskId é lido só do frontmatter. Caso: "corpo com 'jti_sha256:'… não suprime o outro".
3. **Grave — o `--invites` ignorava a validade.** Agora o convite vencido ou com validade ilegível é recusado, pela régua ISO do guard. Casos: "convite vencido", "validade ilegível".
4. **Grave — o trust-log perdia as tentativas bloqueadas.** O veto agora grava uma linha com o `from` rotulado "(declarado, não provado)", e só se o from passou na forma. A falha de gravação avisa no stderr, em vez do `|| true`. Casos: "assinatura ruim → a tentativa entra… ROTULADO", "from fora da forma → veto sem linha".
5. **Menor — caracteres bidi e de largura zero passavam.** A categoria Unicode `Cf` agora também é trocada por U+FFFD. Caso: "bidi U+202E e largura zero…".
6. **Menor — falso negativo de borda.** Um envelope que expira 1 a 2 s depois do recebimento pode ser vetado na reverificação. Não é brecha, e fica **declarado, sem cura**.
7. **Menor — `chronyc` com leap pendente contava como dessincronizado.** Agora `Normal`, `Insert second` e `Delete second` contam como sincronizado, e só `Not synchronised` vence o atestado, no gate e no doctor. Casos: os dois do `chronyc` stub.
8. **Menor — corrida e symlink na escrita.** A escrita agora é exclusiva (`set -C` = O_EXCL).

**O que resistiu ao refutador:**
- injeção no frontmatter e no título;
- quebra da cerca e da moldura;
- registro adulterado;
- `--reverify-at` alcançável de fora (o bridge chama o gate com argv fixo);
- env afrouxando o gate no aceite;
- ferramenta ausente;
- paridade do relógio entre gate e doctor.

## Mutantes

Plantados por `ops/mutate-and-restore.sh`, com `bash -n` antes. Mutante com erro de sintaxe é marcado QUEBRADO e não conta.

- **1ª rodada: 25 de 25 mortos.**
  - O mutante `ver-from-tipo` sobreviveu: a checagem de tipo do from era redundante com a forma fechada. A checagem **saiu do código**.
  - O log do `acc-sem-envelope` se perdeu (o diretório de logs foi apagado por outro agente). Rodado de novo: morto.
- **2ª rodada (curas do refutador): 7 de 8 mortos e 1 quebrado.** O quebrado foi `acc-taskid-por-grep`, por erro de sintaxe do próprio mutante, e não conta.
- **Bancada inteira (`--jobs auto`): 3570 passaram e 3 falharam, nenhuma por este diff:**
  - `rule-title-in-prose` (2 falhas): a cauda é medida em ms e falhou sob carga. Isolada, deu 6/6.
  - `backlog-projection: em-dia`: os nós abertos novos pedem a projeção regenerada, que é passo do pr-finalize.

## Limites declarados

- **A prova do caso que reprovava hoje.** O caso (4b) é a injeção de YAML num registro forjado sem envelope. Contra o `a2a-accept.sh` de `origin/main`, ele sai rc 0 com as chaves injetadas, medido. Contra o novo, sai recusado.
- **A8 e A8g.** Rodou só o caminho de produção em sandbox: 7 variantes, 1 réplica headless cada.
  - 0 canário vazado e 0 escrita.
  - 1 tentativa de Bash no A8c, negada pelo modo default.
  - Não rodou o A8 pré-registrado (canal, interativo, 5 réplicas, maestro presente), nem o A8e e o A8g3.
- **A fila de produção.** Os 2 registros que estão nela hoje (de antes de 2026-10-14, sem `body_sha256`) são recusados pela reverificação, medido numa cópia lida com `sudo -n`. Arquivá-los é do maestro.
- **A poda do estado de jti** virou `Q_ESTADO_DE_JTI_SO_CRESCE`, com gatilho.
- **Ordem de merge.** O manual e o `a2a-live.md` descrevem o bridge do PR marciocar/onion-bridge#71. Este PR deve ser mergeado **depois** do merge e do deploy dele, embora o código do core não dependa dele.
