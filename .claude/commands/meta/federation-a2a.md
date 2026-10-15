---
name: federation-a2a
description: |
  Configurador A2A em wizard: prepara o receptor, convida um membro, guia a entrada dele na rede,
  diagnostica os dois lados, aceita a fila e revoga — trilhas por papel, dry-run antes de toda escrita.
category: meta
tags:
  - federation
  - a2a
  - wizard
  - forge
version: "1.0.0"
updated: "2026-10-15"
related_commands:
  - /meta:federation-member
  - /meta:co-relay
  - /meta:co-evolve
allowed-tools: Read, Grep, Glob, Edit, Write, Bash, AskUserQuestion, TodoWrite
argument-hint: "[preparar|convidar|entrar|conferir|aceitar|revogar] [--member <id>]  (guiado se faltar argumento)"
---

# 🔐 /meta:federation-a2a — montar a rede A2A em trilhas, sem passo manual de shell

Leva o core e um membro da chave ao sinal aceito e à revogação, com o operador respondendo perguntas
em vez de digitar shell. Cada trilha **explica o passo**, mostra o **dry-run** antes de qualquer escrita
e termina no **doctor**. A doutrina inteira (as 8 cláusulas e o que o comando NÃO promete) vive em
[`common:prompts:federation-a2a-doctrine`](../common/prompts/federation-a2a-doctrine.md). **Referencie, não copie.**

**Por que existe:** pedido do maestro em 2026-10-14 (configurador completo, em wizard), forjado pelo
`/meta:forge` em 2026-10-15 (F1 do programa, SAC-122). Plano, spike e decisões no grafo do programa,
core-only: `docs/evolution/research/a2a-configurator-2026-10/` (no adotante não existe).

## Degrau e limites

- **Roda na fonte e no hub** (conjunto `adoption` do `roles.yaml`, ao lado do `/meta:federation-member`):
  não viaja para standalone, plugins nem mini. Na F1 o receptor é o **core**; o hub como receptor dos
  próprios filhos é a F3.
- **O membro não precisa ter este comando:** a trilha 2 prepara um **pacote de entrada** com os três
  motores (keygen, remetente, doctor) e o roteiro da trilha 3, porque o membro adotado como standalone
  não recebe `.claude/utils/federation-transport/`.
- Maestro-invocado. **Não faz deploy**, não edita o ambiente do bridge, não reinicia serviço, não
  escreve em repo alheio e não aceita sinal sem confirmação explícita, um por um (MOAT e cláusula 4).
  Esta superfície não cita caminhos core-privados de operação (REGRA 100 (Superfície que viaja não cita
  ops/ como se o destinatário o tivesse)): o que é do deploy do bridge aparece como "o caminho de
  deploy do bridge do core", feito pelo maestro fora deste comando.

## Contexto medido injetado (peça 3 — o medidor roda ANTES de você pensar)

**Hoje:** !`date +%F`

!`bash .claude/validation/onion-version.sh 2>&1 | grep -E '^(role|kind):' || true`

!`bash .claude/utils/federation-transport/a2a-doctor.sh --selftest 2>&1 | tail -1 || true`

> ⚠️ **As linhas acima são diretivas de injeção — bang seguido de crase —, e o harness executa toda
> diretiva do arquivo.** Por isso a forma literal não aparece em mais nenhum lugar daqui: os comandos
> dos passos abaixo estão em blocos de código, que você roda. O `|| true` mantém a carga viva quando um
> medidor sai rc ≠ 0: a mensagem dele chega no texto injetado, e isso **é** a medição. O doctor
> completo de um membro roda no passo 1, com o `--member` que só a conversa conhece.

Leia o papel antes de oferecer trilha: `source` → trilhas 1 a 6 (o core é o receptor); `hub` → na F1,
só a 3 (entrar na rede do core) e a 4; as trilhas de receptor do hub chegam na F3. Outro papel → diga
que o comando não é deste papel e pare.

## Procedimento

1. **ORIENTAR.** Pergunte (AskUserQuestion) a trilha, com a recomendada primeiro e o porquê. Sem
   `--member` na invocação, pergunte o id. Rode o doctor do lado que cabe ao papel e mostre o resultado
   **antes** de propor qualquer escrita:
   ```bash
   bash .claude/utils/federation-transport/a2a-doctor.sh --side receiver --member <id>   # no core
   bash .claude/utils/federation-transport/a2a-doctor.sh --member <id>                   # na máquina do membro
   ```
   O doctor sai **0** saudável, **1** problema, **2** não pude medir, **3** uso inválido; cada checagem
   traz causa e próximo passo, e é o próximo passo dele que conduz a trilha.
