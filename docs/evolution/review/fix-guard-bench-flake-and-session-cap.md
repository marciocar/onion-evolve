---
branch: fix/guard-bench-flake-and-session-cap
pr: pendente
date: 2026-11-17
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_fixed: 3
findings_blocking: 1
tokens: 0
duration_min: 0
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: 2ª passada independente (2026-11-17) — agente revisor separado, só leitura, mandato de refutar; achou 3 pontos (F1/F2/F3), todos curados nesta mesma branch (ver §"Revisão independente"). Gate mecânico: lint-selftest (private_repo_cite, baton_pulse, session_open) + lint-artifacts.
nota: "os 3 achados são da passada independente sobre o diff das mudanças A/B/C; as curas estão em commits novos nesta branch. tokens 0 e duration_min 0 = não medidos (agentes em segundo plano, custo não recuperado nesta rodada)."
---

# Três curas de guarda/bancada: o flake do hash só-dígitos, o teto de sessões 4→8 e o abridor na cura do pulso

Esta rodada forja três mudanças independentes, cada uma com caso de bancada **e** mutante que morde
(padrão da casa: um caso que passaria com o código quebrado não vale). A bancada é
`.claude/validation/lint-selftest.sh`.

## A — Flake da família `private_repo_cite` (causa PROVADA)

**A1 (bancada determinística).** Dois casos (`(s2)`, `(s3)`) montavam um commit de repo «privado» com
`git commit --allow-empty` e usavam `git rev-parse --short=10 HEAD`. Quando esse hash curto saía SÓ COM
DÍGITOS (≈ (10/16)^10 ≈ 0,9% por caso), a guarda não o tratava como candidato a commit (exige `[0-9]` E
`[A-Fa-f]`) e o caso falhava — exatamente a falha vista no CI (run 44007958327, `(s3)`). A cura força o
hash a ter dígito E letra, com teto e falha explícita:

- `_prc_mixed_commit` (`.claude/validation/lint-selftest.sh`, por `grep -n _prc_mixed_commit`): repete
  `commit --allow-empty` até o `--short=10` casar `[0-9]` e `[a-f]` (teto 100; vazio+rc1 se estourar — o
  caso já exige `[ -n "${pc}" ]`, então o estouro vira falha visível, nunca verde calado).
- `_prc_mixed_commit_tree`: o mesmo para o commit SOLTO (commit-tree, sem ref) do caso `(r)` — o `loc`,
  que alimenta a detecção de hex solto na linha do marcador, também exigia hex misto (3º gerador na
  família, encontrado pela varredura pedida, além de s2 e s3).
- Refatorados: `(s2)` usa `_prc_mixed_commit "${pr}"`; `(s3)` usa `_prc_mixed_commit "${pv}"`; `(r)` usa
  `_prc_mixed_commit_tree "${sb}"`. O `own` (`--short=9` da base) NÃO precisou: ele é SILENCIADO nas
  duas vias (misto → `own_commit`; só-dígito → fora do filtro), então o flake não o atinge.

**A2 (ponto cego REAL da guarda, curado).** Em `.claude/validation/private-repo-cite-check.sh` a camada
de dado coletava um único acervo `occ` de hex MISTO e o usava para as DUAS camadas. Um commit de clone
privado cujo hash curto é só-dígitos passava calado por `COMMIT-PRIVADO-EM-DADO`. Cura (por `grep -n
occ_clone`): dois acervos —

- `occ` (misto) segue alimentando `HEX-NAO-CONFERIDO-EM-DADO` (a falha fechada sobre o novo); a
  exigência de letra fica, para número comum (id, timestamp, telefone) **não** virar falso-positivo;
- `occ_clone` = `occ` **mais** o hex só-dígitos de **10+ casas**, e alimenta SÓ a camada de clones
  (`COMMIT-PRIVADO-EM-DADO`), que acusa apenas o que o `_batch` CONFIRMA ser commit real de um clone
  privado. Um número comum só casaria se fosse, por acaso, prefixo de um commit de verdade do clone — e
  aí é referência a ele.

Não alarguei a 2ª camada (`HEX-NAO-CONFERIDO`) para só-dígitos, exatamente para não introduzir o
falso-positivo que o pedido alertava. Casos novos em `(s4)`: um commit de clone privado com hash
só-dígitos → `COMMIT-PRIVADO-EM-DADO`; um número comum de 10+ dígitos que não é commit → cala; e `(s4-mut)`
reverte o alargamento (`len(h) >= 10` → `False`) e prova que o commit volta a passar calado. O `(s4)`
gera o hash só-dígitos num repo dedicado (`_prc_digit_commit`, teto 2000, `record_skip` se estourar — não
achar um hash só-dígitos é sorte do ambiente, não defeito).

## B — Teto de sessões interativas 4 → 8 (`D_SESSION_CAP_8_AND_TMUX_MIGRATION_1116`)

- `.claude/validation/baton-pulse.sh`: `MAXI="4"` → `MAXI="8"` (por `grep -n 'MAXI="8"'`); comentários
  das linhas do `SESSION_CAP` (`grep -n 'padrão 8'`) e a mensagem «teto prático» (`grep -n 'teto
  prático: 8'`) passam a dizer 8, citando a decisão.
- `.claude/commands/common/prompts/baton-doctrine.md`, cláusula 9: o teto passa a 8, com a data
  2026-11-16 e o id da decisão (`grep -n '8 sessões'`), e o enum `SESSION_CAP ... (8)`.
