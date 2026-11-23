---
branch: fix/drive-audit-seal-radar
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: pendente
findings_total: 6
findings_real: 4
findings_blocking: 2
tokens: 85350
duration_min: 4
findings_fixed: 3
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), que não escreveu o código: só leitura, mandato de refutar, experimentos em cópia no scratchpad. 1ª passada: REJECTED com 2 majors (nó entre dois ciclos nomeado «no ciclo»; arquivo solto .old-drive-*.sh), 2 minors e 2 nits. Curados os 2 majors e o minor do backup. 2ª passada: ver § Segunda passada."
nota: "tokens e duration_min são os da 1ª passada do revisor (85350 tokens, 241 s). Uma tentativa anterior de revisão por `claude -p` estourou o teto de 25 min sem devolver nada; foi ela, ao que tudo indica, que deixou o .old-drive-*.sh (criado às 14:01, durante aquela execução)."
---

# Passada adversarial: `fix/drive-audit-seal-radar`

Tarefa do Linear SAC-483: três defeitos do `/meta:drive` achados na revisão da maquinaria de 2026-11-20.

## O que muda

- `.claude/validation/kg-drive-project.sh`
  - **(a) ciclo parcial**: um ciclo `DEPENDS_ON` entre abertos com outro nó pronto saía `READY`, rc 0. Agora sai
    `CICLO` (`--check` rc 1), nomeando os nós do ciclo e os presos a jusante. Detecção: poda de Kahn entre abertos;
    da sobra, é «no ciclo» quem alcança a si mesmo.
  - **(b) escrever antes de validar**: `--close-lot`/`--seal` gravavam num grafo que o radar já reprovava, avisavam
    e não desfaziam. Agora o radar roda antes (reprovado ou não medido: rc 2, nada escrito) e depois (reprovou:
    desfaz byte a byte, rc 3), como no `kg-decide-seal.sh`.
  - **(c) radar ausente lido como reprova**: o radar era resolvido relativo à raiz de quem chamava, e todo rc≠0
    virava «reprova integridade/schema». Agora o radar é o irmão do script (`$HERE/kg-radar.sh`); só rc 1 é reprova;
    ausência ou outro rc é «NÃO MEDI» (rc 2).
- `lint-selftest.sh`: `_drive_sac483_selftests`, com caso e mutante para cada defeito, mais o caso a2 (nó entre
  dois ciclos). Fixtures `partial-cycle` e `between-cycles`.
- `drive.md` e `onion-drive-doctrine.md`: o veredito `CICLO`, a validação antes e depois e o «NÃO MEDI».

## Reprodução antes da cura

| Defeito | Comando | Antes |
|---|---|---|
| (a) | `kg-drive-project.sh` num grafo com C pronto, X↔Y em ciclo e Z dependendo de X | `READY: pronto=1 bloqueado=3`, rc 0, sem menção a ciclo |
| (b) | `--close-lot` e `--seal` num grafo com nó órfão | `x_drive_checkpoint` gravado, rc 2, arquivo alterado |
| (c) | o grafo íntegro de (a), fora do repo (no scratchpad) | `reprova integridade/schema no radar`, rc 2, com o radar direto dando rc 0 |

## Achados

1. **[major, curado]** Nó entre dois ciclos (depende de um, é citado pelo outro) saía «no ciclo». A 2ª poda
   (no sentido inverso) não isola ciclos. Cura: «no ciclo» é só quem alcança a si mesmo pelas arestas. Caso a2.
2. **[major, curado]** Arquivo solto `.claude/validation/.old-drive-2967130.sh`, cópia da versão antiga, fora do
   gitignore. Apagado antes do commit.
3. **[minor, curado]** Se o desfazer falhasse (exit 9), o trap apagava a única cópia boa. Agora o trap é
   desligado e o caminho do backup é impresso. O mesmo defeito existe no `kg-decide-seal.sh` (fora deste diff).
4. **[minor, limite]** O radar roda com `set -e`; um comando interno que falhe com 1 também sai rc 1 e seria lido
   como reprova. Problema do radar, fora deste diff.
5. **[nit, limite]** `KG_DRIVE_RADAR` é aceito em produção; só é avisado no stderr (mesmo nível do
   `DECIDE_SEAL_RADAR`).
6. **[nit, limite]** O caso c1-MUT supõe `TMPDIR` fora de um repo git. Se cair dentro, o efeito é alarme falso,
   nunca falso-verde.

## Mutantes

Todos por `_prove_mutation` (mutação aplicada, intacto satisfaz, mutante não satisfaz):

- a-MUT: veredito `CICLO` desligado → o ciclo parcial volta a sair READY.
- b1-MUT: sem a validação antes → a escrita chega ao grafo já reprovado.
- b2-MUT: sem o `_undo` → o checkpoint fica gravado num grafo reprovado.
- c1-MUT: radar relativo à raiz → fora do repo o grafo íntegro não se mede.
- c2-MUT: todo rc≠0 lido como reprova → o radar quebrado acusa o grafo.

## Varredura dos grafos reais

Os 1019 `*.kg.yaml` do repo rodados com `--check` depois da cura: nenhum sai `CICLO`. A mudança não acende
nada que já estava verde.

## Segunda passada

Pendente no momento da escrita deste resíduo; atualizado abaixo quando voltar.

## Limites declarados

- Achados 4, 5 e 6 acima.
- O card nomeia o defeito (a) como «ciclo calado no AUDIT». O brief da tarefa o leu como «o ciclo do laço não
  reporta o que fez»; a fonte (o relatório da revisão de 2026-11-20, §4, defeito 1) diz que é o **ciclo de
  `DEPENDS_ON`** que o censo AUDIT não acusa. Curei o que a fonte descreve.

## Re-revisão pós-rebase (2026-11-23, sessão do core)

A fila de merges rebaseou a branch sobre a main (173 commits à frente). `git range-diff` do commit antes e depois:
o código da PR (`kg-drive-project.sh`, as duas fixtures, a família da bancada e o trecho da doutrina) é o mesmo;
o que mudou é só projeção gerada (`docs/onion/testing-inventory.md`, as contagens da bancada), que o pr-finalize
regenera. Nenhuma linha de código desta PR mudou de sentido; a revisão isolada acima segue valendo.
