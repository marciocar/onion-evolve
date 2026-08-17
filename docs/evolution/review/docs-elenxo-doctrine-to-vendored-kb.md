---
branch: docs/elenxo-doctrine-to-vendored-kb
pr: 630
date: 2026-08-17
reviewed_diff_sha256: d99adfd142678ecc9b9c2f4497e52781aa52cf45ca2dff073ae845c4c95f6060
findings_total: 5
findings_real: 3
findings_fixed: 2
tokens: 0
duration_min: 40
verdict: CONFORME-COM-UM-ACHADO-CONTRA-A-PROPRIA-CURA-E-UM-REGISTRADO-SEM-CURA
reviewer: passada adversarial manual (3 ataques dirigidos) + medição no vivo; sem subagentes por restrição da sessão
REVISOU: true
---

# Resíduo — `docs/elenxo-doctrine-to-vendored-kb`

**Origem: um sinal de campo do maestro**, não uma inspeção — *"o ADOTANTE NÃO SABIA O QUE É O
ELENXO"*, colhido de uma sessão da PoC que teve de grepar o repo antes de responder à pergunta dele.

## Limite do método, declarado antes dos achados

A passada adversarial foi **manual**, não orquestrada: esta sessão está sob restrição de não usar
subagentes sem pedido explícito. Rodei **3 ataques dirigidos** ao meu próprio diff em vez de N lentes
independentes. Isso é **menos** que uma refutação adversarial de verdade — e por isso **este PR não é
um Elenxo**, é uma revisão. Usar o nome certo é a primeira exigência da doutrina que o PR entrega.

## Achado 1 — o grafo não sabia que a doutrina graduou (REAL, curado)

O ataque que mais rendeu foi *"algo linkava o rascunho que eu acabei de marcar como graduado?"*.
Rendeu: `docs/onion/graph/onion-doctrine-elenxo-bulbo-2026-07.kg.yaml` tinha **8 nós** com `trace:`
apontando para o rascunho, o **cabeçalho declarava** *"GATED — a pagina nao esta publicada nem
vendorizada"* (agora falso), e `D_PAGE_GATED` seguia **`open`** afirmando *"nao publicar nem
vendorizar ainda"*.

O que torna este achado grave não é o tamanho — é **de quem** é o defeito. Ele viola:

- o **invariante 6 da KB que eu mesmo acabei de escrever** (*"a fonte viva são os grafos; divergiu, o
  grafo ganha"*);
- a **etapa 5 do Elenxo**, que a própria doutrina nomeia como **a que mais falha**: *refutação narrada
  em prosa e grafo em 0/0/0/0*.

Escrever a doutrina da superação-que-vira-aresta e não virar aresta seria a página se refutando na
prática enquanto prega o método.

**Curado:** `E_ADOPTER_DID_NOT_KNOW_ELENXO` e `E_PATH_SCOPED_SKILL_INVISIBLE` (evidências `PROD`, com
`verified_at` e o que foi medido) sustentando `D_GRADUATED_TO_VENDORED_KB`, que `SUPERSEDES`
`D_PAGE_GATED` — com o **status do alvo reconciliado** para `superseded`, porque nó que recebe
`SUPERSEDES` e continua `open` é contradição estrutural que o radar reprova.

**A superação é declaradamente PARCIAL**, e isso está no rótulo: supera a metade **VENDORIZAR**; a
metade **PUBLICAR** segue `open` em `Q_PUBLICATION_AREA`. Fechar as duas seria cerimônia — o maestro
autorizou vendorizar, não publicar.

Radar depois: **exit 0**, 21 nós / 16 arestas, sem contradição estrutural.

## Achado 2 — link morto que EU introduzi no plugin (REAL, registrado SEM cura)

Ao ligar as 4 KBs à definição, o link em `knowledge-graph-sdaal.md` viajou para dentro do plugin
(`plugins/onion-work-tools/kb/`), onde o alvo **não está embarcado**.

Medi antes de reagir, e a medição mudou a conclusão: o plugin **já convivia com 4 links mortos da
mesma forma** (`inference-mitigation`, `onion-dogfooding-doctrine`, `onion-guardrails`,
`specification-driven-ai-abstraction-layer`). O meu é o **5º de uma classe pré-existente**, não um
defeito novo que eu criei.

**A lacuna real é de guarda:** `kb-vendored-link-check.sh` varre `docs/knowledge-base/**` e **não**
varre `plugins/**/kb/`. É a mesma família dos três pontos cegos de filtro de path desta casa
(`plugins/` #241, `docs/` #254, `ops/` #509) — e repare que o **primeiro deles foi exatamente
`plugins/`**.

**Não curei**, e a escolha é declarada: embarcar mais doutrina no plugin resolve 1 dos 5, e estender a
guarda a `plugins/**/kb/` é mecanismo novo que o maestro não pediu. Registro para não ser redescoberto
como surpresa — e porque a métrica honesta aqui é **5 links mortos**, não 4.

## Achado 3 — `8 skills` onde são 11 (REAL, curado de passagem)

`docs/onion/agents-reference.md:9` declarava **8 skills**. São **11** no disco e no inventário. O lint
de deriva de contagem **não pega** essa forma composta — pegou os `90 → 91` de KBs na mesma linha e
passou reto pelo número de skills ao lado.

Curado. Fica o registro de que a regra de contagem tem cobertura desigual por recurso.

## Os dois ataques que não acharam nada (e por isso valem)

- **O SOFT lexical de frescor doutrinário é meu?** Não. É `vps-tool-repo-skeleton.md` (`latest` sem
  `verified_at`), pré-existente. A KB nova não acrescenta SOFT algum.
- **Algo consumia o texto que removi de `onion-patterns`?** Não. `fan-out-and-synthesize` continua
  definido em `onion-orchestration/SKILL.md` — o conceito que a KB cita está vivo e é de outro dono.

## Prova

- Lint: **0 HARD / 4 SOFT** — idênticos à linha de base de antes do trabalho; as 4 são por desenho
  (2 passivos com catraca, 1 isenção declarada, 1 lexical alheio).
- **Passivo de link vendorizado intacto em 43**, `HARD=0` — a KB nova introduz **zero** link
  core-privado (medido com `--format tsv | grep onion-elenxo-doctrine` → vazio).
- Radar do grafo: **exit 0** (medido isolado, não por `$?` depois de pipe — a guarda de shell me pegou
  fazendo isso e estava certa).
- Contagem `90 → 91` varrida em **7 sítios independentes**, incluindo as 4 formas distintas do
  `INDEX.md` — cujo próprio rodapé (linha 598) avisa que a cura anterior desta classe parou em 1/4.

## Ressalva declarada (não é achado, é limite)

Este PR **não dispara a bancada**: `onion-selftest.yml` filtra por `.claude/{validation,hooks,utils}`,
`ops/`, `.github/workflows/` — e eu não toquei maquinaria nenhuma, só doutrina, docs e skills. O
filtro está correto aqui. Mas a rede que o justifica — o cron de 04:17 UTC — **ainda não disparou uma
única vez** (nasceu hoje, 12:54 UTC). Enquanto não disparar, o filtro segue nu, e este PR passa por
baixo dele legitimamente e sem cobertura de regressão.
