---
title: "M8 — o lado serial rodou, e mudou o eixo da própria comparação"
category: research
date: 2026-08-06
status: lado-serial-executado-lado-paralelo-gated
method: "Execução direta do fallback serial (orchestration-fallback.md): 9 workers Agent seriais, um por nó da fila --freshness-tsv, contrato KgReverifySchema idêntico ao modo paralelo, sonnet/medium, READ-ONLY. Custo medido POR ITEM via usage do subagente, nunca estimado."
kg: docs/evolution/research/m8-serial-2026-08/m8-serial-2026-08.kg.yaml
run_id: serial-2026-08-06-m8
tokens: 697710
agents: 9
duration_min: 37
ledger: docs/evolution/research/m8-serial-2026-08/ledger-por-item.tsv
agent_time_min: 12
verified_at: 2026-08-06
source: "docs/onion/graph/vps-shared-tools-2026-07.kg.yaml @ 7fd9392 + host vivo srv1812846"
---

# M8 — o lado serial rodou

> **Projeção do grafo.** SSOT: [`m8-serial-2026-08.kg.yaml`](./m8-serial-2026-08.kg.yaml) (radar exit 0).
>
> **Esta síntese é a primeira a carregar os 4 campos do contrato do M6** — `run_id` · `tokens` ·
> `agents` · `duration_min` — e o carimbo não é decorativo: é o gatilho do M6 sendo testado na
> primeira oportunidade real. Ver §"O gatilho do M6" e a ressalva que o limita.

## A pergunta que valia mais que a corrida

O W3 escreveu, sobre o M8: *"se o fallback **não rodar**, a rede de segurança da portabilidade é
**ficção** — o maior achado possível do menu."*

> **⚠️ Esta citação, e a de "~300k / meia sessão" mais abaixo, NÃO são verificáveis neste repo.** Vieram
> do journal do workflow do W3, que vive fora do versionamento e não sobrevive à sessão. A **substância**
> está ancorada em `onion-identity-2026-07.kg.yaml` (`C_M8_FECHA_SO_UM_TERCO`); **as aspas, não**. Num
> documento cuja tese é rastreabilidade, citar fonte que evapora é o defeito que ele denuncia — fica
> declarado em vez de disfarçado. O `orchestration-fallback.md` estava escrito, testável,
e **nunca havia sido executado nem uma vez**.

> **Não é ficção. O caminho serial roda** — a **iteração com `Agent` mantendo o mesmo `schema`** (Passo 2),
> o **tratamento de falha parcial** (Passo 3) e o **fan-in** (Passo 4) executaram em **9 de 9** itens,
> **zero SKIP**.

**Correção da versão original, que dizia "os 4 passos executaram como escritos" — e isso era falso em
dois deles.** A revisão adversarial mostrou que a frase não sobrevivia ao lado da própria ressalva:

- **Passo 0 é uma detecção.** Executado *como escrito*, com Workflow disponível, ele manda **prosseguir
  com fan-out nativo** — ou seja, executado como escrito ele **não aciona o fallback**. Contá-lo entre os
  passos "executados" é logicamente incompatível com o teste ter sido forçado.
- **Passo 1** manda avisar *"a ferramenta nativa Workflow **não está acessível**"* — falso neste ambiente.
  Emiti-lo seria mentir; não emiti-lo é o passo não ter executado. Eu não o emiti (declarei a natureza
  forçada no lugar), o que é o certo — mas então **o Passo 1 não executou**.
- **Passo 4 não executou por inteiro:** seu item 4 manda manter a verificação adversarial planejada, e o
  `/meta:kg-freshness` exige **juiz adversarial `opus`/`high` quando > 30% vier DRIFTED**. Deu **44%** —
  e **nenhum juiz rodou**. Isso não é detalhe: é a etapa que existe para não deixar 4 vereditos DRIFTED
  passarem sem contraditório.

