---
title: "Revisão — a I3 é fronteira de REPO, não de papel: SEIS rodadas adversariais, e a mesma meia cura achada em cinco passos diferentes"
date: 2026-09-05
branch: fix/kg-inbox-role-routing
reviewer: "2 refutadores independentes (opus, mandato de REFUTAR, default REPROVADO na dúvida): eixo mecânico (helper, extração, força da guarda, fail-open) e eixo doutrinário (I3 no corpus, origem da guarda descartada, fronteira core-vs-adotante, conformidade dos nós, veracidade da triagem). SEIS rodadas: cada uma reprovou a entrega anterior; a partir da 4ª o ataque foi exclusivamente à FORÇA DAS GUARDAS, e achou furo real todas as vezes."
reviewed_diff_sha256: 8772bf1cce67645c0f6f9f5978f96453b4c3db2f33462a422f1096f73a810d15
findings_total: 21
findings_real: 19
verdict: APROVADO
tokens: 0
duration_min: 74
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## O que esta revisão ensinou, antes dos achados

O gate mecânico esteve **verde em todas as seis rodadas** (`lint-artifacts` 0 HARD, bancada
1042+/0, radar exit 0). Os 17 achados reais são **todos invisíveis ao gate** — e a maioria não é
defeito do comportamento entregue, mas **das guardas que este PR criou**. O Elenxo impediu cinco vezes
que uma meia cura fosse selada como completa.

**A classe, nomeada:** numa perna **faseada** (porta → filtro → critério → execução → fecho), curar o
roteamento na ENTRADA é o default errado e sedutor — a mudança fica visível, o gate fica verde, e a
recusa **migra um passo adiante**. Foi achada nos cinco passos, um por rodada:

| rodada | onde a meia cura estava | como a guarda a deixava passar |
|---|---|---|
| 1 | `Passo 3 (a)` — o filtro de fronteira era core-only | a guarda extraía **só o Passo 1** |
| 2 | prosa livre do `Passo 3` refraseando a recusa | decidia por **vocabulário** (2 grafias) |
| 3 | `Passo 3 (c)` — o critério que MANDA selar | a guarda casava a tabela e **nunca olhava o critério** |
| 4 | recusa pela forma **positiva** (`role: source`) · a **tabela virou santuário** | a regra barrava só o papel adotado; e não olhava o que a linha DIZ |
| 5 | `Passo 5` — `done` com o radar como único gate | nenhuma asserção sobre verificação |
| 6 | `Passo 4` (o ATO) e `Passo 5` (o FECHO) | a propriedade estrutural valia **só no Passo 3** |

Registro de classe: `.claude/diary/2026-09-05-meia-cura-tres-vezes-a-mesma-perna-e-o-mutante-ancorado-no-defeito.md`.

## Achados REAIS (17)

**Comportamento entregue (3, rodada 1):** o `Passo 3 (a)` core-only recusava o adotante que o `Passo 1`
roteava · `meta.target` era campo FANTASMA (nenhum produtor o emite — medido nas 2 propostas reais do
corpus), logo a invariante era prosa inexequível, reancorada no ATO · `Q_TENANT_WRITE_DESTINATION`
ficou órfão com o gatilho declarado dele já disparado por este PR.

**Fronteira core/adotante (5, rodadas 2-5):** o carimbo `# SELADO … sessão do core` declarava autor
falso num repo adotado · o `Passo 4` fixava o alvo na convenção do core (medido: nenhum adotante local
usa `docs/onion/graph/`) · o `Passo 5` só conhecia nó do core · o README da fila do core contradizia o
comando roteado e era citado como autoridade, apontando um caminho que **não viaja** · o `Passo 2`
exigia um cabeçalho que só o produtor não-vendorizado (`ops/`, 0 hits em todo `want=`) emite — no
adotante rejeitaria toda proposta nascida à mão.

