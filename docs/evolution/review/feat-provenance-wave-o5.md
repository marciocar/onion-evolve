---
title: "Revisão — onda O5 da migração de provenance (SAC-73): 81 linhas julgadas aplicadas em 34 grafos, localizadores sem caminho de máquina"
date: 2026-10-09
branch: feat/provenance-wave-o5
reviewer: "passada adversarial com o mandato de achar linha aplicada fora do veredito, plano mexido por manter-dev-binario, status mexido por dev-historia, caminho de máquina que sobrou em source, locator ou method, locality inventada ou apagada, nó fora da planilha alterado e regressão do gate. Conferi mecanicamente as 81 linhas aplicáveis contra os 34 arquivos finais e abri uma amostra estratificada de 10 aplicados (semente 20261009) com o nó antes e depois. Rodei a idempotência, a bancada kg_migrate_v3 16/16 com LC_ALL=C e 4 mutantes"
reviewed_diff_sha256: ec70373b2ac49c5049280161e74f7330e7c23db301ffee85d7fd09d3f95e4d1e
reviewed_code_sha256: 7bcda5171f36091416d1725532d22a9d5a13f2b533d40a4aee82e059ceb885d4
findings_total: 6
findings_real: 3
verdict: CORRIGIDO
tokens: 0
duration_min: 90
---

# Resíduo — REGRA 56 (Revisão adversarial registrada no PR)

## O que foi revisado

A onda O5 do SAC-73. O `kg-migrate-v3.py --apply-judged` passou a ler o formato da O5. A planilha é a mesma
da O4, mas aqui campo `*_final` **vazio** quer dizer inalterado. A ferramenta ganhou quatro ações:

- `reescrever-locator-method`;
- `manter-prod-binario`;
- `manter-dev-binario`;
- `dev-sem-versao`.

A guarda de caminho de máquina saiu da source e cobre agora source, locator e method finais, inclusive o valor
mantido. Rodei a ferramenta sobre `o5-juiz.csv`, com 84 linhas em 37 grafos. Mudaram 34 grafos.

**Aplicado por tipo (linhas):**

| Tipo | Linhas | Resultado |
|---|---:|---|
| `reescrever-locator-method` | 61 | — |
| `manter-prod-binario` | 4 | Ficam em PROD com `locality: web`. Em 2 deles, a linha da regra 2 repete a da regra 1 e saiu como já aplicada |
| `manter-dev-binario` | 2 | Ficam em DEV com `locality: web`. Plano intocado |
| `dev-sem-versao` | 2 | Só a provenance mudou (ver achado 1) |
| `dev-historia` | 12 | PROD→DEV, status intocado |

Recusadas 0, ausentes 0. O relatório fecha com `TOTAL · plane 12 · prov 67 · same 2 · rejected 1 · sealed 2`.

## Conferência

- **Planilha × arquivos:** 0 divergências nos 74 nós aplicados. O esperado foi recalculado da planilha sobre o
  HEAD: campo vazio mantém o valor, `dev-*` vai a DEV. Nenhum nó fora da planilha mudou. O meta e as arestas
  dos 34 grafos ficaram intactos.
- **Únicas exceções, deliberadas:** `E_ONDA_O5_APLICADA` e o checkpoint, os dois no grafo do contrato.
- **Idempotência:** a 2ª passada com `--check` dá rc 0, com `same 81`.
- **Radar:** `kg-radar --integrity --schema` sai com exit 0 nos 34 grafos e no grafo do contrato.
- **`kg-contract-check`:** sem piora. Os únicos ✗ são MUST herdados da base: `guardas-revisao`,
  `m2-bridge-logto` e `rito-task-manager`.
- **Caminho de máquina em source, locator ou method, no corpus (fora `fixtures/`):** **63 → 3**. Os 3 que
  sobram são os não aplicados.
- **Gate** (`kg_gate.py` com os `--exclude` do CI, `granularity: node`):
  - testimony-in-prod **8 → 1**. Resta `E_MEDIDO_BLOAT_DO_PROPRIO_CORE_1001`, a exceção selada;
  - os demais códigos SHOULD ficaram iguais, e o MUST segue em 19 grafos;
  - a base foi travada com `--update`, sem `--accept-regression`.

### Amostra de 10 aplicados (semente 20261009, estratificada)

| Nó | Grafo | Ação | Antes → depois |
|---|---|---|---|
| `Q_MAIS_UM_IMUTAVEL_GATED` | identidade-onion-vps | reescrever | `/home/…/onion-vps-vaultwarden 31cd4f9:` → `onion-vps-vaultwarden@31cd4f9:`; open intocado |
| `E_FAROL_ANUNCIAVA_FANTASMA` | guardas-revisao | reescrever | method `/proc` → `procfs`; DEV |
| `E_GIT_LSTREE_MAIN` | onion-identity | reescrever | o caminho saiu da cauda do locator; superseded intocado |
| `E_BINARIO_2_1_258_TETO_200_E_CONTADOR_DE_SESSAO` | websearch-cap | manter-prod-binario (+ regra 1) | `~/.local/share/…/2.1.258` → `binário do Claude Code 2.1.258`; host → web; PROD |
| `E_AUTO_MODE_E_UMA_CAMADA_DE_PERMISSAO_QUE_O_ONION_NAO_USA` | radar-E3-2026-09-21-r5 | manter-prod-binario | method placeholder → `medição: claude auto-mode defaults …`; repo → web; PROD |
| `E_MEDIDO_LOCAL_TIER10_NO_PROPRIO_REPO` | poda-instruction-bloat | manter-dev-binario | `(host)` saiu da source; host → web; **DEV → DEV** |
| `E_OBJECAO_EXIT2_E_PRIMITIVO_GRATIS` | unidade-bilhetavel | dev-sem-versao | `(host)` saiu da source; host → web; DEV (já estava) |
| `E_OIDC_GENERICO_SEM_GUIA_LOGTO` | librechat | dev-historia | PROD→DEV, provenance igual |
| `E_SKILLSYNC_DORMANT_V087` | librechat | dev-historia | PROD→DEV, provenance igual |
| `E_W9_BRIDGE_DEPLOY_0902` | m2-bridge-logto | dev-historia (+ regra 1) | PROD→DEV; method `leitura:` placeholder → `testemunho:` no host; repo → host |

