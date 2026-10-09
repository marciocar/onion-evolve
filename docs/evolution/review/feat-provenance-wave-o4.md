---
title: "Revisão — onda O4 da migração de provenance (SAC-73): 269 linhas julgadas aplicadas em 57 grafos, e o granaai como linhagem histórica"
date: 2026-10-09
branch: feat/provenance-wave-o4
reviewer: "passada adversarial com o mandato de achar linha aplicada fora do veredito, status mexido por dev-historia, caminho absoluto que sobrou na source, locality inventada, nó fora da planilha alterado, regressão do gate e termo de cliente que deixou de ser protegido. Fiz a conferência mecânica das 269 linhas contra os 57 arquivos finais, uma amostra estratificada de 15 aplicados (semente 20261009) com o nó aberto antes e depois, a idempotência, a bancada kg_migrate_v3 15/15 e registry_pins 8/8 com LC_ALL=C, e 6 mutantes"
reviewed_diff_sha256: 021c6d8465333bcd7d029cd1ec324f706a79e79c3805ef47d60a929dbbff7045
reviewed_code_sha256: 54367fbf1d0fb07ca381809642bd55705a34a12cef7839c32c23dc68b684bda8
findings_total: 6
findings_real: 3
verdict: CORRIGIDO
tokens: 0
duration_min: 150
---

# Resíduo — REGRA 56 (Revisão adversarial registrada no PR)

## O que foi revisado

A onda O4 do SAC-73. O `kg-migrate-v3.py --apply-judged` passou a ler o formato da O4 (colunas `regra` e
`locality_final`, o mesmo nó numa linha por regra) e a aplicar `dev-historia`, `manter-prod-medido`,
`reescrever-source` e `corrigir-method-locality`. Rodei a ferramenta com `--verified-at 2026-10-09` sobre
`o4-juiz.csv` (269 linhas, 57 grafos). No mesmo PR entra o selo do maestro sobre o granaai.

**Aplicado por tipo:** `dev-historia` 116 (PROD→DEV, status intocado); `manter-prod-medido` 5 (ficam em PROD,
method `medição:`, `verified_at` 2026-10-09); `reescrever-source` 145 linhas (106 aprovadas, 39 corrigidas,
8 delas omissões do proponente; a 2ª linha de `SY6_ev_settings_presentes` repete a 1ª e saiu como já
aplicada); `corrigir-method-locality` 3. Recusadas 0, ausentes 0, REPROVADAS 0 (o juiz não reprovou nenhuma).

## Conferência

- **Planilha × arquivos:** 0 divergências nas 269 linhas. Nenhum nó fora da planilha mudou, e o meta e as
  arestas dos 55 grafos que só a O4 tocou ficaram intactos. Os únicos nós de fora alterados são deliberados
  e de outro assunto: `E_ONDA_O4_APLICADA` (grafo do contrato) e `Q_GRANAAI_E_BRAIN_NO_MESMO_REMOTO`
  (door-role-parity), mais os checkpoints dos dois.
- **Idempotência:** a 2ª passada com `--check` dá rc 0 (`same 269`).
- **Radar:** `kg-radar --integrity --schema` exit 0 nos 57 grafos e no grafo do contrato.
- **Caminho absoluto na source:** 145 → 0 no corpus inteiro (fora `fixtures/`).
- **Gate** (`kg_gate.py` com os `--exclude` do CI, base em `granularity: node`): testimony-in-prod
  **121 → 8**, verified_at 17 → 15, os demais iguais, MUST 19 grafos inalterado. Travado com `--update`, sem
  `--accept-regression`.

### Amostra de 15 aplicados (semente 20261009, estratificada)

| Nó | Grafo | Ação | Antes → depois |
|---|---|---|---|
| `E_p0_logto_tenant_measured` | m2-bridge-logto | dev-historia (+ regra 2) | PROD→DEV, superseded intocado; source sem `/home` |
| `E_FAMILIA_MULTIIDE_CONGELADA` | onion-identity | dev-historia | PROD→DEV, confirmed, provenance igual |
| `E_A_MESMA_CAUSA_VOLTOU_E_AGORA_COM_O_CORPO_DA_API` | passada-adversarial | dev-historia | PROD→DEV, provenance igual |
| `D_SEM_CREDITO_POR_ORA` | review-gate-saldo | dev-historia | PROD→DEV, confirmed |
| `Q_SENHA_CHAVE_ESTADO_2026_09` | identidade-onion-vps | dev-historia | PROD→DEV, open intocado |
| `E_UPDATE_547_CARIMBOU_0_HARD_E_CHEGOU_COM_1` | gmill-update-547 | dev-historia | PROD→DEV |
| `E_PRIMITIVE_EXISTS` | guardrails-2nd-pr-state | manter-prod-medido | PROD; verified_at 07-31 → 10-09; method `medição:` |
| `C_MATERIALIZADOR_LE_O_REGISTRO` | door-role-parity | manter-prod-medido | PROD; refuted intocado; verified_at 09-30 → 10-09 |
| `Q_ONION_KG_MCP_NEXT` | librechat-kg-runtime | reescrever (CORRIGIDO) | código saiu da source; host |
| `E_MEDIDO_ESTADO_VIVO_1005` | infra-vps | reescrever (omissão) | `/var/run`, `/boot` saíram; locality — → host |
| `E_O_CORPUS_NAO_TRANSFERE_E_METADE_DA_CULPA_E_NOSSA` | claude-code-2.1-onion | reescrever | locality — → host |
| `E_OBJECAO_F6_BLOAT_E_AUTO_INCRIMINACAO` | onda-derivada | reescrever | journal por id, sem caminho |
| `E_ELENXO_SLACK_APP_CLASS_UNMEASURED` | canal-vivo-sessoes | reescrever | journal por id, sem caminho |
| `C_bypass_permissions_exposto` | stack-harmonia | reescrever (+ dev-historia) | `/home/onion/…/.env` → descrição; PROD→DEV |
| `E_BINARIO_2_1_258_TETO_200_E_CONTADOR_DE_SESSAO` | websearch-cap | corrigir-method-locality | method `medição:`, locality — → host, PROD |

