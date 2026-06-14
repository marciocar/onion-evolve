# Notas e Insights — Onion Federation Design v2

## Frota adversarial: padrão de análise para decisões de design

A review adversarial revelou que **3 alertas sistêmicos raiz explicavam 16 de 24 achados**
confirmados. Isso é o padrão clássico de causa raiz: vale sempre procurar o SA antes de
listar os achados individuais. SA-3 (spike não-verificado load-bearing) era o mais perigoso
porque silenciava todos os outros riscos — se o spike falhasse, toda a análise de risco
subsequente seria irrelevante.

## O ledger git é mais simples e mais seguro que o hub

A intuição inicial de hub parecia "mais intuitiva" (um centro coordena N membros). Mas o
hub concentrava risco: um spike não-verificado travava tudo. O ledger distribui: cada repo
faz o que já sabe fazer (ler/escrever arquivos na sua sessão), e o ledger é apenas uma pasta
adicional. A complexidade diminuiu, a confiabilidade aumentou.

## "Comunicação entre si" tem fronteiras claras

O usuário pediu "comunicação entre si" — que poderia ser interpretada como A2A em tempo real.
A clareza veio de mapear a fronteira explicitamente:
- ✅ Assíncrona via git (ledger): permitida, fiel à identidade
- ❌ Instâncias vivas em tempo real (A2A/MCP runtime): abandonada em 2026-05-18

Essa fronteira deve ser re-citada em qualquer discussão futura sobre Federation.

## A máquina de segurança mais forte é de 1ª mão

O hub prometia consolidar docs dos membros para validar mudanças de contrato (2ª mão).
O consumer fazendo isso localmente em casa (1ª mão) é mais forte: tem acesso ao código real,
aos testes reais, sem atraso de consolidação, sem spike cross-dir.

## Sessão orphan: diagnóstico de resíduos pré-refactor

A sessão `.claude/sessions/allowed-tools-and-kb-content/` era um resíduo do padrão pré-refactor
(sem STATE.md, sem plan.md, só context.md + architecture.md). O critério de diagnóstico:
(a) o trabalho já está em main? (b) há STATE.md com pelo menos uma fase `[ACTIVE]`?
Se ambos falharem na mesma direção → resíduo seguro para remover.

## Design v1 como "trilha de racional"

Manter o doc v1 como SUPERSEDED (em vez de deletar) foi a decisão certa. Ele documenta:
- Por que hub foi considerado
- Que riscos a review adversarial confirmou
- Por que o pivô foi necessário

Isso é conhecimento institucional que qualquer retomada futura precisará.
