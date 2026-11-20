---
branch: feat/session-open-resume-by-id-1120
pr: pendente
date: 2026-11-20
reviewed_diff_sha256: b9b8805f86cd0e24f042def808ee52c4774c31808cf2d82e47ea5965434bdeaf
reviewed_code_sha256: c7d5ebf2504029f16abf5fac62030aa30feac100e95db8ab9269af3d6a0cbf68
findings_total: 12
findings_real: 11
findings_blocking: 0
tokens: 152181
duration_min: 12
findings_fixed: 10
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), só leitura, mandato de refutar, três passadas sobre o mesmo diff. 1ª: CHANGES_REQUESTED com 10 achados (8 curados, 1 declarado no cabeçalho, 1 hipótese não medida). 2ª: CHANGES_REQUESTED com 1 achado novo (lista privada contada só entre linhas válidas) e 1 observação, ambos curados. 3ª: APPROVED, com 1 observação baixa do lado seguro, declarada no código."
nota: "tokens = os do revisor no fim da 3ª passada; duration_min = soma das três passadas declarada pelo revisor."
---

# Passada adversarial: `feat/session-open-resume-by-id-1120`

## O que muda

1º passo de D_SESSION_ACCESS_TMUX_MOSH_RESUME_BY_ID_1120 e de D_SESSION_ONE_OWNERSHIP_REGISTRY_BY_NAME_1120:

- o `ops/session-open.sh` retoma sempre por id exato, nunca por `--continue`. O id se resolve pelo nome, no `claude agents --json` ou no transcript mais recente da pasta. Ambiguidade recusa com rc 5;
- o abridor recusa uma 2ª sessão no mesmo checkout (rc 3), seja ela vista pelo `/proc` ou pela lista de peers;
- o `--all` passa a cobrir toda sessão dona do registro de posse;
- na abertura, o abridor imprime o preflight do merge;
- o leitor único de posse é o novo `.claude/utils/orchestration/ownership.sh`, lido pelo abridor e pelo `baton-pulse.sh`;
- a bancada cobre a família `session_open` (reescrita, 64 casos com mutante) e a família `baton_pulse` (caso aj2).

O `ops/pr-merge-verified.sh` NÃO foi tocado. A paridade com a catraca é provada pelo caso (q), que roda o awk extraído do próprio script.

## Achados

1. **Alta, curado.** O slug privado de outro dono vazava o dono no preflight. Caso o5.
2. **Alta, curado.** Uma sessão de fundo viva no checkout, com outro nome, não era vista: o processo dela não se chama `claude` no `/proc`. Agora o abridor confere o cwd na lista de peers. Caso k2.
3. **Média, curado.** Quando o membro neutro tinha `local_path`, o nome casava duas linhas e a busca ficava ambígua. Agora a linha privada substitui a do registro. Caso o6.
4. **Média, curado em duas passadas.** Slug privado repetido: o preflight dizia sim onde a catraca recusa. A contagem agora segue a da catraca, sobre toda linha, válida ou não. Casos g5, g6 e g7.
5. **Média, curado.** O id resolvido entrava cru no comando do tmux. Agora ele é validado pela regex, o `--mode` passa por uma lista fechada e o comando é montado com `printf %q`. Casos r e r2.
6. **Média, curado.** Um caminho não canônico no registro furava a barreira do checkout. Agora entra `realpath -m`. Caso d2.
7. **Baixa, curado.** O `kind` entre aspas divergia da catraca. Agora segue o parse dela. Caso (q) ampliado.
8. **Baixa/média, curado.** Lista de peers ilegível virava «nenhum». Agora recusa a criação (rc 3). Caso s.
9. **Baixa, declarado.** O core fica fora do `--all` por desenho deste passo; entrar nele é decisão do maestro.
10. **Hipótese, não medida.** O preflight busca pelo nome, e a catraca pelo slug do origin. Se o origin real divergir do `remote` do registro, os dois respondem diferente.
11. **Observação da 2ª passada, curado.** Ao anexar, o abridor não avisava da sessão de fundo no checkout. Agora avisa.
12. **Observação da 3ª passada, declarado.** O id repetido com slugs distintos é mais estrito que a catraca, do lado seguro. Fica escrito no comentário da 1ª varredura.

## Dogfood

O tmux real rodou num socket próprio (`tmux -L`), com um repo de brinquedo e um `claude` de brinquedo:
- abriu e passou só `--resume <id>`;
- na 2ª vez, anexou;
- recusou um claude vivo noutra sessão tmux no checkout (rc 3);
- recusou a sessão viva no harness (rc 3) e o ambíguo (rc 5);
- sem histórico, recusou sem `--new` (rc 5).

O `--dry-run` sobre o registro real resolveu os ids de curation e kg-ssot pelo transcript e recusou os checkouts com sessão viva.
