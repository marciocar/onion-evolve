---
date: 2026-08-17
instance: onion-evolve
type: error
classification: collective
tags: [pressuposto, guarda-cega, adopt, baseline, catraca, projecao, nda, medicao-truncada, vocabulario]
affects: [meta, adopt, validation, federation]
breadcrumb_for: []
share_with: []
next_recommended: ""
review_after: 2026-11-17
conflict_class: static
significance: "Uma adoção real de campo achou DOIS defeitos com a mesma forma: em ambos o comentário do mecanismo descrevia o modo-de-falha com precisão, e a máquina não alcançava o que a prosa dizia. O passo do adopt que regenerava 1 de 5 baselines trazia escrito ao lado 'o gate nasceria reprovando o adotante no dia 1 e seria desligado'; a guarda de projeção auditava a anotação entre parênteses e tratava como segura, por construção, exatamente a metade do campo que o gerador publica. Prosa certa não é guarda."
---

# Dois defeitos, uma forma: o mecanismo cobria o caso e confiava no pressuposto

**O que aconteceu.** O maestro pediu um projeto novo com adoção do Onion (uma PoC com cliente
real). A adoção correu limpa — 615 arquivos, gate **provado por execução** — e o lint do alvo
nasceu com **47 violações HARD**. Todas `[kg-verificacao/REMOVIDO]`, cobrando nós de grafos que
só existem no core: `docs/discussions/onion-pessoal-marcio/…`, `bridge-produto-2026-08`.

**Defeito 1 — a adoção regenerava 1 de 5 baselines.** O manifesto copia `.claude/validation/`
inteiro, então os cinco baselines de catraca viajam com o passivo do core. O passo (9) do
`/meta:adopt` regenerava um — e trazia escrito ao lado, com precisão cirúrgica, o que a omissão
causaria: *"o gate nasceria reprovando o repo do adotante no dia 1 e seria desligado, que é
exatamente o modo-de-falha que a catraca existe para evitar"*. O autor daquele comentário
entendeu o problema por completo e aplicou a cura a um arquivo.

Agravante que só apareceu lendo o código da guarda: a catraca resolve a referência **caminhando
até o primeiro commit** que tenha o baseline. Logo o passivo entra na história antes de tudo, e
regenerar depois **não basta** — no alvo a história teve de ser reescrita para o commit raiz já
trazer os baselines dele. Simetria que fecha o diagnóstico: os **mesmos 47** são, no core,
`PASSIVO` tolerado. O que aqui é dívida medida, lá é acusação de dívida alheia.

**Defeito 2 — a guarda de projeção confiava na metade "segura".** Ao registrar o adotante no
`members.yaml`, escrevi o nome comercial do cliente (sob NDA) no campo `name:` — e ele
**apareceu no console publicado**, com o lint verde. O console publica só o trecho antes de
`" ("`; o parêntese é anotação interna. Toda a força da `projection-safety` mira essa
**anotação** — o trecho anterior era seguro **por construção**. Duas cegueiras somadas: o termo
não era derivado (o próprio membro o introduzia), e `federation-map.md` — projeção gerada pelo
**mesmo** `graph.sh` do console — nunca esteve na lista auditada, embora o console esteja desde o
incidente de 2026-07-10 que criou a guarda.

**A forma comum, que é o registro que importa.** Nos dois, *o mecanismo cobria o caso e confiava
no pressuposto*. Não foi lógica errada nem descuido de implementação: foi um pressuposto não
testado — "os outros quatro baselines devem estar bem", "a metade que o gerador publica é segura
porque é curta". Guarda que não testa o próprio pressuposto tem a forma de cobertura sem a
substância, que é a categoria mais caras desta casa: ela produz **verde**.

**As curas, e a polaridade que as faz funcionar.**

- `regen-baselines.sh` age **por descoberta** (varre `*-baseline.txt`, resolve o emissor de cada
  um), não por lista de cinco nomes — porque guarda de lista falha pelo **vocabulário**, e essa é
  a 4ª ocorrência da classe nesta casa. Baseline novo entra coberto por construção.
- O P6 da projeção é **allowlist de ids isentos**, não lista de nomes proibidos. Allowlist falha
  **fechada**: membro novo tem de cumprir. Lista de proibidos falha **aberta**: o nome novo nunca
  está nela. O modo-de-falha vira excesso de bloqueio, que é visível, em vez de vazamento, que não é.
- A isenção mora **no dado** (`projection_name_exempt` no `members.yaml`), não no script: a
  primeira versão a punha como variável no `projection-safety.sh` e a **REGRA 36 (vendor-scrub)**
  reprovou com razão — script vendorizado viaja para todo adotante, e id de adotante ali é
  vazamento cross-tenant por adoção.

**Os meus erros nesta rodada, sem apagar nenhum.** (1) Duas hipóteses erradas sobre a origem das
47 chaves antes de eu **ler o código da guarda**; a segunda me fez tomar "5 linhas" (cabeçalho
emitido) por "5 chaves". (2) `head -20` truncou a bancada por SIGPIPE e eu li o `exit 0` do
`head` como aprovação da suíte — **terceira vez** que trunco uma medição e reporto o número
errado; a bancada teve de rodar inteira, em arquivo, sem filtro. (3) A primeira versão da guarda
do core lia o **arquivo** `.claude/.onion-version` e ficava muda no core, que não o tem: ela
passou por **idempotência**, não por verificação — certo por sorte. (4) A primeira versão do P6
acusou falso-positivo num membro real por não descartar comentário de fim de linha, isto é: eu
discordava do **gerador** sobre o que é projetado, e guarda que discorda do gerador mede outra
coisa que não a superfície.

**Re-teste em 2026-11-17:** contar quantas guardas novas, entre hoje e lá, chegaram com **teste do
próprio pressuposto** (não só do caso) — no idioma que a `projection-safety` já usa: enumerar os
P0…Pn e provar cada um. Se a razão não melhorar, a conclusão não é "prestar mais atenção": é que
a enumeração de pressupostos precisa virar exigência da bancada para guarda nova, e não convenção
que algumas guardas seguem.
