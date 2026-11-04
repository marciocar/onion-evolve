---
branch: docs/vibe-subagent-2026-11
pr: pendente
date: 2026-11-04
reviewed_diff_sha256: c0cb592d7743716be9634cfd5fd939276a00cd64d23886684f4858c268878289
reviewed_code_sha256: d6f01912cff938682188cf60c7b3289b1976788cc3fdc0f7ad5372e327717749
findings_total: 0
findings_real: 0
tokens: 6646842
duration_min: 16
findings_fixed: 0
verdict: SEM_ACHADOS
elenxo: nao
reviewer: nenhum
nota: "Não houve revisão adversarial além do run wf_0c8a4e9e-8da. Os zeros de achados significam não medido, e o veredito SEM_ACHADOS só cumpre o vocabulário da guarda, que não tem valor para não revisado. Tokens e duração são do run; o custo da conferência não foi medido."
---

# Passada adversarial: `docs/vibe-subagent-2026-11`

## O que muda

Só pesquisa: o grafo `vibe-subagent-2026-11.kg.yaml`, a `SYNTHESIS.md` e este resíduo, mais a projeção `docs/backlog.md`.
Nenhuma guarda, comando ou código. O grafo nasceu do `/onion-research`, e entrou um nó de fechamento
(`E_VIBE_SUBAGENT_MEDIDO_NOS_SPIKES_1104`), sem reescrever os nós do run.

## Achados

**Não houve passada adversarial sobre este diff**, por isso os campos ficam em 0, que aqui quer dizer não medido. O que
houve foi o Verify do próprio run (3 votos por afirmação) e uma conferência do grafo contra a evidência dos testes das
portas, feita por quem escreveu o nó. As seis correções estão na síntese; elas corrigem a pesquisa, e não são achados de
revisão sobre este texto. Ninguém conferiu a conferência.

## Mutantes

Não se aplica: nenhum executável mudou.

## Limites declarados

- A recontagem usou scripts avulsos, fora do repo, sobre os arquivos de evidência; nenhuma célula nova rodou.
- A ordem era não rodar a bancada, por a máquina ser compartilhada, e ela rodou: o commit b86c25641 passou pelo pre-commit, que a dispara, e eu não conferi isso antes. Foram 1864 casos, 0 falhas, 8 workers e 28 min 44 s. A carga de 1 minuto estava em 7,11 antes e em 11,25 logo depois; o pico não foi medido, então não sei se o limite de 15 foi respeitado.
- Os tokens são o `totalTokens` do diário do run; a soma dos transcritos não reconciliou com ele (a síntese dá os números).
