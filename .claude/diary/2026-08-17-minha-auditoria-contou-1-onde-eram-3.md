---
date: 2026-08-17
instance: onion-evolve
type: error
classification: collective
tags: [auto-auditoria, lente-unica, residuo-r56, revisor-do-ci, ponto-cego, contagem, reincidencia, elenxo-etapa-1]
affects: [meta, engineering, validation]
breadcrumb_for: []
share_with: []
next_recommended: "Ao escrever resíduo R56, MEDIR cada número que ele afirma (não só o achado): resíduo que conta errado sobre si mesmo dá impressão de auditoria. E ao varrer contagem, conferir a SOMA, nunca a varredura."
review_after: 2026-11-17
conflict_class: static
significance: "Escrevi um resíduo de revisão auto-auditando meu PR com rigor — e o resíduo CONTAVA ERRADO sobre si mesmo: declarei 1 link morto novo onde eram 3. Quem me pegou foi o revisor do CI, não eu, e o defeito era da MESMA família que o PR estava curando. É evidência empírica, colhida contra o autor, de por que a etapa 1 do Elenxo exige lentes INDEPENDENTES: lente única não vê o próprio ponto cego — nem quando está explicitamente procurando por ele."
---

# Auditei a mim mesmo com rigor, e a minha auditoria estava errada

**O que aconteceu.** PR #630 graduou a doutrina do Elenxo para a KB vendorizada. Escrevi o resíduo
R56 com o que julguei ser rigor real: 3 ataques dirigidos ao meu próprio diff, 1 achado grave contra
a minha própria cura (o grafo não sabia que a doutrina graduou), limites declarados, e um achado
registrado **sem** cura com o número honesto — *"5 links mortos no plugin, o meu é o 5º de uma classe
pré-existente de 4"*.

O revisor do CI leu isso e me corrigiu: eram **3** links novos, não 1. As skills `onion-onboarding` e
`onion-wizard` **também** são embarcadas no plugin, e o link que pus nelas foi copiado sem a
profundidade extra de `plugins/onion-work-tools/`.

**O erro de método é específico e nomeável:** verifiquei o link **na KB** — onde eu tinha acabado de
mexer, onde eu estava olhando — e **supus** que as **skills** herdavam a mesma resolução. Não herdam:
vivem em profundidade diferente dentro do plugin. Eu não deixei de medir por pressa; **medi o lugar
onde estava olhando e generalizei para o lugar onde não estava**.

E o revisor achou um segundo: `docs/INDEX.md` dizia *"49 em `concepts/`"* quando já eram 50. Eu tinha
varrido as duas contagens-**total** da mesma hunk e passado reto pelo **sub-total** logo abaixo — e o
próprio arquivo avisa, na linha 598, que a cura anterior dessa mesma classe *"parou em 1/4"*. **Eu li
esse aviso e o citei no corpo do PR como lição aprendida.** Reincidi na linha seguinte do mesmo
arquivo. (O revisor pegou 1 dos 2 sítios; o outro era a árvore ASCII.)

## Por que isto vale ser guardado

**1. Resíduo que conta errado sobre si mesmo é pior que resíduo ausente.** A ausência se vê; a
contagem errada **dá impressão de auditoria** e desliga o próximo verificador. É a mesma forma da
guarda inalcançável (`unreachable-guard-worse-than-absent`) e do revisor verde que nunca revisou —
esta casa já pagou por ela três vezes, agora numa quarta superfície: o **artefato de auditoria**.

**2. Lente única não vê o próprio ponto cego — nem procurando.** Eu estava *explicitamente* caçando
defeitos meus, na área exata do defeito, e ainda assim contei 1 onde eram 3. Isso não é falha de
esforço: é a razão de a **etapa 1 do Elenxo** exigir lentes **independentes** e não "uma lente
atenta". Registro como evidência empírica da própria doutrina que o PR entregava, colhida contra o
autor dela.

**3. O mecanismo funcionou sem o maestro** — e isso qualifica, de novo, a meta-lição de 02-08 ("o
gatilho eficaz é social"). Aqui o gatilho foi **mecânico**: o `onion-review` do CI, rodando sozinho,
achou 2 defeitos reais que a minha passada perdeu. Onde há mecanismo, ele dispara. Onde não há, o
defeito passa: o `kb-vendored-link-check.sh` varre `docs/knowledge-base/**` e **não** varre
`plugins/**/kb/`, e por isso o **lint passou verde nas duas vezes em que eu estava errado**.

**4. A cura tem preço, e o preço também se mede.** Ao curar os 3 links, embarquei a doutrina no
plugin — e junto vieram as 7 irmãs da seção "Relacionados" dela, que não estão lá. Placar: **4 links
mortos antes, 11 depois**. Mantive a decisão (ganha-se a definição presente, perdem-se links de
rodapé), mas só depois de **medir e declarar** que o número piorou. Curar sem medir o custo produz
relatório de vitória.

## A cura que fica

Nenhuma é disciplina. As duas primeiras já estão no artefato:

- o resíduo do #630 foi **re-escrito com o número certo e re-carimbado** — a correção fica visível,
  não substituída em silêncio (é o que `Aufhebung` exige, e é a doutrina do próprio PR);
- a doutrina entrou em `DOCS=()` do manifesto do plugin, então os 3 links resolvem **pelo mecanismo
  que o assembler já tinha** — não por máquina nova.

O que **não** virou mecanismo, e por isso fica aqui como fio: `plugins/**/kb/` não tem guarda de link,
e sub-total de `docs/<seção>` não tem feeder de lint. Enquanto não tiver, **conferir a soma** é a
única cura — e "vou conferir" é exatamente o tipo de promessa que esta casa já mediu como nula.
