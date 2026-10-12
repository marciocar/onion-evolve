# onion-kg-writer — o write(KG) do chat da casa como servidor MCP

Servidor MCP em Python (stdlib + PyYAML; streamable-http stateless, JSON-RPC). Deixa o chat da casa
(LibreChat) **gerar `.kg.yaml` completos e válidos pela maquinaria**, cada usuário na **sua própria
área**. É irmão de escrita do `ops/mcp-onion-kg/` (o Brain), que é só leitura e continua assim.

Nasceu da decisão do maestro de 2026-10-12, tomada por pergunta com opções:

1. qualquer usuário logado escreve, mas **só na sua própria área**;
2. grafo que reprova na maquinaria é **recusado**: nada é gravado, e as linhas do radar e do contrato
   voltam para o modelo corrigir;
3. é um MCP **separado** do Brain.

O registro está em `docs/evolution/research/mcp-kg-writer-2026-10/mcp-kg-writer-2026-10.kg.yaml`.

## Tools

| Tool | Argumentos | Contrato |
|---|---|---|
| `kg_validate` | `yaml`, `slug` (opcional) | dry-run: roda o gate e devolve `veredito` (`APROVADO`/`REPROVADO`), as linhas `✗` do radar, as `MUST` do contrato e os avisos `SHOULD`. **Nunca grava.** Sem `slug`, julga com o `meta.id`. |
| `kg_write` | `slug`, `yaml` | grava `<área>/<slug>/<slug>.kg.yaml` **só com `APROVADO`** e commita no repo git da área com autor = o e-mail do header. Devolve `caminho` (relativo à área), `commit`, `autor`, `mudou` e o veredito. Reprovado = `gravado: false`, `isError: true`, nada no disco, nem a área. |
| `kg_my_list` | — | os grafos da área do usuário (symlink plantado não aparece). |
| `kg_my_get` | `slug` | o texto de um grafo da área do usuário. |
| `kg_schema_help` | — | a gramática que o radar e o contrato cobram, com um exemplo mínimo que **passa no gate** (a bancada confere). |

Toda resposta vem no envelope `untrusted_data: true` + `aviso`, com `usuario`, `served_commit` (o
HEAD da raiz de código, ou seja, a versão da maquinaria que julgou) e `code_source`.

**Pré-checagens antes do gate** (recusa nomeada, nada gravado):

- `slug` em kebab-case estrito (`^[a-z0-9]+(-[a-z0-9]+)*$`, até 80): sem `..`, `/`, maiúscula ou `_`;
- `meta.id` igual ao `slug`;
- yaml até 512 KB, sem byte NUL e **sem âncora nem alias** (vetor de bomba de expansão);
- até 200 grafos por área (`ONION_KG_WRITER_MAX_GRAPHS`).

## O gate

O texto recebido é escrito num diretório temporário e julgado pela maquinaria **real** do core, a
partir de `ONION_KG_CODE_ROOT`:

1. `.claude/validation/kg-radar.sh <arq> --integrity --schema` — exit 0 obrigatório;
2. `python3 -I -B vendor/kg-ssot/tools/kg_validate.py --where <arq>` — rc 0 obrigatório.

Cada gate tem timeout (`ONION_KG_WRITER_GATE_TIMEOUT`, 60 s); estourar conta como reprovação. No
máximo 4 gates rodam ao mesmo tempo. As linhas de falha voltam cortadas (60 por gate, 300 caracteres
por linha) e o teto vem declarado na resposta. Passou: são gravados **os mesmos bytes** que foram
julgados.

**Conteúdo recebido é dado.** Ele nunca é executado. Só é lido por um `SafeLoader` que recusa alias,
e chega aos gates como arquivo, nunca como argumento de shell (o nome do arquivo é o slug validado).

## Área por usuário

- O header `X-User-Email` é obrigatório em todo `tools/call`. Ausente, inválido ou com o placeholder
  não substituído: recusa (fail-closed).
- O e-mail é normalizado (minúsculo, sem espaço) e validado por regex. A área é
  `<parte local saneada>-<sha256 do e-mail, 16 hex>`, sob `ONION_KG_WRITER_ROOT`.
- Nenhuma tool aceita área, usuário ou caminho como argumento: só `slug`.
- Symlink em qualquer nível (área, diretório do slug, arquivo) é recusado, e o caminho final é
  conferido por `realpath` dentro da área.
- O git da área roda com `--git-dir` explícito, `GIT_CEILING_DIRECTORIES`, sem config global, sem
  hook e sem assinatura. O commit nunca cai num repo pai.

## Variáveis de ambiente

| Env | Obrigatória | Efeito |
|---|---|---|
| `ONION_KG_WRITER_TOKEN` | **sim** | token do header `X-Api-Key`. Sem ela o servidor **não sobe**. |
| `ONION_KG_WRITER_ROOT` | não | raiz das áreas; default `/var/lib/onion-chat-kg`. Tem de existir e não pode ser symlink, senão o servidor não sobe. Dono = o usuário do serviço, modo `0700`. |
| `ONION_KG_CODE_ROOT` | não (recomendada) | o worktree destacado do core cuja maquinaria julga. Default: o repo deste arquivo. Sem radar ou contrato lá, o servidor não sobe. |
| `ONION_KG_WRITER_MAX_GRAPHS` | não | grafos por área; default 200. |
| `ONION_KG_WRITER_GATE_TIMEOUT` | não | segundos por gate; default 60. |
| `ONION_KG_WRITER_GATES` | não | gates simultâneos; default 4. |
| `MCP_HOST` / `MCP_PORT` | não | bind; default `172.23.0.1:3037`. `MCP_PORT=0` = porta efêmera. |

O Python precisa ter PyYAML e jsonschema (o do venv). Sem PyYAML o servidor não sobe.

## Tetos declarados

- **A identidade é a que o LibreChat declara.** Quem tem o token escolhe o `X-User-Email`. O token
  prova que quem chama é o LibreChat, e o bind em rede privada é o que separa os dois.
- **Cadastro aberto no IdP**: como a decisão é "qualquer usuário logado escreve", uma conta nova ganha
  uma área. O teto por área (200 × 512 KB) limita uma conta, mas não o número de contas.
- A REGRA 99 (caminho de máquina) não é cobrada no gate: a área é do usuário, não é o corpus do core.
- Concorrência: uma escrita por vez no processo inteiro. Quem tem acesso ao sistema de arquivos da raiz
  está fora do modelo de ameaça (a raiz é `0700` do usuário do serviço).

## Bancada

`python3 -I -B ops/mcp-onion-kg-writer/selftest.py` sobe o servidor de verdade (28 casos). A família
`mcp_onion_kg_writer` do `lint-selftest.sh` trava a contagem e roda um mutante por caso, plantado por
`ops/mutate-and-restore.sh` numa cópia do servidor.
