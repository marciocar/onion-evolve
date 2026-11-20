# «Pode rodar» — autorização de um toque

A doutrina da autorização que o maestro dá no prompt da sessão. A v1 cobre **só o merge** e é **nível 1**.
Decisão de 18/11/2026, com a ressalva dele: «Opção 1 para começar, mas isso pode virar até 2fa no futuro; eu tenho
que poder rodar as coisas e me identificar se o nível de segurança exigir». Por isso todo ato carrega um **nível**.

## O fluxo (o maestro só digita a frase)

1. A sessão prepara o ato. O executor roda **todos** os gates dele (CI verde no head, ponta da base, rascunho,
   catraca do repo próprio) e só então grava o **pedido** canônico em
   `${XDG_STATE_HOME:-~/.local/state}/onion/approvals/requests/<session>.json`. Ele mostra **uma linha**:
   `⏸ merge <repo>#<PR> @<sha curto> (<branch>) — responda: pode rodar`.
2. O maestro digita `pode rodar` no prompt **daquela** sessão. O hook `UserPromptSubmit`
   (`.claude/hooks/userprompt-one-touch-approval.sh`) grava a **aprovação**: o hash do pedido, 10 minutos contados
   **a partir da palavra** e uso único. O hook devolve à sessão uma linha com o comando a rodar.
3. A sessão roda o ato. O **executor** confere a autorização contra o estado atual e grava o uso no **livro dele**
   antes do merge.

A recusa sempre cabe em uma linha e diz o que fazer.

## Quem autoriza: medido, não suposto (18/11/2026)

| sinal | prompt digitado pelo humano | mensagem de outra sessão (peer) |
|---|---|---|
| `origin.kind` no transcript | `human` | `peer` (com `from: uds:…`) |
| `promptSource` | `typed` (ou `queued`, digitado com a sessão ocupada) | `system` |
| `isMeta` | ausente | `true` |
| corpo | o texto | moldura `<cross-session-message …>` |

Também chegam como `user` as `task-notification` (`origin.kind: task-notification`, `promptSource: system`) e as
sugestões aceitas (`promptSource: suggestion_accepted`). **Nenhuma das duas autoriza**: sugestão é texto que o modelo
propôs.

O payload do hook (2.1.327, medido num diretório temporário) traz `session_id`, `transcript_path`, `cwd`,
`prompt_id`, `permission_mode`, `hook_event_name` e `prompt`, e **não traz a origem**. O hook dispara também para a
mensagem de peer e para a notificação de tarefa. O harness grava a entrada do prompt no transcript **depois** do hook:
na 1ª mensagem de uma sessão, o arquivo nem existe quando o hook roda. Daí a divisão:

- o **hook** confere o texto: a frase é o prompt inteiro (sem contar espaços nas pontas, caixa e um ponto ou
  exclamação final), sem moldura de outra sessão ou de sistema. Mensagem fora disso não autoriza, e ele diz por quê.
  Quando registra, a linha dele é condicional («vale se o maestro DIGITOU a frase»), porque a origem ele não vê;
- o **executor** confere a origem: entre as entradas do `prompt_id` no transcript, julga a que traz a frase (a
  auto-compactação disparada no envio grava o resumo com o mesmo `promptId`, antes) e exige `origin.kind: human`,
  `promptSource` `typed` ou `queued` e nenhum `isMeta`. O prazo de 10 minutos conta do horário dessa entrada.
- **no meio do turno** (medido em 20/11/2026, SAC-485, prompt_id `d82f5d09` e `81ad8498`): quando o maestro digita
  com a sessão trabalhando, o hook recebe o `prompt_id` **do turno em curso**, e a mensagem entra no transcript como
  `type: attachment` com `attachment.type: queued_command`, **sem** `promptId`: a frase em `attachment.prompt`, a
  origem em `attachment.origin` (`human` traz `commandMode: prompt` e `humanTurn: true`; peer traz `origin.kind: peer`
  e `isMeta`). O executor aceita essa forma só se ela está **dentro** do turno do `prompt_id` (o último `promptId` visto
  antes dela é o do payload), nasceu a até 30 s da gravação da aprovação, tem `humanTurn: true`, `commandMode: prompt`,
  `origin.kind: human`, nenhum `isMeta` e, se trouxer `promptSource`, ele é `typed` ou `queued`. Antes da cura o leitor
  só via a forma de topo e recusava («a frase … não está no transcript»);
- o **livro do executor** guarda o hash da aprovação **e** o id da palavra (o `prompt_id` no topo; `prompt_id/uuid` da
  mensagem no meio do turno): regravar a aprovação para a mesma palavra gera hash novo, mas não um segundo uso, e duas
  palavras no mesmo turno são duas palavras.

Falha **fechada** nos dois: o que não dá para ler não autoriza.

## O esquema de ato (compartilhado)

[`act-request.schema.json`](act-request.schema.json) define o **pedido** (`onion.act-request/1`) e a **aprovação**
(`onion.act-approval/1`). O hash é sha256 do JSON canônico: chaves ordenadas, sem espaços e em UTF-8, no estilo JCS,
calculado sem o campo `hash`. Ele cobre o alvo (repo, ref completo, sha e PR), o nível, os `approvals_required`, quem
pediu, o horário e o `nonce`. O hash da aprovação cobre `expires_at`, os aprovadores e o seu próprio `nonce`.

