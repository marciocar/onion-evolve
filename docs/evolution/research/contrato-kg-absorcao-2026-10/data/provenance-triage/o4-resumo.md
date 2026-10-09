# Onda O4 — proposta do proponente (SAC-73)

> **Papel:** proponente. Esta onda **não edita grafos e não abre PR**; um juiz independente refuta depois.
> Base: `origin/main` em `cffe09fe` (2026-10-09). Planilha: [`o4-proposta.csv`](o4-proposta.csv), com 258 linhas e
> uma linha por (nó, regra). Há 38 nós que aparecem nas regras 1 e 2.

## Contagens

| Regra | Proposta | Linhas | Observação |
|---|---|---:|---|
| 1. Testemunho em PROD vai a DEV | `dev-historia` | 116 | `plane: PROD → DEV`, status intocado |
| 1 | `manter-prod-medido` | 5 | medidos HOJE, com comando e saída na planilha |
| 2. Caminho de máquina sai da `source` | `reescrever-source` | 137 | 112 do grep do brief e 25 fora dele (ver abaixo) |
| 3. `corrigir-label` sobre journal leva `host` | `add-locality` | **0** | nada faltando (ver abaixo) |

**Universo da regra 1, medido:** `kg_validate.py --where` sobre os 146 `.kg.yaml` versionados fora de `fixtures`
devolve **122 ocorrências em 37 grafos**, e não as 121/36 do brief. A diferença é a única exceção selada que
ainda está no universo, `E_MEDIDO_BLOAT_DO_PROPRIO_CORE_1001`, que ficou fora da planilha. As outras cinco
exceções seladas (`D_AGREGACAO_CROSS_REPO_E_MOAT`, `E_GIT_DIR_QUEBRA_A_RAIZ_DENTRO_DE_WORKTREE`,
`D_CORTE_E_TUDO_INCLUSIVE_META_FABRICA`, `D_VEICULO_STANDALONE_PUBLICO_MAIS_ADOPT` e `E_FABLE_REVIEW`) já
**não disparam** `integrity.testimony-in-prod`. Sobram 121 decididas em 36 grafos.

**Regra 2 por locality proposta:** `host` 91, `repo` 41 e `web` 5.

## Os 5 `manter-prod-medido`, com a medição

| Nó | Comando (2026-10-09) | Saída |
|---|---|---|
| `E_PRIMITIVE_EXISTS` | `projection-safety.sh --terms <1 termo> <alvo>` e `--terms <vazio>` | rc=1 REPROVA no vazamento; rc=1 "lista vazia" |
| `C_MATERIALIZADOR_LE_O_REGISTRO` (refuted) | `grep -niE "members\|federation/" ops/materialize-door.sh` | só comentário, echo e heredoc: o script segue sem ler o registro |
| `A_relatorio_evolve` | `test -f` e `grep projeção` no relatório | existe, e as linhas 17-18 o declaram projeção do grafo |
| `C_POSTURA_ACOPLAMENTO` | `grep -n "mantendo independência sempre que" CLAUDE.md` | linha 25 do CLAUDE.md vigente |
| `SY6_ev_settings_presentes` | `ls -la` dos dois settings e `git log --diff-filter=D` dos templates | os dois existem; os templates foram deletados em `3d2cc9c7`; locality `host` (settings.local é gitignored) |

## Drift achado ao medir (vão a DEV com a medição na evidência)

- **`Q_ONION_KG_MCP_NEXT`:** o nó diz "MCP onion-kg VIVO", mas `systemctl is-active onion-vps-mcp-kg` devolve
  **inactive** (unit disabled, dead). Isto também é **sinal para o maestro**: ou o serviço caiu, ou foi
  desligado sem nó.
- **`C_TIER_HUB_E_CAPACIDADE`:** o apoio do nó ("metagamify é hub") caiu. A linha 73 do `members.yaml` diz
  `standalone` desde 2026-10-07, e a `onion-core` vira `source` na F2.
