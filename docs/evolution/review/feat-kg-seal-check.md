---
branch: feat/kg-seal-check
date: 2026-08-07
reviewed_diff_sha256: 8ebec5bab9fbb10cbe15c9bc8f0a1ff26004b48f3c85f0563851c13d1f3bcb75
findings_total: 28
findings_real: 28
findings_fixed: 9
tokens: 539132
duration_min: 39
verdict: HARD-MAS-NAO-COMO-ESTAVA
reviewer: Elenxo — 4 refutadores por lente + juiz (opus/high), wf_d14c47de-fad
---

# Passada adversarial — a REGRA 57 sob ataque

**4 refutadores, 28 ataques, 0 descartados. Nenhuma lente falhou.** Veredito do juiz:
**«HARD, mas NÃO como está — e não em todos os ramos.»**

O golpe central: **os três falsos-positivos HARD que a guarda produzia disparavam exatamente para
quem OBEDECE a doutrina.** Uma guarda que pune a conformidade é pior que guarda nenhuma.

## Os três falsos-positivos, medidos

**1 · A direção do DRIFTED estava invertida.** O Passo 4 diz: *"**Novo** nó com a verdade atual +
`SUPERSEDES` → antigo; antigo vira `status: superseded`"*. O nó do ledger é o **ANTIGO** — ele
**recebe** a aresta. A guarda só aceitava `SUPERSEDES` **saindo**. Verifiquei em
`m2-bridge-logto-2026-07.kg.yaml`, o grafo que o **próprio contrato cita como o dogfood certo**
(`kg-freshness.md:156`): **11 arestas com alvo `superseded`, ZERO com origem**. Eram 11
falsos-positivos HARD latentes.

**2 · A igualdade de data bloquearia os próprios commits que a embarcaram.** A regra exigia
`verified_at == data do run`. Mas o Passo 4 manda `verified_at: <hoje>`, e "hoje" é o dia em que o
maestro **sela**, não o dia do run. Medido: `8b005f6` e `1681c7c` são **ambos de 2026-08-07**
escrevendo `verified_at: 2026-08-06`. Quem seguisse o contrato ao pé da letra seria reprovado pela
regra do mesmo commit. Curado com `>=`.

**3 · A regra era uma catraca contra RE-VERIFICAR.** Predicado *run-scoped* rodando contra grafo
**vivo**: com dois runs sobre o mesmo grafo, **nenhum estado satisfaz os dois ledgers**, porque
`verified_at` guarda uma só data. Isso a tornava incompatível com a razão de existir do
`/meta:kg-freshness`. Curado com guarda de precedência.

## Os fail-opens dentro da cura do fail-open

**Vocabulário aberto + contagem errada.** Um ledger escrito em **minúscula** — a mesma caixa que o
campo `status:` usa — atravessava os quatro ramos sem casar nenhum, e a guarda saía **VERDE sobre
grafo comprovadamente defeituoso**. A vacuidade não pegava porque eu contava **linhas lidas**
(`judged++`), não **julgamentos aplicados**. Curado: vocabulário fechado com HARD nomeado, e
`applied++` dentro de cada ramo.

**Aresta de JULHO selando veredito de AGOSTO.** O modo de falha original entrando pela porta da
frente: bastava flipar uma linha do ledger para DRIFTED, **sem escrever nada no grafo**, e a guarda
passava — porque a aresta já existia desde julho. Curado: a reconciliação tem de carregar a data do
run em alguma ponta.

**Helper morto == helper limpo.** No wire-in, `2>/dev/null || true` seguido de `[ -n "$out" ] ||
return 0` descartava stderr **e** exit code. Como o modo TSV não imprime nada quando está tudo
selado, **saída vazia significava ao mesmo tempo "verde" e "explodiu"** — toda a engenharia de
ISENÇÃO/VACUIDADE do helper morria na fronteira. Curado nos **dois** consumidores (`check_kg_seal` e
`check_review_artifact`): só no meu seria one-off.

## Severidade proporcional à evidência

**`REFUTED` desceu para SOFT.** Cobre **2 das 6** cláusulas que o Passo 4 exige (falta o nó
`evidence` com PROD, `verified_at`, `verified_against`, `trace`), o ledger real tem **zero** linhas
REFUTED e o teste de aceite **nunca exercitou esse ramo**. HARD ali seria poder emprestado da
evidência dos outros — o vexame do `kg-trace-resolve.sh:50-56` em espécie. `AUSENTE` e
`FONTE-ILEGIVEL` idem: nenhum é o defeito medido que originou a regra.

**A extração de frontmatter ficou restrita** ao bloco entre as duas primeiras linhas `---`: varrer o
arquivo inteiro fazia uma SYNTHESIS que apenas **documenta** o formato num bloco ```yaml disparar a
regra.

## O que NÃO mudou: o teste de aceite

Declarado **antes** de escrever a primeira linha do helper, e **intacto após toda a reescrita**:

```
964ab1c (#552, o selo original)  →  9 acusados   (os 9 ids do ledger, 0 a mais, 0 a menos)
8b005f6 (main pós-#555)          →  2 acusados   (D_whatsapp_dual_waha_default, D_structured_plan_and_doctrine)
HEAD    (com os 2 corrigidos)    →  0 acusados
```

Foi a régua que impediu as correções de virarem afrouxamento: **cada patch do Elenxo foi aceito só
depois de medir que o aceite não perdeu um ponto.**

## Verificação

- **16 selftests** de `kg-selo`, seis deles nascidos deste Elenxo (um por falso-positivo/fail-open)
- o mutation test **(j) falhou primeiro** — *"a mutação NÃO foi aplicada"* — quando reescrevi a
  comparação. A guarda-da-guarda acusou em vez de passar muda; corrigido o alvo do `sed`.
- helper que explode (`exit 2`) → **HARD `NAO-EXECUTOU` com o stderr**, não silêncio
- `lint-selftest` **680 passam / 0 falham / 0 pulam** (env de CI, corrida **SOLO**)
- `lint-artifacts` **0 HARD** · `rules-registry` verde · `lint-rules.md` regenerado (**56 regras,
  50 HARD, 11 SOFT**) e a REGRA 57 deixou de ser publicada **truncada no meio da oração**

## Fios que saem daqui, declarados

- **baseline pré-run para o UNVERIFIABLE**: `confidence rebaixada` é hoje o limiar absoluto
  `< 1.0`, satisfeito por vacuidade em **84,9%** da população real (1.422 de 1.675 nós). Comparar
  com o estado ANTES do run exige ler `git show <commit>:<graph>` — o `source:` já carrega o commit
  e o helper o descarta. Desenho maior que um patch de PR.
- **`status: drifted` como estado terminal**: a regra declara SELADO exatamente o estado em que a
  reconciliação é devida, e sem relógio. Pede catraca de janela, no shape das REGRAS 29/42/49.
- **a convenção única do DRIFTED**: hoje convivem duas formas inversas no mesmo repo. A REGRA 57
  aceita ambas porque não cobra label nem status do nó julgado. **Decidir e depois mecanizar** —
  não o contrário.
- **parser de arestas posicional**: o helper guarda `to:` e consome no `edge_type:`; ordem
  `from→edge_type→to` mapearia errado. Hoje 1.979/1.979 arestas do corpus estão na ordem canônica,
  então é dívida e não bug — mas o helper é menos robusto que o motor que acompanha.
- **proveniência dos 2 nós criados**: `verified_against` promete uma re-medição que o `trace:` não
  contém (aponta para a SYNTHESIS). Quem segue o trace não acha o que o campo promete.
