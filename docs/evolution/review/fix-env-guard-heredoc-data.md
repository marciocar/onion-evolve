---
reviewed_diff_sha256: 7c3fbf2a43fef6edca5338eec61d2b59371d4f3aac3ec80e2b90efaf89f1c603
reviewed_code_sha256: 1cda782a2cc163277260b6d6fba546fa8347fb832278e7f0ca895729de674769
findings_total: 37
findings_real: 36
tokens: 307288
duration_min: 40
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  O veto do .env (PR #932) lia cada linha do CORPO de um heredoc como comando. Medido ao abrir o PR #933:
  uma linha de markdown começando com `**` (glob que casa `.env`) barrou um `cat > corpo.md <<'EOF'` —
  texto inerte. Na outra direção, um ESCAPE que já existia na main: o heredoc sem aspas com crase em volta
  de um `cat .env` passava, porque o `cites_env` não tinha a crase como fronteira.
  Três passadas do Elenxo (opus, mandato REFUTAR):
  1ª REPROVOU a 1ª cura (corpo = dado por padrão): 26 escapes contra a main — pipe para shell, invólucro com
  argumento (`sudo -u x bash`), ssh/docker/kubectl, awk, heredoc dentro de `$(`, dois heredocs numa linha,
  delimitador cortado pelo regex (`<<END-X`), `<<` dentro de aspas ou comentário, `$( (…) )`.
  2ª REPROVOU a 2ª cura (análise linha a linha): 9 escapes confirmados executando `echo PWNED` no bash
  real — heredoc externo não rastreado, aspas atravessando linhas, `\` de continuação, `<<-` mal tokenizado,
  `>(sh)`, `git -c alias.x='!sh'`, `git hook run`, script gravado sem extensão e executado, `>|`/`&>`.
  3ª foi interrompida por um classificador de segurança antes de medir; os pontos que ela listou foram
  medidos NESTA sessão (bateria t3, cura × main): 1 escape real (`cat <<'E' >&3`, descritor que pode ser
  arquivo) → curado; `cat <<'E'; bash` NÃO é escape (o heredoc é do cat; o bash lê o próprio stdin).
  Desenho final (o mais estreito que serve ao caso legítimo): só o 1º `<<` do comando é candidato; o
  PREFIXO inteiro até a linha do operador tem de provar — um único `<<`, nenhuma aspa aberta, nenhum `\`
  de continuação, nenhuma substituição (`$(`, `<(`, `>(`, crase) —; nada de `|` depois do operador;
  consumidor numa lista FECHADA (cat, tee, gh sem alias, ou exatamente `git commit`); delimitador de palavra
  simples e terminador presente. Qualquer dúvida → nada se separa e tudo é julgado como na main. Corpo que
  cita .env e é GRAVADO (tee, > >> >| &>, descritor >= 3) é sempre vetado — qualquer arquivo pode virar
  script depois; corpo sem aspas com substituição que cita .env também.
  Bancada: caso (k) da família env_exposure, 30 casos (os falsos positivos medidos + um representante de
  cada classe de escape das três passadas). Mutantes: a 1ª cura, a 2ª cura e a main — os três reprovam o (k).
  Tetos declarados (a main também os tem): nome montado em runtime (`.e${n}nv`); `gh alias import` que
  define um alias e o roda depois; dois heredocs na mesma linha caem no lado fechado (falso positivo raro).
  Custo novo, de propósito: gravar em arquivo, por heredoc, um texto que CITA .env passa a ser vetado — a
  mensagem manda usar a ferramenta Write (este próprio resíduo foi escrito assim).
---
