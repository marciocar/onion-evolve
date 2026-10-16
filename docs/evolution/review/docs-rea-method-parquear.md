---
branch: docs/rea-method-parquear
pr: pendente
date: 2026-10-16
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 2
tokens: 125952
duration_min: 11
findings_fixed: 3
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente general-purpose (opus), mandato REFUTAR, 1 passada
nota: "PR de registro: triagem do método do REA (parquear) mais a prova em produção da cerca de rede do runner do /chat"
---

# Passada adversarial: `docs/rea-method-parquear`

## O que muda

1. **Triagem do método do REA.** A proposta `2026-10-16-proposal-rea-method-parquear` da curadoria chegou pelo co-relay, sem commit. Ela vai para `inbox/_processed/` verbatim: `cmp` idêntico, e a cópia untracked do checkout principal foi removida.
   - **Lugar, decidido e declarado:** grafo NOVO `docs/evolution/dissect/rea-method-2026-10/`, com 4 nós (teto 4). Segue a forma da triagem do Superpowers e não re-mede a ferramenta. O grafo canônico, de 10 nós, mora no repo da curadoria, no mesmo caminho relativo.
   - **Por que não um grafo que já existe:** o `dissect-census.sh` do core só responde "já dissecamos?" a partir de um grafo com `meta.x_dissect_tool`.
   - **O selo:** `D_REA_METHOD_2610` foi selado pelo `kg-decide-seal.sh`, com a escolhida «Parquear com 2 gatilhos (Recomendado)» e as descartadas «Absorver a paridade já» e «Rejeitar».
   - **A superação:** `E_CORE_JA_SUPERA_REA_1016` (confirmed), medida no core em `cff29401`.
   - **Gatilho (a):** `Q_REABRIR_PARIDADE_POS_FORGE`.
   - **Gatilho (b):** `Q_REABRIR_AUTORIDADE_NO_PROBE`, com `DEPENDS_ON` externo para `Q_REABRIR_CARIMBO_POR_PROBE`. Esse nó mora no core, em `superpowers-2026-10`, e segue open.
   - **Censo:** `dissect-census.sh . --check-verdict rea-method` sai rc 0.
2. **Acréscimo pedido pela sessão principal**, para não abrir um 2º PR de registro em paralelo: `E_EGRESS_FENCE_EM_PRODUCAO_1016`, no grafo `chat-agent-isolation-2026-10`.
   - **O nó:** PROD, confirmed. É a prova do `--apply --egress-fence` medida pela sessão principal às ~17:20 UTC, depois de onion-bridge#75 e do core #1168.
   - **Arestas:** SUPPORTS para `C_SUPERACAO_20261016_EGRESS_PELA_UNIT_NAO_PELO_SANDBOX`, TRACES_TO para `D_DEGRAU3_SEM_OBJETO_NO_CONVIDADO_1016` e TRACES_TO para `E_DEGRAU2_EM_PRODUCAO_1016`.
   - **Teto do `meta:`, de 141 para 142, com motivo:** é a prova em produção que a entrada da opção A construída prometeu para o PR seguinte ao `--apply`.
   - **Não medido:** um turno real de convidado com a API dentro da cerca, e o WebFetch de um modelo contra o loopback.
   - **Teto:** o AF_UNIX segue aberto (a cerca é de IP), e um processo de dentro da slice ainda forjaria uma linha do journal.
   - **Endereços:** os dois globais do host não entram literais no nó. Ficam como "IPv4 e IPv6, conferidos com o ip addr".

## Achados

1. **REAL, média, curado. O critério contava a si mesmo.** O critério da proposta era `gh api search/code?q=x_absorb_target…`. O token aparece no próprio grafo novo (no critério, no `verified_against` e no `method`), então depois do merge e da reindexação o critério sairia 2 sem nenhum plano novo, e o gatilho (a) dispararia sozinho.
   - **Cura:** o `x_dissect_criterion` passou a contar a CHAVE no início de linha, em origin/main: `git grep -lE '^[[:space:]]+x_absorb_target:' origin/main -- 'docs/evolution/dissect/*.kg.yaml' | wc -l`.
   - **Medido:** sai 1 em origin/main e só lista `conductor-2026-10` em HEAD.
   - **Desvio declarado do pedido literal:** a tarefa citava o `gh api`. O defeito é de produto, e a forma ancorada também tira a dependência do índice de busca.
2. **REAL, baixa, curado.** A `confidence` de `D_REA_METHOD_2610` saiu 0.75, contra 0.7 na curadoria, sem motivo escrito. Voltou para 0.7.
3. **Hipótese, baixa, curado no rótulo.** Dizer "o core já supera" escondia que a única regra que falta (o verificador enumerar o id) não é entregue: ela vai ao gatilho (b). O rótulo de `E_CORE_JA_SUPERA_REA_1016` passou a dizer SUPERAÇÃO PARCIAL.

Sem achados no acréscimo da cerca. O refutador reconferiu, só lendo:
- `IPAddressDeny` com 13 faixas;
- `IPAddressAllow` vazio;
- as units active e o `/health` com 200.

## Mutantes

Plantados por `ops/mutate-and-restore.sh`, com `LC_ALL=C`, contra o `--check-verdict rea-method`:

- superação apontando o próprio veredito: rc 1, com `superacao-circular-e-o-proprio-veredito`;
- superação com `status: open`: rc 1, com `superacao-nao-medida-status-open`.

Os dois foram restaurados, e o estado final saiu rc 0. Nenhum caso novo entrou na bancada: o PR é de registro e não muda maquinaria.

## Limites declarados

- O core não re-mediu o REA. Os números do N1 ao N3 são DADO da curadoria (R15.2), citados pelo grafo dela.
- A evidência da cerca é testemunho da sessão principal. Daqui não foi possível reconferir o verify de 73 OK nem o ensaio de TCP com perna de controle.
- O refutador viu uma vez o `--check-verdict` sair rc 1 (`status-open`) por volta das 17:19 UTC. O motivo provável é uma corrida com a worktree em edição, durante o selo. Não reproduziu em cinco tentativas.
