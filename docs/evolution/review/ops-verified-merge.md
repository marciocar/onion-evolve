---
branch: ops/verified-merge
pr: 619
date: 2026-08-16
reviewed_diff_sha256: 1581377b6c30e69425cd0b8dd60b8a3407f1f60a3549189dae71874f3027dfa7
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 10
verdict: CONFORME
reviewer: passada por EXECUÇÃO do caminho de recusa (não leitura) — o modo de falha foi exercido e devolveu rc real 1
REVISOU: true
---

# Resíduo — `ops/verified-merge`

Artefato de 60 linhas que nasce de um defeito **meu**, cometido hoje, dentro de uma sessão
dedicada a curar essa exata classe.

## O defeito de origem

No PR #618 o `gh pr merge` falhou (`CONFLICTING`) e o meu `echo "MERGED 618"` imprimiu
sucesso **assim mesmo** — encadeado com `;`, não condicionado ao `rc`. O que impediu o
relato falso ao maestro foi eu ter reparado, de passagem, numa frase do `gh` que só aparece
quando o merge não acontece. **Sinal fraco lido por acaso não é verificação** — é sorte com
aparência de método.

## Por que virou artefato e não correção pontual

Corrigir aquele script seria nota. O que reincide não é o script — é o **padrão de escrever o
cuidado à mão a cada sessão**. A casa já tem o registro dessa lição
(`nota-nao-e-mecanismo-o-waiter-provou`, 2026-08-03: identifiquei um bug, escrevi a cura no
plano, e reincidi duas vezes nas horas seguintes). Então o caminho do merge passa a ser um só.

## Achado da passada (o único, e é sobre a ordem das travas)

A trava que importa **não** é ler o veredito — é a **prova independente pelo estado**. Um
`gh pr merge` pode sair 0 e o PR não estar merged (auto-merge agendado, por exemplo). Por
isso a declaração final não vem do comando: vem de reler `state` + `mergedAt` na API e exigir
os dois. Sem essa quarta trava, o script seria uma versão mais elaborada do mesmo erro.

## Verificação por execução (não por leitura)

- **PR já mergeado (#617):** declara `MERGED` com o `mergedAt` real — idempotente, não mente
  nem no sentido oposto.
- **PR inexistente (#99999):** recusa com **rc real 1** e mensagem nomeando o que faltou.
  (O `rc` foi capturado sem pipe — a primeira leitura que fiz veio do `tail` e a guarda
  anti-fail-open acusou; a segunda é a válida.)

## Limite declarado

Não exercitei o caminho `gh pr merge` **retornando 0 com PR não-merged** — não tinha como
provocá-lo sem auto-merge armado. A trava existe por desenho e está comentada no script; a
prova fica pendente até aparecer o caso real. Registrado aqui para não ser confundido com
capacidade verificada.
