<#
.SYNOPSIS
  Ponte de imagem do Onion, lado Windows: manda a imagem do clipboard para a VPS e deixa o CAMINHO no clipboard.

.DESCRIPTION
  O maestro tira um print (Win+Shift+S), aperta o atalho (padrão Ctrl+Alt+I) e cola (Ctrl+V) na sessão do
  Claude Code que roda na VPS. O que este script faz entre o atalho e o Ctrl+V:
    1. pega a imagem do clipboard do Windows (print, ou um arquivo de imagem copiado no Explorer);
    2. grava um PNG temporário e confere o tamanho (teto de 20 MiB);
    3. envia por sftp, com a chave SSH que o maestro já usa, para a pasta privada de imagens recebidas na VPS
       (~/.local/share/onion/inbox-images, pasta 0700, arquivo 0600), com o nome AAAAMMDD-HHMMSS-win-XXXX.png;
    4. troca o conteúdo do clipboard pelo CAMINHO absoluto do arquivo na VPS e avisa num balão do Windows.
  O Claude Code aceita imagem pelo caminho do arquivo no disco onde ele roda (doc oficial, «Work with images»).

  Por que sftp e não o Gokapi: veja ops/windows/README.md. Nenhum IP, usuário ou senha mora aqui: o destino é um
  apelido do ~/.ssh/config (o mesmo do mosh), guardado em %APPDATA%\Onion\onion-paste-image.config.psd1 (fora da
  pasta do script: uma cópia do repo nunca carrega a config de ninguém).

.PARAMETER SshHost
  Apelido do ~/.ssh/config (ou usuario@host) da VPS. Gravado na config no 1º uso.

.PARAMETER Setup
  Primeiro uso: pergunta/grava o SshHost, cria a pasta na VPS (0700) e descobre o caminho absoluto dela.

.PARAMETER InstallShortcut
  Cria no Menu Iniciar um atalho com tecla de atalho (padrão Ctrl+Alt+I) que roda este script escondido.

.PARAMETER Hotkey
  Tecla do atalho para -InstallShortcut, no formato do Windows (ex.: "CTRL+ALT+I").

.PARAMETER Quiet
  Não abre balão; só escreve no console (para quem roda pelo terminal).

.EXAMPLE
  powershell -STA -NoProfile -ExecutionPolicy Bypass -File .\onion-paste-image.ps1 -Setup -SshHost vps
.EXAMPLE
  powershell -STA -NoProfile -ExecutionPolicy Bypass -File .\onion-paste-image.ps1 -InstallShortcut
