# Diretrizes de desenho de artefatos educacionais — vinculantes na vertical (camada 2)

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-05 | **Camada**: APPLICATIONS (derivação do projeto)
> Regras de desenho do Onion **derivadas da evidência** da camada 1 — vinculantes para todo
> artefato da vertical `onion-education` (ADR). Cada diretriz cita seu fato-âncora; se a
> evidência mudar (replicações, novas rodadas), a diretriz é revisitada — nunca o contrário.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-07-05 |
| **Última Atualização** | 2026-07-05 |
| **Evidência citada (SSOT)** | [srl-zimmerman.md §4](../theories/srl-zimmerman.md) · [plea-rosario.md](../theories/plea-rosario.md) |
| **Vinculante por** | [ADR onion-adr-education-vertical](../../../analysis/onion-adr-education-vertical-2026-07.md) |

---

## As diretrizes

| # | Diretriz | Fato-âncora (camada 1) | Força |
|---|---|---|---|
| 1 | **Fases SRL explícitas** em todo artefato educacional — o aprendiz vê e percorre planificar→executar→avaliar (e o ciclo dentro de cada fase) | estrutura de fases embutida é o ingrediente ativo do andaime ([srl-zimmerman §4](../theories/srl-zimmerman.md), SRLAgent — medium, aguarda replicação) · recursividade intra-fase ([plea-rosario §2](../theories/plea-rosario.md)) | vinculante |
| 2 | **Avaliação forçada** — artefato educacional NUNCA entrega resposta sem exigir avaliação/reflexão do aprendiz antes ou junto | "metacognitive laziness": IA genérica melhora a tarefa sem gerar aprendizagem ([srl-zimmerman §4](../theories/srl-zimmerman.md), Fan et al. 2025, RCT peer-reviewed) | vinculante |
| 3 | **Avaliação que redesenha** — o fechamento de um ciclo de aprendizagem produz redesenho explícito de estratégia para o próximo, não só nota/veredito | Avaliação = redesenho, precursora da Planificação ([plea-rosario §1](../theories/plea-rosario.md)) | vinculante |
| 4 | **Rótulos de veredito preservados** em todo material derivado — fato-confirmado ≠ analogia-plausível ≠ decisão-nossa | a própria pesquisa (verificadores exigiram a separação); princípio fonte≠derivação desta categoria | vinculante |
| 5 | **Fonte ≠ derivação (fronteira física)** — teoria vive em `theories/` (zero Onion); nossa leitura vive em `applications/` (cita, não reescreve) | decisão do maestro 2026-07-05; convergência Zettelkasten (literature≠permanent notes) · Diátaxis (reference≠how-to) · grounding≠guidance | vinculante |
| 6 | **Prompts móveis: não prometer** — nenhum artefato depende de mensageria autorregulatória até a rodada Q3 + gatilho do eixo SDAAL | Q3 sem claims sobreviventes ([srl-zimmerman §5](../theories/srl-zimmerman.md)) | vinculante |
| 7 | **Narrativa como veículo é bem-vinda** — materiais podem usar herói-modelo/storytelling, citando o mecanismo (modelação observacional) | narrativas de Rosário ([plea-rosario §4](../theories/plea-rosario.md)) | recomendada |

## Aplicação no F1 (dogfood pulse-mais)

O 1º artefato real (guia do aluno pela lente PLEA) deve demonstrar as diretrizes 1-3 e 7 e será o
teste de campo delas — fricções encontradas voltam para cá como revisão, nunca silenciosamente.

## Relações

- Pontes que informam estas diretrizes: [onion-srl-bridges.md](onion-srl-bridges.md)
- Camada 1 (teoria/evidência): [../theories/](../theories/)
