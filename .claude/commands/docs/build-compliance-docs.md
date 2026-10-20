---
name: build-compliance-docs
description: Gerar arquitetura de compliance na pasta de contexto declarada (default `docs/compliance-context/`).

parameters:
  - name: frameworks
    description: Frameworks (iso27001,soc2,iso22301,pmbok ou all)
    required: false
  - name: due_diligence
    description: Caminho para checklist de DD
    required: false
  - name: mode
    description: generate (default em pasta vazia) ou reconcile (default quando a pasta já tem docs)
    required: false

allowed-tools: Read Write Grep Glob Bash(grep *) Bash(find *) Bash(ls *) Bash(wc *) Bash(bash .claude/utils/scope/resolve-context-dir.sh *)
category: docs
tags:
  - compliance
  - security
  - audit

version: "4.1.0"
updated: "2026-10-20"

related_commands:
  - /docs:build-tech-docs
  - /docs:build-business-docs

related_agents:
  - security-information-master
  - iso-27001-specialist
  - soc2-specialist
---

# 📋 Gerador de Documentação de Compliance

Criar documentação de conformidade para auditorias e certificações.

## 🎯 Objetivo

Gerar arquitetura completa de docs de compliance multi-framework.

## 🔧 Modos de Execução

```bash
# Modo 1: Seletivo
/docs/build-compliance-docs frameworks="iso27001,soc2"

# Modo 2: Due Diligence
/docs/build-compliance-docs due_diligence="path/to/checklist.md"

# Modo 3: Auto (analisa projeto)
/docs/build-compliance-docs

# Modo 4: Completo
/docs/build-compliance-docs frameworks="all"

# Modo 5: Reconciliar (pasta já populada — o default nesse caso)
/docs/build-compliance-docs mode=reconcile
```

> **Modo `reconcile`.** A pasta-alvo já tem documentos (gerados antes ou escritos à mão). O comando
> **não regenera** e **não sobrescreve** texto humano: lê cada documento, confronta cada controle que ele
> declara com a evidência (régua de precedência abaixo), e só (1) troca `[TO BE COMPLETED]` por conteúdo
> quando acha evidência citável, (2) marca `[INFERIDO]` o que inferiu, e (3) escreve no `index.md` uma
> seção **"Divergências"** com cada controle que o documento declara e a evidência nega, com a fonte dos
> dois lados (`arquivo:linha` ou documento e data). Documento sem nenhum controle confirmado não é apagado:
> é listado como "sem evidência" na mesma seção. Em pasta populada e sem `mode`, o default é `reconcile`.
> **Populada** quer dizer: há `.md` em `<raiz>` além de `README.md` e `index.md` (a pasta-template que a
> adoção monta só tem o `README.md` e cai em `generate`). `frameworks` e `due_diligence` continuam valendo
> em `reconcile`: escolhem quais documentos reconciliar, e um framework pedido sem documento na pasta é
> gerado como em `generate` (só ele).

## ⚡ Fluxo de Execução

### Passo 0: Resolver a pasta-alvo

A pasta não é fixa. O repo pode declará-la em `.claude/onion-context.yaml` (`context.compliance`), e a
declaração vence a convenção (skill `onion-compliance-context` §2):

```bash
bash .claude/utils/scope/resolve-context-dir.sh compliance --source
# → "docs/compliance<TAB>onion-context"  (declarado)  ou  "docs/compliance-context<TAB>default"
```

Daqui em diante, **`<raiz>`** é o caminho que ele imprimiu. Saída `3` = declaração inválida: **pare** e
mostre o erro (gravar no default quando o repo declarou outra pasta é o defeito que este passo cura).
Passe a `<raiz>` a cada especialista no Passo 3: os caminhos `docs/compliance-context/` dos prompts deles
são o default, não uma ordem.

### Passo 1: Detectar Modo

SE `{{mode}}` = reconcile, ou `<raiz>` está populada (`.md` além de `README.md`/`index.md`) e `{{mode}}`
não foi dado → Modo Reconciliar (os testes abaixo seguem valendo para escolher os frameworks)
SE `{{frameworks}}` → Modo Seletivo
SE `{{due_diligence}}` → Modo DD (analisar checklist)
SENÃO → Modo Auto (analisar projeto)

### Passo 2: Selecionar Frameworks

| Framework | Foco | Quando Usar |
|-----------|------|-------------|
| ISO 27001 | Segurança da Info | Certificação, DD |
| ISO 22301 | Continuidade | DR, BCP |
| SOC2 | Trust Services | Clientes enterprise |
| PMBOK | Governança | Projetos |

