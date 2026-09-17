---
title: "/meta:adopt gera o inventário ANTES do commit durável — greenfield nasce com 0 comandos"
date: 2026-09-08
type: bug
origem: adotante greenfield recém-criado
---

## O sintoma, medido

Numa adoção `--mode greenfield` recém-executada no pin `5dcc706b2233`, o passo **(8)** do
Procedimento de Configuração pós-cópia gerou um `docs/onion/inventory.md` afirmando:

```
| Comandos invocáveis | **0** |
| Agentes             | **0** |
| Skills              | **13** |
| Knowledge Bases     | **93** |
```

com **`rc=0`**. O alvo tinha, naquele instante, 146 arquivos `.md` em `.claude/commands/` e 60 em
`.claude/agents/` — copiados corretamente pela Fase 2.

## A causa

`inventory.sh:39` usa `_tracked_or_find`, que **prefere `git ls-files`** e só cai para `find`
*"quando não há git"*. Num greenfield, o repo **é** git desde o `git init` do PASSO 0c, mas o
framework recém-copiado ainda está **untracked** — então `git ls-files` devolve vazio e a contagem
sai zero. O fallback nunca dispara porque a condição é "sem git", não "sem resultado".

O passo (8) do Procedimento roda **antes** do commit durável da Fase 5. Logo, num greenfield a ordem
garante o inventário errado.

Assimetria que ajuda a localizar: `Skills` e `Knowledge Bases` saíram corretos (13 e 93) — esses
contadores não passam pelo `_tracked_or_find`.

## Por que importa mais do que parece

O `inventory.md` é SSOT com catraca byte-a-byte no lint (REGRA 8). Um adotante que commite esse
arquivo zerado leva para o histórico uma SSOT que **declara** uma superfície que não existe — e é
exatamente a classe *declarado ≠ medido* que a casa persegue. E o `rc=0` faz o erro passar em
silêncio: quem seguir o Procedimento à risca não tem como notar.

Regenerado após o commit durável, o mesmo comando devolve **109 comandos e 51 agentes**.

## Curas possíveis (não decididas)

1. **Mover o passo (8)** para depois do commit durável da Fase 5 — resolve a ordem, mas o
   `install-onion-githook.sh` exige `inventory.md` para o commit não ser barrado, então provavelmente
   é preciso gerar duas vezes (antes para destravar o gate, depois para valer).
2. **Corrigir `_tracked_or_find`** para cair no `find` quando `git ls-files` devolve **vazio**, não só
   quando não há git. Cura de raiz, e independe da ordem.
3. **Assertiva no próprio `inventory.sh`**: superfície com arquivos em disco e contagem zero é
   contradição — sair não-zero em vez de emitir a SSOT mentirosa.

A (2) parece a cura certa: é onde o defeito mora, e conserta qualquer chamador futuro.
