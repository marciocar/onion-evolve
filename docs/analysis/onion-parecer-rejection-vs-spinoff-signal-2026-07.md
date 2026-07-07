# Parecer — rejeição que ressurge: insistência ou sinal de produto-irmão? (lente Onion)

> **Data**: 2026-07-06 · **Para**: decisão do maestro · **Provocado por**: pergunta direta do
> maestro sobre a forma como o Onion valida regras — quando uma proposta rejeitada ressurge, isso
> pode não ser tentar impor a mesma vontade de novo; pode ser sinal de um produto/serviço/visão
> genuinamente novo, endereçando uma dor sem nome ainda. Ele pediu reflexão real (não neutra) +
> investigação sobre se ligações de grafo ajudam + o que é popular no campo em julho de 2026.
> **Verificação em primeira mão**: 2 Explore agents sobre o corpus interno (grep exaustivo, não
> amostra) + 4 buscas WebSearch reais sobre práticas de 2026.
>
> **Status: DECIDIDO (2026-07-06)** — maestro concordou com as recomendações da §5. **D1**: a 5ª
> categoria se chama **`bifurcado`** (combina com o vocabulário git já pervasivo no repo e com o
> nome de relação de grafo `FORKS_INTO` proposto em D2, caso avance depois). **D3**: as 2 sementes
> que já colidem com rejeição prévia ganharam cross-referência a este parecer. **D2** e **D4**
> ficam como recomendado — não agora.

## 0. TL;DR

A intuição do maestro está certa, e não é imposição de vontade — é **falta de vocabulário**. O
Onion já tem 4 rótulos diferentes para "não fazer isso" (rejeitado / abandonado / gated /
descartado), nunca reconciliados, e **já executou duas vezes, com sucesso, o exato movimento que
ele está descrevendo** — sem nunca nomeá-lo como padrão. O grafo/KG faz sentido como **lugar de
registro** da decisão, não como o que resolve o julgamento difícil. E o campo em 2026 confirma a
forma geral (organização ambidestra: unidade separada para o que não cabe no core) sem oferecer
solução pronta pro diagnóstico específico — isso o Onion precisa nomear sozinho.

## 1. O fato que muda o problema

**Não existia, até esta decisão, nenhum rótulo para a categoria que o maestro apontou.** O corpus
usava 4 palavras diferentes pra "não fazer isso", cada uma cunhada ad-hoc, nunca reconciliadas num
só lugar — e ganhou agora uma 5ª, nomeada nesta rodada:

| Rótulo | Onde vive | Quando se usa | Reabre como? |
|---|---|---|---|
| **Rejeitado conscientemente** | 1 linha em `onion-engine-economy.md` §5 (nunca generalizado em meta-spec/skill/ADR) | Fere invariante estrutural (quem orquestra, plataforma única, humano-maestro) | "NÃO reabrir sem evidência nova" — mas nenhum documento diz o que contaria como evidência |
| **Abandonado formalmente** | Família `.onion/`/multi-IDE/CLI, `onion-review-2026-05.md` | Mudança de identidade de plataforma | Tratado como definitivo em toda citação até hoje — nenhuma reversão registrada |
| **Gated/deferido** | A maioria (`local-slm`, `role: distilled`, RFC-0003 F4/F5) | Prematuro por falta de evidência de uso/escala | Automaticamente, ao atingir o gatilho nomeado ("1º adotante regulado", "2º caso de uso") |
| **Descartado** | Avaliação de sinal externo (`onion-orchestration-external-radar-2026-06.md` §4) | Sinal de fora avaliado e não adotado | "Fica registrado, não some" — sem gatilho de reabertura nomeado |
| **Bifurcado** (novo, D1 deste parecer) | onion-mini, whatsapp-sender — nomeado aqui pela 1ª vez | O *lugar* (core) está errado, não o *mérito* — a capacidade é legítima como iniciativa independente | Não reabre o core — a resposta já existe em outro repo/produto; reabriria só se a evidência mudasse a identidade do core em si |

Existe uma distinção real por trás dos 4 rótulos antigos, nunca declarada como regra até agora:
**"rejeitado"/"abandonado" é sobre identidade** (não muda com mais uso, só com mudança de quem o
Onion é); **"gated" é sobre evidência** (resolve-se automaticamente ao acumular uso real).
**"Bifurcado" nomeia a pergunta do maestro**: e se a ideia for certa, só não pra aqui?

**O Onion já tinha respondido essa pergunta duas vezes, na prática, antes de ter o nome:**

