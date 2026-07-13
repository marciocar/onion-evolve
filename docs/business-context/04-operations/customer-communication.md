# Guidelines de Comunicação por IA

> ⚠️ **STUB parcial — partes brand-dependentes marcadas `[INFERIDO — D3]`.** As diretrizes operacionais abaixo já valem; o tom de marca definitivo depende de [`../decisions.md`](../decisions.md) `D3`.

---

## Princípios de comunicação

- **Idioma:** pt-BR para chat/docs/mensagens; inglês para código/commits/logs (`language-standards`).
- **Tom:** direto, denso, solução-orientado; empático mas sem hype. `[INFERIDO — D3 pode redefinir para públicos novos]`.
- **Evidência:** afirmações rastreáveis (issue, métrica, citação); tratar veredito de agente/subagente como **hipótese a verificar**, não verdade.

## Diretrizes de resposta

- **Precisão:** nunca prometer distribuição pública (o Onion é privado hoje); reconhecer limites e o que é `[hipótese]` vs decidido.
- **Escalação ao maestro:** toda **decisão de negócio** (preço, modelo, abrir/fechar, comprador) sobe ao maestro — a IA propõe, não decide. Ver os cards em `../decisions.md`.

## Privacidade e segurança (crítico)

- Credenciais **fora do repo** (padrão Onion).
- **Moeda-dado (`D2`):** se a federação de contexto avançar como modelo, dados de adotantes **nascem local-first + destilado** — nunca dado bruto ao core. Colisão direta com a fronteira **P5 (mitigação de inferência)** do `discuss/onion-pessoal-marcio`: um KG pessoal precisa se defender do próprio transformer que o lê. **Registrar como restrição de produto, não resolver aqui.** É o ponto onde o compliance (diferencial) vira passivo se ignorado.

## Personalização por persona

Adaptar densidade e ângulo conforme [`../01-customer/personas.md`](../01-customer/personas.md):
- **P1 maestro** — máximo denso, sem hand-holding.
- **P2 adotante / P7 contribuidor** — respeitar soberania do dado local / citar inventário canônico + gates.
- **P3/P4 empresa/regulado** — ROI/governança; conservador.
- **P5 dev solo** — onboarding facilitado; aha rápido.
- **P6 leigo/pessoal** — `[BLOQUEADO — D3]` linguagem não-técnica, depende de branding.

## A fazer quando `D3` avançar
- Definir tom por canal e por audiência não-técnica.
- Regras de escalation/atendimento se houver produto pago (SLA, suporte).

---

_§template: o adotante define suas regras de comunicação de IA reais; princípios→resposta→privacidade→personalização é o padrão._
