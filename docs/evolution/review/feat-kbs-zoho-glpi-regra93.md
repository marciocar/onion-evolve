---
branch: feat/kbs-zoho-glpi-regra93
reviewed_diff_sha256: e8204ab37911c985552f9ef25eb08cb294770e8c8952eb6e31b5236d059ecc37
elenxo: sim
verdict: REPROVADO_E_CURADO
findings_total: 18
findings_real: 17
tokens: 245457
duration_min: 25
nota: "Refutador opus/high em worktree isolada, mandato REFUTAR, default REPROVADO, COM as credenciais do portal real. 4 BLOQUEANTES, 3 IMPORTANTES, 6 MENORES, 3 lacunas declaradas. Ele sondou a API por conta propria e derrubou o achado central do adapter: createSubtask nao funciona por caminho nenhum, e eu havia aceitado um 201 como prova — violando a regra de desenho do proprio arquivo. Re-medi os dois bloqueantes de API antes de curar; os dois confirmaram. 1 achado (applies_to que mede o binario e nao a KB) ele mesmo mediu e classificou como salvo pela 2a clausula do campo."
---

# Resíduo da passada adversarial — adapter Zoho + REGRA 93

Refutador `opus`, mandato **REFUTAR**, default **REPROVADO na dúvida**, em worktree isolada e **com
acesso ao portal real** (`pass zoho/projects/*`). Veredito: **REPROVADO**. Os quatro bloqueantes eram
reais, e dois deles eu re-medi por conta própria antes de curar — não se conserta desenho de API por
relato de terceiro.

## Os bloqueantes

| # | achado | evidência (medida, e por quem) | cura |
|---|---|---|---|
| **B1** | `createSubtask` **não funciona por caminho nenhum**, e o adapter prometia que funcionava na V2 | ele e eu, em rodadas independentes: V2 `POST …/tasks/` com `parent_task_id` → **201 e task RASA** (`isparent: False`, nenhuma chave de pai); `GET /tasks/{pai}/subtasks/` → **204 vazio**; pai e filha ambos `depth: 0`; as três formas V3 (`parent_task`, `parent`, `parent_task_id`) → **400 `Enter a valid custom field`** | o membro passou a **RECUSAR** com `ZOHO_SUBTASK_WRITE_NOT_EXPOSED`, com a tabela de medições no lugar da promessa |
| **B2** | a armadilha de configuração estava **INVERTIDA** — e é o primeiro aviso que o leitor obedece | minha sonda: V2 responde **200 com o id do PORTAL** e **404 `6504 Domain Not Available`** com o `login_id`; o envelope V2 traz `login_id` **no topo**, igual ao `owner.id` da V3 — é o **usuário** | as duas versões usam o mesmo id; corrigido nos **7 arquivos** onde a frase falsa havia se propagado |
| **B3** | o bloco da REGRA 93 entrou **entre o header da REGRA 85 e a função dela** — a 85 ficou órfã e o registro gerado passou a publicar **HARD** onde ela é **HARD + SOFT** | parser real (`rules-registry.sh`): `REGRA 85: fn=None`; a projeção mudou de `HARD + SOFT` para `HARD` e o rodapé fechou a aritmética (80/29 em vez de 80/30) | bloco movido; e **catraca nº6** no gerador reprova regra órfã (`exit 2`), com as duas isenções (40, 86) declaradas COM razão |
| **B4** | ids do portal vivo em **três raízes que viajam**, inclusive o canal público de plugin | `--emit-scrub-roots` confirma que `.claude/utils`, `docs/knowledge-base` e `plugins` viajam; e o único projeto do portal chama-se com o nome comercial do adotante | ids trocados por marcadores; e o **nome comercial registrado em `client-terms.txt`** — o slug neutro fechava a projeção e **desligava a busca** |

**O B1 é o achado que mais ensina**, e não pelo endpoint: eu aceitei um **`201`** como prova de
vínculo no **único ponto onde o arquivo faz uma promessa positiva** — depois de escrever, no topo do
mesmo arquivo, *"verifique no corpo da resposta, nunca no código HTTP"*. A regra estava certa e quem a
escreveu não a aplicou a si.

