---
branch: fix/provenance-method-english-writers
date: 2026-11-10
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
findings_fixed: 5
tokens: 180000
duration_min: 70
verdict: REPROVADO_E_CURADO
reviewer: passada própria sobre o próprio artefato (sem subagente) — gate mecânico: bancada kg_migrate_v3 e decide com mutantes, lint-artifacts
---

# Primeiro o que escreve: o único escritor em português era o migrador

Decisão do maestro de 2026-11-10 (`D_PROVENANCE_METHOD_VOCAB_PLAN_1110`, «Selar e começar pelo
seletor»): todo gerador do core grava a classe do `provenance.method` em inglês; o aviso SHOULD do
kg-ssot (v4.21) e a migração do corpus vêm depois. Este PR é só a primeira parte.

## A medição desmentiu a lista de partida

A lista da curadoria (medida na cópia vendorizada dela) apontava `kg-decide-seal.sh`,
`kg-radar.sh`, `agent-frontmatter-keys-check.sh`, `linear.md`, `lint-artifacts.sh`,
`members-validate.sh` e outros. Na `origin/main` de hoje, linha a linha:

- o **selador** já grava `testimony: decisão do maestro…` desde o contrato v4.16 (l.216);
- `seed-adoption-graph.sh`, `migrate-seed-graph.sh`, `census-seal.py`, `design-setup.py`,
  `drive-automate.sh`, `cc-delta-census.sh`, `stamp-adoption-graph-pin.sh`, o `/product:extract-meeting`,
  o workflow `onion-research.js` e a ajuda do `mcp-onion-kg-writer` já gravam ou ensinam em inglês;
- os outros acertos do `grep` são **prosa** («derivado:», «leitura:», «medição:» como palavra comum),
  rótulos de caso de bancada (`leitura: cat` no guarda de escrita de plugin) ou leitores que aceitam
  as duas formas (radar, `kg-contract-check.sh`, regex do selftest do writer MCP).

O único escritor que ainda gravava em português, **de propósito** e com comentário dizendo isso, era o
`kg-migrate-v3.py`: `derivado:` (modo v3 e onda O2), `testemunho:` (política 4, O1 e O2) e a classe do
routing repassada crua.

## Achados da passada adversarial

1. **Os 7 mutantes «morriam» por import, não pela troca (REAL, curado).** A 1ª versão do caso `(en)`
   copiava só o `kg-migrate-v3.py`; sem o `machine_path.py` ao lado, todo mutante quebrava no import
   e o caso contava 7 de 7. Cura: a cópia LIMPA roda no mesmo arranjo dos mutantes e tem de dar verde,
   e o mutante só conta como morto se o probe acusar um NÓ (nunca só o rc). Cada mutante agora morre no
   nó que ele mira (`canon-identidade→E_EN_NOVO`, `rota-alias→E_EN_O1`, `o1-host-pt→E_EN_O1H`,
   `o2-derivado→E_EN_O2`, `o2-host-pt→E_EN_O2H`, `v3-derivado→v3`, `canoniza-mantido→E_EN_MANTIDO`).
2. **A cópia limpa do selador reprovava fora da árvore (REAL, curado).** Copiado, o `kg-radar.sh`
   perde o `lib/status-factor.awk` e o resolver que acha pelo próprio caminho; o selador recusava antes
   de selar. Cura: o radar vizinho é um repasse (`exec`) ao radar real.
3. **«Vermelho» do mutante do selador podia ser quebra (REAL, curado).** O veredito passou a ser a
   classe GRAVADA: limpa tem de gravar `testimony`, o mutante tem de gravar `testemunho` com rc 0.
4. **Canonizar o valor mantido seria migrar o corpus por tabela (REAL, curado no desenho).** As ondas
   O4–O6 mantêm o method atual quando a coluna vem vazia ou `(inalterado)`. O `_put_provenance` só
   canoniza quando o valor difere do atual; o mantido em português fica. O mutante `canoniza-mantido`
   prova que o caso morde, e o `(o)` (E_O_REESC, E_O_DEVBIN) continua afirmando o mantido em português.
5. **O prompt do `/onion-research` nomeava a classe por `testemunho` (REAL, curado).** A l.65 já
   mandava escrever em inglês e a l.69 dizia «`testemunho` é classe de nó DEV»; virou «`testimony`
   (o alias `testemunho`)».

## O que ficou de fora, e por quê

- **Leitores e validadores** (radar, `kg-contract-check.sh`, regex do writer MCP, `METHOD_CLASSES`
  e `MEASURED_PREFIXES` do migrador): o contrato aceita os apelidos até o v5.
- **Fixtures de entrada da bancada** em português (tabelas julgadas, grafos de partida, selftest do
  writer MCP): testam a aceitação do apelido e o valor mantido; mudaram só as asserções sobre o valor
  GRAVADO.
- **`vendor/kg-ssot`** (templates de nó e o aviso SHOULD): é do kg-ssot, v4.21.
- **Corpus**: nenhum grafo migrado. Linha de base medida hoje: **5.328** `method:` em português em
  **206** de 293 grafos (`leitura` 1.909 · `medição` 1.014 · `derivado` 982 · `juízes` 932 ·
  `testemunho` 491), contra 1.056 em inglês.
