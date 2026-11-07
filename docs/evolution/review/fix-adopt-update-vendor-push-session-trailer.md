---
branch: fix/adopt-update-vendor-push-session-trailer
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
findings_blocking: 1
tokens: 0
duration_min: 20
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: passada própria do agente de execução (Opus 5.5), sem refutador externo
nota: "tokens não medidos (0); a passada é do mesmo agente que escreveu o diff, e isso é dito"
---

# Passada adversarial: `fix/adopt-update-vendor-push-session-trailer`

## O que muda

- `vendor-branch.sh update`: lê a `onion/vendor` remota (ls-remote) ANTES de escrever na vendor. Local ausente → nasce da remota. Remota não ancestral da local → rc 13, nada tocado. Depois do commit da vendor e da guarda de BASE CRUZADA, push por fast-forward (sem force) e conferência por ls-remote (rc 14 se não bater; rc 13 se o push for recusado por não-ff). Uma linha diz de onde para onde a remota foi. Sem remoto ou remoto sem a branch: não empurra e diz. `ONION_VENDOR_PUSH=0` desliga, dito.
- `session-trailer.sh` (novo): `Claude-Session: <URL>` de `ONION_CLAUDE_SESSION_URL` ou de `CLAUDE_CODE_BRIDGE_SESSION_ID`, conferidos pela forma; nada inventado, e a nota é dita quando falta. Usado pelo `durable-commit.sh` (commit da vendor e o durável pós-merge) e pelo merge do `vendor-branch.sh`, logo abaixo da assinatura do alvo e sem duplicar.
- `adopt.md`: rc 13/14 na tabela do --update e a linha da remota na seção "Arquivos aplicados" do relatório downstream (sem seção nova: o comando está no teto de 800 linhas da REGRA 5 (Limites de linhas (por TIPO de artefato — tamanho saudável ≠ número universal))).

## Achados

1. (real, corrigido, bloqueava) A seção nova do relatório no `adopt.md` citava a linha entre crases DENTRO do heredoc sem aspas (`<<EOF`): rodada literal, a crase executaria `onion/vendor` como comando. Trocado por aspas.
2. (real, limite) `GIT_TERMINAL_PROMPT=0` não cala um prompt de SSH (host desconhecido, passphrase): num remoto SSH sem agente o ls-remote pode esperar. Não forcei `BatchMode` para não sobrescrever a config SSH do adotante.
3. (real, limite) O push respeita o hook pre-push do adotante; um hook pesado ou que recuse vira rc 14 com a saída dele.
4. (real, limite) O caminho "push recusado por não-ff DEPOIS do commit da vendor" (corrida entre a leitura e o push) não tem caso próprio; o rc 13 dele é deduzido do `--porcelain`, não medido na bancada.
5. (real, limite) Se o precheck cria a vendor local a partir da remota e o update para em seguida por árvore suja (rc 2), a branch local fica criada. É espelho da remota, inofensivo, e é dito no stdout.

## Mutantes

Família `vendor_push_trailer` (fixtures em mktemp com remoto bare local, nenhum adotante real): 6 casos verdes e 5 mutantes in-bancada que morrem (bloco `D_CURE-*` removido numa cópia dos helpers, com a sanidade de que a remoção ocorreu):
- (a) push ff + conferência ← `D_CURE-vendor-push`
- (b) remota divergente → rc 13, vendor e integração intactas ← `D_CURE-vendor-remote-diverged`
- (c) clone novo: a vendor nasce da remota ← `D_CURE-vendor-from-remote`
- (d1) commit da vendor com Claude-Session abaixo da assinatura ← `D_CURE-session-trailer-durable`
- (d2) commit de merge (não ff) idem ← `D_CURE-session-trailer-merge`
- (e) sessão desconhecida ou com forma inválida → sem linha e com a nota (sem mutante: é a ausência do comportamento)

E dois mutantes pelo `ops/mutate-and-restore.sh` contra os arquivos reais, ambos mortos (rc 1 do helper, arquivo restaurado): o push trocado por `if false` (reprovou a, c, d2) e o trailer do durable-commit desligado (reprovou d1). Rodada com `LC_ALL=C`: famílias `vendor_push_trailer,vendor_branch,vendor_baseline_removido,durable_commit` verdes, 0 falhas.

## Limites declarados

- Achados 2 a 5 acima.
- O remoto que não tem a `onion/vendor` não a ganha: criar branch no remoto do adotante é decisão do dono, e a linha diz o comando.
- A curadoria já está com local e remota iguais (461834f) depois do PR #234; a prova do defeito é o relatório daquele update, não o estado de hoje.
