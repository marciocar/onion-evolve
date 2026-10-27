# Sem dependência de serviço externo — o núcleo roda local e aberto

> **Versão**: 1.0.0 | **Última atualização**: 2026-10-27 | **Categoria**: Conceitos
> O núcleo do Onion roda **local e aberto**. Serviço externo, sobretudo o pago, só entra como
> **ponte opcional**: declarada, com **alternativa local nomeada**, e nunca como pré-requisito de uma
> capacidade. O Gamma é um dos casos.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-10-27 |
| **Última Atualização** | 2026-10-27 |
| **Categoria** | Conceitos |
| **Origem** | Decisão do maestro em 2026-10-27, dada duas vezes (citadas abaixo) |
| **Grafo** | `docs/onion/graph/onion-identity-2026-07.kg.yaml` (decisão `D_SEM_DEPENDENCIA_DE_SERVICO_EXTERNO_1027`, ligada a `C_POSTURA_ACOPLAMENTO`) |
| **Padrões-irmãos** | Postura de acoplamento (CLAUDE.md, seção de identidade) · [SDAAL](specification-driven-ai-abstraction-layer.md) (a costura que deixa o provider externo ser troca, não dependência) · [Base atual, sempre](keep-current-doctrine.md) |

---

## 🎯 A decisão, verbatim

O maestro, em 2026-10-27, duas vezes no mesmo dia:

1. Na sessão da curadoria: *"não quero dependências externas como no caso do Gamma"*.
2. Direto ao core: *"reforço: evitar dependências de serviços externos, o Gamma é um dos casos"*.

Selada por `kg-decide-seal.sh` como resposta à pergunta *"O núcleo do Onion pode depender de serviço
externo para entregar uma capacidade?"*. Descartadas: "sim, quando o serviço for a melhor opção do
mercado" e "sim, desde que seja gratuito".

## 🧭 Por que completa a postura de acoplamento

A postura de acoplamento (CLAUDE.md) diz: acoplar ao Claude Code **só quando a capacidade ganha não
existe fora**, e manter a independência quando ela for mais vantajosa. Esta doutrina aplica o mesmo
teste a **serviço de terceiro**. O Claude Code é o substrato escolhido. Um SaaS de geração, uma API
paga ou um MCP de busca são outra coisa: cada um põe rede, conta, cobrança e o roadmap de outra empresa
no caminho de uma capacidade que o Onion promete entregar.

## 🚦 O critério verificável

> **Capacidade do núcleo = funciona sem rede para serviço de terceiro, OU tem alternativa local
> nomeada.**

Como medir, sem julgamento:

1. **Desligue a ponte.** Sem a chave do serviço (`*_API_KEY` vazia) e sem rede para o host dele, a
   capacidade ainda entrega? Se entrega, ela é do núcleo.
2. **Senão, procure o nome.** O artefato (comando, agente, KB) **nomeia** o caminho local, com o comando
   ou a ferramenta concreta? "Há alternativas" não conta; `/design:deck` conta.
3. **Senão, é ponte, e tem de se declarar ponte.** A descrição diz "ponte opcional para o serviço X
   (externo, pago)" e aponta para onde ir sem ele. Nunca "a" capacidade de X.

O que **não** muda: a ponte pode existir, ser boa e ser usada. O que é proibido é a capacidade
**depender** dela.

**Fora do teste: o substrato.** O Claude Code e o modelo da Anthropic que o roda são o substrato
escolhido pela postura de acoplamento, não serviço de terceiro. As ferramentas dele (WebSearch,
WebFetch) contam como do núcleo. O teste vale para o que vem **além** do substrato.

## 🧪 O caso Gamma (aplicado em 2026-10-27)

| Antes | Depois |
|-------|--------|
| `/product:presentation` = "criação de apresentações profissionais via Gamma.app" | declara-se ponte opcional (externo, pago); sem a chave, para e devolve o caminho local |
| `@presentation-orchestrator` entregava "apresentações Gamma.app" | narrativa e diagramas seguem; sem a chave, para antes da geração e devolve o caminho local |
| `@gamma-api-specialist` | o mesmo agente, declarado como especialista da ponte opcional |

O que **não** mudou: o comando e o orquestrador não ganharam um ramo que gere o deck local
sozinhos. Eles param e apontam. Fazer o ramo é trabalho à parte.

O caminho local nomeado:

- **`/design:deck`** gera um único HTML self-contained, que abre offline (fonte embutida, zero CDN).
  O formato dele é o deck de treino/onboarding, não o pitch; não é equivalente ao Gamma em tudo.
- **pptx e docx em Python**, com `python-pptx` e `python-docx`. A curadoria provou o caminho na
  prova do Cortex (PR 137 da curadoria, mergeado em 2026-10-27). Lá é receita provada; no core
  **não há gerador** ainda.

Nada foi apagado: o agente, o comando e a KB da API seguem, para quem quiser a ponte.

## 🔎 Candidatas a reclassificar (levantadas por grep em 2026-10-27, NÃO mexidas)

| Artefato | A dependência | Por que é candidata |
|----------|---------------|---------------------|
| `@research-agent` | Perplexity MCP (pago) descrito como pilar de pesquisa | o frontmatter nem tem a ferramenta: é prosa que promete o que o agente não tem; a pesquisa do núcleo é WebSearch/WebFetch e o corpus |
| `/product:light-arch` | a seção de pesquisa manda usar Context7 e Perplexity | o passo de pesquisa nomeia WebSearch, mas a seção final cita só os dois serviços |
| `/engineer:start` | a mesma frase: "use Context7 e Perplexity" | idem, sem alternativa nomeada na frase |
| `/design:identity` | o material reusa o `/product:presentation` (Gamma) e o MCP Canva | consumidor direto de duas pontes pagas; ganhou a nota do `/design:deck`, mas o Canva segue |
| `@runflow-specialist`, `/development:runflow-dev` | plataforma Runflow, por chave de API | especialista de plataforma: o natural é declarar-se ponte, não capacidade do núcleo |
| revisor de CI (`onion-review`) | chave paga da API da Anthropic, como secret do repo | é o substrato, mas cobrado à parte no CI; falta nomear o par local (`/git:code-review`) |

Já conformes, como referência de forma: **task manager** e **forge** (provider `none`, modo local),
**de-identificação** (`regex` no core, SLM local no alvo) e **design-source** (adapter `file` local;
`figma` e `penpot` são costura).

## 🔗 Ligações

- Decisão: `D_SEM_DEPENDENCIA_DE_SERVICO_EXTERNO_1027` → `C_POSTURA_ACOPLAMENTO`, em
  `docs/onion/graph/onion-identity-2026-07.kg.yaml`
- [Gamma.App API](../platforms/gamma-app-api.md) — a ponte, documentada
- [Orquestração de apresentações](../patterns/presentation-orchestration.md)
