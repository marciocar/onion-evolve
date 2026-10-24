---
branch: refactor/rule-55-kg-trace
pr: pendente
date: 2026-10-24
reviewed_diff_sha256: 2390c65137c31897c2e412a06d6b08bb5b0cac1b9ab26a0d2808574502a87b9a
reviewed_code_sha256: 33d200381fe7d4ad7497c3ee51d7a031657e62b3c11bedcbaad15e4fd746281f
findings_total: 9
findings_real: 4
tokens: 0
duration_min: 60
findings_fixed: 4
verdict: CORRIGIDO
elenxo: nao
reviewer: "agente de execução da sessão principal (claude-opus-5-5), passada própria sobre o próprio diff"
nota: "tokens não medidos pelo agente; o harness reporta o uso na notificação final"
---

# Passada adversarial: `refactor/rule-55-kg-trace`

## O que muda

- A REGRA 55 (O `trace:` de um nó APONTA para alvo que EXISTE) passa a ser julgada pelo `kg_trace.py check
  --external-root memory/` do vendor kg-ssot 4.25.0 (`kg-ssot.trace/1`).
- Novo `.claude/validation/kg-trace.sh`, sem parser próprio: traduz o JSON do produto para o TSV de 5 campos que o
  lint já consumia, mantém a guarda de vacuidade e é a **porta única** do índice de leitura (`--emit-index`).
- O resolvedor awk da casa (`kg-trace-resolve.sh`) **saiu do julgamento** e ficou **restrito ao índice**: qualquer
  modo que não seja `--emit-index` sai rc 2, e o `kg-trace.sh --emit-index` delega a ele. Motivo: o trace/1 da
  4.25.0 não traz os traces que resolvem, e a sessão do kg-ssot orientou não depender da API interna
  (`kg_trace.classify`). Gatilho: kg-ssot 4.25.1 adotada → nó `Q_INDICE_DE_LEITURA_PELO_KG_TRACE_4251`. A 1ª redação
  deste PR removeu o script e gerou o índice por `classify`; foi desfeita por essa orientação.
- Consumidores trocados para o `kg-trace.sh`: `lint-artifacts.sh` (REGRA 55 e REGRA 84 (Índice de leitura do KG em
  sincronia com os traces)), `.githooks/pre-commit`, `ops/pr-finalize.sh`, `.claude/utils/adopt/regen-ssot-projections.sh`,
  o comentário do `kg-read-leg.sh` e a aula 5 (`docs/applying/lesson-5-kg-forge.{md,html}` e os slides). Assim a
  troca da 4.25.1 é só dentro do `kg-trace.sh`. `grep -w kg-trace-resolve` restante fora de histórico: o próprio
  script, a delegação no `kg-trace.sh`, a bancada que o exercita e as lições citadas em comentários de
  `kg-seal-check.sh`, `consumed-mode-check.sh`, `injected-cut-check.sh`, `kg-fixture-paths.sh` e `lint-artifacts.sh`.
- Sem o produto (vendor < 4.25 próprio do alvo, python3 ausente), a REGRA 55 e a REGRA 84 dizem que **não julgaram**
  (SOFT `NAO-JULGOU`), nunca verde. python3 ausente segue HARD na REGRA 84, como antes.
- Grafo: `E_REGRA_55_PASSA_AO_KG_TRACE_1024` em `sinais-de-campo-2026-09`, SUPPORTS para
  `D_CANAL_CORE_KG_SSOT_FORMALIZADO_1023`, e `Q_INDICE_DE_LEITURA_PELO_KG_TRACE_4251` (DEPENDS_ON a evidência). Cinco `trace:` que apontavam o script aposentado foram reapontados ao
  sucessor (`kg-multi-graph-view-2026-09` ×3, `kg-read-leg-2026-08`, `onion-refinaria-2026-08`).

## Paridade medida (main `edcda44b`, antes da troca)

- Corpus: os dois julgam **2.501** traces e os 2.501 resolvem; 0 TARGET-MISSING. Os não julgados somam 2.551 nos
  dois, com baldes diferentes (casa: 1 absoluto, 2 externos, 2.548 não-caminho; produto: 1.684 absoluto/URL, 2
  externos, 865 não-caminho): o produto testa esquema de URL antes de cortar no `:`. Nenhum nó muda de julgado para
  não julgado.
- Fixture `trace-mixed`: o mesmo par de mortos (`C_MORTO_RAIZ`, `C_MORTO_REL`), TSV byte a byte igual.
- Índice (protótipo por `classify`, não adotado): 2.501 linhas nos dois; 6 diferem, todas **defeito da casa**, cura
  adiada à 4.25.1:
  - 5 ids entre aspas (`playbook-sdaal-2026-10`) entravam com as aspas, e o hook nunca casava aquele id;
  - 1 alvo resolvido pela pasta do grafo saía como `docs/onion/graph/../../knowledge-base/…`, forma que o caminho lido
    nunca tem.
