---
title: "Revisão — desacoplar a fonte privada: a face pública vira costura única e catraca (REGRA 79)"
date: 2026-09-07
branch: feat/plugins-en-compliance
reviewer: "Elenxo adversarial com mandato de REFUTAR (worker `elenxo-desacoplar`, veredito APROVADO-COM-RESSALVA) + re-medição independente do condutor contra o vivo (DNS/SMTP, clone público, `claude plugin validate --strict` 2.1.263); gate no SHA final: lint 0 HARD rc=0 · bancada 1101/0 rc=0 · kg-trace-resolve 1737/1737"
reviewed_diff_sha256: 6263a10adc7ce4b8841ccf5673ea6d1eab0f7a5fd1bdb7425549cd4c4b631d3a
findings_total: 8
findings_real: 7
verdict: APROVADO-COM-RESSALVA
tokens: 900000
duration_min: 55
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Achados

1. **A objeção que sobreviveu é sobre o ACEITE, não sobre a decisão.** Issues habilitadas são um
   *canal*; o requisito 3.B pede *contato verificado*. O critério do PR 10 não pode ser "3.B
   resolvido" — tem de ser "o 404 saiu de toda superfície pública **e** o suporte aponta para repo
   público com issues". Preservado em `E_ELENXO_DESACOPLAR_APROVADO_COM_RESSALVA`.
2. **Três ataques mecânicos do refutador CAÍRAM, medidos** — `claude plugin validate --strict`
   aceita o split (`Validation passed`, rc=0, em cópia real do `onion-compliance`); nenhum
   consumidor resolve a URL de `provenance.repository` (`lint-artifacts.sh:1216,1221-1222` a exclui
   do diff; `materialize-marketplace-repo.sh:135` a usa como marcador de existência); sem
   contradição com a REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) nem com
   `install≠adopt`.
3. **O resíduo que a própria tese criava por construção** — `plugin-readme.sh:132` derivava
   `Fonte: https://github.com/…` de `provenance.repository`, não do `plugin.json`: manter o
   provenance privado mantinha **5 hyperlinks 404 já publicados** no clone vivo. É o achado que
   mudou o desenho da cura (separar os três papéis, não só trocar dois campos).
4. **Diagnóstico do resíduo (5) corrigido pela leitura do conteúdo** — o revisor contou 50
   ocorrências de `onion-evolve` no clone público e as tratou como resíduo. Lidas uma a uma, **10
   das 12 menções em prosa são o IDENTIFICADOR do core** (`role: source`, `can_correct_to`,
   mapeamento de papel); apagá-las quebraria a semântica do `members.yaml`. Só 2 eram caminho
   navegável para o repo privado (`co-evolve.md:17` e `:131`) — essas foram curadas. É o único
   achado do revisor que **não** se sustentou como formulado.
5. **A precondição da decisão do maestro caiu na medição** — `suporte@onionevolve.com` era
   indeliverável pelos dois caminhos da RFC 5321 (zero MX em dois resolvers; 25 e 587 recusando no
   fallback do A record). Achado do condutor, não do revisor. Curado no mesmo dia pelo maestro
   (MX/SPF/DMARC da Hostinger no ar, medidos), com o passo (3) do aceite — envio real chegando —
   ainda aberto em `Q_MX_DO_ONIONEVOLVE`.
6. **HARD pré-existente encontrado e curado de passagem** — `D_PR06_FLIP_PARA_EN` traçava para
   `.claude/utils/marketplace/lang.conf`, arquivo que só o PR 5 vai criar; vinha assim desde o
   commit do plano. Repontado para `generate-marketplace.sh`; `lang.conf` segue nomeado no label.
7. **Divergência não prevista** — o `.claude-plugin/marketplace.json` do core se chamava
   `onion-evolve` enquanto o repo público já se chama `onion-plugins`. Alinhado.
8. **A guarda foi testada no modo-de-falha, não só no happy-path** — a REGRA 79 (Artefato de plugin
   não publica o repo-fonte PRIVADO como endereço) rodou contra a árvore **defeituosa** e acusou 11
   violações nos sítios reais; contra a curada, zero — com os 5 `provenance.json` ainda carregando o
   slug, o que prova a isenção no mesmo run. Mais 3 casos de bancada (home crua → HARD ·
   `provenance.json` → limpo · URL pública → limpo).

## Nota sobre o re-carimbo do SHA

O primeiro carimbo (`03213ff3…`) **caducou no próprio commit**: o pre-commit regenera os plugins
bundlados por conta própria, e isso mudou o diff DEPOIS de eu o hashear. O gate acusou
`ARTEFATO-CADUCO` — corretamente. Antes de re-carimbar, medi o delta entre o diff revisado e o
final; ele é **inteiramente mecânico**, sem uma linha de conteúdo novo:

- 4 `provenance.json` com `ref`/`commit_date` re-churnados pelo gerador (campos voláteis que o
  `lint-artifacts.sh:1216` já exclui do diff de drift);
- `plugins/onion/` com a versão derivada `0.1.236 → 0.1.237` — a versão anda porque o conteúdo
  andou (`co-evolve.md`), que é exatamente o comportamento pretendido.

A lição fica: **o SHA do resíduo nasce do estado FINAL commitado**, não do índice pré-hook, quando
o hook é ele próprio um gerador.

**Segundo re-carimbo (`1a7dc920…` → `6263a10a…`), e a fricção que ele expõe.** O commit que fecha
`Q_RESIDUOS_DA_FONTE_PRIVADA_NO_PUBLICO` no grafo mudou o diff outra vez, e a REGRA 56 barrou —
corretamente, porque ela não sabe distinguir "o código mudou" de "o registro do fecho mudou". Como
`docs/evolution/review/` é excluído do hash, a saída é carimbar o SHA do ÍNDICE **no mesmo commit**
que carrega a mudança. Delta desta vez: apenas `docs/backlog.md` (projeção regenerada) e o `status`
+ `label` do nó fechado no `.kg.yaml`. Nenhuma linha de código.

Fica registrado como fricção conhecida, não como defeito a consertar aqui: todo commit pós-revisão
num PR aberto — inclusive um que só carimba grafo — exige re-carimbo, e o caminho certo é sempre
recomputar o SHA do índice antes de commitar, nunca `--no-verify`.

## Fora de escopo
- `Q_SITE_SEM_PORTA_EN_E_SEM_CONTATO` — `onionevolve.com/en/` dá 404 e o site não tem página de
  contato. Nó aberto, `CONSTRAINS` o PR 10; promover a `DEPENDS_ON` é chamada do maestro.
- O e-mail em `author.email` — só entra depois do passo (3) de `Q_MX_DO_ONIONEVOLVE`.
- As 3 reprovações de `claude plugin validate --strict` são o `D_PR01_STRICT_LIMPO`
  (`commands/README.md` sem frontmatter), nó pronto e separado.
- `docs/knowledge-base/tools/vps-tool-repo-skeleton.md:317` carrega um caminho absoluto da máquina
  do maestro (`/home/marcio/onion-evolve/ops/…`) numa KB que o `/meta:adopt` vendoriza. Não viaja
  no plugin, então está fora deste nó — mas é fio próprio.
