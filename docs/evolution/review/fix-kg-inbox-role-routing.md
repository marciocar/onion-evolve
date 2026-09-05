---
title: "Revisão — a I3 é fronteira de REPO, não de papel: duas rodadas adversariais REPROVARAM a cura antes dela ficar de pé"
date: 2026-09-05
branch: fix/kg-inbox-role-routing
reviewer: "2 refutadores independentes (opus, mandato de REFUTAR, default REPROVADO na dúvida): eixo mecânico (helper, extração, fragilidade da guarda, fail-open) e eixo doutrinário (I3 no corpus, origem da guarda descartada, fronteira core-vs-adotante, conformidade dos nós, veracidade da triagem). Duas rodadas: a 1ª reprovou a cura, a 2ª reprovou as guardas da cura."
reviewed_diff_sha256: dac011412c1a91bba1dfb3e09d38e5863be9a6b88d427e57161e5df38cf336cf
findings_total: 11
findings_real: 9
verdict: APROVADO
tokens: 0
duration_min: 38
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

## Como este resíduo difere dos irmãos

O gate mecânico esteve **verde nas duas rodadas** (`lint-artifacts` 0 HARD, bancada 1042/0, radar exit 0).
Os nove achados reais são todos **invisíveis ao gate** — e quatro deles são defeitos **das próprias
guardas** que este PR criou. Foi o Elenxo que impediu a entrega de uma meia cura com selo de completa.

## Achados REAIS (9)

### Rodada 1 — a cura era metade
1. **Roteava só a PORTA.** O `Passo 1` roteava por papel, mas o `Passo 3 (a)` — que o próprio comando
   chama de "o filtro mais importante" — perguntava só pelo core e mandava REJEITAR "contexto de negócio
   de adotante", isto é: o adotante passava a porta e era recusado no filtro seguinte, pelo mesmo
   conteúdo que é a razão de existir da fila dele. O `Passo 4` fixava o alvo na convenção do core
   (medido: nenhum adotante local usa `docs/onion/graph/`) e o `Passo 5` só conhecia nó do core.
   **CONFIRMADO** por leitura + medição própria. Curado: pergunta "mora NESTE repo?" instanciada por
   papel; alvo descoberto por `git ls-files '*.kg.yaml'`; `Passo 5` carimba nó deste repo.
2. **`meta.target` era campo FANTASMA.** A invariante que eu escrevi pendia de um campo que nenhum
   produtor emite — as duas propostas reais do corpus trazem `meta:` sem ele; o produtor MCP valida só
   `nodes:`. Prosa inexequível. **CONFIRMADO.** Reancorada no ATO: o que se prova é que o grafo-alvo
   escolhido resolve dentro deste repo.
3. **`Q_TENANT_WRITE_DESTINATION` ficou órfão** e o gatilho declarado dele ("2ª proposta de tenant **ou
   decisão de desenhar o roteamento**") disparou com este PR. **CONFIRMADO.** Apendado
   `E_KG_INBOX_ROTEIA_POR_PAPEL_0905` + `CONSTRAINS`: fecha a metade do tenant COM repo próprio, nomeia
   a que fica aberta. O `Q_` segue `open` — estreitar o label é flip de status, e flip é selo do maestro.

### Rodada 2 — as guardas da cura eram fracas
4. **A guarda decidia por VOCABULÁRIO.** Três mutantes passavam verdes: a recusa original sem `|hub`,
   `pare` em vez de `parar`, e uma reescrita ("este comando não roda aqui") que ainda autorizava selar
   grafo de outro repo. **CONFIRMADO com o texto do mutante em mãos.** Reancorada na ESTRUTURA (a linha
   da tabela do papel `adopted` nomeia a fila que sela) + recusa barrada na forma diretiva + proibição de
   autorizar grafo alheio. Os quatro mutantes reprovam; o pior deles por três contagens independentes.
5. **A guarda casava com a própria NOTA HISTÓRICA** que citava a pergunta antiga — guarda de string não
   distingue regra de citação. **CONFIRMADO** (o caso reprovou o arquivo correto). A nota passou a
   descrever, não citar.
6. **Duas asserções CONFLACIONADAS** — a frase do `Passo 1` cobria a ausência da guarda no `Passo 4`, e
   dois mutantes passaram verdes por isso. **CONFIRMADO.** Cada asserção ancora em string distinta, na
   seção dela.
7. **Fail-open na criação da fila** — a chamada do starter não lia rc; um DEST somente-leitura faria a
   adoção seguir e o adotante nascer sem fila. **CONFIRMADO por execução** (`rc=1` medido depois da cura).
   O helper confere o próprio efeito e o chamador aborta; caso `(d2)` mede isso.
8. **Fatia por sentinela alheia** — renomear o comentário do bloco vizinho fazia a extração engolir 521
   linhas do `adopt.md` (falhava por acidente, via backtick desemparelhado). **CONFIRMADO por medição.**
   Agora exige teto de linhas + a chamada do helper.
9. **CARTA MORTA — o achado do lote, e fora do meu escopo declarado.** O adotante remetente não estava
   no `members.yaml` nem tinha `outbox/`: as 6 triagens estavam em 2ª pessoa e não tinham como chegar.
   **CONFIRMADO** (`grep` no registro + 14 diretórios de outbox, nenhum do remetente). Registrado com
   pin verificado, projeções regeneradas, anúncio na staging — e o registro acendeu a REGRA 36
   (Superfície VENDORIZADA sem nome comercial de cliente) em 5 arquivos, generalizados.

## Achados REFUTADOS por medição própria (2)

- **"O PR reabre um buraco fechado"** (hipótese doutrinária): medido com `git log --follow` — a guarda de
  papel nasceu junto com o comando em `f7357385`, como guarda do CORE ("a sessão do core não sela grafo
  alheio"), não de um incidente de adotante. O erro foi expressar fronteira de REPO como checagem de
  PAPEL. Nada fechado é reaberto.
- **"9 sinais respondidos para dentro"**: são **6**, e os 3 do PR irmão estão entre eles. Sinal de agente
  é declaração, não medição — a contagem errada quase entrou no anúncio ao adotante.

## Limite declarado (o que este PR NÃO prova)

- A guarda `(e)` incide sobre um **comando em markdown**: prova a FORMA do comando, não o comportamento
  do modelo que o lê. O que é EXECUTADO de verdade na bancada é o starter, nos casos `(d)`/`(d2)`.
- O dogfood do caminho completo `/meta:kg-inbox` **num repo adotado** não foi rodado (exigiria escrever
  repo alheio — I3/MOAT). O que se mediu no adotante foi leitura. **Gatilho:** o adotante rodar
  `/meta:adopt --update` e depois `/meta:kg-inbox`, e comparar com o `/portal:selar` dele — o anúncio
  pede essa comparação de volta.
- `tokens: 0` porque o custo dos dois refutadores não foi instrumentado nesta rodada (não havia run de
  workflow com journal); `duration_min` é medido do relógio da sessão. Declarado em vez de estimado.

## Fora de escopo (com gatilho)
- Estreitar o label do `Q_TENANT_WRITE_DESTINATION` — flip de status, selo do maestro.
- Transporte automático core→fila-do-dono para proposta que pertence a outro repo (a metade aberta).
- Entregar o anúncio no `inbound/` do adotante — escrever repo alheio é do maestro (MOAT).
