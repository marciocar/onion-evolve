---
title: "Vaultwarden + Logto é viável e o único bloqueador caiu na medição — mas o SSO entrega conveniência de login, nunca redução de segredo"
date: 2026-08-10
kg: docs/evolution/research/vaultwarden-logto-2026-08/vaultwarden-logto-2026-08.kg.yaml
run_id: "NÃO MEDIDO"
tokens: "NÃO MEDIDO"
agents: "NÃO MEDIDO"
duration_min: "NÃO MEDIDO"
genre: decision
mode: decision
review_after: 2026-09-09
---

# Vaultwarden + Logto — viável, com expectativa calibrada

> **Projeção** do grafo (12 nós, 12 arestas, radar exit 0). `date` vem de `meta.date` do grafo (2026-08-10), que coincide com `meta.baseline` e com o `verified_at` de todos os nós que o carregam. Grafo `layer: audit`, três frentes declaradas em `meta.note`: estado externo do produto/SSO, terreno medido na VPS e uma verificação focada que só existiu porque as duas primeiras discordaram.

## Custo declarado

| Item | Valor |
|---|---|
| Tokens | NÃO MEDIDO |
| Agentes / workers | NÃO MEDIDO |
| Parede | NÃO MEDIDO |
| run_id | NÃO MEDIDO |