- **`D_EMAIL_SUPORTE_E_MARCIO_ARROBA`:** o destino declarado (`author.email` dos plugin.json) não existe no
  vivo, porque nenhum `plugin.json` tem email.
- **`ENT_whatsapp`:** o WAHA está vivo (`Up 4 weeks`, `127.0.0.1:3999`), mas o "running desde 2026-08-05" do label já não vale.
- **`E_GREP_TRACE`:** `next_recommended` aparece hoje em 4 `.kg.yaml`; era zero em `0923bd88^`.

## Regra 2: como os 137 se distribuem

- **Harness, sem versionamento** (journal `wf_*`, transcrito `.jsonl`, plano, memória, binário do Claude Code,
  scratchpad, `.claude/sessions/`): a `source` passa a descrever sem caminho, como em `journal wf_xxx (host)`,
  com `method: testemunho: … no host <data>` e `locality: host`.
- **`onion-bridge`:** o remoto `marciocar/onion-bridge` **só começa em `c22517ee` (2026-07-27 14:01 -03)**, e o
  estado de produção pós-flip só foi versionado em **`38702f00` (2026-08-01)**. Por isso:
  - os nós de 07-26 a 07-28 vão a `host`. O arquivo daquele instante não está no remoto: `c22517ee` já traz
    OIDC/PKCE na PWA e **não sustenta** `C_pwa_has_no_pkce`;
  - de 08-01 em diante, quando a claim é sobre **código**, a forma é `onion-bridge@<sha>:<path>` com `leitura`
    e `repo`, e o sha vem de `gh api commits?path&until=<data>`;
  - quando a claim é sobre **comportamento** (demo, sonda, rotas vivas, token, `.env`, qual commit roda), a
    proposta é `host`, porque o arquivo citado era só ponteiro.
- **Outros repos com remoto:** `onion-logto`, `onion-waha`, `onion-vps-vaultwarden`, `poc-venda-direta-pdi`,
  `onion-adopt-arandek-local` e `arandek` usam `<repo>@<sha>`. Os shas foram conferidos com
  `gh api commits/<sha>`, menos os da org `ArandekBR`.
- **REGRA 30 (Segurança de PROJEÇÃO: nome comercial de membro privado não sai):** a pasta do host
  `/home/marcio/gmill` foi trocada pelo id **`hub-operacoes-enterprise`**, e a `rhilo-metagamify` pelo id
  **`metagamify`**. Rodei `projection-safety.sh` sobre a planilha: rc=0.
- **CHANGELOG com "cópia local"** (8 nós): saiu só o trecho da cópia do host; a `source` fica sendo a URL
  pública. A locality vira `web`, ou `repo` quando a source também cita um arquivo versionado.

## Regra 3: o que falta é zero

Dos 107 `corrigir-label` dos juízes das ondas 2 e 3, **16 se apoiam em journal do host e os 16 já estão com
`locality: host`**. O passe da v4.2 cobriu todos. Outros 4 citam journal, mas estão corretamente em `repo`:
o journal está ausente do host, ou versionado em `data/`, e a base real é um arquivo do repo. Na varredura do
corpus inteiro, o único nó com journal de host em `locality ≠ host` é `E_MERCADO_WHATSAPP_REVISITA_20260903`,
e o method dele diz "journal não preservado", com source no repo. Também está certo. Os 3 `corrigir-label` sem
locality que citam caminho de host (`D_FASE_ID_CONTEINER_DE_IDENTIDADE`, `Q_EMBEDDINGS_KEY_PENDENTE` e `C_V1`)
ganham locality pelas linhas da regra 2.

## Casos difíceis

