---
tipo: sinal-upstream
origem: rhilo-metagamify (adotante)
destino: onion-evolve (core)
data: 2026-07-16
assunto: "MANDA A DOUTRINA — KG-first não pode ser conselho, tem que ser mecanismo (prova fresca de reincidência)"
fluxo: feedback (adotante → core)
prioridade: alta
relacionado:
  - docs/evolution/inbox/2026-07-16-ssot-como-runtime-para-adr.md
  - docs/evolution/inbox/2026-07-16-kg-sdaal-dogfood-ouro.md
---

# 🔧 Manda a doutrina — KG-first tem que ser MECANISMO, não conselho

> **Pedido do maestro (verbatim):** "avise ao core sobre isso para ele mandar a doutrina."
> Os dois sinais anteriores **descreveram** a doutrina (SSOT = runtime; ciclo read→verify→act→write;
> KG-first + drive-to-verify; cabear nos loops). Este pede que o core a **CODIFIQUE E DISTRIBUA como
> mecanismo enforced** — porque temos agora a prova empírica de que **descrever não basta.**

## 1. A prova fresca: reincidência DEPOIS de eu ter escrito a doutrina

Na mesma sessão em que enviei "o SSOT precisa ser o runtime dos comandos", eu (o assistente) **voltei a violar**:
- montei um **plano de redesenho** do WRR inteiro **sem consultar o KG primeiro** — raciocinei da conversa +
  medições da sessão;
- só depois que o maestro perguntou "você está fazendo SSOT-first?" eu consultei — e o grafo **corrigiu 4
  coisas que eu erraria**: janela 7d→**14d medido** (`C_WINDOW_SWEEP`), morte-da-chamada só-TTL→**sinal +
  derivação** (`C_ABANDON_PUSHED`/`Q_URANO_SIGNAL`), conflito com **`I_NO_AGE_RELEASE`**, e o fato de que
  metade do redesenho **já existia como nó** (`R_DOSEPARAMETA`, `R_ADR018`, a máquina `S_RESERVED→…→S_LIMBO`).
- o maestro então perguntou: **"por que você não faz SSOT-first por padrão?"** A resposta honesta: **porque
  não há forcing function** — o KG não está no meu contexto por default, e "lembrar" é um valor que eu aplico
  à mão e falho (≥4× nesta linha de trabalho).

**Conclusão dura:** conselho-que-depende-de-lembrar **já falhou empiricamente**, inclusive com quem escreveu
o conselho. Só **mecanismo** conserta. A reincidência É o dado.

## 2. A hierarquia de forcing-function (do mais fraco ao que só o core entrega)

| Nível | Trava | Quem instala | Alcance |
|---|---|---|---|
| memória `feedback` | recall automático | o adotante (feito) | 1 projeto, lembra mas não obriga |
| regra no `CLAUDE.md` | contexto de toda sessão | o adotante | 1 projeto |
| **hook** (`UserPromptSubmit`/`SessionStart`) | injeta/roda `kg-state` a cada prompt | adotante **ou core (template)** | forte, mas cada um reinventa |
| **comandos cabeados** (`catch-up`/`warm-up`/`work` consultam o KG) | trava no runtime do framework | **só o CORE** | **todos os adotantes, uniforme** |

Os 3 primeiros o adotante improvisa. **O 4º é o que só o core entrega — e é o único que escala pra todo mundo.**

## 3. O pedido concreto — "manda a doutrina"

1. **Codificar** a doutrina como artefato canônico do core (não só na ADR): o ciclo obrigatório
   **read(KG)→verify(vivo)→act→write(KG)**, KG-first, citar id de nó, frescor em todas as camadas.
2. **Cabear nos loops:** `catch-up`/`warm-up`/`work` DEVEM, quando existir um `.kg.yaml`, consultá-lo ANTES
   de reconstruir de git/memória (é o SSOT de "onde estamos", acima do git).
3. **Shippar um hook-template** de KG-first (auto-load/auto-query do grafo no `UserPromptSubmit`), pra o
   adotante não reinventar a trava.
4. **Distribuir via `inbound/`** — mandar a doutrina + o mecanismo PARA os adotantes (downstream), pra que
   chegue enforced em cada instância, não como leitura opcional.
5. Formalizar `kg state` (projeção de estado-de-trabalho) como 1ª classe, irmão do radar (já pedido no sinal ADR).

> **Se o core fixar UMA coisa deste sinal:** a doutrina só vira runtime quando é **carregada e verificada
> automaticamente como primeiro ato** — provado pela minha própria reincidência. Documentar o KG-first e
> deixar o consumidor "lembrar" reproduz exatamente o bug do SLOT-limbo: um estado que depende de um evento
> que nunca chega. Manda a doutrina como mecanismo.

— sinal do adotante `rhilo-metagamify`, sessão 2026-07-16 (escala o par "ouro" + "ssot-como-runtime").
