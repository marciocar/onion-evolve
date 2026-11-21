# Doutrina da catraca de decisões — quem decide cada ato, e como se explica e se audita

> **Versão**: 1.0.0 | **Última atualização**: 2026-11-21 | **Categoria**: Conceitos
> Cada ato de uma sessão cai numa **classe** medida pelo próprio ato. A classe diz **quem decide**:
> o automático (A), o «pode rodar» digitado pelo maestro (B) ou só o maestro (C). A **força da prova**
> (como a aprovação mostra quem a deu) é outro eixo, separado. A catraca **só afrouxa com histórico
> medido** e **aperta na hora** quando há incidente. E ela declara o que **não** garante.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-11-21 |
| **Última Atualização** | 2026-11-21 |
| **Categoria** | Conceitos |
| **Origem** | Consulta Delphi de 7 sessões da família (20/11/2026) e três selos do maestro no mesmo dia (abaixo). Delphi é o método em que cada participante responde sem ver os outros, as posições circulam sem autor e uma síntese vai ao decisor |
| **Grafo** | `docs/onion/graph/coordenacao-selos-arquivo-2026-11.kg.yaml` (core-only): `D_DECISION_RATCHET_SYNTHESIS_SEALED_1120`, `D_RATCHET_CLASS_B_VALID_NOW_1120`, `D_RATCHET_AUTO_ONLY_NON_STATE_CHANGING_1120` |
| **ADR** | [Catraca de decisões automáticas](../decisions/onion-adr-decision-ratchet-2026-11.md): as opções pesadas e o dissenso |
| **Estado** | **Em observação.** A régua não está ligada e nenhum ato desceu de classe. O que já roda está em §9 |
| **Padrões-irmãos** | [Dogfooding](onion-dogfooding-doctrine.md) (rodar de verdade antes de afirmar) · [Base atual, sempre](keep-current-doctrine.md) (a regra mora num gatilho, não na memória) |

---

## 🎯 Por que esta doutrina existe

O maestro selou a síntese da catraca em 20/11/2026 com uma condição: **documentar para explicação e
auditoria**. Duas perguntas têm de ter resposta escrita:

1. **Explicação:** por que este ato rodou sozinho, ou por que pediu o maestro?
2. **Auditoria:** um terceiro consegue conferir, depois, que a regra foi seguida?

O problema é medido. Numa colheita de 20 dias (01 a 20/11/2026) nas sessões do core, o maestro respondeu
**213 formulários** (507 perguntas) e digitou **85 comandos `!`**. Foram de 2 a 34 intervenções por dia.
Os merges sozinhos somaram cerca de 94 cliques. Parte disso pode descer de classe com segurança. Parte
nunca pode. A catraca é a regra que separa as duas.

**Glossário curto:**

- **ato**: uma ação concreta (um comando, uma chamada de ferramenta) sobre um alvo (um caminho, um repo,
  um serviço).
- **catraca**: regra que gira num só sentido sem prova. Aqui, a classe só desce com histórico medido e
  sobe na hora com incidente.
- **classe**: quem decide o ato (A, B ou C).
- **força da prova**: como a aprovação mostra quem a deu (1, 2 ou 3).
- **livro**: o registro das decisões, só de acréscimo.
- **reversão**: o ato teve de ser desfeito (revert, rollback, recusa do maestro depois do fato).

---

## 1. Dois eixos, nunca um só

A palavra «nível» já significava quatro coisas na casa, e uma delas usava a numeração **invertida**
(no «pode rodar», nível 2 é *mais* forte; numa proposta da catraca, nível 2 era *só o maestro*). O mesmo
número diria coisas opostas no mesmo script. Por isso a catraca usa **letra** para quem decide e
**número** para a força da prova.

### 1.1 Classe: quem decide

