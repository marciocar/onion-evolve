---
title: "Síntese P3 — Captura passiva × declarada e local-first × nuvem"
category: research-synthesis
responde: "SEED.md — pergunta 3 (captura passiva vs declarada; local vs nuvem)"
data: "2026-07-12"
branch: "discuss/behavior-mapping-kg"
fontes_verificadas: 16
metodo: "pesquisa orquestrada 2 frentes (agentes diretos, WebSearch real)"
---

# Síntese P3 — Como capturar, e onde o dado vive

> **Carimbo: hoje = 2026-07-12.** Duas frentes (agentes `general-purpose`, WebSearch real):
> (A) passiva × declarada; (B) local-first × nuvem. Datas como fornecidas; **s/d** = sem data.

---

## A. Passiva × declarada — observar o que faz, ouvir o que diz

A tradição de *personal informatics* separa **sensing passivo** (telas/ações/localização,
automático, alta resolução) de **sensing declarado** (o usuário anota/responde). A passiva contorna
o *recall bias* e a baixa adesão, mas é **cega ao significado** (infere proxies, não sabe o porquê).
A declarada — via **ESM/EMA** (captura in-situ) — é rica em sentido mas **esparsa, custosa e
enviesada**. No meio está o **say-do gap** (attitude-behavior / intention-action): a discrepância
documentada entre o que a pessoa diz e o que faz. Nenhuma basta sozinha — a passiva mostra o "fez",
a declarada o "quis dizer" — e a literatura converge para **triangular**, sabendo que às vezes
medem construtos diferentes.

