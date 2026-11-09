---
branch: fix/sync-main-writable-and-spool-import
date: 2026-11-09
reviewed_diff_sha256: pendente
findings_total: 4
findings_real: 2
tokens: 0
duration_min: 20
findings_fixed: 2
verdict: FIXED
elenxo: false
elenxo_isolado: false
reviewer: "Passada adversarial do próprio agente de execução; não houve refutador independente, e o brief proibia criar agentes."
nota: "tokens = 0: não medido. elenxo: false porque a re-refutação cabe à sessão que encomendou. O que sustenta são a bancada das 3 famílias tocadas (32 casos, 5 mutantes novos) e o dogfood com bind em leitura real no bwrap 0.9.0."
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

## O que continua descoberto

- Sessão ociosa e turno longo não disparam UserPromptSubmit, e subagente não o recebe: o sinal segue no spool até o
  próximo prompt. Cobrir exige a campainha importar no tick dela, no repo `onion-messaging`, fora deste PR.
- O adotante só ganha o modo `prompt` depois de um update que traga o settings novo.
- A falha no meio ainda pode ocorrer se o alvo perder a escrita depois da sonda, ou num bind de escrita em que só o
  unlink falha. Nesse caso o script mede e avisa ÁRVORE PARCIAL, e não desfaz.