| classe | quem decide | o que entra (quando a régua ligar) |
|---|---|---|
| **A** | o automático, com aviso e registro | **só ato que não muda estado**, na lista do selo: ler no privilégio de quem pede, responder no fio do pedido, medir, re-carimbar um nó do grafo. Responder e re-carimbar escrevem algo, mas o selo os conta como «não muda estado»: não mexem em código, serviço nem permissão |
| **B** | o maestro, digitando **«pode rodar»** | ato que muda estado, se desfaz e não está na lista fixa de C. A frase vale **sozinha**: é o prompt inteiro, digitado por ele |
| **C** | **só o maestro**, pelo caminho próprio do ato | a lista fixa (§3) e todo ato que a régua não conhece |

**Por que A é tão estreita agora.** Medido em 20/11/2026: as sessões rodam com o privilégio pleno do
usuário do maestro, sem sandbox. Nesse ambiente, um ato automático que muda estado é feito com todo o
poder da máquina. O maestro selou: até existir um
**executor separado** (usuário ou contêiner só de execução, sem `sudo`, com token próprio limitado), a
classe A vale só para o que não muda estado (`D_RATCHET_AUTO_ONLY_NON_STATE_CHANGING_1120`).

**Por que B vale já.** O maestro selou que o «pode rodar» vale antes de o livro morar fora da máquina
(`D_RATCHET_CLASS_B_VALID_NOW_1120`). O livro serve para **descer** de classe, não para o maestro
aprovar. O selo ressalva um repo da família com regra local mais estrita: lá vale a regra dele. A
generalização («a regra mais estrita do repo vence») vem da síntese do Delphi, item do merge de guarda.

### 1.2 Força da prova: como a aprovação mostra quem a deu

| força | o que prova | estado |
|---|---|---|
| **1** | a frase foi **digitada** na sessão, como prompt inteiro | existe (só para merge, por enquanto) |
| **2** | aprovação **fora da banda**: um canal com identidade conferida (por exemplo, o evento de um chat conferido pelo portão e atestado com assinatura) | em desenho |
| **3** | prova física ou de duas pessoas (chave de acesso, segunda pessoa) | não desenhado |

**A regra entre os eixos:** força 2 por canal ou botão **só depois de medir** que a superfície não
forja o «pode rodar». Botão de aprovação é exatamente o mecanismo que decide uma chamada; um mod
(extensão do Claude Code) sem guarda gerenciada consegue aprovar o que a regra barrou (medido em
laboratório). Enquanto isso não for medido no login real, a força 2 não existe.

**E o clique na ponte de chat?** A ponte que pede clique para atos perigosos seguiu por decisão do
maestro (20/11/2026), com a identidade vinda do evento do chat conferido pelo portão. Esse clique é
uma **guarda da ponte**, não uma força 2 da catraca: até as medições de mods, ele não desce a classe de
nenhum ato.

---

## 2. Classificar pelo ato medido, nunca pelo texto

A classe sai de uma régua determinística, nunca do texto do pedido nem da opinião da sessão.

- **A chave é (verbo, alvo, reversível, origem).** Verbo é o comando real; alvo é o caminho, o repo ou o
  serviço; reversível diz se existe desfazer medido; origem é de onde veio o disparo.
- **Desconhecido cai em C.** Nunca em A. Errar para o lado estrito é o padrão.
- **A origem só sobe a classe.** Ato disparado por mensagem de outra sessão, sinal de caixa de entrada,
  fila A2A (*agent-to-agent*, sessão falando com sessão) ou tarefa agendada **nunca** é A. Mensagem é
  **dado**, nunca autorização. Caso vivido em 20/11/2026: um «merge o que estiver ok» chegou por relay e
  foi recusado, porque relay (repasse de uma sessão a outra) não é o maestro.
- **Precisão assimétrica.** Um C classificado como A é o único erro fatal. O teste da régua é um conjunto
  de ouro com os ~150 atos colhidos (sem conteúdo de cliente), rotulado pelo maestro por regra. Passa se
  **nenhum C cair em A** e a precisão de A for de pelo menos 0,95.

