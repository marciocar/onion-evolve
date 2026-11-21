---
branch: docs/decision-ratchet-doctrine
pr: pendente
date: 2026-11-21
reviewed_diff_sha256: eeec96b1922df56a6fb5dff4961cbd064cb7179becd0f0629c68786a919202a1
reviewed_code_sha256: 7bf04135ff879dead4021c1b85509c868259dfb79af9f519e7f675eeb4876a5b
findings_total: 13
findings_real: 13
findings_blocking: 5
tokens: 135005
duration_min: 3
findings_fixed: 13
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "Agente novo e isolado (general-purpose), só leitura, sem a conclusão do autor: recebeu os dois arquivos, o diff do índice e as fontes primárias (os quatro nós do grafo de coordenação, os três relatórios da catraca e o resíduo do selo de 20/11) e conferiu cada afirmação por grep -n."
nota: "Card SAC-494. Não toca guarda. tokens = os do revisor."
---

# Passada adversarial: `docs/decision-ratchet-doctrine`

## O que muda

Uma doutrina nova em `docs/knowledge-base/concepts/decision-ratchet-doctrine.md` e um ADR novo em
`docs/knowledge-base/decisions/onion-adr-decision-ratchet-2026-11.md`. Eles documentam a catraca de
decisões automáticas para explicação e auditoria, como o maestro exigiu no selo
`D_DECISION_RATCHET_SYNTHESIS_SEALED_1120`. O índice da KB e o inventário foram recontados (117 KBs).

## Achados

Os 13 são reais, e 5 bloqueavam. Todos foram curados no mesmo PR.

1. **BLOQUEIA, curado.** «Incidente em C congela todas as descidas» e a definição de reversão apareciam
   como doutrina selada. Eram posições do Delphi, e duas delas se contradizem. Agora estão numa lista
   «Ainda não selado».
2. **BLOQUEIA, curado.** «Hoje o livro vive na mesma máquina», mas o livro ainda não existe. Agora diz:
   «quando nascer».
3. **BLOQUEIA, curado.** O portão de repo próprio omitia a exceção do core, que merja repo da família com
   flag explícita.
4. **BLOQUEIA, curado.** No ADR, «três sessões listaram como eliminatória» classificar pelo texto. Era
   uma só; as outras duas vetaram casos vizinhos.
5. **BLOQUEIA, curado.** A objeção «virou condição da doutrina». A condição já estava na síntese; agora
   o texto diz que a objeção a reforça.
6. A3 aparecia como «descartada pelo selo 3», mas não era opção da pergunta. Agora: afastada pelo efeito
   do selo.
7. A base da objeção era atribuída à sessão que objetou. Ela vem de outra posição do Delphi; o texto
   agora diz isso.
8. Faltava dizer que o clique da ponte de chat é guarda da ponte, não força 2. Acrescentado nos dois.
9. A classe A dizia «o que entra hoje», com a régua desligada, e incluía atos que escrevem algo.
   Coluna renomeada e convenção do selo explicada.
10. As listas fixas de C diferiam entre doutrina e ADR (tag e release). Unificadas; «master» glosado.
11. Gatilhos do ADR e a generalização da regra local vinham de posições, não do selo. Origem marcada.
12. Detalhe operacional de segurança da máquina (`sudo` sem senha, token de dono) e o nome da sessão que
    objetou. Trocados por forma genérica.
13. Termos sem glosa (Delphi, relay, hash, mod no ADR). Glosados.

## Mutantes

Não se aplica: o PR só traz documentação, sem guarda nem código. A conferência mecânica foi o
`kb-index-check.sh` (rc 0) depois de recontar o índice.

## Limites declarados

- A doutrina descreve uma catraca que ainda não roda; o próprio texto diz isso no §9 e no teto.
- Os números da colheita vêm de classificação por regex, aproximada e declarada no relatório de origem.
