# Onda O5: proposta do proponente (SAC-73)

> **Papel:** proponente. Esta onda **não edita grafos e não abre PR**. Um juiz independente refuta depois.
> Base: `origin/main` em `a7c43d95` (2026-10-09), com a O4 já aplicada. Planilha:
> [`o5-proposta.csv`](o5-proposta.csv), com **80 linhas** sobre **74 nós**, uma linha por (nó, regra).
> Incorpora os dois ajustes do coordenador recebidos durante a onda: `~/` conta como caminho de máquina, e
> **medição sobre binário de versão fixa leva `locality: web`** (selo do maestro).

## Contagens

| Regra | Proposta | Linhas | Observação |
|---|---|---:|---|
| 1. Caminho de máquina sai de `locator`/`method` | `reescrever-locator-method` | 61 | 4 viram testemunho+`host`, 2 vão a `web` (binário), 1 vai a `repo` (`onion-plugins@sha`) |
| 2. Medição sobre binário de versão fixa | `manter-prod-binario` | 6 | 4 já em PROD e 2 **promoções** DEV→PROD (caso D1) |
| 2 | `dev-sem-versao` | 2 | têm versão, mas falta o comando (P1) |
| 3. Testemunho datado em PROD vai a DEV | `dev-historia` | 10 | 6 do librechat + 4 em cascata da regra 1 |
| 3 | `manter-prod-medido` | 1 | `E_HEADROOM_SWAP_100`, medido hoje com `docker inspect` |

### Universo da regra 1, medido

A busca percorre `provenance.locator` e `provenance.method` dos 146 `.kg.yaml` fora de `fixtures`, carregados
com PyYAML.

| Forma | Nós | Nota |
|---|---:|---|
| Absoluto `/home`, `/etc`, `/var`, `/usr`, `/tmp`, `/opt`, `/boot`… | **55** | O grep ingênuo dá 59. Os outros 4 são **falso-positivo** de `/lib/` dentro de caminho relativo (`.claude/hooks/lib/…`, `.claude/validation/lib/…`): `E_CURA_LIB_INVOCACAO_PARTILHADA`, `E_DOIS_DRIFTED_NAO_RECONCILIADOS`, `C_TETO_MUTANTES_QUE_AS_CAMADAS_ESCONDEM`, `I_P3_KG_VIEW_TRIPLO_PARSE_CURADO` |
| `~/` (ajuste do coordenador) | **5** só `~/` e 1 com `~/` e absoluto | `E_R3_F11_REGRAS_DE_PERMISSAO` já está entre os 55 |
| Absoluto **sem barra final** (`/tmp`, `/proc`) | **3** | escapavam de qualquer grep por `/dir/` (M1) |
| **Total** | **63** | 61 linhas na planilha e 2 deixadas de fora de propósito (D2) |

O "cerca de 62" do juiz da O4 bate com isso, a menos dos falso-positivos e das formas sem barra.

**Ficaram de fora (2):** `E_SKILL_INSTALL_PROMPT_AND_CURL` (`~/.claude/skills/jev/SKILL.md`) e
`E_F4_CLAUDE_JSON_CONCORRENTE` (`~/.claude.json`). Nos dois o caminho está dentro de uma **citação verbatim de
terceiro**: a página do fornecedor e a l.7 do CHANGELOG oficial. Trocar o caminho falsificaria a citação. O
`~` ali não é desta máquina, é o texto da fonte.

### Critério para "o nó vira testemunho+host" (regra 1)

A regra diz que, se o caminho só existe no host, o nó vira testemunho com `host`. Apliquei isso só quando o
caminho é **load-bearing**, isto é, quando a medição É o estado do host:

- `E_CONSOLE_LIGADO_DESDE_08_10`
- `E_W9_BRIDGE_DEPLOY_0902`
- `E_VENDOR_PRODUTO_REFUTADO_EM_SANDBOX`, cujo script **sumiu**: o `ls` devolve "No such file or directory"
- `E_librechat_install_started`, cujo repo não tem remoto alcançável

