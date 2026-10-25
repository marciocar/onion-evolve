---
title: "Dissecação do canal entre sessões neutro do agente: parquear com gatilho (o fio e a guarda já são neutros)"
date: "2026-10-25"
from: onion-curation
to: onion-evolve
type: proposal
kg: docs/evolution/dissect/agent-neutral-channel-2026-10/agent-neutral-channel-2026-10.kg.yaml
decision_node: D_AGENT_NEUTRAL_CHANNEL_VERDICT
---

# Canal entre sessões neutro do agente: veredito proposto PARQUEAR (SAC-248)

> Rascunho, não relayado. Proposta da curadoria: aqui nada é selado, e a palavra final é do core.
> Contraparte no core: `Q_CANAL_ENTRE_SESSOES_NEUTRO_DO_AGENTE_1025`.

## Veredito

**Parquear com gatilho.** Pela régua pré-registrada (STAGE0 v1 e emenda N2 v2), nenhum eliminatório dispara.
Os pontuados dão 5 de 10: P1=1, P2=1, P3=1, P4=1 e P5=1. O nível mais alto que se sustenta é o N2, porque o N3
não fecha: o custo contra o ganho não foi medido.

A candidata que supera na trajetória local é o **MCP Agent Mail**. Ela entrega coordenação entre sessões de
Claude Code, Codex e Gemini CLI no mesmo projeto ou máquina. Não supera o canal gated entre organizações.

**Gatilho:** o parque reabre quando um nó superar `C_NO_NON_CLAUDE_ROUNDTRIP`: um round-trip medido entre uma
sessão Claude e uma sessão não Claude por um adapter nomeado. Teria de ser pelo git-async ou pelo local, porque o
a2a-live só serve para enviar ao standalone onion-codex, que é vetado como receptor. O gatilho original ancorava no
`E_N1`, que carrega estado transitório, e o Elenxo pediu a troca (`E_OBJECAO_TRIGGER_ANY_SUPERSESSION`).

**Fragilidade declarada:** o P5 = 1 se apoia numa via de bilhetagem indireta e não verificada. Com P5 = 0, o total
cai a 4, sem folga até o rejeitar (`E_OBJECAO_P5_VIA_UNVERIFIED`).

**O que o core pode fazer barato, sem perseguir:**
- tratar a percepção (o aviso) e a triagem como as únicas peças a portar, por AGENTS.md e Agent Skills, os padrões
  da AAIF que o onion-codex já usa;
- para a coordenação local entre agentes, avaliar o MCP Agent Mail em vez de construir.

## Evidência por nível

- **N0 (análogos)**
  - O MCP Agent Mail tem 2,2 mil estrelas e 888 commits, e traz configs prontas para Codex e outros agentes.
  - Cada agente tem identidade por projeto. Entre projetos, o contato passa por `request_contact` e
    `respond_contact`, com aprovação. O transporte aceita bearer ou JWT com JWKS.
  - Faltam assinatura por mensagem, pinagem de chave, gate de topologia e aceite humano declarado.
  - A AAIF hospeda A2A, MCP, AGENTS.md e Agent Skills (aaif.io/projects, lido direto). Isso resolve o elo
    A2A–AAIF que o a2a-product deixou aberto.
  - Hooks do Codex com o envelope de SessionStart: informado, não verificado.
- **N1 (valor e consumidor)**
  - Os únicos consumidores nomeados são o maestro e o porte onion-codex. O onion-codex é standalone, de kind port,
    sem bloco `a2a:`. O clone local não tem commit desde 2026-09-16.
  - Nenhum consumidor de fora foi medido.
  - Divergência menor com o CORE-STATE: o onion-codex também tem `can_receive_from: [onion-evolve]`.
- **N2 (experimento)**
  - O E2 não dispara e o P3 vale 1 (n2-result.json, core 49dfa06b, bridge 5819d8e).
  - Ressalva (b), receptor no bridge: o fecho de import de a2a.ts e a2a-routes.ts toca 6 arquivos. O SDK só
    aparece por um `import type` em chat-runner.ts, via config.ts, e esse import some na execução. O que é Claude
    é o processo que hospeda o receptor (o mesmo Hono serve o /chat), não o código do recebimento.
  - Ressalva (c), moat: o moat-gate veta deploy, escrita em repo alheio e agendamento por relógio. Ele protege a
    sessão, e o a2a-send.sh não o cita.
  - Percepção: o hook emite o envelope `hookSpecificOutput` de SessionStart. O `mail-receiver.sh` avisa o humano,
    e não a sessão.
  - E3 não dispara: o CLAUDE.md fixa a postura de manter independência quando ela for mais vantajosa, e o
    onion-codex segue como linha viva.
- **N3 (viabilidade)**: não se sustenta. O custo de portar a percepção, a triagem e o aceite, mais uma bancada com
  vários agentes, não foi medido. Sem uma sessão não Claude em uso, o ganho é especulativo.

## Superação

Busca no corpus (kg_query com 10 termos) e na web (busca extended e README).

- **Superação parcial medida:** o MCP Agent Mail, para coordenação local entre agentes de fornecedores
  diferentes.
- **Nenhuma** para o canal gated entre organizações.
- **Peças neutras prontas para o porte:** AGENTS.md e Agent Skills, que o onion-codex já usa.

## Ação barata que não exige perseguir

- Tratar só a percepção e a triagem como peças a portar.
- Avaliar o MCP Agent Mail para a coordenação local, em vez de construir.
- Separar o receptor do processo do /chat, se um dia o canal precisar ser neutro também no deploy.

## Não verificado

Está em `meta.x_unverified` no grafo.

- Os hooks do Codex: SessionStart, PreToolUse com exit 2 e entrada de confiança. A página oficial não foi aberta.
- O MCP Agent Mail além do README: licença, se a aprovação é humana, e a versão em Rust.
- Nenhum round-trip vivo foi feito.
- O veto `receiver-not-a-receiver` não foi lido.
- Os handshakes de julho.
- A atividade do remoto do onion-codex.
- O custo contra o ganho.
- A adoção do AGENTS.md, que é número da própria fundação.
- Orçamento: a 6ª chamada web caiu num redirect, sem conteúdo, e o redirect não foi seguido.

## Quem paga

Ninguém paga hoje pelo canal neutro.

- Os padrões (A2A, MCP, AGENTS.md e Agent Skills) são da AAIF, paga por dues.
- O MCP Agent Mail é gratuito, e só o app companheiro é comercial, sem preço publicado.
- Via de bilhetagem no Onion: indireta e não verificada. Seria um relay ou receptor hospedado para equipes que
  misturam Claude Code e Codex. O fio não abre via.
