---
title: 'O /meta:dissect disseca qualquer objeto por família registrada, com Etapa 0 pré-registrada e checador de forma; o motor do protótipo fica parqueado'
date: 2026-10-24
from: onion-evolve (core / maestro principal)
to: onion-curation (curadoria do Onion Evolve — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-10-24 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — O /meta:dissect disseca qualquer objeto por família registrada, com Etapa 0 pré-registrada e checador de forma; o motor do protótipo fica parqueado

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

**Selo.** O maestro decidiu em 2026-10-24, por pergunta com opções, **"Absorver peças + parquear motor"**
(descartadas: absorver tudo com o motor; só parquear; rodar o objeto extra antes de decidir). Nó
`D_DISSECT_ABSORVE_PECAS_PARQUEIA_MOTOR_1024`, que responde à proposta de vocês de 2026-10-23
(`D_DAO_RULE_OUTCOME`, que vocês podem fechar apontando este selo).

**O que entrou no core** (sobe para vocês pelo `/meta:adopt --update`):
- **Registro de famílias** em `.claude/validation/dissect-families.kg.yaml`: as 6 famílias de vocês
  (ferramenta, prática, ator, app, categoria, ideia), no perfil `x_term`, com o que N0..N4 provam, os
  vereditos válidos e o destino padrão. Mora em `.claude/validation/` porque viaja junto do checador.
  Os apelidos legados `A|B|C` seguem valendo, lidos dos labels `hidden` do registro.
- **Checador de forma** `.claude/validation/dissect-object-check.sh` (o K3 de vocês, com os mesmos 8 itens
  e as mesmas chaves `x_*`), com a bancada portada na família `run_dissect_object_selftests` (72 casos +
  4 de rc 3, cobertura de todo código e mutante por código, mais um piso de casos). Mudanças medidas:
  registro sem família viva sai rc 3; o modo estudo do core (`x_dissect_mode: study`, para no N2) é aceito
  sem veredito e reprova com veredito; o wrapper usa o `.py` vizinho (chamado de outro repo dava rc 2).
- **Etapa 0 pré-registrada, veredito por família, destino declarado e superação buscada também na web**
  na doutrina (§6 de `dissect-doctrine.md`), no comando (passos 0, 4 e 6) e na lente do `/meta:dissect`.

**Medido aqui:** o checador do core, num clone descartável do repo de vocês, sai rc 0 nos três estudos
(`kgquery-b1`, `metering-b1`, `duolingo-b1`) **depois de reapontar** a `external_edges` da família de
`docs/curation/registry/dissect-families.kg.yaml#T_FAMILY_*` para
`.claude/validation/dissect-families.kg.yaml#T_FAMILY_*`. Sem reapontar, sai `aresta-familia-discorda`.

**Parqueado:** o workflow `curation-dissect.js` como motor. **Gatilho** (nó
`Q_DISSECT_MOTOR_PARQUEADO_OBJETO_EXTRA`): 1 objeto decisório a mais rodado nos dois braços com o protocolo
corrigido e pré-registrado (o juiz vê os vereditos válidos da família; os braços têm os mesmos limites). Se o
protótipo vencer de novo no juiz cego com custo até 1,25× o do método atual, absorve-se; senão, rejeita-se
com a medida. O sinal com o placar e a razão de custo sobe ao core.

**Ação no adotante:**
1. Agora vocês podem emendar o próprio CLAUDE.md (os vereditos por família e o destino declarado), como a
   proposta previa para depois do selo.
2. No próximo `/meta:adopt --update`, reapontar a aresta de família dos estudos para o registro do core e
   aposentar o registro e o checador locais (`curation-dissect-check.*`), ou mantê-los só como histórico.
3. O workflow e o CI próprio do protótipo seguem de vocês até o gatilho; o objeto extra, quando rodar, vem
   como sinal.

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- Se a classe for **BREAKING** ou pedir update: rodar `/meta:adopt --update` no momento oportuno.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/onion-curation/2026-10-24-dissect-any-object-absorbed.md <repo-do-adotante>/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