- `approvals_required: [{role, scope: content|execution, min_level}]`. O **dono da área** aprova o conteúdo, o «o
  quê». O **maestro** aprova a execução, o «como», quando o ato toca produção, segurança ou credencial. Há ato que pede
  os dois.
- Cada aprovação recebida guarda `{role, approver_id, channel, level, at}`. Os canais são `prompt` (nível 1),
  `slack-signed` (nível 2) e `passkey` (nível 3).
- **A v1 implementa só `role: maestro`, `scope: execution` e `channel: prompt`.** Qualquer outra combinação está
  declarada no esquema e é recusada com mensagem clara.

O esquema serve também aos atos da vps-ops (`tools/acts/<ato>.sh`: um comando e um log). O log desta peça segue o
mesmo formato: `<estado>/acts/approval-<evento>-<UTC>.log`, cuja última linha é `✓ RESULTADO …` ou `✗ RESULTADO …`.
`<estado>/usage.tsv` mede a experiência: ato, nível e segundos entre o pedido e a palavra.

- `effect: read|write|external` diz o que o ato faz. **Leitura pura nunca pede aprovação.** O merge é `external`.
- **Aprovação por plano** (declarada, fora da v1): aprovar passo a passo é «terrível», mediu o hub. Um pedido `act:
  plan` traz N passos, cada um com o efeito em linguagem simples, mais o escopo (a tarefa) e o prazo (ex.: 30 min). Um
  único «pode rodar» vale para o lote, e cada passo executado ainda confere o hash dele contra o plano. O motor de hoje
  recusa `plan` com mensagem clara.

### Restrições do esquema (alinhadas com os atos da vps-ops)

- O hash cobre o **conteúdo** do executor (`executor.script_sha256`) e os argumentos (`executor.args`), não só o nome
  do ato. O executor recalcula o sha256 do próprio script na conferência e recusa se ele mudou desde o pedido.
- O alvo é **neutro**: sem hostname, IP ou caminho de máquina.
- **Segredo nunca** entra em argumento, log ou hash.
- O log fica **fora do repo**, em diretório modo 700.
- Ato que pede TTY (a senha do GPG, por exemplo) declara `requires_tty: true` e **nunca** é autorizável por palavra.
  O motor recusa esse pedido, e o ato fica para o maestro rodar no terminal dele.
- **Defesa contra lavagem de permissão:** a palavra só vale quando o maestro a digita na **própria** sessão que pediu.
  Repasse de peer nunca conta, nem quando a outra sessão diz que o maestro autorizou lá. Cada sessão pede a sua
  palavra.

## Limites da v1

- Vale para merge de repo da lista fechada (o core e quem declara `owner_session` no `members.yaml`), inclusive o PR
  que toca a própria catraca, que antes só saía com `--maestro`. A autorização **substitui o `--maestro` só nisso**:
  não dispensa check, não declara CI inoperante e não abre repo alheio.
- Repo de **outro dono** (cliente) segue recusado **sempre**, mesmo com autorização viva.
- A palavra vale só para o merge do **repo da própria sessão**: com ela, o core não mergeia repo de outra sessão (o
  `--foreign-repo` é recusado junto). Repo com sessão própria viva tem o PR e o merge feitos por ela; o core só avisa.
- Com autorização viva **não há auto-rebase**. Se o PR precisar de rebase, ou se o sha mudar, a autorização é gasta e
  o executor recusa: «o sha mudou: peça de novo depois do verde». A palavra vale para o ato final (o merge do sha X),
  não para a sequência.
- Deploy, firewall, segredo e publicação externa ficam **fora** da v1.
- O corpo da aprovação nunca passa pela campainha (doorbell). Se um dia algo passar por lá, será só um ponteiro.

## Honestidade: conformidade, não fronteira de segurança

No mesmo usuário Unix, o agente **pode forjar** o arquivo de aprovação, o livro e até o transcript. A camada impede a
sessão de se **autoautorizar por engano**, ou por mensagem de outra sessão. Ela **não** impede um agente hostil.

Não usamos o `ask` de hook: há relatos de que ele é aprovado sozinho em `bypassPermissions`, que é o modo das sessões
da casa. O veto `exit 2` do `--maestro` segue intacto. A autorização entra por outra porta, mais estreita.

## Pontos de extensão

- **Nível 2, fora da banda:** uma identidade que o agente não controla. O transporte declarado é a
  **ponte de mensageria da família**: DM no Slack pela ponte, com o portão por identidade da ponte verificando a assinatura,
  ou WhatsApp no celular do maestro. O mercado indica o mesmo caminho: review no forge por uma conta humana enquanto os
  agentes usam identidade própria (bot ou GitHub App); step-up de autenticação (RFC 9470); aprovação desacoplada no
  dispositivo do usuário (OpenID CIBA); NIST SP 800-63-4, AAL2. Entra **só onde o risco do ato pedir**.
- **Nível 3:** passkey ou 2FA (NIST SP 800-63-4, AAL3).

O canal novo entra em `IMPLEMENTED` e `ACT_POLICY` no [`one_touch.py`](one_touch.py), com a verificação dele, e
nunca por fora do motor.
