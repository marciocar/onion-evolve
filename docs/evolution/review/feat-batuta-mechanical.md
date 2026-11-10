---
branch: feat/batuta-mechanical
pr: pendente
date: 2026-11-10
reviewed_diff_sha256: pendente
findings_total: 26
findings_real: 26
findings_blocking: 4
tokens: 0
duration_min: 140
findings_fixed: 20
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "revisão independente encomendada pela sessão principal (REJECTED no a19e127, 2 bloqueios e 4 pontos), mais a passada da própria construtora antes dela"
nota: "tokens não medido (0): a sessão não tem o contador do próprio run; duration_min pela idade da worktree (140 min, com as duas re-revisões). A 1ª passada foi da construtora; a 2ª, independente, reprovou e foi curada ponto a ponto, com caso e mutante."
---

# Passada adversarial: `feat/batuta-mechanical`

## O que muda

A batuta mecânica da orquestração de sessões, v1, forjada pelo `/meta:forge` sobre o que já existia:

1. **Porta de admissão do passo pesado** (`ops/load-lease.sh`, função `load_lease_reexec`). A bancada
   (`lint-selftest.sh`) e o harness de mutantes (`ops/mutate-and-restore.sh`) chamados direto se re-executam
   sob `run`: carga mais uma das N vagas de passo pesado, com N derivado da carga. O `pr-finalize` pega uma vaga sempre, não só com bancada cheia,
   e o pré-voo repassa a vaga do pai pelo `env -i`.
2. **Parado e pendência no censo do `/meta:decide`** (`decide-census.sh`):
   - idade da última atividade em `thread` e `merge`, com PARADO a partir de `--idle-hours` (4 h);
   - a linha `signal` (campainha sem ack);
   - a linha `ask` (reservas de pergunta ao maestro);
   - a linha `seal` com dona viva noutra sessão vira `outro-dono`.
3. **Dona única por pergunta ao maestro** (`.claude/utils/orchestration/maestro-ask.sh`, novo). A chave é
   `<repo>#<ID>`, com uma dona, prazo de 24 h, o vencido assumido só com `--takeover` e o `resolved.log`.
4. Doutrina `batuta-doctrine.md`, ligada no passo PERGUNTAR do `/meta:decide` e no preâmbulo do agente de
   execução, que passa a pedir espera em 1º plano e passo pesado pela porta.
5. Grafo `session-orchestration-2026-11`:
   - `Q_SO_PADROES_DE_MERCADO` fecha, citando a colheita da curadoria de 04/11 e a de 10/11 (copiada em `data/`);
   - `Q_SO_GATILHO_DE_CONSTRUCAO` segue aberto, com a conferência regra a regra;
   - entram `E_SO_MERCADO_SUPERVISAO_1110` e `C_SO_BATUTA_V1_1110`.

## Achados

1. **BLOQUEIA, curado.** O pré-voo (`ops/testing/preflight-run.sh`) roda a bancada sob `env -i`, que apagava
   `ONION_LOAD_LEASE_HELD`. Com o `pr-finalize` segurando a vaga sempre, a bancada do pré-voo esperaria a vaga
   do próprio pai até o teto, num deadlock de 30 min, e todo fechamento sairia rc 4. Reproduzido com vaga privada:
   sem o repasse, a bancada filha espera a vaga do pai; com ele, roda em 4 s. A cura repassa a variável no
   `env -i`, e o caso `(n) pré-voo` reprova contra o mutante.
2. **Real, curado.** O `maestro-ask.sh` imprimia RESERVADA com rc 0 mesmo quando a escrita do arquivo falhava. A
   cura grava por `_write` e devolve rc 2 em falha de E/S. O caso `(d)` o exercita: com o alfabeto mutado, a saída
   não diz «alfabeto» e o caso reprova.
3. **Real, curado.** O registro nasceu em `ops/`, que não viaja, e a peer adotante (a curadoria, na mesma VPS)
   receberia do censo um comando que não tem. Foi para `.claude/utils/orchestration/`. A REGRA 100 (Superfície que
   viaja não cita ops/ como se o destinatário o tivesse) acusou as 7 citações e voltou a zero.
