---
title: 'Resíduo — o carteiro entrega pelo spool quando o sandbox do remetente barra o inbox do destino (F7)'
date: 2026-11-07
branch: fix/co-relay-sandbox-spool
reviewed_diff_sha256: pendente
findings_total: 6
findings_real: 2
findings_blocking: 1
findings_fixed: 2
tokens: 0
duration_min: 20
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Passada adversarial feita pelo próprio agente de execução, sem refutador independente: o brief proibia
  lançar subagentes. Ela rodou o artefato como o runner o invoca (o co-relay.sh dentro do sandbox real do
  Claude Code 2.1.319, e o hook SessionStart no destino) e passou o diff linha a linha procurando modo de
  falha (tokens: 0 = não medido; a passada correu dentro da sessão, sem contador próprio). Achou 6 itens: 2 defeitos reais, curados (1 bloqueante), 1 conferência sem defeito e 3 limites declarados.
---

# O inbox do core em leitura era o deny da curadoria, não a ordem de repo pai e filho

## Causa medida do F7

Em fixture (`/tmp`, dois repos git, `claude -p --settings` com sandbox mínimo, escrita em cada alvo e
`/proc/self/mountinfo` lidos de dentro do sandbox):

- só com o `inbox/` do destino no `allowWrite`, a escrita **passa**. Um repo pai não cobre o filho por ser pai;
- com `Edit(//<destino>/**)` no `permissions.deny` (a forma do deny v4 da curadoria), a escrita dá
  `Read-only file system`. No mountinfo, o `inbox/` aparece rw e, **depois** dele, o destino inteiro ro;
- com um `permissions.allow` `Edit(...inbox/**)` somado, o resultado é o mesmo.

A hipótese de ordem de montagem se confirma, e o gatilho é o deny da curadoria. O co-relay da main, no
mesmo sandbox, dizia `AVISO: falha ao copiar` e saía **0** com 0 entregues.

## O que entrou

- `co-relay.sh`: quando o `inbox/` do destino não aceita escrita daqui (`[ -w ]` lê o EROFS do bind), ou
  com `--spool`, o carteiro grava em `${ONION_SPOOL_DIR:-~/.local/state/onion-spool}/<slug-do-destino>/`.
  Antes disso passam as **mesmas** guardas e o mesmo dedup. A escrita usa tmp + rename, e a falha de escrita
  sai rc 1.
- `spool-import.sh`: no destino, move o sinal para o `inbox/` dele, untracked. Se o `inbox/` já tem um
  homônimo byte-idêntico, só apaga a cópia do spool. Um homônimo untracked diferente é substituído. Um
  homônimo **commitado** fica no spool e conta como pendente.
- Hook `co-evolution-inbox-check.sh`: importa antes de contar e avisa 📮 o que ficou retido.
- `/meta:co-relay` e `/meta:co-evolve`: o porquê e o `allowWrite` a usar.
- Bancada `corelay_spool`: 10 casos, sendo 3 mutantes que mordem (sem o canal, sem o rc da falha, sem a
  importação no hook).
- Nó `E_CS_F7_SPOOL_DO_CARTEIRO_1107` no grafo da comunicação estável.

## Por que spool, e não a fila do onion-messaging (degrau 3)

A fila existe e tem bancada, mas o teste ao vivo dela ainda espera três atos do maestro: os pares de
chave, a decisão sobre o receptor standalone e os daemons subidos. Ela também não está vendorizada no core.
O spool é um diretório e um `mv`, sem daemon nem chave. Ele reaproveita todas as guardas que o carteiro já
tem e se desfaz sozinho quando a fila assumir. É a menor peça que funciona hoje.

## Achados

1. **Real, bloqueante, curado.** O carteiro saía 0 quando a cópia falhava, e o F7 só apareceu porque
   alguém leu a saída. Agora sai rc 1. Caso (S2) e mutante (S-M2).
2. **Real, curado.** O 1º desenho fazia `chmod 700` no spool raiz e tratava falha do chmod como erro. Isso
   recusaria um `ONION_SPOOL_DIR` que já existe e é de outro dono, e o chmod de volta desfaria um spool que
   o dono deixou só para leitura. O caso (S3) acusou o segundo ponto. Agora o modo 0700 vale só para o que o
   carteiro cria.
3. **Conferido, sem defeito.** Uma escrita direta no spool deixaria o importador ler um sinal pela metade,
   se as duas sessões rodassem ao mesmo tempo. O `_put` já nasceu com tmp + rename, e o importador ignora
   `.*` (caso I2).
4. **Limite declarado.** O portão de destino público confere o dedup contra o `inbox/` e o `_processed/`,
   não contra o spool. Um reenvio idêntico que ainda está no spool pede `--confirm-public` de novo. É uma
   confirmação a mais, sem vazamento.
5. **Limite declarado.** O slug vem do caminho físico do destino. Uma sessão do core aberta num worktree
   tem outro slug e não importa nada, e o sinal espera a sessão do checkout principal, que é o `--target`
   usado na prática.
6. **Limite declarado.** Quem escreve no spool sem passar pelo carteiro pula as guardas do remetente. É o
   mesmo limite de quem copia direto no `inbox/`, e a REGRA 113 (Sinal relayado a destino público só se
   commita revisado) segue valendo só para o que o carteiro marcou.

## Dogfood

- Com o sandbox real (perfil igual ao da curadoria: deny `Edit` do destino, spool no `allowWrite`), o
  co-relay do branch entregou no spool com rc 0, e o hook do destino importou o sinal untracked e contou 📬.
- No mesmo sandbox, o co-relay da main saiu rc 0 com `0 relayado(s)`.
- `lint-selftest.sh --families corelay_spool,corelay,mail_hook,relay_public`: 89 passaram, 0 falharam. Na
  reexecução depois da cura do achado 2, `corelay_spool,corelay,mail_hook`: 60 passaram, 0 falharam.
