---
title: 'Resíduo — a SSOT do que viaja, e o vazamento que estava dentro do diretório permitido'
date: 2026-09-14
branch: fix/adopt-role-aware-manifest
reviewed_diff_sha256: 0447ad2f656c02a2218b5b5fb29bd3547ce8afd23b796e7611f7410e80f210f2
findings_total: 14
findings_real: 14
findings_fixed: 13
tokens: 154769
duration_min: 75
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Este PR não nasce de uma passada adversarial sobre código meu — nasce de uma MEDIÇÃO que o Elenxo da
  rodada de distribuição impôs contra a minha vontade de já desenhar o veículo: "antes de nova rodada de
  fontes externas, meça o PRÓPRIO mecanismo". A medição derrubou a premissa com que eu ia trabalhar e
  achou três defeitos reais, dois deles já entregues a clientes — e a bancada completa achou mais cinco,
  criados pela própria cura. O gate do PR é a bancada completa.
---

# Medi o mecanismo antes de desenhar em cima dele — e ele já fazia metade do que eu ia inventar

## A premissa que caiu

Eu tinha afirmado, na rodada anterior, que **"não há filtro nenhum"** no `/meta:adopt`, com prova: o
`grep -c exclude` no `adopt.md` dá zero.

**Medido por execução:** o `adopt` **não copia árvore**. Usa **allowlist de 11 pathspecs** mais
`git archive HEAD` — duas barreiras em série, e a segunda garante que untracked e ignored nunca viajam.
Rodei o procedimento verbatim num diretório vazio: **680 arquivos chegaram, e nenhuma pasta de
biografia**. Diário, sessões, beacons, `members.yaml`, `docs/evolution`, `docs/analysis`,
`docs/discussions`: nenhum. Confirmado em 6 adotantes reais.

O `grep` deu zero **porque o desenho não usa denylist** — que é exatamente o que a rodada de primárias
recomendou como correto. A ausência que eu li como defeito era a cura.

## Os três defeitos reais

### 1. Eram QUATRO cópias da mesma lista, e as duas guardas estavam defasadas

Não três, como a medição inicial disse: `adopt.md` (duas vezes — transporte e delta do `--update`),
`vendor-branch.sh`, o `roots=` da REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) e o
`VENDORED_ROOTS` da REGRA 45 (Link vendorizado não aponta caminho core-privado, com catraca).

**O transporte copiava 11 raízes; as duas guardas varriam 9.** `.claude/rules` e `.claude/workflows`
**viajavam sem ser varridos** por nome comercial de cliente nem por link core-privado. Guarda que varre
menos do que o transporte emite é fail-open com cara de cobertura.

**Cura:** SSOT única em `.claude/utils/adopt/vendor-manifest.sh`. As quatro superfícies consomem; as
guardas **derivam** as raízes do transporte, e a REGRA 36 falha alto se a SSOT não responder — lista
vazia zeraria a varredura em silêncio.

### 2. A biografia que vaza hoje vaza DENTRO de diretório permitido — e já chegou a 5 clientes

Os `*-baseline.txt` de `.claude/validation/` são **índice nominal do repo privado**: 32 paths únicos de
`docs/{discussions,analysis,materials}`, entre eles **5 arquivos do grafo pessoal do maestro**. Não são
link, então a REGRA 45 não os vê.

Medido nos repos entregues: **24 a 25 linhas em cada um** de `sacola-de-ideias`, `jogo-da-vida`,
`venda-direta-pdi`, `portal-gamificacao` e `onion-adopt-granaa-ai`. O único limpo é o `onion-standalone`
— justamente o que **não passou pelo caminho padrão**.

**Cura na EMISSÃO, não no destino:** `--stub-baselines` reescreve o baseline com o mesmo cabeçalho que o
`regen-baselines.sh` semeia (os dois mecanismos precisam concordar sobre o que é um baseline
ainda-não-emitido), e `--check-bundle` reprova se algum baseline emitido citar caminho privado. **O
passivo do core não é dívida do cliente.**

Para um cliente de consultoria — que forka e lê tudo — a fronteira precisava descer do **diretório** ao
**arquivo**. Desceu.

### 3. O `roles.yaml` não resolvia o problema, e eu tinha proposto ligá-lo como se resolvesse

Ele mapeia papel para **verticais e work_tools** (plugins e comandos). O corte que a consultoria precisa
é papel para **pathspec** — o corte do `onion-standalone` (274 arquivos a menos, zero a mais,
meta-fábrica fora) é de caminho, não de plugin. São SSOTs de coisas diferentes.

**Cura parcial, declarada:** o `--role` nasce **no transporte** (`adopted|hub|standalone`), com papel
desconhecido falhando alto (rc=2). O corte por papel — tirar a meta-fábrica do `standalone` — fica
**nomeado e não implementado**. É execução da próxima passada, não decisão do maestro.

## Os defeitos que a PRÓPRIA cura criou — e que só a bancada completa pegou

A primeira bancada completa depois da SSOT deu **5 falhas**, e nenhuma era do que eu entreguei: eram
efeitos colaterais da mudança. Vale registrar porque a lição é de método.

**O erro de desenho era meu, e grave:** eu fiz o `--emit-scrub-roots` consultar `git ls-tree HEAD`. As
guardas que o consomem rodam em **sandbox sem repositório** — ali a lista vinha **vazia**, meu próprio
fail-closed disparava, e o lint do sandbox saía com **43 HARD**. Uma guarda que depende de git para saber
o que varrer é uma guarda que não roda onde mais precisa rodar. Separado: **superfície declarada** não
consulta git; **manifesto de transporte** consulta e falha alto sem ele. Casos `(c2)` e `(c3)` cobrem os
dois lados.

**A bancada asseria sobre a CÓPIA, não sobre o transporte.** `upstream-portal: (b)` exigia a string
dentro do literal `want=(` — que deixou de existir. A pergunta certa passou a ser: a SSOT **emite**
`.claude/workflows`, e os dois consumidores a **consomem**? Mutante provado nos dois sentidos.

### E a classe que mordeu três vezes num dia

Ao virar SSOT, o `vendor-branch.sh` passou a resolver o irmão por `${HERE}` — e **três** mutantes que
copiam só o motor para um tmp ficaram **sem o manifesto**: `exit 2` (fail-closed correto) em
vez do comportamento que o caso existe para provar, e o teste acusou "vacuidade" onde havia cura.

É a classe `fail-closed-exposes-incomplete-harness`, e a cura é a mesma de sempre: **copiar a dependência
junto**, no harness — nunca afrouxar a guarda. Como mordeu três vezes no mesmo dia, virou **um helper**
(`_adopt_sibs_beside`), não três remendos.

## O que fica ABERTO

- **O corte por papel** (`--role standalone` sem meta-fábrica): nomeado, não implementado.
- **As cinco perguntas** do grafo da distribuição seguem esperando o maestro: fronteira, licença depois
  do MIT, marca, veículo + canal.
- **A REGRA 36 ainda depende do `members.yaml`** para derivar o vocabulário: cliente não registrado
  continua invisível para ela. É o `vendor-scrub-blind-spot`, e não foi curado aqui.

## Gate

```
bancada (LC_ALL=C, --jobs 4) : 1221 pass · 0 fail · 0 skip
lint (LC_ALL=C, completo)    : 0 HARD
radar --integrity --schema   : exit 0 (39 nós · 70 arestas) · realign: ALINHADO
família vendor_manifest      : 10 casos (a-h + c2/c3), incluindo mutante de docs/materials (NDA)
famílias vizinhas            : vendor_branch, vendor_scrub, kb_vendored_link, adopted_role — 20 pass
```
