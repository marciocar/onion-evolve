---
branch: fix/adopt-three-defects
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: pendente
findings_total: 11
findings_real: 9
findings_blocking: 5
tokens: 183837
duration_min: 24
findings_fixed: 7
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "subagente general-purpose (opus), mandato de refutar, sem o raciocínio do autor"
nota: "1 passada independente; 7 curados e com caso na bancada; os 2 reais não curados são limites declarados abaixo; 2 notas sem defeito (fork persistente redirecionado é o desenho; aviso fora desta máquina é verdadeiro)."
---

# Passada adversarial: `fix/adopt-three-defects`

## O que muda

Três defeitos do `/meta:adopt` (SAC-444), cada um reproduzido numa adoção de teste em scratch
(`ops/materialize-adopter.sh`, nunca um adotante real), curado em `.claude/utils/adopt/` e posto na bancada
com mutante:

1. `adopter-guard-core.sh`: com a fonte num clone do core, a linha `core` do `adopter-guard.tsv` ficava com
   o caminho do clone. Agora ela aponta o checkout canônico: primeiro o `local_path` do membro `kind: source`,
   depois o `origin` local. Só vale um core do mesmo repositório.
2. Corrida entre o `install-onion-githook.sh` (e o verificador que ele chama) e o `prove-gate-blocks.sh` no
   mesmo checkout: antes da cura, rc 4 INTEGRIDADE logo depois de PROVADO. Agora eles se revezam por uma
   trava no git-dir comum (`gate-probe-lock.sh`).
3. `ensure-secret-gitignore.sh`: garante `__pycache__/` no `.gitignore` do adotante.

## Achados

1. **BLOQUEANTE, curado.** A REGRA 100 (Superfície que viaja não cita ops/ como se o destinatário o tivesse)
   dava HARD na lib nova, que citava a porta de carga por caminho de `ops/`. Cura: a citação saiu.
   `ops-citation-travel-check.sh` agora dá rc 0.
2. **BLOQUEANTE, curado.** Só o verificador pegava a trava. Os passos 1 a 3 do instalador (hook, `.onion`,
   `core.hooksPath`) mudavam status e config fora dela. O refutador mediu rc 4 com a prova começando antes
   do instalador. Cura: o instalador pega a trava antes do passo 1 e exporta `ONION_GATE_PROBE_LOCK_HELD`.
   O verificador filho reentra pela variável em vez de esperar o pai, que daria deadlock.
3. **BLOQUEANTE, curado.** Um daemon solto pelo hook herdava o fd 9 e segurava a trava depois do fim.
   Medido: a prova seguinte esperou o teto. Cura: `9>&-` nos commits da prova (controle, plantado e base) e
   na sonda e no lint do verificador. Caso (r3) e mutante (MUT-daemon).
4. **BLOQUEANTE, curado (só no caminho sem flock).** A retomada de trava velha dava dupla posse em 6 de 20
   rodadas. A prova também deixava trava órfã ao sair por `verdict_no` antes do `trap finish`. Cura:
   - a retomada passa por uma segunda trava (`.reclaim`) e confere o pid de novo dentro dela;
   - pid vazio nunca conta como velho;
   - a prova arma o unlock logo depois de pegar a trava.
5. **BLOQUEANTE, curado.** Nenhum caso provava que o verificador pega a trava. Cura: o caso (r2) põe o
   verificador real contra a prova, e o mutante (MUT-vrace) tira a trava dele.
6. **Real, limite declarado.** O leitor do `members.yaml` é linha a linha, como o de
   `hooks/lib/adopter-scope.sh`. Aspas simples, `kind` entre aspas, `kind:` aninhado (por exemplo em `a2a:`)
   ou entrada começando por `- name:` caem na pista seguinte. O resultado é o comportamento antigo, com
   aviso. A falha vai na direção segura: nunca troca para outro repositório.
7. **Nota, desenho.** Um fork persistente nesta máquina, sem origin local e com o `members.yaml` herdado, é
   redirecionado ao core de cima. Isso é coerente com o desenho (a linha aponta o core que fica).
8. **Real, curado.** A regex do bytecode aceitava regras que o git não honra: espaço inicial e regra
   desfeita por `!`. Cura: num repo git quem decide é `git check-ignore --no-index`, sem o excludesFile
   global. Caso (h2).
9. **Real, curado.** Os mutantes da pista do origin (j) e da identidade (k) não estavam registrados. Agora
   estão: (MUT-origin) e (MUT-identity).
10. **Real, limite declarado.** O caso (r) usa uma janela de 3 s. Ficou verde em todas as rodadas medidas
    (load até cerca de 7), mas sob carga extrema pode oscilar.
11. **Nota, verdadeira.** Fora desta máquina (CI, fork), a saída do helper avisa "nenhuma pista do checkout
    canônico". O aviso é verdadeiro e fica.

O refutador não conseguiu refutar:

- a serialização com flock nas duas ordens;
- a colisão de descritor com a porta de carga (ela usa 10 ou mais);
- a troca indevida de checkout para outro repositório;
- a REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente);
- os três mutantes originais, que mordem de verdade.

## Mutantes

Na bancada, cada um vira o caso que mede:

- secret-gitignore: (h) MUT;
- adopter-guard-core: (MUT-canon), (MUT-origin), (MUT-identity);
- prove-gate-blocks: (MUT-race), (MUT-vrace), (MUT-daemon).

Por fora, com `ops/mutate-and-restore.sh`, todos rc 1 (o mutante morreu):

- a pista do `local_path` em `adopter-guard-core.sh`;
- a linha `__pycache__/` em `ensure-secret-gitignore.sh`;
- a trava desligada na lib: (r), (r2) e (MUT-daemon) viram.

## Limites declarados

- Achado 6: o leitor linha a linha do `members.yaml`.
- Achado 10: a janela de tempo do caso (r).
- Uma linha `core` antiga que ainda aponta um clone VIVO é tratada como escolha do maestro e fica. Ela é
  trocada no update seguinte, depois que o clone some.
- O `.gitignore` não apaga o `__pycache__/` do disco, e o `kg_vendor.py check` lê o disco.
- Medido depois da cura, com o flock fora do PATH: 3 interessados disputando uma trava de pid morto, 20
  rodadas, 0 duplas posses (antes da cura, 6 de 20). Não medido: o caminho sem flock numa máquina macOS real.
