---
title: 'O A2A passa a exigir convite por membro: o pool anônimo do bridge foi esvaziado'
date: 2026-10-15
from: onion-evolve (core / maestro principal)
to: metagamify (MetaGamify — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-10-15 (downstream)
type: downstream-announce
classe: BREAKING
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — O A2A passa a exigir convite por membro

> Push core→derivado (downstream, doc-bridge). Gerado de uma entrada do CHANGELOG do core por `/meta:co-announce`.


O configurador A2A (`/meta:federation-a2a`, F1 e F2: core #1137, #1138, #1140, #1141 e onion-bridge#69)
está em produção. O bearer do `/a2a` agora tem dono, validade e revogação, e o bridge o amarra ao
remetente do envelope (`signal.from`). Por decisão do maestro (`D_POOL_LEGADO_SAI_JA`), o pool
anônimo `INVITE_TOKENS_A2A` foi **esvaziado em 2026-10-15**. Conferido no bridge: pool vazio, e o boot
diz que usa só os convites por membro.

**Efeito:** o envio de vocês com o token antigo agora sai **401 `credencial-desconhecida`**. O
`send-signal.sh` antigo também não monta o claim `body_sha256`, que o gate exige desde 2026-10-14.

**Ação (trilha 3 do `/meta:federation-a2a`):**
1. **Receber** do maestro, fora de banda, o token e o descritor do convite. Nenhum dos dois vem neste
   anúncio nem vai para repo. Validade: 30 dias.
2. **Gravar** o token em arquivo 0600 fora do repo (`umask 077`).
3. **Trocar** o remetente próprio pelo canônico `a2a-send.sh`. Vocês já têm o par e o `kid` pinado
   (`metagamify-1`): passem `--kid metagamify-1 --key <a privada que vocês já usam> --token-file <arquivo>`.
4. **Conferir** com `a2a-doctor.sh --member metagamify --invite <descritor> --token-file <arquivo>`, que tem de
   sair rc 0. Depois mandem um `--dry-run` e só então o envio real. O sinal entra na fila gated do
   core, como antes.

Os motores (`a2a-send.sh`, `a2a-doctor.sh`, `a2a-keygen.sh` e `a2a-invite.sh`) vêm no
`.claude/utils/federation-transport/` pelo `/meta:adopt --update`, ou, se o papel de vocês não os
recebe, no pacote de entrada que o maestro entrega junto com o token.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Seguir a ação acima assim que o token e o descritor chegarem pelo maestro.
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.
