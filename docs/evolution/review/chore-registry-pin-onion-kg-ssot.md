---
branch: chore/registry-pin-onion-kg-ssot
pr: pendente
date: 2026-10-20
reviewed_diff_sha256: 543ed22e88f4d6994f81e166f75a69d4de23b93e260cad299b19ef5dd7e2016a
reviewed_code_sha256: 8da11d2a8ee41474c5d65f5bb048d2255f0316737fcc60f4f7d844f01c66a4f8
findings_total: 10
findings_real: 3
findings_fixed: 1
tokens: 173810
duration_min: 5
verdict: APROVADO
elenxo: sim
reviewer: "dois subagentes general-purpose independentes do executor, mandato REFUTAR (1ª passada sobre o pin e a tese do papel; 2ª sobre a cura do papel ausente)"
nota: "o hash do diff é carimbado no pr-finalize."
---

# Passada adversarial: `chore/registry-pin-onion-kg-ssot`

O pedido partia de duas alegações medidas em 2026-10-20: o registro do `onion-kg-ssot` diz `role: standalone` e o
carimbo vivo diz `role: adopted`, e "o papel nunca é comparado" pelo `ops/registry-pins.sh`. A 2ª alegação é
**falsa**, e a 1ª não é defeito.

## A tese do papel, refutada antes de qualquer edição

- O `registry-pins.sh` já comparava o papel (bloco `stamp_role` + `case`) pelo mesmo mapa da REGRA 92 (Papel da
  porta no registro concorda com o CARIMBO dela): hub→hub, standalone→standalone|adopted, consumer→adopted.
- Os dois `role:` são dimensões diferentes (comentário do `members-validate.sh`, l.157-170): no registro é o TIER
  na rede; no carimbo é a RELAÇÃO com o framework e o corte. `standalone`×`adopted` é par permitido de propósito, e
  `adopted` nem é valor válido no registro (`ROLES`). "Alinhar" o registro para `adopted` quebraria a REGRA 66.
- A bancada já cobria os dois lados: (f) papel incompatível acusa e não carimba; (f2) standalone×standalone e
  standalone×adopted dão `ok`. Mutantes rodados nesta branch: `*:*` no `case` reprova o (f); tirar
  `standalone:adopted` reprova o (f2).

## Achados

1. **Real, CURADO (baixo, latente).** A conferência de papel só rodava com os DOIS lados preenchidos; carimbo vivo
   sem `role:` pulava direto ao pin, que podia ser o de outra adoção no mesmo remoto e seria carimbado. Cura: com
   papel no registro, papel ausente no carimbo acusa `DIVERGE (papel … × carimbo <sem role>)` e não carimba. Caso
   (f3) novo; o mutante que devolve a condição antiga reprova o (f3) com rc=0 (o pin passou e foi carimbado).
   Medido no `--check` real: nenhum adotante vivo cai nisso (17 em dia, 3 divergentes só por pin).
2. **Real, não curado (cosmético, anterior a este diff).** Remoto falho + clone com carimbo de papel incompatível
   ou ausente sai `DIVERGE` (rc=1) em vez de `ILEGÍVEL` (rc=3), porque a conferência de papel vem antes do teste
   `remote_failed`. Nos dois rótulos nada é carimbado; só a nomenclatura é menos exata.
3. **Real em tese, refutado na medição.** "Membro sem `role:` no registro pula a conferência, e o
   `members-validate.sh` não roda no gate." Roda: o `lint-artifacts.sh` (l.5421-5429) o chama como REGRA 66 HARD.
4. a 10. **Não-reais:** `fab7711811d4` é commit do core e ancestral de `origin/main`; o carimbo remoto diz o mesmo
   pin com `role: adopted` e `integration_branch: main`; o diff do registro é uma linha só; o `members-validate`
   passa (29 membros); `_st` vem sempre da mesma fonte que deu o pin; o (f3) testa o que diz.

## O desenho: o papel é só acusado, nunca carimbado

O `--seal` carimba só o pin. O papel muda o corte de maquinaria que viaja para o adotante, e re-carimbá-lo é ato da
sessão DELE (`/meta:adopt --update --role …`); o registro, quando for o lado errado, se alinha à mão com decisão.
Carimbar papel pela leitura de um remoto seria deixar o core decidir o tier de outra sessão por inferência.

## Veredito

**APROVADO.** O pin do `onion-kg-ssot` sobe para `fab7711811d4` pelo caminho da casa
(`--seal --only onion-kg-ssot`), o papel fica como está (par permitido) e o buraco do carimbo sem papel fecha com
bancada que morde.