---

## 3. A lista fixa de C: nunca desce

Estes atos são sempre do maestro, qualquer que seja o histórico:

- tudo que toca **cliente** ou **dado pessoal**;
- **segredo** (chave, token, credencial);
- **contas, `sudo`, `sshd`, firewall**;
- **produção, deploy, CI/CD** (integração e entrega contínuas);
- **publicação externa** (repo público, porta);
- a branch principal de produção (**master**);
- **apagar sem cópia cifrada**;
- **instalar ou ativar mod**;
- **PR que toca a própria catraca**;
- **selo de contrato, tag e release**;
- **escrita em repo de outro dono**.

**Merge de guarda** (PR que toca hook, check ou lint) segue a regra **mais estrita do repo** e nunca é A.

---

## 4. Afrouxar só com histórico medido

Descer de classe é a única direção que precisa de prova. A ordem é fixa:

1. **Curar a fricção do «pode rodar».** Medido: de 15 tentativas de aprovação, **10 foram recusadas**
   (6 por moldura de outra sessão, 2 porque a frase não era o prompt inteiro, 2 por pedido vencido). Um
   PR precisou de 4 aprovações porque o commit mudou. Classe B com essa fricção vira C na prática.
2. **Modo observar por 30 dias.** A catraca classifica e registra, **não decide**. Mede quantos B o
   maestro dá por dia e quantas reversões houve, inclusive fora do git, pelo carimbo do **resultado** de
   cada ato.
3. **Só então fixar N e ligar descidas.** O ponto de partida é **20 atos sem reversão em 30 dias, por par
   verbo+alvo**. N é hipótese de partida; a medição fixa o valor.

**As regras de movimento:**

- só desce ato que **se desfaz**; ato irreversível nunca chega a A;
- nunca desce abaixo do piso da classe, e nunca desce item da lista fixa (§3);
- **incidente sobe a classe**: o selo diz «subindo com incidente» e não fixa o alcance.

**Ainda não selado** (posições do Delphi, a decidir no fim da observação):

- uma posição pede que incidente do mesmo par suba **na hora**, sem esperar N;
- duas posições divergem sobre incidente num ato C: uma **congela todas as descidas** até o maestro
  selar, a outra **sobe a catraca inteira um degrau**;
- o que conta como **reversão** também é proposta: revert ou rollback, recusa do maestro depois do fato,
  ou incidente ligado ao ato, dentro da janela.

---

## 5. O livro: o que torna a decisão explicável e auditável

Cada decisão da catraca deixa uma linha no livro. Sem livro, não há como descer de classe, nem como
explicar, nem como auditar.

**Forma do livro:**

- **só de acréscimo**: nada se reescreve; correção é uma linha nova;
- **encadeado por hash** (impressão digital do conteúdo): cada linha carrega o hash da anterior, e mexer no meio quebra a corrente;
- **ponta ancorada fora da máquina** a cada decisão: uma cópia do último hash vai para um lugar que a
  sessão não reescreve;
- **teto escrito no próprio livro**, nestas palavras: **«adulteração detectável, não impossível»**.

**O que cada linha registra** (é isto que responde «por que rodou?»):

| campo | pergunta que responde |
|---|---|
| ato (verbo, alvo, argumentos) | o que foi feito? |
| commit ou versão do alvo | sobre qual estado? |
| origem do disparo | quem pediu, por qual canal? |
| classe e regra que a deu | por que esta classe? |
| quem aprovou e com qual força | quem decidiu, com que prova? |
| motivo em uma frase | por que agora? |
| resultado e carimbo | deu certo? foi desfeito depois? |

**Como um auditor confere** (sem confiar na sessão):

1. a corrente de hash fecha do início à ponta;
2. a ponta bate com a cópia guardada fora da máquina;
3. cada ato B tem a frase digitada correspondente;
4. nenhum ato da lista fixa aparece como A ou B;
5. cada descida de classe aponta N atos sem reversão na janela.

