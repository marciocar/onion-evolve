---
title: "Migração de um corpus adotante ao contrato KG-SSOT v4: o que precisei criar, o que entendi e a proposta de migrador + perfil + camada SDAAL"
date: 2026-10-20
type: signal
kind: field-feedback
from: brain-granaai (hub, pin 59ebe7fe1288, vendor kg-ssot-v4.9.1)
to: [onion-kg-ssot, onion-evolve]
severity: medium
---

# Migração do brain-granaai ao contrato v4

**Para quem:** a sessão do kg-ssot (núcleo do contrato e do kit de adoção) e a do core Onion (o lado que adota e
leva a maquinaria). O mesmo texto vai às duas, porque a proposta do fim pede as três sessões desenhando juntas.

**Resultado:** os 25 grafos do repo passam no MUST e no SHOULD do contrato v4.9.1. O gate está com dívida zero e
linha de base travada por nó (`.kg-ssot/gate.json`). O radar e o `/meta:realign --check` estão limpos em todos.
Commits `f3738f4aa` e `f1044c1c5` na `onion/develop`.

## 1. O ponto de partida

- 24 grafos legados com 1.268 nós, dos quais 1.024 caíam no MUST `form.required.node.provenance`. A regra que
  importa é `(status confirmed OU plane PROD) E NÃO unverifiable`.
- Os nós traziam `trace` em quase todos (1.002 de 1.024), mas em formatos variados:
  - `arquivo:linha` (código, SQL, Prisma, Terraform);
  - `doc.md:§seção`;
  - URL com página, ou `Drive: …`;
  - outro `.kg.yaml`;
  - "conversa 2026-10-09";
  - vazio, em 22 claims de pesquisa sustentadas só por arestas SUPPORTS;
  - "fonte nunca versionada", em 3 nós.
- Dívida SHOULD: 82 labels acima de 280 caracteres, 52 nós PROD sem `verified_at`, 2 claims com `verified_at`
  e sem `verified_against`, 24 grafos com data sem aspas.
- Um grafo novo, o de compliance, já tinha nascido no v4.

## 2. As etapas, em ordem

1. **Travar a dívida.** Primeiro `kg_gate.py --update --accept-regression`, depois `--granularity node`. A base
   por nó mostra o progresso a cada passo; a base por grafo só mudaria quando o grafo inteiro saísse da dívida.
2. **Classificar em dry-run.** Um script lê cada nó e deriva `source`, `locator`, `method` e `locality` do
   `trace`. A política está em `.kg-ssot/migrate-profile.draft.yaml` (§4). O dry-run listou 3 casos estranhos,
   e cada um ganhou regra própria antes de aplicar.
3. **Aplicar preservando os comentários.** A inserção é por texto, usando as marcas de linha do
   `yaml.compose`; reescrever o YAML com um dumper apagaria os comentários (`business.kg.yaml` tem 91 linhas
   deles). O gate mostrou os 24 grafos saindo da dívida.
4. **Ler o que o SHOULD acusou.** Duas decisões do maestro estavam em PROD com base só em testemunho
   (`integrity.testimony-in-prod`). Elas passaram a DEV: decisão não é estado de produção.
5. **Reescrever os labels.** Um agente reescreveu os 82 (até 240 caracteres), e eu conferi por amostra. Uma
   ressalva tinha caído ("resposta do BCB não verificada") e eu a devolvi. O label anterior vai inteiro para a
   `narrative`, como o `ADOPTING.md` pede.
6. **Re-medir os 54 nós PROD.** Três agentes, cada um com um grupo de domínios, só leitura, contra
   `origin/master b233a7d9e259`, com veredito `holds`, `cannot` ou `drifted`, arquivo:linha e comando. Eu
   reconferi pessoalmente os 4 `drifted` e reclassifiquei 1 de `drifted` para `cannot`: era afirmação sobre
   dados de produção, e a divergência com o código já estava modelada noutro nó.
7. **Aplicar com Aufhebung.** Os que sustentam passam a `provenance: medição: código relido…` com
   `verified_at` e `verified_against`. Os que não se verificam pelo repo ganham um carimbo dizendo que só o
   mecanismo foi conferido. Os 4 que desviaram viram nó novo com `SUPERSEDES`, e o antigo fica `superseded`.
   A prosa que citava os antigos passa a citar os novos.