Nenhum dos 10 diverge da planilha.

## Achados

1. **REAL, declarado: `dev-sem-versao` encontrou os dois nós já em DEV.** A ação diz "PROD → DEV", mas
   `E_ESTUDO_O_CLAUDE_CODE_RECUSA_O_QUE_NAO_PROVA` e `E_OBJECAO_EXIT2_E_PRIMITIVO_GRATIS` já estavam em DEV no
   HEAD. A ferramenta aceita PROD (e vira DEV) ou DEV (fica). Sobre qualquer outro plano, recusa. Nos dois casos
   só a provenance mudou, e não houve flip.
2. **REAL, curado na ferramenta: a guarda não via caminho logo depois de crase ou dois-pontos.** O prefixo da
   `ABS_FS_RE` não incluía `` ` `` nem `:`. Por isso, `` `~/x` `` e `host:/etc/x` passariam. Acrescentei os
   dois. Medido no HEAD dos 37 grafos, a contagem é a mesma com e sem a cura (63), então nenhuma linha real
   dependia disso.
3. **REAL, curado no desenho: a guarda vale também para o valor MANTIDO.** O campo vazio herda o atual. Se a
   guarda olhasse só o que a linha traz, um method antigo com `/home/…` sobreviveria a uma linha que só trocou o
   locator. Agora ela confere os três campos finais. O caso (o) da bancada cobre isso com `E_O_SOBRA`.
4. **Declarado: 4 nós aplicados seguem sem `locality`.** São `E_ADOCAO_ROBUSTA_F1`,
   `E_LOCALE_FRAGIL_EM_TRES_SITIOS_PRE_EXISTENTES`, `E_NAO_HA_NAO_USO_HA_ASSIMETRIA_POR_DESENHO` e
   `E_V1_COMMITS`. A planilha deixou `locality_final` vazio, que quer dizer inalterado, e eles não tinham a
   chave. Não deduzi a locality, para não mexer em campo fora da planilha. O `--locality` resolve numa passada
   própria.
5. **Declarado: a guarda de caminho é por lista de raízes, não pela classe.** `/outro/repo` não casa. Nesta
   onda, a linha `E_REEXECUCAO_DOS_COMANDOS_REAIS` foi reescrita pelo juiz, então não houve custo. Mesmo assim,
   a guarda pela classe é a P3 do juiz e fica para o maestro.
6. **Declarado: a âncora móvel de `E_REEXTRACAO_2_1_295_SO_NOMES` foi aplicada como julgada.** A
   `source_final` traz `git show HEAD:…`. O F6 do próprio juiz pede `af4a420a~1`, e corrigir aqui seria
   reescrever o veredito.

## Mutantes

| Mutante | Caso que reprova |
|---|---|
| `manter-dev-binario` sem a checagem de plano | kg_migrate_v3 (o) |
| `locality` do juiz ignorada (`web` não aplicado) | kg_migrate_v3 (o) |
| guarda de caminho de máquina só na source | kg_migrate_v3 (o) |
| `~/` fora da `ABS_FS_RE` | kg_migrate_v3 (o) |

## NÃO aplicados

- **REPROVADO:** `E_m3_portabilidade_executada` (onion-refinaria). A receita `env -i` com o PATH e o HOME exatos
  **é** o dado, e a âncora que o proponente apontou não existe.
- **`ao-maestro-P4` (3 linhas):**
  - `E_m3_portabilidade_executada` (a mesma);
  - `E_SKILL_INSTALL_PROMPT_AND_CURL` (jev-type-safe-ai), citação verbatim;
  - `E_F4_CLAUDE_JSON_CONCORRENTE` (radar-E3-2026-09-03), citação verbatim.

  Os grafos ficam intocados até o maestro selar a P4.
- **Regra nova (decisão do maestro), não aplicada:**
  - P1: enum `dev-sem-comando`;
  - P2: re-rótulo das medições de binário;
  - P3: guarda pela classe;
  - P4: isenção para caminho-conteúdo;
  - P5: caminho em `verified_against` (52 nós) e em `trace` (80 nós);
  - D1: promoção DEV→PROD;
  - D3: convenção da locality mista;
  - D5: pasta × remoto.
- **Achados do juiz fora da provenance:**
  - F1: `onion-vps-waha@c92ff68` não existe no remoto;
  - F2: drift provável de `E_HEADROOM_SWAP_100`, que agora está em DEV;
  - F3: âncora sem sha a conteúdo raspado depois;
  - F4: nome privado em 9 nós;
  - F5: a coluna `grafo` da planilha;
  - F6: ver o achado 6 acima.
