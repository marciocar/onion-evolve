# Processo de Vendas

> Deriva do modelo comercial em camadas de [`../02-product/strategy.md`](../02-product/strategy.md) (`D1`) e da sequência de receitas (`D4`). Nesta fase, é **desenho**, não operação viva — receita/preço concretos são `[hipótese — D5]`.

---

## Metodologia

Não é B2C-SaaS de assinatura por assento. É **land-and-expand de alto ticket + camada de serviço**:

```
mini (aha no repo do prospect) → compromisso (dado OU financeiro) → serviço/certificação
```

O funil abre facilitado (mini prova valor rápido) e a progressão vira compromisso. A **moeda-dado** (federação de contexto) alimenta o que justifica a **moeda-financeira** (curadoria SOTA) — ver `strategy.md` §Modelo comercial.

## Qualificação (quem é bom prospect)

- **Sinal primário:** sente delegation gap / drift / retrabalho com IA no dev.
- **P4 — regulado/enterprise:** cunha de **maior valor** (governança/auditoria; disposto a pagar por reduzir risco). Ciclo longo.
- **P3 — empresa c/ sistemas internos:** **volume org** mais provável (consistência/escala).
- **P5 — dev solo:** ticket menor, entrada pelo mini.
- Ver personas em [`../01-customer/personas.md`](../01-customer/personas.md).

## Sequência de receitas `[inclinação — D4]`

**1º** formalizar treino/consultoria (o que você **já vende** — receita mais próxima, menor risco) → **2º** certificação "operador Onion" (selo + rede) → **3º** compliance-pack (regulados, ticket alto) → **4º** assinatura de curadoria SOTA (recorrente).

## Objeções → proof points

| Objeção | Resposta |
|---|---|
| "já tenho CLAUDE.md" | é 1 arquivo; o Onion é o ciclo (3 contextos + workflows + agentes) que conversam |
| "SDD é waterfall?" | faseado retomável, não big-design-upfront (contraponto Fowler) |
| "só Claude Code?" | por design — profundidade idiomática > alcance |
| "por que pagar?" | ROI = retrabalho evitado; contexto bem mantido → 40%↓erro, 55%↑veloc (Anthropic) |

## Enablement

- **Demo = o "aha" do mini instrumentado** no repo do próprio prospect (gera os 3 contextos + mostra o número). É a arma de venda; ver [`../02-product/metrics.md`](../02-product/metrics.md).
- **Case vivo:** o dogfood + adotante de campo que achou+corrigiu bug do core = prova de que o método funciona (moat de credibilidade).

## Guardrails da pesquisa (monetização)

- **Ticket premium > pipoca** — maestro solo não sustenta volume; poucos compradores de alto valor.
- **Vender selo/curadoria/serviço, não o texto** (copiável) — padrão SAFe/EOS.
- 🚩 **Decidir o modelo ANTES de abrir publicamente** — relicenciar depois gera fork/backlash (HashiCorp/Redis/MongoDB). O Onion nunca foi distribuído → janela aberta. Ver `../decisions.md` `D1`.

## Sucesso do cliente / retenção

- **Onboarding:** `/meta:adopt` → `/warm-up` → 1º ciclo faseado concluído.
- **Expansão:** 1 repo dogfood → múltiplos repos via federação.
- **Renovação:** curadoria SOTA contínua + flywheel de federação (valor destilado devolvido).

---

_§template: o adotante troca pela sua metodologia de vendas real; funil→qualificação→objeções→enablement→retenção é o padrão._