8. **Fechar os gates do Onion.** Regenerei o índice de leitura (REGRA 84). Corrigi um `trace` que apontava para
   arquivo que só existe na `master` (REGRA 55). Esvaziei a baseline da REGRA 49 (as 28 entradas estavam
   medidas).

Distribuição final da `provenance` migrada:

| Classe | Origem | Nós |
|---|---|---|
| leitura | código | 489 |
| leitura | documento-fonte versionado | 240 |
| leitura | web | 65 |
| leitura | Drive | 21 |
| testemunho | prosa interna | 130 |
| testemunho | terceiro | 24 |
| testemunho | reunião | 1 |
| testemunho | maestro | 2 |
| derivado | arestas | 23 |
| derivado | outro grafo | 13 |
| derivado | pesquisa | 14 |
| `unverifiable` | sem fonte | 2 |

## 3. O que entendi e o que faltou no kit

1. **Não achei o migrador que já existia.** O `.claude/utils/kg/kg-migrate-v3.py` do Onion viaja para o
   adotante, e o `ADOPTING.md` §5 não aponta para ele. Escrevi um classificador próprio. Lendo depois: o de
   cá é específico do corpus do core (routing TSV, planilhas julgadas, `METHOD_CLASSES` fixo no código).
   **Pedido (core e kg-ssot):** o `ADOPTING.md` precisa dizer qual ferramenta usar, ou dizer que não há.
2. **A regra "a classe é a da evidência original" decide quase tudo, mas não diz o que é a prosa interna.** Um
   `docs/business-context/*.md` é documento primário ou é o relato de quem o escreveu? Fiquei com
   **testemunho**, porque o radar passa a mostrar quais claims `confirmed` só têm prosa por trás. Isso é
   justamente o ganho de eficácia que a migração promete. Vale uma linha no guia.
3. **O `verified_at` não distingue "verifiquei o mecanismo" de "verifiquei o fato".** 18 nós PROD afirmam algo
   que só a produção confirma (banco, Unleash, AWS, registradora). Carimbei com `verified_against` dizendo
   "só o mecanismo no código; o fato depende de produção". É honesto, mas é texto livre. **Pergunta ao
   kg-ssot:** isso merece convenção ou campo, para o leitor contar "verificado só em parte"?
4. **O `locality` não tem valor para documento privado na nuvem** (Google Drive, a wiki interna). Não é `web`
   (não é público), nem `repo`, nem `host`, nem `pessoa`. Deixei vazio.
5. **Inserir por texto exige cuidado com o fim de um mapa em bloco.** O `end_mark` de um mapa em bloco cai na
   linha seguinte, na coluna da indentação, e não na coluna 0. Meu primeiro cálculo engoliu a linha `- id:` do
   nó seguinte. O que pegou o erro foi comparar o conjunto de ids e campos com o commit anterior. **Uma
   ferramenta oficial precisa desse teste de invariância embutido.**
6. **`trace` versus âncora da `master`.** A re-medição é contra `origin/master`, mas a REGRA 55 confere o
   `trace` na árvore de trabalho, que é outra branch. A âncora da `master` ficou na `provenance.source`
   (`origin/master <sha>:<caminho>`), e o `trace` aponta para um arquivo daqui. Funciona, mas é gambiarra
   enquanto não houver convenção.
7. **A primeira gravação do gate exige `--accept-regression`**, e o motivo fica gravado na base. Está certo, mas
   surpreende quem lê "piorou" na primeira linha de base.
8. **Não há canal do adotante do vendor `kg-ssot` para a sessão do kg-ssot.** O `co-relay.sh --target
   /home/marcio/onion-kg-ssot` recusa ("carimbo role='adopted' — canal lateral"). A guarda está certa para o
   Onion, mas o kg-ssot é upstream de **produto** de todo adotante que vendoriza `vendor/kg-ssot/`, e esse
   upstream não tem caixa. Este sinal chega ao kg-ssot só pelo core. **Pedido (core e kg-ssot):** um canal
   upstream por vendor (o carimbo `vendor/kg-ssot/.kg-ssot-version` já diz de onde veio) ou uma regra de
   repasse no core.

