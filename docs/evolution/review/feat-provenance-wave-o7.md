---
title: "Revisão — onda O7 da migração de provenance (SAC-73): 93 linhas julgadas aplicadas em 36 grafos, label e narrative sem caminho de máquina"
date: 2026-10-10
branch: feat/provenance-wave-o7
reviewer: "passada adversarial com o mandato de achar linha aplicada fora do veredito, item do maestro aplicado, label acima de 280, label anterior perdido ou com caminho, caminho de máquina que sobrou em qualquer campo de nó, isenção selada recusada, segredo que sobrou, nó fora da planilha alterado, TARGET-MISSING novo e regressão do gate. Conferi mecanicamente as 93 linhas contra os 36 arquivos finais e abri uma amostra estratificada de 10 aplicados (semente 20261010) com o nó antes e depois. Rodei a idempotência, a bancada kg_migrate_v3 18/18 com LC_ALL=C e 7 mutantes"
reviewed_diff_sha256: pendente
findings_total: 6
findings_real: 2
verdict: CORRIGIDO
tokens: 0
duration_min: 90
---

# Resíduo — REGRA 56 (Revisão adversarial registrada no PR)

## O que foi revisado

A onda O7 do SAC-73. O `kg-migrate-v3.py --apply-judged` passou a ler o formato da O7: a planilha traz
`campo` + `valor_final` e **não** tem a coluna `regra`, com o mesmo nó numa linha por campo. A proposta genérica
`reescrever` vira a ação pelo campo:

- `reescrever-label` (nova): troca o label (no máximo 280, variante A) e acrescenta à narrative o
  "label anterior: …" da planilha. Sem esse texto, a linha é recusada.
- `reescrever-narrative`, `reescrever-reverify-note` e `reescrever-locator` (novas): substituem o campo pelo
  `valor_final`.
- `reescrever-va`, `reescrever-trace`, `reescrever-method` e `marcar-path-conteudo`: as da O6.

A substituição inteira da narrative é aplicada **antes** do label do mesmo nó. Sem isso, o label anterior de
`E_GROUNDING` seria apagado.

A guarda de caminho de máquina (`ABS_FS_RE`) ganhou duas formas (item A7 do juiz):

- a **barra dupla** (`Read(//home/…)`), que exige a barra depois do diretório e não casa depois de `:`, para
  `https://dev.to` não virar caminho;
- o **til de conta** (`~onion/…`) seguido de letra. O `~abril/2026` fica de fora.

Ela também ganhou as isenções seladas pelo maestro em 2026-10-10:

- **A4:** `/dev/null`, `/dev/stdin`, `/dev/stdout` e `/dev/stderr` ficam literais.
- **A6:** caminho relativo do repo é legítimo. A guarda nunca o olhou, e a bancada agora prova isso.

A exceção do gmill (o domínio público e os nomes dos arquivos de deploy ficam verbatim) passa, porque a
ferramenta não tem guarda de nome privado. A bancada também prova isso.

**Aplicado por tipo (linhas):**

| Tipo | Linhas |
|---|---:|
| `reescrever-label` | 71 |
| `reescrever-narrative` | 9 |
| `reescrever-locator` | 4 |
| `reescrever-trace` | 3 |
| `reescrever-va` | 2 |
| `marcar-path-conteudo` | 2 |
| `reescrever-reverify-note` | 1 |
| `reescrever-method` | 1 |

O relatório fecha com `refused 0 · held 0 · missing 0`.

## Conferência

- **Planilha × arquivos:** 0 divergências nas 93 linhas. Nenhum nó fora da planilha mudou, e nenhum campo fora
  do declarado mudou nos nós da planilha. A única exceção deliberada é `E_ONDA_O7_APLICADA`, com a aresta dele e o
  checkpoint (lote 11 selado, lote 12 aberto) no grafo do contrato.
