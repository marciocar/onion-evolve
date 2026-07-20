---
title: 'Drive-to-verify tem um segundo eixo faltando: verificado ≠ neutro (interesse da fonte)'
date: 2026-07-20
from: granaai (consumidor)
to: onion-evolve (core)
type: sinal-de-campo
flow: upstream (consumidor→core)
about: knowledge-graph-sdaal.md — drive-to-verify e proveniência de evidência externa
source_commit: 91d5dbb05a6d
---

# Sinal: o drive-to-verify confirma o conteúdo, não a construção da evidência

## A lacuna

A doutrina manda cruzar claim com o vivo antes de confiar — e isso funciona muito bem para
artefato **nosso**: código, schema, commit, dump. O eixo é *"o que está lá bate com o que
afirmamos?"*.

Quando a evidência vem de **terceiro**, falta um segundo eixo: *"quem produziu este documento ganha
o quê com o que ele diz?"*. Um documento pode ser autêntico, íntegro, correto nos próprios termos —
e ainda assim **calibrado** por quem tem interesse no resultado.

Verificar que o documento existe e diz X não é o mesmo que ler como X foi construído.

## O caso

Auditamos a documentação de compliance para uma due diligence e recebemos o relatório técnico de
um pentest. Reportei ao maestro: **27 achados, 2 críticos, 17 altos, nível de segurança 60/100**.
Verifiquei que os números estavam no documento. Estavam.

O maestro devolveu: *"a função de um pentest é apontar e alarmar; existe supervalorização para
vender a segunda etapa — é como ler a bula de uma aspirina"*.

Fui checar a **estrutura** dos achados, coisa que eu não tinha feito:

- **10 dos 27** são a mesma classe (rate-limit, CWE-799) replicada por host e endpoint — e **as
  duas críticas pertencem a ela**;
- mais **5** são política de senha fraca repetida em 5 formulários;
- ou seja **15 de 27 são duas questões contadas por superfície**;
- CVSS **9.4** atribuído a rate-limit em login — faixa normalmente reservada a RCE ou bypass de
  autenticação;
- e a seção de conclusão pontua 60/100 hoje, 70/100 após correções e **85/100 "após novo teste de
  80h"** — o incentivo comercial está **impresso no próprio documento**.

Simetricamente, eu havia subvalorizado o que o mesmo documento **concede contra o próprio
interesse**: robustez confirmada contra XSS, SQLi, NoSQLi e contra falhas de autorização entre
tenants, e nenhum achado explorável sem autenticação prévia.

## O princípio

**Declaração contra o próprio interesse é a evidência de maior confiança.** O auditor não ganha
nada dizendo que a aplicação resistiu a SQLi e a acesso cross-tenant — por isso essa afirmação vale
mais que a nota de severidade, que ele tem interesse em elevar.

O erro oposto é tão ruim quanto: **descartar evidência porque a fonte tem interesse**. No mesmo
relatório, 7 achados de autorização eram distintos entre si e de lógica de negócio — esses não se
relativizam. Interesse da fonte **qualifica** a leitura; não a anula.

## Pedido

1. **Doutrina**: acrescentar ao drive-to-verify o segundo eixo — ao ingerir evidência de terceiro,
   registrar o interesse da fonte e ler a *estrutura* do documento (concentração de achados,
   afirmações que beneficiam quem o emitiu, incentivos declarados no próprio texto).
2. **Schema (proposta, não implementação)**: hoje um nó carrega `trace`, `verified_at` e
   `confidence`, mas nada distingue *"a fonte afirma isso e lucra com isso"* de *"a fonte concede
   isso contra o próprio interesse"*. A segunda deveria carregar confiança maior **por
   construção**, não por julgamento caso a caso.
3. **Onde dói mais**: comandos que ingerem material externo — `/meta:kg` ao modelar evidência de
   terceiro, `/deep-research` ao citar fonte com interesse comercial, e a vertical de compliance
   ao montar pacote de auditoria.

Relacionado ao sinal `2026-07-20-gate-proveniencia-invertido.md`, do mesmo dia: lá o buraco era
conhecimento nascendo fora do SSOT; aqui é conhecimento entrando no SSOT **sem leitura de quem o
produziu**. São as duas pontas do mesmo laço.

Vale notar como o achado apareceu: **não foi gate, foi ceticismo humano**. O maestro leu o número
que eu reportei e perguntou pelo incentivo. Nenhum mecanismo nosso faria essa pergunta — e é
exatamente por isso que ela merece virar doutrina.
