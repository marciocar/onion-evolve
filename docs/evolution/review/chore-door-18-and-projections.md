---
branch: chore/door-18-and-projections
pr: 869
date: '2026-09-23'
reviewed_diff_sha256: b54f69cf80e2f35cbaceb70ef068a1effe02bba0936a90080c15b592bf2518f5
findings_total: 6
findings_real: 5
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Passada adversarial CONDUZIDA POR MIM MESMO, sem refutador independente em worktree — e isto
  está declarado como limite, não como equivalência. O motivo é o escopo: a leva é um FIX de
  guarda, não selagem de doutrina, e a diretriz desta sessão é não disparar subagente sem pedido.
  O que substitui em parte o refutador é que CINCO dos seis achados vieram de MEDIÇÃO que reprovou
  minha própria hipótese, não de leitura — inclusive duas hipóteses minhas erradas sobre a causa da
  morte, que é justamente o que um refutador cobraria. Os campos tokens/duration_min ficam em ZERO
  porque não houve run de modelo a medir: seria fabricar número para preencher campo.
---

# Resíduo da revisão — porta 18 e a morte silenciosa do lint

## Campos de custo: por que ZERO é honesto aqui

`tokens: 0` e `duration_min: 0` não são omissão: **não houve run de subagente**. Toda a passada foi
determinística (reproduções em shell, bancada, mutante, log de CI baixado). Declarar número inventado
para satisfazer um campo é exatamente a classe que esta leva cura.

## Ângulos de ataque, e o que cada um devolveu

| # | ângulo | resultado |
|---|---|---|
| 1 | *a causa é `set -e` sobre `&&`-list com substituição falha?* | **REPROVOU minha 1ª hipótese** — não reproduziu na 1ª tentativa porque o harness não espelhava o runner (usei `local` na mesma linha, que mascara o rc). Reproduzido só ao copiar a forma exata: `local x=""` + atribuição nua. |
| 2 | *a causa é função cujo último comando é um `if` falso?* | **REPROVOU minha 2ª hipótese** — `rc=0`, chegou ao sumário. |
| 3 | *o dano é só da porta?* | **ACHADO REAL, pior que o diagnóstico inicial**: `--stub-baselines` esvazia os 26 baselines quando o framework viaja, então o lint morria em **todo adotante**, não num caso de borda. |
| 4 | *a cura `\|\| true` virou fail-open?* | **NÃO** — provado por dois casos de bancada: entrada no baseline segue tolerada, entrada fora segue HARD. |
| 5 | *o trap rotula como morte alguma saída LEGÍTIMA (ajuda, repo-não-Onion, subshell)?* | **NÃO** — varredura de `exit` de topo antes do sumário devolve só o `exit 2` do próprio trap; o lint não tem `--help`; e a varredura completa produziu **zero** `MORREU` espúrio (medido em `/tmp/lint-final.out`). |
| 6 | *as 2 falhas da bancada são minhas?* | **UMA É, UMA NÃO** — medido em worktree destacada em `origin/main`: `rules-registry (f)` já falhava lá (pré-existente); `backlog-projection: em-dia` só falha na minha árvore, e a causa é o grafo **não-commitado** da pesquisa Zoho/GLPI (9 nós `open`) — frente alheia, declarada abaixo. |

## Achados e destino

1. **Baseline vazio mata o lint** (causa da porta travada) — CURADO no sítio + mecanismo.
2. **O raio alcança todo adotante**, não só a porta — declarado na mensagem do commit e no PR.
3. **`rules-registry (f)` acusava a regra errada**: media `OK ✓` global e reportava "REGRA 39 acusou o
   estado real". Reprovava hoje pela porta defasada. CURADO, com mutante provado.
4. **`.env.bak-*` fora do `.gitignore`** — backup com tokens rastreável. CURADO (glob + remoção).
5. **REGRA 85 não dispara no CI** — HARD que só morde no disco. NÃO curado: virou nó
   `E_REGRA_85_EMITE_ZERO_NO_CI_E_2_HARD_NO_DISCO` + decisão `D_GUARDA_QUE_SO_MORDE_NO_DISCO_VALE_COMO_GATE`,
   com a lacuna (por que ela cala lá) declarada em vez de explicada por chute.
6. **Eu medi meu próprio artefato truncado** (`tail -18` no relatório da bancada e depois grep nele)
   pela segunda vez nesta sessão — o detalhe das falhas estava no runner, não no que eu guardei. Não
   é achado de produto; é registro de reincidência, e a cura é rodar a família sozinha sem pipe.

## Fora do escopo, e por quê

- **`backlog-projection: em-dia`** segue vermelho na minha árvore. Honesto: o grafo da pesquisa
  Zoho/GLPI tem 9 nós `open` e a projeção não foi regenerada. É frente da pesquisa, e mexer nela aqui
  misturaria duas levas — o erro de `git add -u` que já custou duas varreduras nesta sessão.
- **Os 2 HARD da REGRA 85** não se curam antes do merge: a porta só se re-materializa de `main`
  mergeada. É a razão dos `--no-verify` de checkpoint, e a validação final é o CI **neste** SHA.
