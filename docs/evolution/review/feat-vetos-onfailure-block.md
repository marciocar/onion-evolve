---
reviewed_diff_sha256: bdd0d1277fc9a320b0ebbfdcefe0fa94a40ad671cefb311475890e740726b79c
reviewed_code_sha256: a00eeaa19f0e8f728f88920489f33165dd703c8f13a9089663816e501ab4fd36
findings_total: 9
findings_real: 5
tokens: 138468
duration_min: 13
verdict: REPROVADO_E_CURADO
elenxo: sim
nota: >
  Uma passada de refutador com o veredito começando em reprovado. Ele reprovou o TEXTO do grafo, não o
  mecanismo. O nó Q dizia ter medido o timeout de 600 s, e não mediu. O nó E dizia que o block "não
  barra trabalho honesto", e o refutador achou a exceção: o env-guard tem custo quadrático num token
  gigante e chega ao timeout. O rótulo do E_HOOK_ONFAILURE_BLOCK ficou velho. Na guarda, achou um falso
  positivo (`exit 2` entre aspas) e um falso negativo (`#` entre aspas escondendo o exit 2). Os cinco
  foram curados. Os tetos teóricos estão declarados no cabeçalho. O receio de o block barrar o caso
  honesto foi refutado com 26 sondas. Adotante com CC antigo não regride, medido no 2.1.294.
---

# Resíduo — `feat/vetos-onfailure-block` (SAC-83)

Este PR adota `onFailure: "block"` nos 3 vetos PreToolUse (env-guard, protect-main e merge-gate). A
REGRA 101 (Veto PreToolUse por exit 2 declara onFailure: block) passa a cobrar o campo. O plugin agora
herda o campo, e a classe `onfailure-divergente` confere isso. O nó
`Q_ADOTAR_ONFAILURE_BLOCK_NOS_VETOS` do radar E3 r8 está fechado.

## Medição ao vivo (condição do Q)

As settings do usuário ficaram de fora com `--setting-sources project,local`. O log de debug confirma
que nenhum hook Stop disparou.

| Harness | Hook PreToolUse(Bash) | Resultado |
|---|---|---|
| 2.1.296 | script ausente (rc 127), sem campo | a ação **passou** (arquivo criado) |
| 2.1.296 | script ausente, `block` | **barrada** ("blocking because onFailure is block") |
| 2.1.296 | `exit 0`, `block` | passou |
| 2.1.296 | `exit 2`, `block` | vetou com a mensagem do hook |
| 2.1.294 | script ausente, `block` | passou (chave ignorada, sem erro) |
| 2.1.294 | `exit 2`, `block` | vetou (o veto honesto segue barrando) |

## Passada adversarial: REPROVA, curada

1. **MÉDIO, real e curado.** O nó Q afirmava ter medido o timeout. A narrativa foi corrigida: o
   timeout não foi medido.
2. **MÉDIO, real.** O env-guard é quadrático num token único: 186 s a 300 KB, e cerca de 600 s perto de
   520 KB. Com block, esse comando passa a ser barrado. Ficou declarado no nó E e virou
   `Q_ENV_GUARD_QUADRATICO_ATINGE_TIMEOUT`, aberto, com gatilho.
3. **REFUTADO.** O receio de o block barrar o caso honesto não se sustentou: 26 sondas, todas com rc 0
   ou 2. Edit e Write seguem livres para a recuperação.
4. **BAIXO.** Checkout para uma árvore anterior ao env-guard abre uma janela de corrida. Não foi
   medido. Rota de escape: reiniciar a sessão.
5. **BAIXO.** Harness anterior ao 2.1.294 não foi medido. O settings.json já usa chaves e eventos mais
   novos, então o risco que este PR acrescenta é marginal. Está declarado no nó.
6. **BAIXO, real e curado.** A guarda tinha um falso positivo (`echo 'use exit 2'`) e um falso negativo
   (`echo "a #b"; exit 2`). As aspas agora saem antes do corte de comentário, e os casos (xii) e
   (xiii) entraram na bancada com mutante. Os outros tetos ficaram declarados no cabeçalho da guarda:
   `exit "$rc"`, lib sourced, `sys.exit(2)`, `permissionDecision: deny` e settings.local.json.
7. **REFUTADO.** O receio de a bancada não exercitar o runner não se sustentou: o caso (c) passa pelo
   dispatcher do lint-artifacts.
8. **BAIXO, real e curado.** O rótulo do E_HOOK_ONFAILURE_BLOCK ficou datado e ganhou reconciliação.
9. **BAIXO.** O premodelswitch-guard.sh também veta e não recebeu o campo. Isso está declarado como
   fora do escopo no nó Q, porque só o PreToolUse foi medido.