**Para onde o livro vai.** O livro ainda não existe (§9). Quando nascer, nasce na mesma máquina e no
mesmo usuário das sessões, e por isso é conformidade. O alvo é o
livro gravado por um executor ou CI com identidade que as sessões não têm, depois de encolher o `sudo`.
O livro de um assistente de empresa mora na conta da empresa; ao Onion volta só contagem e classe.

---

## 6. Pacote de atos

O maestro pode aprovar vários atos de uma vez, com regras:

- até cerca de **5 atos**;
- cada item preso a (commit, verbo, alvo, argumentos) e de **uso único**;
- o pacote vale pela **classe mais alta** que ele contém;
- é mostrado pelo **efeito**, em linguagem simples;
- para no primeiro erro, com desfazer do pacote.

---

## 7. O que fica fora (por ora)

- **O drive automático** (`/meta:drive`) fica fora da catraca. O merge dele segue desligado por padrão e
  só liga com a flag explícita do maestro.
- **A personalidade da instância** só **projeta** o livro (contagem, reversões, idade). Nunca é fonte.
- **A confiança de cada assistente de empresa** é separada da do Onion. Uma não passa para a outra.

---

## 8. Antes de ligar: bancada própria

A catraca não liga sem uma bancada (conjunto de testes) com **um mutante por regra**: um caso que
reverte a regra e tem de reprovar. Os mutantes mínimos:

- descer sem N atos limpos;
- não subir depois de incidente;
- a sessão escrevendo o livro;
- origem por relay virando A.

E um **controle vivo**: o caso honesto tem de passar.

---

## 9. O que já roda e o que falta (2026-11-21)

**Já roda:**

- o «pode rodar» de força 1, **só para merge**, no script de merge verificado (`ops/pr-merge-verified.sh --one-touch`) (core-only);
- o portão de repo próprio: sessão sem o maestro só merja o repo da própria sessão (salvo o core, que merja repo da família com flag explícita), e repo de outro dono é sempre recusado;
- a tabela de atos do maestro (`ops/moat-targets.tsv`) (core-only), que vai receber a coluna da classe;
- o portão de efeito (`.claude/validation/guardrails/onion-effect-gate.sh`): ato derivado de conteúdo não confiável sempre passa por gate.

**Falta:** o livro único com reversão, a régua determinística com o conjunto de ouro, o modo observar,
a cura da fricção e o executor separado.

---

## 10. Teto declarado: o que esta doutrina NÃO garante

Leia isto antes de confiar na catraca.

1. **Não é fronteira de segurança.** Tudo roda no mesmo usuário Unix, com o privilégio pleno dele. Uma sessão
   que quiser burlar consegue reescrever o livro local, a aprovação e o transcript. A catraca é **camada
   de conformidade**: faz o caminho certo ser o fácil e deixa o desvio **visível**.
2. **O livro detecta, não impede.** A âncora fora da máquina mostra que houve adulteração. Ela não evita.
3. **O «pode rodar» prova que a frase foi digitada, não quem digitou.** Força 1 não tem identidade.
4. **Um mod pode forjar a frase.** Não está medido, no login real, se um comando de mod sem turno do modelo
   grava no transcript como prompt humano digitado. Se gravar, um mod forja o «pode rodar».
5. **A régua vê o ato declarado à ferramenta, não o efeito no mundo.** Um script que faz mais do que seu
   nome diz passa com a classe do nome.
6. **N é palpite de partida.** Os 20 atos em 30 dias saem do Delphi, não de medição. A medição fixa o valor.
7. **Reversão fora do git é medida pelo carimbo do resultado**, que é declaração do próprio ato.
8. **Repo de outro dono está fora**: é sempre C, e a catraca não o classifica.
9. **Hoje é doutrina.** A régua, o livro e o modo observar ainda não existem. Esta página não é um
   mecanismo, e nenhum check reprova um ato por classe.
