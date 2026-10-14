---
branch: feat/lint-door-leak-scan
date: 2026-10-14
reviewed_diff_sha256: 574f8e7db9e47a1d3488b41cc36341c460ba9c0f058014c4015e6c7d5ca4da89
reviewed_code_sha256: d5dc2b9e183943baaa7f1579666078a61aa8c31584bce1984b2fe61b08f6b646
findings_total: 4
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 25
verdict: REPROVADO_E_CURADO
reviewer: passada própria sobre o diff inteiro, com a bancada nova (12 casos e 8 mutantes), publish e publish_release, lint cheio no branch e a medição sobre e5e9a265, 91dcb25d e o main com o #1097
---

# A varredura de vazamento da publicação passa a barrar no PR

## O que o PR faz

- Extrai o passo (5a) do motor de publicação das portas para `.claude/validation/door-leak-scan.sh`:
  o parser do registro, a derivação dos ids de adotante e das contas reais, e a varredura das três
  famílias (`sub`, `word`, `home`). O motor chama o helper e fica só com os nomes comerciais e a fonte
  privada, cuja ausência continua sendo falha fechada na publicação.
- Cria a REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação), HARD na
  fonte, com as famílias `word` (id `onion-*` de adotante, palavra inteira) e `home` (conta real), nas
  raízes de `vendor-manifest.sh --emit-scrub-roots`. A família `sub` fica com a REGRA 36, que no core
  varre um superconjunto dela. Em adotante, hub e porta a regra não julga; na fonte sem registro, declara
  NAO-VERIFICADO e a família `home` ainda roda.
- Bancada `run_door_leak_scan_selftests`, nó de evidência e decisão no grafo das portas, e a doutrina e
  o comando da publicação citando a regra.

## Medição (o dano e a cura)

| commit | ids `onion-*` | caminhos de máquina | arquivos | rc |
|---|---|---|---|---|
| `e5e9a265` (antes do #1096) | 23 | 8 | 13 | 1 |
| `91dcb25d` (depois do #1096, antes do #1097) | 23 | 0 | 11 | 1 |
| `origin/main` com o #1097 | 0 | 0 | 0 | 0 |

Custo da regra: 0,11 a 0,20 s por passada do helper sobre as raízes que viajam, mais ~0 s do manifesto.
O lint inteiro levou 465 s e 505 s nesta máquina, com carga entre 3 e 4. Esse tempo é da carga, e o lint
não mede tempo por check: a diferença atribuível à regra é o custo do helper.

## Passada adversarial

Perguntas: o placeholder genérico (`/home/<user>/`) acusa? Id citado em URL pública acusa? Quanto custa?
O motor e o lint podem divergir?

1. **Mutante que abortava o lint contava como mordida.** O 1º mutante da restrição às raízes trocava
   `&&` por `;` e o `set -e` derrubava o lint inteiro. O caso só olhava as linhas da REGRA 106, e no modo
   "o HARD sumiu" um lint morto passaria por mordida. **Curado:** o laço de mutantes exige o sumário do
   lint e reprova o mutante que aborta, e esse mutante virou sintaticamente seguro (`&& :`).
2. **Mensagem que se lia como invocação.** A 1ª mensagem do HARD de caminho sugeria
   `bash .claude/validation/door-leak-scan.sh --families home -- <arquivo>`. A REGRA 59 (Modo que a
   produção consome é exercitado pela bancada) leu isso como modo de produção sem teste. **Curado:** a
   mensagem não traz mais o comando, e o caso (j) exercita os modos que a produção consome
   (`--families`, `--terms-file`, `--emit-members-tsv`, registro ilegível com rc 2).
3. **Placeholder genérico: não acusa, mas a fronteira depende da máquina.** As contas vêm do registro,
   de quem roda e do passwd, nunca de uma lista. Nas raízes que viajam há 10 nomes de exemplo em
   `/home/<nome>/` (`x`, `conta`, `user`, `u`, `fake`…), e `/home/<user>/` nem tem forma de conta. Medido:
   nenhum desses nomes é conta real nesta máquina. **Declarado, sem cura:** se um dia existir a conta
   `user` aqui, os exemplos passam a acusar, no lint e no motor igual. Uma lista de genéricos tolerados
   falharia pelo vocabulário, que é o que o (5a) já recusou.
4. **Id em URL pública.** Porte e porta (kind `port` e `door`) ficam de fora pelo kind, inclusive dentro
   de `github.com/<dono>/<id>`, e o caso (c) prova isso. Já `github.com/<dono>/onion-<adotante>` acusa, e
   está certo: é o nome do repo privado. **Declarado:** a palavra inteira do `grep -w` trata `-` como
   fronteira, então `onion-<id>-x` casa o id. O motor faz o mesmo (paridade), e hoje há 0 casos.

## Teto declarado

- Não julga adotante, hub nem porta. A porta é varrida pelo motor na publicação.
- Conta de outra máquina fora do registro e id `onion-*` de adotante não registrado não são vistos.
- O caso (i) confere a forma do motor por grep. Um refator que mude a chamada pede atualizar o caso.
- O lint cheio deste branch tem 1 HARD que não é da regra: a projeção `docs/onion/testing-inventory.md`
  (REGRA 80), que o `pr-finalize` regenera.