- **onion-mini** (bifurcado) — `onion-engine-economy.md` §5 rejeita "model-routing multi-LLM"
  (fere identidade de plataforma única). Mas a resposta real que a organização deu a "não depender
  de 1 fornecedor só" não foi reabrir essa rejeição — foi criar o onion-mini como produto-irmão
  portátil, destilação de doutrina (não de pesos), core intacto. Prova em produção: o Onion Mini já
  roda como Custom GPT no ChatGPT (`chatgpt_gpt:` em `members.yaml`, registrado nesta mesma
  semana). O próprio ADR do Mini (`onion-adr-mini-distillation-2026-07.md`) **não fazia essa
  conexão** — quem nomeou isso retroativamente foi uma semente de pesquisa que plantamos nesta
  sessão (`onion-research-seed-federated-slm-orchestration-2026-07.md`), e ela mesma admitia:
  *"nenhum documento reconcilia essas duas direções [...] sem síntese registrada"* — agora tem.
- **whatsapp-sender** (bifurcado) — o parecer já existente (`onion-parecer-whatsapp-sender-
  2026-07.md`) separou explicitamente "está no lugar errado" (ferramenta boa, mas não pertence ao
  core) de "é ruim" — resolvido por **extração para repo próprio**, com a capacidade abstrata
  preservada como candidata futura, gated. Era o caso mais próximo de um veredito real do tipo que
  o maestro buscava — agora tem rótulo reutilizável.

Achado extra: já existe uma semente recente (`onion-research-seed-ide-integration-revisit-
2026-07.md`) fazendo exatamente essa mesma pergunta sobre multi-IDE — "é reabrir o que foi
fechado, ou é o onion-mini já cobrindo isso por outro caminho?" A mesma figura de raciocínio,
reaplicada, sem que ninguém tenha ainda dito em voz alta que é *a mesma figura*.

## 2. A pergunta do grafo — faz sentido?

**Sim, mas resolve só a metade fácil do problema.** `knowledge-graph-sdaal.md` já tem relações
(`SUPPORTS`/`REFUTES`/`SUPERSEDES`/`CAUSES`/`DEPENDS_ON`/`TRACES_TO`) — todas sobre **veracidade
epistêmica**: um claim está certo, outro claim o refuta ou supera, a história se reconcilia sem se
apagar. Confirmei por grep dedicado: **zero** relação, no KG ou no TBox
(`onion-relation-vocabulary.md`), sobre **linhagem de decisão/produto** — "X foi rejeitado aqui e
gerou Y como iniciativa independente" é uma categoria estruturalmente diferente do que já existe.
Não é "correção de uma verdade" (isso o KG já faz bem) — é **bifurcação de identidade** (isso o KG
nunca precisou modelar).

