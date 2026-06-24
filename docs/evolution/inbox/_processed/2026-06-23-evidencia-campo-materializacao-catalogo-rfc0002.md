---
title: 'Evidência de campo p/ RFC-0002 (materialização do catálogo) + auto-relato de erro do operador'
date: 2026-06-23
from: rhilo-metagamify (adotante standalone / sala de obra)
to: onion-evolve (core / "mestre")
re: rfc-0002-meta-strategy-verdict — catálogo-first/recognition-primed ACEITO (doutrina), materialização DIFERIDA
type: federation-doc-bridge (sinal de campo + auto-relato de erro)
status: sinal para triagem (/meta:co-evolve); transporte manual pelo maestro
---

# Sinal ao core — a doutrina aceita não existe na ponta (e o operador reinventou-a mal)

> Doc-bridge derivado→core. Não é proposta nova (a doutrina já está aceita no RFC-0002). É **evidência de
> campo** de que a **materialização diferida** custa caro na operação real — com um auto-relato de erro do
> próprio agente operador como a evidência mais nítida.

## Auto-relato de erro do operador (pedido explícito do maestro)

Numa sessão-operação longa neste adotante, o agente operador (Claude Code):
1. **Não sabia que o RFC-0002 existia.** Quando o maestro levantou "o Onion precisa de estratégias por caso +
   orientar a tese adequada via wizard", o operador tratou como **ideia nova**, escreveu uma auditoria/proposta
   avulsa e **endossou** algo que **já é doutrina aceita** (catálogo-first / recognition-primed).
2. **Usou a fila errada.** Largou um `.md` em `docs/evolution/` do **adotante**, em vez de emitir **sinal no
   `inbox/` do core**. Não conhecia o protocolo (inbox + `/meta:co-evolve` + transporte do maestro).
3. Só descobriu o RFC-0002 e a fila **porque o maestro perguntou** "mandou pela fila correta?".

**Por que isso é o sinal, e não só um erro meu:** se a doutrina está **aceita no core mas invisível na ponta**,
mesmo um agente capaz **reinventa-a (pior) e erra o canal**. A materialização diferida = a doutrina não chega
ao **momento de ação**. Esse é exatamente o gap que o RFC-0002 deixou em aberto (materialização).

## Sinal de campo (o incidente que justifica materializar)

Sessão real, 2026-06-23, no `rhilo-metagamify` / RHILO em produção (`metagamify_hml`):
- **Dev+HML no MESMO ambiente:** o HML é prod-RHILO **e** homolog/dev do time. Tráfego de teste indistinguível
  do real; feature de dev (payload de snapshot 90KB) custosa em prod; container subdimensionado → dashboard 503 ~3h.
- **Frentes concorrentes sem fronteira:** implantar a "fila nova" (dose) **enquanto** se apagava incêndio da
  antiga (travas, 503). Operação + investigação + feature competindo na mesma janela/ambiente.
- **Estado de ambiente ambíguo:** `.env` ora sandbox ora prod; branches `main`(RHILO)/`rhilo/main`(MGFY)/`develop`;
  flags ligadas no banco vs default do código. Redescoberta constante de "em qual estado estou agindo".
- **3 ações em prod sobre SUPOSIÇÃO não-verificada** (todas revertidas, mas custaram idas-e-voltas): "cap diário
  vaza" (era artefato), "callsDailyCap=2 resolve" (vazou em prod apesar de teste unit 46/46), "trackSelectionContext
  gate o payload" (não gate). + um **fantasma de memória** (`auto-burst-control */5` que não existe no código).

São precisamente os **"casos comuns"** que um catálogo reconheceria: *firefight-em-prod-durante-dev*,
*ação-em-ambiente-compartilhado*, *verificar-antes-de-agir-em-prod*. Com a doutrina **materializada na ponta**,
o operador teria **reconhecido o caso** e aplicado o playbook (guardas de ambiente, split de frentes, "verificar
antes de escrever") em vez de improvisar.

## Pergunta de roteamento ao mestre (não reinventar — só decidir ONDE materializar)

1. A **materialização** do catálogo (situação→playbook + um **seletor/guarda acionável no momento de ação**)
   nasce no **core** (reusável por adotantes) ou é **engenharia local** de cada adotante?
2. Como torná-la **descobrível e acionável na ponta** — hook de sessão? skill (`/meta:strategize`)? guarda que
   **bloqueia** ação em prod sem declarar `{ambiente, branch, reversível?}`? (doutrina sem gate não impediu meus erros).
3. Vale o adotante registrar este caso como **novo blip** (quadrante Método) ou ele só **reforça** os blips #9/#10
   já existentes?

## NÃO feito (aguardando)
- **Não** materializei nada localmente — por desígnio, aguardo o veredito de roteamento do mestre.
- O doc avulso que eu havia criado no adotante (`docs/evolution/MENSAGEM-onion-evolve-...md`) foi **apagado**
  (lugar e formato errados; redundante com o RFC-0002).

> ⚠️ Resposta precisa ser explícita no `inbox/` (push core→derivado, transportada pelo humano) — o adotante é
> cego ao core. (Padrão em `_processed/2026-06-19-sinal-adocao-a0fdf35.md`.)

## Referências
- Report completo do incidente (no adotante): `docs/reports/2026-06-23-sessao-cap-incidentes-rhilo-dev-hml.md`.
- Memória do adotante: `project_dev_hml_simultaneidade_dificuldades`, `project_rhilo_502_and_incorrect_office_20260623`.
- RFC-0002 (este core): `docs/evolution/rfc/rfc-0002-meta-strategy-verdict.md` (materialização diferida) · blips #9/#10 do radar.
