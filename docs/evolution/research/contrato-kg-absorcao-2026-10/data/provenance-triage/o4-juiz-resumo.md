# Onda O4: veredito do juiz independente (SAC-73)

> **Papel:** juiz. O mandato era refutar: na dúvida, reprovado. Não escrevi a proposta, não editei grafos e não
> mexi na planilha do proponente. Base: worktree `feat/provenance-wave-o4` sobre `5651b891`, em 2026-10-09.
> Planilha: [`o4-juiz.csv`](o4-juiz.csv). Ela tem as **258 linhas julgadas e mais 11 linhas acrescidas**, que
> são omissões do proponente marcadas `proposta_original = (omitida)`.

## Concordância

| Regra | Linhas | APROVADO | CORRIGIDO | REPROVADO |
|---|---:|---:|---:|---:|
| 1. Testemunho em PROD (`dev-historia` / `manter-prod-medido`) | 121 | 121 | 0 | 0 |
| 2. Caminho absoluto sai da `source` | 137 | 106 | 31 | 0 |
| **Total julgado** | **258** | **227 (88,0%)** | **31 (12,0%)** | **0** |
| Omissões acrescidas (regra 2: 8; regra 3: 3) | 11 | — | 11 | — |

Na regra 1 a concordância é total. Reproduzi o universo com
`kg_validate.py --where` sobre os 146 `.kg.yaml` fora de `fixtures`: dá **122 ocorrências de
`integrity.testimony-in-prod`**. O conjunto delas, menos `E_MEDIDO_BLOAT_DO_PROPRIO_CORE_1001`, é **idêntico**
às 121 linhas da regra 1, sem nenhuma a mais ou a menos. Nenhuma das 6 exceções seladas aparece na planilha.

### Os 5 `manter-prod-medido`, reproduzidos

Todos foram aprovados com a condição de o `verified_at` passar a 2026-10-09.

| Nó | Comando do juiz | Saída |
|---|---|---|
| `E_PRIMITIVE_EXISTS` | `projection-safety.sh --terms` com termo sintético, lista vazia e alvo limpo | rc=1 REPROVA · rc=1 "lista vazia" · rc=0 (controle negativo) |
| `C_MATERIALIZADOR_LE_O_REGISTRO` | `grep -niE "members\|federation/" ops/materialize-door.sh` | só l.10 e l.50 (comentário), l.67 e l.71 (echo) e l.434 (heredoc) |
| `A_relatorio_evolve` | `test -f` + `grep -n projeção` | existe; l.4 `kg:` aponta o grafo; l.18 "projeção" |
| `C_POSTURA_ACOPLAMENTO` | `grep -n "mantendo independência sempre que" CLAUDE.md` | l.25 |
| `SY6_ev_settings_presentes` | `ls -la` dos dois settings + `git log --diff-filter=D` | 5869 B e 7137 B; deletados em `3d2cc9c7` (2026-06-14) |

### As 5 divergências que foram a DEV, reproduzidas

- `Q_ONION_KG_MCP_NEXT`: `systemctl is-active` devolve **inactive** e `is-enabled` devolve **disabled**.
- `C_TIER_HUB_E_CAPACIDADE`: a l.73 do `members.yaml` diz `role: standalone`.
- `E_GREP_TRACE`: `next_recommended` aparece em 4 arquivos hoje e em 0 em `0923bd88^` (rc=1).
- `ENT_whatsapp`: `Up 4 weeks` em `127.0.0.1:3999`.
- `D_EMAIL_SUPORTE_E_MARCIO_ARROBA`: nenhum `plugin.json` tem email. **Ressalva:** o juiz da O3 já registrou que
  o `author` só com `name` é coerente com "só entra depois do passo (3)". A ausência pode ser **por desenho**, e
  não drift. O DEV continua certo, mas a "drift" do resumo do proponente está mal qualificada.

### Pontos específicos pedidos

- **`E_LSTREE_MAIN_0717`: APROVADO.** Reproduzi `ls-tree fb08cc6b -- .claude` = **399** e `bfb9bce2` = **239**.
  O `bfb9bce2` existe em `marciocar/metagamify` e é o `main` até 2026-07-17 (`gh api …&until`). Pela regra 2
  selada, remoto alcançável dá `repo`, e isso prevalece sobre a amostra.