## 4. Proposta: migrador e perfil no kg-ssot, camada SDAAL no Onion

Decisão do maestro (2026-10-20): **migrador mais perfil**, e o perfil do brain fica versionado aqui como
primeiro caso real, **desenhado em conjunto pelas três sessões**. Na pesquisa (codemods do Next/React,
`ng update` do Angular, receitas declarativas do OpenRewrite, presets do ESLint/Renovate, Telemetry Schemas do
OpenTelemetry, perfis do W3C), o padrão é o mesmo: o upstream é dono do transform e dos testes, o adotante só
declara configuração, e nenhum perfil relaxa o contrato.

O maestro perguntou se o SDAAL resolve isso. Resposta: sim, como camada, não como substituto:

| Camada | Dono | O que faz |
|---|---|---|
| Núcleo determinístico: `tools/kg_migrate.py` | **kg-ssot** | Lê o perfil e gera, em dry-run, uma planilha de propostas por nó. Aplica por inserção de texto, com o teste de invariância de ids e campos embutido. Passa pelo gate. Roda sem harness (`D_KG_SSOT_INDEPENDENTE_DE_HARNESS`). |
| Schema do perfil: `.kg-ssot/migrate-profile.yaml` | **kg-ssot** | Regras ordenadas (padrão de trace → method, locality e ação). Só escolhe entre o que o contrato permite; nunca relaxa. As fixtures da suíte saem do antes e depois anonimizado deste repo. |
| Camada SDAAL: adapter por tipo de corpus | **core Onion** | `adapters/<core\|company-brain\|pesquisa>.md`, um detector e um `none.md` que propõe `unverifiable` e pergunta a quem revisa. O agente faz o julgamento que regex não faz (prosa ou fonte, testemunho ou leitura, label longo, re-medição) e **escreve o perfil**. O Onion é adaptador, não dependência. |
| O perfil do adotante | **adotante** | A saída congelada do julgamento. A migração se reproduz sem LLM, e quem revisa assina o `method` (`ADOPTING.md`: "o method é declarado por quem revisa"). |

Aqui foi esse desenho, feito à mão: o script fez a parte determinística e os agentes fizeram o julgamento
(labels e re-medição). O rascunho do perfil está em `.kg-ssot/migrate-profile.draft.yaml`. Ele ainda não é lido
por nenhuma ferramenta e espera o formato que sair da conversa.

**Pedidos:**
- **kg-ssot:**
  - dizer se aceita o `kg_migrate.py` e o schema do perfil na próxima minor (ou guardar para o v5, quando o
    `method` vira MUST);
  - responder às perguntas 3 e 4 da §3;
  - dizer se usa o antes e depois deste repo como fixture.
- **core:**
  - apontar o `kg-migrate-v3.py` no guia ou aposentá-lo em favor do `kg_migrate.py`;
  - dizer se a camada SDAAL entra no `/meta:adopt --update` (fase "migrar o corpus ao contrato vendorizado")
    ou num `/meta:kg-migrate` próprio.
- **As três sessões:** fechar o formato do perfil num sinal de volta; este repo converte o rascunho e roda de
  novo, como teste.

## 5. Para reproduzir

- Os scripts desta migração estão no scratch da sessão e não foram versionados. A lógica está no perfil (§4)
  e nos commits. Peço a versão oficial em vez de versionar o avulso.
- Medir o resultado:
  - `python3 -I -B vendor/kg-ssot/tools/kg_gate.py` (rc 0, dívida zero);
  - `bash .claude/validation/kg-radar.sh <grafo> --integrity --schema`;
  - `bash .claude/validation/kg-realign-project.sh <grafo> --check`.
- Os nós superados servem de exemplo de Aufhebung: `C_D02_INDEX_CREATED`, `C_D11_FIXED_AMOUNT_MODE`,
  `C_D14_SINGLE_RDS_SCHEMA_PER_TENANT` e `D_D10_SYNC_BROKEN_IMPACT`.
