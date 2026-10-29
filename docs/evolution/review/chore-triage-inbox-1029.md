---
branch: chore/triage-inbox-1029
pr: pendente
date: 2026-10-29
reviewed_diff_sha256: 0525c4b69d411e808891235f59b509d6ceed60e3cfc333e427548890245fcd99
reviewed_code_sha256: ca29c9e703ab4e8092beaf08db21bfbecf01c2bd158fd4e47f9f3b586f3e7626
findings_total: 10
findings_real: 10
tokens: 138681
duration_min: 4
findings_fixed: 9
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente separado, só leitura (general-purpose), sobre o diff da branch; 2ª passada sobre o delta depois das curas
nota: "o achado 2 (sinal do documento controlado na raiz do inbox) fica por instrução da sessão principal: aguarda três decisões do maestro"
---

# Passada adversarial: `chore/triage-inbox-1029`

## O que muda

- Triagem de sete sinais de 2026-10-29. A guarda do carteiro, os atritos de worktree, o build-business-docs
  e os nomes antigos de business-context vão para `_processed/`. Os dois do Esperanto e o do documento
  controlado ficam no inbox, à espera do maestro.
- Curas: o `/docs:build-business-docs` ganha o carimbo da REGRA 15 (Frescor de contexto de domínio: carimbo
  de atualização), o `/meta:inventory` da REGRA 8 (Inventário canônico sincronizado com o filesystem), a
  rota da Fase 1.2 para o `onion-research` e a marca `[DECISÃO PENDENTE]`. A doutrina client-material ganha
  o `.gitignore` sem barra, o material no checkout principal e o `--root` em worktree. O `kg-trace.sh` lê o
  `.kg-ssot/trace-external-roots.txt`, com o caso (j) na bancada. Seis consumidores de business-context
  passam aos nomes que o build gera.
- Os nós: três do maestro no grafo de coordenação, que chega a 40, o teto; seis no sinais-de-campo.

## Achados (1ª passada) e o que foi feito

1. **Real.** O nó `Q_COORD_CORE_ESPERANTO_VEREDITOS` ficaria falso depois do merge: dizia que o sinal não
   estava na main e citava o "estacionar". **Curado:** o nó aponta as duas versões, e a 2ª, que é a
   resposta do maestro, substitui a 1ª.
2. **Menor.** O sinal do documento controlado fica na raiz do inbox, com frontmatter incompleto. **Não
   curado, por instrução:** ele aguarda três decisões do maestro. O frontmatter é do remetente.
3. **Menor.** A exclusão do carimbo divergia: o comando citava `index.md` e `README.md`, mas o template e o
   QA citavam só `index.md`. **Curado** nos três pontos.
4. **Menor.** O prefixo de raiz externa casa o texto do trace literalmente. **Curado:** o bloco «Ext.» do
   `kg-trace.sh` declara isso, pede a barra final e diz que a isenção vale onde o material existe.
5. **Menor.** Dois arquivos do outbox processados diziam "a transportar", e um deles descrevia a
   infraestrutura compartilhada. **Curado:** o status passou a "entregue", e o trecho foi retido com um
   marcador.
6. **Menor.** A REGRA 55 era citada sem título no texto novo. **Curado** com o título canônico.
7. **Menor.** Faltava cobertura da linha indentada. **Curado:** a linha do `tj2` agora é indentada.
8. **Menor.** O `--root` vale para todos os traces do grafo. **Curado:** a doutrina avisa isso.

## Medido

- A família `kg_trace_root_file` passou 10 de 10, e o mutante sem a cura reprova o caso (j).
- O radar `--integrity --schema` saiu rc 0 nos dois grafos.
- O `kg-contract-check` saiu rc 0 nos dois grafos.
- O `ops/kg-gate-ci.sh` saiu rc 0.

## Achados (2ª passada, sobre o delta) e o que foi feito

O mapeamento dos 10 nomes confere com a árvore do comando. O grep pelos nomes em caixa alta em `.claude/` deu
zero. Fora de `.claude/`, os 3 casamentos são ids de nó (`E_VOICE_OF_CUSTOMER_P6…`, `E_CORE_COMPETITIVE_LANDSCAPE_DRIFT`),
não caminhos, e ficam como registro.

9. **Menor.** A nota nova do `analyze-pain-price` mandava rodar o `resolve-context-dir.sh`, que o allowed-tools
   (Read Glob) não permite. **Curado:** a nota aponta a declaração e o `Glob`.
10. **Menor, anterior a este PR.** O template ensinava nomes planos. **Curado:** uma nota no topo declara que a
    estrutura do comando prevalece.

