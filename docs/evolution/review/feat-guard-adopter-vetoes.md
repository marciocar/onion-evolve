---
reviewed_diff_sha256: e9b0c5f651fc84d2458e3e62a13e69ab45659f4364b9c0c218ba9285e4e13f95
findings_total: 9
findings_real: 9
findings_fixed: 5
tokens: 0
duration_min: 0
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: refutador da 1ª passada (7788d9178) + verificação das curas pela sessão da forja (60b622b4a)
nota: >
  O refutador reprovou 7788d9178 com 9 achados reproduzidos, 1 bloqueante. Cinco viraram cura em 60b622b4a,
  cada um com caso na família adopter_guard e mutante; quatro ficaram declarados no cabeçalho do hook e no grafo
  guard-adopter-vetoes-2026-11. O refutador independente que conta para o merge ainda não rodou: o maestro o
  abre depois deste portão. tokens e duration_min não foram medidos (0).
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
