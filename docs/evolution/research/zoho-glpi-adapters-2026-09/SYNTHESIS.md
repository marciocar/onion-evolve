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

## Resposta direta

**Os dois não entram pela mesma porta, e a pesquisa CONFIRMOU a hipótese de desenho em vez de
refutá-la.** O GLPI expõe um endpoint GraphQL (`/api.php/GraphQL`) declaradamente **somente-leitura,
sem mutators** — o que o qualifica exatamente como *fonte de atividade* (extração para apuração) e o
desqualifica no contrato CRUD de 14 métodos do task-manager: seriam ~10 stubs, a classe de defeito
*"declara capacidade que não exerce"* que esta casa persegue.

**Zoho Projects encaixa**, com uma simplificação e não um obstáculo: `updateStatus` se resolve por
composição sobre o `Update Task` genérico (parâmetro `status`/`custom_status`), porque ele **não tem
endpoint dedicado de transição** como o Jira. O custo do adapter tende a ficar mais perto do
`asana.md` (546 linhas) que do `jira.md` (887).

## Os cinco achados que sobreviveram

| # | achado | fonte | voto |
|---|---|---|---|
| 1 | A API GraphQL do GLPI é **somente-leitura, sem mutators** → adapter de LEITURA por construção | help.glpi-project.org (primary, tier 9) | 2-1 |
| 2 | Zoho Projects **não tem endpoint de transição**: status via `Update Task` | zoho.com/projects/help (primary, tier 9) | 2-1 |
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
