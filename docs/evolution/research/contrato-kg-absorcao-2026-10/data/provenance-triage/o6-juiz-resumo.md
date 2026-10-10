# Onda O6: veredito do juiz independente (SAC-73)

> **Papel:** juiz. O mandato é refutar, e na dúvida o veredito é REPROVADO. Não escrevi a proposta.
> **Base:** `feat/provenance-wave-o6` em `2872afa2`.
> **Entrada:** [`o6-proposta.csv`](o6-proposta.csv) (155 linhas), [`o6-novos-nos.yaml`](o6-novos-nos.yaml) e
> [`o6-resumo.md`](o6-resumo.md).
> **Saída:** [`o6-juiz.csv`](o6-juiz.csv), com **160 linhas**: as 155 do proponente e mais 5 do acréscimo do coordenador.
> As regras aplicadas são as seladas pelo maestro em 2026-10-09/10. Nenhum grafo foi editado.

## Concordância

| Veredito | Linhas | % das 155 |
|---|---:|---:|
| APROVADO | 107 | 69% |
| CORRIGIDO | 48 | 31% |
| REPROVADO | 0 | — |
| CORRIGIDO (acréscimo do coordenador) | 5 | fora da base |

**Nenhuma linha foi reprovada por inteiro.** Toda divergência tinha destino certo pela regra selada, então
corrigi em vez de devolver. Das 48 correções, **42 vêm de regras seladas depois da proposta**: a forma do
marcador P4 e o destino dos 72 traces. Só **6** são defeito do proponente contra regra que ele já tinha:
o hostname em dois `verified_against`, o D5 incompleto no `method` do `E_W8`, a ressalva das 11 linhas do
bridge, que ele mesmo apontou mas não escreveu, os 6 traces do waha e a âncora enganosa do `REC_STAGING`.

### Contagens finais por destino

| Regra | `proposta_final` | APROVADO | CORRIGIDO |
|---|---|---:|---:|
| P1 | `dev-sem-comando` | 2 | — |
| P2 | `binario-dev` | 7 | — |
| P2 | `binario-prod` | 1 | — |
| P4 | `marcar-path-conteudo` (marcador **string**) | — | 3 |
| P5-va | `reescrever-va` | 48 | 2 |
| P5-trace | `reescrever-trace` | 36 | 13 |
| P5-trace | `remover-trace-narrative` | 2 | 29 |
| HEADROOM | `reconciliar` | 1 | — |
| PEND | `add-locality` | 4 | — |
| PEND | `reescrever-source` | 6 | 1 |
| PEND | `reescrever-method` (acréscimo) | — | 5 |

**Destino das 72 linhas que eram `ao-maestro-trace-host`:**

- **`reescrever-trace`, 43 linhas:**
  - 41 shas de remoto: 30 do bridge, 8 do logto, 2 do vaultwarden e 1 do arandek;
  - o misto `E_ESPELHO_CADUCO_…`;
  - o `REC_STAGING_…`, de onde a componente só-host sai do trace e vai à narrative.

  Nas 11 linhas do bridge anteriores a 08-08, a `narrative` ganha a ressalva.
- **`remover-trace-narrative`, 29 linhas:** os 6 do waha, os 21 `(b)` restantes e os 2 `(a)`.

Somando as 8 reescritas originais, as 80 linhas de trace ficam em **49 `reescrever-trace`** e **31
`remover-trace-narrative`**. Das 8 originais, o `E_GRANAAI_DOCTRINE` e o `E_OBJECAO_EXIT2` passaram a
remover.

## O que verifiquei, e não só li

1. **Todo sha de `remoto@sha:caminho` foi conferido no `gh api`, os 47.** Conferi três coisas:
   - o commit existe;
   - o arquivo existe em `contents?ref=<sha>`;
   - o sha é o último commit do arquivo em `commits?until=<verified_at>T23:59:59Z&path=`.

   Bateram 40 de 41 nos remotos que não são o waha. O `E_logto` não tem `verified_at`. Usei o `meta.date`
   do grafo e o commit que nasceu o nó (`346d1bd9`, às 22:18Z), e o `17f4ecd9` (21:26Z) é anterior, então
   confere.
