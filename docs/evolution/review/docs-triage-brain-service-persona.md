---
branch: docs/triage-brain-service-persona
pr: pendente
date: 2026-11-05
reviewed_diff_sha256: 788f7f89277776c13a1a9d5ee2905813990d3fc54ef9702371b07ab909935c14
reviewed_code_sha256: 2f6fbca1e89cf7ac704760d14b7c746c950de4cc3d8ccd476bdcdf76b4951146
findings_total: 2
findings_real: 1
tokens: 0
duration_min: 10
findings_fixed: 1
verdict: CORRIGIDO
elenxo: nao
reviewer: sessão principal do core (passada própria, não independente)
nota: "tokens 0 = não medido. Sem refutador separado: o diff é triagem de um sinal (registro), sem código nem regra nova, e as 5 vagas de agente estavam ocupadas pelas forjas de guarda. A passada é da própria sessão e se declara como tal."
---

# Passada adversarial: `docs/triage-brain-service-persona`

## O que muda

- O sinal `2026-11-05-proposal-brain-persona-servico.md` do hub entra tracked em `docs/evolution/inbox/_processed/`, porque já foi triado pelo maestro.
- O nó `D_MA_ARCH` ganha na narrativa o requisito da persona de serviço e um `trace:` para o sinal. Fica aberto: quem sela é o maestro. Não nasce nó novo, porque o grafo está no teto de 30 nós.

## Achados

1. **Real, curado:** o nome da branch nasceu com palavra em pt-BR e foi renomeado antes do push (o hook da guarda anti-fail-open acusou).
2. **Não real:** o sinal cita o id `brain-granaai`. É id de membro registrado em `members.yaml` e já aparece em sinais processados na main. Não é nome comercial novo nem dado do projeto. A varredura do diff por IP e hostname deu 0.

## Mutantes

Nenhum: o diff não tem código nem regra.

## Limites declarados

- A passada não é independente; ela vem da mesma sessão que fez a triagem.
- A conformidade do sinal à REGRA 113 (Sinal relayado a destino público só se commita revisado) foi lida à mão: o sinal declara trazer "só a forma" e não tem marca `reviewed_for_public: false`.
