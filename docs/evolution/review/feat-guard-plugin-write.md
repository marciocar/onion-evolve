---
reviewed_diff_sha256: pendente
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
verdict: PENDENTE
elenxo: nao
nota: >
  A passada adversarial NÃO rodou. A forja saiu de um subagente, que para no resíduo; quem roda o
  Elenxo é a sessão principal do core, em revisor novo, com mandato de achar o falso positivo
  (guard-doctrine, cláusula 4). Até lá os campos acima não dizem nada sobre o artefato.
---

# Veto à escrita de plugin em .claude/skills e a varredura do disco

**O Elenxo está pendente.** Nada aqui é veredito de revisão.

O que uma passada precisa saber antes de começar: o `--selftest` é meu e foi escrito junto com o
artefato. Ele tem dois pontos cegos conhecidos. Um é o que nem os mutantes nem o replay alcançam: a
composição com o `moat-judge.py` herda toda a tabela de verbos do MOAT, e eu só testei as formas que
os casos nomeiam. O outro é a rota de script solto e a de symlink, que o replay não mede.

Os `confirmed` de maior impacto do grafo, que é o que a passada deve tentar refutar:
`E_DEFEITO_PLUGIN_EM_SKILLS_VENCE_O_VETO`, `E_NENHUM_VETO_BARRA_ESCRITA_EM_CLAUDE`,
`E_REPLAY_ACHOU_UM_FALSO_POSITIVO` e `E_DOGFOOD_AO_VIVO_NO_HARNESS`.

Grafo da forja: `docs/evolution/research/guard-plugin-write-2026-11/plugin-write-2026-11.kg.yaml`.
