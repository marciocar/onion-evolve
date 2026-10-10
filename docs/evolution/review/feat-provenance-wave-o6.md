---
title: "Revisão — onda O6 da migração de provenance (SAC-73): 157 linhas julgadas aplicadas em 50 grafos, verified_against e trace sem caminho de máquina"
date: 2026-10-10
branch: feat/provenance-wave-o6
reviewer: "passada adversarial com o mandato de achar linha aplicada fora do veredito, item do maestro aplicado, trace removido sem a linha na narrative, marcador P4 que não é string, caminho de máquina que sobrou em source, locator, method, verified_against ou trace, nó fora da planilha alterado, aresta perdida na reconciliação, TARGET-MISSING novo e regressão do gate. Conferi mecanicamente as 157 linhas aplicáveis contra os 50 arquivos finais e abri uma amostra estratificada de 10 aplicados (semente 20261010) com o nó antes e depois. Rodei a idempotência, a bancada kg_migrate_v3 17/17 com LC_ALL=C e 5 mutantes"
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 2
verdict: CORRIGIDO
tokens: 0
duration_min: 120
---

# Resíduo — REGRA 56 (Revisão adversarial registrada no PR)

## O que foi revisado

A onda O6 do SAC-73. O `kg-migrate-v3.py --apply-judged` passou a ler o formato da O6, em que a planilha traz
`campo` + `valor_final` no lugar dos `*_final`. A ferramenta ganhou:

- as ações `reescrever-va`, `reescrever-trace`, `remover-trace-narrative`, `marcar-path-conteudo`,
  `binario-dev`, `binario-prod` e `reconciliar`, além de `add-locality`, `reescrever-source` e
  `reescrever-method` no formato novo;
- `--new-nodes <yaml>`, que o `reconciliar` usa para inserir o nó novo;
- `--hold <id>[:<regra>]`, que retém a linha como item ao maestro.

A guarda de caminho de máquina passou a cobrir também `verified_against`, `trace` e a linha da narrative. O
hostname deste host é recusado no valor escrito. Rodei a ferramenta sobre `o6-juiz.csv`, com 160 linhas em 51
grafos e 3 `--hold`. Mudaram 50 grafos. O único sem mudança é `jev-type-safe-ai-2026-10`, que só tinha a linha
retida.

**Aplicado por tipo (linhas):**

| Tipo | Linhas | Resultado |
|---|---:|---|
| `reescrever-va` | 50 | — |
| `reescrever-trace` | 49 | 11 com a ressalva do bridge anterior a 08-08 na narrative |
| `remover-trace-narrative` | 31 | O trace sai e a descrição entra como "trace anterior (só no host): …" |
| `binario-dev` | 7 | PROD→DEV, com o method e `locality: web` |
| `binario-prod` | 1 | Fica em PROD com `medição` e `locality: web` |
| `marcar-path-conteudo` | 1 | `E_m3_portabilidade_executada` ganha `x_path_is_content: "receita"`; o literal fica |
| `reconciliar` | 1 | `E_HEADROOM_SWAP_100` → superseded/DEV; `E_HEADROOM_RAM_MEDIDO_1009` entra com SUPERSEDES |
| `add-locality` | 4 | — |
| `reescrever-source` | 6 | — |
| `reescrever-method` | 5 | — |
| `dev-sem-comando` | 2 | Já em DEV, sem mudança |

O relatório fecha com `TOTAL · plane 7 · binario-prod 1 · marcar-path-conteudo 1 · reescrever-va 50 ·
reescrever-trace 49 · remover-trace-narrative 31 · reconciliar 1 · add-locality 4 · reescrever-source 6 ·
reescrever-method 5 · same 2 · held 3 · refused 0 · missing 0`.

## Conferência

- **Planilha × arquivos:** 0 divergências. O esperado foi recalculado de cada linha (`valor_final` decomposto
  campo a campo) e comparado com o YAML final. Nenhum nó fora da planilha mudou, além de
  `E_HEADROOM_RAM_MEDIDO_1009`. As arestas dos 50 grafos ficaram intactas, fora a SUPERSEDES nova. A
  `CONSTRAINS → D_STACK_PADRAO_ONION_VPS` segue no nó antigo.
