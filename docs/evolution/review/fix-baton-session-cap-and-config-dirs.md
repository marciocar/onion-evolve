---
branch: fix/baton-session-cap-and-config-dirs
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: e72fc7425c2edea0034a43e9b3e124f82493475c07bde4139973798a5cc60771
reviewed_code_sha256: eb82a80861d946bc7e4b8a8199ba280d0b868c1afcc5f64d96fd5b6939218159
findings_total: 11
findings_real: 6
findings_blocking: 2
tokens: 84981
duration_min: 5
findings_fixed: 6
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: code-reviewer em contexto isolado (subagente só leitura, recebeu o diff e o objetivo, não a minha conclusão)
nota: "Seis achados reais, todos curados no mesmo PR e cada cura com caso e mutante na bancada. Os dois que bloqueavam: a mesma sessão vista por duas listas virava alerta falso de higiene, e o rótulo da decisão aceitava qualquer número solto (5, 12 e 15 passavam)."
---

# A trava do teto deixava passar o teto errado, e a pasta extra duplicava o processo

## O que muda

- **SAC-484 (a):** o teto de sessões do pulso mora num lugar só, `SESSION_CAP_DEFAULT` com `SESSION_CAP_DECISION` ao
  lado, em `.claude/validation/baton-pulse.sh`. O `baton.md` dizia «padrão 4», o medidor e a doutrina diziam 10. A
  decisão vigente é `D_SESSION_CAP_10_PLUS_5_AGENTS_1119`, que **supera** `D_SESSION_CAP_8_AND_TMUX_MIGRATION_1116`
  (aresta SUPERSEDES no grafo `coordenacao-selos-arquivo-2026-11.kg.yaml`). O brief citava a de 16/11 como vigente; o
  grafo diz outra coisa, e vale o grafo. O modo `--check-cap` confere a decisão (existe, `done`, não superada, rótulo
  diz «N sessões») e a prosa das duas páginas. A bancada roda o `--check-cap` no repo real: o desencontro reprova no CI.
- **SAC-484 (b):** pastas de config declaradas (`BATON_CONFIG_DIRS` ou `~/.local/state/onion/baton/config-dirs.tsv`).
  De cada uma, só a lista de peers (`CLAUDE_CONFIG_DIR=<pasta> claude agents --json`) e o `stat` dos transcripts.
  Subagentes dessas pastas ficam fora por desenho (ler exigiria conteúdo). Medido ao vivo: a sessão do hub, antes
  invisível, sai `IDLE_NO_QUEUE` com fonte `peers@~/.claude-granaai+farol` e o aviso `SESSION_NOT_IN_TMUX` dela.

## Achados

| # | achado | sev. | destino |
|---|---|---|---|
| 1 | o mesmo pid entrava duas vezes em PROCS (pulso com `CLAUDE_CONFIG_DIR` igual a uma pasta declarada): `SESSION_SAME_CHECKOUT` e «dois terminais» falsos | bloqueia | curado: dedupe por (pid, sessionId); a pasta padrão passa a ser a do `CLAUDE_CONFIG_DIR` do ambiente (o `proj_dir` também). Caso (bh) |
| 2 | o rótulo da decisão casava o número solto: teto 5, 12 ou 15 passava pelos «5 agentes», «15» e «12» do mesmo rótulo | bloqueia | curado: número ancorado a «sessões». Caso (bi) |
| 3 | a prosa com «(padrão 4)», «`--max-interactive 4`», «é 4» passava | menor | curado: toda menção à flag, 1º número em até 30 caracteres. Caso (bj) |
| 4 | a bancada não isolava `BATON_CONFIG_DIRS` nem `CLAUDE_CONFIG_DIR` exportados no shell | menor | curado: `env -u` dos dois no `_bpr` |
| 5 | `#` no meio do caminho cortava a pasta | menor | curado: comentário só no começo ou depois de espaço |
| 6 | variável vazia desligava o arquivo em silêncio; rótulos iguais por basename; campo morto; chamada ao harness para a pasta padrão | menor | curados: vazia = ausente, rótulo pelo caminho, campo removido, pasta padrão pulada no bash |
| 7-11 | subagentes das pastas extras não lidos; mutantes provam; `--check-cap` nas bordas; espaço e `~`; troca de sha única | confirmação | — |

## Mutantes

Cada caso novo tem o mutante dele, provado pela `_prove_mutation`: (az) troca o número do medidor, (az2) desliga a
conferência da prosa, (az3) ignora o SUPERSEDES, (bd) tira o `CLAUDE_CONFIG_DIR` da chamada, (be) tira o stat das
pastas extras, (bf) lê subagente da pasta extra, (bg) cala a pasta ausente, (bh) tira o dedupe, (bi) solta o número
do rótulo, (bj) volta o regex antigo da prosa. O (as2) mudou de âncora (`MAXI="10"` virou `SESSION_CAP_DEFAULT="10"`).

## Limites declarados

- A conferência do rótulo é por texto («10 sessões»). Um campo estruturado no nó (`x_session_cap`) seria mais firme;
  não entrou porque editar nó selado pede o selo do maestro.
- O `--check-cap` só olha `docs/onion/graph/*.kg.yaml`; uma decisão de teto noutro diretório não é vista.
- A pasta extra só é medida se declarada: o pulso não descobre `CLAUDE_CONFIG_DIR` de outros processos (seria ler o
  ambiente deles inteiro).
