---
title: "Revisão — forge: parseRepoIdentity com o namespace inteiro do GitLab; README do marketplace diz instalado ≠ habilitado"
date: 2026-09-04
branch: fix/forge-gitlab-namespace-marketplace-readme
reviewer: "condutor com dogfood EXECUTADO: família forge_detector extrai a regex do próprio detector.md e prova 5 URLs em node (2/2); a regex velha reprova o caso aninhado (modo de falha provado numa cópia)"
reviewed_diff_sha256: ff868611266ecfa99063de41fbe0378a76e41bbce7bf05da3054d0758c27e3f5
findings_total: 3
findings_real: 3
verdict: APROVADO
tokens: 60000
duration_min: 20
---

# Resíduo — REGRA 56 (PR aberto carrega RESÍDUO da passada adversarial)

Dois sinais de campo do mesmo dia: (1) o juiz da rodada 3 do E3 mediu que o `parseRepoIdentity` do forge SDAAL devolvia
`owner=subgroup` para `gitlab.com/group/subgroup/project` — o mesmo defeito que o Claude Code 2.1.260 corrigiu (l.39/l.40);
(2) a sessão do maestro no repo pessoal achou o plugin `onion@onion-plugins` instalado mas NÃO habilitado, sem `/warm-up` nem
`/catch-up` — nada dizia que o plugin `onion` é a entrada.

## Achados

1. **Regex extraída, não copiada**: a família `forge_detector` recorta o `remoteUrl.match(/…/)` do `detector.md` e o executa em node —
   se a spec mudar, a bancada testa a spec nova (lição *bancada espelha o artefato*). GitHub segue 1 nível; GitLab dá o namespace inteiro.
2. **Modo de falha provado**: com a regex velha, `group/subgroup/project` ⇒ `owner=subgroup` e o caso (b) reprova.
3. **README do marketplace** (gerado pelo materializador): o plugin `onion` traz a ENTRADA (`/onion:warm-up`, `/onion:catch-up`,
   `/onion:onion`); "instalado ≠ habilitado" com o comando de `enable` e reinício; "atualizar" com `marketplace update` +
   `plugin update` — que agora anda porque a versão é derivada (#787). Fio `I_FORGE_PARSE_GITLAB_SUBGRUPOS` selado.
