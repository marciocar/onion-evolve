---
title: 'Resíduo — a proposta foi selada e caiu no mesmo dia, contra o próprio corpus'
date: 2026-09-19
branch: docs/frontier-recognition-radius-proposal
reviewed_diff_sha256: 78e464f1f035d6600db71d0edd9824b301e5f03de0d553792bbc6a39c2e4a127
findings_total: 10
findings_real: 8
findings_fixed: 8
tokens: 135342
duration_min: 5
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  O refutador derrubou a proposta contra DOIS nós `confirmed` do arquivo que eu estava editando — um
  deles tier 9 e textual. Quatro citações decisivas foram re-conferidas à mão por grep antes de
  aceitar o veredito. A decisão foi SUPERADA (Aufhebung), não revertida: o selo do maestro fica no
  grafo com sua data, porque o defeito foi meu, não da decisão que ele tomou com o que lhe apresentei.
---

# O corpus já tinha a resposta, e eu não a li

A proposta de saída para `Q_FRONTEIRA` foi escrita, levada ao maestro, **selada**, e derrubada pela
passada adversarial **no mesmo dia**. Não por um detalhe: por contradizer diretamente nós
`confirmed` do próprio arquivo que eu estava editando.

## Os dois achados fatais

**1. A camada 3 é textualmente proibida.** `E_R2_EDPB_EXCECAO_SEM_CONSEQUENCIA_ADVERSA` — `confirmed`,
tier 9, **mesmo arquivo**:

> *"C NÃO deve desenhar nada que dependa de opt-in do empregado COMO SALVAGUARDA. LIMITA C."*

Minha camada 3 era "raio expansível só pelo indivíduo" — uma salvaguarda por opt-in dentro de relação
assimétrica. O Elenxo da rodada 1 já havia absorvido que **o pedido do superior já é coerção
contextual**. A pergunta *"a organização recupera o poder por via indireta?"* **já estava respondida
sim** no corpus.

**2. Reintroduzi um desenho já REFUTADO.** `E_AGREGADO_COM_OPTIN_VAZA_POR_DIFERENCA`: *"agregado com
consentimento parcial vaza o indivíduo POR DIFERENÇA em times de 3 a 5"*. Reconhecimento com raio
parcial + `karma_total` íntegro **é** isso. E o `Q_FRONTEIRA` **cita esse nó**; minha proposta, não.

## Os outros que sobreviveram

- **A tese central era parcial, e o contraexemplo estava dentro do nó que ela citava.** *"A cinco, com
  participação completa, o contador satura os elegíveis e o Karma individual de TODOS se reconstrói"*
  — ali o exposto não é o ajudante, são todos, e o predicado revelado é telemetria de produtividade.
  E no ataque 2 o exposto nominal é **o pedinte**, a quem a proposta não dava controle nenhum.
- **Rejeitei a saída do adotante e entreguei o ramo dela, com a mesma string.** Ele propôs `"alguém se
  ofereceu"`; minha camada 1 era `alguém já se ofereceu`. Crédito mal atribuído.
- **Usei a F2 indevidamente.** Ela barra **invocar** "privacidade diferencial" sem ε; faixa
  determinística não é ruído probabilístico — e a própria proposta admite ao escrever *"não é ruído"*.
- **A camada 4 não fecha o que eu afirmei que fechava.** Duas leituras são uso **normal**; budget sem
  ε limita **taxa**, não informação liberada — o mesmo vício que a F2 barra, aplicado por mim.

## O que o refutador atacou e NÃO derrubou

- **"O contador nunca foi o reconhecimento; ele acontece na aceitação"** — correto e sustentado pela
  descrição do próprio adotante. **Sobrevive**, e é o que torna a decisão nova menos custosa.
- **A objeção que eu havia anexado** estava certa no que examinava (n=3, camada 1 isolada); o defeito
  dela era de **escopo** (não olhou n=4/n=5) e de **conclusão**, não de raciocínio.
- **A disciplina de estado do nó**: nasceu `open`, declarou-se proposta, declarou "nenhuma medição
  nova o apoia", preservou a objeção. **Nenhuma verificação fabricada.**

## A cura: Aufhebung, não reversão

`D_FRONTEIRA_RECONHECIMENTO_POR_RAIO_PROPOSTA` → **`superseded`**, com `REFUTES` da evidência e
`SUPERSEDES` da decisão nova. **O selo do maestro fica no grafo, com sua data** — ele decidiu de
boa-fé sobre o que eu lhe apresentei, e apagar isso esconderia de quem foi o defeito.

A decisão que substitui vem do **mesmo corpus que derrubou a anterior**: `EV_DISCLOSURE_GATED` (*"na
dúvida, NÃO sai"*) e `IN_NONE_FAILSAFE` (*"recusa redigir-e-passar; não degrada"*). **Não emitir até
fechar** — o reconhecimento não sai do par enquanto a reidentificação não estiver resolvida.

## ⚠️ O achado que vale mais que o desenho

**O hook que existe para impedir exatamente este erro não disparou.** `kg-read-leg.sh` é
`PreToolUse` com matcher **`Read`**, e lê `tool_input.file_path`. Eu trabalhei o grafo inteiramente
por **bash** — `sed`, `grep`, heredoc de python. Nunca acionei o matcher; nunca houve `file_path`.

> **O hook fica mudo justamente para quem está ESCREVENDO no grafo — que é quem mais precisa de ter
> lido.**

E a ironia fecha o caso: ele nasceu em 2026-09-16 de um sinal de campo em que uma sessão publicou
quatro teses erradas num corpus que tinha a resposta. Curou a porta do `Read` e deixou aberta a porta
por onde o mesmo erro voltou.

Registrado como `E_PERNA_DE_LEITURA_E_CEGA_A_BASH` + `Q_COMO_A_PERNA_DE_LEITURA_ALCANCA_QUEM_ESCREVE`,
com três desenhos candidatos e a medição que decide entre eles ainda por fazer. **Não curado aqui**, e
a razão está escrita: mexer num hook que roda em toda sessão, às pressas, logo depois de um incidente,
é como o próprio incidente.

## A lição

Três passadas nesta onda já haviam mostrado que **escrever a guarda é quando se está mais perto de
reincidir na classe que ela cura**. Esta acrescenta a pior:

> **Propor sem ler o corpus que já responde é pior do que não propor** — porque a proposta chega com
> autoridade de síntese e o interlocutor não tem como saber que ela ignora a própria casa. O maestro
> selou. O custo de eu não ter lido foi pago por ele.