1. **`E_LSTREE_MAIN_0717` diverge da amostra.** A amostra mandava tratar a parte metagamify como testemunho
   `host`, mas `bfb9bce2` **existe** no remoto `marciocar/metagamify` (gh api, 2026-06-26). A proposta é
   `onion-evolve@fb08cc6b:.claude + metagamify@bfb9bce2:.claude`, com `method: medição` e `locality: repo`. O
   juiz decide se a amostra prevalece.
2. **Binário do Claude Code** (`E_REEXTRACAO_2_1_295_SO_NOMES`, `E_MEDIDO_LOCAL_TIER10_NO_PROPRIO_REPO`). Os
   dois já têm `medição:` sobre um binário identificado por versão. Mantive o `method` e pus `locality: host`.
   A regra literal pediria `testemunho`, mas a medição se reproduz em qualquer host com a mesma versão.
   Confiança 0.6.
3. **`onion-vps-librechat` tem sha, mas não tem remoto** (7 nós). Pela regra, isso dá `host` e `testemunho`,
   embora haja um commit local identificado.
4. **Comportamento × arquivo no bridge e no Logto** (`E_p0_logto_tenant_measured`,
   `E_logto_tenant_provisioned_2026_08`, `E_pull_endpoint_works`, F-ID e demo). A `source` antiga apontava
   arquivo, mas a medição foi no banco ou no serviço vivo. Propus `host` descrevendo a medição, e não
   `repo@sha` do arquivo-ponteiro.
5. **`C_allowedtools_does_not_restrict`:** a claim é sobre os tipos do SDK, não sobre código do bridge. Propus
   `npm @anthropic-ai/claude-agent-sdk@0.3.195`, com `web`. O `5c6e2cfb` confirma que a produção estava em
   0.3.195.
6. **Decisões seladas pelo maestro** (7 nós, como `D_R2_EMENDAS_A_C_SELADAS` e `D_SEM_CREDITO_POR_ORA`). O ato
   é imutável, mas o estado que a decisão regula não foi conferido hoje. Pela regra de classe, vão a DEV.
7. **`C_bypass_permissions_exposto` (claim open, segurança).** Para conferir hoje seria preciso ler o `.env` de
   produção, e a ordem é nunca ler `.env`. Vai a DEV, mas o risco que descreve **pode estar vivo**.
8. **`Q_GMILL_MAIN_DIVERGIU` e o grafo `gmill-update-547-2026-10`** carregam o nome da pasta privada no **id do
   nó e no nome do arquivo**, fora da `source`. O O4 não mexe (fora de escopo), mas a REGRA 30 não olha ids.

## Propostas ao maestro (regras novas, NÃO aplicadas)

- **P1. `locality: repo` para repo ALHEIO.** O enum v4.2 define `repo` como "versionado no **próprio** repo".
  A regra 2 usa `repo` também para `onion-bridge`, `onion-logto` e adotantes. Pergunta: precisa de valor
  próprio, ou de um prefixo `<repo>@` obrigatório?
- **P2. Repo local sem remoto, mas com sha:** é `host` ou é `repo`? Hoje é `host` (caso 3).
- **P3. Binário identificado por versão:** `medição` com `locality: host` deveria ser aceita sem cair na
  classe testemunho (caso 2)?
- **P4. Comportamento medido no host com código versionado:** a `source` aponta o que foi medido (serviço ou
  banco), e o código vai ao `locator`. Hoje é convenção minha, não regra (caso 4).
- **P5. O grep da regra 2 só pega `/home/` no INÍCIO da `source`.** Há mais 25 com o caminho no meio, e eu os
  incluí, marcados `[fora do grep do brief]`. A regra deveria nomear a classe ("qualquer caminho absoluto na
  `source`"), e não a forma.
- **P6. Ids e nomes de grafo com nome comercial** (caso 8): a REGRA 30 só olha projeção, não id.
- **P7. `Q_ONION_KG_MCP_NEXT`:** o serviço está `inactive`. Ou isso vira nó novo (o MCP caiu ou foi
  desligado), ou é confirmar que foi ato do maestro.
