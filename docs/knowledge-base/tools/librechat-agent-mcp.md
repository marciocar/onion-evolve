# LibreChat — agente + servidor MCP + atalhos — Knowledge Base

versao: 1.0.0
data: 2026-09-30
categoria: tools
verified_at: 2026-09-30
verified_against: "v0.8.8-rc4 medido no container em execução (ghcr.io/danny-avila/librechat-api:v0.8.8-rc4), não na versão citada pelo sinal de campo"

Fatos **medidos em produção** ao servir um projeto a cliente por um agente do LibreChat ligado a um
servidor MCP próprio. Todos decaem por versão — é por isso que o `verified_at` e a versão exata estão
no cabeçalho, e é a REGRA 42 (Gate de FRESCOR DOUTRINÁRIO, com catraca) que cobra o carimbo.

Doutrina de tom e ordem do material que o cliente lê: `.claude/commands/common/prompts/client-material-doctrine.md`.

---

## 1. O `/` busca pelo NOME do prompt, não pelo `command`

**Medido em v0.8.8-rc4.** O seletor de atalhos do LibreChat (abre digitando `/`) filtra pelo **nome**
do prompt. O campo `command`, que parece ser o gatilho, **não** é o que a busca casa.

Consequência prática, e ela morde o material do cliente: ensinar `/situa` (uma palavra do nome)
funciona por acidente; ensinar o comando completo **não** funciona se o nome não começar por ele.

**A cura é no seed, não no manual**: componha o nome do prompt **começando pelo comando**, e o comando
completo passa a ser o caminho natural.

```
nome do prompt:  "<prefixo>-situacao · Situação do caso"
                  ╰─ o comando abre o nome ⇒ digitar /<prefixo>-situacao traz o atalho em 1º
```

Medido no chat: `/<prefixo>-situacao` devolve o atalho em primeiro lugar, e `/<prefixo>` lista todos
os do projeto. Um atalho de **destaque** que faz o caminho principal num pedido só vale mais que dez
atalhos parciais.

## 2. Servidor MCP com cabeçalho por usuário conecta SOB DEMANDA

**Medido em v0.8.8-rc4.** Quando o servidor MCP exige cabeçalho por usuário, o painel de servidores
mostra **"desconectado"** depois de reiniciar o LibreChat ou o próprio servidor — e continua assim até
a **primeira pergunta** do usuário, que é quando a conexão é estabelecida.

É comportamento **normal**, não falha. Mas parece falha para quem administra: o estado do painel é
indistinguível de servidor caído. Vale entrar nas dúvidas frequentes do material do cliente, e vale
saber antes de investigar um incidente que não existe.

## 3. Sem Redis, o agendador não sobe até declarar réplica única

**Medido em v0.8.8.** Numa implantação **sem Redis**, o agendador do LibreChat não inicia — o log diz
`scheduler NOT started` — enquanto o deploy não declarar explicitamente que roda em processo único:

```yaml
environment:
  SCHEDULES_SINGLE_PROCESS: "true"   # sem isto, e sem Redis, o agendador não sobe
```

A razão é de desenho: sem um coordenador externo o LibreChat não pode garantir que só uma réplica
executa o agendamento, então ele **falha fechado** em vez de rodar duplicado. Quem declara réplica
única assume essa garantia.

## 4. O agente vaza rótulo interno se ninguém o mapear

**Medido no 1º teste pelo chat.** Códigos internos e nomes de ferramenta aparecem na prosa do agente
por default. Pedir "escreva na língua do cliente" em prosa **não** resolve; dar ao agente a **tabela
código → rótulo em português** resolve. É a cláusula 5 da doutrina de material para cliente: instrução
em prosa não é fronteira, tabela é.

## 5. A página do manual, conferida renderizada

O manual do cliente é **um HTML único** (tokens de cor claro/escuro, índice fixo com a seção atual,
busca que filtra seções/atalhos/ferramentas/glossário, "Copiar" com fallback) e foi conferido
**renderizado** a 1440 e 390 px — com Chromium headless no servidor, porque o Claude in Chrome não
alcança o frame de um Artifact publicado. Fronteira de ferramenta, declarada: quem precisa conferir
render de Artifact usa navegador headless próprio.

## 🔗 Referências

- Esqueleto: `.claude/commands/common/templates/agent-project-manual-template.html`
- Tom e ordem: `.claude/commands/common/prompts/client-material-doctrine.md`
- Linha de pesquisa do core sobre LibreChat como runtime de KG: `docs/evolution/research/librechat-kg-runtime-2026-08/`
- Sinal de campo de origem: `docs/evolution/inbox/_processed/2026-09-29-librechat-project-manual-template.md`
