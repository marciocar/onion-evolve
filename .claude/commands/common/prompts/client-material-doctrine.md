# 🤝 Doutrina de material para CLIENTE — o que muda quando quem lê paga a conta

Fragmento canônico. Comandos e skills **referenciam** este arquivo; nenhum o copia.

> **Qual cliente.** O de **quem usa este framework** — o leitor final de um projeto seu, ou do seu
> próprio cliente. Não é sobre material do framework para quem o adota. A distinção entrou aqui
> porque o comando irmão nasceu chamado `build-client-manual` e podia ser lido como material do
> framework para quem o adota: nome ambíguo produz artefato aplicado ao leitor errado, e foi o
> maestro quem pegou, antes do commit. Ele existe porque
a casa tinha doutrina para material de **engenharia** (specs, KBs, resíduos, ADRs) e **nada** para
material que um cliente abre — medido em 2026-09-30: zero artefato no repo tratava tom, ordem ou
critério de exemplo em documento client-facing.

**Origem, declarada**: nasceu do manual do primeiro projeto servido a um cliente por agente + MCP,
refinado em várias passadas de uso real com o maestro em 2026-09-29. Não é teoria — é o que sobrou
depois de o material ser corrigido três vezes contra leitor real. E **é um padrão que vai melhorar**:
ter forma imperfeita é melhor que decidir tom por sorte a cada documento (decisão do maestro,
2026-09-30, contra a objeção de que N=1 não generaliza — a objeção erra porque o material já separa
o que é forma do que é domínio).

## As cinco cláusulas

### 1. Ordem: o acesso vem antes de tudo, e o caminho que gera valor vem em segundo

A ordem do documento importa **mais que o conteúdo dele**, e a prova é que ela foi a coisa mais
corrigida: a 1ª versão abria por referência (o que o sistema é, o que ele faz) e o maestro a inverteu
três vezes até chegar em **01 acesso passo a passo, em destaque, com as telas ilustradas → 02 o
caminho principal, o fluxo que gera o valor, em trilhas ("tem → conferir" / "não tem → gerar") → 03
atalhos → 04 a maquinaria (chat, agente, servidor, ferramentas) → o resto como referência**.

O porquê é sobre o leitor, não sobre o assunto: quem abre o manual está **travado na porta** ou
querendo o resultado. Referência primeiro serve a quem escreveu.

### 2. Tom de cliente: o documento não expõe problema de ninguém

> "Não coloque problemas descaradamente, eles são clientes." — maestro, 2026-09-29

Fora do material client-facing: achados sobre falhas **do próprio cliente**, percentuais de acerto,
bugs corrigidos, jargão interno (`git`, PR, pipeline, nomes de armazém/ferramenta). Dentro, as mesmas
verdades com o enquadramento certo: **limite** vira *"como tirar o melhor"*, **falha** vira *"quando
algo não funciona"* nas dúvidas frequentes.

Isto **não é maquiagem, e a diferença é mecânica**: os achados continuam existindo, num documento
**interno** que sustenta decisão. O que a cláusula proíbe é o mesmo artefato servir a dois leitores
com interesses opostos — quem decide precisa do defeito nomeado; quem usa precisa do caminho.

### 3. O que o usuário vê se escreve a partir da TELA, nunca de memória

Passo de acesso, texto de botão, política de senha e de MFA se escrevem lendo **a fonte viva** — a
configuração do provedor, a API de frases da tela, o painel real —, nos textos exatos em pt-BR.
Medido: a tela dizia *"Esqueceu **sua** senha?"* (não "a senha"), o MFA estava em `NoPrompt` (opcional,
não obrigatório) e existia um login por código que ninguém tinha documentado. Três divergências num
único passo, todas invisíveis a quem escreve de memória — e cada uma trava o cliente na porta.

### 4. Pergunta de exemplo é promessa: só entra depois de testada com dado real

Cada pergunta de exemplo é um **"momento wow"** e por isso um risco: exemplo que falha no primeiro
uso custa mais que exemplo ausente. A regra é dura — a pergunta entra no material **depois** de rodar
com os dados reais daquele cliente, e acompanhada de **"o que você recebe"**. Medido no dogfood que
gerou esta doutrina: numa análise real, dez itens marcados como pendência já tinham resposta
publicada pelo órgão, e o agente as achou com a referência exata — foi isso que virou exemplo, porque
foi isso que aconteceu.

### 5. O agente fala a língua do cliente, e isso é trabalho de configuração

Rótulo interno (`MACHINE_DIVERGENCE`, `ADAPT_NOT_CHECKED`) e nome de ferramenta **vazam** para a prosa
do agente se ninguém os mapear: medido no primeiro teste pelo chat. A cura não é pedir ao agente que
"escreva bem" — é dar-lhe a **tabela código → rótulo em português** e cobrar o rótulo. Instrução em
prosa não é fronteira; tabela é.

## O que esta doutrina NÃO promete

Ela cobre **tom, ordem e critério de exemplo**. Não diz se o material está correto, nem se o produto
entrega o que a página promete. E vale para material **client-facing**: documento interno de decisão
segue a doutrina oposta — nomeia o defeito, com número.

## 🔗 Referências

- Esqueleto de manual de projeto servido por agente: `.claude/commands/common/templates/agent-project-manual-template.html`
- Fatos técnicos de plataforma (decaem por versão, carimbados): `docs/knowledge-base/tools/librechat-agent-mcp.md`
- Sinal de campo que originou: `docs/evolution/inbox/_processed/2026-09-29-librechat-project-manual-template.md`