2. **EXPLICAR e DRY-RUN.** Antes de cada escrita, diga em uma frase o que o passo faz e por quê, mostre
   o que vai mudar (o diff do registro, os arquivos do pacote, o envelope do envio de teste) e peça
   confirmação. Sem confirmação, nada se escreve.
3. **EXECUTAR a trilha** (abaixo). Um passo por vez, conferindo o rc de cada motor.
4. **CONFERIR.** Termine toda trilha no doctor do lado certo e reporte o rc e o que ficou não medido.
5. **REGISTRAR.** O que mudou no registro sai em commit do core pelo fluxo normal (branch, PR, merge
   verificado). O grafo do programa recebe o que a trilha revelou de novo.

### Trilha 1 — Preparar o receptor (core)
Confere a fiação do receptor sem tocar o serviço: registro válido pelo validador do gate,
`members.yaml[<core>].a2a` com `url` e `status`, relógio confiável e alcance do endpoint
(`--endpoint` com a URL do `a2a.url` do registro). O bridge servido (versão, ambiente, restart) é do
caminho de deploy do bridge do core: o wizard aponta, não executa.
```bash
bash .claude/validation/members-validate.sh
bash .claude/utils/federation-transport/a2a-doctor.sh --side receiver --member <membro-de-teste> --endpoint <a2a.url>
```

### Trilha 2 — Convidar um membro (core)
1. **Registro.** Membro novo → `/meta:federation-member register` primeiro. O bloco `a2a` dele nasce com
   `sends_to: <core>` e `keys: []` até a pública chegar.
2. **Pacote de entrada.** Copie para um diretório de entrega os três motores
   (`.claude/utils/federation-transport/a2a-keygen.sh`, `a2a-send.sh`, `a2a-doctor.sh`) e um
   `a2a.conf` com `member=`, `receiver=` e `endpoint=` (nenhum segredo). O pacote vai ao membro pelo
   canal combinado; o core não o instala na máquina dele (I3).
3. **Convite (F1).** O bearer do canal é gerado direto num arquivo 0600, nunca no chat:
   `( umask 077; openssl rand -hex 32 > <arquivo> )`. Incluí-lo no pool do bridge é do caminho de
   deploy do bridge do core (maestro). Entregue o arquivo fora de banda. O convite por membro, com
   validade e sem restart, é a F2.
4. **Pino**, quando a pública e a impressão chegarem (trilha 3, passo 2): confira a impressão por
   outro canal, grave a pública em `.claude/utils/federation-transport/jwks/<kid>.pem` (adição
   deliberada, `git add -f`), acrescente o `kid` em `a2a.keys`, rode o validador e o doctor do receptor
   com `--fingerprint`, e abra o PR. A confiança vale **quando o clone que o bridge serve recebe o
   merge**, pelo caminho de deploy do bridge do core (maestro): o bridge lê o registro e o JWKS desse
   clone, não do repo de trabalho, e o doctor daqui mede o repo onde roda. Merge sem deploy = pino que o
   bridge ainda não conhece.
   ```bash
   bash .claude/validation/members-validate.sh
   bash .claude/utils/federation-transport/a2a-doctor.sh --side receiver --member <id> --fingerprint sha256:<hex>
   ```

### Trilha 3 — Entrar na rede (o membro, na própria máquina)
1. Gere o par: `bash a2a-keygen.sh --member <id>`. Anote o `kid` e a impressão; a privada fica em
   `~/.config/onion/a2a/` (0700/0600) e não sai dali.
2. Mande ao core **só** a pública (`<kid>.pem`) e diga a impressão por outro canal. O `a2a.conf` do
   pacote é um **lembrete legível** (id, receptor, endpoint): nenhum motor o lê, os valores vão nas flags. Se o membro é
   adotante com o carteiro upstream, a pública vai pelo `/meta:co-relay` (inbox do core, sem commit).
3. Grave o bearer que recebeu com `umask 077` em `~/.config/onion/a2a/bridge-token`.
4. Rode o doctor do membro. Sem o registro do core, (d) e (h) saem não medidos (rc 2): é esperado, e a
   resposta é o doctor do receptor no core (cláusula 6).