- Nenhuma divergência é defeito do produto: nada a sinalizar ao kg-ssot.

## Achados

1. **REAL, curado** (a própria regra pegou, na 1ª redação): apagar o script deixou 5 nós com `trace:` nele, e a
   REGRA 55 nova os acusou como TARGET-MISSING. Reapontados ao `kg-trace.sh`, a porta única, que segue valendo quando
   o resolvedor sair na 4.25.1. Radar `--integrity --schema` rc 0 nos três grafos.
2. **REAL, adiado e preso**: a 3ª raiz (pasta pai do grafo) é julgada mas **não indexada** pelo resolvedor da casa:
   o adotante que organiza por vertical (`docs/<vertical>/graph/`) tem o hook de leitura cego para essas âncoras. O
   caso (j) prende o defeito (e o (g), o das aspas), para a troca da 4.25.1 inverter as asserções em vez de passar
   despercebida.
3. **Mudança de escopo, nomeada**: a isenção de fixture passa a ser a do produto (`FIXTURE_SEGMENTS`, carimbo do
   vendor, `docs/materials/`) em vez do `kg-fixture-paths.sh`, e `.kg.json` entra. No corpus do core não muda nó
   nenhum. O teste de consumidores do predicado (`kg_fixture_paths`, caso c) passou de 6 para 5 obrigatórios.
4. **Mutante equivalente, não defeito**: inverter o `case` do rc do produto não reprova a bancada, porque o JSON
   ilegível cai no segundo cinto (`ENTRADA-QUEBRADA` pelo parse) e o rc 1 segue.
5. **Limite**: a guarda de vacuidade decide "o corpus tem `trace:`" com um filtro de caminho próprio (substring
   `fixture`, `vendor/`, `docs/materials/`), mais largo que o do produto. Um corpus em que TODO grafo com trace tenha
   `fixture` no caminho escaparia da vacuidade; é o oposto do caso real, mas fica dito.

6. **REAL, curado** (aviso da sessão kg425, conferido no `spec/release.json`): o perfil `gate` do vendor leva
   `kg_validate`/`kg_gate` e não leva `kg_trace.py` nem `kg_query.py`. Um vendor com o `kg_trace.py` e sem o
   `kg_query.py` sairia ImportError (rc 1) e viraria HARD no adotante pelo vendor dele. O helper exige os três
   arquivos e sai rc 2 com o marcador, que o lint lê como `NAO-JULGOU`. Caso (k).
7. **Achado para o kg-ssot, procede** (resposta da sessão do kg-ssot): o JSON `kg-ssot.trace/1` só traz os
   `missing`, e gerar o índice pelo produto exigiria a API interna. Sai na 4.25.1 (os resolvidos, aditivos), junto com
   o perfil `gate` levando `kg_trace.py` e `kg_query.py` (achado 6). Por isso este PR não usa `classify`.
8. **Ramo sem uso, declarado**: o SOFT `NAO-JULGOU` da REGRA 84 (gerador = produto ausente) não dispara hoje, porque
   o `--emit-index` não depende do produto. Fica pronto para a 4.25.1, com o caso (d) da `kg_read_index_empty`.

9. **REAL, curado (o CI pegou, run 40108236900)**: o `regen-ssot-projections.sh` roda o gerador do ALVO, e a porta
   standalone se materializa de `origin/main`, que ainda não tem o `kg-trace.sh`: o índice não era gerado e o
   `materialize-door.sh` abortava (caso (f) da família `door`). O pré-voo do pr-finalize não rodou essa família. Cura:
   fallback para o `kg-trace-resolve.sh` do alvo, que tem o mesmo `--emit-index` (vale também para adotante num pin
   anterior). Família `door` 13/13.

## Mutantes (família `kg_trace_resolve`, 11/11)

Mortos (medidos na 1ª redação; os da REGRA 55 seguem iguais): guarda de vacuidade desligada (e), marcador `kg_trace.py ausente` trocado (h),
`--external-root memory/` tirado do check (b, d), exigência do `kg_query.py` tirada (k). O de índice da 3ª raiz
saiu junto com o índice por `classify`; o (j) agora prende o comportamento do resolvedor restrito, inclusive o rc 2. Produtos-stub: cego (lê zero, sai 0) → (e); quebrado (rc 2) → (i).

## Limites declarados

- Bancada rodada nas famílias `kg_trace_resolve`, `kg_fixture_paths`, `kg_read_leg`, `kg_trace_root_file` e
  `kg_read_index_empty`; a completa fica com o CI.
- Adotante com vendor kg-ssot próprio anterior à 4.25, ou no perfil `gate`, perde o veredito da REGRA 55 e da REGRA 84 (SOFT declarado)
  até subir o vendor.
