---
branch: feat/deny-bypass-guard
pr: pendente
date: 2026-11-25
reviewed_diff_sha256: 35a89a868207774af27269c4bb4ce5175e451f0c07f64b7e573c66bef3b51f25
reviewed_code_sha256: 028932410c7b9e0f3e22939842cf6c07df62df263a084d2b8cf1007363201c62
findings_total: 17
findings_real: 17
findings_blocking: 4
tokens: 264693
duration_min: 25
findings_fixed: 6
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: "dois refutadores isolados (subagentes general-purpose opus, worktrees próprias, sem o raciocínio do autor): o 1º sobre 6823350d2, o 2º sobre as curas em f8d5f0f9e; a cura da 2ª rodada (5d30e3a66) é a que o 2º refutador propôs e testou no shell, com mutante na bancada"
nota: "PR de GUARDA: muda o .claude/settings.json de todas as sessões e a lib dos vetos. O merge espera o maestro («pode rodar»)."
---

# Passada adversarial: `feat/deny-bypass-guard`

## O que muda

Forja pelo `/meta:forge-guard` do espelho do deny (SAC-551, `Q_DENY_SEGURA_EM_BYPASS_1125`, radar E3 rodada 28). O
`permissions.deny` não segura toda forma de comando em `bypassPermissions`. Os atos irreversíveis que só ele cobria
ganham veto por hook PreToolUse (exit 2), independente dele.

- **Hook novo** `.claude/hooks/pretooluse-deny-mirror.sh`: `git filter-branch`/`filter-repo`; `rm` recursivo da raiz,
  da home (normalizada) e do `.git` do projeto; `gh repo delete`, `gh release delete`, `gh repo edit --visibility`.
- **Lib** `lib/invocation-lines.sh`: o `eval` LITERAL é analisado como `sh -c` (vale para todos os vetos); com
  `ONION_DENY_MIRROR=1` emite as linhas `rm` (com o diretório julgado) e segue o `xargs rm` de stdin literal.
- **protect-main**: o inanalisável com força dura (`-f`, `--force`, `+ref`, `--mirror`) depois do 1º `push` fecha em
  qualquer alvo (antes só com alvo main: `eval "git push -f origin $B"` passava).
- Registro no grupo `Bash` do PreToolUse, com `onFailure: block`. Doutrina: `guard-doctrine` «A camada nativa».
- Grafo: `docs/evolution/research/guard-deny-mirror-2026-11/deny-mirror-2026-11.kg.yaml` (radar `--integrity --schema` rc 0).
- Bancada: família `run_deny_mirror_selftests`.

## Medição contra o uso real

4.040 comandos reais dos transcripts (de 123.258 únicos) reexecutados. O `eval` literal na lib não mudou nenhum
veredito do protect-main nem do merge-gate. A 1ª forma do espelho vetava 8. Seis eram falsos positivos (`.git` de
fixture em rascunho, `filter-branch --help`) e foram curados. Seguem vetados 2: um `--visibility` (o moat-gate também
veta) e um `git filter-branch --msg-filter` numa branch de trabalho (o deny também barra). O 2º refutador reexecutou
mais 703 comandos (`rm` com `.git`, `~`, `HOME`, `xargs`, `eval … push`) sem mudança de veredito.

## Achados

### 1º refutador isolado (sobre 6823350d2): reprovado, 3 bloqueantes, curados em f8d5f0f9e
1. **B1, bloqueia, curado.** `ls && cd . && rm -rf .git` (e `cd .claude && cd ..`, `cd -`) escapava: `cd` condicional
   vira diretório desconhecido e o `.git` passava. Cura: desconhecido veta, salvo se a string cria a pasta antes do rm.
2. **B2, bloqueia, curado.** Falso positivo novo no protect-main: `eval "git push origin $1; tail -f /tmp/l"` vetado
   pelo `-f` do tail. Cura: força só nos tokens depois do `push`, no mesmo segmento.
3. **B3, bloqueia, curado.** `echo / | xargs rm -rf` passava. Cura: o ramo `xargs` da lib segue o `rm`.
4. **L1, limite, curado.** `rm -rf "${HOME:?}"/*`, `~user`, `//home//user`, `~/../user`. Cura: normalização da home.
5. **L2–L6, limite, declarados no grafo** (`T_EVAL_E_SCRIPT_OPACOS_1125`): glob e chaves no alvo, conteúdo de dentro do
   `.git`, binário direto `git-filter-*` e alias com `!`, comando montado por substituição, `gh api -X DELETE repos/o/r`.