Quando a base do nó é um arquivo versionado da `source` e o caminho de máquina era só valor ou ponteiro
secundário, saiu o caminho e ficaram `method` e `locality`. São 54 linhas, com evidência "caminho incidental".

**Cascata:** os 4 load-bearing estavam em PROD. Ao virarem testemunho, disparam `integrity.testimony-in-prod`.
Pela regra de classe da O3, cada um ganhou uma linha da regra 3 `dev-historia`. Se o juiz recusar a conversão,
a linha da regra 3 cai junto.

### Âncoras medidas hoje (regra 1)

- **Repos com remoto:** `onion-vps-vaultwarden@6d82b1b` e `@31cd4f9`, e `onion-logto@617364f`, `@2a4d992`,
  `@4e99f87` e `@dd1ba80`. Conferidos com `gh api …/commits/<sha>`. A pasta local `onion-vps-logto` tem remoto
  `marciocar/onion-logto`.
- **`E_BIOGRAFIA_…`:** vira `onion-evolve@27179d37`. Reproduzido: `ls-tree .claude/diary` = 127.
- **`Q_VPS_EXPOSURE_…`:** vira `onion-evolve@9e75a73d:…vps-exposure-check.sh`, com as l.89-92 e a l.99
  conferidas. O achado é sobre os caminhos, e a âncora os preserva sem repeti-los.
- **`Q_RESIDUOS_…`:** vira `onion-plugins@22b859fc`, o master até 09-07. Conferido: o `README.md` l.116 traz o
  link 404 que o nó descreve.
- **Pastas privadas trocadas pelo id**, resolvido pelo `local_path` do `members.yaml`:
  `hub-operacoes-enterprise` (l.263), `metagamify` (l.88) e `poc-venda-direta-pdi` (l.504). Uma pasta sem
  registro virou `<adotante-sem-registro>` (M3). Nenhum nome de pasta privada aparece na planilha nem aqui.

## Regra 2: binário

Recorte literal: `method` com `medição:` **e** a medição feita **sobre** o binário. Todas as linhas levam
`locality: web`, pelo selo.

| Nó | Plano | Proposta | Base |
|---|---|---|---|
| `E_MEDIDO_LOCAL_O_GATE_E_O_PRIMITIVO_1001` | PROD | manter | `grep -ao` sobre 2.1.286. A metade do repo foi **reproduzida** em `265f6a89`: 15 hooks, 6 com `exit 2`, 5282 linhas e 203 `violation`. Em `1db59240` seriam 5361/208, então o sha certo é o de 09-30 |
| `E_AUTO_MODE_E_UMA_CAMADA_…` | PROD | manter | `claude auto-mode defaults` sobre 2.1.278, com a saída versionada. **Reproduzido:** 17/70/1, e 18/15/6 em `6e4e5088` |
| `E_BINARIO_2_1_258_TETO_200_…` | PROD | manter | `re.finditer` com o trecho verbatim. A regex em si não foi registrada (conf 0.7) |
| `E_BINARIO_2_1_258_MAX_CONCURRENT_…` | PROD | manter | idem |
| `E_ESTUDO_O_CLAUDE_CODE_RECUSA_…` | DEV | dev-sem-versao | versão 2.1.289 presente, "comando não registrado" |
| `E_OBJECAO_EXIT2_E_PRIMITIVO_GRATIS` | DEV | dev-sem-versao | versão presente, sem comando no próprio nó (o irmão registra) |
| `E_MEDIDO_LOCAL_TIER10_NO_PROPRIO_REPO` | DEV | manter (**promoção**) | `grep -ao InstructionsLoaded <binario 2.1.259>` |
| `E_REEXTRACAO_2_1_295_SO_NOMES` | DEV | manter (**promoção**) | versão na source; comando = bancada `--families cited_directive` (conf 0.45) |

