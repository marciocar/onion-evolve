---
branch: feat/a2a-member-invites-core
pr: pendente
date: 2026-10-15
reviewed_diff_sha256: f1c8b9d92587a3a9a2fbf5c6e0c16626051b6f7223982ec0b6f610670a642ad9
reviewed_code_sha256: 33e2e996913a696934fe0c9f54de7d81f15b7d826be2cfd84693893cd0802f59
findings_total: 15
findings_real: 12
tokens: 157767
duration_min: 14
findings_fixed: 10
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente refutador (general-purpose, opus) + mutantes e oráculo do bridge da sessão
nota: "15 = 12 medidos pelo refutador + 3 suspeitas não medidas (as 3 curadas preventivamente); 10 curados por inteiro e 2 parciais (TOCTOU contra escritor de fora e token órfão no kill -9), declarados em Limites; tokens e duração são do refutador"
---

# Passada adversarial: `feat/a2a-member-invites-core`

## O que muda

Este é o lado do core da F2 do configurador A2A (SAC-123): o **convite por membro**. O lado do bridge
está no onion-bridge#69, que ainda não foi mergeado.

- **`a2a-invite.sh` (motor novo).** Faz `create`, `revoke`, `list`, `check` e `inspect` sobre o arquivo
  de convites do bridge (`A2A_INVITES_FILE`).
  - **Julgamento.** O motor aplica as regras do guard do bridge: forma, dono, permissão, diretório e o
    veredito por convite (a "sonda").
  - **Token.** Nasce de `/dev/urandom` direto num arquivo 0600, ou chega por `--token-stdin` vindo de
    redirecionamento. Nunca passa por stdout, stderr ou argv.
  - **Escrita.** Usa temporário no mesmo diretório + rename, sempre em 0600, com trava `flock` no
    diretório. Antes do rename, relê metadados e conteúdo. O motor recusa rodar como root e nunca
    escreve sobre arquivo quebrado.
  - **Dry-run** existe em toda escrita.
- **`a2a-doctor.sh`.** O receptor ganha a checagem (i) com `--invites`, que diz o motivo que o guard
  daria. No membro, a checagem (e) julga o descritor pelas regras do bridge e liga o hash do token ao
  descritor.
- **Superfície.** No `/meta:federation-a2a`, as trilhas 2 e 6 passam a usar o convite por membro, e o
  pool anônimo vira caminho legado. A doutrina ganha a cláusula 9, a lente ganha o item 6 e o README
  dos motores foi atualizado.
- **Bancada.** A família `federation_a2a` tem 39 casos novos e vai de 53 a 92.
- **Grafo.** O `a2a-configurator-2026-10` ganha 4 nós: a evidência, 2 achados e 1 decisão da sessão.

## Achados

A paridade com o bridge foi medida por um **oráculo**: o módulo real `a2a-invites.ts`, rodado em node 22
com `--experimental-strip-types`.

- **Antes do refutador:** a primeira versão do motor divergia em 2 casos, porque o `Date.parse` do V8
  rola o dia até 31 e aceita `24:00`. A sessão curou os dois.
- **Depois das curas:** 0 divergência em 25 arquivos de teste e em 5002 datas aleatórias.

Achados do refutador:

| # | achado | sev. | desfecho |
|---|---|---|---|
| 1 | O `$` do Python casa antes de um `\n` final e o do JavaScript não: validade ou hash com `\n` davam `ok` no motor e `convite-invalido` no bridge | alto | curado: `fullmatch` em todos os regex (caso e mutante `regex-match-com-newline`) |
| 2 | `24:00` com fração abaixo de 1 ms dava `ok` (a fração era truncada antes do teste) | alto | curado: testa a fração crua (`fracao-truncada-em-24`) |
| 3 | Uma surrogate sozinha no arquivo derrubava `revoke` e `create` com traceback, e a revogação de emergência não acontecia | alto | curado: `ensure_ascii=True` (`dumps-nao-ascii`) |
| 4 | Um JSON fundo demais era dado como "o bridge recusa o arquivo inteiro", embora o bridge o leia | médio-alto | curado: sai `unmeasured`, rc 2 (`fundo-vira-quebrado`) |
| 5 | O TOCTOU não pegava escritor que devolve o mtime (`cp -p`): 14 escritas perdidas em 300 corridas | médio | parcial: o ctime e o conteúdo relido entram na assinatura; medido de novo, 1 em 300. Ver Limites |
| 6 | O (e) do membro não ligava o token ao descritor: um token qualquer com um descritor válido saía saudável | médio | curado: `inspect --token-file` compara o hash no processo (`token-nao-ligado`) |
| 7 | O rc de `list` e `check` ignorava a sonda | médio | curado: com sonda e nenhum `ok`, sai rc 1 (`valido-vira-invalido`) |
| 8 | `list` sem `--member` saía rc 0 com o arquivo ilegível ou quebrado | médio | curado: o rc é sempre calculado |
| 9 | Diretório sem escrita dava traceback | médio | curado: `os.access` sai rc 2 com mensagem |
| 10 | O `kill -9` no meio deixava temporário e token órfãos | baixo | parcial: a varredura de temporários sob a trava e o SIGTERM viram desfazimento; o token órfão no `kill -9` fica (ele não autentica) |
| 11 | FIFO no `--invite` travava o motor e o doctor | baixo | curado: `O_NONBLOCK` e exigência de arquivo regular (`descritor-fifo-aceito`) |
| 12 | O custo era quadrático com hash repetido (8000 entradas levavam 210 s) | baixo | curado: um `decide` por grupo |
| S1 | (suspeita) Escrever como root faria o arquivo nascer de root | — | curado: o motor recusa euid 0 |
| S2 | (suspeita) A conta do serviço não lê o repo do operador | — | doc: motor legível pela conta e `--receiver` explícito |
| S3 | (suspeita) `ID_RE` aceitava `\n` | — | curado pelo `fullmatch` (1) |
| s2 | (sessão) O caso de atomicidade comparava o inode depois de duas escritas, e o kernel reusa o inode liberado: deu ✗ intermitente na bancada limpa | — | curado: o inode é medido depois de uma escrita só; `escrita-in-place` foi re-rodado e morreu |
| s1 | (sessão) O doctor da F1 dava saudável com `revoked: null` e com validade em epoch, e usava `date -d` (só GNU) | — | curado: o (e) usa o `inspect` (casos "descritor com revoked null" e "epoch") |