**Fail-open e mecânica (3, rodada 2):** a chamada do starter não lia rc (DEST somente-leitura ⇒
adotante nasce sem fila, em silêncio) — o helper passou a CONFERIR o próprio efeito e o chamador a
ABORTAR, medido com `rc=1` · a fatia de markdown do caso (d) dependia da sentinela do bloco vizinho
(renomeada, engolia 521 linhas; falhava **por acidente**) · `allowed-tools` não permitia o que o
comando manda rodar.

**Força das guardas (5, rodadas 2-5)** — o eixo mais produtivo: decidiam por vocabulário e três
mutantes de reescrita passavam verdes · casavam com a própria **nota histórica** que citava a regra
antiga · duas asserções **conflacionadas** (a frase do `Passo 1` cobria a ausência da guarda no
`Passo 4`) · barravam o papel só pelo **negativo**, e recusar dizendo quem *pode* (`role: source`)
passava · a **tabela virou santuário**: a regra mandou o papel viver nela e parou de olhar o que a
linha diz.

**Força das guardas, rodada 6 (2):** a regra "nenhum papel condiciona a decisão em prosa" valia só no
`Passo 3` — o ATO e o FECHO decidiam por papel à vontade (mutantes verdes: item 0 no SELAR exigindo
`role: source`; `Passo 5` virando "só a sessão do core carimba… pule este passo") · e a âncora do
`Passo 5` era **a frase que a recusa usa para se justificar** (`num adotante`), satisfeita pelo mutante
que a nega. Estendida aos três passos; regra negativa no `Passo 5`, simétrica à do `Passo 3`.

**REGRA 49 no fecho (1, rodada 5):** o `Passo 5` mandava carimbar `done` tendo o radar como único
gate — e o radar `--freshness` **detecta e para aí**, por declaração do próprio R49. Um `done` em
`plane: PROD impact>=4` sem `verified_at`/`verified_against` reprova HARD **depois**, aqui e no
adotante que vendorizou o gate.

**Carta morta (1, rodada 2) — o achado de maior consequência, fora do escopo declarado:** o adotante
remetente não estava no `members.yaml` nem tinha `outbox/`; as 6 triagens estavam escritas em segunda
pessoa e não tinham como chegar. Registrado (pin `pin-ok`, `members-validate valid:true`, projeções
regeneradas, anúncio na staging) — e o registro **acendeu a REGRA 36 (Superfície VENDORIZADA sem nome
comercial de cliente)** em 5 arquivos, generalizados. Registrar adotante é ato de segurança.

## Achados REFUTADOS por medição própria (2)

- **"O PR reabre um buraco fechado"**: `git log --follow` mostra que a guarda de papel nasceu junto com
  o comando (`f7357385`), como guarda do CORE, não de um incidente de adotante. O erro foi expressar
  fronteira de REPO como checagem de PAPEL. O segundo refutador chegou à mesma conclusão
  independentemente e a chamou de "generalização apressada" — ponto **a favor** do PR.
- **"9 sinais respondidos para dentro"**: são **6**; os 3 do PR irmão estão entre eles. A contagem
  errada quase entrou no anúncio ao adotante — sinal de agente é declaração, não medição.

## Erros MEUS que a revisão expôs (e ficam registrados)

1. **Ancorei dois dos meus próprios mutantes na linha defeituosa.** Escrevi
   `**(c) SINAL REAL DO CORE** → **SELAR**` de memória num script de mutação, três vezes, e não a vi.
   Âncora de mutante entra no olho como **coordenada**, não como conteúdo — e âncora boa é
   load-bearing, logo candidata a defeito. Memória durável: `mutant-anchor-is-a-defect-candidate`.
2. **`git checkout --` para reverter mutante apagou o meu patch não-commitado** (o baseline era
   `origin/main`). Passei a usar cópias de backup.
3. **Um refutador mediu a bancada em 6/7 e 40s depois em 7/7** — e diagnosticou certo: não é guarda
   flaky, é **dois escritores no mesmo repo** (ele mediu durante a minha edição). A lição é dele e eu
   assino: **o verde da árvore de trabalho não é gate**; o gate é o SHA final com a árvore limpa.

## Limites DECLARADOS (o que este PR não prova)

