---
branch: fix/sync-main-writable-and-spool-import
date: 2026-11-09
reviewed_diff_sha256: pendente
findings_total: 11
findings_real: 9
tokens: 0
duration_min: 45
findings_fixed: 9
verdict: REJECTED_AND_FIXED
elenxo: false
elenxo_isolado: false
reviewer: "1ª passada: o próprio agente de execução. 2ª passada: refutador independente, que reprovou o head 76d0bbdf5 com 2 bloqueios e 5 ressalvas. As curas deste head são do agente de execução."
nota: "tokens = 0: não medido. elenxo: false porque a re-refutação do head curado cabe à sessão que encomendou. O que sustenta são a bancada das 3 famílias tocadas (51 casos, 14 mutantes novos) e o dogfood com bind em leitura real no bwrap 0.9.0."
---

# Resíduo: o sync da main não quebra mais no meio, e o spool entra na sessão aberta

Passada feita por quem escreveu, rodando o artefato como o `pr-merge-verified.sh` e o settings o chamam.

## O que foi medido

- Reproduzi o defeito em fixture, com `bwrap --ro-bind` no arquivo: `error: unable to unlink old 'f': Device or
  resource busy`, rc 1, HEAD parado e os 3 outros alvos já na versão nova. O `git merge` seguinte recusa.
- Com o script novo no mesmo arranjo, `.claude/.onion-version` em bind de leitura: aviso que nomeia o alvo, rc 0, HEAD
  parado, `git status --porcelain` vazio. Fora do sandbox, a mesma fixture avança.
- Custo do modo `prompt` com o spool vazio: 25 ms de parede, sem rede.
- A campainha (`onion-messaging/campainha/server.ts:131`) ignora nome começado por ponto, então a sonda do diretório
  não dispara aviso, e ela lê o `inbox/` por tick, então vê o sinal importado.

## Achados

1. **Bancada, curado.** O caso de silêncio rodava sobre o spool que o mutante anterior deixou cheio.
2. **Comentário, curado.** A troca de texto no `co-relay.sh` duplicou um trecho do cabeçalho.
3. **Limite declarado.** Arquivo 444 em diretório gravável: o git o trocaria, a sonda o barra. É pulo com aviso, nunca
   árvore parcial.
4. **Limite declarado.** O caso do bwrap não está na bancada: o CI roda com `ONION_SELFTEST_STRICT=1`, skip vira falha,
   e o runner não garante bwrap. A bancada cobre o portão por chmod, e o bind real ficou no dogfood acima.

## Reprovação do refutador no head 76d0bbdf5, curada

Bloqueios:

5. `spool-import.sh`: link simbólico `x.md` passava pelo `[ -f ]`, e o `cp` punha o conteúdo do alvo no `inbox/`. Agora fica no spool e conta como retido (Q1).
6. `sync-main-worktree.sh`: `index.lock` de outro processo fazia o ff-only falhar, e os arquivos que o outro escreveu viravam `ÁRVORE PARCIAL` com `reset --hard` na mensagem. Agora index.lock presente ou HEAD que andou dão aviso de concorrência, e só conta como parcial o arquivo na versão nova com o índice ainda na antiga (j, k, l).

Ressalvas:

7. Teto de 100 sinais por chamada com `--hook`. Com 3000 sinais a chamada levou 1,9 s e saiu `imported=100 pending=2900`, contra rc 124 antes (Q2).
8. O temporário nasce com ponto na frente no `inbox/`, e a passada seguinte varre o de processo morto (Q3).
9. Posse por rename no spool antes da cópia: versão nova que chega durante a cópia fica no nome original (Q4), e posse de processo morto volta ao nome original (Q3).
10. Sinal ilegível, link ou homônimo commitado: o modo `prompt` avisa 📮 uma vez por sessão e contagem (Q5).
11. Depois de um parcial real, o sync seguinte diz `ÁRVORE PARCIAL DE ANTES` e não tenta o merge (h2).

## O que continua descoberto

- Sessão ociosa e turno longo não disparam UserPromptSubmit, e subagente não o recebe: o sinal segue no spool até o
  próximo prompt. Cobrir exige a campainha importar no tick dela, no repo `onion-messaging`, fora deste PR.
- O adotante só ganha o modo `prompt` depois de um update que traga o settings novo.
- A falha no meio ainda pode ocorrer se o alvo perder a escrita depois da sonda, ou num bind de escrita em que só o
  unlink falha. Nesse caso o script mede e avisa ÁRVORE PARCIAL, e não desfaz.
- Se um processo alheio segura o `index.lock` na hora em que um parcial real é medido (um `git status` que atualiza o
  índice, por exemplo), o aviso diz concorrência. O sync seguinte reconhece o rastro e diz que há parcial.
- O `reset --hard` do aviso de parcial supõe quem lê: o rastro prova que o ff-only não terminou, e a frase condiciona a
  não haver mudança local a guardar.
