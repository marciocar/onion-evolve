---
kg: docs/evolution/research/slm-capitalizacao-2026-10/slm-capitalizacao-2026-10.kg.yaml
run_id: wf_904a531b-a01
mode: primaries
tokens: 1392008
agents: 20
duration_min: 10
date: 2026-10-05
---

# Onion SLM — capitalizar: quem paga por avaliação, e por quê

> **Projeção do grafo** `slm-capitalizacao-2026-10` (37 nós, 48 arestas, radar `--integrity --schema` exit 0).
> As 9 fontes foram alcançadas: **25 claims ancoradas**, **21 rejeitadas** (18 exageradas e 3 não encontradas).
> Diretriz do maestro (`C_FRAME_ALWAYS_BILL`, conferida contra as falas verbatim): *"sempre pensando em
> bilhetar, mesmo que para isso tenha que criar a estratégia mais adequada para cada momento"*.

## O que as primárias mostram

1. **O capital também financia a camada de avaliação, não só o modelo pequeno**
   (`C_CAPITAL_ALSO_FUNDS_EVAL_LAYER`): LMArena levou US$100M de seed e **US$150M de Série A** (jan/2026);
   Braintrust levou US$80M e Galileo US$45M. Um bench ou eval **genérico** do Onion entraria contra rivais bem
   capitalizados. O que escapa é o **nicho**, o eval de domínio com erros reais e corretor determinístico, e
   nenhuma fonte mede esse nicho.
2. **Eval-como-serviço que tem tração vive embutido numa plataforma de produção**
   (`C_EVAL_REVENUE_EMBEDDED_IN_PRODUCTION_LAYER`). Exemplos: Braintrust (Pro US$249 + excedente por score/GB),
   Galileo e Arize (OSS ao lado do pago). Isso **veta** bilhetar por volume, porque exigiria SaaS hospedado
   contra a identidade canônica. Também **habilita** o equivalente que o Onion já tem: o eval como **gate
   instalado no repo** do adotante.
3. **Bench próprio não é bench independente** (`C_SELF_EVAL_IS_NOT_INDEPENDENT_BENCH`). A Artificial Analysis vende
   medição independente (*"Providers cannot pay for results"*; Pro US$417/assento). Um bench do Onion sobre
   o próprio mecanismo é autoavaliação de fornecedor. Para valer como bench, ele precisa medir **outros** modelos
   e declarar independência, ou ser publicado como **método reproduzível**.
4. **Forma híbrida** (`C_OPEN_SHOWCASE_PRIVATE_HOLDOUT`): uma fatia aberta serve de vitrine/método, e o held-out
   privado de erros reais serve de prova (a Scale mantém os seus privados pelo mesmo motivo). Isso casa com o
   achado dos frameworks: o eval selado fica fora da porta pública. E **bench sem dono morre** (a HF aposentou o
   Open LLM Leaderboard), então a revisita tem de ser mecanismo, não intenção.
5. **Treinamento e consultoria vendem o sistema INSTALADO** (`C_TRAINING_CONSULTING_SELLS_INSTALLED_SYSTEM`):
   - curso com ativos que continuam rendendo (Parlance/Maven);
   - consultoria que **constrói** o sistema de avaliação no cliente rumo à autonomia.

   É a via mais compatível com o Onion, um framework instalado no repo, e com o NS1: o curso é veículo do
   KG, não fim.
6. **Bench aberto comunitário roda em crédito, não em receita** (`C_OPEN_BENCH_RUNS_ON_CREDIT_NOT_REVENUE`). O MMTEB
   vive de autoria e pontos, e serve de funil e reputação. A receita vem de outra camada.

## Ordem de vias (proposta, não sela — `Q_BILLING_VIAS_ORDER_PROPOSAL`)

| # | via | quem paga | forma |
|---|---|---|---|
| 1 | **consultoria de avaliação** que instala o eval de domínio + gate no repo do cliente | adotante regulado / empresa | sem plataforma hospedada; compatível com fork e adoção |
| 2 | **treinamento** com ativos que continuam rendendo | alunos, times | curso como veículo do KG |
| 3 | **bench aberto** do mecanismo, só no desenho híbrido e medindo OUTROS modelos | ninguém direto; é funil | vitrine + held-out privado |
| — | **NÃO** bilhetar por score/volume | — | exigiria SaaS hospedado |

As vias **federação, advisor de core/hub e membro externo de rede** seguem **sem primária**. São do maestro e
estão nomeadas; a medição delas fica para a próxima rodada.

## NÃO-VERIFICADOS

- **21 claims rejeitadas.** Entre elas, a **única sobre quem PAGA a LMArena** (o texto diz que labs *precisam* de
  avaliação, não que pagam) e o valor da Série C da Arize (quote reconstruída). A lista está em
  `E_LACUNAS_SLM_CAPITALIZACAO_PRIMARIES_1005`.
- **Preço quase ausente.** Só dois preços foram ancorados (AA Pro e Braintrust Pro). Nenhum preço de curso ou consultoria
  ancorou, e o empacotamento de educação/advisory no Enterprise da AA está marcado para re-ancorar
  (confiança 0,5).
- **Retorno do Elenxo:** chegou truncado na objeção 17. O grafo declara isso, e as objeções completas estão em `data/`.
- **Preços envelhecem.** `review_after` está em 2027-01-03, com gatilho para re-medir preços em 30 dias.

## valeu-a-pena

1.392.008 tokens ÷ 37 nós ≈ **38k/nó**, acima da rodada de frameworks e abaixo da referência de 42k/nó.
Página de preço e anúncio de rodada esticam muito: 21 rejeições em 46 claims. A ancoragem pagou o custo.
