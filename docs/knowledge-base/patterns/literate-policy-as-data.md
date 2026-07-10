# Literate Policy-as-Data — a config de três leitores

## 📋 Metadados

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Criado** | 2026-07-10 |
| **Última Atualização** | 2026-07-10 |
| **Categoria** | Patterns |
| **Tags** | `literate-configuration`, `policy-as-data`, `provenance`, `members-yaml`, `ai-operator` |
| **Instância batizadora** | `docs/evolution/federation/members.yaml` (o registro da federação) |

---

## 🎯 O padrão

Um arquivo de configuração onde **dados, história e ordens convivem** — um arquivo, **três leitores**:

1. **O parser** lê os dados (YAML/JSON válido — a política executável).
2. **O humano** lê a história (por que cada valor é o que é, datado e citado).
3. **O operador de IA** lê as **ordens** (guardas comportamentais que a próxima sessão obedece
   *antes* de agir sobre o dado).

O que o distingue de "config bem comentada" comum: o comentário aqui não descreve — ele **governa**.
Exemplo real (a lei inline que nasceu de um incidente):

```yaml
onion_version: 8e22352da32f   # Regra: um pin só entra aqui VERIFICADO por pin-integrity-check.sh
                              # — nunca do stamp declarado (histórico: a458a0fc6b71 era FORJADO
                              # por restore manual de 06-30; sinal 2026-07-02-...).
```

Dado (`8e22352da32f`) + regra ("só entra verificado") + proveniência (o incidente, datado, com o
sinal citado) — no mesmo bloco, no ponto exato onde a regra age.

## 🧬 Genealogia (quem "inventou")

Não há um inventor único — é uma convergência de quatro tradições, com um twist da era dos agentes:

| Tradição | Autor/época | O que contribuiu |
|---|---|---|
| **Literate Programming** | Donald Knuth, 1984 | A filosofia: o artefato é literatura para humanos que por acaso executa. "Expliquemos a humanos o que queremos que o computador faça." |
| **Config UNIX comentada** | cultura UNIX, anos 70–80 (`sshd_config`, `httpd.conf`) | O manual dentro do arquivo — comentário como documentação de operação. |
| **ADRs** | Michael Nygard, 2011 | Decisão **datada com o porquê** e status. Aqui, *inlined* no ponto de configuração em vez de arquivo separado — a proveniência mora onde a decisão age. |
| **Policy-as-data** | onda OPA/declarative-governance | O arquivo **é** a política executável, não descrição dela. |
| **O twist (era dos agentes)** | prática deste framework, 2026 | Comentário como **instrução ao próximo operador de IA** — guarda comportamental lida-e-obedecida por sessões futuras. Evoluiu no uso, incidente a incidente. |

O nome de família estabelecido mais próximo é **"literate configuration"** (popularizado na
comunidade Emacs/org-mode); este padrão é a variante em que a config é **política de governança**
e o terceiro leitor é uma IA.

## 📏 As regras da casa (o que faz o padrão funcionar)

1. **Comentário carrega proveniência datada.** Decisão sem data e sem fonte é opinião — cada "por
   quê" cita `AAAA-MM-DD` + o artefato (sinal, ADR, parecer, commit). É `TRACES_TO` do KG em prosa.
2. **⚠️ vira guarda, não aviso decorativo.** Um warning inline é ordem para o operador ("não renomear
   sem migrar o clone", "NÃO confundir com origem") — a sessão que o viola está errada, não o arquivo.
3. **Decisão revertida não se apaga — se anota.** ("a decisão 'Coexistem' foi revertida p/
   consolidação") — o arquivo reconcilia história como o KG (append de contexto, nunca amnésia).
4. **O parser nunca depende do comentário.** Dado que o motor precisa vive em CHAVE, jamais em
   comentário — o arquivo tem que sobreviver a um strip de comentários sem mudar de comportamento.
5. **Instrução é imperativa e endereçada** ("verificar via pin-integrity no ambiente dele") — não
   voz passiva; o próximo operador sabe o que fazer sem procurar outro doc.
6. **Segredo jamais** — nem em chave, nem em comentário (o arquivo é versionado e legível por todos
   os leitores, inclusive os que não deveriam ter o segredo).

## 🟢 Quando usar / 🔴 quando não

- ✅ **SSOTs de governança versionados** lidos por humanos E por sessões de IA: registro de
  federação, trust policy, roadmaps executáveis, manifests de adoção.
- ✅ Arquivos onde a **história das decisões importa tanto quanto o valor atual** (regulado,
  auditoria, federação).
- 🔴 Config de alta rotação mecânica (lockfiles, gerados) — comentário vira ruído stale.
- 🔴 Substituto de schema/validação — a guarda determinística (lint/selftest) continua sendo quem
  reprova; o comentário governa o **operador**, o gate governa o **artefato**.
- 🔴 Dados que o motor lê — regra 4 é inviolável.

## 🔗 Relações

- **[SDAAL](../concepts/specification-driven-ai-abstraction-layer.md)** — spec estruturada executável
  por IA; este padrão é o mesmo espírito no plano config/política.
- **[Knowledge Graph SDAAL](../concepts/knowledge-graph-sdaal.md)** — a proveniência inline é o
  `TRACES_TO` em prosa; quando a densidade de relações crescer, o grafo é o próximo passo.
- **Spec-as-Code** ([strategy](../concepts/spec-as-code-strategy.md)) — "specs são a fonte de
  verdade"; aqui a política é a spec.
- **Instância batizadora**: `docs/evolution/federation/members.yaml` — nomeado em 2026-07-10 quando
  o maestro perguntou "quem inventou isso? qual o nome desta técnica?" ao ver o arquivo no editor.