**E a ressalva vem junto, porque sem ela o resultado seria lido como mais do que é.** O Passo 0 manda
acionar o fallback **só** se o Workflow estiver indisponível — e aqui ele estava **disponível**. Foi
**teste forçado**, não degradação real. Fingir que o substrato caiu seria a mesma mentira que o próprio
fragmento proíbe (*"nunca fingir paralelismo inexistente"* vale nos dois sentidos).

**O que ficou provado é o caminho de código. O gatilho não.** Que a *detecção* dispare sozinha quando o
substrato cair de verdade exige um ambiente **sem** Workflow — outro IDE, ou a ferramenta desabilitada —
e segue **gated**. Confundir as duas coisas seria o erro de categoria que esta casa mede em outro lugar:
**declarado ≠ verificado**.

## O achado que nenhuma hipótese previa

```
item 2 · ENT_whatsapp  (sem notas do anterior) : 15 tool-uses · 132s
item 3 · ENT_logto     (com notas repassadas)  :  4 tool-uses ·  25s
```

Repassei ao item 3 o que o item 2 descobriu do ambiente — que `docker ps` sem `sudo` dá *permission
denied* e `sudo -n docker ps` funciona.

### ⚠️ Esta inferência foi REBAIXADA — o confounder é meu, e a revisão o nomeou

A versão original desta seção afirmava que *"o serial acumula contexto e o paralelo é cego"*, tratando
o delta 15→4 como prova. **Não é.** Os dois itens são **nós diferentes em espécie de tarefa**:

| | |
|---|---|
| `ENT_whatsapp` | **prova negativa** — demonstrar que algo **não existe** em lugar nenhum do host |
| `ENT_logto` | **health-check** de um container que responde |

Provar ausência é caro **por natureza da tarefa**. E a nota repassada economiza **uma ou duas** chamadas
de permissão — **não onze**. Variável confundida, **n = 1**.

**O que a evidência sustenta, e só isso:** repassar a nota eliminou a redescoberta do fato `sudo`/docker.
O restante do delta **não é atribuível**. Direção plausível, **magnitude desconhecida**.

**O que faltaria para sustentar de verdade:** A/B no **mesmo** nó (rodar `ENT_whatsapp` com e sem nota),
ou notas alternadas nos 9 itens (n≈4/5), ou — o mais barato, e que dava para fazer no dia — **contar
quantas das 15 chamadas do item 2 foram probes de permissão**. Se forem duas, a tese morre ali.

**E há uma ambiguidade que só o ledger resolveu:** o `kg-radar.sh --freshness-tsv` **documenta** "ORDEM:
atenção desc" e **não ordena** (bug pré-existente, medido nesta revisão). Quem executou aplicou `sort`
por fora — mas isso não estava registrado, então um leitor não conseguia distinguir *"o run reordenou"*
de *"os rótulos estão trocados"*. Se estivessem trocados, **a conclusão se inverteria**. A ordem real
está agora em [`ledger-por-item.tsv`](./ledger-por-item.tsv).

## A estimativa errou por 2,3×

| | |
|---|---|
| estimativa do W3, para o **M8 inteiro** | ~300k tokens, "meia sessão" |
| medido, **só o lado serial** | **697.710 tokens** · 78 tool-uses · 699s de agente · 37 min de relógio |
| projeção da corrida completa | **≥ 1,4M** — ver o método e a ressalva abaixo |

**O método da projeção, que a versão original não declarava:** é `serial × 2` — pura extrapolação
linear. E ela **contradiz a seção anterior deste mesmo documento**: se repassar contexto barateia o
serial, então o paralelo (cego por construção) custaria **mais**, não o mesmo. Logo **1,4M é PISO, não
estimativa** — e a versão original que a apresentava como "exatamente o patamar da corrida cheia"
comparava grandezas sem relação. **Retirada a coincidência retórica; mantido o piso, com o método à
vista.**

O item foi aprovado com um número que não se sustentou, e **só a execução disse isso**. É a
justificativa concreta do contrato de custo do M6: sem carimbo por run, a próxima estimativa erraria
igual, sem ninguém notar.

