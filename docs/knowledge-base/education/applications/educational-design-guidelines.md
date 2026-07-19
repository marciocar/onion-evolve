# Diretrizes de desenho de artefatos educacionais — vinculantes na vertical (camada 2)

> **Versão**: 1.3.0 | **Última atualização**: 2026-07-05 | **Camada**: APPLICATIONS (derivação do projeto)
> Regras de desenho do Onion **derivadas da evidência** da camada 1 — vinculantes para todo
> artefato da vertical `onion-education` (ADR). Cada diretriz cita seu fato-âncora; se a
> evidência mudar (replicações, novas rodadas), a diretriz é revisitada — nunca o contrário.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.3.0 |
| **Data de Criação** | 2026-07-05 |
| **Última Atualização** | 2026-07-05 |
| **Evidência citada (SSOT)** | [srl-zimmerman.md §4](../theories/srl-zimmerman.md) · [plea-rosario.md](../theories/plea-rosario.md) |
| **Vinculante por** | [ADR onion-adr-education-vertical](../../../analysis/onion-adr-education-vertical-2026-07.md) |

---

## As diretrizes

| # | Diretriz | Fato-âncora (camada 1) | Força |
|---|---|---|---|
| 1 | **Fases SRL explícitas** em todo artefato educacional — o aprendiz vê e percorre planificar→executar→avaliar (e o ciclo dentro de cada fase) | estrutura de fases embutida é o ingrediente ativo do andaime ([srl-zimmerman §4](../theories/srl-zimmerman.md), SRLAgent — medium, aguarda replicação) · recursividade intra-fase ([plea-rosario §2](../theories/plea-rosario.md)) | vinculante |
| 2 | **Avaliação forçada** — artefato educacional NUNCA entrega resposta sem exigir avaliação/reflexão do aprendiz antes ou junto. **Nuance por mídia** (fricção F-1 do F1): o "forçar" tem três garantias distintas, cada uma com rótulo honesto — **gate técnico** (agente/runtime segura a resposta) · **gate estrutural** (formulário/fluxo que trava) · **gate ritual** (material estático + combinado de grupo, ex.: regra de ouro do squad) | "metacognitive laziness": IA genérica melhora a tarefa sem gerar aprendizagem ([srl-zimmerman §4](../theories/srl-zimmerman.md), Fan et al. 2025, RCT peer-reviewed) · fricção de campo: sinal `2026-07-05-friccoes-f1` | vinculante |
| 3 | **Avaliação que redesenha** — o fechamento de um ciclo de aprendizagem produz redesenho explícito de estratégia para o próximo, não só nota/veredito | Avaliação = redesenho, precursora da Planificação ([plea-rosario §1](../theories/plea-rosario.md)) | vinculante |
| 4 | **Rótulos de veredito preservados** em todo material derivado — fato-confirmado ≠ analogia-plausível ≠ decisão-nossa | a própria pesquisa (verificadores exigiram a separação); princípio fonte≠derivação desta categoria | vinculante |
| 5 | **Fonte ≠ derivação (fronteira física)** — teoria vive em `theories/` (zero Onion); nossa leitura vive em `applications/` (cita, não reescreve) | decisão do maestro 2026-07-05; convergência Zettelkasten (literature≠permanent notes) · Diátaxis (reference≠how-to) · grounding≠guidance | vinculante |
| 6 | **Prompts móveis: não prometer** — nenhum artefato depende de mensageria autorregulatória até a rodada Q3 + gatilho do eixo SDAAL | Q3 sem claims sobreviventes ([srl-zimmerman §5](../theories/srl-zimmerman.md)) | vinculante |
| 8 | **Fidelidade ao design system do alvo** — material derivado HERDA o style/script do documento-referência e usa só componentes existentes (paleta não basta; inventar estrutura paralela = impor e quebrar consistência p/ o aprendiz) | correção do maestro no F1 (fricção F-4, 2026-07-05): a 1ª versão do ciclo-plea copiou tokens mas não o layout — refeita herdando o design system do guia (que carrega os tokens DTCG do Onion + light/dark) | vinculante |
| 9 | **A teoria assina nos créditos; no fluxo, desaparece no comportamento** — em produtos NÃO-educacionais derivados da doutrina (ex: Onion Mini), o nome/jargão da teoria ("PLEA", "Planificar") vive em UM lugar (créditos/README); as superfícies operacionais carregam só o comportamento em língua clara ("Planejar → Executar → Avaliar", "checkpoint de fechamento"). Em produtos EDUCACIONAIS (um adotante, theories/), nomear o modelo segue obrigatório (diretriz 4) | correção do maestro no Mini (fricção F-5, 2026-07-05): acrônimo em ~10 superfícies operacionais = carga cognitiva + distrator de credibilidade p/ dev iniciante; fonte≠derivação aplicado à ATRIBUIÇÃO (assina 1×) | vinculante |
| 7 | **Narrativa como veículo é bem-vinda** — materiais podem usar herói-modelo/storytelling, citando o mecanismo (modelação observacional) | narrativas de Rosário ([plea-rosario §4](../theories/plea-rosario.md)) | recomendada |

## Escopo e modos (revisões do F1 — fricções F-2 e F-3)

- **Dois modos de aplicação**: **nativo** (artefato novo já nasce com as fases embutidas) e
  **aditivo** (artefato existente maduro ganha **camada companheira + costura mínima**, fonte
  preservada — "adota, não impõe" aplicado a materiais). Reescrever material v2+ polido sem
  gatilho é risco, não virtude.
- **Escopo por tipo de material**: as diretrizes 1-3 valem para materiais de **JORNADA/tarefa**
  (guias, trilhas, projetos). Materiais de **REFERÊNCIA** (cartões, glossários, bancos de
  prompts) ficam fora das fases — carregam só a diretriz 4 (rótulos) e, opcionalmente, ponteiros
  aos checkpoints da jornada.

## Aplicação no F1 (dogfood um adotante) — ✅ EXECUTADO 2026-07-05

O 1º artefato real saiu: camada PLEA do guia do aluno (modo aditivo —
`<adopter>:materials/ciclo-plea-2026.html` + costura no guia): checkpoints por fase
com planificação escrita antes do 1º prompt, monitorização ("um ajuste por sessão"), ritual de
fechamento que termina em **redesenho**, regra de ouro do squad (gate ritual) e
personagem-modelo (Marina, à la Testas). As diretrizes 1, 3 e 7 aplicaram limpo; as fricções
F-1/F-2/F-3 (+ F-4, do review do maestro: fidelidade de design — v2 do artefato refeita no layout canônico) (sinal `2026-07-05-friccoes-f1-doutrina-plea`) viraram as revisões acima — o loop
fricção→doutrina fechou no mesmo dia.

## Relações

- Pontes que informam estas diretrizes: [onion-srl-bridges.md](onion-srl-bridges.md)
- Camada 1 (teoria/evidência): [../theories/](../theories/)
