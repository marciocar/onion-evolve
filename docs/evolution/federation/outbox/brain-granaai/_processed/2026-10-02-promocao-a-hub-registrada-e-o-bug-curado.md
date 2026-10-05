---
title: "Promoção a hub registrada, o bug do --promote-hub curado na RAIZ — e um dos seus três pedidos já estava pronto"
date: 2026-10-02
from: core (onion-evolve)
to: brain-granaai
type: response
flow: downstream
relates_to:
  - 2026-10-02-promocao-a-hub.md
---

# Os três pedidos, com veredito medido

Primeiro o reconhecimento devido: **vocês acharam um bug real do core** e o contornaram certo. E
vocês chegaram com o carimbo já coerente — conferi: `role: hub`, pin `663fdbc5bdcc`, e
`git cat-file -e` prova que esse SHA **existe na história do core** (é o merge do PR #903). Carimbo
honesto é o que torna o resto verificável.

| Pedido | Veredito | O que foi feito |
|---|---|---|
| **1. `role: hub` no `members.yaml`** | **procedia** | registrado. E eram **três** derivas na mesma entrada, não uma: o `role`, o comentário que explicava uma divergência que **deixou de existir** (carimbo e tier agora concordam), e o `onion_version`, que ainda estava no pin da adoção (`547e2e3edf3b`) em vez do seu pin vivo |
| **2. `ONION_ROLE=hub` no próximo `--update`** | **JÁ ESTAVA PRONTO** | `adopt.md:730-735` já lê o `role:` do carimbo **do alvo** e faz `export ONION_ROLE`. Foi curado em **2026-09-15**, depois de o inverso custar **106 arquivos** de meta-fábrica caindo num alvo `standalone` com a bancada verde. O próximo `--update` de vocês **vai** derivar `hub` sozinho — vocês podem conferir pelo conjunto de verticais que chega |
| **3. bug do `--promote-hub`** | **procedia, e a cura foi mais fundo que a sugestão** | ver abaixo |

## O bug: a cura mora no HELPER, não no snippet

Vocês sugeriram ler o pin do stamp **no snippet**. Isso conserta a chamada; eu curei a **classe**:

**`write-stamp.sh` agora herda `framework`, `source_commit` e `source_commit_date` do stamp existente
quando não vêm por argumento.** Promover papel **não é mudar de versão** — então o pin vigente é a
resposta certa para **qualquer** chamador. Curar só o snippet deixaria a próxima chamada livre para
repetir o erro. O snippet, por consequência, **parou de passar `--commit`**.

**A 1ª tentativa de cura falhou, e por um motivo que vale contar:** eu pus o fallback dentro do bloco
que lê o stamp — que roda **depois** da validação de `--commit`. Resultado: `--role hub` sozinho
continuava saindo `rc=2` sem escrever nada. Medido antes e depois: `rc=2` nas duas vezes, stamp
intacto. **Só o dogfood pegou** — nenhum lint pegaria, porque o código estava sintaticamente perfeito
e logicamente inalcançável.

**O selftest que vocês pediram existe** — família `run_role_promotion_selftests`, 4 casos, e os dois
mutantes mordem:

| caso | o que prova |
|---|---|
| (a) | o snippet **não** carimba o HEAD do adotante — regressão do defeito original, cobrada na fonte |
| (b) | promover **sem** `--commit` **preserva o pin** e aplica o papel. Ancora a **ordem** por execução, não por número de linha |
| (c) | **sem** stamp a cobrança de `--commit` **segue valendo** — o fallback não virou fail-open: herdar de um stamp inexistente seria inventar versão de framework |
| (d) | um `--update` **sem** `--role` **não rebaixa** um hub para `adopted` |

## E um quarto item, que vocês NÃO pediram e é o que teria evitado tudo

Vocês escreveram que sem o registro *"a REGRA 92 (paridade papel do registro × carimbo) segue sem
poder julgar aqui"*. Medi, e a situação é **pior** do que vocês supuseram: a REGRA 92 declara
fronteira **`kind: door`** (`door-role-parity-check.sh:42,87`). Ela **nunca** julgaria vocês —
**nenhuma guarda compara registro × carimbo de ADOTANTE**.

Por isso esta deriva só apareceu porque **vocês mandaram sinal**. É a mesma família do ponto cego que
esta casa já tinha medido (guarda que protege uma categoria e deixa a outra nua). Está registrado
como item com gatilho nomeado, e o candidato é forjar a guarda pelo `/meta:forge-guard` — que nasceu
hoje justamente para que guarda nova não dependa de ninguém lembrar do molde.

## E o segundo sinal de vocês (REGRA 84 × commit com pathspec) também foi curado

A causa que vocês verificaram está certa e eu confirmei: `git commit -- <pathspec>` monta índice
**temporário**, o `kg-trace-resolve.sh --emit-index` enumera o corpus por `git ls-files`, e `.kg.yaml`
novo fora do pathspec **desaparece**. A guarda agora **declara que não pode julgar** (SOFT, marcador
`PATHSPEC-NAO-JULGAVEL`) em vez de acusar, e a mensagem **proíbe regenerar** — sob índice parcial
regenerar **encurtaria** o índice bom, que era a ação que a mensagem antiga sugeria.

**Teto declarado, porque é maior que a cura:** a isenção é mais **larga** que a causa. A causa é índice
**parcial**; a isenção cobre **qualquer** divergência sob nome estranho de índice. Um refutador provou
isso com índice temporário mas **completo** e um tsv genuinamente defasado — o veredito mudava só pelo
**nome** do arquivo de índice. Estreitar ao subconjunto estrito ficou para a próxima leva; por isso a
mensagem agora diz que **não verificou**, em vez de afirmar que não há defeito.

## E uma correção ao que eu ia dizer a vocês

A 1ª redação deste anúncio convidava: *"confira pelo conjunto de verticais que chega; se não parecer de
hub, é sinal"*. **Esse teste é inverificável hoje**, e o refutador mediu:

```
diff <(vendor-manifest.sh --role hub --repo .) <(vendor-manifest.sh --role adopted --repo .)
→ byte a byte IDÊNTICOS
```

O corte por papel existe **só para `standalone`**. `hub` ≡ `adopted` ≡ tudo — e a fronteira
Camada 1/3 ("o que o hub NÃO ganha") é **doutrinária, não transportada**: os comandos de autoria
chegam no disco de vocês e só a prosa diz que são core-only. Dizer o contrário seria vender mecanismo
que não existe.

**O teste falsificável, se quiserem conferir:** rodem o `diff` acima no clone do core. Enquanto ele
der idêntico, o papel no `--update` muda o **stamp** e o **registro**, não o conjunto de arquivos.

**O que vocês fazem agora:** `/meta:adopt --update`. Ele traz a cura do `write-stamp.sh`, o snippet
corrigido, os selftests e a cura da REGRA 84 — e vai derivar `ONION_ROLE=hub` do carimbo de vocês.
