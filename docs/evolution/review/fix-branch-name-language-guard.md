---
branch: fix/branch-name-language-guard
date: 2026-08-10
reviewed_diff_sha256: a277e4ed3166c6f19b23a79bb6d70472817be81b091a3b407122b5ed83b17ac3
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 0
verdict: TRES-DEFEITOS-ACHADOS-PELA-MATRIZ-E-PELO-DIAGNOSTICO-ANTES-DO-EMBARQUE
reviewer: matriz de 10 casos + par de mutação + repro isolada do clobber de trap; sem passada adversarial externa
---

# A guarda de nome de branch — e as três coisas que ela quase escondeu

## O gatilho

O revisor do #575 acusou `code-standards.md:39`: **branch em inglês**. Eu havia nomeado
`fix/fixture-nao-depende-do-vivo` e `docs/waha-rotacao-e-hash` na mesma sessão. O levantamento do repo
mostrou que não é lapso: `docs/fios-abertos`, `fix/catraca-duas-portas`,
`fix/catraca-separador-de-registro`, `fix/selo-m8-vereditos`.

## Por que na hook, e não no lint

O lint roda no **commit** — e ali renomear já custa caro: a branch nomeia o PR e o próprio resíduo da
REGRA 56. Acusar nesse ponto seria **punir quem já não pode corrigir barato**, que é exatamente o erro
da REGRA 56 que ensinou 23 bypasses numa sessão. O instante em que a correção é grátis é a **criação**
(`git branch -m`), e é quando o `PostToolUse` dispara.

## Defeito 1 — a regra ia embarcar VERDE-VAZIA

Reusar `lib/pt-br-words.txt` da REGRA 60 parecia certo (*"uma fonte de palavras, não duas"*). A
premissa é **falsa na prática**: aquela lista é afinada para **identificador de shell**. Medido:

| palavra | estava na lista? |
|---|---|
| `nao`, `depende`, `vivo`, `rotacao`, `duas`, `portas`, `fios`, `abertos`, `selo`, `separador`, `registro` | **ausentes** |
| `chave`, `vereditos` | presentes |

**11 de 13 ausentes.** A regra não disparava em **nenhum** dos nomes reais que motivaram sua criação.
Quem pegou foi a matriz de 10 casos, **antes do embarque** — não o raciocínio, que dizia "reusa a
lista, logo cobre".

É a mesma falha que `.claude/rules/kg-grammar.md` documenta com o grep de `type: REFUTES` num corpus
onde o campo é `edge_type:`: **guarda que nasce passando sempre e guardando nada**.

Lista estendida 74 → 86. **Custo zero**: REGRA 60 segue `0 HARD · 0 no baseline` — nenhum identificador
do repo usa as palavras novas.

## Defeito 2 — a guarda-de-honestidade da bancada estava MUDA desde que nasceu

A bancada morreu no caso **666**, sem soma e sem um único `✗`. A leitura confortável — *"666 verdes"* —
estava disponível.

Existe uma guarda exatamente para isso (`_bench_abort_guard`, linha 63), e o comentário dela descreve
o caso **palavra por palavra**. Ela estava desarmada:

```bash
trap _bench_abort_guard EXIT          # linha 63
...
trap 'rm -rf "${SANDBOX}"' EXIT       # linha 114 — SUBSTITUI a anterior
```

Bash guarda **um handler por sinal**. Ninguém desligou de propósito; a segunda linha não sabia da
primeira. Reproduzido em miniatura: com o clobber a guarda não emite nada; combinada, emite e ainda
entrega o `rc` real.

Cura: um só handler, `_bench_on_exit`, chamando a guarda **primeiro** (sua 1ª instrução é `local rc=$?`,
então o status chega intacto) e limpando depois.

⚠️ **O que isto NÃO prova:** a corrida seguinte deu 786/0/0. A morte no 666 **não se reproduziu** —
logo o conserto cura o **silêncio**, não a morte. Se ela voltar, agora a bancada diz.

## Defeito 3 — colisão de rótulo

