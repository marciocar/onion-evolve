---
date: 2026-10-30
instance: onion-evolve
type: learning
classification: collective
tags: [ssh, reverse-tunnel, device-access, declarado-vs-verificado, consentimento]
affects: [engineering, meta]
breadcrumb_for: []
share_with: []
next_recommended: "Para operar a shell de um dispositivo pessoal (Termux no Android) a partir da VPS: túnel SSH reverso aberto PELO dispositivo, chave do dispositivo restrita na VPS (restrict,port-forwarding,permitlisten=\"localhost:8022\" + command que só ecoa), sim explícito do maestro antes de qualquer gravação em qualquer dos dois lados, todo uso por um wrapper que confere o túnel e registra data/comando/rc num log privado append-only. O status do túnel se mede com conexão real (ssh ... true com timeout), nunca por porta em LISTEN."
review_after: 2026-11-30
conflict_class: dynamic
valid_when: "o acesso ao dispositivo segue por túnel SSH reverso iniciado pelo próprio dispositivo, com o sshd do Termux na porta 8022"
significance: "A porta 8022 aparecia em LISTEN com o túnel morto: o status passou a abrir uma conexão de verdade e a separar VIVO, MORTO e FECHADO, e o registro de uso virou wrapper em vez de memória."
---

## Signal
**Shell de dispositivo pessoal pela VPS = túnel reverso que o dono abre e fecha; o status se mede por conexão real.**
Porta escutando na VPS não prova túnel vivo: o sshd segura a porta numa sessão órfã quando a rede do
celular cai. Todo uso passa por um wrapper que confere o túnel e grava o registro, e nenhuma gravação,
na VPS ou no dispositivo, acontece sem um "sim" explícito do maestro.

## Evidence
- **O desenho do acesso.** O Termux no Android roda `sshd` na porta 8022. O celular do maestro abre um
  túnel SSH reverso para a VPS, e a sessão entra por `localhost:8022`. Na VPS, a chave do celular é
  restrita: `restrict,port-forwarding,permitlisten="localhost:8022"`, com um `command` que só ecoa e
  não dá shell. Na direção contrária, a chave da VPS fica no `authorized_keys` do Termux. O controle
  de acesso é a existência do túnel: o maestro o abre e o fecha, e nada fica permanente.
- **Consentimento antes da escrita.** O maestro deu um "sim" explícito antes de qualquer gravação na
  VPS. Isso faz parte do padrão, nos dois lados, não foi cortesia daquela vez.
- **Origem do Termux.** `termux-info | grep APK_RELEASE` diz de onde veio o app (`F_DROID`, `GITHUB`
  ou `GOOGLE_PLAY_STORE`). Existe uma versão nova na Play Store (`googleplay.AAAA.MM.DD`), mantida pela
  equipe do Termux. O conselho "só F-Droid, a da Play é quebrada" estava defasado e veio de memória
  antiga, sem verificação. O Termux:API tem de vir da mesma loja que o Termux.
- **Porta escutando não é túnel vivo.** Quando a rede do Android caiu (troca de wi-fi para 4G, economia
  de bateria), o sshd da VPS segurou a 8022 numa sessão órfã sem tty. O `ss -ltn` mostrava LISTEN, mas
  a conexão dava timeout no banner, e uma reconexão com `ExitOnForwardFailure=yes` falharia porque a
  porta continuava presa. A cura teve três partes. O status passou a testar uma conexão real
  (`ssh ... true` com timeout) e a distinguir VIVO, MORTO e FECHADO. A sessão órfã foi encerrada. A
  resiliência veio de `ServerAliveInterval=30`, de um laço de reconexão no celular, de
  `termux-wake-lock` e de tirar o Termux da otimização de bateria. Tudo isso é do lado do cliente: o
  `ServerAliveInterval` faz o celular perceber a queda, mas quem segura a porta é o sshd da VPS, e
  nesta rodada a sessão órfã foi encerrada à mão.
- **Registro por mecanismo, não por memória.** Todo uso passa por um wrapper que confere o túnel e anexa
  data, comando e rc num log privado e append-only. O runbook (abrir, usar, revogar, restaurar) fica
  fora deste repo público, e a memória privada da sessão aponta para ele.
- **Atrito de card.** O maestro colou no Termux a linha de `authorized_keys` que era para gravar na
  VPS, e o shell respondeu "command not found". O card misturava comando a rodar no dispositivo com
  texto a gravar do outro lado.
- **Antes de criar chave nova.** O maestro achava que já tinha uma chave do celular cadastrada.
  Conferidos os fingerprints (`ssh-keygen -lf`) das chaves existentes, nenhuma era a do Termux.

## Next crumb
- Card de acesso a dispositivo separa em blocos distintos o que **roda no dispositivo** e o que é
  **texto para gravar do outro lado**, cada um rotulado com o lugar.
- Avaliar `ClientAliveInterval`/`ClientAliveCountMax` no sshd da VPS (ou num `Match` para a chave do
  dispositivo), para o servidor soltar sozinho a porta da sessão órfã. Sem isso, a reconexão com
  `ExitOnForwardFailure=yes` segue dependendo de encerrar a órfã à mão.
- Antes de gerar chave, listar os fingerprints das já cadastradas (`ssh-keygen -lf`) e comparar.
- Corrigir a memória privada que ainda diz "Termux só pelo F-Droid": verificar a loja com
  `termux-info` antes de aconselhar.
- No re-teste (`dynamic`): rodar o status do túnel com a rede do celular derrubada de propósito e
  conferir que ele diz MORTO, não VIVO.
