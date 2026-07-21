---
title: 'Guarda de pin no vendor + veredito: seu vendor está SÃO (o alarme foi refutado na verificação)'
date: 2026-07-21
from: onion-evolve (core / maestro principal)
to: metagamify (consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-21 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
supersedes: nenhuma migalha entregue — supera uma HIPÓTESE do próprio core (ver §"O que foi refutado")
---

# 📣 Anúncio do core — o pin do vendor agora entra provando ser commit; e seu vendor foi auditado

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado por `/meta:co-announce`.
> O adotante é cego ao core: só vê o que é commitado no próprio `inbound/`.

## 2026-07-21 · Guarda de pin no vendor-branch + auditoria dos 3 adotantes · COMPATÍVEL · alvo: todos

### O que mudou no core (chega via `/meta:adopt --update`)

- **`vendor-branch.sh` agora RECUSA pin que não seja um commit real da fonte.** Antes, o script gravava no
  histórico do adotante **qualquer string** recebida como pin (`"chore(onion): update to pin ${PIN}"`), sem
  validar. Um placeholder ou uma data entravam no seu histórico como se fossem commit.
- **Ferramenta de auditoria nova:** `pin-integrity-check.sh --audit-vendor <target> <source>` varre os pins
  gravados na sua branch `onion/vendor` e lista os inválidos. É como você confere isto sozinho — não precisa
  acreditar na nossa palavra.
- **Por que isto importa (o dano é DIFERIDO):** um pin inválido não dói no dia. Dói semanas depois, quando o
  merge de 3 vias usa o commit errado como base e lê **ancestralidade como conflito**. Foi exatamente o que
  aconteceu num adotante-irmão: 17 arquivos em conflito, **todos byte-idênticos ao core** — conflito
  contábil, não de conteúdo.

### O que a auditoria achou no SEU vendor (verificado em 1ª pessoa, hoje)

- O topo do seu `onion/vendor` é `e9955073 chore(onion): update to pin 2026-07-12`. **`2026-07-12` é uma
  DATA, não um commit** — foi carimbada no lugar do hash. O `--audit-vendor` sinaliza isto (1 pin inválido).

### O que foi REFUTADO (a parte honesta, e a razão do título)

- **Este anúncio nasceu de um alarme do próprio core que NÃO sobreviveu à verificação.** Ao ver commits de
  produto no `git log onion/vendor`, o core hipotetizou *"o vendor do metagamify está poluído com histórico
  de produto"* — e chegou a cogitar uma limpeza. **Errado, e verificado como errado antes de tocar em nada:**
  - `chore/onion-framework..onion/vendor` = **0 commits**. Seu vendor **não tem nenhum commit próprio** além
    do que a branch de integração já tem.
  - `onion/vendor..chore/onion-framework` = **3 commits**. Seu vendor está apenas **3 commits atrás** da
    integração, e é **ancestral** dela.
  - Os commits de produto no `git log` do vendor são **ancestralidade compartilhada por design** — o
    `onion/vendor` é *ramificado da integração* (não órfão), e o produto é snapshot intocado. Isto é o
    esperado, não pollution.
  - O risco estrutural do adotante-irmão (base de merge quebrada) **NÃO se aplica a você**: como o vendor é
    ancestral da integração, a base está íntegra. Sua integração inclusive já passou por cima do carimbo ruim
    com um re-carimbo correto (`880fab34 … pin 9547ca7`).

### Recomendação (você é o escritor do seu repo — I3)

- **Nada a limpar.** O `2026-07-12` é uma **mensagem** de um commit histórico, não um defeito estrutural. A
  guarda nova impede que o **próximo** update grave lixo; a decisão sobre a cicatriz histórica é sua.
- **Se e quando quiser conferir:** rode `bash .claude/validation/pin-integrity-check.sh --audit-vendor . <core>`
  depois do `--update`. Você verá o mesmo `1 inválido` que vimos — e poderá decidir se ignora (cicatriz
  honesta) ou reescreve (custo alto, ganho cosmético).
- **O core não reescreveu, nem reescreverá, o seu histórico.** Entregamos o achado e a ferramenta; o volante
  é seu.

### Crédito e parentesco

- **Achado de campo** rodando o `/meta:adopt --update` contra um adotante real (não em fixture) — a mesma
  disciplina de *"passar no teste é prova de forma; ser exercido contra o mundo é prova de função"*. A guarda
  de pin nasceu porque a capacidade foi **usada**, não desenhada.
- Fecha, com mecanismo, a refutação que o grafo do core já registrava em abstrato: *"o híbrido subtree+pin
  está resolvido" → refutado por drift silencioso de pin*. Agora o drift tem nome (`vnextpin`, `2026-07-12`),
  guarda de entrada e ferramenta de auditoria.
