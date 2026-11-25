# Ponte de imagem — lado Windows

`onion-paste-image.ps1` manda a imagem do clipboard do Windows para a VPS e deixa no clipboard o **caminho** do
arquivo na VPS, pronto para colar (Ctrl+V) na sessão do Claude Code. Guia completo, com o segundo caminho (Gokapi) e o
que fazer quando dá errado: `docs/knowledge-base/concepts/send-image-to-session.md`.

## Instalar (uma vez)

Pré-requisito: você já entra na VPS por `ssh` ou `mosh` com chave, usando um apelido no `~/.ssh/config` do Windows
(por exemplo `Host vps`). O «Cliente OpenSSH» do Windows precisa estar instalado (já vem no Windows 10 e 11).

1. Copie esta pasta (`ops/windows/`) para o Windows, por exemplo em `C:\Users\<você>\onion\`.
2. No PowerShell, dentro da pasta, prepare o destino (cria a pasta na VPS e grava a config ao lado do script):

   ```powershell
   powershell -STA -NoProfile -ExecutionPolicy Bypass -File .\onion-paste-image.ps1 -Setup -SshHost vps
   ```

3. Crie o atalho de teclado (padrão **Ctrl+Alt+I**; troque com `-Hotkey "CTRL+ALT+P"`):

   ```powershell
   powershell -STA -NoProfile -ExecutionPolicy Bypass -File .\onion-paste-image.ps1 -InstallShortcut
   ```

Pronto. Uso: **Win+Shift+S** → **Ctrl+Alt+I** → **Ctrl+V** na sessão.

A config fica em `%APPDATA%\Onion\onion-paste-image.config.psd1`, com o apelido SSH e a pasta remota. Ela fica fora da
pasta do script de propósito: a pasta pode ser uma cópia do repo, e o `.gitignore` daqui ainda recusa `*.config.psd1`
por garantia. Não há IP, usuário nem senha no script.

## Atalho mais rápido (opcional): AutoHotkey

O atalho do Windows (arquivo .lnk no Menu Iniciar) às vezes demora uns segundos. Com o AutoHotkey v2 instalado, um
arquivo `onion.ahk` responde na hora:

```autohotkey
^!i:: Run 'powershell.exe -STA -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\<você>\onion\onion-paste-image.ps1"', , 'Hide'
```

Ponha o `onion.ahk` em `shell:startup` para ele abrir com o Windows. Se usar o AutoHotkey, apague o atalho
«Onion - colar imagem na VPS» do Menu Iniciar, para a tecla não rodar duas vezes.

## Dois cuidados do Windows

- **Histórico do clipboard (Win+V) e sincronização entre dispositivos.** Se estiverem ligados, o print e depois o
  caminho ficam guardados no histórico, e a sincronização os manda à nuvem da Microsoft. Para print com dado sensível,
  desligue em Configurações > Sistema > Área de transferência, ou apague o item no Win+V depois de usar.
- **`-ExecutionPolicy Bypass` e a marca da web.** O atalho roda o script com `Bypass`, que ignora a política de
  execução, inclusive a marca «baixado da internet» (Mark-of-the-Web) que o `RemoteSigned` usaria para barrar o arquivo.
  Então quem consegue editar o `.ps1` consegue rodar código no seu login. Guarde a pasta no seu perfil, leia o script
  antes de usar, e se ele veio por navegador ou anexo, rode `Unblock-File .\onion-paste-image.ps1` só depois de ler.
  Se preferir não usar `Bypass`, troque no atalho por `-ExecutionPolicy RemoteSigned` depois do `Unblock-File`.

## Por que sftp, e não o Gokapi

- **É o padrão de mercado** para copiar um arquivo a um servidor Linux, e já vem no Windows (OpenSSH).
- **Usa a chave SSH que você já tem.** O Gokapi pediria uma chave de API guardada no Windows: mais um segredo na
  área de trabalho, sem ganho.
- **Menos passos e nada novo na VPS.** Uma conexão envia, fecha o arquivo em 0600 e pronto. Sem serviço novo.
- O Gokapi segue como o **segundo caminho**, para o celular ou outra máquina sem a sua chave SSH: cola a imagem no
  navegador e a sessão baixa com `ops/gokapi-fetch.sh`. Por isso este script não tem modo `-Via gokapi`.

## O que o script garante

- Imagem do clipboard (print) ou o primeiro arquivo de imagem copiado no Explorer (png, jpg, gif, webp), com a
  extensão tirada dos bytes, não do nome.
- Teto de 20 MiB, conferido antes de enviar.
- Nome `AAAAMMDD-HHMMSS-win-XXXX.png`, o mesmo formato que a limpeza da VPS (`ops/gokapi-fetch.sh --prune`) reconhece.
- Na VPS: pasta `~/.local/share/onion/inbox-images` em 0700 e arquivo em 0600.
- O arquivo temporário do Windows é apagado no fim, com sucesso ou erro.
- Erro vira balão vermelho com o motivo; nada falha calado.

## Limite medido

Este script não rodou num Windows ainda: a VPS não tem PowerShell (`pwsh`), então nem a sintaxe foi conferida
lá. A bancada do core (`lint-selftest.sh --families image_bridge`) confere a sintaxe quando houver `pwsh` e declara a
lacuna quando não houver.