- **Idempotência:** a 2ª passada com `--check` dá rc 0.
- **Radar:** `kg-radar --integrity --schema` sai com exit 0 nos 36 grafos.
- **`kg-contract-check`:** a saída é idêntica antes e depois nos 36 grafos. Os 3 MUST que aparecem são herdados.
- **`kg-trace-resolve`:** TARGET-MISSING **0 → 0**, com 2218 julgáveis, todos resolvendo.
- **Caminho de máquina em TODOS os campos de nó** (146 grafos de `git ls-files`, fora `fixtures/`, com a guarda
  da O7):
  - **antes:** 91 campos em 81 nós. Por campo: label 70, narrative 9, locator 6, verified_against 4,
    reverify_note 1, method 1. A guarda anterior não via 13 deles.
  - **depois:** 5 campos em 3 nós, os 3 marcados com `x_path_is_content`:
    - `E_SKILL_INSTALL_PROMPT_AND_CURL`, citação;
    - `E_F4_CLAUDE_JSON_CONCORRENTE`, citação;
    - `E_m3_portabilidade_executada`, receita.
  - Pela guarda anterior eram 92 em 82. O 82º é o `/dev/null` do curl em `Q_SITE_SEM_PORTA_EN_E_SEM_CONTATO`,
    isento pelo A4 e de qualquer forma descrito pelo juiz.
- **Gate** (`kg_gate.py` com os `--exclude` do CI): `form.range.node.label` **2224 → 2162**. São −62 labels: os
  61 condensados e a omissão da barra dupla, todos acima de 280 antes. Os outros códigos ficaram iguais. A base foi
  travada com `--update`, sem `--accept-regression`.
- **O segredo (`Q_ARANDEK_SEGREDOS…`):** o valor (20 caracteres) foi extraído do label no commit anterior à
  aplicação, sem ser impresso. A contagem é feita sobre os arquivos rastreados da branch, no disco e por
  `git grep`: **1 antes, 0 depois**. Ele não entrou na narrative nem no "label anterior".

### Amostra de 10 aplicados (semente 20261010, estratificada por ação)

`Q_ARANDEK…` ficou fora do sorteio de propósito, para que a amostra não abra o nó do segredo.

| Nó | Grafo | Ação | Antes → depois |
|---|---|---|---|
| `E_REGISTRO_RECUSA_PAPEL_MINI_E_PLUGINS` | door-role-parity | reescrever-narrative | o clone com a raiz absoluta → "⟨o clone local do onion-plugins não tem⟩"; o resto é verbatim |
| `Q_floors_effective` | m2-bridge-logto | reescrever-locator | "…caminhador-de-cadeia-em-⟨hostname⟩" → "…na-vps-do-core" |
| `Q_floors_effective` | m2-bridge-logto | reescrever-va | a mesma troca no verified_against; o label vai de 1226 para 277 car. |
| `E_GRANAAI_DOCTRINE` | doctrine-sync-ingestor | reescrever-trace | sem trace → os 4 `onion-evolve@<sha>:…/_processed/…` (item 2 da O6) |
| `E_F4_CLAUDE_JSON_CONCORRENTE` | radar-E3-2026-09-03 | marcar-path-conteudo | `x_path_is_content: "citação"`; o label vai de 328 para 270 car. |
| `E_p1p3_provisioned` | m2-bridge-logto | reescrever-reverify-note | o arquivo de bootstrap com o home do root → "no home do root (ausente hoje)" |
| `ENT_whatsapp` | vps-shared-tools | reescrever-method | "host vivo ⟨hostname⟩" → "host vivo da VPS"; o testemunho fica |
| `E_CAUSA_ABERTA_LEITOR_MULTITHREAD_0904` | fios-abertos | reescrever-label (CORRIGIDO) | 776 → 278 car.; preserva a redação antiga do grep (A5 fica com o maestro) |
| `E_session_is_on_vps` | waha-adapter | reescrever-label | 618 → 264 car.; o hostname vira "hostname dela" |
| `E_TASK_TOOLS_A_FORMA_DO_GATE_MUDOU_O_DESLIGAMENTO_NAO` | radar-E3-2026-09-21-r5 | reescrever-label | 944 → 278 car.; o label antigo inteiro está na narrative |