**O B3 é reincidência de classe, e agora tem mecanismo.** O mesmo modo-de-falha aconteceu em
2026-08-03 e a cura de então foi **conselho** no comentário do lint ("mova o docstring para junto da
sua função"). Repetiu duas vezes hoje. A catraca nº6 foi provada por mutação: um header órfão
plantado antes da REGRA 85 devolve `exit 2` nomeando a regra.

## A bancada era decorativa — 8 de 9 mutantes sobreviviam

O achado mais útil do refutador não foi um defeito do adapter, foi um defeito da **prova**: os 10 casos
eram `grep` de palavra no documento, e ele mediu que **um adapter com o texto certo e o endpoint errado
passava**. Inclusive o controle (remover um membro inteiro) sobrevivia — `getProject` casava **dentro
de** `getProjectList`, e a paridade cobria 14 dos 16 membros porque `provider` e `isConfigured` são
`readonly` e escapavam do regex.

Reescrita, e **provada por mutação**: das 9 mutações, **8 morrem**. As que faltavam morreram por duas
mudanças de método:

- **cobrar a FORMA medida, não a palavra** (`PATCH /projects/{projectId}/tasks/{taskId}`, `{"comment":`,
  `"tasklist":{"id"`, `"status":{"id"`, `"owners_and_work"`, a base com `portal/` singular);
- **escopar à SEÇÃO que decide**. Este foi o passo que eu não teria achado sem mutar: a regra em prosa
  da §1 cita as formas corretas, então um mutante que corrompia **só o exemplo da seção** sobrevivia — o
  documento passava a se contradizer e a guarda não via.

**Teto declarado**: o mutante que sobra corrompe um exemplo de **resposta** fora da seção que decide.
Não estendi a lista — daí em diante cada caso cobre um trecho a mais do mesmo documento, que é
força-de-guarda, não achado. Gatilho para voltar: alguém errar em uso real por seguir um exemplo.

## O caso (j) caiu pela classe que veio curar

A paridade de vocabulário nasceu porque eu havia declarado "9 pontos ligados" **por menção** e o tipo
`TaskManagerProvider` não tinha `'zoho'`. A cura foi uma **lista digitada de 8 caminhos** — e o
refutador mostrou que ela falhou igual: **7 sítios operacionais ficaram fora**, entre eles o
`@task-specialist` (a quem o `CLAUDE.md` roteia o Zoho, dizendo que atende "Asana e Linear"), o
`description:` do `/product:task`, os **dois** `onion` (só a skill tinha sido atualizada, de três) e a
**segunda** declaração da união em `interface.md` — `types.md` foi curado, esta não.

Agora a varredura é **derivada**: arquivo rastreado de `.claude/` + `CLAUDE.md` que **enumera**
providers (cita 3+ dos existentes — assinatura de enumeração, não a palavra solta) tem de citar os
novos. Fora do escopo por razão escrita: `diary/` (snapshot histórico não se reescreve), `vendor/`,
baselines. **25 sítios curados**, 1 isento com razão (o comparativo de assignee do Asana). A guarda
SDAAL também passou a nomear `mcp_zoho_`: a Zoho não tem MCP oficial, e guarda que não nomeia o
provider novo nasce cega justamente para o caminho que alguém tentaria por não existir o oficial.

## REGRA 93 tinha fail-open, e o commit que a criou entregava o artefato que ela descreve

- `applies_to: ""`, `TBD` e `?` **passavam todos**. Cobrar a presença do campo sem cobrar **conteúdo** é
  a mesma brecha um nível adiante. O predicado agora é **versão tem dígito**, com a única saída sendo
  declarar a não-medição em voz alta — não uma lista de placeholders, que envelheceria no vocabulário.
- `find -maxdepth 1` deixava subpasta de fora. Hoje não existe nenhuma, então a cura **não muda um byte**
  do resultado — fecha uma porta antes de alguém entrar por ela.
- `printf '%s\n' "${missing[@]}"` com array vazio imprimia **uma linha vazia**, contada como isenção: o
  passivo nunca chegaria a zero e a "métrica de saúde é esta lista encolhendo" seria mentira no último
  passo dela.
- A medição do header estava errada: **1 das 10** KBs já declarava o campo (`librechat-agent-mcp.md`),
  não zero. O número menor **reforça** a regra — a convenção nasceu no uso antes de virar guarda.
- `patterns/glpi-zoho-ticket-to-task.md` documenta dois produtos de terceiro e **não tinha frontmatter
  nenhum**: o commit que cria a regra entregava, dentro da letra dela, exatamente o artefato que ela
  descreve. Ganhou o bloco e o campo; e o que fica **fora da varredura** está escrito, com gatilho.

## Menores, curados

- a tabela de erro afirmava que `INVALID_PARAMETER_VALUE` **prova que o campo existe** — medido: em
  `/tasks`, uma chave **inventada agora** dá o mesmo erro. **Um erro de leitura produziu uma promessa de
  API**: foi essa inferência que me fez crer que `parent_task` existia, e daí que a V2 entregava subtask.
- "todos HTTP 200" era falso para as duas linhas de `POST` (**201**) — quem escrevesse `assert status ==
  200` quebrava nos dois casos de criação.
- `tasklist_id` plano dá **400**, não 200-e-ignora; a forma aceito-e-ignorado vale para `milestone_id`.
- `DELETE /projects/{id}` devolve `"error": [ … ]` — **array**, não objeto. É a §2 do arquivo aplicada
  ao canal de erro.
- o nó `E_BACKLOG_DO_GRAFO_JA_EXISTE` cravava "229 em 51" e a projeção do **mesmo commit** dizia 230 em
  52 — o nó invalidava o próprio número ao nascer, 4ª vez nesta classe. O número saiu do nó: a
  população vive na projeção, que se regenera.
- o `--map` da bancada não alcançava `.env.example` (regex só aceitava `.claude|ops|docs|…`), e isso
  **não** caía no failsafe: conjunto não-vazio + SUT de raiz = a família deixaria de rodar num commit
  que tocasse só o arquivo de raiz.
- `runflow.md` ficou com `version:` do alvo **e** `applies_to` — a ambiguidade duplicada que o campo
  existe para desfazer. O `version:` saiu, com a razão no lugar.
- a mensagem do caso (d) tinha backtick dentro de string dupla: o shell **comia a palavra `portal`**,
  justamente o termo que o caso existe para nomear.

## Lacuna que fica declarada

**"Não há MCP nativo da Zoho para Projects"** é **pesquisado, não medido** — nenhum servidor foi
instalado nem chamado. A linha importa porque é ela que justifica o transporte único contra o dual do
`linear.md`: se aparecer MCP oficial, a razão cai. Agora está escrito assim no adapter, com gatilho.

## O que este PR toca no grafo, e o que ele NÃO mexe

O PR edita `rito-task-manager-2026-09.kg.yaml` — e o único nó tocado é o
`E_BACKLOG_DO_GRAFO_JA_EXISTE` (dele saiu o número que se auto-invalidava). Os três `confirmed` de
maior impacto do arquivo **ficam como estão**, de propósito:

- **`E_WORKLOG_E_MECANISMO_MORTO`** — `resume_command` em 0 de 12 sessions, porque o hook resolve o
  slug por branch e nenhuma das 12 tem branch; e um dos dois hooks ainda carrega o filtro antigo. É a
  **Frente 2** do plano, que não entrou nesta leva: ressuscitar o mecanismo vem ANTES de escrever o
  resolvedor sobre ele.
- **`D_UMA_TASK_POR_FIO`** — selado pelo maestro no mesmo dia: a unidade é o **nó do grafo**, e o task
  manager é **projeção** dele, nunca segunda fonte. Este PR é coerente com isso justamente por tirar a
  **população** do nó: contagem vive na projeção, que se regenera.
- **`E_RITO_COMPLETO_CHAVE_QUEBRADA`** — o rito está completo em fases e gates; falta a chave única que
  o auto-localiza. Intocado: é o que a Frente 2 endereça (`resolve-session-slug.sh` + o `## Map`).

Nenhum deles é afetado pelo adapter nem pela REGRA 93 (KB de terceiro declara a QUE VERSÃO se aplica) —
e é por isso que esta leva pôde fechar sem abri-los.

## Gate no SHA final

`lint-artifacts.sh` → **0 HARD / 16 SOFT** (`rc=0`, varredura completa). Bancada: **15/15** na família
do adapter, com as 8 mortes de mutante medidas uma a uma e a restauração conferida por hash. O passivo
da REGRA 74 **encolheu** (119 → 117): a lista de um caminho nu por provider virou a forma `{provedor}.md`
que a própria página já usava, em vez de crescer o baseline a cada provider novo.
