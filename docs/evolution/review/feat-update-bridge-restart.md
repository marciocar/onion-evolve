---
branch: feat/update-bridge-restart
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: 9a9a8cffa921df23782d4775be962ab2eff8de24f2f398ec8b61b841e7a0102e
reviewed_code_sha256: 8f2d86072d914f12496db683a8d54bdd341fa0357ecdd2147f3e9300a2f32a3f
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 25
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada no próprio fork, sem subagente)"
---

# Passada adversarial: `feat/update-bridge-restart`

## O que muda

- `ops/update-bridge.sh` ganha `--restart` (D_UPDATE_BRIDGE_GANHA_RESTART_1022). No caso NOOP (clone e bridge em
  origin/main, árvores limpas), em vez de só re-verificar o boot vivo, ele para e religa o serviço pelo mesmo caminho
  do update (stop, trap de religamento enquanto parado, reset-failed, start), espera o `/health` local e público, exige
  um InvocationID NOVO e o `auth: enforce` no boot desta invocação, e roda as fases 6 (verifies, JWKS, NRestarts
  absoluto) e 7 (sandbox). Sem a flag o NOOP fica idêntico. Com mudança a atualizar, a flag só é anunciada: o update
  completo já religa. Argumento desconhecido sai rc 2 sem fazer nada.
- `post_update_checks` ganha o modo `restart`: reprovação sai rc 1 com o serviço rodando e SEM rollback de código
  (o código não mudou; a causa provável é a configuração relida).
- Bancada `update_bridge`: o `systemctl` falso passa a gerar InvocationID novo a cada start (`same-inv` o congela),
  `_ubr` aceita argumentos, e entram u34–u38.

## Achados

1. A mensagem de "serviço deixado RODANDO" do restart começava com o mesmo prefixo da do update e virou a 1ª
   ocorrência da âncora do mutante (u8), que passou a mutar o ramo errado e sobreviver. Reescrita ("o serviço segue
   RODANDO no boot novo"); u8 volta a morrer.
2. A âncora do mutante u36 levava a barra de continuação de linha e não casava (o sed virou no-op, a guarda da guarda
   acusou). Âncora trocada pela comparação do InvocationID.

## Mutantes

- u34 (tirar a chamada do restart → sem stop/start), u35 (RESTART=1 por padrão → o NOOP religaria), u36 (sem a prova do
  InvocationID novo → "OK" sobre o boot antigo), u37 (sem a fase 6 no restart), u38 (typo vira rc 0): todos mortos.
- Família `update_bridge` inteira: 76 passaram, 0 falharam (38 casos, intacto e mutante).

## Limites declarados

- Não rodado no vivo (o deploy é do maestro ou com o ok dele). A bancada esboça systemctl/journalctl/curl; a prova real
  é a 1ª execução de `bash ops/update-bridge.sh --restart` depois de uma mudança só no .env.