**Fora do recorte, sem aplicar:**

- **Medição sobre o binário, mas rotulada `derivado`, `leitura` ou `juízes`, e em PROD:**
  `E_INSTRUCTIONSLOADED_PAYLOAD_MEDIDO_0903`, `E_FALLBACK_NATIVO_MEDIDO_0903`,
  `E_DEEP_RESEARCH_EMBUTIDO_E_A_BASE`, `E_PREMODELSWITCH_DISPARO_MEDIDO_0902`,
  `C_CREATE_SKILL_EXECUTA_GIT_DIFF_A_CADA_INVOCACAO`, `C_RAIO_X_PUBLICA_ALVOS_FALSOS_DE_SKILLS` (os dois
  superseded) e `E_CONTRATO_DE_HOOKS_EXPLODIU`. Ver P2.
- **Medição COM o binário, e não sobre ele:** a claim é sobre a doc, o changelog, a conta ou o ambiente.
  São `E_ELENXO_CC_VERSION_NOT_ANCHORED`, `E_CC_FORCE_ENV_E_HOOK_MODELSWITCH`, `E_LACUNAS_E3_R4_0904`
  (versão do processo), `D_REGRA65_MEDE_O_PROCESSO` (claude sintético), `E_HOOKS_INERT_ON_INSTALL_FIXED`
  (marketplace mutável) e os dois `E_PROBE_ALIAS_FABLE_*` (resolução de alias na API).

## Regra 3: os 7 do librechat

Universo reproduzido: `kg_validate.py --where` dá `integrity.testimony-in-prod` ×7 em `librechat-2026-08` e
×1 em `E_MEDIDO_BLOAT_DO_PROPRIO_CORE_1001`. Esta última é a exceção selada e fica.

- **6 vão a `dev-historia`:** `D_STACK_PADRAO_ONION_VPS`, `E_OIDC_GENERICO_SEM_GUIA_LOGTO`,
  `E_PEGADINHAS_OPERACIONAIS`, `E_SKILLSYNC_DORMANT_V087`, `E_SKILLS_FORMATO_IDENTICO` e
  `Q_EMBEDDINGS_KEY_PENDENTE`.
- **`E_HEADROOM_SWAP_100` fica em PROD (`manter-prod-medido`).** Medido em 2026-10-09T22:11Z com
  `docker inspect --format '{{.Name}} mem={{.HostConfig.Memory}}'`:

  | Container | `mem_limit` |
  |---|---:|
  | api | 1073741824 |
  | rag | 1073741824 |
  | vectordb | 536870912 |
  | mongo | 536870912 |
  | meilisearch | 536870912 |
  | admin (entrou depois) | 536870912 |

  Bate com o label. **Ressalva:** "o swap já esteve 100%" é passado e não se re-mede.

## Casos difíceis

- **D1. "Fica em PROD" × "sobe a PROD".** `E_MEDIDO_LOCAL_TIER10_NO_PROPRIO_REPO` e `E_REEXTRACAO_2_1_295_SO_NOMES`
  satisfazem a condição, mas **nasceram DEV por autoria** (`ac6d6356` e `af4a420a`). Propus a promoção com
  confiança baixa. Se o juiz ler "fica" literalmente, as duas linhas viram só a troca de locality para `web`.
- **D2. Caminho como CONTEÚDO.** Vetor de teste (`/usr/bin/gh` em `E_DEFEITO_…`), receita de comando
  (`env -i PATH=/usr/bin:/bin HOME=/tmp/nohome` em `E_m3_…`) e citação verbatim (os 2 excluídos). Os dois
  primeiros reescrevi pela forma, com confiança 0.6. A receita literal do `E_m3` sobrevive no `SYNTHESIS.md`.
