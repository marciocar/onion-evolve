# Sinal ao core — a `D_FRONTEIRA` decide pessoa × federação; falta pessoa × EMPREGADOR

**Data:** 2026-09-13 · **Repo:** jogo-da-vida (adotante) · **Endereçado a:**
`docs/discussions/onion-pessoal-marcio/proto/fronteira-decision.kg.yaml` (`Q_FRONTEIRA` e `D_FRONTEIRA`, os dois `open`)

Este sinal **não pede** que o core decida por nós. Ele traz **três medições que o adotante tem e o core não**,
nomeia um **eixo que a decisão atual não cobre**, e propõe **como fechar a questão em conjunto** — com o que
cada lado põe na mesa.

## O que já está decidido lá, e está bem decidido

- **P3:** falsa dicotomia — *membro adotante pelo método, soberano no dado*.
- **P4:** a postura de privacidade já está certa; o elo sem cifra é a **inferência**.
- **P5:** para o dono, **inferir é o produto**; a defesa são camadas negativas na **fronteira**; a inferência
  interna é indefesa por construção — **nomeada, não escondida**.

Nada disso precisa ser refeito. O que segue é ortogonal.

## O eixo que falta

`D_FRONTEIRA` resolve **pessoa × federação**: como um Onion pessoal se registra, que confiança tem, o que sai
como destilado verificável. É a fronteira com o **mundo técnico**.

A fronteira que decide o **Company Brain** é outra: **pessoa × empregador**. E ela tem uma assimetria que a
primeira não tem — **relação de poder**. Um indivíduo escolhe federar-se; um colaborador não escolhe da mesma
forma, e "consentimento" sob contrato de trabalho não é o mesmo objeto que consentimento entre pares.

**A pergunta que falta, e da qual tudo decorre:** *dado de nível individual entra no grafo da empresa —
sim ou não?*

## As três medições que o adotante traz

### 1. O corpus do autor é SILENCIOSO sobre o contrapoder do trabalhador

Medido em *O Jogo dos Negócios* (4.640 linhas, do mesmo autor, sobre gamificar a própria empresa):
`opt-out` · `sair do sistema` · `sindicat` · `negociação coletiva` · `retificaç` · `direito de acesso` ·
`titular` · `portabilidade` · `contestar` · `recusar` → **zero ocorrências**.

E `manipular` aparece **6 vezes**, em **todas** com o participante ou o behaviorista como sujeito — **nunca o
desenhista manipulando o participante**. A ética do livro tem duas pernas (o participante não trapaceia; o
dado é protegido); **a terceira — o sistema não abusa da pessoa — não está lá**.

**Consequência para o core:** a fundamentação do produto **não fornece** a ética de proteção do colaborador.
Ela terá de ser escrita, e escrita conscientemente, e não herdada.

### 2. A régua para decidir já está no corpus, e prevê o resultado

O mesmo livro adota a **Teoria da Autodeterminação** (Deci e Ryan): autonomia, competência, relacionamento. E
o lado negativo é explícito: necessidades **frustradas** fazem a motivação virar *"controlada ou **alienada**,
o que pode resultar em menor engajamento e qualidade de vida"*.

**Um Company Brain que colete sem devolver autonomia produz, pela teoria que o próprio corpus adota, motivação
alienada.** Não é proibição — é **previsão**. Serve como teste de qualquer feature: ela devolve autonomia,
competência e relacionamento, ou consome?

### 3. Já rodamos o experimento que essa decisão precisa — e a opção ingênua FALHOU

Isto é o que o adotante tem de mais útil, porque é **medição em produto vivo**, não raciocínio.

No Jogo da Vida, times mostram **Karma agregado** e eventos **nominais** (quem pediu ajuda, quem deu emblema).
Na passada adversarial `Q_OPS_KARMA_EVENTS_NOMINAL` (2026-09-09), a opção *"mostrar o número alheio só com
opt-in do próprio dono"* foi **REFUTADA** — e a razão transfere inteira para o Company Brain:

> **agregado com consentimento parcial vaza o indivíduo por diferença.** Num time pequeno, "quem não aparece
> no agregado" identifica a pessoa. É aritmética, não política — e nenhuma salvaguarda de acesso a resolve.

A opção *"anonimizar os eventos"* também caiu, por outro motivo: **a dois ou três, o anônimo é dedutível**, e
esvaziar o nome mata o reconhecimento, que era o ponto.

**O que sobreviveu** foi (b): o cuidado é **nominal por desenho**, nenhum número de terceiro é somável, e **a
tela declara o limite antes do consentimento**. Está em produção.

**Tradução para o Company Brain:** *"a empresa só vê agregado"* e *"o indivíduo dá opt-in"* são as duas
opções que **já foram refutadas** no pequeno. Se falham em time de cinco, não melhoram em empresa de
quinhentos — pioram, porque há mais eixos de diferença.

## A proposta de desenho (entrada, não selo)

**O Company Brain é o cérebro reconciliado da ORGANIZAÇÃO — suas decisões e as consequências delas — não um
cérebro SOBRE as pessoas.** Colaboradores entram como **autores de decisões**, não como dados.

É o que o MAAGICA manda, e está na primeira letra da sigla: **AUTO**rregulação — quem regula é **quem
aprende**. Se a empresa é o sujeito que aprende, o grafo é sobre ela: *"decidimos X em março, executamos
assim, o resultado foi Y — redesenhar"*. Que é exatamente o que o Onion já faz para um repositório.

E resolve o problema comercial sem o dilema: o valor não é saber o que o colaborador fez — é **a empresa
parar de reaprender o que já decidiu**.

Salvaguardas que decorrem das medições, não de opinião:
1. **Nada de agregado com consentimento parcial** (refutado acima, por diferença).
2. **Visibilidade simétrica**: se a empresa computa, a pessoa vê que foi computado — corolário direto da P5
   ("nomeada, não escondida").
3. **Nenhuma consequência automática sobre a pessoa**: sem pontuação, sem ranking, sem "quem está atrasado".
4. **Sair sem prejuízo** — e é aqui que o corpus não ajuda: essa parte não existe nele.
5. **O "Exército de Fiscais" do livro NÃO atravessa.** Recompensar participantes por monitorar colegas é
   cooperação numa sala de aula e **vigilância entre pares** numa relação de emprego. Texto idêntico,
   natureza diferente, por causa da assimetria de poder.

## Como fechar em conjunto (o pedido concreto)

O adotante não quer que o core decida sozinho, nem decidir sozinho. Proposta de divisão:

| lado | o que põe |
|---|---|
| **core** | o **eixo novo** como nó em `fronteira-decision.kg.yaml` (pessoa × empregador, ao lado de pessoa × federação) e o selo — é frente do core, o adotante é consumidor |
| **adotante** | o **banco de provas**: o Jogo da Vida tem times reais, agregado, eventos nominais e um risco de dedução **já medido e documentado**. É o N=1 que pode **falsear um desenho antes de existir cliente** |
| **conjunto** | o **critério de falseamento**: se num time de 3 a 5 pessoas o agregado somado aos eventos reconstrói o indivíduo, o desenho caiu. Já sabemos que **reconstrói** — a pergunta aberta é se existe forma que não reconstrua, ou se a resposta é não coletar |

**O que o adotante pede ao core:** abrir o eixo como nó e dizer se aceita o banco de provas. Se aceitar,
qualquer proposta de desenho do Company Brain pode ser testada aqui **antes** de virar produto — e falhar
barato, em cinco pessoas, em vez de caro, em quinhentas.
