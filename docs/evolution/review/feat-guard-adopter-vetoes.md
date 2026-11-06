---
reviewed_diff_sha256: 3288faaa39864a8f2b68d5f8912012ca19c72836e18bafb1a57c00494ec1e7c0
findings_total: 12
findings_real: 12
findings_fixed: 8
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: refutador da 1ª passada (7788d9178) + refutador independente (ca37a5ee2) + verificação das curas pela sessão da forja (e3f008af9)
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
| L1 | vocabulário git de baixo nível | limite | **cura** de uma linha; (i16), (i17) |
| L2 e resto | brace e glob no caminho, caminho em runtime, `find -exec sh -c "$1"`, git por python, remoção do hook, edição do settings.json, heredoc sem terminador | limite | **declarado** no cabeçalho do hook |

## Os confirmed do grafo editado (REGRA 87)

- `E_SONDA_27_DE_31_PASSARAM`: as curas não o contrariam; as formas da sonda seguem vetando (casos c1 a c6).
- `E_REPLAY_DOS_ADOTANTES`: o replay foi na versão antes das curas desta volta; o replay dirigido da 1ª passada e os
  lotes do refutador independente re-rodados não acharam veto honesto novo, salvo o heredoc sem terminador, declarado.
- `E_REFUTADOR_INDEPENDENTE_3_BLOQUEIA`: é o nó desta volta.
