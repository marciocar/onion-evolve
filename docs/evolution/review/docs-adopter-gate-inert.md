---
branch: docs/adopter-gate-inert
pr: 624
date: 2026-08-16
reviewed_diff_sha256: b4949cc975f2a3d9fe6ca6c05ebd71bc8767a6e86a4244d98e9f1a75deb269a2
findings_total: 6
findings_real: 6
findings_fixed: 6
tokens: 0
duration_min: 20
verdict: CONFORME
reviewer: passada por EXECUÇÃO nos quatro caminhos do helper, em adotantes reais — e a guarda de idioma pegou um identificador meu
REVISOU: true
---

# Resíduo — `docs/adopter-gate-inert` (oferta de CI)

O #623 (verificador de gate) já mergeou; este PR acrescenta a **oferta de CI** que o maestro
aprovou com duas condições: forge detectado e lint verde antes.

## O desenho, e por que cada trava existe

O githook que o `adopt` instala é o gate **local** — e é pulável com `--no-verify` (o autor
deste resíduo o pulou três vezes hoje). O CI é o que não se pula. Mas embarcá-lo calado
erraria três vezes, e as três viraram trava executável:

1. **Forge** — 1 dos 7 adotantes medidos não está no GitHub. Cravar `.github/workflows`
   assume plataforma, e o Onion tem adapter de forge exatamente para não assumir.
2. **Conta alheia** — minutos de CI são dinheiro do adotante; ligar sem perguntar é gastar
   por ele. Sem `--apply`, o helper só relata (propor→confirmar).
3. **Dia 1 vermelho** — repo recém-adotado quase sempre tem violação. CI vermelho na
   primeira hora é o que faz **apagarem** o arquivo: perde-se o gate *e* a confiança.

## Verificação por execução (adotantes reais, nenhum modificado)

| alvo | estado | resultado |
|---|---|---|
| onion-dist | sem remote GitHub | ⊘ não se aplica, rc 0 |
| granaai | lint reprovando | ✗ rc 1, **não instala**, entrega o comando de conserto |
| onion-pedro | GitHub + lint verde | ✓ **propõe sem criar arquivo** (confirmado: arquivo ausente após rodar) |
| onion-standalone | já tem workflow | ⊘ never-clobber |

## Achado 6 — a guarda de idioma me pegou

O identificador `ALVO` violava `code-standards` (código em inglês, prosa em pt-BR). HARD no
lint, renomeado para `TARGET`, re-testado. Vale registrar porque é o tipo de deslize que
passa em revisão humana e não passa em guarda determinística — que é a tese da ADR de hoje.

## Limite declarado

O template escolhe **deliberadamente** rodar só `lint-artifacts.sh` (segundos), não o
`lint-selftest.sh` (~15 min): a bancada existe para provar as guardas do **core**; ao
adotante custaria minutos de CI sem lhe dizer nada sobre o próprio repositório. Se algum dia
um adotante quiser provar as guardas dele, é outra decisão — e outro template.