- **onion-bridge de 26 a 28/07: APROVADOS em `host`.** Até 08-02, o remoto tem só `c22517ee` (07-27 17:01Z) e
  `38702f00` (08-01). Confirmei que `c22517ee` já traz `web/src/auth/oidc.ts`, o que não sustenta
  `C_pwa_has_no_pkce`. O argumento do proponente se sustenta.
- **Shas do onion-bridge de 08-01 em diante:** os 30 conferidos existem no remoto. Onde a claim é sobre
  código, o sha é o último commit do arquivo até a data, ou o commit que o próprio nó cita.

## Correções: padrões de erro

1. **Convenção (a) aplicada de modo inconsistente (10).** Demo, sonda e role do Logto foram corretamente para
   `host`. Mas as **7 fases de deploy** (`F0`–`F5`, `F_ID_1`, `F_ID_2_CONTEXTOS_ORG`) foram para `repo` com
   `leitura:`, embora o locator delas descreva **deploy medido no serviço** (health, rotas 401/404/429, ataques).
   Isso **promove um ponteiro derivado na migração** (rota A2, "não reverificado") a leitura de código. Corrigi
   para `host`, com a source descrevendo a medição e o código no locator. Em `F_ID_1` troquei `83033b25`, que é
   da F-ID.2, por `2e10b497`, o deploy que o locator nomeia. Também acrescentei o código ao locator onde a
   proposta o descartou: `E_SONDA_…` e `E_pull_endpoint_works`. Em `Q_ONION_KG_MCP_NEXT`, o código saiu da
   source.
2. **Promoção de método sem base (1, mais as 7 acima).** `I_SEGUNDO_IDP_COM_CONSOLE_DESTRANCADO` passou de
   `testemunho:` a `leitura:` num relato em 1ª pessoa de medição sem comando.
3. **"sha da data do nó" sem conferir a data (4).** `D_engine_noweb_confirmed` cita `onion-waha@86662e01`, que
   é o **único** commit do remoto e é de 08-02T23:22Z, um dia **depois** do nó. `E_GAP2_ZERO` usava `HEAD`.
   `E_CENSO0901_Q_ARANDEK_UPDATE` e `E_LSTREE_METAGAMIFY_0804` ficaram sem sha. Reproduzi as medições
   (`merge-base` rc=0, lista de pins, 239 arquivos) e ancorei em `onion-evolve@5c40b1cc`, `arandek@cd682ac4`,
   `arandek@611329a1` e `metagamify@bfb9bce2`.
4. **Regra 3 selada ignorada (1, mais 3 omissões).** O proponente **renumerou as regras**: a "Regra 3" dele é a
   5 do maestro. Por isso tratou o binário como caso difícil (P3) e escreveu que "a regra literal pediria
   testemunho". **Isso é falso**: a regra 3 selada manda `medição` com `host`. `E_OBJECAO_EXIT2_E_PRIMITIVO_GRATIS`
   ficou com `testemunho`. `E_ESTUDO_O_CLAUDE_CODE_RECUSA_O_QUE_NAO_PROVA` e os dois `E_BINARIO_2_1_258_*`
   nem entraram.
5. **Regra 2 ampliada lida como "/home" (8 omissões).** O grep do proponente, mesmo estendido ao "meio" da
   string (a P5 dele), só via `/home`. Ficaram de fora `/etc/caddy`, `/etc/systemd`, `/var/run`, `/usr/sbin` e
   `/tmp/claude-1000`, em `E_MEDIDO_ESTADO_VIVO_1005`, `E_OBJECAO_CHECKRESTART_AUSENTE`,
   `E_OBJECAO_LIVEPATCH_CRUZAR_SINAIS`, `C_tunneling_nome_errado`, `E_ancestor_floor_applied`,
   `C_console_not_the_path`, `E_floors_effective_measured_20260729` e `E_AS_GUARDAS_DO_FANIN_SAO_LOAD_BEARING`.
   O corpus tem **145** sources com caminho absoluto, e a planilha cobria 137.
6. **Afirmação sem medir (7).** "onion-vps-librechat sem remoto" é falso: há um `origin`, só que ele **aponta
   para `marciocar/onion-bridge.git`**, e os commits do librechat não existem lá (`gh api` 422). `host` continua
   certo, mas pela razão "sem remoto **alcançável**".
