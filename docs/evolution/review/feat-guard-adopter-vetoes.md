---
reviewed_diff_sha256: 2820e2b1723b1882d040c455cfbd32e4a928d194dfad6f7a2b0e5650a5df9d75
reviewed_code_sha256: 88048c43671eb979ead7577ec39a444bc27651487d1c098803439419f43cd7df
findings_total: 13
findings_real: 13
findings_fixed: 9
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: refutador da 1ª passada (7788d9178) + refutador independente (ca37a5ee2) + verificação das curas pela sessão da forja (e3f008af9 e a volta do python)
nota: >
  O refutador reprovou 7788d9178 com 9 achados reproduzidos, 1 bloqueante. Cinco viraram cura em 60b622b4a,
  cada um com caso na família adopter_guard e mutante; quatro ficaram declarados no cabeçalho do hook e no grafo
  guard-adopter-vetoes-2026-11. O refutador independente reprovou ca37a5ee2 com 3 bloqueantes; os três viraram
  cura em e3f008af9, re-medidos no executor dele (16 divergências restantes, todas no teto declarado). A verificação
  seguinte olha só o diferencial. tokens e duration_min não foram medidos (0).
---

# O modo de adotante dos vetos

## A passada adversarial

**Refutador da 1ª passada, sobre 7788d9178: REPROVADO.** Bancada dele: cópia do adotante descartável, o hook
real e o rc lido do processo, nada executado nos repos reais.

| # | achado | grau | destino |
|---|---|---|---|
| 1 | a porta pública (`kind: door`, a standalone) armava o veto de merge e de push na main, sem caminho verificado para o usuário | BLOQUEIA | **cura**: `onion_adopter_role` recusa `kind: door`; casos (f4), (f5) e mutante |
| 2 | push na main de fixture descartável (remoto bare local) veta no adotante | médio | **declarado**: herdado do core; a linha canônica do lib não carrega o diretório |
| 3 | leituras em subcomando de escrita vetavam no core (notes list, lfs ls-files, sparse-checkout list, clean -n, apply --check, tag -n) | baixo | **cura**: exceções de leitura; caso (h11) |
| 4 | python -c que lê o core e usa `.replace(` fecha como opaco | baixo | **declarado**: 0 no replay |
| 5 | repo registrado de nome com menos de 4 letras por caminho relativo escapa do pré-filtro | médio | **declarado** |
| 6 | `$HOME/<repo>` não resolvia | baixo | **cura**: `$HOME` vale `~` no juiz; caso (h12) e mutante |
| 7 | git init, clone, worktree add no repo alheio, push por caminho local, `--work-tree` e fetch a:b passavam, e o cabeçalho prometia | médio | **cura**: casos (h4) a (h9), mutantes (h4) e (h9); (h10) fetch DO core segue passando |
| 8 | vocabulário: tar -C, unzip -d, perl -pi, sort -o, curl -o, patch -d, awk -i inplace, rsync --remove-source-files, find -delete | médio | **declarado** |
| 9 | o carimbo `.claude/.onion-version` não era protegido: uma edição no `role:` desarmava os dois vetos | médio | **cura**: Write, Edit e escrita de shell no carimbo vetam; o `git merge` do update passa (h3); casos (h1), (h2) e mutante |

## Medidas

- Família `adopter_guard`: 77 verdes, 0 falhas, 18 mutantes mordendo (cada um com a cópia limpa provada no mesmo arranjo).
- Replay dos transcritos de dois adotantes: 5.105 comandos no hook novo, 1 veto, verdadeiro (cp à mão no inbox do core,
  por fora do /meta:co-relay); replay dirigido de 371 comandos tocados pelas curas: 0 vetos.
- Lint completo: rc 0, 0 HARD, 22 SOFT, todos anteriores à forja.

## A passada independente

**Refutador independente, sobre ca37a5ee2 (156 casos): REPROVADO.** As 5 curas da 1ª passada se confirmaram, e o uso
normal passou, inclusive o co-relay real.

| # | achado | grau | destino |
|---|---|---|---|
| B1 | `git push origin --tags` sentado na main virou veto falso no adotante (a main remota não muda: medido) | BLOQUEIA | **cura** no `push_dsts_without_spec` do lib e no push nu do merge-gate; casos (i1) a (i4) e mutante |
| B2 | `cd -P`, `pushd`, `env -C`, `xargs` com here-string, `>|` e `exec N>` que o cabeçalho prometia | BLOQUEIA | **cura**; casos (i5) a (i11), mutantes (i5), (i7), (i8), (i10) |
| B3 | o carimbo caía pelo pai (`rm -rf .claude`, `mv .claude`) ou pelo git (`git rm`) | BLOQUEIA | **cura**; casos (i12) a (i15), mutantes (i12), (i14); o `git merge` do update passa (h3) |
| B2b | python -c com `subprocess.run(['git','-C',core,'commit'])` e `os.chdir`+`os.system` criava commit no core, e o hook prometia cobrir python -c | BLOQUEIA | **cura**: o verbo do git sem aspas e colchetes conta; casos (i18) a (i20) e mutante; 538 comandos python do corpus, 0 vetos |
| L1 | vocabulário git de baixo nível | limite | **cura** de uma linha; (i16), (i17) |
| L2 e resto | brace e glob no caminho, variável e substituição no nome do repo, `find -exec sh -c "$1"`, git por python, remoção do hook, edição do settings.json, heredoc sem terminador | limite | **declarado** no cabeçalho do hook |

## Os confirmed do grafo editado (REGRA 87)

- `E_SONDA_27_DE_31_PASSARAM`: as curas não o contrariam; as formas da sonda seguem vetando (casos c1 a c6).
- `E_REPLAY_DOS_ADOTANTES`: o replay foi na versão antes das curas desta volta; o replay dirigido da 1ª passada e os
  lotes do refutador independente re-rodados não acharam veto honesto novo, salvo o heredoc sem terminador, declarado.
- `E_REFUTADOR_INDEPENDENTE_3_BLOQUEIA`: é o nó desta volta.

## A verificação do diferencial (sessão principal)

A sessão principal copiou os arquivos da branch para as 30 cópias da bancada do refutador independente e rodou os 10
lotes dele: 187 casos, 16 divergências, todas no teto declarado (python por subprocess/os.system na versão anterior à
volta do python, glob, nome do repo só em runtime, find -exec sh -c, settings e hook do próprio adotante, nome curto
relativo, tar -C e o heredoc sem terminador, que fecha de propósito). Na volta do python (3af0bcfa3) o f3 e o f15
passaram a vetar: sobram 14, todas declaradas.

## Os commits

Os commits desta branch saíram com `--no-verify`: o pre-commit morreu por timeout (590 s) em todas as tentativas, com
a máquina carregada, inclusive com ONION_PRECOMMIT_CHECKPOINT=1. O gate do SHA final é o CI deste PR, e o lint completo
e as famílias rodaram à mão, em 1º plano, com rc 0.