#>
[CmdletBinding()]
param(
  [string]$SshHost,
  [switch]$Setup,
  [switch]$InstallShortcut,
  [string]$Hotkey = 'CTRL+ALT+I',
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

$ConfigDir  = Join-Path $env:APPDATA 'Onion'
$ConfigPath = Join-Path $ConfigDir 'onion-paste-image.config.psd1'
$RemoteRel  = '.local/share/onion/inbox-images'
$MaxBytes   = 20MB

function Show-Note([string]$Title, [string]$Text, [bool]$IsError = $false) {
  if ($IsError) { Write-Host "$Title - $Text" -ForegroundColor Red } else { Write-Host "$Title - $Text" -ForegroundColor Green }
  if ($Quiet) { return }
  try {
    Add-Type -AssemblyName System.Windows.Forms, System.Drawing
    $n = New-Object System.Windows.Forms.NotifyIcon
    $n.Icon = [System.Drawing.SystemIcons]::Information
    if ($IsError) { $n.Icon = [System.Drawing.SystemIcons]::Error }
    $n.BalloonTipTitle = $Title
    $n.BalloonTipText = $Text
    $n.Visible = $true
    $n.ShowBalloonTip(4000)
    Start-Sleep -Milliseconds 4500
    $n.Dispose()
  } catch { }
}

function Fail([string]$Text) {
  Show-Note 'Onion: imagem NÃO enviada' $Text $true
  exit 1
}

function Read-Config {
  if (Test-Path -LiteralPath $ConfigPath) { return Import-PowerShellDataFile -LiteralPath $ConfigPath }
  return @{}
}

function Write-Config([string]$HostAlias, [string]$RemoteDir) {
  $body = "@{`r`n  SshHost   = '$($HostAlias -replace "'", "''")'`r`n  RemoteDir = '$($RemoteDir -replace "'", "''")'`r`n}`r`n"
  if (-not (Test-Path -LiteralPath $ConfigDir)) { New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null }
  Set-Content -LiteralPath $ConfigPath -Value $body -Encoding UTF8
}

function Test-Tools {
  foreach ($t in 'ssh', 'sftp') {
    if (-not (Get-Command $t -ErrorAction SilentlyContinue)) {
      Fail "falta o $t do Windows (OpenSSH Client). Instale em Configurações > Sistema > Recursos opcionais > Cliente OpenSSH."
    }
  }
}

# ── atalho com tecla (Menu Iniciar: o Windows só honra tecla de atalho em .lnk da Área de Trabalho ou do Menu Iniciar)
if ($InstallShortcut) {
  $dir = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
  $lnk = Join-Path $dir 'Onion - colar imagem na VPS.lnk'
  $ws = New-Object -ComObject WScript.Shell
  $s = $ws.CreateShortcut($lnk)
  $s.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
  $s.Arguments = "-STA -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  $s.WorkingDirectory = $PSScriptRoot
  $s.Hotkey = $Hotkey
  $s.WindowStyle = 7
  $s.Description = 'Onion: manda a imagem do clipboard para a VPS e deixa o caminho no clipboard'
  $s.Save()
  Show-Note 'Onion: atalho criado' "Tecla $Hotkey (Menu Iniciar). Tire o print, aperte $Hotkey e cole na sessão."
  exit 0
}

# ── primeiro uso: grava o host e descobre o caminho absoluto da pasta na VPS (uma conexão, uma vez)
$cfg = Read-Config
if ($SshHost) { $cfg.SshHost = $SshHost }
if ($Setup -or -not $cfg.ContainsKey('RemoteDir') -or -not $cfg.RemoteDir) {
  Test-Tools
  if (-not $cfg.SshHost) { $cfg.SshHost = Read-Host 'Apelido do ~/.ssh/config da VPS (o mesmo do mosh), ou usuario@host' }
  if (-not $cfg.SshHost) { Fail 'sem SshHost: rode de novo com -Setup -SshHost <apelido>' }
  $remoteCmd = "umask 077; mkdir -p ~/$RemoteRel && chmod 700 ~/$RemoteRel && cd ~/$RemoteRel && pwd -P"
  $abs = & ssh -o BatchMode=yes -- $cfg.SshHost $remoteCmd
  if ($LASTEXITCODE -ne 0 -or -not $abs) { Fail "não consegui preparar a pasta na VPS por ssh $($cfg.SshHost) (a chave SSH está carregada? o apelido existe no ~/.ssh/config?)" }
  $abs = ($abs | Select-Object -Last 1).Trim()
  if ($abs -notmatch '^/[^\s''"]+$') { Fail "caminho estranho devolvido pela VPS: $abs" }
  $cfg.RemoteDir = $abs
  Write-Config $cfg.SshHost $cfg.RemoteDir
  if ($Setup) { Show-Note 'Onion: ponte de imagem pronta' "Destino $($cfg.SshHost):$($cfg.RemoteDir). Config em $ConfigPath"; exit 0 }
}

Test-Tools
# a config pode ter sido editada à mão: o caminho remoto vai entre aspas no batch do sftp, então nada de espaço nem aspas
if ($cfg.RemoteDir -notmatch '^/[^\s''"]+$') { Fail "RemoteDir inválido na config ($($cfg.RemoteDir)): rode de novo com -Setup" }
Add-Type -AssemblyName System.Windows.Forms, System.Drawing
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
  Fail 'o clipboard pede modo STA: rode com powershell -STA (o atalho criado por -InstallShortcut já faz isso).'
}

