---
title: "Guia — Operar as sessões do Claude Code no tmux"
category: concepts
tags: [tmux, sessions, terminal, vps, copiar-colar, atalhos, onion-attach]
status: candidato
date: 2026-11-25
---

# Guia — Operar as sessões do Claude Code no tmux

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Categoria** | Concepts |
| **Aplicação** | Entrar, sair, trocar, rolar, copiar e colar nas sessões longas do Claude Code que rodam numa máquina remota |
| **KBs irmãs** | [parallel-work-worktrees-pattern.md](parallel-work-worktrees-pattern.md) (§3.2.1, entrar pelo nome) · [agent-orchestration.md](agent-orchestration.md) |

> Este guia diz **como usar**. O porquê das escolhas fica no grafo
> `docs/onion/graph/onion-attach-2026-11.kg.yaml` (no core). Medido em 2026-11-25, Claude Code 2.1.331 e tmux 3.4.
>
> **Onde vale:** o atalho `onion-attach`, o abridor de sessões e a config da casa vivem hoje na máquina do core.
> No adotante, chegam quando o core levar essa maquinaria (card SAC-546); até lá, os atalhos do tmux (seção 3) e o
> copiar e colar (seção 4) valem em qualquer tmux.

## 1. Para que serve o tmux aqui

A sessão do Claude Code roda na máquina remota, não no seu computador. O tmux mantém a sessão viva quando a
conexão cai ou quando você fecha o terminal. Você sai, volta depois e encontra tudo como deixou.

## 2. As peças, em linguagem simples

| Peça | O que é | Na prática |
|---|---|---|
| **Servidor** | O processo do tmux que guarda as sessões. Cada servidor tem um nome e um arquivo de conexão (socket). | O servidor padrão se chama `default`. Outro servidor se escolhe com `tmux -L <nome>`. |
| **Sessão** | Um espaço de trabalho dentro do servidor. | Uma sessão do tmux por sessão do Claude Code, com o mesmo nome. |
| **Janela** | Uma tela dentro da sessão, como uma aba. | Quase sempre uma só. |
| **Painel** | Uma divisão da janela. | Aparece quando um colega de time (agente nomeado) abre ao lado. |

**Um servidor ou vários?** O padrão decidido pelo maestro em 2026-11-25 é o **servidor único** (`default`). Por
um tempo, a máquina teve um servidor por sessão (`tmux -L <nome>`), para que a queda de um não levasse as outras.
A queda de 2026-11-22 foi medida depois, no registro do sistema (21:44–21:48): a causa foi **falta de memória**, e
servidor separado não protege os processos do Claude Code disso. **Até o abridor de sessões mudar (num ajuste à
parte), a sessão reaberta ainda nasce num servidor próprio.** Depois dessa mudança, cada sessão passa ao servidor
único no seu próximo reinício. Por enquanto convivem os dois tipos.

**Por que o `onion-attach` esconde o `-L`.** Enquanto os dois tipos convivem, quem entra à mão precisa saber em
qual servidor a sessão está: sem o `-L` certo, o tmux procura no `default` e diz que a sessão não existe. O
`onion-attach <nome>` procura em todos os servidores e entra no certo, então ninguém precisa lembrar do `-L`.

**Colegas de time em painéis.** Decisão do maestro (2026-11-25): quando a sessão delega trabalho, o agente
**sempre** recebe um nome. Abrir esse agente num painel ao lado é **opcional**: é a configuração `teammateMode`
do Claude Code, não uma regra da casa.

**Fundo nativo só para tarefa curta.** Decisão do maestro (2026-11-25): a sessão de fundo do Claude Code
(`claude --bg`) serve só para tarefa curta. A sessão que usa a campainha **nunca** vai para o fundo, porque lá ela
perde o canal (seção 7). Para sair de uma sessão sem fechá-la, use `Ctrl-b d`, não o fundo.

## 3. Atalhos

No tmux, todo atalho começa com **`Ctrl-b`**. Aperte `Ctrl-b`, solte, e então aperte a tecla seguinte.

| Atalho | O que faz |
|---|---|
| `Ctrl-b d` | **Sai sem fechar.** A sessão continua rodando. É o jeito certo de sair. |
| `Ctrl-b s` | Lista as sessões **deste servidor** e troca para outra. |
| `Ctrl-b [` | Entra no modo de rolagem e cópia. Setas ou PgUp/PgDn rolam; `q` sai. |
| `Ctrl-b o` | Vai para o próximo painel. |
| `Ctrl-b` + setas | Vai para o painel daquele lado. |
| `Ctrl-b z` | Amplia o painel atual para a janela toda; repita para voltar. |
| `Ctrl-b x` | Fecha o painel atual (pede confirmação). |
| Roda do mouse | Rola o histórico. Um clique escolhe o painel. |