- **Únicas exceções, deliberadas:** `E_ONDA_O6_APLICADA`, a aresta dela e o checkpoint (lote 10 selado, lote 11
  aberto), os três no grafo do contrato.
- **Idempotência:** a 2ª passada com `--check` dá rc 0, com `same 157` e `held 3`.
- **Radar:** `kg-radar --integrity --schema` sai com exit 0 nos 51 grafos e no grafo do contrato.
- **`kg-contract-check`:** saída idêntica antes e depois nos 51 grafos. Os ✗ são os MUST herdados da base.
- **`kg-trace-resolve`:** TARGET-MISSING **0 → 0**. Os julgáveis sobem de 2216 para 2218 e os absolutos/URL
  caem de 75 para 1. O `remoto@sha:caminho` cai em não-caminho por desenho: o parser corta no primeiro `:` e o
  `@` reprova o filtro de caracteres.
- **Caminho de máquina no corpus (nós, fora `fixtures/`):**

  | Campo | Antes | Depois |
  |---|---:|---:|
  | source | 0 | 0 |
  | locator | 3 | 3 |
  | method | 0 | 0 |
  | verified_against | 52 | 2 |
  | trace | 80 | 0 |

  O que sobra é `E_m3_portabilidade_executada` (locator e verified_against, marcado P4 `receita`) e as duas
  citações retidas pelo item 3: `E_SKILL_INSTALL_PROMPT_AND_CURL` (locator e verified_against) e
  `E_F4_CLAUDE_JSON_CONCORRENTE` (locator).
- **Gate** (`kg_gate.py` com os `--exclude` do CI, `granularity: node`):
  - `form.pattern.node.provenance.method` **39 → 34**, pelos 5 `reescrever-method`;
  - os demais códigos SHOULD ficaram iguais, e o MUST segue em 19 grafos;
  - a base foi travada com `--update`, sem `--accept-regression`.

### Amostra de 10 aplicados (semente 20261010, estratificada)

| Nó | Grafo | Ação | Antes → depois |
|---|---|---|---|
| `E_MEDICAO_READ_VS_BASH_NO_CORPUS_DE_TRANSCRICOES` | passada-adversarial | reescrever-va | o diretório de transcrições com `~/` → "diretório de projetos do Claude Code do usuário"; PROD intocado |
| `E_VENDOR_PRIMARY_NOT_ON_DISK` | jev-decision-round2 | reescrever-va | `find` com a raiz absoluta do clone → "(na raiz do clone) `find .`"; PROD intocado |
| `C_commodity_vs_diff` | m3-federation-admin | reescrever-trace | o README do clone de onion-vps-logto no host → `onion-logto@17f4ecd9:README.md` |
| `E_L2` | doctrine-behavior-over-declaration | reescrever-trace | a componente só-host do stack → `onion-logto@7c008b2` |
| `E_producao_alcancou_o_repo` | stack-harmonia | remover-trace-narrative | o trace do clone de produção sai; narrative nova "trace anterior (só no host): o clone de produção…" |
| `C_permission_mode_fail_open` | m2-bridge-logto | remover-trace-narrative | o trace `src/config.ts:26` do clone de produção sai; narrative "trace anterior (só no host): src/config.ts l.26…"; refuted intocado |
| `E_DEEP_RESEARCH_EMBUTIDO_E_A_BASE` | meta-research-lens | binario-dev | PROD→DEV; method `derivado:` → `medição: extração…`; repo → web |
| `E_m3_portabilidade_executada` | onion-refinaria | marcar-path-conteudo | `x_path_is_content: "receita"` + narrative; o literal `env -i PATH=… HOME=…` fica |
| `E_HEADROOM_SWAP_100` | librechat | reconciliar | confirmed → superseded; DEV; nó novo e SUPERSEDES; CONSTRAINS mantida |
| `C_TETO_O_QUE_O_PRE_PUSH_NAO_PEGA` | guard-pre-push | reescrever-method | method sem classe → `leitura: provenance derivada…` |

Nenhum dos 10 diverge da planilha.

## Achados

