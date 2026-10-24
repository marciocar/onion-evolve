---
branch: feat/canonical-names-core-layer
pr: pendente
date: 2026-10-24
reviewed_diff_sha256: c0d09ff7d25e40423e9e5a4e36e00a2a4fbd45340137044a8b53dcdf4dc42488
reviewed_code_sha256: 14ba8b7d8a720cde7f1b9fd0a352e2d1fbd592ddde8d056e6be91304ffaebc0c
findings_total: 8
findings_real: 7
findings_fixed: 7
tokens: 170036
duration_min: 23
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "refutador independente (ferramenta Agent, subagent_type general-purpose, mandato REFUTAR; 56 chamadas de ferramenta, cópia própria em /tmp)"
nota: "tokens e duração são do refutador (medidos pela ferramenta); os da sessão condutora vão no relatório do PR. O achado 8 veio do CI depois da passada e foi re-revisado pela sessão condutora (mudança mecânica da bancada, sem código de produção)"
---

# Passada adversarial: `feat/canonical-names-core-layer`

## Achados

1. **BLOQUEAVA — a reincidência do hook parou de barrar a rodada seguinte do radar** (curado). O estado do
   lembrete guarda `(token, linha, kind)`, e a linha do termo passou a ser o ESQUEMA (`radar-cc`). Lembrado r12
   (que é termo), o r18 da rodada nova e o r20 da bancada caem na linha genérica `r\d{1,3}` e não casavam mais:
   o Stop deixava passar justo o código mais provável depois do merge. Medido pelo refutador: `OLD r18 rc=2 ·
   NEW r18 rc=0`. **Cura:** `_family_row()` — a reincidência do termo guarda a FAMÍLIA (a linha static que casa
   o código) e só na falta dela o esquema. Caso novo `(vf)` com as duas polaridades (r18 barra, N2 de outra
   família não barra); o mutante que devolve o esquema mata 2 casos.
2. **Hook e lint discordavam no sentido** (curado). Só três dos seis esquemas tinham linha `scheme`, então
   r7–r13 saíam no hook como "rodada do radar" com opacidade alta enquanto o lint os chamava de ambíguos.
   **Cura:** os seis esquemas declarados (`bench-case`, `refutation-finding`, `selfconsistency-claim` entraram),
   o hook passou a enxergar a colisão igual ao lint.
3. **Regressão nas glosas de nível do dissect** (curado). As linhas static de N0–N4 aceitavam as palavras do
   nível (mecanismo, transfer, absor, identidade, capacidade); a linha `scheme dissect` só aceitava "dissec", e
   frases antes glosadas passaram a ser acusadas com opacidade alta. **Cura:** o accept do esquema recuperou as
   palavras. Efeito colateral medido e curado no mesmo movimento: com N1–N10 como termos, o N8 virou "código
   conhecido" e matava a regra de rótulo LOCAL (caso `(d)` da bancada caiu) — agora o termo só conta como
   conhecido se o domínio do esquema dele estiver no bloco.
4. **Alargar as externas desligava o lint sem alarme** (curado). A base não registrava com quais externas foi
   gravada; uma linha `tudo [A-Za-z]{1,3}[0-9]{1,3}[a-z]?` mandava os 2194 códigos para "externos" e deixava
   rc 0 com zero achado. **Cura dupla:** (a) `.kg-ssot/vocab-externals.sha256` — a TSV mudar sem a base ser
   regravada sai rc 2; (b) SONDA: toda externa é provada contra códigos da casa (r13, N2, A7, F2, D10, E3, I3,
   NS1, Q7, S9) e, se casar algum, sai rc 2 nos DOIS modos, inclusive no `--update` (medido: a linha larga do
   refutador agora sai rc 2 nas duas invocações).
5. **Mutantes vivos na bancada** (curados). Quatro ramos fail-closed do `ops/kg-vocab-ci.sh` e dois do
   `house_codes.py` sobreviviam. **Cura:** caso `(i)` com um `kg_vocab.py` DE MENTIRA (rc acima de 1, JSON de
   outra forma, rc discordando do JSON, base não lida), caso `(j)` de grafo ilegível e os casos `(v11)`/`(v12)`
   do hook. Mortos agora: 6 de 7 mutantes do script e 4 de 4 do hook.