2. **Cada `trace` relativo proposto foi conferido no repo com `test -e`:** `ops/mcp-onion-kg/server.py`,
   `docs/evolution/federation/members.yaml`, `CLAUDE.md`, os dois do SY4 e o `_processed` do E_L2.
   - Li o parser do `kg-trace-resolve.sh` (l.97-127 e o awk da l.168-170). Ele corta no primeiro `:`, então
     `remoto@sha:caminho` vira `remoto@sha` e é pulado como não-caminho por causa do `@`.
   - Os relativos sem espaço são julgados e existem. **Nenhum `TARGET-MISSING` novo.**
3. **HEADROOM re-medido às 2026-10-10:** `free -m` dá available **24252** de 32094 MiB e o swap está em
   **3588** de 8191 MiB. `swapon --show` dá `/swapfile 8G 3.5G`. Bate com o proponente.
   - O nó novo passou no `kg-contract-check.sh` sem achado próprio.
   - Os line numbers do compose (`7338dcb`), que o proponente não pôde reler (F-O6-3), **eu reli**: a l.6 é a
     frase do swap e as l.16, 82, 100, 119 e 137 são os 5 `mem_limit`.
   - O `admin` não está em `7338dcb`. O 512m dele vem do `docker inspect`, e o label do nó novo já diz isso.
4. **Pendências:** conferi no `gh api` `onion-logto@617364f` (README l.9), `cc15d9b`, `a0ce0fd` (console.sh
   l.30-37), `onion-bridge@7e736ba`, `onion-waha@86662e01` (README l.33-34 e compose l.12/l.16),
   `ArandekBR/arandek@1aa794f9/88d93f26` e `gustavo-pulga@21ff04f`. Este último está no remoto registrado
   no `members.yaml`, e o diário tem 10 entradas nesse ref.
   - `3408d82` e `c92ff68` devolvem **422**.
   - `af4a420a~1` = `9f403c2a`: a l.80 é `function D3n`, e o nó nasceu em `af4a420a`.

## Padrões de erro do proponente

1. **O hostname escapou da guarda do gerador.** A guarda do proponente é o `ABS_FS_RE`, que pega caminho e
   não hostname. Por isso `D_logto_not_ssot` e `Q_route_inventory` levavam o hostname da VPS no
   `verified_against` proposto. A regra geral cita hostname, então corrigi.
   - O mesmo hostname está no `method` do `ENT_whatsapp`, mas fora do campo da onda (ver achados).
2. **O D5 foi aplicado por campo, e não por nó.** O `E_W8_CONSOLE_AUTOOFF_VIVO` trocou a pasta pelo remoto
   na `source` e deixou o `method` com o nome da pasta. Corrigi.
3. **O sha foi medido "até a data", mas a data não foi confrontada com a do commit.** Nos 6 traces do waha,
   o `commits?until=` volta vazio, porque o único commit (`86662e01`, 08-02T23:22Z) é **posterior** aos nós
   de 07-31 e 08-01. O proponente propôs `86662e01` assim mesmo. Pela regra selada, isso é só-host na data
   (corrigido para `remover-trace-narrative`, com o sha posterior nomeado como tal na narrative).
4. **Âncora relativa enganosa.** Em `REC_STAGING_…`, o `(b)` deixava no trace `docs/evolution/inbound/ do
   clone local de marcio-pessoal`. Hoje o resolvedor pula por causa do espaço, mas o prefixo é um diretório
   que **existe no core** e é outro diretório. Corrigi: sai do trace e vai à narrative.
5. **Troca por equivalente.** `E_GRANAAI_DOCTRINE` trocava o alvo, que era o `_processed` do clone do
   adotante, pela cópia no core.
   - No remoto do granaai, até 07-18, o `_processed` só tinha `.gitkeep`, então o alvo era só-host.
   - Trocar pelo equivalente de outro repo é regra nova. Corrigi para `remover-trace-narrative`, e nada se
     perde, porque a `source` já cita o `_processed` do core.

