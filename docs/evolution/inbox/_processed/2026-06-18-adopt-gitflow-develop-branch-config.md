---
title: 'Gap: /meta:adopt não configura a branch de integração (gitflow.branch.develop) no alvo'
date: 2026-06-18
from: sessão-core (emergiu ao adotar o Arandek + criar branch de evolução dedicada)
to: onion-evolve (core)
type: field-signal / framework-gap
severity: medium
flow: A (downstream / distribuição)
relates: 2026-06-18-co-evolution-not-distributed-by-adopt.md · adopt.md Fase 3/5
status: aberto (proposta abaixo; ação = sessão-core futura)
---

# Gap — adopt não carimba a branch de integração do alvo

## Sinal

Ao adotar o `Arandek` (legacy) decidiu-se ter uma branch dedicada **`arandek-evolve`** como **alvo dos
PRs de evolução Onion** (separada da `main` de produto). Para o `/engineer/pr` mirar essa branch
automaticamente, foi preciso setar **à mão**:

```bash
git config gitflow.branch.develop arandek-evolve   # branch de integração
git config gitflow.branch.master  main             # produção
```

O `/engineer/pr` resolve a base do PR pelo **motor GitFlow**, que lê `git config gitflow.branch.develop`
([gitflow-patterns.md](../../../knowledge-base/frameworks/gitflow-patterns.md)). Sem essa config, o fluxo
não sabe qual é a branch de integração do alvo — cai no default (`develop`/`main`) e pode mirar errado.

## Causa-raiz

O `/meta:adopt` instala o framework e carimba `.onion-version`, mas **não configura a estratégia de
branches do alvo**. A branch de integração é uma **decisão de adoção** (cada projeto pode querer uma:
`develop`, `<projeto>-evolve`, `main` puro…) e hoje fica implícita.

Agravante: `git config` é **local da máquina** (não viaja no clone). Cada dev/sessão que rodar o fluxo
Onion no alvo precisa re-setar — a config não é compartilhada via git. Logo, mesmo setando à mão, não há
durabilidade entre máquinas.

## Proposta (decisão do core — não executar sem dono)

1. **Adopt pergunta/define a branch de integração** (Fase 3, junto do scaffold): default `develop`;
   permitir `--integration-branch <nome>` (ex.: `<projeto>-evolve`). Setar `gitflow.branch.{develop,master}`.
2. **Durabilidade entre máquinas:** como `git config` é local, gravar a escolha também num lugar
   **versionado** que o motor GitFlow/forge leia como fallback — candidatos: campo no `.onion-version`
   (ex.: `integration_branch:`) ou no `.env.example` do alvo. Assim o fluxo reconstrói a config local a
   partir do versionado (ou o `/warm-up` a re-aplica).
3. **Documentar no CLAUDE.onion.md** a estratégia de branches escolhida (produto vs integração).

## Próximo passo

Backlog do core (severity média — afeta todo projeto que adota com branch de integração != default).
Casa com os outros gaps de distribuição do adopt (#91/#95 e a nota de `settings.json` merge).
