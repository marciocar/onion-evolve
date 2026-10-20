---
branch: feat/decide-who-executes
pr: pendente
date: 2026-10-19
reviewed_diff_sha256: pendente
findings_total: 12
findings_real: 12
tokens: 147367
duration_min: 5
findings_fixed: 11
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente refutador (general-purpose), uma passada sobre o diff inteiro, com sandbox e gh simulado
nota: >-
  A passada achou 1 ALTO, 7 MÉDIOS e 4 BAIXOS. Onze foram curados neste PR, cada um com caso de bancada e
  mutante que morde (13 mutantes, todos mordem). O que ficou declarado como teto, sem cura mecânica, é o
  onion-review soft-pass contado como ok no rollup.
---

# Passada adversarial: `feat/decide-who-executes`

O diff faz o medidor do `/meta:decide` dizer **quem executa** cada ato (faço-eu, maestro-com-!,
maestro-fora, outro-dono), com o comando pronto, e a doutrina ganha a cláusula 8 (o card de passo a
passo). A passada procurou classe errada, comando que não roda, regressão, bancada que não morde,
diretiva de injeção acidental, `ops/` sem marca, privacidade e ruído de UX.

## Achados e destino

| # | Sev. | Achado | Destino |
|---|---|---|---|
| 1 | ALTO | O card de merge alheio escolhia `--squash` quando o repo aceita os três métodos. Num PR de update do Onion isso quebra o próximo update (a `onion/vendor` sai da ancestralidade, medido em 2026-10-08). | **Curado.** `UPDATE_HEAD` (`chore/onion-update-*`, `onion/adopt`, `onion/vendor`) leva `--merge`. Nos demais, a ordem é rebase, squash, merge, e o card diz que o método foi inferido. Caso (p), mutantes M3 e M10. |
| 2 | MÉDIO | No adotante, a trava de merge só avisa, e a prosa dizia "o veto barra". | **Curado na prosa.** O texto diz "no core, o veto; em todo papel, repo alheio não é da sessão (MOAT)". A classe continua maestro-com-!. |
| 3 | MÉDIO | PR alheio em rascunho e verde recebia o card de merge, que o gh recusa. | **Curado.** Vira o card de `gh pr ready`. Caso (m), mutante M11. |
| 4 | MÉDIO | PR sem nenhum check recebia "espero o CI" com `--watch`, que bloqueia a chamada. | **Curado.** O sem-check tem ação própria (conferir se o CI disparou). O pendente é acompanhado em segundo plano. Caso (p), mutante M8. |
| 5 | MÉDIO | `gh pr merge N` sem flag de método não roda sem TTY. | **Curado.** A flag sai de `merge_flag('')`. Caso (p). |
| 6 | MÉDIO | PR deste repo cuja branch está na worktree de outra sessão recebia oferta de conserto ou merge. | **Curado.** Herda outro-dono. Caso (p), mutante M9. O dogfood mostrou isso ao vivo no PR#1214. |
| 7 | MÉDIO | A bancada não exercitava o PR verde pelo caminho verificado, o rascunho, o sem-check nem o pendente. | **Curado.** O caso (p) cobre os quatro, rodando num repo com o caminho verificado rastreado e depois sem ele. Mutante M7. |
| 8 | MÉDIO | O `onion-review` em soft-pass conta como ok na pré-condição do card. | **Declarado como teto** na doutrina ("Não julga o CI pelo veredito"). No PR deste repo, o caminho verificado relê o veredito. |
| 9 | BAIXO | A seção `## merge` se partia em duas por causa da linha access. | **Curado.** A classe de linha virou chave secundária da ordenação. |
| 10 | BAIXO | `--foreign-repo` aceitava `-R/x`, `dono/`, `/x` e `a/../b`, e duplicava quando repetido. | **Curado.** Regex fechada e dedupe. Caso (m), mutante M12. |
| 11 | BAIXO | O badge faço-eu em toda linha seal era ruído (53 de 59). | **Curado.** A linha seal leva 🗳️, os selos são contados à parte ("decisões a selar N") e o cabeçalho de outro-dono só sai se houver linha dessa classe. O falso positivo da pista ("o onion não tem sudo") fica declarado. |
| 12 | BAIXO | Com `GH_TOKEN` inválido no ambiente, o card mandava `gh auth login`, que não vence a variável. | **Curado.** O card manda trocar a variável. Caso (n): o runner do CI tem a variável, então o caso a tira para medir o ramo do login e a repõe para medir o da variável. Mutante M13. |

## O que o refutador tentou derrubar e não derrubou

- O merge deste repo é faço-eu no core: o caminho verificado existe e o hook só barra o `gh pr merge` direto.
- As flags do gh existem na 2.96.0.
- O TSV não regrediu: as 3 colunas novas vão no fim, com 11 campos em toda linha.
- REGRA 98 (Diretiva de injeção escrita como citação não pode estar viva): só as 2 diretivas reais do `decide.md` têm `!` seguido de crase.
- REGRA 100 (Superfície que viaja não cita ops/ como se o destinatário o tivesse): as citações levam `(core-only)`.
- Privacidade: zero nomes privados nas linhas novas.
