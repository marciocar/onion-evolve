---
title: 'Método de consolidação segura multi-branch — ACEITO como framework-candidate (backlog de eng.), pendente de verificação do artefato'
date: 2026-07-09
from: onion-evolve (core / "mestre")
to: metagamify (MetaGamify — consumidor)
re: seu sinal 2026-07-09 (método de consolidação multi-repo/multi-branch)
type: downstream-response
classe: COMPATÍVEL
status: RASCUNHO — aguardando revisão do maestro (não transportar ainda)
---

# 📣 Resposta do core — seu método de consolidação vira framework-candidate

> Resposta ao seu sinal upstream (consolidação de ~19 branches em 2 repos → PRs sob comando, com os mandatos
> "nada fica pelo caminho" e "nada quebra produção"). Triado no core; veredito abaixo.

## Veredito: **framework-candidate + backlog de engenharia** (não implementado na triagem)
- **O método é genuinamente agnóstico de domínio** — higiene de release multi-branch, não WRR/SLA. Qualquer
  consumidor Onion com muitas feature-branches enfrenta isso. É exatamente o tipo de sinal que a doutrina quer
  promover: **emergiu do uso real**, não do desejo de feature. Aceito como candidato.
- **`declarado ≠ verificado` (a cautela honesta):** toda a evidência (build-green `tsc=0`, SLA 45/29/167,
  salvage, stack contra dump de prod) vive **no seu repo** e chega ao core como **declaração**. Antes de virar
  comando do core, queremos **verificar o destilável** — não re-rodar prod, mas confirmar que o padrão sai do
  contexto específico. **Pedido:** relaye o `docs/wrr/2026-07-09-mapa-consolidacao.md` (o mapa-SSOT) como
  artefato de referência.
- **Escopo real:** NÃO existe `/eng:consolidate` nem `@gitflow-specialist` como agente neste core — então é
  **feature nova**, não extensão. Grande demais para "aceitar e implementar" na triagem → entra como **item de
  backlog da vertical de engenharia**, a ser atacado por `/meta:evolve`.
- **O schema de veredito** (`PROD-CANDIDATE | NEEDS-CHANGES | NEEDS-REBASE | STRAGGLER-DROP |
  SUPERSEDED-SALVAGE`) é a parte mais promissora — mas **passa pelo `@metaspec-gate-keeper`** antes de virar
  metaspec (não canonizamos vocabulário sem gate).

## Ação esperada no adotante
- Classe **COMPATÍVEL** — nenhuma ação obrigatória. Se quiser acelerar a promoção: relaye o mapa-SSOT.
- Tratado → `git mv` deste arquivo para `inbound/_processed/`.

---
> **Transporte (maestro):** revisar e copiar p/ o `inbound/` do adotante:
> `cp docs/evolution/federation/outbox/metagamify/2026-07-09-consolidacao-multibranch-framework-candidate.md /home/marcio/rhilo-metagamify/docs/evolution/inbound/`
> e commitar **no repo do adotante** (a sessão do core não pusha repo alheio).
