---
title: 'Resíduo — as decisões da distribuição pública, e o vazamento que só a decisão de publicar encontrou'
date: 2026-09-14
branch: feat/public-distribution-decisions
reviewed_diff_sha256: 470847a59778af2530f9cf4642f48e3a08fa8ddc62c96ca69d951ef11b08f3ec
findings_total: 5
findings_real: 5
findings_fixed: 5
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Este PR não é código novo: é o SELO de sete decisões do maestro mais a cura que a primeira delas obrigou.
  O achado que domina o resíduo não veio de passada adversarial — veio da regra de medir antes de publicar:
  havia nome comercial de um cliente real em dois arquivos que viajam para todo adotante, e a guarda que
  existe exatamente para isso não o via.
---

# Selei sete decisões, e a decisão de publicar achou o vazamento

## O que este PR sela

Sete selos do maestro em 2026-09-14, todos escritos no grafo com `verified_against` nomeando o selo:

| Selo | Nó | Grafo |
|---|---|---|
| Veículo: standalone público **mais** `/meta:adopt` no repo do cliente | `D_VEICULO_STANDALONE_PUBLICO_MAIS_ADOPT` | distribuição |
| Corte: viaja **tudo**, inclusive a meta-fábrica | `D_CORTE_E_TUDO_INCLUSIVE_META_FABRICA` | distribuição |
| Licença **dual**: código MIT, método CC BY-NC 4.0 | `D_LICENCA_DUAL_CODIGO_MIT_DOUTRINA_CC` | distribuição |
| Marca: **medir** antes de decidir (a rodada rodou; o depósito espera o INPI) | `D_MARCA_MEDIR_ANTES_DE_DECIDIR` | distribuição |
| Vazamento nos 5 adotantes: limpar no **próximo `--update`** de cada | `D_LIMPAR_BASELINES_NO_PROXIMO_UPDATE` | distribuição |
| Scrub: **curar antes de publicar**, e a guarda passa a asserir forma | `D_SCRUB_POR_FORMA_CURADO_ANTES_DE_PUBLICAR` | distribuição |
| As **quatro emendas** à opção C entram no desenho de C | `D_R2_EMENDAS_A_C_SELADAS` | compartilhamento |

## O achado que dominou

**Nome comercial de um cliente real de PoC, em dois arquivos que viajam para todo adotante**
(`.claude/commands/meta/adopt.md` e `.claude/utils/adopt/regen-baselines.sh`). A REGRA 36 (Superfície
VENDORIZADA sem nome comercial de cliente) nunca cobrou, e não por bug: ela **deriva os termos do
`members.yaml`**, então cliente que nunca foi registrado é invisível para ela. Derivar do registro é o
desenho certo — nome hardcoded num script É o próprio vazamento —, mas o defeito dominante em guarda de
lista é o **vocabulário**, não a lógica.

Ele só apareceu porque a decisão de publicar obrigou a medir. Sem a publicação em vista, seguiria viajando.

**Cura em duas metades, e as duas entraram:**

1. **O nome saiu do texto**, nos dois arquivos, neste PR.
2. **A guarda passou a asserir FORMA** — `.claude/validation/vendor-scrub-form-check.sh`, ligado na segunda
   metade da REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente): ampersand corporativo (pelo menos um lado com 2+ caracteres, o que já elimina M&A,
   Q&A, V&V, R&D) e âncora de contexto (`PoC`/`cliente`/`adotante`/`empresa` seguida de nome próprio).
   Forma gera **candidato**, nunca veredito: o legítimo vai para um baseline que **só encolhe**, candidato
   novo é HARD — idioma das REGRAS 45 (Link vendorizado não aponta caminho core-privado, com catraca) e 49
   (Catraca de passivo declarado).

**Teto declarado:** nome comercial **sem** ampersand e **sem** âncora continua invisível. Alargar o padrão
para "qualquer palavra capitalizada" mataria a guarda de falso-positivo, e uma guarda que grita sempre é
uma guarda desligada.

## Os quatro defeitos que a própria cura criou

**1. O baseline se auto-acusava.** Ele vive em `.claude/validation/`, que está **dentro** da superfície
varrida — então todo termo tolerado renascia como candidato novo num caminho diferente. Medido na primeira
execução: **8 HARD, todas o baseline acusando a si mesmo**. Cura: o scan exclui o próprio baseline.

**2. Exemplos do detector viravam achado do detector.** `Acme&Co` e `Baker&Sons` estão nos comentários do
próprio script, para explicar a forma. Ficaram no baseline com a razão escrita — é passivo tolerado, não
vazamento.

**3. O teto da REGRA 16 (Contagem de inventário-TOTAL divergente da SSOT).** Corrigido no PR anterior, mas vale registrar aqui porque a classe é a mesma: o
conjunto `[...]` com caractere multibyte casa **byte** no GNU grep sob locale C. Continua valendo a
guarda `shell-locale` da bancada.

**4. `--emit-scrub-roots` não pode depender de git.** Já curado no PR #826, e a razão reaparece aqui: o
detector por forma consome a SSOT e roda em sandbox sem repositório. Se a lista viesse vazia, o fail-closed
dispararia e o lint do sandbox sairia com dezenas de HARD.

## O que fica ABERTO, com dono e gatilho

- **A colidência de "onion" na base do INPI não foi medida** — a busca exige sessão de navegador e nenhuma
  rota automática funcionou. São **10 minutos do maestro** em `busca.inpi.gov.br/pePI`. É a condição
  declarada de `Q_MARCA_DEPOSITAR_CLASSE_42_AGORA`: pode derrubar a recomendação inteira.
- **Os 5 adotantes seguem com o índice nominal** (24-25 linhas cada) até o próximo `--update` de cada um.
  Custo aceito e declarado; **gatilho de reabertura**: algum desses repos virar público ou ganhar terceiros.
- **O `onion-standalone` público ainda está no corte de 2026-07-19** (274 arquivos a menos). Levá-lo ao core
  atual é execução nomeada; **publicar é ato do maestro** (outward-facing).
- **As sete lacunas legais** do fio do compartilhamento (TST por acórdão, ANPD sancionadora, negociação
  coletiva) seguem abertas **por ordem do maestro** — ele vê em paralelo e informa. Não bloqueiam o desenho
  de C, e a razão está escrita no próprio selo.

## Gate

```
bancada (LC_ALL=C, --jobs 4) : 1227 pass · 0 fail · 0 skip (164 famílias, 859s)
lint (LC_ALL=C, completo)    : 0 HARD
radar --integrity --schema   : exit 0 nos dois grafos
  distribuição               : 52 nós · 91 arestas · realign ALINHADO
  compartilhamento           : 116 nós · 191 arestas · realign ALINHADO
família vendor_scrub_form    : 6 casos, com mutante que reprova quando a exclusão do baseline cai
commit                       : SEM --no-verify (ordem do maestro)
```
