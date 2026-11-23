---
branch: fix/pr-merge-verified-three-defects-1121
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: e8f304ab0a9da154f5eac62b1e72d21ce185d2eae3d17930c47bc6ec18694144
reviewed_code_sha256: 5060cb60c533abf79e4b9d36ed10c9552ae718f82561d11cc21b647c2fc62a34
findings_total: 9
findings_real: 9
findings_blocking: 1
tokens: 206998
duration_min: 4
findings_fixed: 4
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), só leitura, mandato de refutar; não escreveu o código. 1ª passada 08:10 a 08:12 UTC: REJECTED com 1 bloqueante. Reconferência das curas 08:50 a 08:51 UTC: APPROVED com 3 baixos."
nota: "tokens somam as duas passadas do revisor (95632 + 111366, medidos pelo harness); duration_min é o relógio declarado pelo revisor (2 min + 1 min). A curadoria do 1º baixo da reconferência entrou depois do APPROVED, coberta pelos casos pmv1b/pmv1bm."
---

# Passada adversarial: `fix/pr-merge-verified-three-defects-1121`

## O que muda

`ops/pr-merge-verified.sh` cura três modos de falha, sem mexer no que o gate decide (CI verde, strict, catraca do
repo próprio, one-touch, sessão do core medida em /proc):

1. **Merge feito com a branch local presa numa worktree.** Não reproduziu como rc 1: o ramo «mergeou, a limpeza
   falhou» já devolvia rc 0 (a cura do #814), e seis merges reais com essa saída do gh (10/19 a 11/13) saíram rc 0.
   O que faltava era o aviso: agora ele nomeia a worktree, lida do `git worktree list --porcelain` (dado, não a prosa
   do gh), e os comandos de limpeza; e o `ls-remote` ilegível deixa de virar «já não existe».
2. **Rodado de fora de um checkout.** De `~`, o gh sem `--repo` não resolvia o repo e o script morria na âncora.
   Agora entra no checkout do próprio script antes de resolver o alvo (com `--repo`, só se o origin dele é esse repo).
3. **A corrida logo após o push.** A leitura dos arquivos do PR tenta de novo com espera crescente e teto declarado
   (5 leituras, 50 s; nenhuma soma passa de 60 s). Esgotado, recusa como antes e diz quanto esperou.

## Achados

| # | Severidade | Achado | Destino |
|---|---|---|---|
| 1 | BLOQUEANTE | O `cd` da cura 2 quebrava os caminhos tirados de `BASH_SOURCE[0]` quando o script era chamado por caminho relativo; o `_rm_script` vazio fazia o `_fallback_guard_gate` passar o PR de guarda sem o resíduo | CURADO: `_PMV_SELF` absoluto fixado antes do `cd`; caso pmv2b e mutante pmv2bm |
| 2 | BAIXO | O mesmo defeito no one-touch (`--script`) e no `sync-main-worktree.sh` | CURADO com o 1 |
| 3 | MÉDIO | Com `--repo` de outro repo, o aviso podia nomear worktree de um clone que não é o alvo | CURADO: aviso só quando o checkout daqui é o alvo; caso pmv1b e mutante pmv1bm |
| 4 | BAIXO | De fora de um checkout, o modo "repo sem CI" passa a julgar a árvore do script | DECLARADO no comentário do bloco do `cd` |
| 5 | BAIXO | O teto de 60 s cobre as esperas, não o tempo das chamadas `gh api` | DECLARADO (a repetição é só um GET, sem efeito) |
| 6 | BAIXO | A bancada da cura 1 prova o aviso, não o rc 0 (já existia, caso (b)) nem os ramos `0)`/`2)` do `ls-remote` | DECLARADO |
| 7 | BAIXO | (reconferência) A cura do 3 olhava só o `--repo`, não o `GH_REPO` | CURADO: o alvo é o `--repo`, senão o `GH_REPO` |
| 8 | BAIXO | (reconferência) O pmv2b prova a resolução da pasta, não o gate de guarda em si | DECLARADO: é a mesma expressão do `_rm_script` |
| 9 | BAIXO | (reconferência) Os baixos 5 e 6 seguem como estavam | DECLARADO |

## Prova

Família `pr_merge_verified`: 277 casos, 0 falhas. Casos novos pmv0, pmv1, pmv1b, pmv2, pmv2b, pmv3 e pmv3b; mutantes
pmv1m, pmv1bm, pmv2m, pmv2bm e pmv3m, todos mortos pelo caso da cura, com a cópia limpa no mesmo arranjo passando
nos cinco casos (pmv0). Antes da cura, pmv2, pmv3 e pmv3b reprovavam com as mensagens do defeito, e o pmv1 reprovava
só por não nomear a worktree (rc já era 0).
