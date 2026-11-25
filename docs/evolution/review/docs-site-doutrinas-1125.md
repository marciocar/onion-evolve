---
branch: docs/site-doutrinas-1125
pr: pendente
date: 2026-11-25
reviewed_diff_sha256: pendente
findings_total: 3
findings_real: 3
findings_blocking: 1
tokens: 0
duration_min: 25
findings_fixed: 1
verdict: FIXED
elenxo: false
elenxo_isolado: false
reviewer: autor (passada própria, sem subagente por ordem da sessão principal)
nota: "tokens não medido. Sem refutador isolado: a sessão principal vetou subagentes nesta tarefa."
---

# Passada adversarial: `docs/site-doutrinas-1125`

## O que muda

A página `/doutrinas/` (pt-BR e en) passa de 7 para 12 doutrinas. Entram cinco nascidas depois da
reforma do site (agosto): Base atual, sempre (2026-10-16); Sem dependência de serviço externo
(2026-10-27); A batuta (2026-11-10); A catraca de decisões (2026-11-21); Linguagem Simples (2026-10-17 e
2026-11-20). Cada card segue o contrato editorial da página: frase-síntese, cicatriz datada, mecanismo e
limite declarado. A home troca "7 doutrinas" por "12". O fecho ganha a catraca na lista do que ficou à
mostra.

Medição de partida: o site no ar era igual à fonte do main (7 cards, 17 invenções, status revistos em
2026-11-08). A tabela de invenções segue com as 17 linhas da §1.5 da KB de identidade e não foi tocada.

## Achados

1. **(real, BLOQUEANTE, curado)** O herói diz que cada doutrina "nasceu de um erro meu", e a primeira
   redação da cicatriz da catraca descrevia só a carga do maestro, sem o erro do framework. Curado nas duas
   línguas: a cicatriz nomeia o erro (levar ao maestro, sem régua, decisões que podiam ser do framework).
2. **(real, LIMITE)** O `astro` do lockfile é 5.18.2 e o publicado é 7.4.13 (duas majors). Nomeado e não
   subido aqui: é migração de major de um site cujo deploy é ato do maestro, fora do escopo de um PR de
   conteúdo.
3. **(real, LIMITE)** Ficaram de fora como card as doutrinas operacionais sem cicatriz pública própria ou
   já cobertas: um escritor por repo (citado no limite da batuta), Modernização, Abstração e o catálogo de
   ferramentas da VPS (as duas primeiras já estão na tabela de invenções; a última é interna da máquina).

## Mutantes

Não se aplica: mudança só de conteúdo do site, sem guarda nova. Prova: `npm ci && npm run build` rc 0,
12 `dcard` em `dist/doutrinas/` e `dist/en/doutrinas/`, nenhum aviso `nota-drift`.

## Limites declarados

- Sem refutador isolado (ordem da sessão principal): `elenxo_isolado: false`.
- Itens 2 e 3 acima.
- Deploy não feito: é do maestro.
