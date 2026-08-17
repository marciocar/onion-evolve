---
branch: fix/adopt-regen-all-baselines
pr: 628
date: 2026-08-17
reviewed_diff_sha256: d0929fa351015d69643f1018c6ef357b125a8164f5d8d62066c70ed4ea841306
findings_total: 6
findings_real: 6
findings_fixed: 6
tokens: 0
duration_min: 55
verdict: CONFORME-COM-SEIS-DEFEITOS-PROPRIOS-CORRIGIDOS-EM-LOOP
reviewer: dogfood de campo (adoção greenfield real) + as guardas da própria casa — quem achou 4 dos 6 defeitos foi mecanismo, não pergunta do maestro
REVISOU: true
---

# Resíduo — `fix/adopt-regen-all-baselines`

**Origem: dogfood de campo, não inspeção.** O maestro pediu um projeto novo com adoção do Onion
(uma PoC com cliente real). Rodar o `/meta:adopt` de verdade produziu o achado que nenhuma leitura
do procedimento produziria: **o adotante nasceu com 47 violações HARD**, todas
`[kg-verificacao/REMOVIDO]`, cobrando nós de grafos que só existem no core.

## Achado 1 (do core) — a adoção regenerava 1 de 5 baselines de catraca

O manifesto copia `.claude/validation/` inteiro, então os cinco baselines viajam com o passivo do
core. O passo (9) do `/meta:adopt` regenerava **um** — e trazia escrito ao lado, com precisão, o que
a omissão causaria: *"o gate nasceria reprovando o repo do adotante no dia 1 e seria desligado"*.

Agravante que só apareceu ao **ler o código da guarda**: a catraca resolve a referência caminhando
até o **primeiro commit** que tenha o baseline, então o passivo entra na história antes de tudo e
regenerar depois não basta.

**Cura:** `.claude/utils/adopt/regen-baselines.sh`, por **descoberta** (varre `*-baseline.txt` e
resolve o emissor de cada um; baseline novo entra coberto por construção), com falha **ruidosa**
(rc=3) que **preserva** o baseline em vez de trocá-lo por vazio, e recusa rodar no core.

## Achado 2 (do core) — a guarda de projeção confiava na metade que o gerador publica

Ao registrar o adotante, o nome comercial do cliente (sob NDA) entrou no `name:` do `members.yaml`
e **apareceu no `federation-console.html` publicado, com o lint verde**. O console publica só o
trecho antes de `" ("`; toda a força da `projection-safety` mira a **anotação** entre parênteses.

**Cura:** P6 — o trecho projetado tem de ser o próprio slug, com isenção declarada **no dado**
(`projection_name_exempt`). Mais `federation-map.md` admitido às superfícies auditadas: o console
é auditado desde o incidente de 2026-07-10 e o irmão gerado pelo mesmo `graph.sh` nunca foi.

## Achados 3–6 — defeitos MEUS, nesta mesma rodada

3. **A guarda do core passou por idempotência, não por verificação.** Minha 1ª versão lia o arquivo
   `.claude/.onion-version` e ficava **muda no core**, que não o tem (ali o papel é *computado* pelo
   `onion-version.sh`). Não houve dano só porque os baselines do core saíram byte-idênticos —
   **certo por sorte**. Agora pergunta à autoridade.
4. **Falso-positivo no P6 por discordar do gerador.** Eu não descartava comentário de fim de linha
   no `name:`, e o gerador (que lê YAML com parser) descarta — a checagem acusou um membro real.
   Guarda que discorda do gerador sobre o que é projetado mede outra coisa que não a superfície.
5. **A REGRA 36 me pegou:** pus a allowlist de isenção como variável dentro do
   `projection-safety.sh`, que é **vendorizado** — id de adotante ali é vazamento cross-tenant por
   adoção. A isenção passou para o `members.yaml`.
6. **Meus selftests novos matavam a bancada.** `cmd; rc=$?` sob `set -e` aborta a suíte, e os
   helpers saem 2/3 de propósito. A **guarda da própria bancada** acusou (`BENCH_RC=2`, *"NÃO leia
   esta saída como verde"*), nomeando o suspeito nº 1 que era exatamente o meu padrão. Corrigido de
   passagem um defeito latente pré-existente da mesma classe.

## Erros de MEDIÇÃO desta rodada, registrados sem apagar

- **`head -20` truncou a bancada** por SIGPIPE e eu li o `exit 0` do `head` como aprovação da
  suíte — **terceira vez** que trunco uma medição e reporto número errado. A bancada teve de rodar
  inteira, em arquivo, sem filtro.
- **Editei o `lint-selftest.sh` enquanto ele rodava** em background: o bash lê o script
  incrementalmente e a suíte morreu com `BENCH_RC=127`. Script em execução não se edita.
- Duas hipóteses erradas sobre a origem das 47 chaves antes de ler o código; a segunda me fez tomar
  "5 linhas" (cabeçalho emitido) por "5 chaves".

## O que a rodada prova sobre o gatilho de correção

Quatro dos seis defeitos foram acusados por **mecanismo** — a guarda anti-fail-open do shell (2×),
a REGRA 36, e a guarda de abort da bancada — nenhum por pergunta do maestro. Isso **qualifica** a
meta-lição de 2026-08-02 (*"o gatilho eficaz é social"*) na mesma direção do registro de 08-11:
onde existe mecanismo, ele dispara sozinho. Os dois que faltaram (a 1ª guarda muda no core, o
falso-positivo do P6) foram achados pelos **testes que eu escrevi para eles** — não por leitura.

## Prova

- Lint do core: **0 HARD / 4 SOFT** (rc=0).
- Radar do KG: **exit 0**, 35 nós / 44 arestas, sem contradição estrutural.
- Bancada: 2 kinds novos (`regen-baselines` 5 casos · `projection-name` 4 casos), cada um com o
  defeito medido reduzido a fixture **e** o falso-positivo testado junto com o vazamento.
- Defeito original reproduzido em fixture: baseline com 2 chaves de path do core → **0** após o
  helper, sem sobrar nenhuma referência a `onion-pessoal-marcio`/`bridge-produto`.
- Alvo real: **0 HARD / 4 SOFT**, gate provado por execução, `main`/`onion/adopt`/`onion/vendor`
  publicados em repo **privado**.