4. **Real, curado.** A campainha saía `absent` quando o censo roda numa worktree, porque o estado é indexado pela
   raiz principal. O leitor passou a receber a raiz principal (`git-common-dir`).
5. **Real, curado.** A porta re-executava por nome fixo (`<dir>/load-lease.sh`), e a cópia mutada da bancada não
   seria exercida. Passou a re-executar pelo próprio arquivo (`BASH_SOURCE`).
6. **Real, curado.** Sem `--self`, a reserva da própria sessão sai `outro-dono`. O cabeçalho da seção `ask`, o
   `/meta:decide` e a doutrina passaram a dizer isso.
7. **Real, curado.** A chave não dizia qual nome de repo usar. A doutrina passou a dizer: a pasta do checkout
   principal, o mesmo nome que o censo casa.
8. **Limite.** A faixa parcial do pre-commit também pega uma vaga, pela porta da própria bancada. Com a carga perto
   de 12 (N = 1), os commits com bancada esperam uns pelos outros até 30 min (rc 4, dito). A refutação está em
   `C_SO_BATUTA_V1_1110`.
9. **Limite.** A corrida de duas reservas ao mesmo tempo foi provada no dogfood (uma dona e uma recusa), mas não
   entrou na bancada: o mutante sem `flock` não reprova de forma determinística.
10. **Limite.** O gatilho do degrau 2 não fecha pela letra: nas janelas 2 a 4 o diário mostra 4 regras claras e
    2 parciais por janela, e a cláusula pede 5 de 7. A v1 não é o degrau 2 (não rascunha fila), e a construção vem
    da decisão «Batuta primeiro» do maestro.
11. **Limite.** A régua de carga não muda. O PSI já foi medido contra o load em 06/11 (`E_SO_PSI_CONTRA_LOAD_1106`),
    e o maestro selou «15/12 + PSI 30». A amostra de hoje (load entre 3 e 6, PSI de CPU entre 2% e 6%) não traz
    dado novo.
12. **Limite.** O censo não vê a sessão ociosa sem pendência (worktree limpa e sem PR), nem a espera de subagente
    que não acordou: isso é do harness, e a cura v1 é o preâmbulo pedir espera em 1º plano.

## Re-revisão: N vagas derivadas da carga (pedido da sessão principal, 13:35 UTC)

Diff novo depois do 1º fechamento. A sessão principal mediu às 13:35 UTC: 4 passos na fila da vaga única
(mutantes, `pr-finalize`, lint, revisor) com load 3,5 em 8 CPUs. Um mutex único serializa o que cabe junto.

13. **Real, curado.** A vaga única virou N vagas (`slot.<i>.lock`). N = piso((RESUME − load1) / `ONION_LOAD_SLOT_CPUS`),
    entre 1 e `ONION_LOAD_SLOTS_MAX` (2 e 4 no conf), medido a cada tentativa. A carga é re-julgada enquanto se
    espera vaga. Os casos `(o)`, `(p)` e `(q)` provam os dois lados e a queda de N; o `(e)` ficou com N = 1.
14. **Real, curado (dogfood real).** A 1ª fórmula media a folga até `nproc` e deu N = 1 com load 5,3. Isso
    serializava o que a régua selada chama de livre (abaixo de 12). A folga passou a ser medida até RESUME: com
    load 3,5, dá N = 4, e duas tarefas reais entraram juntas em 5 s, contra ≥ 8 s em série.
15. **Real, curado (dogfood real).** A espera pela vaga sondava a cada 20 s (o intervalo da carga), e B esperou 20 s
    a mais depois que A saiu. A vaga passou a ser sondada a cada 2 s no máximo.

`ONION_LOAD_SLOT_CPUS=2` é estimativa inicial, sem medida: calibra-se pela série dos donos, e a refutação está no
nó. A régua de admissão (15/12 + PSI 30) não mudou.

