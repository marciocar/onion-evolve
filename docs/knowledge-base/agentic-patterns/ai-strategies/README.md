# 🧠 AI Strategies — Como Guiar o Transformer

## O que são estratégias de AI

**Estratégias de AI** são padrões de interação que emergem da prática de operar o transformer
de perto: como ele se comporta por padrão, onde tende a errar, e quais sinais/estruturas
fazem a diferença entre "acomodação" (infere o mais provável) e "absorção" (segue a intenção).

Não são prompt templates genéricos — são **padrões com evidência de campo**, nascidos de
observar o modelo operar em contextos reais e notar o que funciona.

---

## Padrões mapeados

| Padrão | Resumo | Arquivo |
|--------|--------|---------|
| **Object-Led Discovery** | Promover objeto existente a papel premium via ciclo dirigível | [object-led-discovery.md](object-led-discovery.md) |
| **Breadcrumb Patterns** | Sinais explícitos nos artefatos que forçam absorção vs acomodação | [breadcrumb-patterns.md](breadcrumb-patterns.md) |
| **Verify-the-Read-Path-First** | Onde o dado vive é hipótese até rastrear quem o lê no código (crédito: adotante de campo) | [verify-read-path-first.md](verify-read-path-first.md) |

---

## Princípio unificador

> **A IA se acomoda, não absorve — a menos que você force.**

O transformer infere pelo "mais provável no corpus de treinamento". Em sistemas idiossincráticos
(como o Onion, ou o o app de um adotante), o mais provável está **errado**. Estratégias são os mecanismos
que fecham a lacuna entre "mais provável" e "intencionado".

Cada entrada neste trilho documenta um mecanismo diferente de fazer isso.
