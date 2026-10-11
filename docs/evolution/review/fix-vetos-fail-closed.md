---
reviewed_diff_sha256: pendente
reviewed_code_sha256: c4c6e7d3fc50b78bf8ee24484c44b1d2e210a102c2a468e0c8aa85a840555c16
findings_total: 7
findings_real: 7
tokens: 175944
duration_min: 19
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Uma passada de refutador com o veredito começando em reprovado e mandato de achar falso positivo
  novo, veredito mudado e fail-open. Ele reprovou. As três curas fazem o que prometem e nenhum veredito
  mudou com python3: zero divergência em 745 mil payloads dele, 300 mil tokens comparados entre o shlex
  e o LinearShlex, e 1.500 comandos de fuzz git/gh nos dois vetos. Ele achou sete coisas, todas reais:
  o modo sem python3 ainda abria por aspas, barra, variável e xargs, contradizendo o próprio comentário;
  `git push --mirr` forçava a main com python3 (anterior ao diff); o premodelswitch-guard abria sem
  python3; falsos positivos do modo degradado sem declaração pela forma; um surrogate no JSON derrubava o
  leitor; um terceiro quadrático no env-guard (o `[` sem `]` do fnmatch); e o leitor de JSON em bash era
  quadrático com muitos escapes. Os sete foram curados ou declarados com caso e mutante.
---

# Resíduo — `fix/vetos-fail-closed`

Este PR cura os três achados que a passada adversarial do #1026 (SAC-83, `onFailure: block` nos vetos)
deixou abertos. A evidência medida está no grafo novo `guard-vetos-fail-closed-2026-10`, porque o da r8
está no teto. O `Q_ENV_GUARD_QUADRATICO_ATINGE_TIMEOUT` da r8 fechou.

## As três curas, com medição

1. **Os vetos abriam por dentro sem python3.** O protect-main e o merge-gate da main deram rc 0 em 20 de
   20 sondas com um PATH sem python3, inclusive em `git push --force origin main` e `gh pr merge 1`. O
   `onFailure: block` não cobre exit 0. Agora o JSON é lido em bash, e o veto fecha só no que pode tocar
   o objeto do veto, com uma mensagem que diz que falta python3. Nos 31.183 comandos Bash únicos dos
   transcripts, o recorte final fecha 2,12% no protect-main e 5,71% no merge-gate. O env-guard, que
   está no mesmo matcher, já barra todo Read, Grep e Bash sem python3, e isso ficou declarado no grafo.
2. **PreModelSwitch.** A doc oficial de hooks não o lista entre os eventos em que o campo não tem
   efeito. Medido no 2.1.296 com `claude -p --setting-sources project,local "/model sonnet"`: com o
   script ausente e sem o campo, a troca **foi aplicada**; com `block`, foi **barrada**. O caso honesto
   não muda (exit 0 aplica, exit 2 barra). O log de debug mostra só hooks de troca de modelo, nenhum Stop.
   O campo entrou no settings.json. A REGRA 101 (Veto PreToolUse por exit 2 declara onFailure: block)
   passou a cobrar o evento, com o caso (xiv) e um mutante. O título ficou como estava, porque é o nome
   que os documentos citam. A sonda de caminho honesto do premodelswitch-guard (56 entradas) não produziu
   nenhum código fora de 0 e 2.
3. **env-guard quadrático.** Havia três causas: o regex de `cites_env`, o acumulador do shlex e o
   `fnmatch.translate` com `[` sem `]`. Medição com o comando `echo <token único>`:

   | Tamanho | Antes | Depois |
   |---|---|---|
   | 100 KB | 21,6 s | 0,14 s |
   | 300 KB | 208 s | 0,32 s |
   | 1 MB | mais de 900 s (o medidor cortou) | 0,89 s |

   Com 1 MB de `[` o tempo ficou em 1,05 s. O refutador tinha medido 172 s com 80 KB.

   Nenhum veredito mudou: a comparação antes e depois cobriu 866.219 entradas (o corpus real, dois
   sintéticos e nove de fuzz do refutador), com zero divergência e zero exceção.

## Bancada e mutantes

As famílias tocadas rodaram com `LC_ALL=C`: `pretooluse_veto`, `premodelswitch_guard`, `env_exposure` e
`veto_onfailure`, todas verdes. Os 15 mutantes passaram por `ops/mutate-and-restore.sh`, e cada um
reprovou o próprio caso:

