---
reviewed_diff_sha256: 8a65694fc41adb6825b4d7b11d62b7eea94ebdb1182428d46798dac28a008aae
findings_total: 3
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 4
verdict: conforme
reviewer: claude-opus-5
---

# Revisão adversarial — `docs/gpg-key-custody-node`

O diff acrescenta um nó (`Q_CUSTODIA_DA_CHAVE_GPG_FORA_DA_VPS`), uma aresta `CONSTRAINS` e corrige
uma chave YAML duplicada. Ataquei as afirmações do próprio nó.

## Achado 1 — REAL, corrigido: o número nu ia envelhecer calado

O rótulo dizia *"decifra TODOS os 38 artefatos"*. **Terceira vez no dia** que eu ia gravar um
instantâneo como estado — as duas anteriores foram `devices=1` (eram 2) e `36 cifrados` (eram 38).
Desta vez medi antes: `38 cifrados / 0 em claro` em três diretórios. O número **está certo hoje** e
**estará errado amanhã**, porque o cron produz mais.

Corrigido não pelo número, mas pela forma: *"todo artefato de backup desta VPS (38 na medição de
11-08 — o número cresce com o cron, a dependência não)"*. A afirmação que importa é a
**dependência**, e essa não decai.

## Achado 2 — REAL, corrigido: `verified_at:` duplicado no nó vizinho

`Q_BACKUP_AINDA_NAO_SAI_DA_MAQUINA` tinha **duas** linhas `verified_at:` (10-08 e 11-08). O radar é
`awk`, não parser YAML — uma chave por linha, e duplicata não é erro para ele: é ambiguidade que
passa. Ficou só a data da medição real (11-08), e o `verified_against` passou a dizer
`...pacote-de-1.1MB-ainda-no-disco` em vez de `...entregue`, que era otimista: o pacote foi
**gerado**, não **entregue** a lugar nenhum.

## Achado 3 — INVESTIGADO, não é defeito: `CONSTRAINS` e não `SUPPORTS`

A aresta nova vai de custódia → backup-offsite. Testei se deveria ser `SUPPORTS`. Não: a custódia da
chave não *sustenta* a questão do offsite, ela **limita** a solução — qualquer destino escolhido é
inútil se a chave morrer junto com a origem. `CONSTRAINS` é a aresta que carrega isso. Segue.

## O que este nó deliberadamente NÃO afirma

Que a chave chegou ao destino. Eu medi a **ausência** do `.asc` na VPS e a **presença** da privada no
chaveiro; o download é observável só do lado do maestro. Arredondar isso para "custódia resolvida"
seria a mesma falha de medir no caminho errado — e aqui o custo do erro é o pior possível: descobrir
que o lacre não tem dono no dia em que a VPS morrer.

**Radar:** exit 0 sem pipe (23 nós, 19 arestas, zero contradição estrutural).
