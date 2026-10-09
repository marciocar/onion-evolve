# Onda O5: veredito do juiz independente (SAC-73)

> **Papel:** juiz. Meu mandato era refutar, e na dúvida o padrão é REPROVADO. Não escrevi a proposta.
> Esta onda **não edita grafos**. Base: branch `feat/provenance-wave-o5` em `fd0fb6ea`, sobre `origin/main`
> `a7c43d95`, em 2026-10-09. Planilha: [`o5-juiz.csv`](o5-juiz.csv), com **84 linhas**: as 80 do proponente e
> 4 que eu acrescentei.
>
> **Convenção da planilha:** campo `*_final` vazio quer dizer **campo inalterado** no grafo, a mesma convenção
> da proposta.

## Concordância

| Veredito | Linhas |
|---|---:|
| APROVADO | **71** de 80 (**88,75%**) |
| CORRIGIDO (linhas do proponente) | 8 |
| REPROVADO | 1 |
| CORRIGIDO (linhas novas: 3 omissões e 1 cascata) | 4 |

### Contagens finais por `proposta_final`

| Regra | Proposta final | Linhas |
|---|---|---:|
| 1 | `reescrever-locator-method` | 61 (60 do proponente + `E_REEXECUCAO_DOS_COMANDOS_REAIS`) |
| 1 | `ao-maestro-P4` | 3 (`E_m3_portabilidade_executada` + as 2 citações verbatim) |
| 2 | `manter-prod-binario` | 4 |
| 2 | `dev-sem-versao` | 2 (o rótulo é falso nas duas, ver P1) |
| 2 | `manter-dev-binario` | 2 (os dois casos de D1) |
| 3 | `dev-historia` | 12 (6 do librechat, `E_HEADROOM_SWAP_100`, 4 cascatas do proponente e a cascata de `Q_route_inventory`) |
| 3 | `manter-prod-medido` | **0** |

Conversões a testemunho com `locality: host` pela regra 1: **5**. São as 4 do proponente mais
`Q_route_inventory`.

## O que reproduzi

- **Shas remotos (`gh api`), todos existem e batem com a data:** `onion-vps-vaultwarden` em `6d82b1b8`
  (08-10) e `31cd4f99` (08-11); `onion-logto` em `617364f2`, `2a4d992e`, `4e99f87c` e `dd1ba808`;
  `onion-waha` em `86662e01`; `onion-plugins` em `22b859fc`, que é o master até 09-07.
  O `onion-waha@c92ff68` devolve **422**, o que confirma o M2.
- **`onion-plugins@22b859fc`**, no clone local: `git grep -c onion-evolve` soma **50**. Os 5 hits `Fonte:`
  estão nas linhas exatas que o nó cita.
- **Shas do repo:** `27179d37` (ls-tree `.claude/diary` = 127, `exclude` = 0) e `9e75a73d` (l.89, 90, 92 e
  99) estão em `main` e são da data do nó. `6e4e5088` dá 18/15/6 e o JSON da 2.1.278 dá 17/70/1.
  `265f6a89` reproduz 15/6/5282/203, **mas é do dia anterior**: corrigi para `0f8a2d41`.
- **Binário 2.1.295 (instalado):** `function UPe(` está no byte 215300356 e `function Ltr(` no 215300693. O
  offset 215300431 do nó cai dentro desse trecho.
- **`E_HEADROOM_SWAP_100`:** rodei `docker inspect` às 22:21Z e os `mem_limit` batem. Rodei também `free -m`:
  available 24169 MiB de 32094 e swap 3,5G/8G.
- **`E_VENDOR_PRODUTO_REFUTADO_EM_SANDBOX`:** o diretório do job não existe mais.

## Padrões de erro do proponente

1. **O critério "load-bearing" foi aplicado com dois pesos.** `Q_route_inventory` (D4) satisfaz o critério do
   próprio proponente: o label diz que o inventário "só existe no host", e o locator É o `sudo grep` no clone
   de produção. Ele recusou a conversão porque "a source é versionada". Só que na `E_CONSOLE_LIGADO` a source
   também é versionada, e ali houve conversão. O que separa as duas, e separa também as l.47 e l.48, é outra
   coisa: se **o observado está registrado num arquivo versionado** (`rodada2.json`, `backlog-real` l.32) ou
   só no próprio grafo. Corrigi para testemunho com `host`, com a cascata da regra 3.
2. **Âncora sem sha em conteúdo que mudou depois.** Em `E_F4_BLOCK_READS_FORA_WORKDIR` o locator diz que
   `kg-freshness.md:120-126` "cita o caminho". Hoje não cita: o caminho foi raspado em `b239e08c`, em
   2026-09-16. Corrigi para `8320b1c3:` (nascimento do nó), onde a l.124 cita. A regra 1 já mandava
   `commit:caminho`.
3. **Afirmação falsa no resumo (D2).** "A receita literal do `E_m3` sobrevive no `SYNTHESIS.md`" não procede.
   As l.10 e l.95 dizem só `env -i` e "sem HOME, sem PATH do usuário", e o literal não está em linha
   nenhuma. Pior: "sem HOME" contradiz o HOME **definido** da receita.
