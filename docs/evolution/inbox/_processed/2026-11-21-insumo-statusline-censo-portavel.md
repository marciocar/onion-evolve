---
title: "Insumo — statusLine de censo de sessões portável + bloco de settings + «clicar→ir»"
date: 2026-11-21
type: insumo
from: onion-curation
to: onion-evolve
re: "estudo statusline-sessoes-2026-11 (PR #356/#357), parte 1 do veredito perseguir"
reviewed_for_public: true  # relido pelo core em 2026-11-21 como se publicado: script, bloco de settings e cuidados de camada; sem cliente, pessoa nem segredo
status: processed  # costurado no core no PR feat/sessions-statusline-1121 (linha, oferta do /meta:adopt, aviso no merge, bancada sessions_statusline)
---

# Insumo da parte 1 do censo de sessões (para o core costurar)

A curadoria PROPÕE; o core SELA. Isto é o braço da curadoria da **parte 1** do veredito perseguir do estudo
`statusline-sessoes-2026-11` (distribuir a statusLine do censo a todos). Três peças, como você pediu:
(1) o script portável, (2) o bloco de statusLine proposto, (3) a linha do «clicar→ir». **Nada aqui está selado.**

## 1. Script portável — `onion-sessions-line`

Mudança sobre o que roda hoje na curadoria: **zero caminho de home absoluto**. Único resíduo que havia era o
fallback `~/.local/bin/claude`; removido. Agora:

- **binário `claude` só por PATH** (`shutil.which`). Fora do PATH → a atualização falha e caímos no cache ou
  na **lacuna declarada**, nunca num caminho chutado de home.
- **cache em `XDG_RUNTIME_DIR`** (ou tmp do SO) — nunca em `$HOME`. Mantido o TTL de 25 s (evita o processo de
  ~145 MB por refresh) e o STALE de 90 s (mostra a idade da leitura).
- **rc 0 SEMPRE**: uma statusLine que sai != 0 some da barra, então todo caminho (sem leitura, cache velho,
  erro) imprime uma linha e retorna 0. A lacuna é **texto visível**, não silêncio, e **nunca inventa zero**.

Lugar sugerido na instalação do framework (caminho relativo, viaja como o `baton-pulse`):
`.claude/utils/statusline/onion-sessions-line`. Medido aqui: rc 0 no caminho normal e no caminho de lacuna
(sem `claude` no PATH serve o cache; sem cache imprime «sessões: não li o estado»).

