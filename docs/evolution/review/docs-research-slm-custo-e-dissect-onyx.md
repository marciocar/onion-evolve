---
title: 'Resíduo — a pergunta estava mal posta, a narrativa era de fornecedor, e a fronteira em prosa não segurou'
date: 2026-10-02
branch: docs/research-slm-custo-e-dissect-onyx
reviewed_diff_sha256: 4c7032de48bb5a8571e84ac57057da34ee0b6d976fac786ca1e766c305342c21
findings_total: 18
findings_real: 18
findings_fixed: 16
tokens: 27495442
duration_min: 188
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >-
  Oito achados de duas rodadas de pesquisa (27,5M tokens somados) e uma dissecação. Seis curados, DOIS
  declarados medidos-e-não-curados com gatilho. Os dois mais valiosos são contra as premissas: a
  pergunta de economia de inferência estava MAL POSTA (o gate já é LLM-free e a doc oficial recomenda
  exatamente essa troca), e a narrativa de evolução dos SLMs tem a fase 2026 sustentada só por
  declaração de fornecedor — com o analista independente REBAIXANDO a recomendação no mesmo período.

# Três entregas, e as duas melhores contradizem quem perguntou

## 1. A pergunta de economia de inferência estava MAL POSTA — e a casa é a prova

Fui pesquisar como baixar o custo de inferência no CI e no lint. **Não há custo ali.** O gate
determinístico são 26.441 linhas de shell, 93 regras, radar sem LLM e 1605 asserções: custa **minuto
de runner**, zero token. E a **doc oficial da Anthropic recomenda exatamente essa troca** — mover
verificação para hook determinístico, caindo de **dezenas de milhares de tokens para centenas**.

A parte que eu ia otimizar **já é a prática recomendada**. O veredito é *fica como está*, e isso só
aparece porque o eixo 1 da rodada foi escrito para **duvidar da própria pergunta**.

## 2. Modelo local nesta VPS: armadilha MEDIDA

Um **32B denso Q4** entrega **3,54 tok/s** numa CPU **melhor** que esta (12c/24t, 96 GB), e aqui
competiria pelos **mesmos 8 cores** que a bancada satura por 17 min. A página de benchmark da Qwen
**não traz uma única medição CPU-only** — a faixa **sequer é anunciada** para este uso.

Na rodada irmã, **nenhum tok/s em x86 sobreviveu** aos votos. Resta ARM (Raspberry Pi 5 a 7,6 tok/s,
medição do próprio fornecedor) e o detalhe que mata a esperança do MoE: **a memória segue o parâmetro
TOTAL, não o ativo**.

## 3. A narrativa de evolução dos SLMs: a fase 2026 é declaração de fornecedor

O maestro colou uma síntese de outro assistente e disse *"você que tem que buscar a verdade"*. O
resultado:

- **2024** (eficiência + qualidade do dado) é **a fase mais sólida**, com data e fornecedor.
- **2025** está **parcialmente refutada**: MoE e multimodal em SLM já estão no paper Phi-3 v4
  (**2024-08-30**). **Marcos de 2024 foram realocados para 2025** — é "narrativa limpa demais".
- **2026** (SLM como agente local) sobrevive **só como declaração de fornecedor**: blog + eco no mesmo
  dia, mais um **position paper de jun/2025**. **Nenhuma medição de produção atravessou os três votos.**

**E o achado que decide vem do analista INDEPENDENTE:** o Thoughtworks Radar carrega o blip desde
out/2024 em **Trial** e **moveu para ASSESS** entre abr/2025 e nov/2025, mantendo Assess em abr/2026 —
**rebaixou a recomendação no mesmo período em que o discurso de fornecedor subia**. Curvas opostas: a
do fornecedor é a suspeita.

Duas correções de atribuição: a variante de reasoning é **Microsoft** (Phi-4-mini-reasoning), não
Google; e a survey SLM-first é **arXiv 2506.02153, de 2025-06-02, NVIDIA + Georgia Tech** — **anterior**
à narrativa e **position paper, não medição**. A suspeita que eu levantei sobre o formato do ID
estava certa.