- **M1 e M2:** os hooks ignoram a falta de python3.
- **M3:** o protect-main fecha sem exigir a marca de force.
- **M4:** o `\n` deixa de ser desescapado.
- **M5:** o hook julga o JSON cru em vez do campo.
- **M6:** todo `gh api` passa a fechar.
- **M7:** volta o regex quadrático.
- **M8:** volta o shlex da stdlib.
- **M9:** a lib deixa de expandir a opção abreviada.
- **M10:** as aspas não saem do texto.
- **M11:** a regra dinâmica é desligada.
- **M12:** a marca de force passa a valer no texto inteiro.
- **M13:** sem `errors=backslashreplace`.
- **M14:** o premodelswitch-guard volta a sair 0.
- **M15:** o fnmatch é chamado sem o atalho.

O mutante da REGRA 101 sobre os eventos fica dentro da família `veto_onfailure`.

Com python3, nos 1.361 comandos reais que têm forma git/gh, a comparação dos dois vetos deu 2.722
julgamentos e zero divergência.

## Passada adversarial: REPROVA, curada

1. **MÉDIO, real e curado.** Sem python3, o veto ainda abria por `pu''sh`, `p\ush`, `me\rge`, rota numa
   variável e push vindo do xargs. Isso contradizia o comentário "errar só pode fechar". Agora aspas e
   barra saem antes de casar, uma construção dinâmica (`$`, crase, xargs, eval ou `\u00..` no JSON) com
   git ou gh e uma palavra do objeto fecha, e a marca de force do protect-main vale só no segmento do
   push. Os casos (np-aspas), (np-barra), (np-dyn) e (np-seg) cobrem isso, com os mutantes M10 a M12.
   Ficam declarados dois tetos: o escape `\uXXXX` fora da faixa ASCII imprimível e a chave `command`
   repetida. O Claude Code não gera nenhum dos dois.
2. **ALTO, anterior ao diff, curado.** `git push --mirr origin` forçava a main num remoto bare e passava
   pelos dois vetos com python3. O git aceita prefixo único de opção longa. A lib agora expande o prefixo
   com `push_long_opt`. Os casos `--mirr`, `--mi` e `--al` cobrem isso, com o mutante M9. Com python3, a
   comparação nos comandos reais deu zero divergência.
3. **MÉDIO, real e curado.** O premodelswitch-guard saía 0 sem python3 e liberava o downgrade. Agora os
   campos saem do leitor de JSON em bash da lib. O caso "sem python3" cobre isso, com o mutante M14.
4. **BAIXO, real e declarado.** Sem python3, um comando honesto que só cita o vocabulário passa a fechar:
   echo, heredoc, mensagem de commit ou `gh pr view --json merge` no merge-gate. O custo está declarado
   pela forma no grafo e pela taxa na lib. No core, o env-guard já barra tudo nesse modo.
5. **BAIXO, real e curado.** Com python3, um surrogate solto no JSON derrubava o `print` e o hook caía
   no modo sem python3, o que vetava um push honesto. Agora o hook usa `errors=backslashreplace`, e um
   `tool_input` que não é dict vira vazio. O caso (surrogate) cobre isso, com o mutante M13.
6. **BAIXO, anterior ao diff, curado.** O env-guard era quadrático com `[` sem `]`, por causa do
   `fnmatch.translate` da stdlib. Um `[` depois do último `]` é literal, e nenhum alvo testado contém
   `[`. O caso (q) cobre isso, com o mutante M15.
7. **BAIXO, real e curado.** O leitor de JSON em bash era quadrático com muitos escapes: 41 s com 1 MB
   de `\"`. A cura trocou o `${v//…}` por um awk só, que leva 0,93 s com 1 MB.

## Achado lateral, declarado e não curado

O env-guard tem um falso positivo anterior a este PR, que apareceu ao vivo enquanto eu media. Depois de
um `cd` com variável, ele barra um glob absoluto sem relação com `.env`. Está registrado no nó
`C_ENV_GUARD_GLOB_ABSOLUTO_APOS_CD_VARIAVEL`, com gatilho.

## Commits

Os commits usaram `--no-verify` como checkpoint. O gate final é o `ops/pr-finalize.sh` com o CI.

## Passada pós-CI (2026-10-11)

O selftest da faixa 2 reprovou na catraca do pipefail: 7 sítios `printf | grep -q` em
`.claude/hooks/lib/invocation-lines.sh` contra a catraca de 1. Convertidos para here-string,
e o pipe de segmentos do push virou variável intermediária, com o veredito por here-string.
Comportamento idêntico: `pretooluse_veto` + `env_exposure` + `shell_pipefail_robustness`
deram 228/228. O SHA volta a `pendente` e o `pr-finalize` recalcula.
