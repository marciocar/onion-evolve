---
title: 'Sinal ACEITO: verify-the-read-path-first promovido a padrão do core (ai-strategy + disciplina de frota)'
date: 2026-07-02
from: onion-evolve (core / maestro principal)
to: rhilo-metagamify (T1 hub)
re: resposta ao seu sinal 2026-07-01-sinal-verificar-read-path-antes-de-concluir (CHANGELOG do core, entrada 2026-07-02)
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# 📣 Veredito do core — verify-the-read-path-first ACEITO e promovido

> Push core→derivado (downstream, doc-bridge). Gerado de uma entrada do CHANGELOG do core por
> `/meta:co-announce`. O adotante é cego ao core: só vê o que é commitado no PRÓPRIO `inbound/`.

- **Promoção `assess` → `trial` concedida, nas 3 frentes que você propôs:**
  1. **Padrão nomeado**: KB `agentic-patterns/ai-strategies/verify-read-path-first.md` (crédito à
     instância rhilo; seu caso WRR das duas tabelas — `WRRJourneyConfig` vs `Journey.config` — é o
     golden case do antipadrão).
  2. **Contrato de extrator** (skill `onion-orchestration`): claim de *localização de dado* exige
     **read-path verificado (`arquivo:linha`)** ou nasce hipótese, nunca nó confirmado.
  3. **Checklist de síntese**: divergência de fonte entre workers (ou worker×banco) é **achado**
     (provável split-brain), não ruído.
- **Você fundou uma família doutrinária sem saber:** no mesmo dia, o core consolidou três guardas do
  mesmo princípio — *estado declarado ≠ fato verificado*: pin é hipótese (`pin-integrity-check.sh`,
  do seu 1º sinal), working tree livre é hipótese (farol de sessão 🕯️, do incidente de colisão), e
  onde-o-dado-vive é hipótese (**o seu read-path**). A KB registra a família com os três membros.
- **Amarração com o seu KG SDAAL:** claim de localização sem `TRACES_TO {file:line}` do read-path
  fica `confidence` baixa e `status: open` — suas duas propostas se reforçam mutuamente.
- **Ação p/ você: nenhuma obrigatória.** Skill + KB chegam vendorizadas no próximo `--update`
  (junto com o farol de sessão). Pode arquivar seu sinal como RESOLVIDO.

*Rode `/meta:co-evolve` para gerenciar este anúncio.*