Para fechar a **sessão do Claude Code**, use `/exit` dentro dela, nunca `Ctrl-b x` no único painel.

## 4. Copiar e colar

| Quero | Como |
|---|---|
| Copiar texto da sessão | Arraste com o mouse. Ao soltar, o texto deve ir para a área de transferência do seu computador (protocolo OSC 52). |
| Se isso não copiar | Segure **Shift** enquanto arrasta: a seleção passa a ser do seu terminal local, sem o tmux no meio. |
| Colar na sessão | `Ctrl+Shift+V` (no Windows Terminal). O botão direito, sem Shift, abre o menu do painel do tmux; com Shift, é o do seu terminal. |
| Mandar uma imagem | Pelo claude.ai. A imagem **não passa pelo terminal** (seção 7). |

**O que foi medido e o que não foi.** O tmux 3.4 aceita a config da casa, e o botão direito abre o menu do
painel (medido em 2026-11-25). A cópia pelo mouse até o computador local **não** foi medida de ponta a ponta:
ela depende do terminal local aceitar o OSC 52 (o Windows Terminal é feito para aceitar, e o mosh 1.4 repassa a
sequência). Se o app dentro do painel captura o mouse, o arrastar vai para o app e não para o tmux; aí, Shift +
arrastar.

**A config da casa.** O comportamento acima vem de uma config do tmux versionada no core: mouse ligado,
rolagem de 50.000 linhas e cópia ao soltar o mouse, que vai à área de transferência por OSC 52. Duas coisas ficam
de fora de propósito: o programa que roda no painel **não** escreve sozinho na sua área de transferência
(`set-clipboard external`, só a cópia que você faz com o mouse vai), e o tmux **não** deixa passar ao seu terminal
as sequências especiais do programa (`allow-passthrough` desligado), que poderiam trazer conteúdo não confiável.
Para instalar:

```bash
onion-attach --install-tmux --check     # só confere se ela já está instalada e em dia (não escreve nada)
onion-attach --install-tmux --dry-run   # mostra o que faria
onion-attach --install-tmux             # instala e recarrega nos servidores vivos
```

Instalar faz duas coisas:

1. **Copia a config para `~/.config/onion/tmux.conf`**, um lugar fixo fora do repo. O tmux nunca lê direto do
   repo: trocar de branch mudaria a config que está valendo, e uma config de tmux pode rodar comandos. Se já havia
   uma cópia diferente, ela vai antes para um backup com data, e a cópia nova é conferida contra a do repo.
2. **Acrescenta uma linha ao seu `~/.tmux.conf`**: `source-file -q ~/.config/onion/tmux.conf`. O que você já tinha
   no arquivo fica como estava: nada é sobrescrito nem apagado.

Rodar de novo não muda nada. Para atualizar a config depois que ela mudar no repo, rode o `--install-tmux` de
novo; o `--check` diz se a cópia está atrasada. Ele recusa quando `~/.tmux.conf` (ou a cópia) é um link, de um
repo de configurações por exemplo, para não escrever através dele. Um servidor que não recarregou é dito pelo
nome. A rolagem maior vale nos painéis abertos depois da recarga. Quem tem também `~/.config/tmux/tmux.conf` precisa conferir esse arquivo: o tmux o lê depois e
ele pode desfazer a config da casa.

## 5. Entrar, sair e reabrir

| Situação | Comando |
|---|---|
| Ver todas as sessões e o comando de cada uma | `onion-attach` |
| Entrar numa sessão pelo nome | `onion-attach <nome>` |
| Ver o que ele faria, sem fazer | `onion-attach <nome> --dry-run` |
| Instalar o atalho (uma vez) | `onion-attach --install` (cria o link em `~/.local/bin` e avisa se essa pasta não está no `PATH`) |
| Abrir uma sessão nova com nome | o abridor de sessões do core, com `--new` |
| Reiniciar uma sessão sem perder trabalho | `/meta:restart` dentro dela: espera os agentes, grava onde parou e mostra o comando de reabrir pelo id |

O `onion-attach <nome>` acha a sessão onde ela estiver:

- **No tmux**: entra no servidor certo. **De dentro de uma sessão, `onion-attach <outra>` troca direto**: no
  mesmo servidor, troca de sessão; noutro servidor, o tmux desliga o seu terminal da sessão atual e, no mesmo
  terminal, entra na outra. Nunca abre um tmux dentro de outro. **Só troca se este for o único terminal na sessão
  atual**: com dois (o computador e o celular, por exemplo), o tmux poderia levar o outro terminal em vez deste.
  Aí ele avisa quantos terminais há e pede para você sair com `Ctrl-b d` e rodar `onion-attach <outra>` de fora.
- **No fundo nativo do Claude Code**: entra com `claude attach <id>`. De dentro do tmux, isso roda no próprio
  painel: você não sai do tmux.
- **Fechada**: acha a conversa mais recente com aquele nome e a reabre pelo abridor de sessões, com o id e a
  pasta certos.

## 6. Quando algo some

| Sintoma | O que fazer |
|---|---|
| «a sessão sumiu» | `onion-attach` lista o que está vivo. Se ela não aparece, `onion-attach <nome>` a reabre pela conversa. |
| «não sei o id» | Não precisa saber: `onion-attach <nome>` acha o id pelo nome da conversa. |
| «ele disse ambíguo» | Há duas conversas com o mesmo nome que mudaram quase juntas, ou em pastas diferentes. Ele lista as duas, com data; escolha com `onion-attach <nome> --resume <id>`. |
| «saí da sessão e caí no terminal de fora» | A sessão de destino sumiu entre a saída e a entrada. A sessão de onde você saiu continua viva. Rode `onion-attach <nome>` de novo. |
| «ele disse que há 2 terminais nesta sessão» | Outro terminal (o celular, por exemplo) está na mesma sessão. Saia com `Ctrl-b d` e rode `onion-attach <outra>` de fora do tmux. |
| «reabri a sessão fechada e ele disse para sair com Ctrl-b d» | A sessão fechada é reaberta pelo abridor de sessões, que ainda pede para sair antes quando você está dentro do tmux. Saia com `Ctrl-b d` e rode `onion-attach <nome>` de novo. |
| «avisou que a conversa tem outro título» | O id que você passou em `--resume` é de uma conversa com outro nome. Confira o id; se estiver certo, ela reabre com o nome que você pediu. |
| `tmux attach` diz que não há sessão | A sessão pode estar noutro servidor. Use `onion-attach <nome>`, que procura em todos. |
| Copiar com o mouse não funciona | Shift + arrastar. Depois confira se a config da casa está ligada (`onion-attach --install-tmux --check`). |
| Saí e a sessão fechou | Para sair sem fechar é `Ctrl-b d`. Reabra com `onion-attach <nome>`. |

## 7. Limites medidos

- **O fundo nativo perde a campainha.** A sessão de fundo do Claude Code (`claude --bg`) não carrega o canal da
  campainha: retomar uma sessão no fundo com a flag do canal abre uma **cópia** com outro id. O defeito foi
  relatado ao Claude Code (issue anthropics/claude-code#90160, aberta). Por isso as sessões longas ficam no tmux,
  e o fundo nativo é só para tarefa curta.
- **A imagem não passa pelo terminal.** Colar imagem no Claude Code por um terminal remoto não funciona, e o
  pedido foi fechado pelo Claude Code como «not planned» (issue anthropics/claude-code#42712). Imagem vai pelo
  claude.ai.
- **O OSC 52 leva só texto.** A cópia pelo mouse leva texto, não imagem. Pelo mosh, ela só passa a partir da
  versão 1.4.0.
- **O daemon do fundo nativo some com o reboot.** Depois de um reinício da máquina, as sessões de fundo não voltam
  sozinhas. As do tmux também não: elas são reabertas pelo abridor de sessões, cada uma pelo seu id.
- **A sessão interativa fora do tmux não se anexa.** O `onion-attach` diz onde ela roda; entre pelo terminal dela.
- **Nome com sufixo « (2)».** Quando dois nomes colidem, o Claude Code acrescenta « (N)» ao título, e a busca do
  `onion-attach` pelo nome exato não acha essa conversa.

## 8. Resumo

| Faça | Não faça |
|---|---|
| Sair com `Ctrl-b d` | Fechar o terminal com a sessão no meio de uma pergunta |
| Entrar com `onion-attach <nome>` | Adivinhar o servidor ou o id |
| Copiar arrastando (ou Shift + arrastar) | Selecionar em modo de cópia sem a config da casa |
| Reiniciar com `/meta:restart` | Abrir uma 2ª sessão no mesmo checkout |
