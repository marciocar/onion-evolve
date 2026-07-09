---
title: 'SDAAL→design/IA: vertical design JÁ EXISTE (convite a mapear) · des-gate /meta:kg = AVALIAR (falta ancorar) · padrão de orquestração = aceito leve'
date: 2026-07-09
from: onion-evolve (core / "mestre")
to: metagamify (MetaGamify — consumidor)
re: seu sinal 2026-07-09 (SDAAL generaliza para design/IA) + companheiro 2026-07-08 (KG)
type: downstream-response
classe: COMPATÍVEL
status: RASCUNHO — aguardando revisão do maestro (não transportar ainda)
---

# 📣 Resposta do core — SDAAL como método geral: por item

> Resposta ao seu sinal (KG-SDAAL de domínio → mesmo método cura a UI "por identidade, não por analogia":
> atom-map + `SourceTag` + invariante de fonte-única). Triado por item — dois já convergem com o que o core tem.

## Ponto 1 — des-gate `/meta:kg`: **AVALIAR (ainda não)**
- O `/meta:kg` **já existe e é funcional** no core. O "gate" na descrição dele é o **gate de integridade** do
  `.kg.yaml` (exit 1 no commit), **não** um gate de maturidade "espera 1 dogfood". Então não há o que
  "des-gatear" no sentido que o sinal supõe.
- **`declarado ≠ verificado`:** a premissa "cumprido em dobro" apoia na **mensagem companheira de 2026-07-08**
  (o 1º dogfood do KG) — que **não está no core** (nem inbox nem `_processed`). Ou nunca foi relayada, ou não
  retida. **Pedido:** relaye o sinal de 07-08 para ancorarmos a evidência antes de qualquer mudança de gate.

## Ponto 2 — vertical design/IA: **JÁ EXISTE — convite a mapear**
- A **vertical de design já é do core** (`/design:generate`, `/design:identity`, `design-context/` SSOT). O
  pedido "adicionar a vertical" está desatualizado — bom sinal de **convergência independente**.
- **Novo e valioso:** `atom-map` (cada átomo = 1 fonte + 1 dono de exibição + 1 dono de escrita) e o
  **invariante de fonte-única verificável**. Convite: **mapeie-os contra o `design-context/` + o SDAAL** que já
  existem, para o core absorver a *ideia* sem duplicar a vertical.
- **Separar as camadas:** a **ideia** (rastreabilidade-como-UI, fonte-única no front) é **framework**; o
  **`SourceTag` como componente React** é **específico do seu stack** — absorvemos o conceito, não a impl.

## Ponto 3 — padrão `explorar-frota → modelar-SDAAL → validar → construir`: **ACEITO (leve)**
- Rima com o que o core já tem (`onion-orchestration`, fan-out-and-synthesize). Baixo custo, alto valor
  doutrinário → candidato a **KB/diário**, não a código.

## Ação esperada no adotante
- **Relaye o sinal KG de 2026-07-08** (ancoragem do Ponto 1).
- Se puder, relaye o `command-center-atom-map.md` como artefato de referência do Ponto 2.
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** revisar e copiar p/ o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/metagamify/2026-07-09-sdaal-design-vertical-ja-existe-kg-avaliar.md /home/marcio/rhilo-metagamify/docs/evolution/inbound/`
> e commitar **no repo do adotante** (a sessão do core não pusha repo alheio).
