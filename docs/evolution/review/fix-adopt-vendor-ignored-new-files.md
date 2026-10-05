---
reviewed_diff_sha256: 97c652b9839efcd4a5fe5aadb9c14ba84d49684066544e8c28ec72b6bc317fb8
findings_total: 9
findings_real: 9
tokens: 139447
duration_min: 8
verdict: APROVADO
elenxo: sim
nota: >
  Elenxo opus em worktree isolada REPROVOU a 1a versão com dois blockers: nome acentuado no core
  derrubaria o update de todo adotante com rc=12 falso, e o rc=12 não tinha caso. Os nove achados
  foram curados ou declarados; os mutantes mordem, inclusive o M5 do refutador. A mesma classe estava
  latente na checagem de base cruzada e foi curada junto. APROVADO é o estado depois das curas.
---

# Resíduo — `fix/adopt-vendor-ignored-new-files`

Triagem do sinal de alta severidade do hub `brain-granaai` (2026-10-04): o `/meta:adopt --update`
perdia em silêncio todo arquivo NOVO do core quando o `.gitignore` da `onion/vendor` cobria `.claude/`.

## O que o refutador confirmou executando

- Adotante sintético do core real com `.claude/` ignorado: `main` perde 20 arquivos com rc=0; a cura
  entrega os 760.
- Clone do `onion-adopt-granaa-ai` (vendor com `.claude` ignorado): `main` deixa 59 arquivos de fora.
- Clones dos 21 adotantes com `onion/vendor`: **zero rc=12** com a cura (4 rc=10 de conflito real).
- `check-ignore` nos 26 adotantes: nenhum ignora de propósito um arquivo que o core transporta.

## O que ele derrubou, e o desfecho

| # | sev | achado | desfecho |
|---|---|---|---|
| 1 | blocker | `tar -t` escapa acento sob `LC_ALL=C` e `ls-tree` sem `-z` cita: rc=12 falso no 1º arquivo acentuado | curado — índice temporário do mesmo sha + `ls-files -z`; NUL ponta a ponta; casos (g3) e (e2) com acento |
| 2 | blocker | os `return 12` eram no-op sem reprovar nada | curado — caso (e3) faz o commit durável falhar de verdade e exige rc=12 com a integração intacta |
| 3 | rec. | 1 caminho ausente virava N no relatório | curado — ausente nomeado antes do add; (h) exige que só ele seja nomeado |
| 4 | rec. | duas arestas decorativas no grafo | curado — a do `index.md` foi para o grafo da pergunta dela (`CONSTRAINS`); a do ClickUp restringe a lacuna declarada pelo hub |
| 5a | opp. | `git archive HEAD` duas vezes | curado — sha resolvido uma vez |
| 5b | opp. | mensagem dizia `core@PIN` com conteúdo de HEAD | curado — cita o sha |
| 5c | opp. | justificativa errada no nó do teto da adoção inicial | curado — o ignore PARCIAL passa calado; gatilho renomeado |
| 5d | opp. | pathspec com colchete forçaria arquivo ignorado | curado — `--literal-pathspecs`; caso (g3) |
| + | — | a MESMA classe latente na base cruzada (`diff --name-only` com quotePath) | curado — achado pelo caso (e2) acentuado |

## Os `confirmed` dos grafos que este PR edita

- `E_UPDATE_PERDIA_ARQUIVO_NOVO_IGNORADO` e `E_SO_O_HUB_FOI_AFETADO` (impacto 5 e 4) — nasceram aqui.
- `E_TRIAGEM_DECLAROU_ENDERECADO_SEM_LER_O_SINAL_INTEIRO` (grafo `inbox-triage-2026-10`) — intocado; a
  triagem desta vez leu os dois sinais inteiros antes do veredito.

## O que não foi verificado

O `/meta:adopt --update` ponta a ponta (regen de baselines e reconfiguração), symlinks e submódulos,
e a adoção inicial (Fase 5), que segue sem a lista — teto declarado com gatilho.