Nenhum dos 15 diverge da planilha.

## Achados

1. **REAL, não curado (decisão do maestro): a regra 2 criou 7 testemunhos em PROD.** Em
   `librechat-2026-08`, o juiz trocou `leitura:` por `testemunho:` em 7 nós PROD, porque o repo
   `onion-vps-librechat` não tem remoto alcançável (locality `host`). Nenhuma linha da regra 1 os mandou a
   DEV. São `D_STACK_PADRAO_ONION_VPS`, `E_HEADROOM_SWAP_100`, `E_OIDC_GENERICO_SEM_GUIA_LOGTO`,
   `E_PEGADINHAS_OPERACIONAIS`, `E_SKILLSYNC_DORMANT_V087`, `E_SKILLS_FORMATO_IDENTICO` e
   `Q_EMBEDDINGS_KEY_PENDENTE`. O `kg-contract-check` acusa o código novo nesse grafo. O gate por nó cai
   mesmo assim (−120 + 7). Não inventei o flip: aplicar DEV ali seria decisão que o juiz não tomou.
   Proposta: uma linha de regra 1 para os 7 na próxima onda, ou medir e voltar a `leitura`.
2. **REAL, curado no fixture: a guarda de caminho absoluto vale também para a source herdada.** Na 1ª
   versão do caso (n), `E_N_CML` (`corrigir-method-locality`, source `(inalterada)`) herdava um `/home/…`, e a
   ferramenta recusou a linha. O comportamento ficou (é conservador: nenhuma source final sai com caminho
   absoluto); o fixture ganhou source própria. Nos dados reais, as 3 linhas da regra 3 têm source limpa.
3. **REAL, declarado (passivo da bancada): crash e recusa têm o mesmo rc no modo members.** O 1º mutante
   do `members-validate.sh` (`elif False:` na checagem de existência) sobreviveu: o `KeyError` seguinte
   derruba o Python com rc 1, que o `run_members_fixture` lê como "inválido, pegou". Troquei por um mutante
   que desliga a checagem inteira (rc 0, reprova). A ambiguidade é anterior a este PR e fica registrada.
4. **Declarado: `superseded_by` em vez de mover para `lineages:`.** Não há seção `lineages:` de topo no
   registro, só por membro. Tirar o granaai da lista apagaria o `id` e o `name` que a REGRA 36 (Superfície
   VENDORIZADA sem nome comercial de cliente), o `projection-safety` e o `vendor-scrub` leem, e a chave a2a
   `granaai-1`. A entrada ficou, com `superseded_by: brain-granaai`. Medido: `projection-safety.sh` e
   `vendor-scrub-form-check.sh` com saída idêntica antes e depois, e os ids derivados pela REGRA 36 com o
   mesmo sha256. Só o `ops/registry-pins.sh` muda: 19 em dia, 0 divergentes, rc 0. O granaai aparece como
   `fora (linhagem histórica → brain-granaai)`.
5. **Declarado: a família `fixtures` não rodou inteira localmente.** Ela roda o lint por fixture e passou de
   25 minutos. Conferi as duas fixtures novas direto no `members-validate.sh` (good rc 0, bad rc 1) e a CI é
   o gate final.
6. **Declarado: o `verified_at` dos 116 dev-historia não mudou**, por desenho. DEV aqui quer dizer "não
   conferido", e a data continua sendo a da observação original.

## Mutantes

| Mutante | Caso que reprova |
|---|---|
| veredito ignorado (aplica REPROVADO) | kg_migrate_v3 (m) |
| dev-historia mexe no status | kg_migrate_v3 (m) |
| locality do juiz ignorada | kg_migrate_v3 (m) e (n) |
| guarda de caminho absoluto desligada | kg_migrate_v3 (n) |
| registry-pins sem o ramo `superseded_by` | registry_pins (h) |
| members-validate sem a checagem de `superseded_by` | fixture members-bad-superseded-unknown (rc 0) |

## Itens do juiz que NÃO foram aplicados (regra nova é decisão do maestro)

- **M1:** `C_bypass_permissions_exposto`, `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO` e
  `Q_JWKS_REFETCH_STORM_SEM_PISO_NA_FALHA` foram a DEV como "não conferido", **não** como resolvido. O risco
  pode estar vivo.
- **M2:** o MCP `onion-vps-mcp-kg` está inactive e disabled, sem nó que registre o desligamento.
- **M3:** estender "nenhum caminho absoluto" a `locator` e `method` (62 nós ainda carregam).
- **M4:** medição sobre binário de versão fixa poder ficar em PROD com a versão no locator.
- **M5:** `<repo>@` obrigatório para desambiguar `locality: repo`.
- **M6:** ids de nó e nomes de grafo com nome de pasta privada fora do alcance da REGRA 30 (Segurança de
  PROJEÇÃO: nome comercial de membro privado não sai).
- **M7:** `E_floors_effective_measured_20260729` tem `verified_at` 2026-08-29 e label 07-29.
- **Fora da provenance:** o `onion-vps-librechat` tem `origin` apontando para o repo do bridge (um push ali
  mandaria a história errada); o reboot do host segue pendente desde 2026-09-24.
