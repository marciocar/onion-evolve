---
branch: docs/site-refresh-2026-11
pr: pendente
date: 2026-11-08
reviewed_diff_sha256: pendente
findings_total: 7
findings_real: 7
tokens: 0
duration_min: 15
findings_fixed: 7
verdict: CORRIGIDO
elenxo: sim
reviewer: "1ª passada: o próprio agente de execução, com mandato de refutar; 2ª lente: o refutador independente da sessão do core (refuter-1533), que REPROVOU com 2 bloqueios + 1 erro"
nota: "tokens = 0: não medido (a passada foi do próprio agente, sem subagente medido pelo harness). A 1ª passada foi de uma lente só; a 2ª lente, independente, reprovou e os 3 achados dela foram curados na mesma branch."
---

# Passada adversarial: `docs/site-refresh-2026-11`

## O que muda

- Correções de TEXTO no fonte do onionevolve.com (`site/src/pages/`): home, `/estado/`, `/doutrinas/` (pt e en),
  `/maquinaria/` (pt e en), `/historia/` e `/historia/migalhas/provas/`. Sem mudança de design nem de componente.
- Os números novos são medidas de 2026-11-08, com os comandos no corpo do PR.

## Achados (contra o primeiro rascunho do próprio diff)

1. ERRADO: a nota nova do interlúdio da federação (`/historia/`) dizia que os sinais assinados entre
   repositórios existem "desde outubro". O canal vivo abriu em 10 de julho (o capítulo de julho da mesma página
   diz isso); outubro trouxe o convite por membro (CHANGELOG de co-evolução, entrada de 2026-10-15). Reescrito.
2. EXAGERA: "membros na rede A2A" lia como membros ativos no canal. O que se mediu é o registro: 6 membros
   não-fonte com bloco `a2a` e chaves no `members.yaml`. Rótulo trocado para "membros com chave A2A".
3. INCOMPLETO: a página de provas passou a mandar conferir o PR pelo número, mas parte dos cards cita commit, não
   PR. Acrescentado "ou o hash de cada commit". Conferido por amostra que os números batem com o repo do core
   (`gh pr view 292` e `394`: mergeados, 110 e 1 arquivos, iguais aos cards).
4. ERRADO: o rascunho dizia que o core "ficou público em outubro de 2026" em `/doutrinas/` (pt e en). A data da
   mudança não está medida (a memória registra a MEDIÇÃO de 2026-10-13, não o ato). Trocado por "é público hoje".

## O que foi conferido e se sustenta

- `exit 2`: a home mantém "barra inclusive sob `bypassPermissions`" (é o que segue barrando no core) e acrescenta o
  que `D_EXIT2_COUPLING_WORDING_2026_11` selou: camada de conformidade, não fronteira de segurança.
- Onion Mini: o repo público hoje é a porta gerada do core (README: Claude Code, cópia de `.claude/`, nove passos).
  A copy antiga (78 linhas, qualquer IA, AGENTS.md, web chat) descrevia o Mini anterior e saiu.
- Plugins: seis manifestos no core e seis plugins no `marketplace.json` publicado; as glosas de `onion-docs`,
  `onion-testing` e `onion-work-tools` (absorvidos em 2026-09) saíram e `onion-meta` ganhou a sua.
- Build: `npx astro build` verde, 10 páginas; a tabela de invenções não acusa drift (17 = 17 na KB §1.5).

## Varreduras

- REGRA 106 (Superfície que viaja passa pela varredura de vazamento da publicação), pelo mesmo
  `door-leak-scan.sh`, famílias `sub,word,home` com o registro e a lista de termos de clientes, sobre as linhas
  ACRESCENTADAS: rc 0. Sobre o `site/` inteiro: achados PRÉ-EXISTENTES (ids de adotante já publicados em
  `/historia/` e na home, e um caminho de máquina em `site/historia/migalhas/README.md`), nenhum vindo deste diff.
- REGRA 119 (O diff não acrescenta nome de repo ou de clone de adotante não federado): `private-name-check.sh`
  rc 0, sem achado.
- REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente): `site/` não é raiz vendorizada; a família `sub`
  da varredura acima cobre os termos de cliente nas linhas acrescentadas.

## Achados da 2ª lente (refutador independente), curados

5. BLOQUEIO: na home, «24 adotantes · 6 com chave A2A» lia como 6 de 24, mas só 4 ADOTANTES têm chave; os outros 2
   eram identidades de teste (kind method). Medido: membros `kind: adopter` com `a2a.keys` = 4. Corrigido no tile
   e no destaque da federação.
6. BLOQUEIO: no /estado/, «24 adotantes … todos chegaram por relação» inflava o número com peças do próprio autor.
   Separado em 16 de terceiros + 8 do próprio autor, com o critério escrito no PR (peças do próprio Onion e a empresa
   do autor, os dois membros com o mesmo remote). O «por relação» vale só para os 16.
7. ERRADO: a glosa do onion-meta dizia que ele «saiu» do marketplace. Ele ficou FORA por desenho quando o marketplace
   nasceu e ENTROU por decisão em outubro. Reescrito.

## Mutantes

- Nenhum: a mudança é texto. O teste que vale é o build e a varredura de vazamento, rodados acima.