Dois casos distintos chamavam-se `(b4)`: o meu e um de outra sessão. `record_fail` com rótulo ambíguo
aponta para o lugar errado justamente quando alguém precisa achar o caso. Meus casos → `(b5)`/`(b5b)`.

## O padrão do dia, e é o que importa

**Duas vezes hoje a cura que a casa já pagou existia e não estava em uso**: a âncora em início de
comando (detector 5), que eu não reusei ao escrever a regra do `pgrep`; e o `_bench_abort_guard`,
desarmado por um `trap` que não sabia dele.

Guarda muda é **pior que guarda ausente**: com guarda ausente você desconfia da saída; com guarda muda
você confia.

## Erros conhecidos, com cura ou superação

| erro | cura ou superação |
|---|---|
| detector por **lista enumerada** só vê o que foi enumerado (teto compartilhado com a REGRA 60) | **cura de hábito**: todo termo pt-BR achado por revisão entra na lista no MESMO movimento em que é corrigido. Sem isso, cada achado se paga uma vez só |
| `PostToolUse` é **posterior** — a branch já foi criada quando o aviso sai | **contorno em runtime**: `git branch -m` é grátis enquanto não há push. **superação**: um `PreToolUse` negaria antes, mas é substrato NÃO-VERIFICADO neste repo (medido e refutado em 2026-08-06) |
| a morte no caso 666 **não tem causa conhecida** | **superação**: a guarda rearmada passa a NOMEAR o abort e o `rc`. Sem reprodução não há o que consertar — o que se conserta é a cegueira |
| outros `trap ... EXIT` podem reintroduzir o clobber | **cura mecanizável, não feita**: um caso de bancada contando `trap .* EXIT` e exigindo ≤1 no arquivo. Fora do gatilho medido; fica proposto |

---

## Acrescentado neste diff — o cofre, e o que ele custou para ficar honesto

`onion-vps-vaultwarden` no ar em `https://vault.onionevolve.com`, com as quatro pendências da
pesquisa pagas. O que vale registrar não é a instalação — é **quanto de "pronto" era falso**.

### A jail nasceu muda, e o contador não sabia dizer

```
$ sudo fail2ban-client get vaultwarden logpath
No file is currently monitored          # com 7 falhas já gravadas no arquivo
```

O backend default desta distro é `systemd`: a jail lia o **journal** e ignorava o `logpath`. O
status mostrava `Total failed: 0` — exatamente o que mostraria se não houvesse ataque nenhum.

**Guarda lendo o lugar errado é indistinguível de guarda funcionando.** A única coisa que separa os
dois é provocar o ataque de verdade — e foi só por isso que apareceu.

### O `IP_HEADER` era a diferença entre proteção e incidente

Atrás do Caddy, toda requisição chega de `127.0.0.1`. Sem `IP_HEADER: X-Forwarded-For` o filtro
leria sempre o mesmo IP, e o primeiro ataque **banaria o loopback** — derrubando o acesso de todos.
A proteção viraria o incidente.

### Três achados menores, cada um com a cura no arquivo

| achado | consequência |
|---|---|
| a imagem não tem `sqlite3` | `sqlite3 ".backup"` sai 127; o embutido `/vaultwarden backup` é o caminho |
| o log subiu no 1º commit do repo do cofre | IP e e-mail de cada tentativa no git — o `.gitignore` foi escrito **antes** do artefato que precisava proteger |
| `code_challenge=abc` no meu teste de SSO | `invalid_request` que eu quase li como config quebrada; o PKCE exige 43+ e **o erro era do teste** |

### O que ficou declarado, e não coberto

- **O backup cifrado mora no mesmo disco.** Protege contra `down -v`, engano humano e outro usuário
  — **não** contra perda do host. Tirá-lo da máquina exige um destino que o maestro confie.
- **`SSO_ONLY=false` por desenho.** SSO autentica quem entra; a senha mestra segue sendo o único
  material que decifra o cofre. O equivalente comercial (Trusted Device Encryption) é PR **aberto**
  no upstream desde 31/07 — planejar com ele seria contar com o que não existe.