4. **Sha da véspera.** Para `E_MEDIDO_LOCAL_O_GATE_…` o proponente mostrou corretamente que o
   `git log --before` daria contagens erradas. Mas a cura certa é o **commit de nascimento** do nó, que é da
   data e reproduz, e não o main do dia anterior.
5. **"Medição de hoje" que não mede o claim.** O `docker inspect` mede a consequência (`mem_limit`), e não o
   sujeito do label, "o headroom de RAM **é** apertado". Ver o achado F2.
6. **Rótulo falso por falta de enum.** `dev-sem-versao` foi usado em dois nós que **têm** a versão. O
   desfecho (DEV) está certo, mas o rótulo mente (P1).
7. **Busca por lista de diretórios, e não pela classe.** O próprio P3 do proponente previa o defeito, e ele
   aconteceu: `/outro/repo` (`E_REEXECUCAO_DOS_COMANDOS_REAIS`) escapou.

## Decisão de D1: leitura estrita, não promove

A regra 2 diz que a medição sobre binário de versão fixa "**fica** em PROD". É uma cláusula de
**não-rebaixamento**: protege um nó PROD que cumpre a condição de ser varrido a DEV pela regra 3. Não autoriza
**subir** um nó que o autor selou DEV. Promover seria regra nova, e pela regra 5 isso vira proposta ao
maestro. Nos dois casos há ainda um agravante:

- **`E_MEDIDO_LOCAL_TIER10_NO_PROPRIO_REPO`:** o `method` é o placeholder da migração ("não reverificado").
  Nem a letra "o method for `medição: …`" descreve uma medição real.
- **`E_REEXTRACAO_2_1_295_SO_NOMES`:** falta o comando. "Extração por python lendo bytes" não tem script, e a
  bancada `--families cited_directive` mede a guarda, não o binário.

**Desfecho:** os dois ficam em DEV, com `locality: web` e sem o "(host)" na source. O rótulo é
`manter-dev-binario`, que descreve o resultado da não-aplicação e não é regra nova.

## D2 e as citações verbatim

| Caso | Veredito | Por quê |
|---|---|---|
| `E_DEFEITO_…` (`/usr/bin/gh`, vetor) | **APROVADO** | A classe do escape é "gh por caminho absoluto", e a forma a preserva. O literal sobrevive versionado no `_case` de `lint-selftest.sh` |
| `E_m3_…` (receita `env -i`) | **REPROVADO → maestro (P4)** | O valor exato de PATH e de HOME **é** a receita. A forma não a reproduz, e a âncora apontada é falsa |
| `E_REEXECUCAO_…` (`/outro/repo`, vetor; **omissão**) | **CORRIGIDO** (reescrito) | Mesma classe do `E_DEFEITO`, e o literal está nos rótulos `_case` e no commit da source |
| `E_SKILL_INSTALL_PROMPT_AND_CURL` e `E_F4_CLAUDE_JSON_CONCORRENTE` (citação verbatim) | **Exclusão NÃO aprovada.** Viram linhas `ao-maestro-P4` | A regra selada é universal ("todo `~/`") e não tem isenção. Excluir é aplicar a P4 antes de selá-la. Também não reescrevo, porque isso falsificaria a citação. Os grafos ficam intocados até o maestro decidir |

## Busca própria (regra 1)

Rodei uma busca pela **classe**: absoluto no início de token, ou `~/`. Ela cobriu `source`, `locator` e
`method` dos 146 grafos fora de fixtures. Rodei em seguida uma varredura por substring (`home/…`,
`.local/share`, `/tmp`, `/proc`, `/boot`, `$HOME`, o hostname).

- **As 61 linhas R1 estão todas no meu universo.**
- **A `source` está limpa.** O proponente só varreu `locator` e `method`. Medi `source` e não há caminho de
  máquina, então a omissão de método não teve custo.
- **Omissões:** 3, todas da classe conteúdo (`/outro/repo` e as 2 citações), lançadas como CORRIGIDO.
- **Falsos positivos da classe:**
  - comandos `/meta:*`, `/engineer:pr`, `/catch-up`;
  - endpoints `/health`, `/v1/messages`, `/a2a`, `/oidc`, `/metrics`;
  - caminhos de URL (`/docs`, `/agent-skill`);
  - glob relativo `/fixtures/`, `TZ="$HOME"` (vetor) e `/lib/` dentro de caminho relativo.

  A P3 precisa excluí-los explicitamente.

## Itens para o maestro

