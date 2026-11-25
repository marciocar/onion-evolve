# Delphi second-brain-order-1125 — esqueleto do selo

**Pergunta:** Second Brain (SAC-562): o maestro selou C (começar pela central de decisão do company-brain) e depois B (vertical irmã federada), usando o aprendizado de A (ADR-003, app no celular). Qual é a ORDEM de construção e de certificação das jornadas fim a fim, progressiva, que fecha primeiro o que está pela metade? Para cada passo: o que entra, o critério de pronto medível (jornada certificada) e o que destrava o seguinte.
**Participantes:** company-brain, onion-slm, onion-curation, brain-granaai
**Rodada 3:** 4 aceita(m) (company-brain, onion-slm, onion-curation, brain-granaai) · 0 objeta(m) (ninguém)

## Síntese (proposta do condutor, levada à rodada 3)

SÍNTESE PROPOSTA (Delphi second-brain-order-1125, após 2 rodadas) — Lean com a lente do Onion: fazer funcionar a menor fatia, medir, melhorar.

MVP 0 — hoje, zero construção: o maestro sela 1–3 decisões REAIS da fila que a batuta já mede, pelo /meta:decide, e o selo cai no grafo. Mede: o laço fecha? passos fora do trilho (atrito)? tempo do surgimento ao selo.

MVP 1 — 5 dias, um usuário (o maestro), uma fila única alimentada por três fontes que já existem:
  (i) o bloco pessoal do relatório diário do hub (Fazer · Responder · Esperando);
  (ii) os itens que a batuta e o /meta:decide já trazem;
  (iii) 3 a 5 itens capturados no celular: o classificador que já roda lá propõe o tipo, o maestro confirma, e só sai um resumo que ele mesmo escreve (Wizard-of-Oz declarado).
  Decide pelas superfícies que já existem (aviso sem conteúdo no Slack de teste + lista do dia; formulário do decide); o selo volta à origem (grafo; linha no celular).
  Mede: uso diário (abre a central em ≥3 de 5 dias); % de itens com ação em 24 h (≥50%); tempo item→selo; atrito; itens perdidos e falsos; bytes que saem do celular = só o resumo.

Incremento 1 (só se o MVP 1 bater: uso ≥3/5 e ação ≥50%): responder no Second Brain sela no Company Brain («a pedido de», com trilha); link que expira de verdade (servidor da vps-ops); 2ª pessoa (conta de teste) com sonda negativa de que um não vê a fila do outro. Se o uso for baixo: trocar o formato/gatilho do hábito antes de construir mais.

Incremento 2 (se o 1 funcionar sem retrabalho): de-identificação automática no celular medida contra a manual da semana (os resumos viram o 1º gabarito de PII em pt-BR); publicação autoral de uma nota do lado pessoal para a empresa por liberação; depois o pull «minha fila» e o app nativo.

Depois: B (vertical irmã federada) com o que A e o MVP ensinaram.

Limites declarados (não pré-requisitos): N=1 e autor do produto (viés); só dado do maestro (sem dado de terceiro → de-id/LGPD revistos na 2ª pessoa); celular em Termux, não app nativo; resumo de-identificado à mão; transporte por scp; uma semana não prova retenção; métricas de ação autodeclaradas; exige manter o ambiente de teste do Slack (decisão do maestro).

## Dissenso declarado

Nenhuma sessão objetou na rodada 3.

## Confiança por rodada

| participante | rodada 1 | rodada 2 | rodada 3 |
|---|---|---|---|
| company-brain | 0.6 | 0.7 | 0.75 |
| onion-slm | 0.6 | 0.65 | 0.75 |
| onion-curation | 0.6 | 0.7 | 0.75 |
| brain-granaai | 0.7 | 0.75 | 0.8 |

## Para o selo (kg-decide-seal.sh)

O nó da decisão nasce `open` com a síntese no `label` (até 280 caracteres) e esta `narrative`, ANTES da pergunta ao
maestro; o selador mantém a narrative anterior verbatim e acrescenta a escolhida e as descartadas.

```yaml
narrative: "Delphi second-brain-order-1125 em 3 rodadas (posições independentes, crítica cruzada sem autor, convergência), participantes company-brain, onion-slm, onion-curation, brain-granaai. Rodada 3: aceitaram company-brain, onion-slm, onion-curation, brain-granaai; sem objeção. Confiança na rodada 3: company-brain 0.75, onion-slm 0.75, onion-curation 0.75, brain-granaai 0.8. Dissenso: nenhum declarado na rodada 3."
```
