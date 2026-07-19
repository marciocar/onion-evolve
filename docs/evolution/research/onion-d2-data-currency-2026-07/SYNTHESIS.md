---
title: 'Síntese — D2 (moeda-dado / flywheel de federação): recomendação para ratificar'
date: 2026-07-19
type: research-synthesis
run_id: wf_b533468d-41c
method: fan-out (doutrina-interna+colisão · externo-2026, sonnet) → síntese (opus)
related:
  - docs/business-context/decisions.md (D2 — a decidir)
  - docs/discussions/onion-pessoal-marcio/05-mitigacao-inferencia.md (a colisão P5)
  - docs/evolution/rfc/rfc-0004-a2a-live-interop.md (single-source; só destilado circula)
---

# D2 — moeda-dado: o veredito (read-only; o maestro ratifica)

Pesquisa orquestrada p/ resolver **D2** (o modelo usa "compromisso de dado" — adotantes contribuem contexto →
flywheel de federação?). Colide com a fronteira **P5** (mitigação de inferência do `onion-pessoal-marcio`) e
depende da doutrina de federação. **Decisão do maestro** — esta é a moldura + a recomendação.

## O achado central: o card FUNDE duas decisões

| Camada | Recomendação | Por quê |
|---|---|---|
| **DIREÇÃO** (arquitetura) | **Ratificar (c) local-first + destilado AGORA** | É a **única** forma do flywheel que não regride doutrina JÁ ratificada (fail-safe > fail-open, `private` inviolável, declarado≠verificado). P5 (L1-L6, fronteira de saída) **É a especificação** de (c) — não um bloqueio a resolver depois. Destrava D7 ("upsell limpo depende de D2") a **custo zero**. |
| **ATIVAÇÃO** (ligar o flywheel) | **GATED** — só quando o mecanismo existir + for dogfoodado | O SSOT único das 6 camadas (classificação-por-inferência + gate-por-propósito + ε-ledger) hoje é **só protótipo** (`.kg.yaml`), não operacional. Anunciar (c) como garantia antes disso = vender garantia não-verificada = **queima o moat** (declarado≠verificado). |

**Ratificar direção ≠ ligar o flywheel.** São camadas compatíveis; o card as funde numa só.

## As 4 opções, resolvidas
- **(a) sim, sem restrição** — **ELIMINADA.** Regride doutrina vigente + colide com EU AI Act/EDPB no exato pilar que
  o Onion vende (compliance-peer). Para QUALQUER outro produto (a) é neutra; para o Onion é auto-contraditória.
- **(b) adiar** — vira **estado interino gated**, não destino: só empurra o bloqueio de D7.
- **(c) local-first + destilado** — **RECOMENDADA** (direção), ativação gated.
- **(d) só financeira** — **rede de segurança** pré-comprometida (se o custo do mecanismo inviabilizar), **nunca (a)**.
  Não é co-primária: sem NENHUM destilado, o flywheel não existe → esvazia D7.

## Mecânica de "local-first + destilado" (o flywheel de negócio)
- **FICA soberano** (nunca sai do install do adotante): o **contexto de negócio bruto** (KG/registros = SoT local; git como SoT).
- **SOBE** (atravessa p/ core/hub): **apenas predicados destilados/agregados** — claims provados, nunca registros.
- **Classificação por PIOR CASO DE INFERÊNCIA** (P4): o destilado herda a sensibilidade do que permite **deduzir**, não do que afirma.
- **Gates de saída (L1-L6)**: escopo de consulta · propósito vinculado · filtro por composição · juiz-de-CI separado · self-red-team pré-emissão · ε-ledger monotônico.
- Estruturalmente = **a mesma doutrina RFC-0004** (single-source p/ identidade/contratos; federa-se só a derivação/comunicação) aplicada a um domínio novo. Para framework **instalado** (não SaaS central), FL/DP completos são over-engineering nesta fase; destilado/agregado on-device-first minimiza risco sem inviabilizar.

## Guardrails (duros)
- **Nunca** anunciar (c) como garantia operacional antes do SSOT das 6 camadas existir + dogfoodado.
- **Registrar o resíduo, nunca "seguro":** ~7-8%, por-resposta (não composto); um LLM reconstrói atributos mesmo do destilado.
- **Verificar o threat model N-tenant com lente própria** — P5 foi provada em **N=1 pessoal** (motor local raciocinando p/ o dono); D2 é **multi-adotante** (contexto cruzando p/ o hub). Não citar P5 fora do escopo em que foi provada.
- **Nunca relicenciar depois de abrir** — decidir o modelo de dado ANTES do flip (janela ainda aberta; Onion nunca foi distribuído).
- **Gates de custo que podem abortar p/ (d):** self-red-team 15-20x/release; ε-ledger em N=1 sem tratamento publicado; taxonomia L3 com ~36% falso-positivo em finanças.
- **Reciprocidade percebida explícita** ao adotante (o que sobe/fica) — flywheels que sobrevivem em 2026 dependem disso.

## Evidência externa (Frente B — 2026)
- Data-flywheels em devtools sobrevivem só com **reciprocidade percebida + transparência**; a defensibilidade vem de moat de integração/comunidade, **não do dado bruto** ([startups.com/data-flywheel](https://www.startups.com/lexicon/data-flywheel)).
- Movimento ativo de devtools **all-local, sem coleta** (nascido de incidente de adware, mar/2026 — [awesome-privacy-devtools](https://github.com/septimlabs-code/awesome-privacy-devtools)).
- **EU AI Act + EDPB** fecharam a via livre de scraping/pooling: base legal GDPR documentada + minimização antes de pooling ([techtimes/EDPB](https://www.techtimes.com/articles/320024/20260709/gdpr-applies-ai-training-data-eu-ends-web-scraping-free-pass-every-lab.htm)).

## O que o maestro ratifica
1. **Ratificar (ou não) a DIREÇÃO (c) agora** — mata (a), troca (b) de destino p/ interino gated. *(Recomendo ratificar.)*
2. **Definir o GATILHO DE ATIVAÇÃO** — SSOT das 6 camadas construído+dogfoodado; threat model N-tenant verificado; abertas de ε/purpose-binding/L3 resolvidas. Decisão pura: comprometer roadmap p/ construir o mecanismo ANTES de perseguir a moeda-dado, ou deixar amadurecer.
3. **Pré-comprometer o fallback (d)** se o custo inviabilizar — nunca (a).
4. **Nomear a ressalva de escopo** (P5 = N=1; N-tenant a verificar) no texto ratificado.
5. **Propagação:** ratificar (c) destrava D7 imediatamente — sair agora com "arquitetura ratificada, ativação gated" ou esperar.
