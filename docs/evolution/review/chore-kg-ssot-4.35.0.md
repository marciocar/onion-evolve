---
branch: chore/kg-ssot-4.35.0
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 8
findings_real: 8
tokens: 95974
duration_min: 4
findings_fixed: 8
verdict: CORRIGIDO
elenxo: sim
reviewer: "subagente revisor novo (code-reviewer), sem a conclusão da sessão de adoção, sobre o diff inteiro contra a origin/main"
nota: "o revisor leu o kg_trace.py e os schemas do vendor como fonte da verdade do JSON, rodou o kg-projection.sh e o kg-trace.sh no core real e mediu o mutante m4 e a vacuidade numa pasta sem git; tokens e duração são os do subagente"
---

# Passada adversarial: `chore/kg-ssot-4.35.0`

## O que muda

A adoção da kg-ssot 4.35.0 (contrato v4.16 sem mudança), com quatro frentes: o `--with` no `--chain`, o piso do
Python em 3.12, o `kg_trace.py projection` e o locator em JSON Pointer no `kg_trace check`. No core:

- a REGRA 112 (Página com projection_of cita ids que existem nos grafos dela), pelo `kg-projection.sh`;
- o `kg-trace.sh` traduz o `locators` do JSON, e a REGRA 55 (O `trace:` de um nó APONTA para alvo que EXISTE) o acusa;
- o `design-context-check.py` delega a parte genérica do locator e fica com o `$value` e a regra do brief;
- o template de CI que viaja sobe o piso para 3.12;
- o brief piloto do design lista os dois grafos que projeta;
- o nó `E_KG_SSOT_435_ADOTADA_1027` e as pendências fechadas no grafo de coordenação.

## Achados (8 reais, 8 corrigidos)

1. **O mutante m4 do `kg-trace.sh` dava erro de sintaxe** (alta). O `grep -v` apagava o único corpo do `for`, o Python
   do heredoc dava `IndentationError` e o caso caía no ramo do JSON ilegível, não na guarda do rc 1; o m5 herdava o
   erro e o caso reprovava. Cura: o `print` vira `pass` com a mesma indentação, e o caso exige a mensagem do ramo novo
   (`rc=1 sem achado`) e nenhum `Error` na saída.
2. **Delegação incondicional do locator** (média, fail-open). Com o `.claude/` novo e o vendor entre 4.25 e 4.34, o
   token que some do JSON não era acusado por ninguém. Cura: o `.sh` passa `--delegate-locator` só quando o
   `kg_trace.py` que a REGRA 55 usa tem `integrity.trace-locator-missing`; sem ele a vertical segue acusando. Caso (q).
3. **"A fonte fora da raiz é dele" era falso** (baixa-média). O produto só conta `outside_root` e `absolute`. Cura: o
   `LOCATOR-FORA-DA-RAIZ` volta a valer para `.json`, e a docstring diz o que o produto faz.
4. **Vacuidade no `kg-projection.sh`** (média, fail-open). Numa pasta sem git, ou com a página não rastreada, o produto
   julgava 0 páginas e o helper saía rc 0. Cura: descoberta própria no disco; raiz fora do git com página dá rc 2, e
   o produto que julga 0 com página no disco dá rc 2. Caso (h) e mutante m4 da família.
5. **Aviso eterno no adotante sem projeção** (baixa). Sem vendor 4.35 e sem página com `projection_of`, a REGRA 112
   dava SOFT "não rodou" a cada lint. Cura: sem página no disco, rc 0 sem chamar o produto. Caso (h).
6. **Severidade incoerente entre papéis** (baixa). Cura: no derivado, a REGRA 112 sai SOFT no 1º ciclo, como a REGRA
   111 e o locator da REGRA 55.
7. **Mensagem enganosa na REGRA 55** (baixa). O produto dá `LOCATOR_MISSING` também quando o arquivo da fonte sumiu.
   Cura: a mensagem distingue a chave que saiu do JSON do arquivo que não existe.
8. **BOM no arquivo de tokens desligava o `LOCATOR-GRUPO`** (baixa). Cura: `utf-8-sig`, como o produto lê. Caso (q)
   com BOM.

## Conferido e sem defeito

- As chaves que o código lê batem com `spec/projection.schema.json`, `spec/trace.schema.json` e o `kg_trace.py`.
- `set -uo pipefail` sem armadilha no `kg-projection.sh`; o rc 2 do argparse no vendor antigo vira rc 2.
- Os sed dos mutantes m1, m2 e m3 da família `kg_projection` casam e geram Python válido.
- O piso 3.12 do template e o caso (d) de `kg_ssot_require_hashes`.
- O `brief.md` com o `projection_of` em lista: 3 de 3 ids resolvem.

## Limites declarados

- Página nova não rastreada, num repo que já tem outras rastreadas, não é julgada pela REGRA 112 (o produto lê o
  índice do git; o pre-commit e o CI a veem depois do `git add`).
- A fonte `.tokens` sem `.json` continua só na vertical: o produto não a lê.
