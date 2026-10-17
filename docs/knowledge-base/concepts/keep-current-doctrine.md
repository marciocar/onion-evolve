# Doutrina "Base atual, sempre" — manter atualizado é eterno

> **Versão**: 1.0.0 | **Última atualização**: 2026-10-16 | **Categoria**: Conceitos
> Quem constrói no Onion constrói sobre a **base atual**: a branch padrão buscada agora, as versões
> estáveis mais novas das ferramentas e dependências do caminho do trabalho. Defasagem achada no caminho
> é **subida no mesmo fluxo ou nomeada**. Ferramenta que falta é **pedida ao maestro e instalada**, nunca
> contornada. E a regra não mora na memória de ninguém: um **gatilho mecânico** a cobra sozinho.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-10-16 |
| **Última Atualização** | 2026-10-16 |
| **Categoria** | Conceitos |
| **Origem** | Ordem do maestro em 2026-10-16, em dois reforços seguidos (citados abaixo) |
| **Gatilho mecânico** | hook `UserPromptSubmit` `.claude/hooks/session-currency-check.sh`, que roda o medidor `.claude/validation/currency-census.sh` |
| **Grafo** | `docs/evolution/research/guard-keep-current-2026-10/keep-current-2026-10.kg.yaml` (decisão `D_MANTER_ATUALIZADO_E_ETERNO`) |
| **Padrões-irmãos** | [Verify-External-for-Current](verify-external-for-current.md) (o mesmo princípio para o que se AFIRMA) · [Dogfooding](onion-dogfooding-doctrine.md) (rodar de verdade, no mesmo loop) · [Behavior over declaration](../agentic-patterns/ai-strategies/behavior-over-declaration.md) |

---

## 🎯 A ordem, verbatim

O maestro, em 2026-10-16, ao achar uma sessão construindo sobre versões velhas:

1. *"se não tem algo instalado é só pedir autorização para mim e instalar, voce já está na VPS, temos que
   usar sempre as versões mais atuais e não sair criando coisas em cima de base velha"*
2. *"este aviso anterior de manter atualizado é eterno, não só em memoria e sessão"*

E a doutrina permanente dele que decide **a forma** desta: *"a IA é prosa, mas a maquinaria garante o
determinismo"*; uma regra *"não tem que ser absorvida, ficar em memória: ela deve ser um gatilho que faça
isso ser lembrado/cobrado"*. Por isso esta página é a fonte citável, e não a defesa: a defesa é o hook.

---

## 🚦 O que a doutrina exige

1. **Começar sobre a base atual.** Antes de construir, a branch de trabalho nasce da branch padrão do
   origin **buscada agora** (fetch antes da worktree), e a ferramenta que se vai usar é conferida contra o
   publicado (`npm view`, `pip index versions`, `git ls-remote --tags`, `claude --version`). Construir
   sobre base velha é construir o que alguém vai ter de refazer.
2. **Defasagem no caminho é subida ou nomeada.** Achou dependência ou ferramenta atrás do publicado no
   caminho do trabalho? Declare **de/para** e suba no mesmo fluxo. Se não der para subir agora (pino de
   contrato, deploy que é de outro, risco medido), **nomeie o porquê** ao maestro. Calar é o que esta
   doutrina proíbe.
3. **Faltou pacote: pedir e instalar, nunca contornar.** Ferramenta ausente não justifica "não medido",
   nem um caminho alternativo improvisado. Pare, peça ao maestro a autorização para instalar (nome,
   versão, fonte oficial, porquê) e, com o sim, instale pela fonte oficial e registre.
4. **"Não medido" é só para fonte inalcançável.** Quando o registro, o PyPI ou o remoto não respondem, a
   superfície fica **NÃO MEDIDA**, nunca "em dia". Zero por falta de medição se lê como "não há", e é
   pior que não medir.
5. **Atual quer dizer o canal que a casa segue.** Para o CLI do Claude Code, é o canal de auto-update do
   host (`latest` por padrão); para pacote com **pino de contrato** (as dependências do leitor do KG-SSOT),
   a subida é do produto que fixa o pino, e chega pelo re-vendor. Subir só localmente o que o CI instala
   pinado desalinha os dois.

---

## ⚙️ O gatilho que cobra (a parte que não depende de ninguém lembrar)

| Peça | O que faz | Quando dispara |
|---|---|---|
| `.claude/validation/currency-census.sh` | mede cada superfície contra o publicado e devolve `em-dia` · `defasada` (com a ação de subida) · `pinada` (atrás por pino de contrato: aviso INFORMATIVO, a subida é do produto) · `fora-do-pino` (instalado à frente do pino que o CI instala) · `nao-medida` (fonte inalcançável, perna morta ou estourada, leitura suspeita) · `ausente` (com o pedido de autorização) | sob demanda (`--table` para humano) e pelo hook |
| `.claude/hooks/session-currency-check.sh` | injeta o aviso na sessão quando algo não está em dia | todo prompt (`UserPromptSubmit`). Só as respostas REMOTAS ficam em cache (registros 1 h; origin e SDK 5 min; fonte que falhou, 10 min), o lado local é relido a cada prompt, e cada perna tem prazo de 9 s. Cada superfície avisa 1× por sessão e re-avisa quando o publicado anda ou quando ela volta a cair depois de ter ficado em dia |
| `.claude/hooks/session-version-drift.sh` (pré-existente) | o processo da sessão roda um CLI que o disco já trocou | todo prompt |