## Itens ao maestro (regra nova, NÃO aplicada)

1. **Binário no `trace`.** A regra selada tem dois ramos: repo com remoto, e só-host. O binário de versão
   fixa não cabe em nenhum dos dois, porque é público e "web" pelo selo, mas o arquivo só esteve no host.
   - Apliquei a letra: a componente sai do trace e vai à narrative. São 2 linhas, `E_MEDIDO_LOCAL_TIER10` e
     `E_OBJECAO_EXIT2`.
   - Se o maestro quiser `binário do Claude Code <versão>` como forma do trace, são 2 linhas de volta.
2. **Trace para a cópia versionada em outro repo.** É o caso do `E_GRANAAI_DOCTRINE`: o alvo só-host tem
   uma cópia fiel versionada no core. Proponho decidir se "apontar a cópia" é um 3º ramo.
3. **Marcador P4 × guarda mecânica.** A regra diz "home de conta ou `~/` **do operador**". Em 2 dos 3
   marcadores (`E_SKILL_INSTALL_…` e `E_F4_…`), o literal tem `~/`, mas o til é do leitor da página de
   terceiro. Uma guarda mecânica (P3) que recuse `~/` reprova os dois.
   - É preciso decidir se a guarda recusa todo `~/` (e esses 2 não ganham o marcador) ou se aceita `~/`
     **dentro de citação delimitada**.
4. **Sha posterior ao nó no LOCATOR.** O `E_lid_addressing_root_cause` cita `onion-waha@86662e0` no
   locator, um dia depois do nó. A regra "sha pela data do nó" foi selada só para o `trace`. Se valer para o
   locator, essa âncora (e o padrão) cai.
5. **Push do onion-waha.** `c92ff68` e `3408d82` existem só no clone local. Um push validaria as âncoras sem
   tocar o nó. É a alternativa do proponente, e eu a confirmo.

## Achados fora do mandato

- **J-O6-1.** O hostname da VPS ainda aparece em `method`, por exemplo no `ENT_whatsapp` ("medição no host
  vivo <hostname>"). A O5 raspou caminho do method, mas não hostname. Ele cabe na O7, junto de label e
  narrative, por uma regra de hostname.
- **J-O6-2.** Confirmo o F-O6-1 do proponente: a premissa do `I_CONSOLE_DO_LOGTO_ESTA_PUBLICO` (open) está
  derivada. É candidato a `/meta:kg-freshness`.
- **J-O6-3.** A coluna `grafo` segue carregando um nome de arquivo com nome privado de adotante
  (`gmill-update-547-…`), que é o F5 da O5. Em `valor_final` e `motivo` não há nenhum nome de pasta privada
  (varri com a lista derivada do `members.yaml`).
- **Acréscimo do coordenador.** Os 5 `method: "derivado na migração…"` sem `: ` estão todos em
  `guard-pre-push-2026-10.kg.yaml`. Classifiquei pela evidência: 2 `juízes` (Elenxo), 2 `leitura` (logs de CI
  e o cabeçalho do hook) e 1 `medição` (o dogfood do motor). O texto ficou na forma da O1.

## Tetos

- Os binários da P2 não foram re-medidos: nenhuma das versões está instalada. Julguei pela regra.
- O sha do bridge anterior a 08-08 é "o que o remoto tinha", e não o que rodava. A ressalva vai à narrative,
  mas a linha citada (`App.tsx:21`, `server.ts:27`) pode não apontar o mesmo trecho que a produção tinha.
- Para os nós re-verificados depois de nascer, usei o `verified_at`, e não a data de nascimento. Os dois
  coincidem na maioria dos casos; não conferi o nascimento um a um.
- Não reli a prosa inteira dos nós. Julguei pelos campos da onda (`trace`, `verified_against`,
  `provenance`).