| Item | Proposta | Minha opinião |
|---|---|---|
| **P1** | Enum `dev-sem-comando` | **A favor.** Hoje o rótulo mente em 2 nós. Sugiro também `manter-dev-binario` como valor formal do desfecho de D1 |
| **P2** | Medição de binário rotulada `derivado`, `leitura` ou `juízes` (7 nós em PROD) | **A favor da regra, contra o re-rótulo em massa.** Trocar o rótulo para `medição` é afirmar que houve medição. Cada nó tem de passar pela condição completa da regra 2 (versão **e** comando no próprio nó), e quem não passar vai a DEV |
| **P3** | Guarda pela classe | **A favor, com evidência:** a lista deixou escapar `/outro/repo` nesta própria onda. A guarda precisa de isenções para comando `/x:y`, para caminho após domínio de URL e para endpoint. Sem elas, a busca de classe casou 161 nós, dos quais 64 são verdadeiros (61 + 3 omissões) e 97 são falsos positivos |
| **P4** | Isenção para caminho-conteúdo | **A favor, só com marcador explícito** (por exemplo, citação entre aspas com a fonte de terceiro no `source`) e só para **caminho que não é desta máquina**: citação de terceiro e placeholder de vetor. Para vetor e receita com literal versionado noutro lugar, reescrever pela forma (como `E_DEFEITO`). Para a receita sem literal versionado (`E_m3`), ou se isenta, ou se aceita a perda |
| **P5** | Caminho fora de `provenance` | **A favor, e é maior do que o proponente disse:** `verified_against` carrega caminho de máquina em **52 nós** e `trace` em **80**. Raspar só a provenance é cosmético enquanto o mesmo literal fica dois campos acima (`E_m3`, `E_VENDOR_PRODUTO`, `E_REEXTRACAO`) |
| **D1** | Promover DEV→PROD pela regra 2? | Decidi **não**, pela leitura estrita. Se o maestro quiser promoção, que a regra diga "sobe" |
| **D3** | `locality` mista (binário + repo) | Apliquei o selo (`web`) e ancorei a metade do repo com sha no locator. Sugiro selar essa convenção |
| **D5** | Pasta (`onion-vps-logto`) vs remoto (`onion-logto`) no mesmo nó | Unificar pelo nome do remoto. Fora da regra 1 |

## Achados fora da provenance

- **F1 (M2 confirmado).** `onion-vps-waha@c92ff68`, citado em `E_waha_public_route_caddy`, não existe no
  remoto (422). A âncora está quebrada.
- **F2. Drift provável de `E_HEADROOM_SWAP_100`.** O label diz, no presente, que o headroom "é apertado". Hoje
  há 24 GiB disponíveis de 32, e o swap está em 44%. Candidato a `/meta:kg-freshness`.
- **F3. Classe "âncora sem sha a conteúdo raspado depois".** Toda raspagem de caminho num arquivo (como
  `b239e08c`) invalida em silêncio os locators que citavam o arquivo pela linha, sem sha. Vale uma varredura
  dirigida.
- **F4. Regra 4 fora do universo desta onda.** Ainda há nome privado em `source`, `locator` ou `method` de
  pelo menos 9 nós:
  - `E_ELENXO_MEMBERS_YAML_HAS_NO_PLATFORM_IDENTITY` e `E_ELENXO_CHANNELS_TOGGLE_UNMEASURED_PER_ADOPTER`;
  - `E_REGEN_POS_MERGE_MUDOU_O_INVENTARIO`;
  - `I_SEGUNDO_IDP_COM_CONSOLE_DESTRANCADO`, com uma variante de pasta local do arandek;
  - `C_EDGE_HAGEL`;
  - `C_PARECER_2LINEAGE`, em nome de arquivo;
  - dois nós cujo **próprio id** carrega o nome, em `rito-task-manager-2026-09` e `vps-shared-tools-2026-07`.

  Os casos em prosa trocam-se pelo id. Os casos em nome de arquivo ou id dependem da P6 da O4 (renomear).
- **F5. A coluna `grafo` da planilha carrega nome privado.** A linha de `Q_CORTE_POR_PAPEL_SO_COBRE_STANDALONE`
  traz o caminho do grafo que tem o nome privado no nome do arquivo. Isso vale para a proposta e para este
  CSV, e é inevitável até a P6. O `o5-resumo.md` do proponente afirma "nenhum nome de pasta privada aparece
  aqui" e, mesmo assim, escreve esse nome de grafo na seção M4.
- **F6. `E_REEXTRACAO_2_1_295_SO_NOMES`** ancora a guarda em `git show HEAD:`, uma âncora móvel. O certo é
  `af4a420a~1`.

## Tetos

- **Binários 2.1.258, 2.1.259, 2.1.278, 2.1.286 e 2.1.289:** não estão instalados, então não reproduzi as
  contagens do binário (`grep -ao`, os trechos `re.finditer`). Reproduzi só a metade do repo e o 2.1.295.
- **`arandek`:** não conferi os shas, porque o token não alcança a org.
- **Os 6 nós do librechat:** não reli a prosa inteira. Julguei pela classe, como o proponente.
- **Linhas testemunho/host:** não medi o estado atual de console, deploy ou kernel. Elas vão a DEV pela
  classe, então essa medição não muda o desfecho.
- **"Incidental" vs "load-bearing":** julguei pelo label e pela source de cada nó, sem reler o diário de cada
  sessão.
