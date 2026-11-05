---
reviewed_diff_sha256: 256e753f689583b3564a6824d2cfa8dcdfc208325704b8e97f72a5cb98ddc7af
reviewed_code_sha256: 76841511127dcdcead998c564acd7f54ed63d806faae64bf5c8e983f6472fa79
findings_total: 0
findings_real: 0
tokens: 0
duration_min: 0
verdict: PENDENTE
elenxo: nao
nota: >
  A passada adversarial NÃO rodou: um refutador independente julga depois, com mandato de achar o falso
  positivo (nota honesta barrada ou avisada). Os campos acima seguem sem dizer nada sobre o artefato, e
  quem os preenche é a sessão que rodar a passada, ao fim dela.
---

# Guarda da escrita na memória do Claude Code e a varredura do disco

**A passada está pendente.** Nada aqui é veredito de revisão.

O que uma passada precisa saber antes de começar: o `--selftest` é meu e foi escrito junto com o
artefato. Três pontos cegos conhecidos. (1) O vocabulário do Bash: só se julga o caminho de memória
citado como DESTINO de uma forma listada; o replay de 618 escritas reais deu zero alarme, mas o
replay só mede o que esta máquina já fez. (2) A forma HARD é o par de envelope inteiro; uma nota
que documenta o formato abrindo E fechando a tag dentro de um bloco de código seria barrada, e
nenhum caso cobre isso. (3) A extração de memória em segundo plano do Claude Code não foi medida
contra o PreToolUse.

No adotante, o caso (e) monta o repo só com o manifesto do papel adopted e o registro do
`merge-onion-hooks.sh`; ele não exercita um `/meta:adopt --update` de verdade sobre um adotante clonado.

Os `confirmed` de maior impacto do grafo, que é o que a passada deve tentar refutar:
`E_DEFEITO_MEMGHOST_NO_CLAUDE_CODE_SDK`, `E_NENHUM_HOOK_OLHAVA_A_MEMORIA`,
`E_REPLAY_618_ESCRITAS_ZERO_ALARME` e `E_DOGFOOD_AO_VIVO_2_1_318`.

Grafo da forja: `docs/evolution/research/guard-memory-write-2026-11/memory-write-2026-11.kg.yaml`.
