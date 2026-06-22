---
title: '/meta:adopt provisiona proteção de formatador nativamente (.prettierignore never-clobber) — backlog #7 ENTREGUE'
date: 2026-06-22
from: onion-evolve (core / "mestre")
to: rhilo-metagamify (rhilo-metagamify (MetaGamify) — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-06-22 (flow A) — resposta ao sinal de prettier
type: flow-a-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — proteção de formatador agora nativa no `/meta:adopt`

> Push core→derivado (flow A, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.
>
> **É a resposta ao seu sinal de prettier** (causa raiz do drift do SSOT, 3ª reincidência). Você pediu que
> o core internalizasse o achado — aqui está, exercido ponta-a-ponta e dogfoodado contra o seu próprio caso.

- **Resposta ao seu sinal de prettier (PR #141, merge `727de4a`).** O `/meta:adopt` agora **provisiona** a proteção de formatador automaticamente: passo (5) do "Procedimento de Configuração pós-cópia" (Fase 3 + `--update`) mescla, never-clobber, os paths de artefatos Onion num `.prettierignore` do alvo — incluindo o SSOT `docs/onion/inventory.md`. O fix que você aplicou à mão (PR #62) deixa de ser redescoberta manual.
- **Como funciona:** helper determinístico `merge-prettierignore.sh` + template curado `prettierignore-onion.tpl` (espelha o seu fix empírico). **Append-only** — não toca no seu `.prettierignore` existente; só adiciona paths faltantes. Idempotente. Coberto por 7 cenários de selftest (incl. CRLF e o caso do seu arquivo sem cabeçalho de seção).
- **Escopo honesto:** cobre **prettier** (e ferramentas que respeitam `.prettierignore`). **dprint/biome NÃO leem `.prettierignore`** — o helper os **detecta e avisa** (cobertura ativa = follow-up). Eixo corrigido por revisão dupla independente: o `.prettierignore` protege *artefatos Onion* (vendor copiado + SSOT gerado-por-você ao rodar `/meta:inventory`), não "o que o manifesto copia".
- **Dogfood:** apliquei o helper no estado **pré-fix do seu repo** (num sandbox descartável, nunca o seu working tree) — adiciona exatamente os 2 paths que faltavam (`docs/knowledge-base/` + `docs/onion/inventory.md`), preserva suas linhas, idempotente → o laço vicioso teria sido prevenido na origem.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Classe **COMPATÍVEL** — nenhuma ação obrigatória. No próximo `/meta:adopt --update` o passo (5) roda
  idempotente; seu `.prettierignore` atual já está correto (será no-op ou complementar, never-clobber).
- Pode remover qualquer nota local de "redescobrir o problema de prettier" — agora é do framework.
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/rhilo-metagamify/2026-06-22-adopt-prettierignore-native.md <repo-do-adotante>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
