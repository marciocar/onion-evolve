---
title: 'Doutrina KG-SSOT tem forcing function só na leitura — proposta de gate de proveniência invertido'
date: 2026-07-20
from: granaai (consumidor)
to: onion-evolve (core)
type: sinal-de-campo
flow: upstream (consumidor→core)
about: knowledge-graph-sdaal.md §SSOT-as-runtime — lacuna estrutural + cura testada
source_commit: 91d5dbb05a6d
---

# Sinal: o laço do KG-SSOT está fechado na leitura e aberto na escrita

## O buraco

O pin `91d5dbb` trouxe a doutrina *SSOT-as-runtime* e o `/catch-up` já obriga a **abrir o KG
primeiro** (passo 0, com mecanismo — não conselho). O `kg-radar.sh` reprova grafo inconsistente. E
implementamos aqui um veredito **STALE-TRACE** que acusa nó cujo arquivo-traço mudou depois do
`verified_at`.

Três mecanismos. Todos protegem o grafo de **estar errado**. Nenhum impede conhecimento de
**nascer fora dele**.

Se um agente produz um markdown com achados, nada dispara. O laço está fechado em *"não deixe o KG
mentir"* e aberto em *"não deixe conhecimento viver fora do KG"*.

## A evidência — e por que ela é forte

Não foi desleixo. Foi um agente disciplinado seguindo um plano aprovado.

Rodamos uma avaliação orquestrada de documentação de compliance para uma due diligence: **70
agentes, 0 erros**, um especialista da vertical por controle + refutação adversarial de cada
achado. Saíram 50 achados confirmados e 10 derrubados, em JSON estruturado.

Escrevi o relatório em markdown (422 linhas) e **não ingeri nada no `.kg.yaml`**. Idem para uma
auditoria de referências de ambiente contra a AWS. Só entrou no SSOT quando o maestro perguntou
*"fez kg das pesquisas e atualizou o kg principal?"*.

**A raiz estava no plano, não na execução.** O plano — escrito por mim, aprovado pelo maestro —
punha "construir o grafo" numa fase e "avaliar" na fase seguinte, com saída declarada em markdown.
O grafo virou **predecessor** da avaliação em vez de **destino** dela. Nenhum gate existente pegaria
isso, porque nenhum gate olha para essa direção.

Sintoma correlato, na mesma rodada: a etapa adversarial derrubou um nó **do nosso próprio grafo**
porque o `trace` citado não sustentava a afirmação (a observação vinha do Google Drive, não de
documento versionado). Ou seja, afirmação sem âncora verificável também entra pela modelagem
manual, não só pelos relatórios.

## A cura que testamos

Duas peças, ambas em validadores **locais** (não tocamos o `lint-artifacts.sh` vendorizado, para
não gerar drift que conflite no próximo `--update` — mesma disciplina do incidente `DRIFT-ONION`):

**1. Relatório como projeção do grafo.** Um renderizador lê o `.kg.yaml` e emite o markdown, que
passa a carregar cabeçalho declarando que edição manual não altera o SSOT. Enquanto o relatório for
redigido em paralelo, ele pode divergir do grafo — recriando, dentro do instrumento
anti-divergência, a divergência que ele combate.

**2. Gate de proveniência INVERTIDO.** O radar já pergunta *"esta decisão está ancorada numa
origem?"*. Falta o espelho: *"este relatório existe no grafo?"*. Um documento de análise está
coberto quando algum nó o cita em `trace:`/`evidence:`.

**A catraca é o que torna adotável.** O passivo (aqui, 31 documentos anteriores) vai para um
baseline e é tolerado; documento **novo** sem nó é violação HARD. Sem isso o gate nasceria
reprovando dezenas de arquivos e seria desligado no primeiro dia. E o baseline só encolhe — ao
modelar um legado, ele sai da lista. A métrica de saúde é o baseline diminuindo, não o gate passando.

Verificado nos dois sentidos: os dois documentos criados naquele dia passam por **cobertura real**,
não por tolerância; e um documento de teste sem nó foi corretamente reprovado.

## Pedido

Considerar promover como doutrina no core:

1. **Princípio**: relatório é projeção do grafo, não fonte paralela. Se um comando produz achados
   estruturados, o destino é o `.kg.yaml`; o markdown é vista.
2. **Mecanismo**: gate de proveniência invertido com catraca, espelhando a checagem de proveniência
   que o radar já faz para decisões.
3. **Consequência para os comandos que orquestram** (`/meta:evolve`, `/meta:kg`, `/meta:context-freshness`,
   `/meta:kb-freshness`): a fase de síntese deveria escrever no grafo **antes** de renderizar
   relatório — e o template de plano deveria desencorajar "saída: relatório.md" como destino final
   de achados estruturados.

O item 3 é o que teria evitado o nosso caso: o erro entrou na fase de **planejamento**, quando
declarei markdown como saída da avaliação.

Implementação de referência disponível neste repo se for útil — mas o que viaja é schema + método,
não o código, conforme a soberania que a doutrina já estabelece.
