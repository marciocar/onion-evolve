---
reviewed_diff_sha256: 94620a24fd117828baffbcbda7707d7cfb369d887edc80e168cff142eb1cd2c4
reviewed_code_sha256: a06740c150c3eeeeca796fe6129d1c863dab0facf8668adb3a6ca70e2b3f3f8d
findings_total: 6
findings_real: 4
tokens: 118635
duration_min: 16
verdict: CORRIGIDO
elenxo: sim
nota: >
  Uma passada de refutador novo, só-leitura, com mandato de achar falso positivo. Ele aprovou com
  ressalvas: 6 achados, 4 reais, nenhum reprovando. O mais sério era o portão do carteiro vir antes do
  dedup, o que fazia um reenvio com tudo já triado pedir confirmação; o portão agora conta só os
  pendentes, com caso e mutante. Os outros reais (unknown marcando false num destino que pode ser
  privado, resumo reescrito no mesmo arquivo untracked, régua --- na linha 1) foram curados ou
  declarados no teto. O endurecimento do --selftest contra GIT_DIR entrou. Nenhuma regressão no
  comportamento antigo do co-relay: a família corelay segue verde.
---

# Resíduo — `feat/relay-guard-public-target`

Este PR forja, pelo `/meta:forge-guard`, a guarda que o hub propôs em 2026-10-29 para o carteiro
upstream. São duas metades. O `co-relay.sh` mede a visibilidade do destino pelo forge e, se ele é
público ou não foi medido, para sem `--confirm-public`; com a confirmação, entrega o sinal marcado
`reviewed_for_public: false`. A REGRA 113 (Sinal relayado a destino público só se commita revisado)
lê o índice do destino e barra o commit da marca false.

## Defeito medido

São 2 casos em 3 dias (2026-10-27/28 e 2026-10-29) de sinal de adotante chegando ao inbox do core,
que é público, com detalhe do projeto do remetente. Nos dois quem segurou foi a revisão do core, sem
mecanismo. Os detalhes não entram aqui.

## A passada adversarial

| # | achado | severidade | real | desfecho |
|---|---|---|---|---|
| 1 | o portão para antes do dedup: reenvio com tudo já triado pede confirmação | média | sim | curado: o portão conta só os pendentes; caso (m) com mutante |
| 2 | visibilidade não medida marca false num destino talvez privado, e a REGRA 113 acusa lá | média | sim | curado: a marca diz, em comentário, a visibilidade medida, e a mensagem da regra diz que unknown num repo privado se resolve com true |
| 3 | `---` na linha 1 como régua vira frontmatter | baixa | sim | declarado no teto (check e grafo) |
| 4 | apagar a linha da marca cala a guarda | baixa | teto | declarado no cabeçalho do check |
| 5 | resumo reescrito no mesmo arquivo untracked é sobrescrito por um reenvio | baixa | sim | curado: o co-evolve.md manda escrever o resumo com nome novo |
| 6 | o `--selftest` do check, chamado de dentro de um hook, mexeria no índice real | baixa | hipotético | curado: limpa GIT_DIR, GIT_INDEX_FILE, GIT_WORK_TREE e GIT_PREFIX |

## Bancada

- Família `relay_public`: 30 verdes, 0 falhas. Cada comportamento do carteiro tem caso e mutante
  (público para, não medida para, privado passa byte-idêntico, a marca entra, o true do remetente sai,
  frontmatter criado, dry-run mostra, lista avisa, dedup pré-guarda, reenvio triado é no-op). Há também
  o dispatcher da REGRA 113 sobre o índice que o carteiro produz, o `--selftest` do check (10/10), 5
  mutantes dele e o índice real no modo `--format tsv`.
- Família `corelay`: 46 verdes. Ela ganhou um gh falso, porque os casos de hub e de vendor têm remote
  no GitHub e chamariam a rede.

## O que a guarda não pega

Paráfrase, `true` gravado sem reler, a linha da marca apagada, sinal que não passa pelo carteiro, e
confirmação no reflexo. A confirmação é lombada; a revisão continua sendo do destino. O grafo
`docs/evolution/research/guard-relay-public-review-2026-10/` guarda o defeito, as decisões e os tetos.
