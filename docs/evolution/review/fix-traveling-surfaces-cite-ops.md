---
reviewed_diff_sha256: pendente
findings_total: 19
findings_real: 7
tokens: 245722
duration_min: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Duas passadas de um refutador em worktree isolada, com mandato de achar FALSO POSITIVO. A 1ª
  REPROVOU a REGRA 100: quatro falsos positivos reais (ops/ de outro projeto, presença testada em
  outra linha, sandbox de selftest, variação do marcador) e um falso negativo de catraca (2ª citação
  de token já tolerado). A 2ª APROVOU COM RESSALVAS e achou que uma cura da 1ª reabria o defeito
  verbatim em prosa. Os sete reais foram curados; os teóricos baratos também; o resto está no teto do
  cabeçalho. 17 casos no selftest, 19 mutantes mordem.
---

# Resíduo — `fix/traveling-surfaces-cite-ops`

A REGRA 100 (Superfície que viaja não cita ops/ como se o destinatário o tivesse) foi forjada pelo
`/meta:forge-guard` sobre o SAC-86. O defeito foi medido em 2026-10-09, na materialização do
onion-standalone: a lente `kg-grammar.md` descrevia ao adotante um script de `ops/`, e `ops/` não
viaja.

## 1ª passada — REPROVA (13 achados, 5 reais)

A prova veio do modo de produção. Uma rule com `src/ops/handler.ts` saía HARD e travava o merge.

**Os cinco reais, todos curados:**

1. **`ops/` precedido de segmento literal ou URL era acusado.** Agora o token só conta no início de
   palavra ou depois de uma variável de raiz, que é uma lista fechada.
2. **Teste de presença numa linha e uso na seguinte.** A linha do uso era acusada. Agora o token
   testado fica guardado, inclusive pela variável que o recebe, e só esse token fica guardado.
3. **Fixture de selftest de outra guarda** (`${tmp}/ops/motor.sh`). Já estava no baseline. Saiu pela
   cura 1.
4. **Variações honestas do marcador** (`(Core-only)`, `(core-only, …)`).
5. **A catraca por par `arquivo|token` era um passe livre.** A 2ª citação de um token tolerado passava
   calada. O baseline agora conta as ocorrências.

**Também curados:**

- CRLF e BOM no frontmatter;
- token que não é arquivo (`ops/s/core`, `ops/1.5`);
- frontmatter negado ou sem fechamento;
- o `paths:` de uma rule, que é gatilho de carga e não descrição.

**Declarados no teto:**

- árvore genérica em bloco cercado;
- `.yaml` sem isenção de arquivo;
- hook sem extensão;
- catraca sem referência no PR de bootstrap.

## 2ª passada — APROVA COM RESSALVAS (6 achados, 2 reais)

1. **Falso negativo real, aberto pela cura 2.** A presença propagada ao arquivo inteiro também valia
   em prosa. Um bloco de exemplo com `[ -f ops/… ]` calava a frase do SAC-86 escrita acima dele.
   Agora a presença vale no arquivo inteiro só em código; em prosa, vale só na mesma linha. O caso
   (xvi) cobre isso, com mutante.
2. **`[ -r …ops/… ] && . …` era acusado.** O `-r` e o `-L` passaram a contar como teste de presença.
   Caso (xvii).

Os achados 3 e 4 (pontuação do marcador e do frontmatter) foram curados numa linha. Os achados 5 e 6
(variável de raiz fora da lista e `$(mktemp -d)/ops/`) ficaram declarados no teto.

## Defeitos meus que o dogfood pegou

- **A 1ª execução do selftest deu seis verdes por VACUIDADE.** O script não era executável e o
  selftest o chamava pelo caminho. Saída vazia cala tudo.
- **O join do baseline usava `FNR==NR`.** Com o baseline vazio, essa condição casa o 2º arquivo.
- **Um mutante com comentário dentro do awk quebrava a sintaxe** em vez de reverter a cura.

## O que esta guarda NÃO garante

Ela vê a FORMA, não o SENTIDO. A citação que descreve o core sem se marcar é acusada igual à que
descreve o destinatário. A classe descrita sem o token `ops/` passa calada.

Passivo na catraca: 31 pares (`arquivo|token|N`).