A pesquisa externa (provenance graphs que preservam ramos aceitos E rejeitados como entidades
distintas — [dataset de decisão em agentes autônomos](https://www.mdpi.com/2306-5729/11/4/66),
[provenance-enhanced statements](https://arxiv.org/pdf/2606.15246)) confirma que isso é
território ativo, mas **nenhuma fonte, interna ou externa, tem um relation-type nomeado
especificamente pra "rejeitado aqui, spin-off lá"** — se o Onion criar um, é proposta original,
não adoção de padrão pronto. Isso não é motivo pra não fazer — é motivo pra não vender como "já
resolvido em algum lugar".

**O que o grafo NÃO resolve**: qual caso é qual. Adicionar uma aresta `FORKS_INTO` (ou nome
equivalente) dá lugar pra **registrar** o veredito depois de tomado — não decide, por si, se uma
ideia que ressurge é "insistência" ou "sinal novo". Esse julgamento continua exigindo o mesmo gate
humano que RFC-0003 já formaliza pra graduação em geral: *"gatilho mecânico + decisão final
humana"* — nunca automático, mesmo quando o critério mecânico está satisfeito.

## 3. O que é popular no campo, julho de 2026 (pesquisa externa real)

- **Organização ambidestra** ([O'Reilly/Tushman](https://umbrex.com/resources/frameworks/strategy-frameworks/ambidextrous-organization-framework/),
  ainda o framework dominante): a prescrição clássica pra "isto viola a identidade do core mas
  pode ser breakthrough real" é uma **unidade autônoma separada** — P&L próprio, cultura própria,
  físicamente distinta — trocando sinergia por independência. **É literalmente o que o onion-mini
  já é.** O Onion reinventou a resposta certa sem saber o nome dela.
- **ADR/RFC/PEP** ([Fowler](https://martinfowler.com/bliki/ArchitectureDecisionRecord.html),
  [RFC Editor](https://www.rfc-editor.org/status-changes/)): convenção estabelecida é
  imutabilidade + supersede — nunca reabrir um registro aceito, sempre publicar um novo que o
  supera. O Onion já segue isso pros ADRs (§ "ADRs são superseded, nunca removidos" no
  `docs/analysis/README.md`). Isso resolve o *processo* de emendar uma decisão — não resolve o
  *diagnóstico* de que tipo de emenda é essa.
- **Pedidos recorrentes como sinal** ([Feature Request Management
  2026](https://www.featurebase.app/blog/feature-request-management)): prática mainstream de
  produto em 2026 — recorrência importa, mas **com ressalva**: *"feature requests são sinal
  valioso mas um roadmap terrível"* — recorrência sozinha não prova necessidade real, precisa
  triangular com uso/analytics/dor concreta. Aplica direto aqui: uma ideia ressurgir 2x não é, por
  si, evidência nova — é só o sinal de que vale *olhar de novo com critério*, não de que a resposta
  mudou.
- **"Parking lot" (agile)**: falso positivo — é ferramenta de triagem de reunião (curto prazo), não
  mecanismo de revisão de decisão antiga. Vale descartar como analogia, mesmo sendo o primeiro
  instinto de nome.

**Veredito honesto**: o campo confirma a *forma* da resposta (separar em unidade própria) mas não
oferece um *diagnóstico* pronto pra "isto é re-litígio ou sinal novo" — essa parte, o Onion
precisa nomear e testar sozinho, com os próprios casos (onion-mini, whatsapp-sender, e as 2
sementes que já colidem com rejeição prévia) como evidência de que já sabe fazer isso na prática.

## 4. O que o core absorve de doutrina

1. **"Rejeitado" nunca deveria significar "ideia ruim"** — os 4 "porquês" no `onion-framework-
   identity.md` §7 já são, na própria linguagem do documento, sobre desalinhamento de identidade
   ("dilui", "contradiz a identidade"), nunca sobre mérito técnico. Isso já é a distinção certa —
   só falta declará-la como regra, não deixar implícita.
2. **O teste que separa as duas categorias**: não é "isso fere a identidade do core?" (isso já é
   avaliado) — é "a *capacidade* por trás da proposta é legítima, mesmo que o *lugar* (o core)
   esteja errado?" Mesmo teste que o whatsapp-sender já aplicou informalmente.
3. **O grafo registra, não diagnostica** — qualquer relation-type novo é complemento ao julgamento
   humano (RFC-0003: gatilho mecânico + decisão final humana), nunca substituto dele.
4. **Recorrência é convite a olhar de novo, não veredito** — uma ideia ressurgir não muda
   automaticamente a resposta; muda a obrigação de checar se as premissas da rejeição original
   ainda valem (é exatamente o que as sementes `federated-slm-orchestration` e
   `ide-integration-revisit` já fazem, cada uma isoladamente).

## 5. Decisões (maestro concordou com as recomendações, 2026-07-06)

| # | Decisão | Veredito |
|---|---|---|
| D1 | Nomear a 5ª categoria ("certo pro core, sinal de produto-irmão fora dele")? | ✅ **DECIDIDO: `bifurcado`** — combina com o vocabulário git já pervasivo no repo e com `FORKS_INTO` (D2, se avançar depois) |
| D2 | Criar o relation-type novo no KG (`FORKS_INTO` ou equivalente) em `knowledge-graph-sdaal.md`/`onion-relation-vocabulary.md` agora? | ⏳ **Gated, não agora** — só 2 instâncias reais existem (onion-mini, whatsapp-sender), abaixo do padrão "2º caso de uso" que o próprio Onion já exige antes de formalizar abstração nova |
| D3 | Retrofitar as 2 sementes já plantadas (`federated-slm-orchestration`, `ide-integration-revisit`) com o vocabulário novo? | ✅ **EXECUTADO** — cross-referência ao rótulo `bifurcado` adicionada em ambas |
| D4 | Formalizar a reconciliação dos 4+1 rótulos (rejeitado/abandonado/gated/descartado/bifurcado) num glossário único? | ⏳ **Não isolado** — só quando `bifurcado` estiver testado em mais 1-2 casos reais; virar meta-spec antes da hora é "construir catedral antes do gatilho" (a própria lição do `.onion/`) |
