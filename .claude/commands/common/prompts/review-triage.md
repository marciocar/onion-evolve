---
description: "Régua da triagem de achados de revisão separada (Elenxo, passada adversarial, refutador de forja): o que BLOQUEIA e o que entra como LIMITE declarado; alimenta findings_blocking do resíduo da REGRA 56."
---

# ⚖️ Triagem de achados: BLOQUEIA ou LIMITE (fragmento canônico)

> **Fragmento canônico compartilhado (SSOT).** Referenciado, **não copiado**, pelo `/engineer:pr`
> (passada adversarial), pelo `/meta:forge` e pelo `/meta:forge-guard` (Elenxo da forja), pelo
> `/meta:dissect` (Elenxo da dissecação) e pelo workflow `.claude/workflows/onion-research.js` (Elenxo
> da pesquisa, que traz a régua em uma linha por limite de prompt). Quem encomenda revisão a agente
> separado cola a seção "Para colar no brief" sem cortar.

## Por que existe (medido na noite de 2026-11-05/06)

O pré-registro do estudo `problem-route` passou por **8 versões** (o pré-registro e 7 emendas) em 3 h 28 min,
porque cada rodada tratava todo achado como bloqueio. Com a triagem **INVALIDA** (bloqueia) contra **LIMITE**
(entra declarado) pedida na 7ª rodada, **fechou em 2**; os achados de precisão, cobertura e n viraram os 7
limites declarados da última emenda. As guardas forjadas na mesma noite levaram **3 a 4 voltas** de
refutação cada (relato da sessão principal, não medido aqui). A lição mora no repo da curadoria
(`docs/curation/tools/review-triage-brief.md`, o checador `review-triage-check.sh` e o nó
`C_REVIEW_TRIAGE_IN_PATH_1105` do grafo `curation-process-2026-11`); a curadoria propôs ao core o campo
`findings_blocking` ao lado de `findings_real`, e a sessão principal aceitou. Este fragmento é a
adaptação do core, **não cópia**: o formato de linha e o checador de forma são da curadoria e ficam lá.

**Padrão de mercado de onde a régua parte:** Conventional Comments (<https://conventionalcomments.org/>),
decoração `(blocking)` / `(non-blocking)`. O que o Onion acrescenta, declarado: a decoração é
**obrigatória** em todo achado real, e o critério de bloqueio é fixo (abaixo), não gosto de quem revisa.

## A régua

Um achado **BLOQUEIA** só quando ao menos um destes vale, e quem o escreve mostra o **cenário concreto**
(a entrada ou o estado, e o resultado errado que ela produz):

1. **o veredito pode sair diferente numa direção previsível** — o defeito empurra o resultado sempre para
   o mesmo lado (a guarda passa o que devia barrar, a contagem infla, o caso de bancada passa com a cura
   revertida);
2. **o veredito fica ao arbítrio de quem conduz** — quem roda escolhe o n, o corte, a fixture ou a ordem e
   com isso escolhe o resultado;
3. **o artefato promete algo que não entrega** — o texto, a mensagem ou o cabeçalho afirma uma cobertura,
   um número ou um comportamento que o código não faz.

Todo o resto é **LIMITE**: afeta precisão, cobertura, n, estilo ou manutenção, e o artefato segue com uma
**frase declarada** (no resíduo, em `## Limites declarados`; no estudo, no relato). Limite não é achado
descartado: é achado real que não segura o merge.

**Na dúvida, escreva o cenário.** Se o cenário concreto não sai, é LIMITE. Em re-revisão, **não reabra**
limite já declarado: confira só se o bloqueio anterior foi curado.

## No resíduo da REGRA 56

A REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial) ganhou o campo `findings_blocking`: quantos
dos `findings_real` **bloqueiam** por esta régua, com `0 ≤ findings_blocking ≤ findings_real`. O campo é
**opcional**: resíduo anterior a 2026-11-06 segue válido sem ele, e uma passada que não triou **apaga a
linha** (ausente = não triado; `0` = triado e nenhum bloqueia). O validador
(`.claude/validation/review-artifact-check.sh`) cobra só a forma e o teto; se a triagem foi justa é
trabalho de quem lê o resíduo, não de script.

## Para colar no brief

> **Triagem obrigatória, em todo achado real.** Marque cada um como `(blocking)` ou `(non-blocking)`.
> - `(blocking)` = **INVALIDA**: o veredito pode sair diferente numa direção previsível, ou ao arbítrio de
>   quem conduz, ou o artefato promete algo que não entrega. Na mesma linha, `cenário:` com a entrada ou o
>   estado concreto e o resultado errado que ele produz. Sem cenário concreto, não é bloqueio.
> - `(non-blocking)` = **LIMITE**: afeta precisão, cobertura, n ou manutenção, e o artefato segue com uma
>   frase declarada. Na mesma linha, `limite:` com a frase pronta para entrar no texto.
>
> Só `(blocking)` segura o merge (ou o de acordo). Na dúvida, escreva o cenário: se ele não sai, é limite.
> Numa re-revisão, não reabra limite já declarado; confira só se o bloqueio anterior foi curado.
> Termine com a contagem `blocking=N non_blocking=M`.
