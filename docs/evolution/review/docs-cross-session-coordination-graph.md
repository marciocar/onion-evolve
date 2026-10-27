---
branch: docs/cross-session-coordination-graph
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 3
tokens: 0
duration_min: 15
findings_fixed: 3
verdict: CORRIGIDO
elenxo: nao
reviewer: "subagente da sessão principal (claude-opus-5-5), passada própria sobre o diff"
nota: "tokens não medidos; grafo, projeção e duas frases de doc"
---

# Passada adversarial: `docs/cross-session-coordination-graph`

## O que muda

- Nasce `docs/onion/graph/coordenacao-sessoes-2026-10.kg.yaml`, o grafo de coordenação entre as sessões: 32
  pendências abertas, cada uma com `owner:` (campo do contrato v4.8 da kg-ssot), 16 arestas DEPENDS_ON, 6
  external_edges para nós que já existem em outros grafos do core, o nó de censo e a lição do kg-ssot sobre o
  merge em segundo plano.
- O grafo entra no escopo da REGRA 58 (O backlog cumpre as promessas do próprio meta:) com TETO de 40 nós.
- `docs/backlog.md` regenerado depois do `git add`: o agrupamento por `owner:` passa a valer para as pendências.
- `/meta:backlog` e o comentário do gerador deixam de dizer que nenhum nó declara `owner:`.

## Achados

1. **Real, corrigido.** A frase do comando e do gerador dizia que nenhum nó do corpus declara `owner:`. Medido
   antes deste PR, já era falso: sete grafos tinham nós com `owner:` (passada-adversarial, distribuição do
   método, medidores silenciosos, radar E3 r5, door-role-parity, onion-identity, fios-abertos). A frase nova diz
   o que vale hoje: o grafo de coordenação o declara em cada pendência, outros grafos em nós avulsos.
2. **Real, corrigido.** O label do PR 1407 dizia que o merge é do maestro com o dono `core`: duas afirmações que
   se contradiziam. Ficou só «falta o merge».
3. **Real, corrigido.** «D0 do lançamento» era código curto sem glosa; virou «dia zero (D0)».
4. **Limite, não defeito.** O `kg_query.py` não filtra por `owner`. A consulta por dono sai pelo `--fields owner`
   no JSON com um filtro `jq`, e o comando exato está no corpo do PR.

Conferido e mantido: o nome do membro do brain no registro carrega o nome de um cliente, por isso o grafo diz só
«brain» e não cita o caminho do clone; o nó da curadoria (`Q_MC_BROWSER_LOCAL`) entra pela proveniência com URL
fixada no sha, conferida por `peer-ref-check.sh` (rc 0 @ e3db38e), e não por external_edges, que o gate confere
só contra os grafos deste repo.

## Mutantes

- TETO declarado 30 com 34 nós: `kg-backlog-check.sh` sai HARD TETO.
- Linha do TETO apagada: HARD SEM-TETO.
- Primeira pendência trocada para `done` sem carimbo: HARD DONE-NU.
- O original: OK, 34/40 nós. Radar `--integrity --schema` rc 0 e `kg-contract-check.sh` conforme.

## Limites declarados

- O estado dos PRs é o da medição de 2026-10-27; o grafo não se atualiza sozinho. Quem fecha uma pendência fecha
  o nó com carimbo.
- A maior parte das pendências vem por testemunho das sessões peer, repassado pela sessão principal; só os PRs
  do core e o nó da curadoria foram medidos aqui.
- O lint inteiro não terminou no foreground desta sessão (VPS com outros lints em paralelo); até onde rodou,
  nenhuma violação tocava os arquivos deste PR. O gate do pr-finalize e o CI são a medição completa.
