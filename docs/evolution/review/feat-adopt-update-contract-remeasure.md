---
branch: feat/adopt-update-contract-remeasure
date: 2026-10-20
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 6
findings_fixed: 5
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente refutador (só leitura, 60 chamadas, sandboxes próprios e a cópia pré-migração do hub)
---

# Passada adversarial: `feat/adopt-update-contract-remeasure`

## O que muda

A fase 1 de D_U1_CAMADA_SDAAL_NO_UPDATE e o corte de D_U1_MIGRADOR_NO_KG_SSOT:

- `remeasure-contract.sh` mede o contrato KG-SSOT do alvo, com o vendor do próprio alvo, e relata sem bloquear (rc 0, 1, 3 ou 4).
- O `adopt.md` cola essa saída no relatório do `--update`.
- O `offer-onion-ci.sh` deixa de chamar de verde um corpus que reprova.
- O `kg-migrate-v3.py` sai da adoção. A REGRA 100 (Superfície que viaja não cita ops/ como se o destinatário o tivesse) ganhou o 3º vocabulário, o script core-only cortado.

## Achados

1. **REAL, curado (número errado no relatório).** A contagem "fora de nó" subtraía nós distintos do total de ocorrências. Um nó com dois códigos MUST aparecia como "1 ocorrência fora de nó", o que era falso. Agora as ocorrências fora de nó são contadas à parte. Ficaram o caso (i), com um nó órfão e sem provenance, e o mutante (i).
2. **REAL, curado (fail-open por rc).** Um traceback fora do `try` saía com rc 1, o mesmo código da dívida MUST. Um vendor com `where()` de 4-tupla inventava dívida num corpus que passa, e a oferta de CI imprimia "REPROVA ()". Agora:
   - o Python inteiro roda num `run()` envolvido por `except BaseException` que sai com rc 3;
   - a API usada é conferida pelo nome antes de medir.

   A bancada ganhou o caso (h) com três vendors (API de 4-tupla, leituras que discordam e vendor sem `where`) e três mutantes.
3. **REAL, curado (mensagem que engana).** Um vendor anterior (4.0.1, medido num adotante local) saía com "instale requirements.txt". Agora a mensagem é "o vendor do alvo é anterior ou incompatível (falta …) — o --update traz o atual", e só dependência ausente (`ModuleNotFoundError`) pede o `requirements.txt`.
4. **REAL, curado na prosa (afirmação errada).** O cabeçalho dizia "o corpus que o gate dele mediria", mas os excludes do kg-inbox arquivado são política do core. O cabeçalho agora diz isso, e a saída imprime a linha `corpus … excluídos: …`. Ler o `--exclude` do workflow de cada alvo fica fora deste PR: nenhum adotante local tem grafo arquivado, então não há divergência medida.
5. **REAL, curado (mutantes faltando).** Entraram mutantes para o `-B` (f), para a checagem de concordância `seen != gate_must` (h), para a contagem por nó (i) e para a conferência da API (h). O caso (f) passou a rodar dentro do veredito, com `git status --ignored`.
6. **REAL, curado (robustez da guarda).** Duas falhas no 3º vocabulário da REGRA 100:
   - o fallback do vocabulário sobrescrevia a lista de scripts mesmo quando o manifesto respondia;
   - só o `.` era escapado na regex.

   Agora o fallback dos scripts só vale quando o manifesto não respondeu nada, todo metacaractere de ERE vira classe de um caractere, e nome com `[ ] ^ \` fica de fora com AVISO.
7. **NOTA, não curado (teto declarado).** O 3º vocabulário não vê o nome sem extensão (`kg-migrate-v3 --locality`) nem a forma de módulo (`kg_migrate_v3`). O grep nas raízes que viajam dá zero ocorrências das duas formas. A derivação shell do vocabulário não tem mutante próprio: a cópia mutante roda sem o `vendor-manifest.sh` irmão e cai no fallback. Ela é coberta pelo caso (xxiii) do selftest real.
8. **NOTA, curado.** `NÃO MEDIDO` sai no stderr, e o `adopt.md` passou a mandar colar com `2>&1`. Python ausente agora dá rc 3 em vez de 127. Array vazio sob `set -u` (o bash 3.2 do macOS) usa `${EXTRA[@]+…}`.
9. **NOTA, honesto como está.** Um alvo que é subdiretório de outro repo, com grafos não rastreados, sai com rc 4 "nenhum .kg.yaml rastreado". A frase diz "rastreado", então não engana.

## O que o refutador tentou e não derrubou

- **Números contra o gate do alvo:**
  - cópia do hub: 25, 1 e 24, com 1.024 nós (vendor 4.9.1);
  - core: 178, 162 e 16, idêntico ao `kg_gate.py` com os mesmos `--exclude`.
- **Escrita no alvo:** zero (sem `__pycache__`, `git status --ignored` vazio).
- **REGRA 100 no corpus real:** HARD 0. Não sobrou `kg-migrate-v3.py` sem declaração nas raízes que viajam.
- **`adopt.md`:** juntar linhas para caber nas 800 não quebrou a bancada `adopt_robust`.

## Dogfood

- O hub (só leitura) passa nos dois pontos medidos: 26 grafos, 26 passam (HEAD 66a06c59bdd9, vendor 4.11.0; e 8b3451bfeb9c, vendor 4.12.0).
- O commit 606d6941b, anterior à migração e copiado por `git archive`, dá 24 de 25 grafos reprovando: 1.024 nós no MUST `form.required.node.provenance`. A dívida SHOULD é 82, 52, 2 e 24. Bate número a número com o sinal do hub.
- A oferta de CI nessa cópia dizia "lint do alvo VERDE" antes e agora diz "contrato do corpus REPROVA no MUST (1024 nó(s) em 24 grafo(s))".
