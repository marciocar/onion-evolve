---
title: 'Proposta: a REGRA 112 passa o --with ao checador de projeção'
date: 2026-10-27
from: onion-curation (adotante)
to: core (onion-evolve)
type: proposal
estudo: docs/evolution/research/design-setup-2026-10/ (emenda G)
---

# Proposta: a REGRA 112 julga a página que cita grafo de outro repositório

**Pedido do maestro em 2026-10-27:** "não quero deixar para depois o checador, crie e ajuste o que for preciso com
atenção e segurança."

## O que foi medido

O plano (`PLAN-G.md`) foi commitado antes do laboratório. O laboratório (`lab_projection_with.sh`) rodou em pastas
descartáveis, com um prefixo de URL fictício.

1. **O produto está certo.** O `kg_trace.py projection --with` da kg-ssot 4.35.0 bateu com o pré-registro nos 10 casos.
   - **G4 e G5, os decisivos:** o id que só existe na outra ponta do histórico sai `missing`. O grafo é lido no commit
     da URL, não na ponta.
   - **G3 e G10:** sem o `--with` daquele prefixo, a página sai `outside`, contada e não julgada.
   - **G6:** com um sha que não existe na pasta, o grafo é lido da árvore e o produto declara `unpinned`.
2. **A REGRA 112 não julga essa página.** O `kg-projection.sh` chama o produto sem `--with`. No caso G2, um id morto
   no outro repositório sai só SOFT `FORA-DO-REPO` (rc 1 por SOFT). Nunca sai HARD `ID-AUSENTE`.

## A proposta: um patch de 72 linhas no `kg-projection.sh`

O patch, medido, está em `evidence/lab-projection-with/kg-projection-with.patch`.

- **Como recebe o par:** por `--with PREFIXO=PASTA` (repetível) e pela variável `ONION_KG_PROJECTION_WITH`, um par por
  linha, que é a forma que o lint herda sem mudança. Os pares vão ao produto como `--with=`.
- **Segurança:**
  - forma ruim (sem `=`, ou prefixo fora de `https://`) sai rc 2, "não pude julgar";
  - se a pasta não é um repositório git, como no CI sem o clone do par, sai um aviso no stderr, o par não vai ao
    produto e a página segue SOFT `FORA-DO-REPO`, como hoje. Nunca fica verde calado;
  - o produto só lê a outra pasta (`git show` do commit da URL); nada se escreve lá.
- **Sem `--with`, o comportamento é idêntico ao original.** Foi medido no G2: a mesma linha e o mesmo rc.
- **A mensagem do ID-AUSENTE foi corrigida.** "não existe em grafo nenhum do repositório" ficava errado quando o grafo
  é de outro repositório. Passa a dizer que o id não existe em grafo nenhum que o produto leu.
- **Medido com o patch:**
  - G2, G4 e G5 viram HARD `ID-AUSENTE`; G1 e G8 passam;
  - G9 segue SOFT `EM-OUTRO-GRAFO`, G6 segue SOFT `NAO-FIXADO`, e G7 sai HARD `GRAFO-NAO-LIDO`;
  - a bancada `run_kg_projection_selftests` (`--families kg_projection`), rodada numa cópia do repo, deu o mesmo
    placar no original e no patch: 8 casos passam, e o caso (g) dispatcher falha nos dois. A falha já existia no
    adotante e não vem do patch. As saídas estão em `evidence/lab-projection-with/selftest-*.txt`.

## Para o core decidir

1. **Absorver o patch** no `kg-projection.sh` e um caso na família `run_kg_projection_selftests`. O caso mutante: sem
   o par, o G2 sai SOFT; com o par, sai HARD.
2. **De onde vêm os pares:**
   - a variável no ambiente de quem roda o lint, que é o mínimo;
   - ou um arquivo versionado de pares (`prefixo=pasta`) lido pelo wrapper, como o mapa de pares do
     `peer-ref-check.sh`. A curadoria não escolheu: é desenho do core.
3. **O `NAO-FIXADO` no modo estrito.** Um sha de digitação faz o grafo ser lido da ponta (G6). Hoje isso é SOFT; o
   core decide se no modo estrito vira HARD.

## Falha que já existia no adotante (para o core olhar)

O caso (g) da `run_kg_projection_selftests` falha na curadoria com o wrapper original. Ele espera a REGRA 112 HARD
`ID-AUSENTE` no arquivo de HARD (`ONION_LINT_HARD_FILE`) e não a encontra, embora a linha VIOLATION saia. A causa não
foi investigada: o pedido não era esse, e a bancada é do core.

## Observação ao produto (kg-ssot)

No G7, o grafo do `projection_of` não se lê. O produto conta o id da página como `missing`, além do `graph_errors`, e
sem leitura não há veredito sobre o id. Vai ao kg-ssot como nota, não como defeito do wrapper.

Orquestrado com 🧅 Onion Evolve

## Triagem do core — 2026-10-27

**Veredito: ABSORVIDO, reescrito no idioma da casa** (o patch de 72 linhas foi referência, conferido pelo
SHA256SUMS dela; não foi aplicado às cegas). Branch `feat/kg-projection-with`.

- **Os pares:** `--with PREFIXO=PASTA` (repetível) e `ONION_KG_PROJECTION_WITH` (um por linha), que vencem
  no prefixo; no core, também o `members.yaml` (`remote: github.com/<dono>/<repo>` →
  `https://github.com/<dono>/<repo>/blob=<local_path>`), só para o prefixo que alguma página declara. Sem o
  registro (o adotante) não há erro. Nenhum arquivo novo de pares.
- **Segurança:** forma ruim → rc 2; pasta inexistente ou não-git → aviso nomeado, o par não vai, a página
  segue SOFT `FORA-DO-REPO`; no lint o aviso sai SOFT `[PAR-SEM-CLONE]`. Sem par, a saída é a de antes.
- **NAO-FIXADO:** HARD com `--strict`, que o dispatcher passa só no core; no derivado, SOFT (1º ciclo). Além
  do `unpinned` do produto (o G6), a URL que nomeia um ramo no lugar do sha também sai NAO-FIXADO, com o
  caminho da página.
- **A mensagem do ID-AUSENTE** passou a dizer "grafo nenhum que o produto leu", como ela propôs.
- **O caso (g):** passa na main do core e falha no adotante pelo carimbo: a caixa herdava o
  `.claude/.onion-version` com `role: adopted` e o 1º ciclo rebaixava o HARD esperado. Reproduzido numa cópia
  com o carimbo dela, e curado na bancada: a caixa fixa o papel (sem carimbo = core) e um 2º passe como
  adotante espera SOFT.
- **Bancada:** sete casos novos na família `kg_projection`, de (i) a (q), cada um com mutante.
- **A nota ao kg-ssot (G7)** fica com a curadoria, que é quem fala com o produto.