#### Resolução de evidência conflitante

Fontes podem se contradizer (ex.: controles reais divergem da política escrita, ou docs antigas
descrevem um processo superado). Aplique esta **ordem de precedência** (mais forte → mais fraca):

1. Controles e configuração reais (o que está implementado e é auditável)
2. Políticas e registros vigentes marcados como atuais
3. Docs de compliance sem marcação de status
4. Docs marcadas como históricas/superadas → **não** usar como verdade atual

Registre o conflito explicitamente e sinalize a fonte desatualizada como follow-up, em vez de
propagar a contradição para a documentação gerada.

> **⚠️ Evidência de FORNECEDOR carrega interesse — a precedência acima ordena por *frescor*, não por
> *neutralidade*.** Relatório de pentest, laudo, parecer e certificação são autênticos e íntegros e ainda
> assim **calibrados** por quem os emite. Ao montar pacote de auditoria a partir deles, leia a
> **estrutura** antes de propagar a métrica: achados replicados por superfície (mesma classe por
> host/endpoint/formulário) inflam a contagem; severidade fora da faixa usual da classe é ênfase;
> **incentivo impresso no próprio texto** (reteste pago, etapa seguinte precificada) é evidência, não
> suspeita. O que o fornecedor **concede contra o próprio interesse** é a parte de maior confiança do
> documento. **Interesse qualifica a leitura, não a anula** — achado distinto e de lógica de negócio não
> se relativiza. Doutrina: [evidence-source-interest.md](../../../docs/knowledge-base/concepts/evidence-source-interest.md).

> **⚠️ E o documento PRÓPRIO feito para fora carrega o mesmo interesse.** Status de certificação,
> carta de due diligence, questionário de segurança respondido, deck para investidor: a empresa os escreve
> para o cliente ou o auditor, e eles **declaram** controles. Não são "políticas vigentes" (nível 2) só
> por serem internos e recentes. Valem como **declaração a verificar**: o controle que eles afirmam entra
> como implementado **só** se o nível 1 (código, configuração, registro) o confirma. Quando o código nega
> o que o documento declara, o código vence, e a divergência vira **lacuna nomeada** (fonte e data dos
> dois lados) no `index.md`. Nunca vira texto de conformidade. Caso de campo (2026-10-19, um adotante):
> a wiki declarava um controle que o backlog interno negava, e o status de certificação declarava um
> avanço que o próprio documento do programa negava. Leitura completa em
> [evidence-source-interest.md](../../../docs/knowledge-base/concepts/evidence-source-interest.md) §Documento próprio.

> **Modo não-interativo (infer-from-evidence).** Sem usuário disponível ou evidência completa,
> não bloqueie: infira a partir do repo e dos artefatos existentes, **marque cada inferência**
> com `[INFERIDO]` e liste as suposições numa seção "Pendências de validação" no `index.md`.
> Requisitos sem qualquer evidência viram `[TO BE COMPLETED]` — **nunca** invente conformidade.

### Passo 3: Delegar para Especialistas (Fan-Out Paralelo)

Os 4 especialistas são **independentes entre si** — sem dependência de ordem. Despachá-los em **paralelo** via orquestração (pattern `fan-out-and-synthesize`).

Use `/meta:orchestrate` ou a skill `onion-orchestration` para despachar em paralelo:

```
PARALELO (todos ao mesmo tempo, sem esperar o anterior):
  "iso27001" → @iso-27001-specialist
  "iso22301" → @iso-22301-specialist
  "soc2"     → @soc2-specialist
  "pmbok"    → @pmbok-specialist
```

> Despache apenas os especialistas cujos frameworks foram selecionados no Passo 2.
> Não há dependência entre eles — iniciar todos simultaneamente.

**Fan-in (síntese):** após todos finalizarem, `@security-information-master` consolida os resultados e segue para o Passo 4.

> **Em `reconcile`**, o despacho é o mesmo, mas o pedido a cada especialista muda: **ler** os documentos do
> framework dele em `<raiz>`, confrontar cada controle declarado com a evidência e devolver a lista de
> trocas (lacuna preenchida com fonte, `[INFERIDO]`, divergência). O especialista não reescreve documento
> existente; o Passo 4 aplica só essas trocas e a seção "Divergências".

### Passo 4: Gerar Documentação

Em `generate`, gere os arquivos em `<raiz>` (Passo 0) seguindo o template-base
`.claude/commands/common/templates/compliance-context-template.md`. Crie apenas os arquivos dos
frameworks selecionados. Em `reconcile`, aplique só as trocas devolvidas no Passo 3 e escreva a
seção "Divergências" do `index.md`; documento existente não é regenerado.

