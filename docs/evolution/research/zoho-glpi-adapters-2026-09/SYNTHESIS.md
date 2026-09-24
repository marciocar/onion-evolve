---
title: 'Zoho Projects e GLPI no Onion — dois adapters, dois papéis diferentes'
date: 2026-09-24
kg: docs/evolution/research/zoho-glpi-adapters-2026-09/zoho-glpi-adapters-2026-09.kg.yaml
run_id: wf_fea4633d-17c
tokens: 7179117
agents: 107
duration_min: 42
verified_at: '2026-09-23'
---

# Zoho Projects e GLPI — a pergunta e o que a medição respondeu

**Pergunta do maestro:** integrar Zoho Projects (como task manager) e GLPI (como **fonte de
atividade** para apuração, relatórios e apresentações) ao Onion via adapters SDAAL — e qual o caminho
de GLPI hospedado/online para self-hosted na VPS **sem reescrever o adapter**.

## Resposta direta — e ela é MENOS confortável do que a primeira leitura sugeria

⚠️ **Esta seção foi reescrita em 2026-09-24**, depois de a REGRA 87 (PR que EDITA um `.kg.yaml`
enxergou os `confirmed` dele) me obrigar a ler as **objeções sobreviventes** do grafo — que eu havia
ignorado ao escrever a primeira versão, por ter trabalhado pelo `summary` do run. As duas principais
**derrubam as duas metades** do que eu tinha afirmado.

**Sobre o GLPI: read-only não é suficiente NEM seguro** (`E_OBJECAO_1`, confiança 0,6 — um agente,
sem votação, mas com fonte primária lida verbatim).

A lacuna é **exatamente a atividade que se quer apurar**. O fórum oficial diz, verbatim: *"The
actiontime field on the ticket itself is just one accumulated total, which isn't enough"* · *"The only
field that we could find that is exportable via the REST API is actiontime"* · *"We also tried the
timetracking plugin, but it doesn't seem to work reliably on GLPI 10.x"*. Um **moderador reconhece a
lacuna** e diz que o suporte na API nova é *"still a work in progress"*. E o workaround real relatado
é **plugin Advanced Dashboard + export CSV — não a API**.

E não é seguro: a própria página v2 diz que a legacy *"in some cases allows more functionality"*. Se a
cobertura empurrar para a legacy, cai-se numa superfície **com escrita** (POST/PUT/DELETE), e a
garantia de read-only por construção evapora.

**Consequência honesta:** o desenho "GLPI como fonte de atividade read-only" continua sendo a forma
certa de **modelar**, mas **não está provado que o GLPI entrega o dado** que o maestro apura. Isso
precisa ser medido na instância real **antes** de qualquer linha de adapter — e o caminho pode ser
export/dashboard em vez de API.

**Sobre o Zoho: o achado pode descrever um meio MORTO** (`E_OBJECAO_2`, confiança 0,55 — um agente,
tier 4 no ponto decisivo).

A página lida é **mista**: expõe endpoints **v2** (`/restapi/portal/.../tasks/`) e **v3**
(`/api/v3/portal/...`) juntos — e há superfície v3 **dedicada a status**
(`GET /api/v3/portal/{Portal_Id}/taskstatushistory`) que o achado ignorou. Pior: uma fonte de
consultoria (tier 4) afirma que **todas as APIs pré-V3 desapareceram em 31/12/2025** e que chamada a
endpoint legacy retorna **404/410 desde 01/01/2026** — e hoje estamos **nove meses depois** desse corte
alegado.

**Consequência honesta:** o `updateStatus` por composição pode estar descrito sobre a v2 morta. A
primária que fecharia a questão — `projects.zoho.com/api-docs` — está **citada e NÃO lida**.

## O que isto muda na ordem de trabalho

Não se escreve adapter nenhum antes de duas medições, e nenhuma delas é leitura de página:

1. **GLPI, na instância real**: existe endpoint que devolva atividade **por período e por pessoa**,
   ou só o `actiontime` acumulado? Se só, o adapter de fonte-de-atividade não tem fonte — e a saída
   é export/dashboard, não API.
2. **Zoho, na primária não lida**: a v2 ainda responde, ou é 404/410? Qual é o contrato v3 de status?

## Os cinco achados que sobreviveram

