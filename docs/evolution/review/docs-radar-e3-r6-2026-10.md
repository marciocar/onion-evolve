---
reviewed_diff_sha256: d0a05b8d698c4b245ecaad7f782bed49b99d2c0a0fde27690796f6850c86ffe4
findings_total: 6
findings_real: 6
tokens: 122349
duration_min: 6
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Juiz opus/high em worktree isolada, mandato REFUTAR, abriu a fonte (HTTP 200, 4.071.840 bytes,
  19.245 linhas, 154 cabeçalhos de versão) E mediu o repo. Reprovou 5 dos 6 achados da 1ª passada
  e, além deles, reprovou a ISENÇÃO DE ESCOPO estruturalmente — provou colhendo um item da
  2.1.286, de dentro da janela que eu declarava coberta pelo corpus. REPROVADO_E_CURADO porque os
  seis achados foram re-medidos bloco a bloco contra `data/2.1.28*.txt` (atribuição conferida uma
  por uma: o `Added` do opus-5-5 mora na 2.1.280 l.2, as menções na 287/288 são Fixed/Changed) e
  porque a causa-raiz ganhou cura MECÂNICA nesta mesma leva — o `kg-corpus-grep` passou a imprimir
  `imp=` e `conf=` junto de `tier=`, para a isenção falhar na LEITURA em vez de falhar no juiz.
---

# Resíduo adversarial — `docs/radar-e3-r6-2026-10`

**Data:** 2026-10-03 · **Eixo:** E3-claude-code-delta (rodada 6) · **Juiz:** opus/high, mandato
REFUTAR, worktree isolada, abriu a fonte (HTTP 200, 4.071.840 bytes, 19.245 linhas, 154
cabeçalhos de versão)

## Placar: 1 aprovado · 5 reprovados · 1 lacuna genuína

Mais a **isenção de escopo reprovada estruturalmente** — e esta é a reprovação que importa, porque
não era um achado errado, era o **desenho da rodada** errado.

| # | Achado da 1ª passada | Veredito | Por quê |
|---|---|---|---|
| A1 | "2.1.279 e 2.1.280 não aparecem no changelog" | **REPROVADO pela metade** | a `2.1.280` **existe**, com 114 itens — e traz `claude-opus-5-5` como Opus default, o item de maior consequência do delta. A metade falsa era a que escondia o achado |
| A2 | item atribuído à 2.1.287 | **REPROVADO** | versão errada |
| A3 | "as guardas `PreToolUse` barram commit em main" | **REPROVADO** | inflação: elas vetam **force-push e merge**; o commit é barrado pelo `.githooks/pre-commit`, mecanismo diferente — e o corpus **já media isso** (`E_CURA_MERGE_GATE_2O_VETO`) |
| A4 | skill `verify` na 2.1.287; "o gate do Onion é exatamente um verify" | **REPROVADO 2×** | é **2.1.286**, de dentro da janela que eu declarei coberta; e a equivalência era **analogia minha** apresentada como medição |
| A5 | Claude Mods + "You should know" (2.1.287) | **APROVADO** | as três citações verbatim, versão correta |
| A6 | item atribuído a versão errada | **REPROVADO** | atribuição |
| — | `2.1.279` ausente | **LACUNA GENUÍNA** | não existe na fonte; desfecho de 1ª classe, não finding |

## As três coisas que esta passada ensinou, e nenhuma é sobre o Claude Code

1. **A terceira morada da fabricação é a ATRIBUIÇÃO DE VERSÃO.** Quatro dos cinco reprovados
   tinham o **texto certo na versão errada** — citação verbatim impecável ancorada num `<Update>`
   que não a contém. Conferir a citação e conferir **em que versão ela mora** são **dois atos**, e
   eu fiz só o primeiro. A série: r4 = fonte externa · r5 = medição do repo · **r6 = atribuição**.
2. **O corpus virou instrumento de isenção.** Na r5 o defeito foi *pular* o `kg-corpus-grep`;
   nesta foi **invocá-lo e usar a saída para não medir**. Li `id` e `tier=9` de três nós e declarei
   seis versões cobertas; o que eu não li estava nos mesmos nós — dois com `impact: 2`, um com
   `confidence: 0,4` e auto-rótulo *"informação próxima de zero e não deve inflar a cobertura"*.
   **Tier alto é qualidade da FONTE, nunca extensão da COBERTURA.**
   → **Cura mecânica aplicada nesta leva** (proposta pelo próprio juiz): `kg-corpus-grep` imprime
   `imp=` e `conf=` ao lado de `tier=`. A isenção agora falha na **leitura**, não no juiz.
3. **O alvo da reconciliação também se fabrica.** A 1ª redação do `meta:` declarava
   `supersedes_external` para `radar-E3-2026-09-21-r5#E_CC_VERSION_DA_RODADA` — **nó que não
   existe** (o r5 tem 15 nós, nenhum com esse id). Mesma espécie da atribuição errada: forma
   impecável sobre referente inexistente. Só `grep '^  - id:'` no grafo alvo revela.

## O instrumento reprovado

`WebFetch` sobre a página de changelog (4.071.883 bytes) **resume, trunca e inventa atribuição** —
medido duas vezes, com saídas divergentes entre si: datou a `2.1.281` como "October 1" (é 23/09,
ordem impossível porque a `2.1.286` é de 30/09) e copiou a lista `Changed` dela para a `2.1.286`.
Método certo, e é o que `data/` guarda: **âncora `id="2-1-NNN"` no HTML cru**, um bloco por versão.

## O que fica PROPOSTO ao maestro (flip é humano)

`D_SESSION_MODELS_PRECISA_DO_OPUS_5_5` — `claude-opus-5-5` (Opus default desde a 2.1.280) e
`claude-sonnet-5-5` (Sonnet default da API desde a 2.1.284) **não estão** no `session_models`, e a
`premodelswitch-guard.sh` nega o que não está na lista. ⚠️ **O número vem do eixo E6**, que tem
`last_run` próprio e **não foi rodado aqui** — editar o lineup por esta rodada seria o
carimbo-sem-medição.

## Teto declarado

A **alcançabilidade** da condição corrigida na 2.1.288 nas duas guardas `PreToolUse` da casa **não
foi medida**. Ambas desserializam `tool_input` e portanto pertencem à classe corrigida, mas o
matcher literal `Bash` torna "matching failed" implausível para elas — o candidato real é matcher
**regex**. Isto está no grafo como **inferência declarada**, não como medição.
