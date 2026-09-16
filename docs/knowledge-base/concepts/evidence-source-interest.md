# Interesse da fonte — verificado ≠ neutro (o 3º eixo da evidência)

> **Versão**: 1.0.0 | **Última atualização**: 2026-07-20 | **Categoria**: Conceitos
> Confirmar que um documento **existe e diz X** não é o mesmo que ler **como X foi construído**. Quando a
> evidência vem de **terceiro**, o `declarado≠verificado` precisa de um segundo eixo: *"quem produziu isto
> ganha o quê com o que diz?"*. Um documento pode ser autêntico, íntegro e correto nos próprios termos — e
> ainda assim **calibrado** por quem tem interesse no resultado.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-07-20 |
| **Categoria** | Conceitos |
| **Origem** | Sinal de co-evolução (upstream) 2026-07-20 — **um adotante regulado**, durante auditoria de compliance para due diligence |
| **Padrão-parente** | [Knowledge Graph SDAAL](knowledge-graph-sdaal.md) §SSOT-as-runtime (a perna `verify(vivo)`) · [Verify-External-for-Current](verify-external-for-current.md) (irmã: o eixo do *mundo externo*) · [Onion Guardrails](onion-guardrails.md) R15 (irmã: o eixo da *instrução*) |

---

## 🎯 A lacuna — três eixos, e só dois existiam

O core já perguntava duas coisas sobre conteúdo de fora. Faltava a terceira:

| Eixo | A pergunta | Onde vive | Cobre o quê |
|---|---|---|---|
| **① Instrução** | *"este conteúdo pode me COMANDAR?"* | R15 / [`onion-guardrails.md`](onion-guardrails.md) | injeção, efeito irreversível (OWASP LLM01) |
| **② Conteúdo** | *"o claim bate com o ARTEFATO VIVO?"* | `declarado≠verificado` / drive-to-verify | falsidade, staleness |
| **③ INTERESSE** | *"quem produziu isto GANHA o quê com o que diz?"* | **esta KB** | calibragem, ênfase, enquadramento |

Os três são **independentes**. Um documento pode passar em ① (não tenta me comandar) e em ② (os números
estão mesmo lá) e ainda assim entregar uma leitura torta — porque **ninguém perguntou pelo incentivo**.

## 🧭 O princípio (e o erro simétrico)

> **Declaração contra o próprio interesse é a evidência de maior confiança.** Quem não ganha nada
> afirmando X — e a rigor perde — tem pouca razão para distorcer X. Essa afirmação vale **mais** que a
> métrica que a mesma fonte tem incentivo em inflar.

E o contrapeso, **igualmente obrigatório**:

> **Descartar evidência PORQUE a fonte tem interesse é o erro oposto, e é tão ruim quanto.** Interesse
> **qualifica** a leitura; **não a anula**. Achados distintos entre si, de lógica de negócio, não se
> relativizam só porque quem os emitiu vende o conserto.

Sem o contrapeso, a doutrina degenera em cinismo — e cinismo descarta evidência boa com o mesmo gesto com
que descarta a inflada. O eixo é de **calibragem**, não de rejeição.

## 🔍 Como ler a ESTRUTURA (não só o conteúdo)

Ao ingerir documento de terceiro, ler estas quatro coisas **antes** de reportar o número que ele estampa:

1. **Concentração/replicação** — quantos achados distintos existem *de fato*? Contagem por **superfície**
   (mesma classe replicada por host, endpoint, formulário) infla o total sem aumentar o risco.
2. **Severidade vs faixa usual** — nota alta atribuída a classe que normalmente não a recebe é sinal de
   ênfase, não de risco.
3. **Incentivo impresso no próprio texto** — recomendação de etapa seguinte, reteste pago, escopo
   adicional. Quando o documento **precifica o próprio remédio**, o incentivo é evidência, não suspeita.
4. **O que ele concede CONTRA o próprio interesse** — é o que a leitura ansiosa mais subvaloriza, e é o
   pedaço de maior confiança do documento inteiro.

