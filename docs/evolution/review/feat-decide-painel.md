---
branch: feat/decide-painel
pr: pendente
date: 2026-10-21
reviewed_diff_sha256: pendente
findings_total: 8
findings_real: 6
tokens: 118601
duration_min: 4
findings_fixed: 6
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente refutador general-purpose (passada única sobre o diff de 818558d9 e o WIP), autor curou e provou por mutante
nota: "tokens e duração são os do refutador; 2 suspeitas sem defeito provado viraram casos de bancada (raiz e ref repetido)"
---

# Passada adversarial: `feat/decide-painel`

## O que muda

O `/meta:decide` ganha o modo opcional `--painel` (plano `A_ABSORB_DECIDE_PAINEL_INTERATIVO`, decisão
`D_INTELLIGENT_UI_1021` opção B). Peças forjadas pelo `/meta:forge`: a cláusula 9 da doutrina, o
`decide-panel.sh` (round emite o painel e o payload do AskUserQuestion da mesma rodada; seal chama só o
`kg-decide-seal.sh`), a página `decide-panel.html` e os casos pn1 a pn4 em `run_decide_selftests`.

## Achados

1. **Média, curado.** No HEAD `today` ficava fora do `round_id`: a data do selo podia ser trocada no round
   e resposta de outro dia valia. Cura: data no hash. Caso pn4 (`r-data`), mutante M8.
2. **Média, curado.** Mesma composição no mesmo dia gerava o mesmo `round_id`, e `answers/` nunca era
   limpa: resposta velha valia para a rodada nova. Cura: nonce da emissão no hash e o passo 2 do
   comando apaga `answers` e `status` a cada rodada. Caso pn4 (reemissão), mutante M7.
3. **Média, curado.** A página não zerava as escolhas quando a rodada mudava; como os rótulos de ato se
   repetem, uma escolha antiga valeria para outro ato. Cura: `picks` e `sent` zerados quando o
   `round_id` muda. Lido no código, não rodado (a página não roda na bancada).
4. **Média, curado antes do fim da passada.** O estado não levava `round_id`, e a página não o mostraria.
   Cura: cada item leva o `round_id`. Caso pn4, mutante M12.
5. **Baixa, curado.** O `round_id` é hash, não assinatura: um round editado com o hash recalculado
   passava, e `node="--new"` virava flag do selador. Cura: o seal revalida o nó (`[A-Z][A-Z0-9_]*`) e a
   raiz do grafo, e a doutrina diz que o hash detecta edição não recalculada. Casos pn4 (`r-flag`,
   `r-fora`), mutantes M9 e M10.
6. **Baixa, curado.** A doutrina chamava resposta de outra rodada de "ambígua"; o código grava
   "recusada". A doutrina foi alinhada ao código.

Suspeitas sem defeito provado, que viraram caso: grafo fora da raiz (M10) e ref repetido na composição
(M11). A forma exata do que o ArtifactData grava em `out_dir` não foi medida (declarado).

## Mutantes

Doze, via `ops/mutate-and-restore.sh`, cada um reprovando o caso dele com a família verde sem ele:
M1 ask invertido e M2 recomendada fora do 1º lugar (pn1); M3 escrita direta no grafo (pn2 e pn3);
M4 checagem de opção removida, M5 `--other` ignorado e M6 subprocess por shell (pn3; M6 também pn2);
M7 nonce fixo, M8 data fixa no hash do seal, M9 regex do nó removida, M10 raiz não conferida,
M11 ref repetido aceito e M12 estado sem `round_id` (pn4). Restauração conferida por hash.

## Os `confirmed` do grafo editado (REGRA 87 (PR que EDITA um `.kg.yaml` enxergou os `confirmed` dele))

O PR muda só o nó do plano `A_ABSORB_DECIDE_PAINEL_INTERATIVO` (open → confirmed, com a bancada como
proveniência). Conferidos os `confirmed` de maior impacto, nenhum o refuta:
- `E_OBJECAO_01_GPT6_PREMISE_UNANCHORED` e `E_LACUNAS_PRIMARIES_1021`: a UI do GPT-6 segue sem âncora. O
  PR não depende dela: costura o mecanismo aberto do MCP Apps, e nenhuma peça usa o nome ou a marca.
- `E_OBJECAO_16_MARKET_CAPITAL_AXIS_EMPTY`: o eixo de mercado segue vazio; o PR não afirma nada de mercado.
- `E_OBJECAO_04_DECIDE_CARDS_NOT_PROVEN` (o terminal não é host MCP Apps): é a razão do desenho. O painel
  roda no Artifact do Claude Code, não no MCP Apps, e a parte que ele não mede (a página publicada) está
  declarada como não medida na narrativa do nó.

## Limites declarados

- Nenhum Artifact real foi publicado: a página e a leitura pelo ArtifactData não rodam na bancada. O
  envelope do documento lido é aceito nas duas formas conhecidas (nu e `{"data": …}`), sem medição viva.
- O painel não sela decisão sem nó (`--new`) nem checkpoint do `/meta:drive`: esses seguem no terminal.
- A ambiguidade do texto livre é julgamento da sessão (o `--other qN` só depois de ler); o helper só
  garante que texto livre nunca sela sozinho.
- Sem a ferramenta Artifact na sessão, o modo degrada declarando e pergunta no terminal; isso é regra da
  superfície, não mecanismo medido.