- Bancada (família `baton_pulse`): `(as)` prova as duas bordas com teto EXPLÍCITO (`--max-interactive 6`
  dispara; `7` não), independente do padrão; `(as2)` (NOVO) prova o padrão — 7 interativas e SEM flag
  não disparam, e o mutante `MAXI="8"` → `MAXI="4"` morde (com 4, 7 > 4 e o CAP volta). `(au)` passou a
  usar teto 6 vs 9 (antes dependia do padrão disparar).

## C — Abridor de sessão na cura do pulso + bancada nova

**C1 (bancada nova `session_open`).** Família nova para `ops/session-open.sh`, com dublês por ambiente
(tmux de mentira que registra chamadas e responde `has-session`; `/proc` falso com `comm`/`cwd`/
`environ`). NENHUM tmux, claude ou processo real é tocado; tudo roda `--dry-run`. Casos (cada um com
mutante): `(a)` cria com `--name` sem doorbell; `(a2)` doorbell no `.mcp.json` entra no canal; `(b)`
anexa e não cria quando a sessão tmux existe; `(c)` RECUSA rc 3 claude fora do tmux; `(d)` não recusa
claude dentro do tmux; `(e)` rc 2 para nome que não é repo; `(f)` `/proc` ilegível recusa rc 3
(fail-closed); `(g)`/`(g2)` `--all` percorre só concessão «sim» com pasta. A família entrou em
`SELFTEST_CORE_ONLY_FAMILIES` (ops/ não viaja; no adotante ela pula visível).

**C2 (texto de cura do pulso).** Em `baton-pulse.sh` a cura do `SESSION_NOT_IN_TMUX` passa a citar
`bash ops/session-open.sh <repo> --resume <id>`, com a forma `tmux new -s` como alternativa onde não há
o abridor. A linha leva o marcador `(core-only)` (REGRA 100, como `ops/load-lease.sh` na mesma casa). A
cláusula 9 da doutrina e o caso `(ao)` da bancada foram atualizados para conferir as duas formas.

## Revisão independente (2ª passada, 2026-11-17)

Um agente revisor separado, só leitura, com mandato de refutar, releu o diff de A/B/C e achou três pontos.
Os três foram curados nesta mesma branch, em commits novos.

**F1 (relevante) — o abridor travava por causa de um `claude` de OUTRA conta.** Em `ops/session-open.sh`,
`claude_pids` devolvia rc 2 (→ recusa rc 3) sempre que o `readlink` do cwd de um processo `claude` falhava —
mas o cwd de um processo de outro usuário é ilegível por permissão, então um `claude` de outra conta na
máquina travava o abridor para todo mundo. A bancada (caso `f`) afirmava essa recusa como correta. Cura: o
script agora lê o DONO de `/proc/<pid>` (`stat -c %u`) e compara com «meu uid» (`MY_UID`, substituto de teste
`SESSION_OPEN_UID`); se o cwd/environ não se lê e o processo é de OUTRO dono, IGNORA (não é a sessão desta
conta); do MESMO dono (ou dono indeterminado), segue recusando — falha fechada de verdade. Mesma regra no
`environ`. O caminho de ANEXAR, que engolia o erro com `|| out=""`, agora dá lacuna NOMEADA quando não mede um
processo do mesmo dono. Casos novos na família `session_open`: `(f)` mesmo dono/cwd → rc 3; `(f2)` mesmo
dono/environ → rc 3; `(i)` outro dono/cwd → cria normal; `(i2)` outro dono/environ → cria normal; `(h)`
anexar com cwd ilegível do mesmo dono → lacuna nomeada. Cada um com mutante que morde.

**F2 (baixa) — a cura do pulso citava o abridor com o nome errado.** `baton-pulse.sh` montava
`bash ops/session-open.sh <name> --resume <id>` com o `name` do harness, mas o abridor resolve `~/<nome>` e
exige repo: sessão sem `--name` virava «sessao» (rc 2) e sessão em worktree abriria o checkout principal. Cura:
o helper `opener_name(cwd)` só devolve nome quando o cwd é a RAIZ de um repo em `~/<basename>`, e o nome é esse
basename; em qualquer outro caso (worktree, fora de `~`, sem nome) o pulso imprime SÓ a forma `tmux new -s …`.
Casos de bancada: `(ao)` o ramo tmux-only (cwd fora de `~`) e `(ay)` o ramo do abridor (repo em `~/<nome>`,
prova que o basename é impresso, não o `name` da sessão), cada um com mutante.

**F3 (baixa) — resíduo declarado.** O corte em 10 casas para hex só-dígitos (A2) deixa de fora commit privado
citado por hash curto só-dígitos de 7 a 9 casas. O corte fica (baixá-lo acusaria inteiro comum de CSV — falso
-positivo pior que o buraco); o resíduo foi DECLARADO no comentário do trecho em `private-repo-cite-check.sh`
e aqui. Hash misto de 7+ segue coberto; só o só-dígitos curto escapa.

## Verificação

Famílias tocadas (`--families private_repo_cite,baton_pulse,session_open`): **189 passaram, 0 falharam, 0
pularam** (inclui os casos novos de F1 e F2). Lint completo: a única HARD é `docs/onion/testing-inventory.md`
(REGRA 80), regenerada aqui porque os casos novos defasaram o inventário do harness; `docs/backlog.md` fica
para o `pr-finalize` da sessão do core que finaliza.
