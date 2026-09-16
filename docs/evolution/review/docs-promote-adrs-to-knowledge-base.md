---
title: 'Resíduo — promover ADRs ao knowledge-base publicou 32 nomes que eu não tinha visto'
date: 2026-09-16
branch: docs/promote-adrs-to-knowledge-base
reviewed_diff_sha256: 779ff6e575e9029154aa82e9ef0a7a31116bb46534c8aa4fe10bc5c7305899f9
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: nao
nota: >-
  Os quatro refutadores foram GUARDAS. A REGRA 36 achou a razão social que o meu grep de id não
  alcançava; a REGRA 22 achou que eu reescrevi as referências PARA os ADRs e esqueci as de DENTRO
  deles; a REGRA 45 passou a valer sobre eles porque agora viajam — e cobrou na hora. Nenhum achado
  veio de leitura minha.
---

# A promoção que quase publicou quem são os clientes

## O que o maestro pediu

Liberar a meta-fábrica ao plugin público *"sem nada pessoal, sem segredo, sem identificação de
empresa"*, e para isso promover ao `knowledge-base` os ADRs que a fábrica cita — para quem instala
receber também o **porquê** do mecanismo, não só o mecanismo.

## A parada antes do `git mv`

Medi o **conteúdo** antes de mover, e foi o que salvou:

| o que | n |
|---|---|
| ids do registro (`metagamify`, `granaai`, `arandek`, `gustavo-pulga`) | 22 |
| nomes **fora** do registro (`rhilo-app`, **`Tornak`**) | 5 |
| caminhos de máquina (`/home/marcio/...`) | 5 |
| razão social (**`Grana.Ai`**) — achada só pela REGRA 36 | 1 |

**`Tornak` é cliente de um adotante.** Exposição de segundo grau: o `members.yaml` nunca o conheceu,
e nenhum grep meu por id o acharia. É o ponto cego que a migalha `vendor-scrub-blind-spot` registra —
a guarda só protege quem está no registro.

Promover cru teria publicado, **para todos os adotantes**, quem são os outros.

## Os quatro achados, e os quatro vieram de guardas

**1. REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) achou `Grana.Ai`.** Eu varri o
**id** (`granaai`); a guarda conhece também a **razão social**, com ponto e maiúsculas. Eu conhecia
uma forma do nome, ela conhece as duas.

**2. REGRA 22 (Links relativos quebrados em docs/evolution/ e docs/knowledge-base/) achou o erro
simétrico.** Reescrevi cuidadosamente as 82 referências **para** os ADRs — e esqueci as **de dentro**
deles. Saindo de `docs/analysis/` para `docs/knowledge-base/decisions/` desceram um nível, e todo
`../` ficou curto. Só o lint viu.

**3. REGRA 45 (Link vendorizado não aponta caminho core-privado, com catraca) passou a valer sobre
eles — porque agora viajam.** Isso não é efeito colateral, é o objetivo: o ADR entrou na superfície
vendorizada e herdou as guardas dela. Cobrou os ponteiros privados de dentro, e a catraca detectou o
escopo expandido.

**4. Sete links NUS para vizinhos que ficaram.** Funcionavam quando os ADRs moravam ao lado deles em
`docs/analysis/`. Apontar para lá de superfície vendorizada seria a própria REGRA 45 — viraram nome
marcado `(core-only)`.

## O que NÃO foi promovido, e por quê

`onion-adr-granaai-consolidation-2026-07.md`: o **nome do arquivo** identifica o cliente. Não se
neutraliza por texto — se o nome já responde a pergunta, o documento não sai do core. Está declarado
no README da categoria nova como critério, não como exceção.

## A categoria

`docs/knowledge-base/decisions/` com README que fixa três condições de entrada, e a terceira nasceu
desta medição: *não identifica ninguém*. O README cita os 32 como razão — quem for promover o próximo
ADR encontra a conta antes de mover.

## Verificação

Tudo por **ausência**, nunca pela forma que eu imaginava ter sobrado:

```
nomes nos 13 ADRs           : ZERO  (grep de id + razão social + caminho de máquina)
referências a analysis/<adr>: ZERO
links externos              : 82 abertos a partir da pasta de quem cita — 0 quebrados
links internos dos ADRs     : 25 abertos — 0 quebrados
contagem de KB              : 93 → 107 (snapshots de inbox/ e review/ preservados)
```

A busca por ausência achou **seis** ocorrências que a substituição deixou para trás — entre elas
`tornak` minúsculo, que meu par literal capitalizado não pegou. Sem ela, teriam ido para o bundle.

## Gate

```
lint (LC_ALL=C) : 0 HARD
plugin          : reassemblado (tree_sha em sincronia)
inventário      : idêntico ao gerador
commit          : SEM --no-verify
```