## 4. A dissecação da Onyx confirma o diferencial do Onion POR AUSÊNCIA DE CAMPO

O schema do grafo dela (lido na primária) **não tem** `valid_from`/`valid_to`, **não tem**
`verified_at`, **não tem** tier de fonte e **não distingue** verificado de extraído. Isso é muito mais
forte que ausência em página de preço: **ausência de página é falta de saliência; ausência de CAMPO é
o dado não existir para ser cobrado.**

E fechou por medição a opção que parecia boa: *Onyx como receptor hospedado* — **12 containers** com
OpenSearch e **dois** servidores de modelo, contra 8 vCPU já saturados. **Bloqueada por hardware, não
por princípio** — o que muda o gatilho.

## 5. O gatilho que eu nomeei ontem FUNCIONOU, e é medição do próprio mecanismo

Subi `maxVerify` de 36 para 52 honrando o que eu havia escrito. **A fração verificada quase dobrou
(36% → 63%) com custo por nó praticamente igual** (~246k contra 212–242k). Comprou **cobertura**, não
gastou mais por unidade. Mantida a faixa.

## 6-7. DOIS achados declarados MEDIDOS E NÃO CURADOS, com gatilho

**6. A fronteira entre rodadas irmãs declarada em PROSA não segurou.** Escrevi no corpus *"o
cruzamento legítimo é só o eixo 6"* e a rodada do SLM veio com **13 claims duplicadas** contra 3 da
irmã — custo por nó de **305k** contra 246k. **Prosa não é fronteira**, que é a mesma lição do
refutador que escreveu em seis arquivos com instrução explícita para não escrever. Cura candidata: o
workflow aceitar lista de `kgPath` irmãos e descartar claim cuja URL+asserção já exista. **Gatilho:** a
próxima vez que eu disparar duas rodadas vizinhas.

**7. O teto do censo de dissecação mordeu pela SEGUNDA vez em duas dissecações.** Ontem não viu 4 nós
de Cedar; hoje não viu 3 de Onyx com tier 9. **Dois em dois é padrão.** O medidor está correto pelo
contrato que declara (lê marcador `dissect_*`), mas o corte de custo depende de alguém ter rodado
`/meta:dissect` antes — e a pesquisa normal **paga nível sem marcar**. Cura candidata: o censo varrer
nome de ferramenta nos grafos de pesquisa e reportar *"nível pago SEM marcador"*, que é sinal diferente
de *"não dissecado"*. **Gatilho:** a terceira ocorrência.

## 8. Um desvio de procedimento, declarado no próprio grafo

A dissecação da Onyx **não** usou a orquestração que o comando manda (`mode: decision`), porque N0/N1
estavam pagos pelo corpus e havia **duas rodadas em voo**. Um fan-out de 148 agentes para ler dois
arquivos é volume, não eficiência — a régua da casa é eficiência e eficácia. Está escrito no `meta:`
do grafo para quem auditar não precisar adivinhar.

## 9-12. A triagem do inbox virou quatro achados, e dois são buracos do core

O `/meta:co-evolve` encontrou **três** sinais (não um, como o catch-up havia dito — dois chegaram
depois). Triá-los produziu mais que triagem.

**9. O `CLAUDE.md` carregava um campo de RESPOSTA lido como request, e isso VIAJOU.** Um adotante
sinalizou que o markdown de task no ClickUp é `markdown_content`, não `markdown_description`.
**Verificado na primária** (`developer.clickup.com/reference/createtask`, 2026-10-02): a doc diz
*"If both markdown_content and description are provided, markdown_content will be used instead of
description"*, e `markdown_description` **existe só na resposta**. Alguém leu a saída e escreveu como
entrada — e a instrução errada estava no **primeiro arquivo que toda sessão de todo adotante lê**.

