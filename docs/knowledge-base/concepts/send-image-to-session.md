# Mandar imagem para a sessão

> **Versão**: 1.0.0 | **Última atualização**: 2026-11-25 | **Categoria**: Conceitos (operação)
> Como um print do Windows chega à sessão do Claude Code que roda na VPS. Dois caminhos: o **atalho do Windows**
> (o principal) e o **Gokapi pelo navegador ou pelo celular** (o segundo).

---

## 📋 Metadata

- **Peças (core-only):** `ops/windows/onion-paste-image.ps1` (Windows) · `ops/gokapi-fetch.sh` (VPS) · `ops/windows/README.md` (instalação)
- **Grafo:** `docs/onion/graph/image-bridge-2026-11.kg.yaml`
- **Relacionadas:** [Trabalho paralelo em worktrees](parallel-work-worktrees-pattern.md) · [Segredos e o agente](secret-handling-agent.md)

---

## 1. Por que não dá para só colar a imagem no terminal

A sessão roda na VPS. O seu Windows Terminal só mostra a tela dela.

- O **Ctrl+V** do Claude Code lê o clipboard da **VPS**, não o do Windows. A VPS não tem tela, então não tem imagem.
- O **OSC 52** (o que faz o copiar e colar de texto funcionar no tmux) não leva imagem. A Anthropic fechou esse
  pedido como «não planejado» (issue anthropics/claude-code#42712).
- O Claude Code **aceita imagem pelo caminho do arquivo** (doc oficial, «Work with images»). Basta o arquivo estar
  no disco da VPS e o caminho ir na mensagem.

Por isso a ponte faz uma coisa só: **põe a imagem num arquivo da VPS e entrega o caminho a você.**

## 2. Caminho 1: o atalho do Windows (o principal)

**O que você faz (3 passos):**

1. Tire o print: **Win+Shift+S** (ou copie uma imagem, ou um arquivo de imagem no Explorer).
2. Aperte **Ctrl+Alt+I**. Um balão do Windows avisa «imagem enviada».
3. Na sessão, escreva o que quer e cole com **Ctrl+V**. O que cola é o caminho, por exemplo
   `/home/<você>/.local/share/onion/inbox-images/20261125-143012-win-a3f1.png`. Envie.

**O que a máquina faz:** o script pega a imagem do clipboard, salva um PNG temporário, confere o tamanho, envia por
**sftp** com a mesma chave SSH do mosh, fecha o arquivo para só você ler (0600) e troca o clipboard pelo caminho.

**Instalar uma vez:** veja `ops/windows/README.md` (core-only). São 3 comandos no PowerShell: copiar a pasta, rodar com
`-Setup -SshHost <apelido>` e rodar com `-InstallShortcut`.

## 3. Caminho 2: o Gokapi (navegador ou celular)

Use quando estiver longe do seu Windows, por exemplo no celular.

**O que você faz:**

1. Abra `transfer.onionevolve.com` e entre (login do Onion).
2. Cole a imagem no painel com **Ctrl+V** (ou escolha o arquivo). **Não** marque cifra de ponta a ponta.
3. Copie o link de **download** (o que tem `?id=`) e cole na sessão: «pega esta imagem: <link>».

**O que a máquina faz:** a sessão roda `ops/gokapi-fetch.sh <link>` (core-only). O script baixa pela API do Gokapi com a chave de API
do Onion (a mesma do upload, que tem todas as permissões), confere pelos bytes que é imagem, grava na mesma pasta privada e imprime o caminho. A sessão lê a
imagem por esse caminho.

## 4. Onde as imagens ficam e quando somem

- Pasta: `~/.local/share/onion/inbox-images/` na VPS. Só a sua conta lê (pasta 0700, arquivo 0600).
- Os nomes começam com data e hora: `AAAAMMDD-HHMMSS-...`.
- **Limpeza:** imagens com 7 dias ou mais são apagadas. Isso acontece sozinho a cada imagem baixada pelo Gokapi, ou
  quando alguém roda `ops/gokapi-fetch.sh --prune` (core-only) (use `--days N` para outro prazo e `--dry-run` para só ver).
  A limpeza só apaga arquivos com esse formato de nome, só nesta pasta, e nunca entra em subpasta nem segue atalho.
- O caminho 1 sozinho não roda a limpeza. Quem só usa o atalho pode pedir à sessão um `--prune` de vez em quando.

## 5. Quando dá errado

| O que aparece | O que fazer |
|---|---|
| Balão «não há imagem no clipboard» | Tire o print de novo e aperte o atalho depois. |
| Balão «o envio por sftp falhou» | Abra o PowerShell e rode `ssh <apelido>`. Se pedir senha ou falhar, a chave SSH não está carregada. |
| Balão «falta o ssh do Windows» | Instale o cliente SSH do Windows em Configurações > Sistema > Recursos opcionais. |
| O atalho demora uns segundos | É normal no Windows. Para resposta imediata, use o AutoHotkey (veja o README). |
| `gokapi-fetch` rc 2, «falta a chave de API» | A entrada do pass não abriu. Rode `ops/gokapi-fetch.sh --check` (core-only) e veja a seção 6. |
| `gokapi-fetch --check` diz «download: AUSENTE» | A chave não tem a permissão de download. Dê a permissão no painel do Gokapi. |
| `gokapi-fetch` rc 3, «cifrado de ponta a ponta» | Suba de novo sem marcar a cifra. A API não entrega arquivo cifrado. |
| `gokapi-fetch` rc 3, HTTP 404 | O link expirou ou o id está errado. Suba de novo. |
| `gokapi-fetch` rc 4 | Não é imagem png, jpeg, webp ou gif, ou passa de 20 MiB. |
| Link de hotlink | Não serve. Copie o link de download, o que tem `?id=`. |

## 6. O que ainda falta (medido em 2026-11-25)

- **Chave do Gokapi.** O caminho 2 usa a mesma entrada do pass do upload, `onion/vps-gokapi/api-upload`. O nome diz
  «upload», mas a chave tem todas as permissões (maestro, 2026-11-25). A variável `GOKAPI_FETCH_PASS_ENTRY` troca a
  entrada. O `ops/gokapi-fetch.sh --check` (core-only) faz uma chamada só de leitura e diz se a permissão de download está lá; a
  primeira medida contra o servidor real fica para depois do merge.
- **Primeiro uso no Windows.** O script do Windows foi escrito e revisado, mas não rodou num Windows ainda: a VPS não tem
  PowerShell. O primeiro uso do maestro é a medição.

## 7. Limites

- Teto de **20 MiB** por imagem nos dois caminhos.
- Tipos aceitos: **png, jpeg, webp e gif**, conferidos pelos bytes do arquivo, não pelo nome.
- A imagem que chega é **dado não confiável**: a sessão a lê como conteúdo, nunca como ordem.
- O atalho do Windows troca o clipboard: depois de usar, o que está lá é o caminho, não mais a imagem.