6. **A mensagem final mentia sobre grafo ilegível** (curado): dizia "código novo sem termo" quando o que
   reprovava era um grafo que ninguém conseguiu ler. Agora o veredito nomeia a ilegibilidade (caso `(j)`).
7. **O filtro do gerador não via a chave citada nem `.kg.json`** (curado). `git grep '^\s*x_term:'` perdia
   `"x_term":`; a bancada `(d)` (filtro × `--root`) pegava, a catraca da REGRA 62 (Projeção GERADA em sincronia
   com a fonte (docs/backlog.md)) não. **Cura:** o filtro passou a `-lE '^[[:space:]]*"?x_term"?[[:space:]]*:'`
   e a varredura inclui `*.kg.json`.

8. **O CI achou o que a passada não viu: as famílias novas mandavam a seleção da bancada para o failsafe**
   (curado, re-revisado pela sessão condutora). O `selftest_selection` reprovou a faixa 4: a seleção de
   famílias por bloco lê a fronteira pelo `}` na coluna 0, e as duas famílias novas tinham strings
   multilinha com linhas na coluna 0 (python de `-c` e YAML montado entre aspas). Bissecção medida: cada
   família, sozinha, mandava o seletor para "tudo"; sem as duas, a seleção é a da `origin/main`.
   **Cura:** as strings viraram linha única (`$'...\n'` e python de uma linha). **Re-revisão:** a mudança só
   toca a bancada (nenhum código de produção), a seleção do caso (c1) volta a ser igual à da `origin/main`,
   e as famílias seguem verdes com o `selftest_selection` (60/60).

## Tetos declarados (não curados por desenho)

- **Sentido errado com nome único resolve calado.** A resolução do vendor é por notation: "o caso r14 da
  bancada" resolve como rodada do radar enquanto a bancada não tiver o termo r14. O lint pega o código SEM nome
  e o AMBÍGUO, não o sentido errado com nome único. Escrito na `note` do grafo e no cabeçalho do
  `ops/kg-vocab-ci.sh`; a segunda rede é o hook, onde o DOMÍNIO do bloco decide. A cura é nomear o sentido que
  falta, e o lint cobra isso do código NOVO.
- **O ramo `rc ≥ 2` do lint não é observável sozinho** (mutante mascarado): com o guarda desligado, a
  discordância entre o rc do vendor e o do JSON pega o mesmo caso. É redundância deliberada; o mutante que a
  remove morre pelo outro guarda.
- **Catraca por CONTAGEM tem a folga de toda catraca por contagem:** legado corrigido não aperta a base
  sozinho. Apertar é ato de quem regrava (`--update`), e agora a TSV das externas tem carimbo próprio.
- **Prefixo de esquema digitado errado (`radar-c:r13`) cala no hook** pela heurística de caminho. Já era assim
  na `origin/main`; não é regressão, e a forma qualificada certa glosa.

## Fora de escopo

- FASE 3 (o selador e a forja exigindo nome e esquema): fica para depois, por ordem do pedido.
- Nomear o sentido que falta para cada código do legado (2148 achados na base): a catraca existe para que isso
  aconteça por uso, não numa varredura.

## O que o refutador tentou e NÃO conseguiu refutar

- As definições contra o corpus: r1–r17 batem com os 17 diretórios `radar-E3-*` (r1 = 09-02, r3 = "Rodada 3" em
  09-04, r4 = `-09-04-r4`); os rN de `door-role-parity-2026-09` são casos de bancada; os N1–N10 de
  `a2a-configurator-2026-10` são achados da passada de refutação; os N1–N5 de `typesafe-ai-2026-09` são as
  afirmações do teste de autoconsistência; N0–N4 conferem com `.claude/commands/meta/dissect.md`.
- A catraca do lint: pega r18 novo (unresolved), +1 r9 do legado (ambiguous) e `bench-case:r14` qualificado sem
  termo; o reclassificado fica restrito ao legado.
- O drift do gerador (mudar o `pref` de r13 no grafo faz o `--markdown` divergir do TSV) e o fail-closed do
  `_gen_into` quando o gerador quebra.
- A ordem dos códigos de saída no `ops/kg-gate-ci.sh` (o 2 vence) e o hook não chamar o vendor
  (`grep kg_vocab|vendor/` no hook = zero; carga do glossário medida em 0,29 ms, 48 linhas).
