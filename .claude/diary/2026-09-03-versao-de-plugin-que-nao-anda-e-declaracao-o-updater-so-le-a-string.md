---
date: 2026-09-03
instance: onion-evolve
type: learning
classification: public
tags: [plugins, marketplace, versao, behavior-over-declaration, mecanismo]
affects: [meta, engineering]
breadcrumb_for: []
share_with: []
next_recommended: "na outra sessão: `claude plugin marketplace update onion-evolve && claude plugin update <plugin>` volta a funcionar; uninstall+install deixa de ser necessário"
review_after: 2026-12-02
conflict_class: static
---

## Signal
Sinal de campo do maestro (sessão no repo pessoal): `claude plugin update` respondeu "already at the latest version (0.1.0)"
para os 6 plugins do core enquanto o cache de 08/07 divergia do repo em **89 arquivos**. O updater compara a STRING de
versão, nunca o conteúdo — e os 8 manifestos das verticais estavam parados em `0.1.0` desde o nascimento.

## Evidence
- O assembler já calculava `tree_sha` do conteúdo (provenance.json, padrão gh skill) — sabia que o conteúdo mudou e
  publicava a mesma versão: declaração ≠ comportamento, no lugar exato onde o consumidor decide atualizar.
- Cura de mecanismo, não de disciplina ("bump quando lembrar" reincide): `version = <major.minor>.<N>`, N = commits que
  tocaram as fontes canônicas do plugin (+1 com mudança pendente no índice, para pre-commit e CI concordarem). Monotônica,
  semver-válida, anda exatamente quando o conteúdo anda; a REGRA 19 (drift plugins vs fonte) já regenera no pre-commit.
- Bancada `plugin_version_derived` (4 casos): mesma fonte ⇒ mesma versão; índice sujo = pós-commit; commit alheio não anda;
  `ONION_PLUGIN_VERSION_DERIVED=0` mantém o manifesto (legado).

## Next crumb
A publicação human-gated do marketplace externo (`onion-plugins`) herda as versões derivadas; o `--update` do adotante e o
`plugin update` passam a enxergar mudança quando há mudança.
