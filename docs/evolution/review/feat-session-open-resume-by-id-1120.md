---
branch: feat/session-open-resume-by-id-1120
pr: 1699
date: 2026-11-20
reviewed_diff_sha256: 4232b90113d448449ae5a3e348b3883d99d9bb9ec5b5a56d3267eecf22b2fe13
reviewed_code_sha256: e2c2ebe1728f83b56383578c06638545a74b2c5db9f08788382cf83b14fa7dc3
findings_total: 15
findings_real: 14
findings_blocking: 0
tokens: 177300
duration_min: 23
findings_fixed: 13
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente revisor separado (code-reviewer), só leitura, mandato de refutar, três passadas sobre o mesmo diff. 1ª: CHANGES_REQUESTED com 10 achados (8 curados, 1 declarado no cabeçalho, 1 hipótese não medida). 2ª: CHANGES_REQUESTED com 1 achado novo (lista privada contada só entre linhas válidas) e 1 observação, ambos curados. 3ª: APPROVED, com 1 observação baixa do lado seguro, declarada no código. 4ª (acréscimos pedidos pelo core, incluindo o hook session-version-drift, que é guarda): código correto, CHANGES_REQUESTED só pelo inventário do harness defasado (REGRA 80, regenerado pelo pr-finalize) e pelo carimbo caduco do resíduo; 1 sugestão baixa (imprimir o id da sessão no hook) curada."
nota: "tokens = os do revisor no fim da 4ª passada; duration_min = soma das quatro passadas declarada pelo revisor."
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

13. **4ª passada, curado.** A bancada herdava CI=true, e no CI a lista privada não se lê (desenho da catraca): 13 casos reprovaram no CI. Agora a bancada tira o CI do ambiente, e o caso g8 prova o lado do CI. Verde nos dois ambientes.
14. **4ª passada, curado.** `docs/onion/testing-inventory.md` defasado (REGRA 80): o texto novo das superfícies conta como par de modo consumido. O pr-finalize regenera a projeção.
15. **4ª passada, sugestão curada.** O hook de versão imprime o id da sessão, em vez de mandar anotar.

## Acréscimos pedidos pelo core (4ª passada)

- Três superfícies trocaram «/exit → claude --continue» pela retomada pelo id exato: o hook `session-version-drift.sh` (guarda), o `currency-census.sh` e a REGRA 65 do `lint-artifacts.sh`. O caso t, com um mutante por arquivo, trava o regresso.
- A flag da campainha foi medida numa sessão descartável, depois removida. Com `--bg --resume`, abre cópia. Interativo no tmux, retoma o mesmo id, mas para no aviso de dev channels até alguém dar Enter. O registro está no cabeçalho do abridor.

## Dogfood

O tmux real rodou num socket próprio (`tmux -L`), com um repo de brinquedo e um `claude` de brinquedo:
- abriu e passou só `--resume <id>`;
- na 2ª vez, anexou;
- recusou um claude vivo noutra sessão tmux no checkout (rc 3);
- recusou a sessão viva no harness (rc 3) e o ambíguo (rc 5);
- sem histórico, recusou sem `--new` (rc 5).

O `--dry-run` sobre o registro real resolveu os ids de curation e kg-ssot pelo transcript e recusou os checkouts com sessão viva.
