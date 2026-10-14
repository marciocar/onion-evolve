---
branch: docs/lesson-5-kg-forge
date: 2026-10-14
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 60
verdict: REPROVADO_E_CURADO
reviewer: 2 subagentes (roteiro e slides) + passada própria da sessão principal: varredura de nome de cliente, pessoa, id e caminho de máquina; comandos do deck conferidos contra o roteiro; JS dos dois decks checado
---

# Aula 5 da série de adoção: KG e forja (roteiro, slides e deck)

Material da aula prática de KG e forja para a equipe de um hub: o roteiro (`.md` + `.html`), os slides completos (49) e o deck curto para a apresentação de 2 h (18 slides, só conceitos, fluxos e diagramas). Sem nome de cliente; as aulas 1–4 e 6 só quando o maestro pedir (SAC-134).

## Passada adversarial

1. **A aula ensinava comando que o hub não tinha?** Real, curado: a 1ª versão forjava à mão e selava à mão, porque o forge, o decide e o dissect eram só do core. O maestro os abriu (#1118), o hub foi atualizado e o roteiro passou a usar os três comandos de verdade, com o pin preenchido (6e6deab1c443, onion-v1.2.0).
2. **O vocabulário era claro para a turma?** Real, curado: "coere" virou "está alinhado (aligned)", a pedido do maestro. Nos diagramas virou a forma curta, porque a longa vazava das caixas de 165 e 230 px.
3. **O deck inventa conteúdo?** Real e declarado: no slide 4, a frase "o git guarda os arquivos; o grafo diz em que estado o trabalho está" é redação nova, não está no roteiro; fica para o maestro confirmar. Os comandos e flags dos decks foram conferidos automaticamente contra o roteiro (0 fora).
