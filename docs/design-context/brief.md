# Brief de Identidade Visual — Sistema Onion (core)

> **Papel:** intenção declarada que ancora a SSOT de tokens. Não é guia de estilo livre —
> é restrição verificável. A IA materializa a partir dos tokens; não inventa.

## Personalidade da marca

**Confiável · Estruturado · Modular · Transparente**

O Onion é um framework template que opera o ciclo completo de desenvolvimento com Claude Code.
Sua identidade visual deve comunicar: *ferramenta séria, feita por e para engenheiros* —
sem ornamento desnecessário, com clareza e consistência.

## Público

Engenheiros e consultores que implantam e evoluem o Onion em projetos reais (novos, legados, regulados).
Expectativa visual: profissional, direta, sem excessos decorativos.

## Cores de marca (derivadas dos badges do README — fonte canônica)

| Papel | Cor | Origem |
|---|---|---|
| Primária (CTA, ação) | `#D97757` laranja-quente | Badge "Claude Code" do README |
| Acento/família | `#8A2BE2` roxo médio | Badge "família Onion" do README |

As duas cores coexistem: o laranja ancora a plataforma (Claude Code); o roxo ancora a família/ecosistema.
**Hierarquia:** laranja = ação primária; roxo = acento, nunca concorre com o laranja em CTA.

## Tom e restrições

- **Tom:** direto, técnico, sem metáforas ornamentais
- **Acessibilidade:** WCAG AA mínimo em todos os pares texto/fundo (gate obrigatório)
- **Evitar:** gradientes complexos, paletas de mais de 4 primitivos de marca, cores "suaves/pastel" que
  percam leiturabilidade técnica
- **Referências buscadas:** ferramentas CLI/DevTools (clareza), documentação técnica (legibilidade)

## Restrições verificáveis (gate `lint-design-tokens.sh`)

1. Toda cor em uso deve existir como primitivo em `foundations/` ou alias em `semantic/`
2. Todo alias `{...}` deve resolver sem ciclo/órfão
3. Contraste WCAG dos pares declarados ≥ `min` exigido por par (`governance/contrast-pairs.json`).
   WCAG 2.1: 4.5 = texto normal · 3.0 = texto grande/bold ou UI. **Estado atual:** todos os 6 pares
   declarados exigem **4.5** (AA-normal pleno — inclusive o CTA, ver decisão #171).

## Fonte upstream

`docs/business-context/` está vazio (framework template — não tem produto/cliente específico).
Brief derivado da identidade canônica dos badges do README + princípios do framework (spec-as-code,
dogfood, legibilidade técnica).