## O que a corrida achou no caminho: 44% de drift

Os vereditos, medidos contra o **host vivo** e não contra doc:

| | |
|---|---|
| CONFIRMED | 4 |
| **DRIFTED** | **4 — 44%** |
| UNVERIFIABLE | 1 |

**Bem acima do limiar de 30%** que o próprio `/meta:kg-freshness` define para acionar juiz adversarial.

**Os quatro drifts:**

1. **`ENT_substrate`** — `bridge.onionevolve.com` está no label e **resolve por DNS**, mas **não tem
   vhost no Caddy**: `curl` retorna `000`. O `onion-bridge` serve sob `app.`, não sob `bridge.`
2. **`ENT_whatsapp`** — o nó afirma `whatsapp-sender` **VIVO**. Busca full-filesystem com `sudo` não
   acha processo, container, unit nem diretório — apesar do parecer de 2026-07-05 registrar
   reinstalação em `~onion/whatsapp-sender`. **WAHA**, esse sim, confirmado vivo (up 13h, API 401)
3. **`D_whatsapp_dual_waha_default`** — o desenho "dual adapter" tem **um só lado material** hoje
4. **`D_structured_plan_and_doctrine`** — a doutrina do catálogo **foi** promovida a KB, mas por
   **bypass do F0 direto**, depois da fase F2 ser **formalmente reprovada** (`stack-harmonia-2026-08`,
   síntese com premissas fabricadas). `A_analysis_structure` segue `open`

**E o `UNVERIFIABLE` é o contrato funcionando:** `D_email_plus_logto_connector` afirma **só direção**
(`"DIRECAO: construir…"`), e o worker **recusou-se a inventar uma medição substituta** — que é
exatamente o erro que o comando existe para não cometer.

## O gatilho do M6, testado na primeira oportunidade

O contrato do M6 declarou: *"se a próxima síntese nascer **sem** os quatro campos, aí — e só aí —
mecanize a emissão automática."* **Esta é a próxima síntese, e ela nasceu com os quatro campos.** Logo
a emissão automática segue **gated**, por razão medida e não por fé.

**Ressalva sem a qual o teste vale pouco:** quem escreveu o contrato e quem escreveu esta síntese são
**o mesmo agente na mesma sessão**. O teste real é a **próxima** síntese, de outra sessão, que não viu o
contrato nascer. Este resultado é **necessário, não suficiente**.

**E o contrato encontrou seu primeiro limite no primeiro uso:** os 4 campos pressupõem um run de
**Workflow** — `run_id` é um `wf_xxxxxxxx-xxx`. Esta corrida não teve Workflow: foram 9 invocações
seriais da ferramenta `Agent`, e **não existe `wf_` para carimbar**. Preenchi `run_id:
serial-2026-08-06-m8` e declarei a natureza, em vez de inventar um id falso ou deixar vazio.

> **Questão aberta para o maestro:** o contrato deve **(a)** aceitar id sintético com prefixo declarado
> para modo serial, **(b)** trocar `run_id` por `run_ref` agnóstico ao substrato, ou **(c)** valer só
> para Workflow? A **(c)** deixa o modo serial fora da série histórica — justamente o modo que o M8
> existe para avaliar. **Ela se refuta sozinha.**

## O que fica

**O lado paralelo segue gated.** Com o serial em 697k, a corrida completa projeta ~1,4M — e a decisão
de pagá-la é do maestro, agora com número em vez de estimativa.

**E o teto do M8 continua o que `C_M8_FECHA_SO_UM_TERCO` declarou antes de ele rodar:** ele fecha **um**
dos três números da lacuna do porte (`Q_CUSTO_DO_PORTE_NUNCA_MEDIDO`) — o do fallback vivo. **Não** fecha
o custo do porte de 2026-05 nem o inventário do que se perdeu. Ter escrito o teto *antes* é o que impede
esta síntese de ser lida como encerramento.
