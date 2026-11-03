---
title: Orquestração de sessões — o caso de 2026-11-03 e o mecanismo em degraus
date: 2026-11-03
kg: docs/evolution/research/session-orchestration-2026-11/session-orchestration-2026-11.kg.yaml
run_id: "nenhum (sem Workflow: estudo escrito pela sessão do core a partir do próprio diário)"
tokens: 0
agents: 0
duration_min: 30
review_after: 2026-12-03
type: research
mode: estudo de caso
nota: "tokens 0 = não medido; o custo da janela está nos estudos que ela produziu (spikes das portas, comandos do vigia)"
---

# Orquestração de sessões — o caso de 2026-11-03

**O pedido do maestro:** gravar as estratégias da orquestração da viagem para virar um mecanismo do Onion Core,
automático ou semiautomático, com papéis e funções. O mecanismo deve casar com o vigia de eventos, o A2A e o grafo de
coordenação. O [DIARIO.md](DIARIO.md) é o registro em primeira mão. Este estudo é o que dele vira proposta.

## O que o caso mostrou (`E_SO_JANELA_DE_2026_11_03`)

Durante cerca de 10 horas, o core orquestrou a curadoria e o kg-ssot sem o maestro no terminal. As revisões
cruzadas pegaram mais de 60 achados reais antes de qualquer veredito valer. Cada repo executou e fez merge só do que
era dele.

| Nó | O que vira regra candidata |
|---|---|
| `C_SO_TRES_PAPEIS` | Três papéis: orquestrador e construtor, dona da especificação e revisora adversarial, fornecedora de medida e revisora técnica |
| `C_SO_RODIZIO_DE_CPU_E_LOCK_SOCIAL` | A CPU compartilhada foi coordenada por lock social declarado, e nada o faz cumprir |
| `C_SO_REVISAO_EM_TRES_CAMADAS` | Desenho, código e processo: o processo reprovou um executor cujo código já tinha passado |
| `C_SO_REGRA_DO_MEDIDOR` | Instrumento mudou, roda tudo de novo; reclassificar acrescenta, nunca sobrescreve |
| `C_SO_FRASE_DE_VEREDITO_DO_INSTRUMENTO` | Toda frase de veredito cita o campo que a produz, ou se declara feita à mão |
| `C_SO_DONO_DA_ESPEC_JULGA_A_SEMANTICA` | Quem escreveu a especificação julga a semântica; quem constrói negocia nomes, não critérios |
| `C_SO_RITMO_POR_EVENTO_E_AUTORIZACAO_DATADA` | Acordar por evento, com reserva de 25 a 30 minutos; agir sob autorização com validade escrita |

## O mecanismo proposto (`D_SO_MECANISMO_EM_DEGRAUS`, aberto)

1. **Degrau 1 (hoje):** o diário e o grafo de coordenação, mantidos à mão pela sessão orquestradora.
2. **Degrau 2 (semiautomático):** o vigia de eventos e o grafo de coordenação alimentam um **rascunho** da próxima
   fila, com papel, dono e lease de CPU. O humano aprova. Usa o que já existe ou está em PR: a pendência com dono do
   grafo de coordenação, o registro de rascunhos do vigia (PLAN-E, em PR, #1461, no fecho deste estudo), o canal entre sessões e o A2A com aceite humano. A peça
   nova é o **lease de CPU**, que hoje é lock social.
3. **Degrau 3 (automático em escopo):** despacho por A2A entre sessões, dentro de uma autorização datada. Merge
   alheio, deploy e segredo seguem do maestro em qualquer degrau.

## Gatilho (`Q_SO_GATILHO_DE_CONSTRUCAO`, `Q_SO_PADROES_DE_MERCADO`)

O caso é um só (N=1): as linhas da tabela acima são observações desta janela, e como regra geral são candidatas. O
degrau 2 só se constrói com duas condições:
- três janelas registradas pelo mesmo diário, ao menos uma com outro tipo de trabalho, cada uma com os três papéis
  e ao menos 5 das 7 regras observadas. Papéis diferentes numa janela de outro trabalho refutam `C_SO_TRES_PAPEIS`
  como geral;
- a pesquisa de mercado feita antes, pelo `/onion-research`. Ela pergunta que padrões já cobrem papéis entre
  agentes, reserva de recurso e passagem de tarefa com aceite, como o ciclo de tarefa do A2A aberto. O perfil do
  Onion vai por cima, e cunhagem só entra onde o mercado não tiver.

## NÃO-VERIFICADOS

- Nenhuma busca de mercado foi feita nesta rodada. Por isso `Q_SO_PADROES_DE_MERCADO` está aberta.
- Os papéis podem ter emergido das peças desta janela (spikes e vigia), e não da natureza das sessões. Só uma
  segunda janela com outro trabalho separa as duas coisas.
- O custo em tokens da orquestração em si (mensagens, despertares) não foi medido à parte.

## Valeu a pena

Este estudo custou cerca de 30 minutos de escrita sobre um diário já existente. Ele transforma 20 estratégias soltas
em 7 regras candidatas, um desenho em degraus e um gatilho com nome, sem construir nada antes da hora.
