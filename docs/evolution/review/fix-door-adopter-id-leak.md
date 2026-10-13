---
branch: fix/door-adopter-id-leak
date: 2026-10-13
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 15
verdict: REPROVADO_E_CURADO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida. Gate mecânico: varredura dos ids onion-* do members.yaml nas raízes que viajam, bash -n e node --check nos arquivos tocados
---

# O id do repo privado do produto KG-SSOT sai da superfície que viaja

## O que aconteceu

O 2º ensaio de `/meta:publish --all` (fonte `91dcb25d`, depois do #1096) reprovou de novo standalone, core e
plugins no passo (5a): o id de adotante `onion-kg-ssot` (o repo PRIVADO de desenvolvimento do produto; o
espelho público tem outro nome) em 23 comentários de 11 arquivos que viajam, escritos em 2026-10-12 e
2026-10-13 ao registrar os sinais de campo desse adotante. A REGRA 36 (Superfície VENDORIZADA sem nome
comercial de cliente) do lint não o vê por desenho, porque deriva termos do registro e ignora o prefixo
`onion-` — o ponto cego medido duas vezes antes; só o motor de publicação o cobre.

## A cura

As 23 menções viram "adotante KG-SSOT" (KG-SSOT é o nome público do produto). Varredura de todos os ids
`onion-*` de adotante do `members.yaml` nas raízes que viajam: zero, salvo `onion-codex` (1), que é porte
público e que o motor não acusa.

## Passada adversarial

1. **Quebrou código?** Todas as ocorrências eram comentário ou texto de doc; `bash -n` e `node --check`
   nos arquivos tocados passam; nenhuma asserção da bancada procurava o id.
2. **Por que voltou a acontecer depois do #1096?** A classe é a mesma do caminho de máquina: o lint não
   tem a varredura do passo (5a) do motor, e quem escreve comentário de sinal de campo cita o id do
   adotante. Real, não curado aqui: pede uma guarda no lint que rode a varredura do (5a) sobre o diff do
   PR, para quebrar no PR e não na publicação (próximo item, registrado no resíduo e ao maestro).