- **D3. `locality` mista.** `E_MEDIDO_LOCAL_O_GATE_…` e `E_AUTO_MODE_…` medem binário **e** repo. O selo manda
  `web`, mas metade da evidência é `onion-evolve@sha`.
- **D4. `Q_route_inventory`.** É pergunta aberta medida com `sudo grep` no clone de produção. Só tirei o
  caminho, sem converter a testemunho, porque a source é a análise versionada.
- **D5. `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO`.** O locator passa a `onion-logto@617364f` (nome do remoto), mas o
  method diz `onion-vps-logto@617364f` (nome da pasta). Não unifiquei o method, que está fora da regra.

## Propostas ao maestro (regras novas, NÃO aplicadas)

- **P1. `dev-sem-comando`.** A regra 2 nomeia só a falta de versão. Os dois `dev-sem-versao` têm a versão e não
  têm o comando. O enum pede um valor próprio.
- **P2. Medição de binário rotulada `derivado`, `leitura` ou `juízes`.** São 7 nós em PROD, listados acima.
  Proposta: corrigir o rótulo para `medição` e então aplicar a regra 2. Sem isso, a regra cobre a forma e
  não a classe.
- **P3. A guarda deve nomear a CLASSE.** Uma lista de diretórios erra pelo vocabulário: `/boot` e `/opt`
  ficaram fora do brief, `/tmp` e `/proc` sem barra também, e `/lib/` deu 4 falso-positivos dentro de
  caminho relativo. A guarda deve casar "absoluto no início de token, ou `~/`", e não uma lista.
- **P4. Isenção para caminho-conteúdo** (D2): citação verbatim de terceiro, vetor de teste e receita. Ou se
  marca explicitamente, ou se proíbe também e se aceita a perda da literalidade.
- **P5. Caminho absoluto fora de `provenance`.** `verified_against` e `trace` continuam com
  `/home/marcio/.local/share/claude/versions/…`, por exemplo em `E_ESTUDO_…`, `E_OBJECAO_EXIT2_…`,
  `E_MEDIDO_LOCAL_O_GATE_…` e `E_MEDIDO_LOCAL_TIER10_…`. A regra 1 não os alcança.

## Para o maestro (fora da provenance)

- **M1.** Ver P3. As formas sem barra e `/boot` escapavam do grep do brief e do juiz.
- **M2.** O `onion-vps-waha@c92ff68`, citado em `E_waha_public_route_caddy`, **não existe** no remoto
  `marciocar/onion-waha`: o `gh api` devolve 422. O backup de DNS de 2026-10-08 também só existe no host.
- **M3. Ponto cego da REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente).** Uma das 10 pastas do
  locator de `E_W9_PIN_GREP_MEDIDO` (a 1ª da lista original) **não tem entrada no `members.yaml`**. O nome não
  é repetido aqui. Há também dois clones
  locais para o id `poc-venda-direta-pdi`. Isso fica invisível à REGRA 36, e registrar é ato de segurança.
- **M4.** `C_TOPO_SHARED_BASE` e `E_GIT_MERGEBASE` carregavam, no locator, o nome de uma **branch** do
  metagamify que contém o nome privado. Como o locator já era reescrito, troquei a branch por
  `<branch do fork privado>`, e o sha `f7e4b034` continua identificando o commit. O id do nó, o label e o
  nome do grafo `gmill-update-547-2026-10` seguem com nome privado, mas estão fora do alcance desta onda (P6
  da O4). A REGRA 30 (Segurança de PROJEÇÃO: nome comercial de membro privado não sai)
  não olha refs.

## Tetos

- Não reli a prosa inteira dos 7 nós do librechat. Julguei pela classe e medi só um.
- Não reproduzi as contagens nos binários 2.1.258, 2.1.259, 2.1.286 e 2.1.289: essas versões não estão
  instaladas (`versions/` = 2.1.294..296).
- Não conferi os shas de `arandek`, porque a org `ArandekBR` não é alcançável com o token.