> **Convenção de nomes (esta seção tem precedência sobre o template-base).** Use
> **kebab-case minúsculo** para todos os arquivos e pastas (`risk-assessment.md`,
> `trust-services.md`), exatamente como na estrutura abaixo. Se o template sugerir nomes em
> UPPERCASE, **ignore** — a estrutura deste comando é a autoritativa.

Estrutura de saída (em `<raiz>`; o default é `docs/compliance-context/`):
```
<raiz>/
├── index.md
├── iso27001/
│   ├── policy.md
│   ├── risk-assessment.md
│   └── controls.md
├── soc2/
│   ├── trust-services.md
│   └── evidence.md
└── reports/
    └── summary.md
```

### Passo 5: Validar e Entregar

Antes de imprimir o resumo, **meça**. Cada número do resumo sai de um comando, e o comando vai junto:

```bash
find <raiz> -name '*.md' | wc -l                              # documentos na pasta (inclui README/index)
grep -rlF '[TO BE COMPLETED]' <raiz> | wc -l                  # documentos com lacuna aberta
grep -roF '[TO BE COMPLETED]' <raiz> | wc -l                  # lacunas abertas (marcadores)
grep -roF '[INFERIDO]' <raiz> | wc -l                         # inferências sem confirmação
```

**Não há percentual de cobertura no resumo.** "Controles: 85%" exige um denominador (os controles
aplicáveis) e um numerador medido (os confirmados no nível 1 da precedência). O comando não mede
nenhum dos dois, então não imprime a razão. Documento gerado não é controle implementado, e a contagem
de documentos não diz nada sobre conformidade.

## 📤 Output Esperado

O exemplo mostra a **forma**. Os números são de uma rodada ilustrativa: copie o comando, nunca o número.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 DOCS DE COMPLIANCE GERADOS — rascunho, não atestado
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Pasta: docs/compliance (declarada em .claude/onion-context.yaml)
⚙️  Modo: generate · Frameworks: ISO 27001, SOC2

📊 Medido (comandos do Passo 5):
∟ Documentos na pasta: 9  find docs/compliance -name '*.md' | wc -l
∟ Com lacuna aberta: 7     grep -rlF '[TO BE COMPLETED]' docs/compliance | wc -l
∟ Lacunas abertas: 41      grep -roF '[TO BE COMPLETED]' docs/compliance | wc -l
∟ Inferências: 12          grep -roF '[INFERIDO]' docs/compliance | wc -l

⚠️ Divergências (documento declara, evidência nega): 2 → index.md §Divergências
∟ MFA "implantado" (wiki, AAAA-MM) × contagem de usuários com MFA no backlog (AAAA-MM)
∟ "Aprovado pela Alta Direção" (policy.md) × nenhuma ata citada → [TO BE COMPLETED]

🚫 Não medido: cobertura de controles (sem denominador nem confirmação no código)

🚀 Próximo: fechar as lacunas com evidência citável, ou rodar mode=reconcile depois
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 🔗 Referências

- **Template-base**: `.claude/commands/common/templates/compliance-context-template.md`
- **Pasta-alvo**: a resolvida no Passo 0 (`resolve-context-dir.sh compliance`; default `docs/compliance-context/`)
- **Comandos complementares**: `/docs:build-tech-docs` · `/docs:build-business-docs`
- **Ciclo de vida (SSOT viva)**: [domain-context-lifecycle.md](../../../docs/knowledge-base/concepts/domain-context-lifecycle.md)
- Orquestrador: @security-information-master · ISO 27001: @iso-27001-specialist · SOC2: @soc2-specialist

## ⚠️ Notas

- Não criar um único arquivo grande — sempre multi-arquivo linkado pelo `index.md`
- Docs gerados são templates base; customizar para o contexto específico antes de auditorias
- Marcar gaps como `[TO BE COMPLETED]` e inferências como `[INFERIDO]` — nunca inventar conformidade
- Aprovação, assinatura e ata ("Aprovado pela Alta Direção", "Assinado por") só com a ata ou o registro
  citado (data e instância); sem ele, o campo fica `[TO BE COMPLETED]`
- "Requisito mapeado" (existe documento que o trata) não é "requisito atendido" (controle confirmado no
  nível 1 da precedência); o resumo e o `index.md` dizem qual dos dois é
- Regenerar quando controles, escopo ou frameworks mudam (contexto é SSOT viva, não snapshot)
