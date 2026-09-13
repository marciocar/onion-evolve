---
title: "Gates do Onion: a sessão tinha um único veto, o merge em main virou o segundo, e as catracas de atestação seguem confiança no modelo"
date: 2026-09-02
kg: docs/evolution/research/audit-textual-gates-2026-09/audit-textual-gates-2026-09.kg.yaml
run_id: "NÃO-APLICÁVEL"
tokens: 1900000
agents: 3
duration_min: 95
genre: validation
mode: audit
review_after: 2026-12-31
---

# Gates do Onion: veto mecânico, aviso textual ou confiança no modelo

> **Projeção** do grafo (25 nós, 31 arestas, radar `--integrity --schema` exit 0). Execução da `D_AUDITAR_GATES_TEXTUAIS` (grafo `fable-5-1-superacao-2026-09`), selada pelo maestro em 2026-09-02. `date` vem de `meta.baseline: 2026-09-02`, que é também o `verified_at` de 20 dos 21 nós carimbados (o 21º, `E_O_VERDICT_GANHOU_VOCABULARIO_MAS_NAO_VERIFICACAO`, é de 2026-09-09). `review_after` repete `meta.review_after` do grafo.

## Custo declarado

| Item | Valor | Origem |
|---|---|---|
| Tokens | 1.900.000 | frontmatter de `docs/analysis/onion-gates-textuais-2026-09.md` e do resíduo `docs/evolution/review/audit-textual-gates.md`. A própria projeção decompõe o total como aproximado — l.149, literal: "~1,9M tokens (3 workers read-only ≈ 0,9M + contexto principal ≈ 1,0M)" —, então é **declaração do run**, não contagem de workflow |
| Agentes | três workers read-only (sonnet/medium) + o contexto principal | mesmos dois arquivos; `meta` do grafo nomeia os 3 workers |
| Parede | 95 min | mesmos dois arquivos |
| run_id | não se aplica | não passou pela ferramenta Workflow: foram teammates mais probes e bancada no contexto principal (`meta` do grafo). O corpo dos commits `943ca1d5`/`5cf7dc39` também não traz id |

Onde procurei: o `meta` do grafo (sem custo), a pasta (só o `.kg.yaml`), `git log --all -S 'audit-textual-gates-2026-09'` (4 commits: `943ca1d5`/`5cf7dc39` criaram o grafo; `57fff2af`/`931ecd34` só citam o slug em texto e não tocam a pasta), os corpos dos commits que tocaram a pasta (os de criação, mais `badb5707`/`8e251772` da F1 da lente de pesquisa e `61fc1a74`/`be29ab00` da R0 de 09-09). Nenhum traz custo atribuível a esta rodada: o `61fc1a74` declara "16 workers, 1,24M tokens, 14,7 min", mas esse é o custo da R0 inteira (16 nós re-medidos), que aqui acrescentou 1 nó. Por fim, grep do slug em `docs/`. O custo só aparece na projeção em `docs/analysis/` e no resíduo de revisão.

Ressalva: o total pagou a rodada de 2026-09-02, quando o grafo tinha **24 nós** (corpo do `943ca1d5`). O 25º nó veio da R0 de 2026-09-09, e ela não entra nesse custo.

## Veredito

A pergunta `Q_GATES_TEXTUAIS` (done) foi respondida, e a resposta é que **antes da rodada a sessão tinha um único veto incondicional**. Era o `pretooluse-protect-main.sh`, que só barrava force-push (`E_VETO_UNICO_ANTES_DA_RODADA`). `gh pr merge N`, `git push origin main` e a REST de merge não tinham veto nenhum. A única barreira era o "PARE" escrito no `/meta:drive`.

No host, todo check de CI é **aviso**. O repo é privado sem Pro, a branch protection devolve 403 e `gh pr merge` com CI vermelho mergeia (`E_HOST_SEM_PROTECAO_CI_E_AVISO`). O único lugar onde o CI virava veto era `ops/pr-merge-verified.sh`, e usá-lo era voluntário.

A rodada curou com mecanismo e bancada, no mesmo PR:

1. **2º veto** (`E_CURA_MERGE_GATE_2O_VETO`): `pretooluse-merge-gate.sh` barra com exit 2 o merge e o push em main e aponta `ops/pr-merge-verified.sh`. O efeito de segunda ordem é que os HARD do lint e o revisor semântico viram **veto de fato no caminho da sessão**, sem branch protection. O grafo declara a fronteira: o hook se desarma no adotante, porque `/meta:adopt` copia `.claude/` e não `ops/`.
2. **Lib de invocação única** (`E_CURA_LIB_INVOCACAO_PARTILHADA`): antes, 8 invólucros (`command`, `\`, `env`, `exec`, `sudo -u`, `sh -c`, `$( )`, `git -C/-c`) passavam com rc=0 nos dois vetos (`E_BURACO_INVOLUCROS_NOS_DOIS_VETOS`). Fica declarado o teto de plataforma: `eval`, script em arquivo e o 2º nível de `-c` continuam invisíveis ao PreToolUse.
3. **Bancada dos vetos** (`E_CURA_BANCADA_DOS_VETOS`): 32 casos, 32/32.

A contagem depois do PR está em `C_CONTAGEM_POS_RODADA`. A rodada moveu o item de **maior consequência** (o merge), não a massa. A razão VETO:CONFIANÇA continua perto de 1:10.

## Achados por tema

### Atestação é confiança no modelo por construção

- Seis catracas do lint checam só **presença e formato** de campo escrito pelo próprio modelo (`E_CATRACAS_SAO_ATESTACAO_AUTODECLARADA`): REGRA 29 (Gate de PROVENIÊNCIA INVERTIDO, com catraca), REGRA 42 (Gate de FRESCOR DOUTRINÁRIO, com catraca), REGRA 49 (Nó plane:PROD de alto impacto carrega VERIFICAÇÃO, com catraca), REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial), REGRA 57 (O veredito do run está SELADO no grafo que ele julgou) e REGRA 58 (O backlog cumpre as promessas do próprio `meta:`).
- REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial): só `reviewed_diff_sha256` é conferido contra algo fora do controle do modelo (`E_REGRA56_VERIFICA_PRESENCA_NAO_VERDADE`, **superseded**, ver abaixo).
- REGRA 57 (O veredito do run está SELADO no grafo que ele julgou): nenhuma cláusula verifica **quem** selou (`E_KG_SEAL_NAO_SABE_QUEM_SELOU`).
- Não há cura determinística barata (`C_ATESTACAO_NAO_TEM_CURA_DETERMINISTICA`). A fonte externa ao modelo é o revisor externo, e o merge-gate o pôs no caminho crítico. O residual fica declarado.

### Leitura acha a classe, bancada acha as instâncias

- `C_BANCADA_ACHA_O_QUE_LEITURA_NAO_ACHA`: 3 workers lendo o corpus acharam a classe (invólucros). Três instâncias só apareceram na bancada: `HEAD:main` (`E_BURACO_HEAD_MAIN_NO_VETO_EXISTENTE`, um buraco no veto que existia havia 1 dia), `sudo -u` e `$( )`.
- A consequência doutrinária registrada é que gate sem bancada com casos de bypass é **VETO-DECLARADO**. O princípio já estava na REGRA 59 (Modo que a produção consome é exercitado pela bancada). O que faltava era a família dos vetos.

### Avisos com o nome certo e avisos com o nome errado

- `E_POSTTOOLUSE_E_SINAL_POS_FATO`: o `bash-empty-result-guard` julga depois de o comando executar. É aviso na família certa e não deve ser promovido a veto. Sem `jq`, ele se cala.
- `E_ASIDE_ROUTER_GATE_E_PROMPT`: o "GATE" do aside-router é uma string injetada no prompt. O desenho está certo, mas o **nome** sugere veto.

### Guardas mecânicas por dentro, voluntárias na invocação

- `E_OPS_GUARDAS_INTERNAS_INVOCACAO_VOLUNTARIA`: todo `ops/*.sh` barra por dentro com `die()`, mas nada impede `rsync`/`systemctl`/`sudo cp` crus fora do wrapper.
- `E_UTILS_GUARDAS_SEM_HOOK`: `onion-untrusted-wrap` (R15, protótipo), `a2a-verify` e `a2a-accept` não são chamados por hook nenhum neste corpus.
- `E_PRECOMMIT_CONDICIONAL_A_CONFIG_LOCAL`: os 5 vetos do `.githooks/pre-commit` dependem de `core.hooksPath` local e caem com `--no-verify`. Quando os workers divergiram sobre isso, a discrepância foi resolvida por medição.

### Prosa

- `E_PROSA_29_GATES_1_COBERTO`: são 29 gates em prosa e só 1 tem mecanismo (vazamento de moat no `onion-publish`, coberto pela REGRA 61 (Fronteira de MOAT: manifesto de plugin publicável não vaza meta-fábrica nem grafo privado)). Dos 8 irreversíveis ou outward-facing sem mecanismo, o merge ganhou veto nesta rodada. Deploy, escrita em repo alheio e relógio seguem em prosa.

## NÃO-VERIFICADOS

Contagem a partir do grafo: **5 itens** (4 nós open sem `verified_at` e 1 superseded), mais 5 ressalvas (3 de verificação parcial, 1 de citações por linha caducas e 1 observação sobre a cadência de revisita). Nenhum nó está refutado ou unverifiable.

1. `D_MOAT_DEPLOY_E_RELOGIO_VIRAM_MECANISMO`: decisão **proposta**, open, confidence 0.7, sem `verified_at`.
2. `Q_PRECOMMIT_ARMADO_EM_CLONE_FRESCO`: open, confidence 0.6, sem `verified_at`. Nunca foi medido num clone fresco se o core se auto-instala.
3. `Q_R15_WRAP_NO_CAMINHO_CRITICO`: open, confidence 0.6, sem `verified_at`. O custo de latência e de falso-positivo não foi medido.
4. `Q_REGRA56_VERACIDADE_DOS_ACHADOS`: open, confidence 0.6, sem `verified_at`. O próprio nó diz que não há número.
5. `E_REGRA56_VERIFICA_PRESENCA_NAO_VERDADE`: **superseded** por `E_O_VERDICT_GANHOU_VOCABULARIO_MAS_NAO_VERIFICACAO` (R0 de 2026-09-09). A tese central segue verdadeira. O que caducou foi a frase de que `verdict` "passa sempre que presente", porque desde 2026-09-08 ele tem vocabulário fechado de 5 valores. Também caducou a citação `l.205-211`, porque o script foi de 211 para 254 linhas.

Ressalvas (nós confirmed com verificação parcial declarada no próprio grafo):

- `C_CONTAGEM_POS_RODADA` (0.85): a contagem de aviso é aproximada ("~63") e vem da consolidação dos relatórios dos workers. O `meta` do grafo diz que a **amostra** foi re-medida, não um censo.
- `E_PROSA_29_GATES_1_COBERTO` (0.85): os 29 gates saem de 107 hits de worker menos 19 descartados. É o mesmo regime de amostra.
- `E_CURA_BANCADA_DOS_VETOS`: o 32/32 foi obtido em **runner isolado**. A bancada completa estourou 10 min na VPS carregada e não rodou localmente.
- **Citações por linha do grafo caducaram** (medido com `sed -n`/`grep -n` em `.githooks/pre-commit` em 2026-09-13):
  - `.githooks/pre-commit:142-149` ("selftest das guardas se toca validation/") é citado em 3 nós: `E_PRECOMMIT_CONDICIONAL_A_CONFIG_LOCAL`, `E_CURA_BANCADA_DOS_VETOS` e `C_BANCADA_ACHA_O_QUE_LEITURA_NAO_ACHA`. Hoje o trecho é comentário sobre tempo de bancada; a chamada do selftest está em l.157-161 (`--affected-staged --jobs auto`).
  - No mesmo nó `E_PRECOMMIT_CONDICIONAL_A_CONFIG_LOCAL`, `:122-127` ("HARD") hoje é o erro de execução do `kg-reverify-schema-check`; o bloqueio por HARD está em l.132.
  - `:30-36` ("main/develop") hoje barra só a default branch; `develop` não aparece mais no arquivo.
  - A `l.205-211` de `review-artifact-check.sh` já está dada como caduca pelo próprio grafo (item 5 acima).
  - Não re-medi as demais citações por linha (`onion-review.yml:493`, `kg-seal-check.sh:118-222` e as outras).
- **Observação sobre `meta.review_after`**: o comentário do grafo diz "revisita (mecanismo/gates 120d) — REGRA 67". As cadências que a REGRA 67 (Grafo de pesquisa com REVISITA carimbada (meta.review_after)) enumera em `lint-artifacts.sh` são "ferramenta 30d · modelos 45d · mercado 90d · benchmark 120d · doutrina 12m". Não existe categoria "mecanismo/gates". O valor 2026-12-31 bate numericamente com baseline + 120d, que é a cadência de *benchmark*, mas o rótulo não corresponde a nenhuma cadência declarada. Mantive a data e não editei o grafo.

## valeu-a-pena

Dá para computar só como **ordem de grandeza**: o numerador é "~1,9M" declarado e pagou auditoria **e** cura juntas, então dividir por nó com mais de um dígito significativo seria precisão falsa. Dá **~80 mil tokens por nó**, seja contra os 24 nós da rodada, seja contra os 25 atuais.

Tokens por nó subestima esta rodada, porque o produto não foi só o grafo. Vieram também 1 veto novo, 1 buraco fechado no veto existente, 1 classe de bypass fechada (8 invólucros) e 32 casos de bancada (`E_CURA_MERGE_GATE_2O_VETO`, `E_CURA_LIB_INVOCACAO_PARTILHADA`, `E_CURA_BANCADA_DOS_VETOS`). Não calculo custo por veto aqui porque a divisão depende de atribuir tokens entre auditoria e cura, e isso não foi medido.

## Backlog

| Nó | Ação pedida | Gatilho (do grafo) |
|---|---|---|
| `D_MOAT_DEPLOY_E_RELOGIO_VIRAM_MECANISMO` | PreToolUse + lib + bancada para deploy, push em repo alheio e relógio, com assinatura por **alvo**, não por vocabulário | 1º dogfood com deploy/cron/push-alheio fora do wrapper, OU a próxima onda de guardas |
| `Q_REGRA56_VERACIDADE_DOS_ACHADOS` | medir achados exclusivos da auto-revisão contra os do revisor externo (experimento `Q_EXP_AUTO_REVISAO_5_1`) | próximo PR com resíduo ≥ 4 achados |
| `Q_PRECOMMIT_ARMADO_EM_CLONE_FRESCO` | SessionStart que mede `core.hooksPath` e avisa, sem vetar | próximo clone fresco do core, ou commit em main sem o hook disparar |
| `Q_R15_WRAP_NO_CAMINHO_CRITICO` | PostToolUse que envolve conteúdo externo (WebFetch/inbox), medindo latência e falso-positivo | 1ª injeção observada em sessão de drive, OU o R15 sair de protótipo |
