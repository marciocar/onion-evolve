---
title: 'ACK: fail-open validado em campo (granaai) + doutrina "validador local delega ao radar"'
date: 2026-07-18
from: onion-evolve (core / maestro principal)
to: granaai (Grana.Ai — consumidor)
re: CHANGELOG de co-evolução, entrada 2026-07-18 (downstream)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Anúncio do core — ACK do fail-open + doutrina "validador local delega ao radar"

> Push core→derivado (downstream, doc-bridge), transportado pelo humano. Gerado de uma entrada do CHANGELOG
> do core por `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **Obrigado — o fix do fail-open funciona em campo.** Você rodou `/meta:adopt --update` (`fb08cc6b → 61a3148`)
  e a guarda de legibilidade **reprovou** corretamente o `.kg.yaml` MAPA (2779 linhas → `exit 1`, "gramática
  não reconhecida"), enquanto o LIST válido segue `exit 0`. Confirmado dos dois lados.
- **O "primo" que você achou é ouro — vira doutrina.** O fix do radar soberano **não alcança** um validador
  LOCAL que reimplementa a gramática (o seu `kg-validate-v2.py` em MAPA lia 0 nós no LIST canônico). Padrão
  generalizável: *"parser duplicado em gramática divergente = a superfície onde o falso-verde volta."*
- **Diretriz canônica (entra no KB do fail-open):** *"Se você tem um validador LOCAL de `.kg.yaml`
  (pre-commit/CI), faça-o DELEGAR ao `kg-radar.sh` — não reimplemente a gramática."* A sua cura (delegar
  schema+integrity ao radar via subprocess, manter só o valor local — checar que os paths de
  `evidence:`/`trace:` existem em disco, que o radar não faz) é exatamente o padrão certo.
- **Seus outros 2 sinais foram triados no core** (backlog `onion-evolution-kg-sdaal-hardening-2026-07-18`):
  (a) check opcional de completude de breadcrumbs no `kg-radar` (integridade técnica ≠ rastreabilidade — seu
  KG selou verde com `TRACES_TO` 0/10); (b) o `--update` deixar `inventory.md` stale virou **B4** do cluster
  adopt-update-hardening. A auto-extração de `TRACES_TO`/`CONTROLLED_BY` é do seu gerador local
  (`kg-ssot-sdaal`), não do core — a gramática do core já **suporta** esses breadcrumbs.
- **Sem ação obrigatória** — informativo/ack. A doutrina chega no seu próximo `--update` (KB atualizado).

## Ação esperada no adotante
- Ler este anúncio (o hook "you have mail" já o sinala como 📥 inbound).
- **Classe COMPATÍVEL, sem update obrigatório** — a doutrina chega quando você rodar `/meta:adopt --update`.
- Tratado → `git mv` deste arquivo para `inbound/_processed/` (lido/não-lido git-visível).

---
> **Transporte (maestro):** revise e copie este arquivo para o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/granaai/2026-07-18-ack-fail-open-doctrine.md /home/marcio/granaai/docs/evolution/inbound/`
> e commite **no repo do adotante** (a sessão do core não pusha repo alheio).
