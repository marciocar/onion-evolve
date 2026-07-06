# Fonte ≠ Derivação — a fronteira física entre o conhecimento-como-é e a nossa leitura dele

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-05 | **Categoria**: Conceitos
> Doutrina transversal batizada em 2026-07-05 (pergunta do maestro na vertical educacional:
> *"não podemos misturar o core das teorias com as nossas derivações — esta separação não
> deveria ser clara?"*). Como toda doutrina do Onion, **emergiu da prática antes de ganhar
> nome**: várias estruturas do framework já a executavam sem saber.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-07-05 |
| **Última Atualização** | 2026-07-05 |
| **Origem** | Refatoração das duas camadas de `education/` (PR #256) — a instância que revelou o princípio geral |
| **Família** | irmão epistemológico do "declarado ≠ verificado" |

---

## 1. O princípio

**Conhecimento-fonte e derivação nossa vivem em artefatos FISICAMENTE separados.** A fonte
(teoria, spec, medição, filesystem) é SSOT; a derivação (análise, ponte, diretriz, síntese,
lente) é **consumidora que cita — nunca reescreve**.

A separação por **rótulo inline** ("isto é fato, isto é analogia") é o primeiro passo, mas
frágil: rótulo apodrece na edição seguinte, exige disciplina de leitura, e mistura ritmos de
mudança num arquivo só. A separação por **fronteira física** (arquivos/diretórios distintos)
é estrutural: o drift vira impossível ou detectável por gate.

**Litmus test:** *"se a fonte mudar, em quantos lugares eu edito?"* — a resposta certa é **um**.

## 2. As três tradições convergentes (o consenso externo)

| Tradição | Separa | Equivalente aqui |
|---|---|---|
| **Zettelkasten/PKM** (Ahrens) | *literature notes* (fiéis à fonte) ≠ *permanent notes* (pensamento próprio) | teoria-como-é ≠ derivação |
| **Diátaxis** (padrão de facto em docs técnicas) | *reference/explanation* (fatos) ≠ *how-to/tutorial* (aplicação) | catálogo ≠ diretrizes |
| **Grounding ≠ guidance** (prática RAG/agêntica) | corpus-fonte com proveniência ≠ orientação sintetizada | KB citável ≠ ponte de engenharia |

## 3. Instâncias JÁ vivas no Onion (a doutrina emergiu daqui)

| Instância | Fonte | Derivação | Fronteira |
|---|---|---|---|
| **Vertical educacional** (a que batizou) | [`education/theories/`](../education/theories/) — zero Onion | [`education/applications/`](../education/applications/) — cita, não reescreve | diretórios + regra no README |
| **Identity KB** | material bruto (toda afirmação citada linha a linha) | [síntese canônica](../meta/onion-framework-identity.md) | arquivos distintos + ponteiro |
| **Spec-as-code derivada** | filesystem/frontmatter/manifests | `graph.md` · `inventory.md` (GERADOS) | scripts + lint de drift (R8/R19/R21) |
| **Knowledge Graph** | fontes via `trace:`/`TRACES_TO` | claims com `confidence` + veredito do radar | schema `.kg.yaml` ([doutrina](knowledge-graph-sdaal.md)) |
| **Memória de sessão** | o repo (ADR/KB/git) | memória = cache/ponteiro | [session-memory-lifecycle](session-memory-lifecycle.md) §4 |
| **Pesquisas verificadas** | fontes primárias (verbatims) | achados rotulados CONFIRMADO/PLAUSÍVEL | relatórios de deep-research |

## 4. Regras operacionais (quando e como aplicar)

1. **Um artefato consome conhecimento de outro?** → cita por referência; reescrever = criar uma
   segunda fonte que vai divergir.
2. **Duas naturezas com ritmos de mudança distintos num arquivo?** → separar fisicamente (o mesmo
   critério dono×ritmo×decisão que separa contextos de domínio).
3. **Rótulo inline é aceitável** para separações pequenas/locais; **fronteira física é
   obrigatória** quando a fonte é reutilizável por terceiros (exportável) ou quando a derivação
   pode ser refutada sem invalidar a fonte.
4. **Derivação refutada não contamina a fonte** — corrige-se a camada 2; a camada 1 só muda se a
   *fidelidade* estiver errada.
5. Onde houver gerador determinístico (graph, inventory), a fronteira é **guardada por lint** —
   editar o derivado à mão é violação.

## 5. Relação com "declarado ≠ verificado"

A família original trata de **estado** (o stamp diz X; o filesystem prova Y). Esta doutrina trata
de **conhecimento** (a fonte diz X; a nossa leitura propõe Y). O parentesco: ambas recusam
confiar em afirmação sem lastro rastreável — verificação para estado, **citação para
conhecimento**.

## 6. Relações

- Instância batizadora: [`education/README.md`](../education/README.md) (regra das duas camadas)
- Irmãs: [domain-context-lifecycle](domain-context-lifecycle.md) · [session-memory-lifecycle](session-memory-lifecycle.md) · [knowledge-graph-sdaal](knowledge-graph-sdaal.md)
- Diário da família: `.claude/diary/2026-07-03-declared-vs-verified-family.md`
