---
branch: feat/onion-attach
pr: pendente
date: 2026-11-25
reviewed_diff_sha256: fcae4b5b27c5414e38d8dee8cc9758dd417eab3498bd73120c68de3d992b5ebb
reviewed_code_sha256: b406efa274e446a9402410f4492ec9f087a996567a2d426e1f50240b503aaff2
findings_total: 39
findings_real: 39
findings_blocking: 0
tokens: 269110
duration_min: 8
findings_fixed: 30
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "attach-reviewer (opus, isolado)"
nota: "Duas passadas do refutador do agente de execução (subagente opus, só leitura: 9 achados com 5 curados, e 12 com 8 curados) e duas rodadas da revisão isolada attach-reviewer (opus), ambas FIXES_NEEDED sem bloqueio: a 1ª com 8 itens (6 curados, 1 limite, 1 informativo), a 2ª com 6 itens, todos curados; a 3ª rodada deu APPROVE, com 3 notas baratas, curadas. elenxo_isolado: true carimbado com a autorização da sessão do core, depois da 3ª rodada. Toca .github/workflows/: toque de guarda, merge pelo one-touch do maestro. tokens e duração somam só as passadas do refutador; os da revisão isolada não foram medidos aqui."
---

# Passada adversarial: `feat/onion-attach`

## O que muda

- `ops/onion-attach.sh` (novo): `onion-attach` lista as sessões (servidor tmux de cada uma, fundo nativo, socket
  sem servidor e o comando exato); `onion-attach <nome>` entra no servidor tmux certo (`switch-client` dentro do
  mesmo servidor; `detach-client -E` com o attach do alvo dentro de outro; os dois só com UM terminal na sessão
  atual, senão rc 3), anexa o fundo nativo vivo por `claude attach <id>` (no próprio painel, se dentro do tmux), ou reabre
  a fechada pela conversa mais recente com o título, por `session-open.sh <nome> --resume <id> --dir <pasta>`.
  Ambíguo (dois servidores, dois fundos vivos, duas conversas quase juntas ou em pastas diferentes) lista e para
  (rc 5). `--install` cria o link em `~/.local/bin` e confere o PATH, sem sobrescrever.
- `ops/session-transcript.sh` (novo): acha a conversa por id ou por título; a pasta é a de ONDE ela nasceu
  (primeiro `cwd` cuja codificação bate com a pasta do transcript), nunca o último `cwd`.
- `ops/session-open.sh`: com `--resume <id>`, a pasta vem do transcript daquele id ou de `--dir`, e não do registro
  de posse (que é ambíguo para a dona de várias peças); sem `--resume`, quando o registro dá rc 2, a pasta vem da
  conversa mais recente com o título, dita, e recusa se o título existe em pastas diferentes.
- `ops/tmux/onion.tmux.conf` e `ops/tmux/install-tmux-conf.sh` (novos): a config do tmux da casa e o instalador
  (cópia estável em `~/.config/onion/tmux.conf` e uma linha `source-file -q` no `~/.tmux.conf`), chamados por
  `onion-attach --install-tmux [--check|--dry-run]`.
- Bancada (contagem atual): família nova `onion_attach` com 74 ✓ (36 casos e 38 mutantes: 34 casos com um mutante no
  SUT ou no instalador, mais o (t6) e o (t8), num tmux real, com 2 mutantes cada) e os casos (rd1) a (rd5) na `session_open` (antes (u) a (u5)).
- KB nova `docs/knowledge-base/concepts/tmux-operation-guide.md`, a §3.2.1 de `parallel-work-worktrees-pattern.md`,
  e o grafo `docs/onion/graph/onion-attach-2026-11.kg.yaml` (9 nós; a decisão `D_ONION_ATTACH_ONE_ENTRY_1125` selada
  pelo `kg-decide-seal.sh`, destino design). Toca `.github/workflows/onion-selftest.yml` (o tmux no runner).

Decisão tomada sem o maestro, declarada: «ambíguo» é a regra de tempo e de pasta, não «mais de uma conversa com o
título». A leitura literal deixaria a sessão de serviços (3 conversas com o título, de reinícios) sempre ambígua.

## Achados

1. `--resume <id>` com a sessão viva no tmux: o abridor anexava à conversa que já roda lá, não à pedida. CURADO:
   rc 3 com o porquê; caso (j) com mutante.