Onde procurei: `meta` do grafo (sem campos de custo); a pasta (só o `.kg.yaml`); `git log --all -S 'vaultwarden-logto-2026-08'` (1 commit, `ba29f6eb`, PR #575) e o corpo dos commits que tocaram a pasta (`ba29f6eb`, `775569f1`/`52ca3e64`, `c9d0c87b`) — nenhum declara custo da pesquisa; grep do slug em `docs/` e `.claude/` (zero fora da própria pasta). O resíduo `docs/evolution/review/fix-fixture-nao-depende-do-vivo.md` declara `tokens: 92072` e `duration_min: 12`, mas é a passada adversarial do PR #575 (fixture da bancada e guarda de `pgrep`), **não** a pesquisa — não atribuível a este run. `genre`/`mode` foram inferidos da forma do grafo (um nó `decision` de viabilidade como veredito); a pesquisa é anterior ao workflow `/onion-research` e não traz modo declarado.

**Revisita vencida.** O grafo não tinha `review_after`; escolhi 30 dias (cadência de *ferramenta* pela REGRA 67 (Grafo de pesquisa com REVISITA carimbada (meta.review_after))), porque o conhecimento dominante é estado de produto — releases, PRs abertos, CVEs e issues do Vaultwarden e do Logto. A partir de 2026-08-10 isso dá 2026-09-09, que já passou em relação a 2026-09-13. A linha foi gravada também em `meta.review_after` do grafo.

**O SOFT é intencional.** Pela baseline anterior à REGRA 67, o grafo estava isento dela. Com `meta.review_after` carimbado e já vencido, o lint passa a emitir SOFT "revisita VENCIDA" para este grafo a partir do merge. A data não foi empurrada para silenciar o aviso: o conhecimento **é** caduco (PR #7534 aberto, cadência de CVEs de SSO, versão obrigatória de cliente), e o SOFT é o sinal verdadeiro. A cura é a revisita, não a data. O gatilho está no Backlog.

## Veredito

**Viável: o único bloqueador candidato caiu na medição** (`D_VIAVEL_COM_EXPECTATIVA_CALIBRADA`, confidence 0.9). A condição é de expectativa, não de configuração. Integrar o Logto **não tira um segredo do mundo, adiciona um sistema ao caminho**. A senha mestra continua sendo o único segredo raiz do cofre (`C_SSO_NAO_REDUZ_SEGREDO`, confidence 1.0). O ganho real é operacional: provisionar e desprovisionar num lugar só, com botão único de login. O grafo registra que isso tem a mesma forma do INVARIANTE 0 do onion-pessoal: é propriedade a preservar, não limitação a contornar.

O SSO foi **provado pelo fluxo, não pela variável** (`E_SSO_VALIDADO_PONTA_A_PONTA`): o cofre redireciona ao Logto com PKCE S256 e o Logto devolve a tela de login da aplicação certa. Com `SSO_ONLY=false` por desenho.

## Achados por tema

### A tese que decide: SSO não substitui a senha mestra
- `C_SSO_NAO_REDUZ_SEGREDO`: a wiki oficial do Vaultwarden diz que a senha mestra segue exigida e fora do controle do SSO. Num cofre zero-knowledge a chave de cifra deriva dela no cliente, então comprometer a sessão do IdP permite *tentar* entrar, nunca ler o cofre.
- `E_SEM_EQUIVALENTE_A_KEY_CONNECTOR` (SUPPORTS a tese): o que fecharia o buraco não existe no Vaultwarden. Key Connector (Bitwarden Enterprise) não tem equivalente nem no roadmap. Trusted Device Encryption é o PR #7534, **aberto** desde 2026-07-31. No desenho atual, a senha mestra é permanente.

### O bloqueador que só apareceu no cruzamento
- `E_ES384_ERA_O_BLOQUEADOR_CANDIDATO` (**refuted**): a discovery viva do Logto declara só ES384, sem RS256. Esse padrão já quebrou outros clientes OIDC. Nenhuma das duas frentes achou isso sozinha, e a lição de método registrada é que duas passadas independentes que **discordam** são sinal.
- `E_ES384_CAIU_NA_MEDICAO` (REFUTES o anterior): o doc-comment da crate `openidconnect` 4.0.1 diz que P-384 não é suportado, mas o código (`verify_ec_signature` com `p384::ecdsa::VerifyingKey`) verifica de fato. Só P-521 cai. É `declarado != verificado` dentro de uma dependência de terceiro. Há ainda uma rede independente: o Logto permite trocar a chave para RSA.
- `E_SSO_VALIDADO_PONTA_A_PONTA` fechou a questão em produção: o ES384 passou sem ruído. O nó registra duas armadilhas do teste que pareciam defeito e não eram: `aud` inválido por base de chamada errada, e `code_challenge` curto demais para o PKCE. O erro era do teste.

### Maturidade
- `E_SSO_MADURO_MAS_JOVEM`: o SSO já não é fork. O PR #3899 foi mesclado no upstream em 2025-08-08, e a 1ª release estável com SSO é a v1.35.0 (2025-12-27). Em seis meses saíram correções de vários CVEs específicos de SSO, e a v1.37.0 é obrigatória para clientes ≥2026.7.0. Uso em produção pede acompanhar as releases de perto. Fricções abertas: #7072 e #6826.
- `E_PRIMEIRO_CASO_DOCUMENTADO` (**superseded**): não havia relato público de Vaultwarden + Logto. `E_SSO_VALIDADO_PONTA_A_PONTA` o REFUTA, porque passou a existir o primeiro caso.

### O terreno
- `E_TERRENO_E_COPIAVEL`: o padrão já está escrito como KB canônica (`docs/knowledge-base/tools/vps-tool-repo-skeleton.md`) e roda em três repos. Os pontos obrigatórios são bind em loopback (o Docker fura o ufw nesta máquina), segredos fail-closed, `mem_limit` explícito, vhost validado antes de aplicar e backup com integridade. Não há registry central, por decisão.
- `Q_QUATRO_PENDENCIAS_DO_TERRENO` (**done**): as quatro pendências foram pagas e verificadas por comportamento:
  1. DNS criado com `overwrite:false`.
  2. Backup cifrado com prova de restauração.
  3. Fail2Ban provado com ataque real. A jail nasceu muda: lia o journal e ignorava o `logpath`.
  4. Cabeçalho de IP real, sem o qual a jail baniria o loopback.

  Lição do nó: *guarda lendo o lugar errado é indistinguível de guarda funcionando*.

### Colaterais de produção (não são sobre Vaultwarden)
- `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO` (**open**): na medição de 2026-08-10, o console do IdP estava ativo, contra três documentos que o declaravam desligado. A decisão é do maestro.
- `I_PROVISION_FICOU_PARA_TRAS_NO_RENAME` (**open**): uma variável morta e duas strings de diagnóstico tinham o nome de container anterior ao rename. O nó também corrige o diagnóstico inicial de um agente, que alegava um caminho de execução quebrado que não existia.

## NÃO-VERIFICADOS

6 nós, derivados dos critérios open, refuted/superseded, sem `verified_at` e confidence < 1.0:

1. `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO`: **open**, decisão pendente do maestro.
2. `I_PROVISION_FICOU_PARA_TRAS_NO_RENAME`: **open** e **sem `verified_at`**.
3. `E_ES384_ERA_O_BLOQUEADOR_CANDIDATO`: **refuted** por `E_ES384_CAIU_NA_MEDICAO`.
4. `E_PRIMEIRO_CASO_DOCUMENTADO`: **superseded**, confidence 0.9. Carrega uma ressalva própria ainda não fechada no grafo: `offline_access` "merece teste específico".
5. `C_SSO_NAO_REDUZ_SEGREDO`: confirmed, mas **sem `verified_at`**. O `trace` aponta para a wiki do produto.
6. `D_VIAVEL_COM_EXPECTATIVA_CALIBRADA`: confirmed, **sem `verified_at`**, confidence 0.9. O rótulo lista três itens GATED no maestro, e o resto do grafo os deixa em estados diferentes:
   - "criar o DNS": pago, segundo `Q_QUATRO_PENDENCIAS_DO_TERRENO`;
   - "decidir sobre o console aberto": **não pago**, continua em `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO` (open);
   - "backup de cofre exige cifra em repouso + saída da máquina": **pago pela metade**. A cifra em repouso foi paga, com prova de restauração. A saída da máquina **não** foi: o próprio `Q_QUATRO_PENDENCIAS_DO_TERRENO` diz que o backup "ainda mora no mesmo disco".

   O rótulo ficou atrás do grafo só no item do DNS.

Limite declarado dentro de um nó `done`, sem nó próprio neste grafo: o backup cifrado "ainda mora no mesmo disco" (`Q_QUATRO_PENDENCIAS_DO_TERRENO`). É a metade "saída da máquina" do item GATED de `D_VIAVEL_COM_EXPECTATIVA_CALIBRADA`.

## valeu-a-pena

**Não computável.** A razão tokens ÷ nós exige os dois valores, e só um foi medido: há 12 nós, mas os tokens do run não foram registrados em nenhum lugar atribuível a esta pesquisa (ver *Custo declarado*). Os 92.072 tokens do resíduo do PR #575 são de outra passada e não entram na conta.

## Backlog

| Nó | Ação que pede |
|---|---|
| `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO` | decisão explícita do maestro sobre o console do IdP; depois, carimbar o nó |
| `I_PROVISION_FICOU_PARA_TRAS_NO_RENAME` | re-verificar e selar: medi que os sítios já usam o nome atual; falta carimbar com `verified_at` e fechar |
| `D_VIAVEL_COM_EXPECTATIVA_CALIBRADA` (item GATED) | saída do backup cifrado para fora da máquina; ainda não paga no grafo |
| grafo inteiro (REGRA 67 (Grafo de pesquisa com REVISITA carimbada (meta.review_after))) | **revisita vencida** desde 2026-09-09. Gatilho: o SOFT "revisita VENCIDA" do lint, a partir do merge. Cura: `/meta:kg-freshness` nos nós PROD e `/onion-research --revisit` no externo (PR #7534, releases e CVEs de SSO), depois carimbar um novo `review_after` |

⚠️ **Drift entre grafo e vivo** (medido por mim em 2026-09-13, fora do grafo, **não carimbado**): em `ops/bridge-auth/logto-provision.sh`, a variável já tem o nome `onion-vps-…` e está em uso (l.50 e l.166, via `grep -n`). Em `/etc/caddy/conf.d/`, o vhost do console hoje tem sufixo `.disabled`. Ou seja, os dois nós open parecem resolvidos no vivo, mas o grafo segue `open`. Quem fecha é `/meta:kg-freshness` ou o selo do maestro, não esta projeção. Existe também um resíduo `docs/evolution/review/docs-console-ativo-por-decisao.md` que registra uma decisão de manter o console ativo, o que diverge do estado `.disabled` medido hoje. A sequência entre os dois não está no grafo.
