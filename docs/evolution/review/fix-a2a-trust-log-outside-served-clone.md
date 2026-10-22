---
title: "Revisão — o trust-log do gate A2A ganha destino explícito fora do clone servido (A2A_TRUST_LOG)"
date: 2026-10-22
branch: fix/a2a-trust-log-outside-served-clone
reviewer: "subagente refutador de contexto limpo, com o diff e a lente do transporte A2A, medindo em sandbox (mktemp) e rodando a bancada"
reviewed_diff_sha256: 4d88b46d1f8b64a2a94393cf7f4e664694bd41967e30b40bd217ffb790720936
reviewed_code_sha256: 8f016bf52a6b7ba1bc1455e0ea9add3ff79226063abfb1144cf01e808d5c1a2a
findings_total: 5
findings_real: 5
verdict: APROVADO
tokens: 110044
duration_min: 8
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

O defeito: o bridge roda o `a2a-verify.sh` com o `--repo` no clone servido do core, e a trilha de
auditoria caía no `docs/evolution/trust-log.md` rastreado de lá. Cada `ops/update-bridge.sh` a prendia
num stash (medido pela sessão principal: 7 stashes, 16 eventos). A cura é a env `A2A_TRUST_LOG`, um
arquivo absoluto julgado fail-closed por um juiz só (`trust-topology-check.sh --check-log-dest`).

## Achados do refutador, e o que foi feito com cada um

1. **Limitava: symlink num componente do meio, ou ancestral 777 sem sticky, passavam pelo juiz.** O `-L`
   só olhava o arquivo e o diretório imediato. Provado: `$S/lnk/sub/log` deu `ok` e o relay gravou em
   `$S/real/sub/`. **Curado:** o diretório tem de ser o próprio caminho físico (`dir-path-has-symlink`), e
   cada ancestral tem de ser do dono ou do root, sem escrita de outros fora do sticky
   (`ancestor-not-owned`, `ancestor-writable-by-others`). O caminho do bridge em produção passa: o
   refutador mediu `/home/onion` 750, `onion-bridge` 755, `data` 755, todos da conta do serviço.
2. **Limitava: 7 dos 12 motivos não tinham caso nem mutante** (`dir-not-owned` entre eles). **Curado:**
   cada motivo do juiz tem caso e um mutante que apaga a linha dele (`control-char`, `not-normalized`,
   `dir-symlink`, `dir-path-has-symlink`, `dir-not-owned`, `ancestor-writable-by-others`, `not-regular`,
   `hardlinked`, `not-writable`), além dos cinco da 1ª forma.
3. **Limitava: um arquivo aceito e não gravável fazia um relay AUTORIZADO sair rc 1, o de bloqueado.**
   Pré-existente no caminho do repo. **Curado:** o juiz recusa `not-writable`, e a gravação no
   `log_attempt` sai exit 2 (configuração) se falhar, com caso e mutante no caminho sem env.
4. **Cosmético: hardlink e newline no caminho eram aceitos.** **Curado:** `hardlinked` (nlink ≠ 1) e
   `control-char`.
5. **Fora do diff: um caminho relativo passado pelo bridge vetaria todo o A2A.** **Conferido no PR do
   bridge:** o handler resolve o caminho absoluto, e a bancada de lá prova o absoluto com e sem a env.

## O que o refutador conferiu e estava certo

FIFO e diretório recusados; ACL com máscara aberta recusada; `--ensure-log` cria 0600 sob umask 022 e
preenche o cabeçalho de arquivo vazio; env vazia vale como ausente; sem a env a linha cai no repo como
antes; o veto do juiz não tenta gravar (o `FROM_SHAPED` ainda está vazio); os ramos novos não abortam
sob `set -euo pipefail`; os mutantes `if false`/`if true` de u24/u25 são fortes.

## NÃO MEDIDO

- A corrida (TOCTOU) entre o juiz e a escrita com dois usuários reais: a janela segue existindo, e o que
  a fecha é o diretório não aceitar escrita de outros (medido, e agora também nos ancestrais).
- O `stat -f` do BSD/macOS: só se provou que, sem nenhum `stat`, o juiz recusa.
- Se o bridge registra o stderr do gate (ele o descarta: `stdio` `ignore`), o que decide se o AVISO de
  falha ao gravar o sucesso fica visível.
- O deploy: nada disto roda no bridge servido até o merge dos dois PRs e o `ops/update-bridge.sh`.

## Gate

`LC_ALL=C bash .claude/validation/lint-selftest.sh --families a2a_verify,federation_a2a`: 255 passaram,
0 falharam, 0 pularam. `--families a2a_accept,trust_topology,update_bridge,a2a_ssrf`: 112/0/0.