| # | achado | fonte | voto |
|---|---|---|---|
| 1 | A API GraphQL do GLPI é **somente-leitura, sem mutators** → adapter de LEITURA por construção. ⚠️ **ESTREITADO por `E_OBJECAO_1`**: read-only não é suficiente (a atividade não é exportável) nem seguro (a legacy tem escrita) | help.glpi-project.org (primary, tier 9) | 2-1 |
| 2 | Zoho Projects **não tem endpoint de transição**: status via `Update Task`. ⚠️ **SOB SUSPEITA por `E_OBJECAO_2`**: pode descrever a v2, cortada em 31/12/2025; há superfície v3 dedicada a status que o achado ignorou | zoho.com/projects/help (primary, tier 9) | 2-1 |
| 3 | Existe **GLPI Network Cloud** (SaaS em OVH/Europa, backup diário) → o "online primeiro" é viável | glpi-project.org (primary, tier 7, validFrom 2022-06) | 2-1 |
| 4 | A doutrina de **export é restritiva e nomeada**: só CLI ou HeidiSQL; phpMyAdmin, o menu de Manutenção e PowerShell são **explicitamente desaconselhados** | help.glpi-project.org (primary, tier 9) | **3-0** |
| 5 | A página "Run GLPI with Docker" **não responde** a nada da pergunta — achado por AUSÊNCIA | glpi-project.org (primary, tier 9) | **3-0** |

## O que NÃO sobreviveu, e é o que mais importa declarar

**A premissa confortável caiu.** *"O adapter não precisa ser reescrito porque a API é a mesma em
qualquer hospedagem"* **não sobreviveu aos votos adversariais**. Permanece **hipótese a medir contra a
instância real da empresa** — não achado. Medir significa: subir, restaurar, chamar a API e **contar
os campos**, não ler página de instalação.

**O achado 1 tem ressalva de peso:** ele fala da via **GraphQL**. Não prova que a REST v2 inteira seja
read-only — o GLPI notoriamente escreve por REST. O que está confirmado é que **existe uma via
oficialmente sem escrita**, adequada a um adapter de leitura por construção.

## Mercado: SEM SINAL, e isso é falha do run

O eixo mercado/capital/analistas **não devolveu nenhuma claim confirmada** — zero rodadas, zero M&A,
zero relatório de analista. Isso **viola a invariante `follow-the-money`** e deve ser tratado como
defeito do fan-out, não como conclusão sobre o mundo. Três perguntas ficaram sem resposta, e a
terceira é a que decide o faseamento pelo bolso:

1. A Teclib (empresa por trás do GLPI) tem capital externo — risco de mudar licença ou fechar a API
   atrás do Network?
2. O Zoho Projects é linha viva ou de manutenção dentro do bundle Zoho One?
3. **Qual o preço real do GLPI Network Cloud** por técnico/ativo **versus o custo marginal de subir no
   KVM 8 já pago?**

## Corpus vazio: tudo aqui é desenho novo

Os 101 grafos do repo tinham **zero nós** sobre GLPI, Zoho Projects ou adapter de fonte-de-atividade.
Nada a transferir e nenhuma claim prévia a respeitar — mas também **sem lastro da casa**.

## valeu-a-pena

7.179.117 tokens · 107 agentes · 42 min · 23 nós de grafo → **~312k tokens por nó**, contra ~68-74k
das rodadas de censo. O múltiplo tem explicação e ela é o achado: **corpus vazio não tem o que
transferir**, então cada nó nasceu de coleta externa em vez de reconciliação. Rodada de tema novo
custa ordem de magnitude mais que rodada de revisita — e isso é dado para a próxima decisão de
orçamento, não desculpa.

## Próximos passos, na ordem

1. **Escrever o adapter Zoho** em `.claude/utils/task-manager/adapters/zoho.md`, no molde do
   `asana.md`, com `updateStatus` por composição.
2. **Desenhar o papel "fonte de atividade"** — é categoria nova no SDAAL, irmã de task-manager e
   forge, com contrato de LEITURA (extrair atividade por período e por pessoa), não CRUD.
3. **Medir a instância real** antes de prometer portabilidade online→VPS: subir, restaurar, chamar,
   contar campos.
4. **Rodada complementar de mercado**, porque a invariante não foi satisfeita.
