---
branch: chore/kg-ssot-4.37.0
pr: pendente
date: 2026-10-28
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
tokens: 71668
duration_min: 3
findings_fixed: 3
verdict: CORRIGIDO
elenxo: sim
reviewer: "subagente revisor novo (code-reviewer), só leitura, sem a conclusão da sessão de adoção, sobre o diff contra a origin/main fora do vendor"
nota: "o revisor leu o check_schemes do kg_trace.py do vendor como contrato, rodou o kg_trace check com e sem --with no core real e o --selftest do detector da REGRA 36; tokens e duração são os do subagente"
---

# Passada adversarial: `chore/kg-ssot-4.37.0`

## O que muda

A adoção da kg-ssot 4.37.0 (contrato v4.17, só SHOULD), saltando a 4.36.0. No core:

- o `kg-trace.sh --format tsv` traduz o `schemes` do `kg_trace check`: a falha sai `SCHEME-FALHA:<código>` com o nó,
  e a REGRA 55 (O `trace:` de um nó APONTA para alvo que EXISTE) a acusa HARD no core e SOFT no derivado; o skipped
  que é defeito de quem declara sai numa linha `SCHEME-AVISO`, SOFT, que não conta para o rc;
- a REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente), forma (A): `chave=valor&chave=valor` deixa de ser
  ampersand corporativo (2 HARD falsos medidos no adotante sge, nos fragmentos de PDF de duas fixtures da 4.37.0);
- a (f) do `plan_contract_migration` põe o python3 do PATH restrito por wrapper (o symlink perdia o venv);
- o nó `Q_MA_FREE_ORG_READ_ENFORCED` ganha `scheme: kg-node` e o `sha256` da fonte na curadoria;
- a identidade do contrato regravada no `.kg-ssot/gate/` (`kg_gate.py --update`).

## Achados (5 reais, 3 corrigidos, 2 declarados)

1. **O texto prometia julgar o unpinned, e no core ele não nasce** (média). O `kg-trace.sh` não passa `--with`, e no
   produto o `unpinned` só aparece com `--with`: a URL de outro repo cai em `absolute`, não julgada. Cura: o teto
   declarado no `kg-trace.sh` e no cabeçalho da REGRA 55, e a mensagem do aviso diz que o unpinned é o do `--with`.
   O `absolute` não vira aviso: todo nó que cita outro repo acusaria a cada lint, e aviso permanente treina a ignorar.
2. **O sha256 do nó novo não é protegido por guarda** (média). É o mesmo teto: a conferência é o
   `kg_trace check --with` apontando o clone da curadoria (1 julgado, 1 ok, 1 sha256) e o `peer-ref-check.sh`, ambos
   rc 0, rodados nesta adoção. Declarado, não curado: ligar o `--with` no lint depende do clone do par, que o CI não
   tem. A narrativa do nó segue citando o commit `2c8d3846` do nó espelhado, e o `source` usa `518b332b`, o commit
   pedido para o card; os dois resolvem.
3. **`missing_source` com sha256 declarado calava** (baixa). Cura: entra na linha de aviso; caso (s5).
4. **O (f0-MUT) mede o symlink ao lado, não reescreve o caso** (baixa). Declarado: ele aplica ao mesmo predicado do
   (f0) o PATH com o symlink de antes e mostra o `sys.prefix` do Python base; onde não há venv, pula visível.
5. **A regra do `=` dos dois lados se mantém viva por um caso só** (baixa). Cura: o comentário da família diz qual
   caso segura cada regra (os fragmentos de PDF, a dos dígitos; o `?lang=pt&mode=dark`, a do `=`).

## Não reais (testados pelo revisor)

- O rc do `kg-trace.sh` nos três caminhos (só aviso, aviso com rc 1 sem achado, achado).
- Falso negativo de nome comercial com `&`: `Acme&Co`, `Baker&Sons`, `Foo&Bar` e `name=Acme&Co` seguem acusando.
- A âncora do mutante (s-MUT) e o wrapper do python3 (`%q`, shebang absoluto).