6. **L7, limite, declarado:** `rm -rf .git` com a sessão fora do projeto é vetado (cwd do hook nas ROOTS), como o deny.
7. **L8, limite:** sem python3 o regex de reserva só falha fechando.
8. **L9, limite:** `eval cd X` não move o diretório julgado; ganho colateral (`eval "B=main"; git push origin $B` agora veta no merge-gate).

### 2º refutador isolado (sobre f8d5f0f9e): B1, B3 e L1 curados; reprovado por 1 bloqueante, curado em 5d30e3a66
9. **Bloqueia, curado.** O corte guloso (`s/.*\bpush\b//`) guardava só o texto depois do ÚLTIMO `push`:
   `eval "git push -f origin feat/push-$N"`, `--push-option=x`, `-o push` e `# push` voltavam a passar. Cura: corte
   no PRIMEIRO `push` (a que o refutador testou). Mutante (b4) na bancada.
10. **Limite, curado.** `# mkdir` no fim, `mkdir` depois do rm, `which rsync` reabriam o veto do `.git`. Cura: a
    criação conta só antes do 1º `rm`, fora de comentário, como palavra de comando. Mutante (b5).
11. **Limite, declarado:** `cd "$wt" && rm -rf .git` e `cd /tmp/naoexiste && rm -rf .git` agora vetam (antes 0). O
    deny `rm -*r* .git` veta o mesmo comando, e o corpus não tem caso assim. Teto corrigido no grafo.
12. **Limite (antigo):** `rm -rf ~root`, `rm -rf .` e `../..` com cwd na home, `~+/..`.

## Mutantes

`LC_ALL=C bash .claude/validation/lint-selftest.sh --families deny_mirror`: 15 mutantes, um por cura (eval literal
na lib; inanalisável com força no protect-main; força depois do 1º push; segmento do push; emissão do rm na lib; `.git`
no juiz; `.git` do projeto; cd não seguido sem criação; criação antes do rm; xargs com stdin literal; normalização
da home; relevant_mirror no eval dinâmico; gh repo delete; subcomando do git; `--help`).

## Teto

Camada de conformidade, não fronteira de segurança: análise estática não fecha `eval "$X"` opaco, script em arquivo
nem outra linguagem. Fora de propósito (guard-doctrine): `reset --hard`, `--force-with-lease` de branch de trabalho,
`rm -rf` de pasta de trabalho, apagar branch remota de trabalho (apagar a main remota o merge-gate já veta).

## Re-revisão: o CI reprovou duas guardas do selftest (2026-11-25)

1. **`adopter-guard: (m) (d6)` — o mutante sobrevivia.** O juiz do adotante (`lib/adopter-judge.py`) roda em
   `moat_command`, ANTES do ramo `eval` do lib (`lib/invocation-lines.sh`), e os dois faziam `scoped(txt)` do
   eval literal. Com o lib analisando o eval por si (esta PR), tirar a análise do juiz não mudava nada: o texto era
   julgado duas vezes e a linha mutada não carregava o veto. Cura: o juiz deixa o eval literal para o lib e fica só
   com o texto de runtime (`moat_unanalyzable`); o inanalisável cai no `except` do lib, que já chama
   `moat_unanalyzable` com a string inteira. O mutante (d6) passou para a linha que agora carrega o comportamento,
   `if txt and not DYNAMIC.search(txt):` do lib → `if False:`. O caso não foi apagado.
2. **`veto-onfailure: (c) dispatcher — n=11`.** O caso tira o `onFailure` de todos os vetos PreToolUse e espera a
   REGRA 101 em cada um; o `pretooluse-deny-mirror.sh` é o 11º veto, e o número fixo era 10. Cura: o caso exige 11
   e nomeia o deny-mirror, como nomeia os outros.
3. **`adopter-guard: (m) (e13)` reprovava no pré-voo local, não no CI.** O caso fazia `S=/tmp/x; cd $S`. Com o
   diretório existindo, o lib resolve o `cd` por si e a pilha de `cd` do juiz não é consultada, então o mutante
   sobrevivia; no runner `/tmp/x` não existe. Medido com o juiz e o mutante lado a lado: o mutante só morde com o
   diretório ausente. Cura: `S=@R@/../e13-ausente`, um caminho dentro da pasta descartável da bancada que ela
   garante ausente. O caso deixa de depender do disco do host.