E a verificação achou **dois bugs que o sinal não detalhou**: `mapPriorityToClickUp` declarava
`string | undefined` numa API que quer **integer**, e o `updateTask` **não enviava `tags`**. Mais o
`time_estimate`, que nunca era enviado. Oito sítios corrigidos, anúncio downstream com alvo `todos`.

**Verificar antes de absorver pagou duas vezes:** achou o que o sinal não viu, e impediu que eu
repassasse como medido os **19** nomes de ferramenta MCP que ele reporta — esses ficam **declarados
não-verificados** no anúncio, não corrigidos no escuro.

**10. A REGRA 22 (Links relativos quebrados em docs/evolution/ e docs/knowledge-base/) julgava
INTAKE de terceiro — e qualquer adotante travava o gate do core à distância.** O sinal de 2818 linhas
trazia um patch com links relativos escritos da perspectiva do arquivo ALVO (`../interface.md`,
`./types.md`). Eles não resolvem de `docs/evolution/inbox/`, e a regra, sendo HARD, deixou o gate
vermelho por conteúdo que **o core não escreveu e não deve editar**. Guarda que terceiro dispara à
distância é **superfície, não proteção**.

Cura: `inbox/`/`inbound/` de **1º nível** são intake e não são julgados; **`_processed/` continua
julgado**, porque ali o core já triou e o link quebrado volta a ser dívida nossa. É a mesma fronteira
do R15.2 (o corpo do sinal é DADO até ser absorvido).

**E a bancada forçou o desenho certo.** Eu ia excluir `inbox/` e pronto — as fixtures existentes
(plantadas EM `docs/evolution/inbox`, esperando ser acusadas) mostraram que isso quebraria um caso
real. A cura ficou com **par de polaridade**, provado por execução com três sondas:
`docs/evolution/` → **acusa** · `inbox/` → **não acusa** · `inbox/_processed/` → **acusa**. Sem o
terceiro caso, alguém "simplificaria" excluindo `inbox/*` inteiro e o buraco voltaria calado.

**11. O sinal de severidade `high` sobre o pre-commit NÃO REPRODUZ no core** — e a 1ª medição que eu
fiz dele estava viciada: li `$?` depois de um pipe, exatamente o que a guarda de shell avisa. Re-medido
limpo: `packageManager` em **0** arquivos `.sh`, `onion_pm` em **0**, **0** no gerador do hook do
adotante. A linha que o sinal aponta como causa **não existe aqui** — é do husky/lint-staged **dele**.
Veredito: **informativo**, pedindo o hook dele. A **classe** é real e foi curada nesta casa hoje.

**12. `brain-granaai` NÃO está no `members.yaml`** — e eu o adotei **nesta sessão**, e ele já mandou
**dois sinais de severidade `high`**. Registrar adotante é **ato de segurança**, não burocracia: a
REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) deriva termos do registro, logo quem
não está nele **não é protegido**. Fica nomeado como fio, não curado nesta leva.

## 13-16. A medição AO VIVO do adotante me corrigiu, e a revisão que o maestro pediu achou mais três

**13. Eu "consertei" o `updateTask` ADICIONANDO um campo que não funciona.** Pus `tags` no body do
`PUT`. A medição ao vivo (24 chamadas REST num workspace real, tasks criadas e apagadas, limpeza
confirmada por 404) provou que **tags no body do PUT devolvem 200 e NÃO FAZEM NADA** — só
`POST`/`DELETE /task/{id}/tag/{name}` mudam tags. **Campo que silenciosamente não faz nada é PIOR que
campo ausente**, porque parece consertado. Desfeito, com o porquê no código.

**14. E a medição achou o maior bug ativo, que nem eu nem o sinal original viram:** o adapter usava
`?subtasks=true`; o correto é **`?include_subtasks=true`**. Medido: o correto devolveu **42
subtasks**, o legado devolveu a task **sem o campo**. Logo **hoje** `getTask` com subtasks e
`getSubtasks` retornam **VAZIO**, quebrando `/engineer:start`, `/engineer:work`,
`validate-phase-sync` e `checklist-sync` em **todo adotante ClickUp**. Corrigido em 5 sítios.