- Sensing ativo (esforço do participante) × passivo (automático) — a distinção canônica — [Acceptability of Personal Sensing (PMC10495858)](https://pmc.ncbi.nlm.nih.gov/articles/PMC10495858/), 2023.
- ESM/EMA captura in-situ, reduz *recall bias* do relato retrospectivo — [Ecological Momentary Assessment (SimplyPsychology)](https://www.simplypsychology.org/ecological-momentary-assessment.html), s/d.
- **Measurement reactivity**: perguntar repetidamente muda o que se sente/faz — [A Novel ESM Tool (PMC9002591)](https://pmc.ncbi.nlm.nih.gov/articles/PMC9002591/), 2022.
- **Value-action / say-do gap** — sinônimos e o caso do carro limpo (atitude ≠ comportamento) — [Value-action gap (Wikipedia)](https://en.wikipedia.org/wiki/Value-action_gap), s/d.
- Em pesquisa de consumo, preferência declarada falha em prever compra real (~50% de gap) — [Say-Do Gap (NielsenIQ)](https://nielseniq.com/global/en/insights/analysis/2024/connecting-mind-matter/), 2024.
- Complementaridade **com limite**: em 1 de 4 estudos o passivo teve valor incremental sobre o autorrelato — [Passive sensing review (npj Mental Health)](https://www.nature.com/articles/s44184-024-00089-4), 2024; sensor × relato batem p/ sono, divergem p/ estresse — [Detecting reward/affect (PMC12884851)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12884851/), 2025.
- **Reactivity / Hawthorne**: ser observado muda o comportamento — [Hawthorne effect review (PMC3969247)](https://pmc.ncbi.nlm.nih.gov/articles/PMC3969247/), 2014.

**Tensões:** a passiva **não é neutra** (carrega *measurement bias*, proxies pobres) — não é a
"verdade" contra a qual o relato erra. Combinar **nem sempre soma** (para estresse, sensor e relato
quase não se sobrepõem). O EMA cura o recall bias mas introduz reactivity. O say-do é **bilateral**:
cada fonte falha onde a outra é forte.

## B. Local-first × nuvem — o bruto fica em casa

O ensaio **Local-first software** (Ink & Switch / Kleppmann, 2019) fixa 7 ideais; três são sobre
**soberania** (longevidade, privacy-by-default, propriedade/controle do usuário). A evolução técnica
é o **on-device/edge**: o bruto é processado onde nasce e não cruza a rede, encolhendo a superfície
de ataque. O tradeoff é assimétrico — nuvem dá poder/composição, local dá soberania. O meio-termo já
é produção: **Apple Private Cloud Compute** (on-device por padrão; servidores stateless que nada
retêm) e **Gboard** (federated learning + DP; texto bruto nunca sai). O padrão: quando a nuvem se
justifica, sobe o **de-identificado/agregado/predicado**, nunca o bruto — e **não guardar** (o
statelessness) é garantia mais forte que qualquer chave.

- Os 7 ideais do local-first (3 de soberania) — [Local-first software (Ink & Switch)](https://www.inkandswitch.com/essay/local-first/), 2019; [PDF Onward! 2019](https://www.inkandswitch.com/local-first/static/local-first.pdf), 2019.
- **Private Cloud Compute**: on-device por padrão; só o dado relevante sobe; servidores stateless, dado "never stored", verificáveis — [PCC (Apple Security)](https://security.apple.com/blog/private-cloud-compute/), 2024.
- **Federated learning + DP**: modelo treina no device, bruto nunca sai — [FL with DP Guarantees (Google)](https://research.google/blog/federated-learning-with-formal-differential-privacy-guarantees/), 2022; [Gboard FL+DP (arXiv 2305.18465)](https://arxiv.org/abs/2305.18465), 2023.
- Edge reduz superfície de rede (mas o modelo no cliente vira alvo white-box) — [Edge AI Security & Privacy](https://edge-ai-tech.eu/edge-ai-security-privacy-protecting-data-where-it-matters-most/), ~2025; [Security Guide for Edge ML (Wevolver)](https://www.wevolver.com/article/security-guide-for-edge-ml-designers), s/d.
- Minimização + limitação de armazenamento (GDPR Art. 5(1)(c)) — base do "non-retention" — [Data minimization (IAPP)](https://iapp.org/news/a/data-minimization-an-increasingly-global-concept), s/d; [Data Sovereignty & GDPR (Kiteworks)](https://www.kiteworks.com/gdpr-compliance/data-sovereignty-gdpr/), s/d.

**Tensões:** soberania × agregação (local limita a composição multi-fonte que dá valor). Edge **não
é** automaticamente mais seguro (troca superfície de rede por superfície de dispositivo/white-box).
"Verificável" (PCC) ainda é confiança no fabricante, não soberania plena. DP tem custo de utilidade
e é sobre o agregado, não o indivíduo. **Honestidade:** não há fonte primária única que enuncie
"non-retention > cifra" — é composição do statelessness da PCC + a limitação de armazenamento do GDPR.

---

## Convergências

1. **Duas fontes, dois planos.** Passiva = observado (**PROD**, "o que faz"); declarada = intenção
   (**DEV**, "o que diz"). Isso mapeia direto no KG: reconciliar não é escolher uma, é registrar as
   duas e deixar o radar expor o gap (prepara a Q4).
2. **O bruto fica local; só o predicado sai.** Local-first + a lacuna da inferência (P1) + o gate 2
   (P2) apontam todos para: minimizar, processar on-device, exportar só derivado.
3. **Observar tem custo epistêmico e ético.** Reactivity (a passiva altera o comportamento; o EMA
   também) reforça o gate 1 (observar é o ato sensível) — e recomenda captura **parcimoniosa**.

## Implicações para a nota P3

- **Nem passiva nem declarada sozinha** — o sensor precisa das duas, e a reconciliação é feature,
  não bug (o say-do gap é *informação*, não erro).
- **Local-first como default; nuvem só para o derivado** — ancora em rfc-0003 (soberania), na
  de-identification SDAAL e no "non-retention > cifra".
- **Parcimônia de captura** — reactivity + minimização: capturar o mínimo que serve ao propósito.
- **Honestidade** — combinar fontes nem sempre soma; edge não é bala de prata; "non-retention >
  cifra" é princípio composto, não citação única.
