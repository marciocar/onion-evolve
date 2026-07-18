# Síntese — Doutrina unificada de breadcrumbs (validação multi-lente + adversário)

> **Proveniência:** orquestração `wf_3d64cf59` (2026-07-18) — 3 lentes (taxonomia interna · mercado/estigmergia web
> · risco-adversarial) → síntese opus → verificação adversarial opus (**CONFIRMADO com 2 correções**). `write(KG)`
> da orquestração. Grafo co-locado: `./breadcrumb-doctrine.kg.yaml` (radar exit 0). Doutrina: a KB
> `breadcrumb-patterns.md` v2.0.0.

## O que se decidiu

**Família = "breadcrumbs/migalhas"; 3 gêneros por DIREÇÃO do sinal** (a hipótese inicial de 2 gêneros foi refutada):
- **① Absorção** (presente) — sinal no artefato que força a leitura certa agora (anti-acomodação). Estigmergia sematectônica.
- **② Proveniência** (aponta pra trás) — `trace:`/`TRACES_TO`/`origin:`, âncora à fonte. **Não é estigmergia** (cita passado fixo).
- **③ Trilha** (aponta pra frente) — `next_recommended`/o ato `write(KG)`, marca pra a próxima sessão. Estigmergia marker-based.
- **Eixo transversal (não-gênero): validade/frescor** — `conflict_class`/`review_after`/`verified_at`/`status`, modificador que qualquer gênero carrega.

**A amarra `read=comer / verify=cheirar / act=andar / write=deixar` ao SSOT-as-runtime é válida — escopada à Trilha**
(4 pernas; generalizar aos 3 é overclaim que o corpus contradiz).

## Prior-art (mercado 2026 — "seguir a corrente")

**Estigmergia** (Grassé, 1959 — coordenação de cupins via marca no ambiente) é o termo canônico reaplicado a
agentes LLM em 2026: agentes deixam rastro no ambiente compartilhado para o próximo seguir, sem comunicação
direta (alinha com o "sem IA-fala-IA" + I3 do Onion — coordenação por artefato, não por fala). Distinção
**sematectônica** (o sinal É a estrutura → Absorção) × **marker-based/sign** (marcador depositado, separado do
produto → Trilha). Proveniência **não** é estigmergia (é citação a passado fixo, não coordenação de ação futura).

## As 2 correções do adversário (o adversário ganhou)

1. **Rótulo da família** — não pode ser "Estigmergia" (Proveniência é membro **não-estigmérgico**). Família =
   "breadcrumbs/migalhas"; estigmergia = **propriedade** de 2 dos 3.
2. **Locus-slip** — a Trilha **viva** é no **diário** (`next_recommended`; o loop do federation-radar). A Trilha
   **no KG** é **aspiração não-construída**: `.kg.yaml` têm **zero** campo forward; `trace:` é Proveniência. A
   runtime-ness do KG **hoje** são as pernas read→verify (Proveniência + verify-vivo), **não** a perna write-forward.

## Achado estrutural (real, não retórico)
O KG tem campo explícito de **Proveniência** (`trace:`) mas **nenhum campo de Trilha** (forward). A trilha-no-KG é
implícita no *ato* `write(KG)`. Uma aresta/campo forward (`NEXT`/`next_recommended` no nó) é candidato **dogfood-gated**
(não inventar antes de um dogfood provar a falta — doutrina `/meta:kg`). Gap de radar honesto: falta gate para ③ Trilha e ① Absorção.

## Confiança / gaps
- **Alta:** os 3 gêneros + a correção `trace:`=Proveniência (grep direto de 6 `.kg.yaml`, evidência primária).
- **Média:** o escopo exato da amarra (leitura interpretativa coerente com o corpus).
- `declarado≠verificado`: a doutrina sela aqui (KB v2.0.0), mas a Trilha-no-KG fica **proposta-não-construída** até um dogfood.
