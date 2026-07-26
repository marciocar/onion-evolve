---
name: onion-compliance-context
description: >
  Contrato de SSOT mínimo e resolver de contexto da vertical de COMPLIANCE do Onion.
  Use ao rodar comandos de compliance (build-compliance-docs) ou os especialistas
  ISO 27001/22301, SOC2, PMBOK, para localizar o contexto de CONTROLES do projeto —
  mesmo quando o repo NÃO segue o layout Onion padrão (sem docs/compliance-context/).
  Resolve onde ler/gravar o contexto vivo de compliance, faz bootstrap de um stub
  mínimo quando ausente, e aponta os templates de framework embarcados. Ative mesmo
  sem o usuário mencionar "contexto" ou "SSOT".
---

# Contexto de Compliance — contrato SSOT mínimo + resolver

Garante que a vertical de compliance **sabe onde está o seu SSOT de controles** em qualquer projeto —
adotado ou não. Separa dois tipos de conhecimento:

- **Framework (tipo A)** — os **templates** ISO 27001/22301, SOC2, PMBOK. **Viajam embarcados no
  plugin** (o assembler os empacota em `templates/`). São a estrutura normativa estável.
- **Contexto vivo (tipo B)** — os controles/políticas/evidências DO CONSUMIDOR. É dado dele
  (regulado, sensível); **não** viaja no plugin. Esta skill o **resolve** (ou faz bootstrap).

## 1. Framework (tipo A) — onde consultar

Os templates dos frameworks estão **embarcados**:
- **Como plugin**: em `${CLAUDE_PLUGIN_ROOT}/templates/` (ISO 27001, ISO 22301, SOC2, PMBOK).
- **No Onion completo**: nos templates de `common/templates/` referenciados pelos especialistas.

Ao gerar/auditar documentação normativa, **use o template embarcado** — não assuma paths do core.

## 2. Contexto de controles do consumidor (tipo B) — resolver

Para ler/gravar o contexto de compliance vivo (escopo, frameworks aplicáveis, controles, evidências,
RTO/RPO), resolva **nesta ordem** e use o primeiro que existir:

1. **Mapa explícito**: chave `context.compliance` em `.onion-version` (JSON) ou `.claude/onion-context.yaml`,
   se o consumidor declarou um caminho próprio. **Declaração explícita vence convenção** — o específico
   ganha do default (senão o mapa vira código morto: a adoção CRIA `docs/compliance-context/`; sinal de campo/D1).
2. **Layout Onion padrão**: `docs/compliance-context/` (índice em `docs/compliance-context/index.md`;
   overview em `COMPLIANCE_OVERVIEW.md`).
3. **Heurística de layout comum**: `contexto-projeto.md` · `docs/INDEX.md` · `SECURITY.md` ·
   `docs/security/` · `COMPLIANCE.md`.
4. **Bootstrap** (só com confirmação): criar o stub mínimo (seção 3) e passar a usá-lo.
5. **Degradação honesta**: nada existe e o usuário recusa o bootstrap → **prosseguir declarando**
   "não encontrei SSOT de compliance — operando sem ele" e **nunca inventar** controles/evidências
   (num contexto regulado, inventar é pior que ausência).

## 3. SSOT mínimo (a "estrutura mínima" garantida)

O contexto de compliance mínimo é **um arquivo**. No bootstrap, criar em
`docs/compliance-context/index.md` (ou no caminho resolvido):

```markdown
# Contexto de Compliance — <projeto>

## Escopo & Frameworks aplicáveis
<quais normas: ISO 27001/22301, SOC2, PMBOK — e por quê>

## Controles
<lista: controle · status (implementado/parcial/gap) · dono>

## Evidências
<onde vivem as evidências; última coleta>

## Continuidade (se aplicável)
<RTO/RPO, plano de recuperação>
```

Manter vivo (atualizar a cada auditoria/mudança) é o contrato. É o piso: num projeto regulado,
`docs/compliance-context/` completo (com business-continuity, ISO, SOC) o supera.

## 4. Regra de ouro

- **Tipo A** (templates) → sempre do embarcado; independe do consumidor.
- **Tipo B** (controles) → resolver → bootstrap → degradar **honesto**. Nunca assumir path fixo.
- **Contexto regulado:** ao não achar, **dizer** — inventar controle/evidência é falha grave.
  declarado ≠ verificado. Ver `[[onion-dogfooding-doctrine]]`.