1. **REAL, curado antes do commit: o despacho do formato O6 quebrava o formato O3.** Eu lia
   `next(iter(judged.values()))[0]`, mas no formato O3 o valor é a linha e não uma lista. A bancada pegou: os
   casos (j) e (k) caíram com Traceback. Agora o despacho confere `isinstance(list)` antes.
2. **REAL, curado antes do commit: o `status` saía entre aspas.** A 1ª aplicação escreveu
   `status: "superseded"`, diferente do resto do corpus. O vocabulário fechado (`plane` e `status`) agora vai sem
   aspas. Reverti os 51 grafos e reapliquei do zero.
3. **Declarado: a linha do trace removido entra como "trace anterior (só no host): …".** O `valor_final` do
   juiz diz "trace anterior: …". A forma com "(só no host)" é a da instrução do coordenador, e as 31 linhas são
   só-host por definição. A conferência aplica a mesma normalização.
4. **Declarado: o hostname é recusado só no valor que a linha escreve.** No valor mantido, só o caminho de
   máquina recusa. Sem isso, `ENT_whatsapp` (troca de locator) seria recusado pelo hostname que segue no
   `method`. Esse é o achado J-O6-1 do juiz e fica para a O7. Restam hostname em 3 locators, 1 method e 2
   verified_against, todos fora do campo da onda: `E_GROUNDING`, `Q_floors_effective`, `Q_route_inventory`,
   `ENT_whatsapp` e `Q_BRANCH_MAIN`.
5. **Declarado: os itens 1 e 2 do juiz foram aplicados pela letra da regra selada.** Os dois binários de
   `E_MEDIDO_LOCAL_TIER10_NO_PROPRIO_REPO` e `E_OBJECAO_EXIT2_E_PRIMITIVO_GRATIS` saíram do trace para a
   narrative. O mesmo vale para a cópia no core de `E_GRANAAI_DOCTRINE`. O juiz aplicou assim e pôs a regra nova
   ao maestro. São reversíveis em 2 e 1 linhas.
6. **Declarado: `binario-dev` move o plano, ao contrário do `manter-dev-binario` da O5.** A P2 selada manda o nó
   a DEV, e os 7 estavam em PROD. Os flips estão nomeados no nó `E_ONDA_O6_APLICADA`.
7. **Declarado: o nó novo do headroom é PROD com `locality: host`.** É medição de serviço feita no host, e o
   locator cita o compose de um repo local sem remoto, sem caminho de máquina. O `testimony-in-prod` não sobe,
   porque o method é `medição`.

## Mutantes

| Mutante | Caso que reprova |
|---|---|
| a linha da narrative do trace removido não é escrita | kg_migrate_v3 (p) |
| guarda de caminho de máquina no verified_against/trace desligada | kg_migrate_v3 (p) |
| vocabulário do marcador P4 desligado | kg_migrate_v3 (p) |
| recusa sem desfazer o que a linha já mudou (não atômica) | kg_migrate_v3 (p) |
| reconciliar sem trocar o status do antigo | kg_migrate_v3 (p) |

## NÃO aplicados (itens do maestro no resumo do juiz)

- **Item 3, marcador P4 × guarda mecânica:**
  - `E_SKILL_INSTALL_PROMPT_AND_CURL` (jev-type-safe-ai);
  - `E_F4_CLAUDE_JSON_CONCORRENTE` (radar-E3-2026-09-03).

  O `~/` é do leitor da página de terceiro. Se a guarda recusar todo `~/`, esses dois não ganham o marcador.
  Ficam intocados até o maestro decidir.
- **Item 4, sha posterior ao nó no LOCATOR:** a linha PEND de `E_lid_addressing_root_cause` ficou retida. Ela só
  renomearia `onion-vps-waha@86662e0` para `onion-waha@86662e0`. A linha P5-trace do mesmo nó foi aplicada.
- **Item 1, binário no trace, e item 2, a cópia em outro repo:** aplicados pela letra (achado 5). A regra nova
  fica para o maestro.
- **Item 5, push do onion-waha:** não é edição de grafo.
- **Fora do mandato:**
  - J-O6-1: hostname em method, locator e verified_against fora da onda, para a O7;
  - J-O6-2: premissa derivada de `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO`, candidata a `/meta:kg-freshness`;
  - J-O6-3: a coluna `grafo` da planilha com nome privado de adotante.
