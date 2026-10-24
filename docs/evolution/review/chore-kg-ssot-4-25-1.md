---
branch: chore/kg-ssot-4-25-1
pr: pendente
date: 2026-10-24
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 1
tokens: 0
duration_min: 50
findings_fixed: 1
verdict: CORRIGIDO
elenxo: sim
reviewer: "agente de execução k4251a (passada própria)"
nota: "tokens não medidos (0): a sessão não expõe o custo do agente."
---

# Passada adversarial: `chore/kg-ssot-4-25-1`

## O que muda

- Vendor kg-ssot 4.25.0 → 4.25.1 (`kg-ssot-v4.25.1`, 8980b95e6ad7) pelo `kg_vendor.py update`; `ops/kg-gate-ci.sh` rc 0 sem `--update`.
- `kg-trace.sh --emit-index` gera o índice do `resolved_targets` do JSON `kg-ssot.trace/1` (`path·id·file`, ordem em bytes). Recusa em vez de esconder: produto ausente ou incompleto (rc 2, `kg_trace.py ausente`), JSON sem `resolved_targets`, que é a forma da 4.25.0 (rc 2, NAO-GEROU), rc do produto fora de 0 e 1 (rc 2, NAO-GEROU), zero resolvidos (rc 3, VAZIO).
- O hook `kg-read-leg.sh` tira a barra final do caminho consultado; o casamento continua por igualdade de campo.
- A REGRA 84 (Índice de leitura do KG em sincronia com os traces) lê os dois marcadores do rc 2 como NAO-JULGOU (SOFT).
- `kg-trace-resolve.sh` foi removido. Os nomes que sobram são lições datadas em comentários de guardas, o fallback do `regen-ssot-projections.sh` para o arquivo do ALVO num pin anterior a 2026-10-24, e o histórico.
- O índice tinha 2.504 linhas antes e 2.504 depois da troca (2.473 iguais e 31 curas: 26 diretórios, 5 ids sem aspas, 1 `../`). Fica com 2.506 depois dos dois nós novos do grafo.

## Achados

1. **Real, curado.** A REGRA 84 teria dado HARD a um adotante com vendor 4.25.0 e core novo. O ramo NAO-JULGOU só lia o marcador `kg_trace.py ausente`, e o JSON sem `resolved_targets` sai rc 2 com outro texto. O lint passou a ler também `resolved_targets` no stderr. Caso (j3) e mutante.
2. **Não procede.** Suspeita de `../` que o hook não cobre: o hook não normaliza `..`, e não precisa. O `path` vem resolvido relativo à raiz, e o caso (j) prende a ausência de `../` no índice.
3. **Não procede.** Hook lento ou fail-open: a mudança é um laço de shell sobre a string já extraída, sem processo novo; o caminho mudo (Bash sem `.kg.yaml`) continua sem python, e os casos (j)/(j2) da família kg_read_leg seguem verdes. O hook é aviso por desenho, sai 0 sempre.

## Mutantes

Os cinco morreram na bancada (famílias kg_trace_resolve e kg_read_leg):

- hook sem tirar a barra: morto por (l);
- gerador sem recusar o JSON da 4.25.0: morto por (j3);
- lint sem ler o marcador `resolved_targets`: morto por (j3), HARD em vez de SOFT;
- gerador emitindo `target` em vez de `path`: morto por (j) e (j2);
- índice vazio com rc 0: morto por (j4).

## Limites declarados

- Grafo ilegível fica fora do índice com um aviso no stderr. Quem o acusa é a REGRA 55 (O `trace:` de um nó APONTA para alvo que EXISTE), não a 84.
- O `regen-ssot-projections.sh` engole o rc do gerador (`|| true`): num alvo com vendor 4.25.0 o índice não é regenerado e o velho fica. A REGRA 84 do alvo diz NAO-JULGOU.
- `memory/` segue fora do índice, como antes.