## Re-revisão: revisão independente, REJECTED no `a19e127`

16. **BLOQUEIA, curado.** O N limitava o **índice** da vaga, não o número de donos. Com as vagas 1 a 3 tomadas e
    N = 1, uma 4ª entrava na vaga 0, e 4 passos rodavam juntos. A cura varre todas as `SLOTS_MAX` vagas sob uma trava
    de admissão (`admit.lock`), conta as tomadas e só entra com tomadas < N. O caso `(r)` segura as vagas 1 a 3. A
    medida do revisor foi reproduzida já curada: rc 4 com N = 1, e com N = 4 o 4º dono entra.
17. **BLOQUEIA, curado.** A admissão da bancada rodava antes de ler os argumentos, então `--list`, `--checkpoint` e
    `--dry-run` esperavam vaga e saíam rc 4 sem rodar nada. O checkpoint do pre-commit esperaria até 30 min. Agora o
    modo sem execução (`--list`, `--map`, `--dry-run`, `--checkpoint`) passa direto. O caso `(t)` roda a bancada real
    copiada para uma sandbox, com a vaga tomada.
18. **Real, curado.** Pressão de CPU ilegível com o sinal ligado era «ocupado para sempre»: num kernel sem
    `/proc/pressure`, todo fechamento morreria no teto. Agora é «não medido», dito, e a admissão cai na carga (caso `(s)`).
19. **Real, curado.** A idade da worktree usava `%ct`, que rebase e amend renovam. Passou a usar `%at` (caso `(f)` do
    `batuta_census`). O mtime do índice ficou de fora, porque o próprio `git status` do censo o reescreve. O falso
    PARADO de arquivo ignorado e o `updatedAt` mexido por bot ficam declarados na doutrina e no cabeçalho do censo.
20. **Real, curado.** A dona era nome livre, e duas sessões `core` se renovavam uma à outra. A identidade passou a ser
    o id da sessão (`--session` ou `CLAUDE_CODE_SESSION_ID`); sem ele, rc 2 (casos `(f)` e `(g)` do `maestro_ask`). O
    censo usa o mesmo id como «eu». Medido: o subagente herda o id da sessão-mãe, então a identidade separa sessões,
    não agentes. Isso está declarado.
21. **Real, curado na doutrina.** A vaga é por uid e vale para toda sessão deste usuário nesta máquina. Esse custo
    está declarado.

O achado 6 da 1ª passada (a reserva própria saindo `outro-dono`) ficou superado pelo 20.

## Re-revisão: a cura barata pedida na aprovação

22. **Real, curado.** O subagente herda o id da sessão-mãe. Com o mesmo id e outro `--owner`, a renovação reescrevia o
    nome da dona, e o `release` fechava a reserva da mãe. Agora renovar e fechar exigem o mesmo nome e a mesma sessão;
    com a mesma sessão e outro nome, a resposta é «já tem dona (… nesta sessão)», rc 3. O caso `(h)` tem dois
    mutantes, um no claim e um no release. Dogfood com o id real desta sessão (herdado da mãe): o agente recebeu rc 3
    nos dois, e a mãe fechou.
23. **Limite declarado.** Um `load-lease.sh` da versão anterior, noutra worktree, não pega a `admit.lock` e pode furar
    a contagem de donos até todas as worktrees subirem para a `main`.

## Re-revisão: o conflito do auto-rebase no merge