## Mutantes

39 mutantes foram plantados por `ops/mutate-and-restore.sh`. Cada um rodou
`LC_ALL=C bash .claude/validation/lint-selftest.sh --families federation_a2a`. Um mutante conta como
morto quando o rc é diferente de 0 **e** o caso nomeado aparece como ✗. **39/39 morreram**, todos depois
das curas. A árvore ficou limpa ao fim, e a restauração foi conferida por hash.

| mutante | caso que reprova |
|---|---|
| dry-run-escreve | invite dry-run |
| token-em-stdout · token-em-argv | invite token vazou (registrador de argv em python3/sh/git/openssl) |
| sem-amarra-ao-membro | invite outro membro |
| revoga-so-o-primeiro · revoke-nao-escreve | invite revoke · invite sonda revogado |
| escrita-in-place · temporario-0644 | invite atomicidade · invite create |
| revogacao-frouxa · validade-sem-fuso · validade-epoch | revoked null · validade sem fuso · epoch |
| dia-sem-rolagem · hora-24-frouxa · fracao-truncada-em-24 | 02-30 · 24:30 · 24:00 com fração |
| sem-validade · so-a-primeira-entrada · versao-true-vale | vencida · hash repetido · version true |
| aceita-gravavel · sem-diretorio · sem-dono · segue-symlink | gravável · diretório · dono · symlink |
| escreve-sobre-quebrado · sem-registro | sobre quebrado · membro fora |
| sem-piso-de-token · token-com-cr · sem-trava | token curto · token-stdin · trava |
| desconhecida-vira-ok · valido-vira-invalido | descritor que não está no arquivo · invite sonda ok |
| inspect-revoked-frouxo · inspect-sem-receptor · token-nao-ligado | descritor com revoked null · outro receptor · outro token |
| regex-match-com-newline · dumps-nao-ascii · fundo-vira-quebrado · descritor-fifo-aceito | `\n` final · surrogate · JSON fundo · FIFO |
| doctor-sonda-qualquer · doctor-sem-arquivo-critico · doctor-quebrado-vira-ok · doctor-ok-nunca | receptor revogado · (i) sem arquivo · arquivo quebrado · (i) ok |

Na primeira rodada, dois mutantes não valiam: um foi recusado pela falta do marcador e outro quebrava a
sintaxe e derrubava 35 casos. Os dois foram refeitos e morreram no caso nomeado.

## Limites declarados

- **NÃO MEDIDO: a escrita de produção.** A escrita como a conta do serviço do bridge (`sudo -u`) não foi
  medida, porque o MOAT veda escrever no arquivo de convites de produção. O dogfood rodou só em sandbox,
  com o módulo do bridge como oráculo:
  - o convite criado passa no guard;
  - o mesmo bearer apresentado por outro membro sai `convite-de-outro-membro`;
  - depois do `revoke`, sai `convite-revogado`, sem restart.
- **TOCTOU contra escritor de fora (parcial).** A trava só vale entre motores. A releitura estreita a
  janela de 14 para 1 escrita perdida em 300 corridas, mas não a fecha. Por isso a doutrina diz para não
  editar à mão.
- **Token órfão no `kill -9`.** O token órfão fica: ele não autentica, porque não tem entrada no arquivo.
- **Divergências que restam.** O motor é mais estrito que o bridge só onde o Python não lê, como o JSON
  fundo, que sai "não medido", nunca "recusado". `jq` não lê surrogate sozinha, então o doctor sai "não
  medido" nesse arquivo.
- **Plataforma.** BSD/macOS não foram medidos. O motor não usa `date -d` nem `stat` do GNU, mas a
  bancada usa `stat -c`, como já usava na F1.
- **Merge e deploy.** O merge é da sessão principal, depois do merge e do deploy do onion-bridge#69. Um
  bridge anterior à F2 ignora o arquivo de convites.