2. Título com sufixo « (N)» (colisão de nomes no Claude Code) não casa a busca exata. LIMITE.
3. `locate_by_title` do abridor escolhia a pasta sem a regra de pastas diferentes. CURADO: recusa se o título
   existe em mais de uma pasta; caso (u5) com mutante. A regra de tempo fica com o `resolve_id` dentro da pasta.
4. Pasta de projetos ausente ou erro de leitura virava «nenhuma conversa» e o atalho sugeria abrir uma NOVA.
   CURADO: rc 2 no leitor (pasta ilegível, ou grep com erro e sem achado; com achado, segue e avisa); caso (k) com
   mutante. O `except OSError` por arquivo segue pulando o arquivo ilegível (limite).
5. A bancada dá pid ao fundo nativo; uma sessão de fundo viva sem pid contaria como morta. LIMITE (a viva medida
   em 25/11, a sessão do core no fundo nativo, tem pid; a regra «sem pid → morta» é a do #1761).
6. Fallback de «viva»: pid 0 contava como vivo, e pid torto matava a interativa. CURADO (pid ≥ 1; interativa sem
   pid numérico segue viva, como no helper do #1761).
7. Conversa com pasta «-» contava como «pasta diferente» e travava o nome. CURADO (o «-» fica fora da comparação).
8. Interativa renomeada dentro do tmux aparece como «fora de um tmux»: o rc 3 é seguro, a mensagem engana. LIMITE.
9. A busca por título lê os transcripts sem cache: 3 s com cache quente, 51 s frio. LIMITE.

## Mutantes

Família `onion_attach` (cada caso reprova contra o seu mutante): (a) servidor certo; (b) switch-client; (b2) outro
servidor → rc 3; (a2) dois servidores → ambíguo; (c) fundo nativo → `claude attach`; (c2) pid morto → reabre;
(h) o helper de vida do #1761 vence; (i) interativa fora do tmux → rc 3; (d) fechada → `session-open --resume
--dir`; (d2) pasta do nascimento, não o último cwd (mutante no leitor); (d3) histórico na mesma pasta; (e) ambíguo
no tempo; (e2) ambíguo por pasta; (e3) `--resume` escolhe; (f) a lista; (g) `--install`; (j) `--resume` com a
sessão viva; (k) pasta ilegível → rc 2 (mutante no leitor).
`session_open`: (u) pasta do transcript no `--resume`; (u2) `--dir` vence; (u3) id sem transcript → rc 5;
(u4) registro ambíguo → pasta pela conversa; (u5) título em pastas diferentes → recusa.
Bancada: `--families onion_attach,session_open`, 130 ✓, 0 ✗, 0 ⊘ (36 da onion_attach, 94 da session_open).

## Limites declarados

- Nenhum attach real rodou: `tmux attach`, `switch-client` e `claude attach` só com dublês. A retomada de verdade
  (`claude --resume` no tmux) só pelo ensaio.
- O helper `session-liveness.sh` (#1761) ainda não está na origin/main: o atalho usa a mesma regra copiada e o
  helper vence assim que existir (caso h).
- Achados 2, 5, 8 e 9 acima, e o `except OSError` por arquivo do achado 4.
- No abridor, o rc 2 do registro também cobre «ilegível», e esse caso agora segue pela conversa com o título, dito.

## Re-revisão: o acréscimo do tmux (pedido do maestro, 25/11)

O que entrou depois da 1ª passada:

- `ops/tmux/onion.tmux.conf`: a config do tmux que o maestro aplicou em 25/11, versionada sem mudar o
  comportamento (o `terminal-features` passou a índice fixo para recarregar sem empilhar).
- `onion-attach --install-tmux [--dry-run]`: backup datado do `~/.tmux.conf`, cópia e `source-file` em cada
  servidor vivo; recusa o `~/.tmux.conf` que é link (rc 3); servidor que falha é nomeado (rc 3).
- KB nova `docs/knowledge-base/concepts/tmux-operation-guide.md` (conceitos, atalhos, copiar e colar, entrar e
  reabrir, quando a sessão some, limites), com o índice, o inventário (122 KBs) e a referência de agentes acertados.
  A KB diz o padrão decidido em 25/11: servidor único; as sessões em servidor próprio migram no próximo reinício.
- Grafo: `E_OAT_COPY_PASTE_OSC52_1125` e `E_OAT_TMUX_CONF_VERSIONED_1125`, ligados à `D_ONION_ATTACH_ONE_ENTRY_1125`
  (nome novo da decisão, agora `status: open`: o selo é da sessão do core).
- CI: o passo de capacidade do runner da bancada instala o tmux se faltar (o caso t8 o usa).

Achados da 2ª passada (12; curados 8):

1. `~/.tmux.conf` que é link: a cópia escreveria através dele. CURADO: rc 3; caso (t7) com mutante.
2. A KB dizia que o botão direito cola; com `mouse on` ele abre o menu do painel (medido no tmux 3.4). CURADO.
3. A KB afirmava a cópia por OSC 52 como medida. CURADO: diz o que foi medido e o que não foi.
4. A KB viaja, mas o atalho e a config moram no core. CURADO: a KB diz onde vale e que chega ao adotante pelo
   SAC-546; o nó do grafo diz o mesmo.
5. Nenhum caso carregava a config num tmux real. CURADO: caso (t8), servidor descartável com socket na pasta da
   bancada, com dois mutantes (opção com erro de digitação; `-as` que empilha).
6. `set -as terminal-features` empilhava a cada recarga (medido). CURADO: índice fixo; o (t8) prova.
7. «config recarregada» prometia demais. CURADO: diz que rolagem e tipo de terminal valem nos painéis novos.
8. O `source-file` vai a todo servidor do usuário, inclusive os sem relação com o Onion. LIMITE.
9. O cabeçalho dizia «só lê, nunca mata». CURADO: diz onde escreve; o rc 3 lista os casos novos.
10. `--install --install-tmux` juntos ignoravam o 2º em silêncio. CURADO: recusa a combinação.
11. `~/.config/tmux/tmux.conf` pode desfazer a config da casa. LIMITE, dito na KB.
12. Sem caso para o backup que já existe no mesmo segundo. LIMITE.

Bancada depois da re-revisão: `--families onion_attach,session_open`, 147 ✓, 0 ✗, 0 ⊘ (53 da onion_attach, 94 da
session_open). A cópia pelo mouse até o computador local segue não medida de ponta a ponta (a sessão não tem
terminal local).

## Re-revisão 2: o instalador por linha source-file e as decisões do maestro (25/11)

A sessão do core pediu, na mesma branch, que a config se ligue ao `~/.tmux.conf` sem sobrescrevê-lo. Mudou:

- `ops/tmux/install-tmux-conf.sh` (novo). Nesta rodada ele acrescentava uma linha `source-file` que lia direto do
  repo; a 1ª revisão isolada trocou isso (item «Instalador» abaixo). **Comportamento atual:** copia a config para
  `~/.config/onion/tmux.conf` (backup datado da cópia anterior que difere, conferência por cmp) e acrescenta ao
  `~/.tmux.conf` a linha `source-file -q ~/.config/onion/tmux.conf` se faltar; idempotente, nunca sobrescreve;
  `--check` só mede; recusa link no `~/.tmux.conf`, na pasta `~/.config/onion` ou na cópia (rc 3); recarrega em cada
  servidor vivo e nomeia o que falha. O `onion-attach --install-tmux [--check|--dry-run]` chama ele.
- KB: por que o `onion-attach` esconde o `-L`; as três decisões do maestro; os limites de imagem (issue
  anthropics/claude-code#42712, «not planned»), OSC 52 só texto e mosh ≥ 1.4.0; a issue #90160 da campainha.
- Grafo: três nós de decisão do maestro, com `status: done` e método testimony, como pediu a sessão do core:
  `D_TMUX_SINGLE_SERVER_DEFAULT_1125`, `D_DELEGATED_AGENT_ALWAYS_NAMED_1125`, `D_NATIVE_BG_SHORT_TASKS_ONLY_1125`.
  O teto foi a 9 nós.
- Bancada: (t1) acrescenta sem tocar o conteúdo; (t3) idempotente; (t2) recarga por servidor; (t4) falha nomeada;
  (t5) ensaio; (t7) link; (t9) `--check`; (t10) worktree; cada um com mutante do instalador. (t6) e (t8) seguem.
  Rodada: `--families onion_attach,session_open`, 151 ✓, 0 ✗, 0 ⊘ (57 + 94).

Achado próprio nesta rodada: ao trocar o bloco de casos, o (t8) saiu junto sem que nada acusasse, porque a
contagem só sobe. A contagem por caso no log (`grep '(t8)'`) o pegou, e ele voltou. Limite: o achado 12 da 2ª
passada (backup no mesmo segundo) deixou de existir, porque não há mais backup.

## Toque de guarda

O diff toca `.github/workflows/onion-selftest.yml` (o passo de capacidade instala o tmux para o caso t8). Isso é
**toque de guarda**: o merge é pelo one-touch do maestro, não pela sessão.

## Revisão isolada, 1ª rodada: attach-reviewer (opus, isolado) — FIXES_NEEDED, sem bloqueio

reviewer: attach-reviewer (opus, isolado)

Oito itens (L1–L3, N1–N5), mais o pedido da sessão do core sobre o instalador. O destino de cada um:

1. **L1** — a KB afirmava como fato atual a migração ao servidor único, mas o abridor ainda cria servidor próprio.
   CURADO: a KB diz que o padrão decidido é o servidor único e que, até o abridor mudar (PR à parte), a sessão
   reaberta ainda nasce em servidor próprio. A mudança do abridor não entrou neste PR.
2. **L2** — `set-clipboard on` deixava o app do painel escrever na área de transferência local. CURADO:
   `set-clipboard external`; o (t6) trava `external` e reprova `on` (mutante); o (t8) confere no tmux real.
3. **L3** — `allow-passthrough on` contradizia a decisão de imagem e deixava DCS não confiável passar. CURADO:
   removido; o (t6) reprova se voltar (mutante); o (t8) confere `off` no tmux real.
4. **N1** — `onion-attach X --resume <id>` não dizia quando o título do id não é X. CURADO: aviso no stderr, sem
   recusa; caso (n1) com mutante.
5. **N2** — LIMITE DECLARADO. A regra local de «viva» do `onion-attach` (o ramo sem o helper do #1761, na
   função `is_live`) ignora o `state` e aceita um pid reciclado como vivo, divergindo do `peer_live` do abridor de
   sessões. No pior caso, um `claude attach` falha numa sessão de fundo morta. Já é limite declarado no #1761, cujo
   helper vence a regra local assim que entrar (caso h).
6. **N3** — este resíduo não declarava o toque de guarda nem a rodada isolada. CURADO: seções «Toque de guarda» e esta.
7. **N4** — o grafo citava ids de sessão. CURADO na 2ª rodada: viraram descrição («a sessão do core», «a conversa da
   sessão de serviços»).
8. **N5** — INFORMATIVO. Injeção não achada: a pasta vinda do transcript entra só como argumento (argv), e o id é
   validado por regex. Vetor residual de confiança: a pasta do transcript vira o cwd do `claude`, que carrega o
   `.claude/` e o `.mcp.json` dela; só é explorável por quem já escreve em `~/.claude/projects`.
9. **Instalador** (pedido da sessão do core junto da 1ª rodada) — o `~/.tmux.conf` lia do checkout do repo (trocar
   de branch mudaria a config viva; config de tmux pode rodar run-shell). CURADO: a cópia estável fora do repo e a
   linha `source-file -q`, descritas acima; casos (t1) a (t10) com mutante. A recusa de worktree saiu: com a cópia
   estável, ela não protege mais nada.

Medido num tmux 3.4 real (servidor descartável): um `~/.tmux.conf` com `set -g mouse off` mais a linha instalada
termina com `mouse on`, `set-clipboard external` e `allow-passthrough off`.

## UX pedida pelo maestro: trocar de sessão de dentro do tmux, sem aninhar

- Dentro de OUTRO servidor tmux, o `onion-attach <nome>` não recusa mais: roda `tmux detach-client -E
  "<attach do alvo>"` no servidor atual, e o cliente vira o attach do alvo no mesmo terminal. Medido num servidor
  descartável com cliente real num pty (script): o cliente sai e o comando do -E roda. Mesmo servidor segue com
  `switch-client`. (Na 2ª rodada: a troca só acontece com UM terminal na sessão atual, e o fundo nativo de dentro
  do tmux passou a rodar `claude attach <id>` no próprio painel, sem desanexar ninguém.)
- O comando do -E é montado com citação POSIX de aspas simples (`sq`): o nome do servidor vem do diretório de
  sockets e o id vem do harness, ambos dado. Casos (b2) comando montado, (b3) servidor com aspa no nome, (c3) fundo
  nativo de dentro do tmux; cada um com mutante.
- Limite: a sessão FECHADA reaberta de dentro do tmux passa pelo abridor de sessões, que ainda pede para sair com
  Ctrl-b d (não mexi no abridor neste PR; dito na KB).

Bancada: `--families onion_attach`, 64 ✓, 0 ✗, 0 ⊘.

## Revisão isolada, 2ª rodada: attach-reviewer (opus, isolado) — FIXES_NEEDED, sem bloqueio

reviewer: attach-reviewer (opus, isolado)

1. **LIMITE A** (medido pelo revisor com dois clientes reais) — `detach-client -E` e `switch-client` sem -t/-c agem no
   cliente «mais ativo» da sessão, não em quem chamou: com o PC e o celular anexados, o celular podia ser o trocado.
   CURADO: antes de trocar, nos dois ramos (outro servidor e mesmo servidor), o atalho lê a sessão atual
   (`display-message -t $TMUX_PANE`) e conta os terminais (`list-clients -t =<sessão>`); com mais de um, ou sem
   conseguir ler, recusa rc 3 com «há N terminais nesta sessão; saia com Ctrl-b d e rode onion-attach <alvo>».
   Casos (b4) outro servidor e (b5) mesmo servidor, com dublê que devolve 2 terminais, cada um com mutante.
2. **LIMITE B** — este resíduo não era honesto sobre a 1ª rodada (8 itens, não 6) e descrevia comportamento velho
   (l.26 e l.122–123). CURADO: a 1ª rodada listada com o destino de cada item; as duas linhas descrevem o atual;
   `elenxo_isolado` voltou a false até o revisor conferir.
3. **n1** — o (t8) não exercia o caminho real do usuário. CURADO: HOME descartável, `~/.tmux.conf` gerado pelo
   instalador (com a linha `source-file -q ~/.config/onion/tmux.conf`), servidor `-S` lendo esse HOME, conferência de
   `mouse on`, `set-clipboard external`, `allow-passthrough off` e terminal-features sem empilhar. Mutantes: opção com
   erro de digitação e `-as`.
4. **n2** — fundo nativo de dentro do tmux desanexava o maestro do tmux. CURADO: `claude attach <id>` roda no próprio
   painel; caso (c3) refeito, com mutante que reintroduz o detach. KB atualizada.
5. **n3** — `~/.config/onion` como link não era recusado. CURADO: recusa rc 3; caso (t11) com mutante.
6. **KB** — faltava o que fazer quando o alvo some entre a saída e a entrada. CURADO: linha na tabela «quando algo
   some» (você cai no terminal de fora, a sessão de origem segue viva, rode de novo), e outra para «há 2 terminais».

Também N4 da 1ª rodada (ids de sessão no grafo), curado nesta.

## Revisão isolada, 3ª rodada: APPROVE

reviewer: attach-reviewer (opus, isolado), 3ª rodada sobre 87ab8ed52..e147efd85: APPROVE

Três notas baratas, todas curadas:

1. O (t8) lia `mouse` e `set-clipboard` só depois de um `source-file` explícito. CURADO: lê `mouse`, `set-clipboard`
   e `allow-passthrough` logo depois do `new-session`, antes de qualquer `source-file`: prova que a linha instalada
   carrega a config sozinha. Só então recarrega duas vezes e conta o terminal-features.
2. Faltavam casos para o `display-message` e o `list-clients` que FALHAM. CURADO: (b6) e (b7), recusa rc 3 sem troca,
   cada um com o mutante `|| true` no lugar do `|| die`, que reprova.
3. O resíduo citava um id de sessão e contagens velhas em «O que muda». CURADO: o id virou descrição; as contagens são
   as atuais.

Selo: `D_ONION_ATTACH_ONE_ENTRY_1125` selada pelo `kg-decide-seal.sh` (rc 0, radar e contrato verdes), com
`--destination design`, que o selador exige e o comando passado não trazia.

## Re-revisão por rebase sobre a main com o #1761 (25/11)

O #1761 (fundo nativo e regra única de «viva») entrou na main e deixou o PR em conflito. A branch foi refeita como
UM commit em cima da `origin/main` (merge `--squash` dos 14 commits, conflitos resolvidos uma vez; a branch antiga
ficou em `backup/onion-attach-pre-rebase`, local). O que mudou além de juntar as duas mudanças:

- `ops/session-open.sh`: o conflito era só nas variáveis do topo; ficam as duas, a `LIVENESS` do #1761 e a
  `TRANSCRIPT` deste PR. Nenhuma linha de lógica foi reescrita.
- `.claude/validation/lint-selftest.sh`: os dois blocos novos na família `session_open` entraram na mesma âncora;
  ficam os dois, o do #1761 primeiro. **Renomeados os casos deste PR de (u)–(u5) para (rd1)–(rd5)**, porque o #1761
  usa (u) e (u2) na mesma família (as funções `_so_u`/`_so_u2` colidiriam no nome e no rótulo). Corpo e mutantes iguais.
- `docs/onion/testing-inventory.md`: projeção; ficou a da main e o `pr-finalize` a regenera.
- Efeito de comportamento: o helper `session-liveness.sh` agora existe na árvore, e o `onion-attach` passa a usá-lo
  sozinho para dizer «viva» (o ramo local deixa de rodar, como previsto no caso h). A interface `live <kind>
  <state> <pid>` foi conferida no helper real (rc 0 vivo, rc 1 pid morto). Com isso, o limite N2 da 1ª rodada
  isolada (pid reciclado na regra local) deixa de valer em uso real.
- **Mudança de código além do conflito** (pede conferência do delta): os casos de cópia do #1761 ((w), (w2), (w3),
  (w5), (w6)) retomam por `--resume` um id cujo transcript de fixture não grava `cwd`, e a cura deste PR recusava
  com rc 5 («não grava a pasta»). Agora, com `--resume` e transcript sem `cwd` compatível, a pasta vem do registro de
  posse (o caminho de antes), DITO; só recusa (rc 5, pede `--dir`) se o registro também não der a pasta. Transcript
  real sempre grava `cwd`, e a sessão de serviços segue curada. Caso novo (rd6) com mutante.

Bancada depois do rebase: `--families onion_attach,session_open,baton_pulse`, 402 ✓, 0 ✗, 0 ⊘ (74 + 132 + 196).

## Revisão isolada do delta do rebase: attach-delta-reviewer (opus, isolado) — FIXES_NEEDED, com reprodução

reviewer: attach-delta-reviewer (opus, isolado)

1. **O fallback do transcript sem `cwd` abria na pasta ERRADA com rc 0.** Com o registro ambíguo, o `locate` caía na
   conversa mais recente com o TÍTULO (não a do id); com o nome fora do registro, no palpite `~/<nome>`; e o aviso
   «uso a do registro de posse» mentia nos dois. CURADO: o abridor lê o caminho do transcript (campo 4 do `by-id`) e
   só aceita a pasta que o nome dá se a codificação dela (`[^A-Za-z0-9-]` → `-`) for IGUAL à pasta do transcript,
   que é onde o `claude --resume` procura a conversa; senão rc 5 pedindo `--dir`. O aviso diz a pasta usada e que ela
   foi conferida pela codificação. Casos (rd7) registro ambíguo com a conversa mais recente do título noutra pasta →
   rc 5, e (rd8) nome fora do registro → rc 5, os dois com o mutante que tira a conferência; (rd6) segue: a pasta do
   registro bate com a do transcript e abre.
   Consequência nas fixtures do #1761: os casos de cópia (w)–(w10) guardavam os transcripts retomados em pastas de
   nome livre (`-orig`, `-outra`), forma que o Claude Code não grava. Os transcripts que eles RETOMAM foram movidos
   para a pasta codificada do checkout da fixture; as cópias seguem onde estavam (o `fork-of` as acha em qualquer
   pasta). Nenhuma asserção dos casos mudou.
2. **Nota:** o rc 2 do `session-liveness.sh` (não medido) virava «morta» sem aviso no `onion-attach`. CURADO: conta
   como morta, mas avisa no stderr; caso (lw) com mutante.

Bancada depois das curas do delta: `--families onion_attach,session_open,baton_pulse`, 408 ✓, 0 ✗, 0 ⊘ (76 + 136 + 196).

## Revisão isolada do delta, 2ª rodada: APPROVE

reviewer: attach-delta-reviewer (opus, isolado), 2ª rodada sobre 6ba8f1d9e..9b7ac2194: APPROVE

A reprodução agora fecha com rc 5. As fixtures (w)–(w10) não enfraqueceram o #1761, e o (lw) está correto (212 ✓
na rodada do revisor).

Commits da branch sobre a `origin/main`. A sessão do core falou em 3 (a feature e 2 de projeções); medi 5 antes
deste registro: 2 de código (`c164cecd6`, a feature; `432d99bd5`, a cura do delta) e 3 de projeções geradas pelo
`pr-finalize`. Este registro acrescenta um commit de resíduo, e o fechamento pode acrescentar outro de projeções.

Rebase sobre a main depois do merge do #1763 (core, 25/11 ~12:37Z): único conflito real na linha SELFTEST_CORE_ONLY_FAMILIES (main +image_bridge, branch +onion_attach), resolvido pela união; projeções puladas e regeneradas. reviewer: rebase-resolution-reviewer (sonnet, isolado): APPROVE (range-diff: código do PR igual fora dessa linha; lista sem perda nem duplicata; resíduo idêntico ao do tip pré-rebase).
