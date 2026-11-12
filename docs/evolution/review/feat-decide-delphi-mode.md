---
branch: feat/decide-delphi-mode
pr: pendente
date: 2026-11-12
reviewed_diff_sha256: 43aa0e6a1cb1bea44cab4e44079b8866dae46b5b289b418cd3c60603bfb8c52d
reviewed_code_sha256: e43e0db66e49231e0f97fe7ab2a9cf2abd51cb337968f581b4daa1f5ff8ac68d
findings_total: 16
findings_real: 16
findings_blocking: 3
tokens: 145223
duration_min: 173
findings_fixed: 5
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "passada do construtor e refutador independente (subagente opus, sessão principal, 2026-11-12)"
nota: "tokens e duration_min são do refutador independente (a passada do construtor não foi medida). O refutador ficou cerca de 3h preso num tool_use sem resultado antes de fechar o veredito, o que infla duration_min"
---

# Passada adversarial: `feat/decide-delphi-mode`

## O que muda

Forja do **modo Delphi** do `/meta:decide` (`D_FORGE_DELPHI_MODE_IN_DECIDE_1111`, maestro, 2026-11-11), peças 2,
3 e 7 (o decide já tinha 5 e 6):

- **Doutrina (peça 2):** cláusula 11 da `decide-doctrine`: quando usar, as três rodadas, o anonimato da rodada
  2, o dissenso declarado como parte do selo e o que o modo não promete.
- **Estado e medidor (peça 3):** `.claude/validation/decide-delphi.sh` (`open`, `record`, `propose`, `anon`,
  `status`, `synthesis`), com o estado fora do git em `~/.local/state/onion/delphi/<id>.json` (700/600,
  escrita atômica sob flock), ordem embaralhada por sal guardado no estado e cerca R15.2 ao reexibir.
- **Superfície:** seção "Modo Delphi" no `decide.md` (versão 1.4.0); o selo segue pelo `kg-decide-seal.sh`,
  com a narrative gerada pelo `synthesis` no nó que nasce `open`.
- **Bancada (peça 7):** família nova `run_decide_delphi_selftests`, casos (d1) a (d8), sete com mutante.
- O script entra no manifesto do plugin `onion` (viaja com o decide).

## Achados

1. **Bloqueante, curado.** O `anon` de uma rodada incompleta marcava a rodada como emitida, e quem respondia
   depois lia as posições alheias antes de escrever a sua. Cura: `anon` incompleto só com `--partial`, e a
   resposta gravada depois do anon da rodada fica marcada **tardia** no `status` e na síntese. Prova: (d7).
2. **Curado.** A síntese e o dissenso do condutor saíam sem desarme na saída que também carrega cercas.
   Cura: `defang` nos dois.