5. Depois do merge do pino: o envio de teste em dry-run, conferido, e só então o envio real.
   ```bash
   bash a2a-send.sh --dry-run --from <id> --to <receptor> --body "olá do <id>"
   bash a2a-send.sh --from <id> --to <receptor> --endpoint <url> --body "olá do <id>"
   ```
   Quem tinha remetente próprio troca pelo canônico: o envelope antigo sem `body_sha256` é vetado pelo gate.
   Depois de uma rotação, passe `--kid <id>-<N>` (o default é `<id>-1`). O envelope do `--dry-run` é um JWS
   assinado e válido por 300 s: confira e descarte, não o cole em canal compartilhado.

### Trilha 4 — Conferir e diagnosticar (qualquer lado)
O doctor do lado certo, com os insumos que a conversa tiver (`--endpoint`, `--invite`,
`--fingerprint`). Leia cada ❌ e ⚪ com o próximo passo dele; nunca resuma rc 2 como saudável.

### Trilha 5 — Aceitar a fila (core)
A fila do bridge mora na conta do serviço; listá-la é do maestro, com o acesso dele. Para cada
registro, leia o sinal, confirme com o maestro e aceite **um por vez**:
```bash
bash .claude/utils/federation-transport/a2a-accept.sh <registro.json>
```
O sinal entra no inbox e segue a triagem normal (`/meta:co-evolve`). Recusado (não verificado) não se
força.

### Trilha 6 — Revogar (core)
Tire o `kid` de `a2a.keys` e a pública do JWKS no mesmo PR (o validador reprova `kid` sem `.pem`, e
`.pem` sem `kid` não autoriza nada); tire o bearer do pool pelo caminho de deploy do bridge; e peça ao
membro que destrua a privada (`shred -u ~/.config/onion/a2a/<kid>.key.pem`). A revogação vale no
bridge **quando o clone que ele serve recebe o merge** (caminho de deploy do bridge, maestro): até lá o
`kid` revogado segue aceito lá. Confira com o doctor do receptor nomeando o `kid` revogado, que tem de
sair `falha` em (d) (sem `--kid` o doctor confere só os kids que restam):
```bash
bash .claude/utils/federation-transport/a2a-doctor.sh --side receiver --member <id> --kid <kid-revogado>
```

## Destino (peça 5)

O que muda de verdade é o **registro** (`members.yaml` e o JWKS), validado pelo `members-validate.sh` —
o mesmo que o lint cobra como HARD pela REGRA 66 (Registro da federação validado no gate). O que a
trilha revelou de novo vai para o grafo do programa com o radar exit 0 (`kg-radar.sh --integrity
--schema`). O **contrato de custo** (`run_id` · `tokens` · `agents` · `duration_min`) **não se aplica**:
não há run de workflow, e os motores são 0 tokens. Declarado aqui e na doutrina.

## Peça 4 (orquestração faseada) — AUSENTE por desenho, declarado

Cada trilha é serial e depende de uma resposta humana a cada passo (confirmar o dry-run, conferir a
impressão, aceitar um registro); não há fan-out com independência real. **Gatilho nomeado:** convidar
ou revogar em lote (vários membros por rodada), que pede orquestração.

## Peça 6 (lente)

[`federation-a2a-lens.md`](../../rules/federation-a2a-lens.md), que carrega ao tocar
`.claude/utils/federation-transport/**`, com a guarda da REGRA 53 (Regra path-scoped declara `paths:`
que casa algo real).

## O que este comando NÃO faz

- Não faz deploy, não edita o ambiente do bridge, não reinicia serviço, não lista a fila do serviço com
  acesso de administrador (isso é do maestro).
- Não escreve no repo do membro, não instala nada na máquina dele, não rotaciona chave sem pedido.
- Não aceita sinal em lote nem sem confirmação.
- Não é o convite por membro com validade (F2), nem o hub como receptor (F3), nem o servidor do hub (F4).

## 🔗 Referências

- Doutrina (peça 2): [`common:prompts:federation-a2a-doctrine`](../common/prompts/federation-a2a-doctrine.md)
- Motores: `.claude/utils/federation-transport/a2a-keygen.sh`, `a2a-send.sh`, `a2a-doctor.sh` (medidor
  da peça 3), `a2a-verify.sh` (o gate) e `a2a-accept.sh` (o aceite)
- Registro: `/meta:federation-member` e `.claude/validation/members-validate.sh`
- Bancada (peça 7): `run_federation_a2a_selftests`
- Lente (peça 6): `.claude/rules/federation-a2a-lens.md`
- Molde de wizard: a skill `onion-wizard`; molde de forja: [`/meta:decide`](decide.md)