```python
#!/usr/bin/env python3
"""Linha da statusLine: quantas sessões trabalham e quantas esperam o Maestro.

Lê `claude agents --json`, a interface suportada (sem mod). Guarda a leitura por TTL segundos, para várias
sessões não dispararem um processo de ~145 MB a cada atualização. Falhou a leitura: mostra a última com a
idade, ou declara a lacuna. NUNCA inventa zero.

Portabilidade (insumo da curadoria, 2026-11-21): zero caminho de home absoluto. O binário `claude` é
resolvido só por PATH (`shutil.which`); se não estiver no PATH, a atualização falha e caímos no cache ou na
lacuna declarada — nunca num caminho chutado de home. O cache mora em XDG_RUNTIME_DIR (ou no tmp do SO),
nunca em $HOME. Sai SEMPRE rc 0: uma statusLine que sai != 0 some da barra, então todo caminho (sem leitura,
cache velho, erro) imprime uma linha e retorna 0. A lacuna é texto visível, não silêncio.
"""
import fcntl
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time

TTL = 25
STALE = 90
CACHE_DIR = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or tempfile.gettempdir(), "onion-sessions-line")
CACHE = os.path.join(CACHE_DIR, "agents.json")
LOCK = os.path.join(CACHE_DIR, "lock")


def age():
    try:
        return time.time() - os.path.getmtime(CACHE)
    except OSError:
        return None


def refresh():
    """Atualiza o cache. Quem não pega a trava serve o que já existe, sem esperar.

    `claude` vem só do PATH. Fora do PATH: FileNotFoundError sobe e o chamador cai no cache/lacuna.
    """
    with open(LOCK, "w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError:
            return
        claude = shutil.which("claude")
        if not claude:
            raise FileNotFoundError("claude não está no PATH")
        out = subprocess.run([claude, "agents", "--json"], capture_output=True, text=True, timeout=5, check=True).stdout
        json.loads(out)
        fd, tmp = tempfile.mkstemp(dir=CACHE_DIR)
        with os.fdopen(fd, "w") as f:
            f.write(out)
        os.replace(tmp, CACHE)


def main():
    os.makedirs(CACHE_DIR, mode=0o700, exist_ok=True)
    current = age()
    if current is None or current > TTL:
        try:
            refresh()
        except (OSError, ValueError, subprocess.SubprocessError):
            pass  # cai no cache ou na lacuna; nunca propaga rc != 0 para a barra
    current = age()
    if current is None:
        print("sessões: não li o estado")  # lacuna declarada: nenhuma leitura ainda
        return
    try:
        with open(CACHE) as f:
            data = json.load(f)
    except (OSError, ValueError):
        print("sessões: leitura ilegível")  # lacuna declarada: cache corrompido
        return
    wait = [x for x in data if x.get("state") == "blocked" or x.get("status") == "waiting"]
    work = [x for x in data if x.get("status") == "busy"]
    line = f"sessões: {len(work)} trabalhando · {len(wait)} esperam você"
    if wait:
        line += ": " + ", ".join(str(x.get("name") or "?")[:24] for x in wait)
    if current > STALE:
        line += f" (leitura de {int(current)} s atrás)"
    print(line)


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # a barra nunca deve quebrar por causa da linha
        print(f"sessões: indisponível ({type(exc).__name__})", file=sys.stdout)
    sys.exit(0)  # rc 0 SEMPRE: statusLine que sai != 0 some da barra
```

## 2. Bloco de statusLine proposto

Para o **settings do usuário** (`~/.claude/settings.json`) e para o **merge do `/meta:adopt`**:

```json
{
  "statusLine": {
    "type": "command",
    "command": "python3 -I <PATH>/onion-sessions-line",
    "refreshInterval": 30
  }
}
```

Dois cuidados **medidos**, que o core precisa decidir na costura:

- **`<PATH>` resolvido na adoção.** No settings de PROJETO o comando roda com cwd = raiz do repo, então um
  caminho relativo (`python3 -I .claude/utils/statusline/onion-sessions-line`) basta. No settings de USUÁRIO o
  cwd varia por sessão, então o `/meta:adopt` deve gravar o **caminho da instalação resolvido** no momento da
  adoção (não um relativo, não um de home chutado).
- **A statusLine de PROJETO substitui a do usuário sem aviso** (o objeto `statusLine` é trocado, não
  mesclado — layers managed > CLI > settings.local.json > settings.json de projeto > settings.json de
  usuário). Um projeto adotado que já tenha a sua própria statusLine **apaga o censo** para aquele projeto.
  Decisão do core: ou o `/meta:adopt` detecta e avisa, ou documenta que a do projeto vence. É o risco que o
  nó `C_FIT_DISTRIBUTION` do estudo declarou.

## 3. «Clicar no nome → ir para a sessão» — já é NATIVO

Não precisa peça nova para a metade «clicar→ir» do pedido do Maestro: o **`claude agents`** (agent view) já
lista por estado (quem espera no topo) e pula para a sessão — seta-esquerda no prompt vazio põe a atual em
segundo plano e pula; `claude attach <id|nome>` pula do shell; `/resume` lista as de fundo. A statusLine é
texto (sem clique); a superfície de clique é o agent view nativo. A band/pane clicável própria
(`D_PIECE_MODS_WIDGETS`, parqueada) só se justifica se **superar** o agent view — é a parte 3, gated.

## Referência

Estudo completo: `docs/evolution/research/statusline-sessoes-2026-11/` (grafo + SYNTHESIS) no repo da
curadoria, PR #356 + correção #357 na main. Veredito perseguir em 3 partes; esta é a parte 1.