3. **Curado (dogfood).** A reencenação mostrou o texto do core denunciando o autor ("o core não vira
   dependência"). O `anon` agora avisa, sem dizer qual sessão, quando uma posição cita um participante; o
   limite fica declarado na doutrina.
4. **Limite.** O `status` liga sessão a confiança, e o `anon` mostra confiança por posição: os dois juntos
   desfazem o anonimato. Declarado no cabeçalho e na doutrina: às sessões vai só o `anon`.
5. **Limite.** O nome de quem objetou é conferido por palavra inteira; "onion-core" conta como "core", e a
   conferência prova a presença do nome, não a fidelidade do dissenso.

### Refutador independente (2026-11-12): REJECTED, 2 bloqueiam e 9 limites, os 2 curados pela sessão principal

6. **Bloqueante, curado.** A narrative que vai ao selo dizia "posições independentes" mesmo com posição tardia e
   sem rodada 2 de quem respondeu (prova do refutador: `synth-late.txt`). A marca tardia só ia à tabela, que não
   entra no nó. Cura: a narrative diz "independência PARCIAL" e nomeia sem rodada 1, posição tardia, sem rodada
   2 e troca por `--replace`. Prova: (d9), com mutante.
7. **Bloqueante, curado.** Objeção da rodada 3 trocada por aceite com `--replace` sumia do estado e da síntese.
   Cura: a resposta anterior vai para `history`, a síntese mostra a objeção retirada cercada e a narrative nomeia
   quem a retirou. Prova: (d10), com dois mutantes (sem histórico; sem a recusa da resposta repetida, que antes
   sobrevivia).
8. **Limite, declarado na doutrina.** O `<id>.json` guarda sal e autor, e outra sessão do mesmo usuário o lê.
9. **Limite, declarado na doutrina.** Comparar o `anon --partial` com o completo mostra quem chegou depois.
10. **Limite.** A rodada 2 é aceita de quem não fez a rodada 1; agora a narrative nomeia quem ficou sem rodada 1.
11. **Limite.** `--absent c,c` não deduplica.
12. **Limite.** `--absent` permite fechar com uma só voz, desde que os ausentes fiquem nomeados.
13. **Limite.** A conferência do dissenso por palavra inteira casa nome curto como `a` (já declarado).
14. **Limite.** `chmod 700` num `ONION_DELPHI_DIR` preexistente o fecha.
15. **Limite.** A confiança vem da primeira linha `confiança:`, mesmo dentro de citação.
16. **Limite.** A bancada não cobre `propose` depois da rodada 3, `--absent` de quem respondeu e a rodada 3 sem
    `--stance`. A marca tardia e a recusa da resposta repetida passaram a ser cobertas por (d9) e (d10).

Resistiu ao refutador: a cerca R15.2 (nenhum `/tmp/pwned*` criado), os ids maliciosos (rc 2), as permissões
700/600, a narrative em YAML válido com caracteres difíceis e a ordem do anon presa ao sal.

## Mutantes

Dez mutantes plantados pelo `ops/mutate-and-restore.sh` no `decide-delphi.sh` real, cada um contra
`lint-selftest.sh --families decide_delphi` com `LC_ALL=C`: todos **morreram** (rc 1 do helper), com o caso do
defeito reprovando no SUT limpo: autor no cabeçalho do anon (d1), ordem sem o sal e ordem dos participantes
(d2), status sem o nome de quem falta (d3), synthesis sem a recusa da rodada 3 incompleta (d4), sem a recusa
da objeção sem dissenso e sem a do dissenso que não nomeia (d5), sem o desarme da cerca (d6 e d2), sem a
ordem das rodadas e sem a exigência do `--partial` (d7). A família também carrega os próprios mutantes em
cópia (11, inclusive a chave instável que muda com o estado), e roda verde: `decide,decide_delphi` 57 casos,
0 falhas, 0 pulos, com `ONION_ASK_DIR` isolado.

## Dogfood

Reencenação do Delphi do serviço Onion na VPS (curadoria, kg-ssot, core) a partir do selo
`D_VPS_SERVICE_EDGE_WITH_TWO_BLOCKING_GATES_1111`: as rodadas originais não estão no repo, então as posições
foram reescritas do label, dos nós vizinhos e da opção descartada, e o dissenso do core é reconstruído. O
modo de falha rodou: rodada 2 antes do anon (rc 2), synthesis com rodada 3 incompleta, sem dissenso e com
dissenso sem o nome (rc 2 nas três), e a síntese final rc 0. O bloco `narrative` gerado entrou num grafo de
sandbox e o `kg-decide-seal.sh` selou rc 0 com a narrative verbatim (resposta do maestro simulada no sandbox;
nenhum grafo real tocado).

## Limites declarados

- Os achados 4 e 5 acima.
- O anonimato é dos metadados; o texto pode denunciar o autor, e reescrever é da condutora.
- `--from` é declaração da condutora: o estado não prova que a resposta veio da sessão nomeada.
- Sem refutador independente nesta execução (o brief proibiu lançar agentes).

Depois da cura do refutador: `--families decide_delphi` com 10 casos (d1–d10), 0 falhas; mutantes novos `limpo = True`
(d9), sem `history` (d10a) e sem a recusa da resposta repetida (d10b) mortos.