24. **Real, sem defeito.** O auto-rebase do merge parou na base `3994f6f`. O driver das famílias resolveu sozinho um
    conflito de encaixe no `lint-selftest.sh`: a família nova da `main` (`run_private_repo_cite_selftests`) e as
    minhas (`run_maestro_ask_selftests`, `run_batuta_census_selftests`) entravam no mesmo ponto, logo depois de
    `_family run_load_lease_selftests`. A revisão mediu:
    - o meu diff no arquivo é idêntico, linha a linha, ao revisado;
    - as cinco famílias envolvidas estão definidas e registradas uma vez cada, sem duplicata nas 332;
    - as outras peças da branch não mudaram.

    Como a `main` tinha andado mais 10 commits, um deles na família `role_cut`, rebaseei de novo sobre a
    `origin/main` atual. O único conflito foi a projeção gerada `testing-inventory.md`, regenerada da árvore. O meu
    diff seguiu idêntico. As 4 famílias da batuta, mais `private_repo_cite` (a vizinha do conflito) e `role_cut` (a que
    a `main` mudou), passam 213 de 213. As duas projeções que a tentativa de merge deixou no índice foram devolvidas
    ao estado do commit, porque são regeneráveis e o `pr-finalize` as refaz. Não houve `reset --soft`.

## Re-revisão: o CI reprovou a `plugin_bundle` (shard 2)

25. **BLOQUEIA, curado.** O `decide-census.sh` estendido citava o leitor da campainha pelo caminho do core
    (`.claude/utils/co-evolution/...`, nas linhas 22 e 546 do bundle), e o bundle do plugin `onion` leva o censo sem
    o `co-evolution`. A REGRA 74 (Caminho .claude/ NU dentro de plugin só resolve no core, com catraca) deu HARD NOVO.
    A cura segue a 2ª opção da sessão principal. Embarcar foi descartado porque o manifesto só aceita diretório
    inteiro, e o `co-evolution` levaria junto os carteiros da federação. Agora o censo acha o leitor AO LADO de si
    mesmo (`../utils/co-evolution/`), e a cópia que viaja sem ele diz «campainha não disponível neste papel». O caso
    `(g)` do `batuta_census` roda o censo sem o leitor ao lado, e o mutante que roda o leitor ausente cai em «NÃO
    MEDIDA». Os casos `(a)` a `(f)` passaram a rodar a cópia numa árvore com o leitor ao lado, como na fonte.
26. **Real, diagnóstico corrigido.** O «novas: `plugins/onion/skills/onion/SKILL.md`» do `(b2)` não veio deste PR. É a
    última linha da baseline, que o próprio caso remove de propósito para simular a catraca crescendo. O `(b2)`
    reprovava porque a comparação com a baseline igual saía rc 1, por causa do HARD do achado 25. Este PR não toca o
    `SKILL.md` nem a baseline (diff de 0 linhas contra a `main`), e a catraca segue em 81.

Na reprodução, a carga da máquina chegou a 35,9 com testes de outro projeto. O lease esperou 181 s e só admitiu a
bancada com load 11,4: a peça funcionando de verdade. Um defeito meu na adaptação (o aplicador do mutante apontava para
o caminho velho) abortou a 1ª rodada antes da soma e foi curado.

## Mutantes

Cada caso reprova contra o mutante dele (`_prove_mutation`):
- `load_lease`: `(o)` duas juntas com carga baixa; `(p)` nenhuma nova com carga alta, nem com vaga solta durante a
  espera; `(q)` N cai a 1 com carga média; `(l)` porta sob a vaga e com a vaga alheia; `(m)` guarda do laço; `(n)` ligação da bancada, dos
  mutantes, do `pr-finalize` e do pré-voo;
- `maestro_ask`: casos `(a)` a `(h)`;
- `batuta_census`: casos `(a)` a `(g)`;
- `load_lease`, depois da revisão independente: `(r)` donos contados, `(s)` pressão de CPU ilegível e `(t)` `--list` sem esperar vaga.

A família `decide` segue verde, com os casos `(l)` e `(o)` ajustados à coluna `ask` nova no fim do TSV. Nenhum
consumidor lê esse TSV por posição (medido por grep).

## Limites declarados

- Fora da v1, por postura: cgroup, slice e timer do systemd (do maestro), despacho entre sessões (degrau 3) e painel.
- A vaga e o registro de perguntas são desta máquina; o notebook não os vê.
- Sem refutador independente: a passada é da própria construtora (ver `nota`).