# ── 1. a imagem do clipboard: bitmap (print) ou arquivo de imagem copiado no Explorer
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$rand  = -join ((48..57) + (97..102) | Get-Random -Count 4 | ForEach-Object { [char]$_ })
$name  = "$stamp-win-$rand.png"
$tmp   = Join-Path ([System.IO.Path]::GetTempPath()) $name
try {
  if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
    $img = [System.Windows.Forms.Clipboard]::GetImage()
    $img.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
  } elseif ([System.Windows.Forms.Clipboard]::ContainsFileDropList()) {
    $src = [System.Windows.Forms.Clipboard]::GetFileDropList() | Where-Object { $_ -match '\.(png|jpe?g|gif|webp)$' } | Select-Object -First 1
    if (-not $src) { Fail 'o clipboard tem arquivos, mas nenhum é imagem png, jpg, gif ou webp.' }
    # confere pelos bytes, não só pelo nome (a VPS recebe o arquivo como veio)
    $fs = [System.IO.File]::OpenRead($src)
    try { $hd = New-Object byte[] 12; [void]$fs.Read($hd, 0, 12) } finally { $fs.Dispose() }
    $hex = -join ($hd | ForEach-Object { $_.ToString('x2') })
    # a extensão sai dos BYTES, como no gokapi-fetch.sh da VPS: um .png que é jpeg chega como .jpg
    $ext = $null
    if ($hex.StartsWith('89504e470d0a1a0a')) { $ext = '.png' }
    elseif ($hex.StartsWith('ffd8ff')) { $ext = '.jpg' }
    elseif ($hex.StartsWith('474946383761') -or $hex.StartsWith('474946383961')) { $ext = '.gif' }
    elseif ($hex.StartsWith('52494646') -and $hex.Substring(16, 8) -eq '57454250') { $ext = '.webp' }
    if (-not $ext) { Fail "o arquivo copiado não é imagem png, jpg, gif ou webp pelos bytes: $src" }
    $name = "$stamp-win-$rand$ext"
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) $name
    Copy-Item -LiteralPath $src -Destination $tmp
  } else {
    Fail 'não há imagem no clipboard. Tire o print (Win+Shift+S) ou copie a imagem e aperte o atalho de novo.'
  }

  # ── 2. teto de tamanho
  $len = (Get-Item -LiteralPath $tmp).Length
  if ($len -le 0) { Fail 'a imagem salva saiu vazia.' }
  if ($len -gt $MaxBytes) { Fail ("a imagem tem {0:N1} MiB; o teto é 20 MiB." -f ($len / 1MB)) }

  # ── 3. envio por sftp, uma conexão: cria a pasta se sumiu, envia e fecha o arquivo em 0600
  $remote = "$($cfg.RemoteDir)/$name"
  # o batch vai num ARQUIVO UTF-8 sem BOM: o pipe do PowerShell 5.1 é ASCII e trocaria «João» por «Jo?o» no caminho
  # do TEMP; barras normais no caminho local, que o sftp do OpenSSH do Windows aceita
  $localFwd = $tmp -replace '\\', '/'
  $batch = @(
    "-mkdir `"$($cfg.RemoteDir)`"",
    "put `"$localFwd`" `"$remote`"",
    "chmod 600 `"$remote`""
  )
  $batchFile = "$tmp.sftp"
  [System.IO.File]::WriteAllLines($batchFile, [string[]]$batch, (New-Object System.Text.UTF8Encoding $false))
  & sftp -q -o BatchMode=yes -b $batchFile -- $cfg.SshHost | Out-Null
  if ($LASTEXITCODE -ne 0) { Fail "o envio por sftp para $($cfg.SshHost) falhou (rede, chave SSH ou pasta). Teste no terminal: ssh $($cfg.SshHost)" }

  # ── 4. o caminho remoto vai para o clipboard, pronto para o Ctrl+V na sessão
  Set-Clipboard -Value $remote
  Show-Note 'Onion: imagem enviada' "Caminho no clipboard. Cole (Ctrl+V) na sessão: $remote"
} finally {
  foreach ($f in @($tmp, "$tmp.sftp")) {
    if (Test-Path -LiteralPath $f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue }
  }
}