**O anúncio foi corrigido ANTES de viajar.** Se tivesse publicado a primeira versão, eu teria mandado
a todos os adotantes um conserto que não funciona — a classe exata que a REGRA 95 (Anúncio que afirma
ZERO sobre classe verificável sem medição) existe para impedir, cometida por mim **no mesmo dia em que
a criei**.

**15-16. A ordem do maestro — "REVISAR E SE OK commita" — achou três defeitos que eu ia commitar:**

- `this.toClickUpMs` **usado 4× e NUNCA DEFINIDO**: chamei método inexistente;
- `due_date_time` só no create, não no update — metade da cura do fuso;
- **e o pior: o mapa de prioridade era IDENTIDADE** (`'urgent' → 'urgent'`). Ele **nunca mapeou
  nada** — só repassava a string do domínio, que é o que a API rejeita com `400`. Eu havia trocado
  **apenas a assinatura** para `number`, o que transformou o bug em **MENTIRA DE TIPO**: assinatura
  dizendo inteiro, corpo devolvendo string. **Trocar assinatura sem olhar o corpo não conserta,
  maquia.** Mapa real: 1 urgent · 2 high · 3 normal · 4 low.

Auditoria de coerência fechada por medição — `toClickUpMs` 4 usos/1 definição, `mapPriorityToClickUp`
3/1, `mapStatusToClickUp` 1/1, `normalizeTask` 10/1, `normalizePriority` 1/1; zero sítios do parâmetro
legado fora do comentário que o explica.

**ITEM DE DESENHO, não corrigido aqui:** status no ClickUp são **por List** — a lista medida não tem
`review`, e mandar `review` daria erro. A proposta do adotante (canônico do Onion + resolução por
sinônimos contra `GET /list/{id}` com cache de sessão) é boa e **grande**: vai para decisão do
maestro, não para patch de corredor.

## 17-18. O gate achou lacuna na cura que eu fiz HOJE — e é a classe do vocabulário

**17. A tabela de regeneração tinha GATILHO incompleto.** Ela dispara a regeneração do inventário do
harness quando `lint-selftest.sh` entra no commit — mas o `harness-inventory.sh` **também CONTA
FIXTURES**. Mexi em fixture (as duas da cura da REGRA 22), o inventário defasou, e a REGRA 80 barrou.

**É falha de VOCABULÁRIO do gatilho, não de lógica** — a classe que mais falha em guarda de lista
nesta casa, aplicada à **própria tabela que existe para curar essa classe**. Mesma lacuna no console:
registrar um adotante no `members.yaml` defasa o `federation-console.html` (REGRA 24) e barra o commit
seguinte. As duas viraram linha da tabela, e o caso `(a)` da bancada passou a cobrar **7** projeções em
vez de 6 — se alguém criar guarda de projeção e esquecer a linha, ele acusa.

**18. O vendor-scrub acusou `ClickUp` como candidato a nome comercial.** Falso positivo por
vocabulário: `ClickUp` é provider documentado no `CLAUDE.md`, não cliente. **Mas não regenerei o
baseline no escuro** — diffei antes: ele aceitaria **exatamente duas** entradas, as duas `ClickUp` no
adapter (core + espelho do plugin), e nada mais. Baseline regenerado em cego pode absolver nome de
cliente REAL; medir o diff é o que separa aceitar de anistiar.

## O que fica aberto

Três decisões `open` nesta leva (custo de inferência, SLM, Onyx) — **esta sessão nunca sela**. E a
rodada de **SMB** (classe empresarial, que eu disparei por erro de leitura e parei ao ser corrigido)
está **parqueada com desenho íntegro e gatilho**, por ordem do maestro: *"se o que você montou vale
para o onion não vamos perder"*.