**As superfícies medidas hoje:** o CLI do Claude Code em disco × o canal no npm; o Agent SDK de quem
serve por SDK × o latest do npm (os alvos são os mesmos do censo do `/meta:cc-update`); o `vendor/kg-ssot`
× a maior tag do produto; PyYAML e jsonschema no python do lint × o PyPI (com o pino do contrato citado);
o HEAD do checkout × a branch padrão do origin (por `git ls-remote`, sem mudar refs); e o pin por SHA da
`anthropics/claude-code-action` nos workflows × a maior tag de release dela, com o CLI que cada commit
instala no texto da ação (desde 2026-10-17, SAC-169: o revisor de IA do CI rodava o CLI 2.1.220 com o host
em 2.1.302, e nenhum censo via; um CLI que a action instala no runner é tão "em produção" quanto o do disco).

**Por que aviso e não veto (`exit 2`).** Toda superfície depende de registro de terceiro e de rede: um veto
que dispara no minuto em que o npm publica é falso positivo por construção, e falso positivo treina a
sessão a ignorar o veto (cláusula 4 da [doutrina de guardas](../../../.claude/commands/common/prompts/guard-doctrine.md)).
Subir é ato do fluxo, com o maestro sabendo; o hook garante que ele **sabe**.

**Para quem não recebe o hook.** Subagente não dispara `UserPromptSubmit`. A regra chega a ele pelo
[preâmbulo versionado do agente de execução](../../../.claude/commands/common/prompts/execution-agent-preamble.md),
que manda rodar o censo antes de construir. E o fechamento de PR já rebaseia sobre a branch padrão do
origin antes de enviar.

---

## 🧱 O que esta doutrina NÃO promete (o teto)

- **"Latest" não é juízo de estabilidade.** O censo compara com o que o registro publica no canal; se uma
  versão nova quebra algo, o que decide é o dogfood, não o censo.
- **Não vê o que não lista.** Pacotes do sistema, node/npm, o lock de outro repo e as dependências
  transitivas ficam fora; ampliar as superfícies é editar o censo, com caso de bancada.
- **A base medida é a do checkout da sessão principal**, não a de uma worktree de agente (o subagente
  roda o censo no próprio diretório).
- **O canal do CLI é lido do npm**, não do manifesto do instalador nativo (alinhados em 2026-10-16): se o
  npm publicar antes, `claude update` ainda não sobe e o aviso persiste até o nativo chegar. Managed
  settings não são lidos para o canal.
- **Em PR empilhado** a ação "rebase sobre a branch padrão" é errada: a base certa é a branch-mãe.
- **Versão com sufixo** (`0.3.302-beta.1`) é comparada pelo número (`0.3.302`).
- **O hook viaja** (o registro dele entra no adotante pela fusão de hooks): lá ele lê o npm, o PyPI, o
  remoto do kg-ssot e o origin, no máximo pelas TTLs acima. A perna do SDK só existe onde há alvos
  declarados (no core).
- **A versão servida do SDK fica em cache 5 min** (é lida por sudo como a conta dona): depois de subir o
  SDK, o aviso pode persistir até 5 min. Entre a conferência do caminho real e a leitura há uma janela
  (TOCTOU) que só a conta dona explora, e o que sai é só uma string de versão.
- **Fonte travada pode deixar um processo vivo** por até o teto da fonte (4 s) depois que o censo sai; o
  prazo da perna é grampeado em 12 s para o hook (15 s) nunca ser morto.
- **A dedupe é por sessão**, lida do `session_id` do JSON do hook; sem ele, da variável de ambiente; o
  estado só vale num diretório da conta não gravável por outros (fora disso o aviso repete, nunca cala).
- **Não sobe nada sozinho.** Instalar, subir e re-implantar são atos com autorização; o gatilho cobra,
  não executa.

---

## 🔗 Ligações

- Decisão selada: `D_MANTER_ATUALIZADO_E_ETERNO` no grafo da forja (Metadata acima).
- Irmã para afirmações: [verify-external-for-current](verify-external-for-current.md).
- Modelos (a mesma ordem aplicada à escolha de modelo): o lineup `session_models` e o piso de sessão,
  vigiados pelo hook `PreModelSwitch` (`.claude/hooks/premodelswitch-guard.sh`).
- Atualização do Claude Code como gatilho de estratégia: `/meta:cc-update`.
