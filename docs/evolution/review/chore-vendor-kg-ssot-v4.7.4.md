---
branch: chore/vendor-kg-ssot-v4.7.4
pr: pendente
date: 2026-10-17
reviewed_diff_sha256: 2b3cc4d8efd8891467826613e3df9e88f132a502064f52f4419ecc5e9c8959ac
reviewed_code_sha256: b13b1b97c8ce99589e1ddfd955a28fcadd8f88f0c22910b2eb5c6db66ef4e8ea
findings_total: 6
findings_real: 6
tokens: 116332
duration_min: 4
findings_fixed: 5
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose model opus, 1 passada com mandato de refutar; gate mecânico: kg_vendor check, kg-contract-check A/B 4.7.3 × 4.7.4 nos 215 grafos fora do vendor, kg-gate-ci, bancada com LC_ALL=C e 7 mutantes
nota: "o achado não curado é dívida anterior: o conselho do censo usa caminho relativo ao repo, igual à linha do kg_vendor update que já existia"
---

# O vendor sobe para a kg-ssot-v4.7.4 e as dependências do leitor instalam com `--require-hashes`

## O que muda

- `vendor/kg-ssot` ← `kg-ssot-v4.7.4` (c0a1ddbdf6ea, 315 arquivos), pelo motor `kg_vendor.py update --tag`,
  como o censo de atualidade mandou. Muda o `tools/requirements.txt` (sha256 de todos os arquivos publicados
  das 7 dependências; piso Python 3.11) e a documentação; os dois schemas têm o mesmo sha256, então o gate
  segue rc 0 sem `kg_gate.py --update`.
- `--require-hashes` no `pip install` do CI do core (com `python3 --version` e o piso 3.11 nomeado) e no
  template de CI dos adotantes (só quando o requirements do alvo traz hash), e no conselho do censo.
- Bancada: família `kg_ssot_require_hashes` (população medida, linha lógica normalizada, piso 3, caso (c) com
  as formas que escapavam) e casos (g2) e (g3) do censo.
- `E_CONTRATO_V43_ADOTADO` recebe a medição do kit.

## Achados

1. **A justificativa da flag estava errada** (real, curado). O pip liga o modo de hash sozinho quando o
   arquivo traz `--hash` (medido: requirements adulterado sem a flag dá rc 1). A flag só acrescenta falhar
   alto se o arquivo perder todos os hashes. Os comentários do CI, do template, da bancada e o nó dizem isso.
2. **O template quebrava o CI de quem tem `vendor/kg-ssot` próprio e anterior** (real, curado). O manifesto
   não sobrescreve o vendor do alvo, e sem hash o `--require-hashes` recusa tudo. O template passa a flag só
   quando o arquivo traz hash; provado: com hash rc 0 com a flag, sem hash rc 0 sem ela.
3. **A guarda dependia do vocabulário** (real, curado). `-r` na linha de baixo, flag só no comentário e
   pacote avulso escapavam, e o piso 2 deixava passar a perda de um sítio. Agora a linha é normalizada, o piso
   é 3 e o caso (c) prova as três formas.
4. **Ordem cronológica no nó** (real, curado): a entrada da 4.7.4 tinha caído no meio do `verified_against`.
5. **"Três sítios que instalam"** (real, curado): o censo aconselha, não instala.
6. **Caminho relativo no conselho do censo** (real, não curado): é a convenção que a linha do
   `kg_vendor update` já usava; dívida anterior, declarada.

## Mutantes

Todos plantados pelo motor de mutação da casa (com marcador e restauração conferida por hash): template sem a flag; CI com a linha quebrada e
sem a flag (o que o refutador mostrou passar na 1ª versão); template com `rh` sem a flag; junção de
continuação desligada; corte de comentário desligado; conselho do censo voltando a `pkg==pin`; pino do censo
ancorado no fim da linha. Os 7 reprovam.

## Limites declarados

- Requirements passado por variável (`-r "${RQ}"`) não é visto pela guarda.
- Os adotantes que já têm o CI do template não recebem o workflow novo (o oferecedor nunca sobrescreve), mas
  ficam protegidos pelo modo de hash automático do pip assim que o vendor novo chegar pelo `/meta:adopt --update`.
- Python do CI medido pela imagem do runner (ubuntu-24.04); o `python3 --version` novo no passo mostra o valor no CI deste PR.