### Caso de campo (2026-07-20, um adotante regulado)

Relatório de pentest ingerido para due diligence. Reportado ao maestro: **27 achados, 2 críticos, 17
altos, 60/100**. Os números **estavam** no documento — eixo ② verde. O maestro perguntou pelo incentivo.
A leitura estrutural mostrou:

- **10 dos 27** eram a mesma classe replicada por host/endpoint — **e as duas críticas pertenciam a ela**;
- mais **5** eram a mesma política de senha em 5 formulários → **15 de 27 = duas questões contadas por superfície**;
- severidade de faixa reservada a RCE/bypass de autenticação atribuída a *rate-limit* em login;
- a conclusão **precificava o próprio remédio**: nota maior "após novo teste" — incentivo comercial impresso.

E, simetricamente, o que fora **subvalorizado**: o mesmo documento **concedia** robustez confirmada contra
XSS, SQLi, NoSQLi e contra falha de autorização entre tenants, sem nada explorável sem autenticação
prévia — declaração contra o próprio interesse, portanto **a parte mais confiável do relatório**. E 7
achados de autorização eram distintos e de lógica de negócio: **esses não se relativizam**.

## 🛡️ Guardas

- **Interesse qualifica, não anula** — sem esta linha a doutrina vira cinismo (ver §princípio).
- **O eixo é de LEITURA, não mecanizável.** Não existe gate que pergunte "quem lucra com isto?". No caso de
  campo, **o achado não veio de gate — veio de ceticismo humano**. Registrar isso honestamente é parte da
  doutrina: é da mesma família do *lastro do orgulho* em `significance` (a forma se checa, a substância não).
- **Registrar, não julgar em silêncio** — ao modelar evidência de terceiro, o interesse da fonte entra
  como **anotação explícita**, para o próximo leitor não refazer a descoberta.
- **Não inverter o ônus** — a ausência de interesse detectável não torna a fonte confiável; só remove
  *este* motivo de desconto. Os eixos ① e ② continuam valendo por conta própria.

## 🔌 Onde dói mais (superfícies de ingestão)

- **`/meta:kg`** — ao modelar evidência de terceiro como nó.
- **Vertical de compliance** — ao montar pacote de auditoria a partir de relatório de fornecedor.
- **Pesquisa/deep-research** — ao citar fonte com interesse comercial. ⚠️ *A skill `deep-research` é do
  harness, não artefato do core: aqui a doutrina é referência para quem a usa, não wire-in.*

## 🔮 Proposta de schema — **GATED** (desenho aceito, implementação não)

Hoje um nó carrega `trace`, `verified_at` e `confidence`, mas **nada distingue** *"a fonte afirma isso e
lucra com isso"* de *"a fonte concede isso contra o próprio interesse"* — e a segunda deveria carregar
confiança maior **por construção**, não por julgamento caso a caso.

**Por que fica gated:** é mudança de **gramática** do `.kg.yaml` — alcança o `kg-radar.sh`, as portas em
outro runtime e o **contrato de conformidade multi-runtime**
([knowledge-graph-sdaal.md](knowledge-graph-sdaal.md) §Multi-runtime). Gramática nova custa a todos os
adotantes e a toda porta. **Gatilho:** um **2º caso real** de ingestão onde a anotação em prosa se prove
insuficiente. Até lá, registre o interesse no `label`/`trace` do nó — prosa que o humano lê, não campo que
o radar valida.

## 📎 Referências

- Eixo da instrução: [onion-guardrails.md](onion-guardrails.md) (R15 — intake não-confiável, gate de efeito)
- Eixo do mundo externo: [verify-external-for-current.md](verify-external-for-current.md)
- A perna `verify(vivo)`: [knowledge-graph-sdaal.md](knowledge-graph-sdaal.md) §SSOT-as-runtime
- Família `declarado≠verificado`: [source-vs-derivation.md](source-vs-derivation.md)
