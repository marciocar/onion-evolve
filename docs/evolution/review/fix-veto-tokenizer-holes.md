---
branch: fix/veto-tokenizer-holes
pr: pendente
date: 2026-11-11
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_blocking: 2
tokens: 0
duration_min: 0
findings_fixed: 3
verdict: FIXED
elenxo: false
reviewer: agente de execução (passada própria; o brief da sessão principal proibiu lançar agentes, então não houve refutador independente)
nota: "tokens e duração não medidos. A passada é do mesmo agente que escreveu a cura: falta o refutador independente que o preâmbulo pede, e isso fica declarado para a sessão principal decidir antes do merge."
---

# Passada adversarial: `fix/veto-tokenizer-holes`

## O que muda

Cura de SAC-390 (decisão D_PRIORIDADE_CURA_DOS_VETOS_1111): vinte formas medidas pelo juiz do radar E3 r24 passavam
com rc 0 nos vetos PreToolUse. A cura mora no ponto comum sempre que existe um:

- `lib/invocation-lines.sh` (tokenizador partilhado por merge-gate, protect-main, moat-gate, plugin-write e adopter):
  a atribuição de prefixo casa com `re.S` (valor citado com quebra de linha); `env -C D`/`--chdir=D` é seguido como
  `cd` de escopo próprio, por `chdir_target`, que os juízes hospedados podem redefinir; o rabo literal de
  `xargs git push …` é julgado como comando.
- `lib/moat-judge.py` (juiz de escrita, composto pelo plugin-write): o `w`/`W` do script do sed e a flag `w` do `s///`
  gravam; e o `env -C` dos juízes de escrita segue a pasta literal que só nasce na mesma string, como o `cd` já seguia.
- `lib/adopter-judge.py`: a leitura própria do `env -C` (B2) saiu, porque ficou morta; fica só a sobrescrita do
  `chdir_target` com o que é do adotante (`$HOME`, o `cd -P` que só este juiz segue).
- `pretooluse-env-guard.sh` (tokenizador próprio): `$'…'` decodificado e `$"…"` sem o `$`, fora de aspas.

## Achados

1. **(bloqueante, curado)** O mutante (i7) do adopter-guard virou não load-bearing: com a lib tirando o invólucro `env`
   antes, a leitura própria do adopter-judge nunca mais via o `env -C`. Achado pela bancada `adopter_guard`. Cura: a
   lib passou a resolver o diretório por `chdir_target`, o adopter-judge a sobrescreve para o `$HOME`, o bloco morto
   saiu, o (i7) mira a lib e o (i7b) novo prova o `$HOME`.
2. **(bloqueante, curado)** `mkdir -p .claude/skills/y && env -C .claude/skills/y mkdir hooks` passava: a regra
   estrita do `cd` na lib exige a pasta no disco, e ela só nasce em runtime. O `cd` equivalente já barrava. Cura: o
   moat-judge sobrescreve `chdir_target` para seguir a pasta literal; os vetos de merge e force-push não carregam esse
   juiz e ficam com a regra estrita, que nunca isenta. Caso novo e mutante J2.
3. **(não bloqueante, curado)** A mensagem do caso (u) do env-exposure declarava 50 leituras barradas; contadas no
   código, são 49.

Variantes testadas que já barravam ou calavam como devem: `env A=$'b\nc' git push`, `env -i -C .`, `env -C ./nada`,
`env -C $X`, `cd docs && env -C ..`, `xargs git push -f origin main` no protect-main, prefixo com quebra antes de
`cat .env`, `sed -E`/`-i.bak -e`/`--expression 'w …'`, e os honestos `sed -e :a -e '$!N;…;ta'`, `sed -n '/\/hooks\//p'`,
`sed 's/a/w b/'`, `sed 'y/wab/xyz/'`, `cat $'.envrc'`.

## Mutantes

Pela bancada (cópia, `_pvmut`, `_pw_mut`, tabela do adopter e mutantes do U4): nl1–nl5 e xa1 (pretooluse_veto),
L1, L2, J1, J2 (plugin_write_guard), i7 e i7b (adopter_guard), M35 (env_exposure). Pelo `ops/mutate-and-restore.sh`
sobre a sonda de SAC-390: `re.S` (8 divergências), xargs (1), `env -C` (1), `sed w` (1), ANSI-C do env-guard (6), todos
rc 1; o controle positivo sem efeito sobreviveu (rc 0).

## Re-revisão de 2026-11-11

Depois do rebase, o único código novo no diff é a linha do teto do grafo da rodada r24 (de 25 para 30 nós, com a razão: a evidência da cura entrou como nó próprio). Conferido: radar `--integrity --schema` exit 0 e o diff toca os mesmos arquivos de código que o refutador revisou (rebase sem conflito).

## Limites declarados

- Expansão dinâmica segue fora: `$(echo git)`, `eval` montado, variável com nome de comando.
- `sed -f arquivo` com `w` dentro do arquivo de script não é lido; `env` com `-C` colado num grupo de opções curtas
  (`-iC dir`) não é seguido.
- O parser do script do sed é heurístico: só acusa quando o nome extraído tem a forma guardada, então o erro dele
  tende a calar.
- `$'…'` com escape que o Python não decodifica (fora do latin-1) fica como estava, sem decodificar.
- Os vetos são contenção de acidente, não fronteira de segurança.