Nenhum dos 10 diverge da planilha.

## Achados

1. **REAL, curado antes do commit: a narrative do próprio nó de colheita carregava `~/`.** Ao descrever a
   guarda, escrevi `~/` e `~<conta>/` na narrative de `E_ONDA_O7_APLICADA`, e a medição pegou: 4 nós em vez de 3.
   Troquei por "til do home" e "til de conta".
2. **REAL, curado antes do commit: a primeira contagem misturava duas guardas.** O "antes" de 92 em 82 somava a
   guarda anterior e a nova, e o `/dev/null` isento pelo A4 entrava. A contagem pela guarda selada é 91 em 81, e o
   nó de colheita foi corrigido.
3. **Declarado: no formato O7, a `regra` sintética é o próprio campo** (`[regra label; narrative]`). Ela só serve
   para ordenar e etiquetar o relatório.
4. **Declarado: o nó que termina igual ao que era sai como `same`.** Na 2ª passada, a narrative substituída e o
   label anterior reacrescentado se compensam em `E_GROUNDING`.
5. **Declarado: a fidelidade semântica de cada label condensado é do juiz** (11 de 61 corrigidos). A ferramenta
   confere forma, tamanho, caminho de máquina e hostname.
6. **Declarado: o valor do segredo some da árvore, mas segue no histórico git.** Isso vale inclusive para a linha
   removida no diff deste PR (item A2 do juiz, do maestro).

## Mutantes

| Mutante | Caso que reprova |
|---|---|
| teto de 280 desligado | kg_migrate_v3 (q) |
| reescrever-label aceito sem "label anterior" | kg_migrate_v3 (q) |
| barra dupla fora da guarda | kg_migrate_v3 (q) |
| til de conta fora da guarda | kg_migrate_v3 (q) |
| isenção do /dev/null (A4) desligada | kg_migrate_v3 (q) |
| ordem narrative → label invertida | kg_migrate_v3 (q) |
| linha da narrative não escrita | kg_migrate_v3 (q), (p) e mais um |

## NÃO aplicados (itens do maestro no resumo do juiz)

- **A3:** renomear os 4 ids com o nome privado do gmill (`E_gmill_demo_route_caddy`,
  `E_GMILL_VEREDITO_DOS_TRES_FALSOS_POSITIVOS`, `Q_GMILL_FALSOS_POSITIVOS_SEM_TRIAGEM`, `Q_GMILL_MAIN_DIVERGIU`).
  Fica para o SAC-99.
- **A4:** `/dev/null` e `/dev/stdin` nos 7 campos com o idioma de shell. O selo os mantém **literais**: não há
  nada a reescrever, e a guarda os isenta.
- **A6:** o alcance da REGRA 5 (Limites de linhas) sobre `docs/discussions/onion-pessoal-marcio/…`. O selo diz que
  o caminho relativo do repo é legítimo e fica como está.
- **A5:** o `E_CAUSA_ABERTA_LEITOR_MULTITHREAD_0904`, que erra o grep. É candidato a `/meta:kg-freshness`, e a O7
  só preservou a redação antiga.
- **A1 e A2:** estão decididos ou são atos do maestro. A variante A foi selada. A rotação do segredo, o aviso ao
  adotante e a reescrita do histórico não são edição de grafo.
- **Fora do mandato:** J-O7-2 (os `onion-vps-librechat@sha` sem remoto), J-O7-3 (o `I_CONSOLE_DO_LOGTO` diz
  "ATIVO") e o `meta.note` do `bridge-produto-2026-08` (F-O7-3).
