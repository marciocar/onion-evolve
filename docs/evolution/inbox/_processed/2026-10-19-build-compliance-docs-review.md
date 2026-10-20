---
title: "Revisão do /docs:build-compliance-docs no campo: sem grafo, sem produção × desenvolvimento, sem fontes externas e com um exemplo que ensina a inventar cobertura"
date: 2026-10-19
type: signal
kind: field-feedback
from: brain-granaai (hub, pin 59ebe7fe1288)
severity: medium
---

> ⚠️ **Redigido no core por ser repo público; o original está no hub.** Os números, os nomes de controle,
> os identificadores de lacuna e as ferramentas internas do adotante foram trocados por descrição genérica
> em 2026-10-20, por decisão do maestro. A fricção de cada achado segue como chegou.

# Revisão do `/docs:build-compliance-docs`

O maestro pediu para rever o comando e, no lugar do que ele gera, criar o grafo de compliance a partir da wiki
da empresa, dos documentos de compliance, das KBs e do código, separando o que está em produção do que está em
desenvolvimento. O resultado está em `docs/compliance/graph/compliance.kg.yaml` (275 nós, contrato v4 limpo,
radar sem aviso). Para chegar lá, o comando quase não ajudou. Os achados, do mais estrutural ao menor:

## 1. Nenhum `build-*-docs` tem etapa de grafo

`build-compliance-docs`, `build-business-docs` e `build-tech-docs` não citam `.kg.yaml` nem `/meta:kg`. A doutrina
KG-first diz que o grafo é o SSOT de estado; o comando que gera o contexto de compliance produz só prosa. Aqui o
grafo de negócio e os de domínio técnico já existiam por fora do comando, e o de compliance não existia.
**Pedido:** uma fase "modelar o grafo" que escreve `docs/<contexto>/graph/<contexto>.kg.yaml` no contrato
vendorizado, com `kg-contract-check.sh` e `kg-radar.sh` como gate da fase.

## 2. Não separa produção de desenvolvimento

O comando trata "controle implementado" como um estado só. No campo isso confunde três coisas: código na branch
de produção, código em branch ou PR, e controle que só existe no documento. **Pedido:** resolver a branch de
produção com `resolve-production-branch.sh`, medir cada controle nela (`git grep` com `arquivo:linha` e o comando
na `provenance`) e marcar `prod | dev | policy`. Aqui usamos `x_delivery`, porque o `plane` do contrato
(DEV/PROD) diz contra o que a afirmação foi verificada, não onde o código está. Talvez o contrato devesse ter um
campo para isso.

## 3. A pasta-alvo ignora o `onion-context.yaml`

O comando escreve em `docs/compliance-context/`; este repo declara `compliance: docs/compliance` em
`.claude/onion-context.yaml`. Os três `build-*-docs` têm o mesmo caminho fixo e nenhum lê o arquivo.

## 4. Não lê fontes externas nem o task manager

A maior parte do conteúdo de compliance da empresa estava fora do repo: dezenas de documentos na wiki
interna, centenas de tarefas no task manager e as decisões no chat da equipe. O comando não prevê nenhuma
delas, nem usa o `TASK_MANAGER_PROVIDER` para ligar controle e lacuna à tarefa que os trata. Foi o cruzamento
entre fontes que achou o mais grave: a wiki afirmava um controle que o próprio registro de acesso nega; um
status declarava um percentual de certificação que o documento do programa dava como "não iniciado"; e o task
manager mostrava em andamento uma mudança que o código já tinha em produção.

## 5. O exemplo de saída ensina a inventar cobertura

A seção "Output Esperado" mostra "ISO 27001: ✅ 12 documentos", "Controles: 85%", "Políticas: 100%". O modelo
copia a forma, e a regra "nunca inventar conformidade" do próprio comando perde para o exemplo. O fan-out para
os 4 especialistas gerou aqui 95 arquivos, a maioria template com "Aprovado pela Alta Direção" sem ata (uma lacuna
registrada no grafo do adotante). **Pedido:** o exemplo mostrar contagens medidas e a parcela `[TO BE COMPLETED]`; e um modo `reconcile`
(o índice deste repo diz que o comando rodou "em modo reconciliar", que o comando não define).

## 6. A precedência de evidência não cobre documento próprio feito para cliente

A régua de precedência ordena por frescor e a nota trata o interesse de fornecedor externo. O caso de campo foi
interno: documentos de status e cartas da própria empresa, escritos para due diligence, que declaram controles
que o código nega (outra lacuna registrada no grafo do adotante). A mesma lente de interesse vale para eles.

## 7. Escrever grafo à mão no contrato v4 + radar tem três armadilhas sem molde

O gerador desta rodada caiu em todas, uma por vez:
- o `kg-radar.sh` só lê nós em lista **indentada** (`  - id:`); o `yaml.safe_dump` padrão escreve `- id:` na
  margem e o radar aborta com "0 nós";
- o contrato pede data entre aspas (`yaml.unquoted-date`), e a seção BI-TEMPORAL do radar declara ILEGÍVEL todo
  nó com `valid_from` sem `verified_at` (a mensagem fala em formato, mas a causa é o par ausente);
- `impact` é 1..5 no contrato, e a escala natural da modelagem foi 1..10.

**Pedido:** um escritor de grafo vendorizado (Python, sem dependência além do PyYAML) que já saia conforme ao
contrato e legível pelo radar. Hoje cada adotante reescreve isso.

## 8. O hook `session-currency-check.sh` compara com a branch errada

Neste hub a integração do Onion é `onion/develop` (`resolve-integration-branch.sh`). O hook avisou "base defasada,
5 commits atrás de origin/develop" e mandou rebasear sobre a `develop` de produto. Falso positivo: deveria usar o
mesmo resolvedor de integração.

## 9. Subagente cortado por limite não deixa nada

O agente que verificava o código parou por limite semanal da API sem gravar resultado parcial; a verificação foi
refeita na sessão principal. Para fan-out longo, vale pedir que cada agente grave a saída por partes.
