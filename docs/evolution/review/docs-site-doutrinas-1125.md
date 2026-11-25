---
branch: docs/site-doutrinas-1125
pr: 1769
date: 2026-11-25
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 9
findings_blocking: 2
tokens: 0
duration_min: 55
findings_fixed: 7
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: site-doctrines-reviewer (sonnet, isolado)
nota: "tokens não medido. 1ª passada do autor (3 achados) + rodada isolada do site-doctrines-reviewer (FIXES_NEEDED, 6 achados, todos curados nas duas línguas)."
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

## Rodada isolada: site-doctrines-reviewer (sonnet, isolado) — FIXES_NEEDED

Revisor isolado, sem o raciocínio do autor. Seis achados reais, todos curados em pt e en:

4. **(real, BLOQUEANTE, curado)** Card 12 citava «1.568 turnos / 33,6% / 0,9%» sem fonte, e os números
   não batiam com a fonte. Curado com os números do nó `E_MEDIDA_TAXA_DE_BLOQUEIO_EM_TURNOS_REAIS`
   (`docs/evolution/research/guard-house-code-gloss-2026-10/house-code-gloss-2026-10.kg.yaml`), citado no
   card: 1.556 turnos, 36,4% com sigla sem glosa, 2,3% barrando toda sigla de opacidade alta, 0,3% barrando
   só a reincidência; o 0,9% aparece como a 1ª medida, derrubada pelo refutador.
5. **(real, curado)** Card 8: «a sessão contornou e seguiu» não tinha sustentação. Reescrito fiel à KB
   `keep-current-doctrine.md`: «construindo sobre versões velhas» e a fala «é só pedir autorização para mim
   e instalar». As aspas da 2ª fala viraram verbatim («este aviso anterior… memoria e sessão»).
6. **(real, curado)** Card 12: a síntese dizia que a régua não vale onde só a máquina lê. A KB
   `plain-language-by-surface.md` (seção «Por que o tráfego de máquina fica de fora») mantém duas exceções:
   C1 (glosa de sigla) na mensagem entre sessões e U1 (data de revisita) no grafo e no sinal. Acrescentadas.
7. **(real, curado)** Card 11: a inferência «o erro era meu» saiu (ela vinha da cura do achado 1, que
   passou do ponto). A cicatriz agora diz «numa colheita de 20 dias nas sessões do core» e «parte pode
   descer de classe com segurança, parte nunca pode», como `decision-ratchet-doctrine.md`.
8. **(real, curado)** Cards 9 e 10 (e 8 e 12, conferidos junto): aspas só em citação verbatim. Card 9:
   «melhor opção do mercado» (era «o melhor do mercado»), a 2ª fala do maestro é a da KB
   `no-external-service-dependency.md`, e o «via» e o molde «ponte opcional…» viraram paráfrase sem aspas.
   Card 10: a fala verbatim de `baton-doctrine.md`. Card 12: a fala verbatim do grafo da guarda. Em en, as
   falas são traduções declaradas («translated from Portuguese»).
9. **(real, LIMITE, curado)** Linguagem Simples: jargão explicado ou trocado nos cards 8 a 12 (pinada →
   fixada; gancho → gatilho automático; worktree → cópia de trabalho; forge → GitHub; mutantes → testes de
   mutação, explicados; lint → verificação automática de regras; SDK → kit de agentes do Claude) e frases
   longas partidas.

## Mutantes

Não se aplica: mudança só de conteúdo do site, sem guarda nova. Prova: `npm run build` rc 0 depois das curas,
12 `dcard` em `dist/doutrinas/` e `dist/en/doutrinas/`, nenhum aviso `nota-drift`.

## Limites declarados

- O revisor isolado foi o site-doctrines-reviewer; a 1ª passada foi do autor.
- Itens 2 e 3 acima.
- Deploy não feito: é do maestro.
