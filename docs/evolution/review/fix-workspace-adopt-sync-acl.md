---
branch: fix/workspace-adopt-sync-acl
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
tokens: 0
duration_min: 30
findings_fixed: 2
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada na própria sessão, sem subagente)"
---

# Passada adversarial: `fix/workspace-adopt-sync-acl`

## O que muda

- `ops/workspace-adopt-sync.sh`: o `apply` deixa de usar `rsync --chown` e passa a copiar com `--numeric-ids`,
  devolvendo o dono por `find -uid <dono do staging> -exec chown -h`; o backup leva `--acls --xattrs
  --numeric-owner`; nasce o `reapply` (refaz só os metadados quando o conteúdo do vivo já é o do staging; conteúdo
  diferente recusa).
- Bancada: 3 casos novos (grupo nomeado do ACL chega intacto; reapply restaura; reapply com conteúdo diferente recusa)
  e 2 mutantes novos (`aclmap`, que reintroduz o `--chown`, e `reapply`) — 16 casos, 9 de 9 mutantes mortos.

## Achados

1. **Medido no 1º apply real (2026-10-22):** o `--chown=onion:onion` do rsync é `--usermap=*:onion
   --groupmap=*:onion`, e o mapa vale para os grupos NOMEADOS do ACL. O `group:onion-chat` (gid 987, posto pelo
   `ops/chat-runner.sh` para o runner do convidado) virou `group:onion` no workspace inteiro. O staging estava certo
   (conferido por `getfacl -n`). A bancada não via porque rodava com `OWNER=""`; agora roda com o próprio usuário como
   dono, e o mutante `aclmap` morre.
2. O backup não guardava ACL (`tar` sem `--acls`): um rollback devolveria o workspace sem as ACLs do runner.

## Mutantes

- `aclmap` (o `--chown` de volta) e `reapply` (sem a recusa de conteúdo diferente): mortos; os 7 anteriores seguem
  mortos.

## Limites declarados

- O conserto do workspace vivo é o `reapply` com o staging da 1ª rodada, depois do merge.
- Uma conferência minha à mão (`sudo git status` no workspace, fora do wrapper) reescreveu o `.git/index` como root;
  o `reapply` o devolve do staging com o dono certo. O `verify` do wrapper já roda o radar como o usuário do serviço.