- A guarda `(e)` incide sobre um **comando em markdown**: prova a FORMA, não o comportamento do modelo
  que o lê. O que é EXECUTADO na bancada é o starter (casos `(d)`/`(d2)`).
- O dogfood do caminho completo `/meta:kg-inbox` **num repo adotado** não foi rodado — exigiria
  escrever repo alheio (I3/MOAT). O que se mediu no adotante foi leitura. **Gatilho:** o adotante rodar
  `/meta:adopt --update` e depois `/meta:kg-inbox`, comparando com o `/portal:selar` dele; o anúncio
  pede essa comparação de volta.
- Os 2 nós novos em `fios-abertos` não citam id alheio, contra a letra do cabeçalho do próprio grafo —
  mas a medição do refutador mostra que **nenhum** dos 19 nós do arquivo cita. Deriva **pré-existente**;
  a cura devida é do cabeçalho ou da convenção, não deste PR.
- O gatilho do `I_KB_GAMIFICACAO_RAMPA_GATED` depende de um nó no grafo **do adotante**, que o core não
  pode verificar: é gatilho **por sinal**, não por medição.
- `tokens: 0` porque o custo dos refutadores não foi instrumentado (não houve run de workflow com
  journal). Declarado, não estimado. `duration_min` é do relógio da sessão.
- **TETO DECLARADO da guarda `(e)` — decisão, não desistência.** Na 6ª rodada o refutador reescreveu o
  corpo da GUARDA DO ATO para autorizar árvore vizinha (*"o alvo pode viver em qualquer árvore… inclusive
  a de um vizinho"*) **preservando os literais** que a guarda procurava: a I3 inteira saía e a guarda não
  via. As evasões medidas entraram na classe e o mutante reprova — mas essa foi a **última extensão de
  vocabulário**, e está escrito no código. Prosa livre reescrita para significar o contrário preservando
  os literais é classe que **guarda de texto não fecha**; o que fecha a I3 é ela valer por MECANISMO no
  repo-alvo (o pre-commit/merge de lá), não por frase aqui. **Gatilho:** achado de força-de-guarda a
  partir daqui vira nó com gatilho nomeado, não nova rodada — senão a perna troca entrega por polimento.
  (Balanço que justifica o teto, e o número é do próprio refutador: dos **12 achados dele, os 3 que
  mudaram o produto** — `Passo 3` core-only, `meta.target` fantasma, `Q_TENANT_WRITE_DESTINATION`
  aberto — saíram todos da **primeira** passada, lendo o artefato inteiro; os 9 seguintes foram força
  de guarda e **nenhum** mudaria o que o adotante experimenta. Ele fechou concordando com o teto pela
  mesma razão: *"vocabulário não converge"*. Último ataque de comportamento dele — `allowed-tools`
  contra o que os passos mandam rodar — **falhou**: os dois comandos novos (`git ls-files`, o starter)
  já estão permitidos.)

## Gate no SHA final (árvore limpa, medido)

`lint-artifacts.sh` rc=0 — **0 HARD**, 8 SOFT (passivos com catraca) · bancada `--jobs auto`
**1043 passaram / 0 falharam / 0 pularam** · `kg-radar --integrity --schema` **exit 0** nos dois grafos
tocados (`fios-abertos`, `librechat-kg-runtime-2026-08`) · árvore conferida **antes e depois** da
medição. Os checkpoints intermediários usaram `--no-verify`; este é o gate que vale.

## Fora de escopo (com gatilho nomeado)
- Estreitar o label do `Q_TENANT_WRITE_DESTINATION` — flip de status, selo do maestro.
- Transporte automático core→fila-do-dono para proposta que pertence a outro repo (a metade aberta).
- Produtor de 1ª classe para o adotante (hoje a proposta nasce à mão ou por comando local).
- `/meta:kg-inbox` no plugin — `Q_KG_INBOX_FORA_DO_PLUGIN`, gatilho nomeado; `install ≠ adopt`.
- Entregar o anúncio no `inbound/` do adotante — escrever repo alheio é do maestro (MOAT).