7. **Resíduo de replace mecânico (14).** Há "journal journal" em 5 linhas, "testemunho: leitura:" em 7, a pasta
   `onion-bridge-dev` no method de `E_CONVITE_…` e `onion-vps-logto` no de `I_UPGRADE_…`. Também há uma
   **contradição entre as duas linhas de `SY6`**: o method da regra 2 é a medição de hoje, mas o locator dela
   era o de 07-21.
8. **Contagem da regra 5 (corrigir-label sobre journal).** A conclusão "nada faltando" se mantém, mas os números
   não: o proponente diz 107/16/4, e eu meço **123** `corrigir-label` nos juízes das ondas 2 e 3, dos quais 19
   citam journal, **14** em `host` e **5** corretamente em `repo`.

## Itens para o maestro

Nenhum foi aplicado. As regras novas abaixo são **propostas**.

- **M1. Segurança, abertos e indo a DEV:** `C_bypass_permissions_exposto`, `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO` e
  `Q_JWKS_REFETCH_STORM_SEM_PISO_NA_FALHA`. DEV aqui quer dizer "não conferido", **não "resolvido"**: o risco
  pode estar vivo e pede medição viva por quem pode olhar (a ordem de não ler `.env` vale).
- **M2.** O MCP `onion-vps-mcp-kg` está **inactive e disabled**, e nenhum nó registra o desligamento. É nó novo
  ou ato a confirmar.
- **M3 (regra nova).** Estender "nenhum caminho absoluto" a **`locator` e `method`**: depois da O4, **62 nós**
  ainda carregam caminho absoluto nesses campos.
- **M4 (regra nova).** Interação da regra 1 com a regra 3: uma medição sobre binário de **versão fixa** é fato
  sobre artefato imutável. A proposta é que ela possa ficar em PROD com a versão no locator. Hoje os
  `E_BINARIO_2_1_258_*` estão em PROD e `E_ESTUDO` vai a DEV. Mantive os dois como estão.
- **M5.** Endosso a P1 do proponente: hoje `locality: repo` mistura o repo próprio com o alheio. O prefixo
  `<repo>@` obrigatório já desambigua, e pode virar regra.
- **M6.** Endosso a P6: ids de nó e nomes de grafo com nome de pasta privada (`Q_GMILL_*`, `gmill-update-547-*`)
  ficam fora do alcance da REGRA 30 (Segurança de PROJEÇÃO: nome comercial de membro privado não sai).
- **M7.** Em `E_floors_effective_measured_20260729`, o `verified_at` é 2026-08-29 e o label diz 07-29.
- Descarto a **P3** do proponente: a regra 3 selada já responde.

## Achados fora da provenance

- **`onion-vps-librechat` tem `origin` = `git@github.com:marciocar/onion-bridge.git`.** Um `git push` ali
  mandaria a história do librechat para o repo do bridge. Sugiro corrigir ou remover o remote.
- **O reboot do host segue pendente:** `/var/run/reboot-required` está datado de 2026-09-24 e o kernel em uso
  ainda é o 6.8.0-139. É o mesmo estado que `E_MEDIDO_ESTADO_VIVO_1005` registrou em 10-05. Fica como
  sinal, sem ação proposta sobre ferramenta.
- No 2.1.296 instalado, o default de `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` segue **20**. O padrão de regex do
  teto de WebSearch (200) **não casou** no 2.1.296. Não sei dizer se mudou o valor ou só a forma do binário,
  então fica não medido.
- `wf_87c4a44e-0ff`, citado no locator de `E_default_deny_never_existed`, **não existe** no host (`find` vazio,
  rc=0). Os 15 journals usados como source existem.

## Tetos (o que o juiz NÃO fez)

- Não li o conteúdo de cada journal ou transcrito. Conferi só que os 15 journals de source existem.
- Não reproduzi as contagens dos binários 2.1.286 e 2.1.258, porque as versões não estão mais instaladas.
- Na regra 1 julguei pela classe: universo reproduzido, exceções conferidas e as 10 medições reproduzidas. Não
  reli a prosa inteira dos 116 nós `dev-historia`.
- Não conferi o `.env` de produção nem o banco do Logto. Por ordem, isso fica fora.
