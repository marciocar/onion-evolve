---
branch: feat/aside-routes-reforco-nota-1120
pr: pendente
date: 2026-11-20
reviewed_diff_sha256: pendente
findings_total: 9
findings_real: 9
findings_blocking: 0
tokens: 92944
duration_min: 11
findings_fixed: 8
verdict: FIXED
elenxo: false
elenxo_isolado: true
reviewer: "subagente code-reviewer isolado, sem a conclusão do autor, com mandato de refutar e rodar comandos (proibido criar card real)"
nota: "tokens = os do subagente revisor. elenxo: false porque não é o Elenxo de workflow; elenxo_isolado: true porque o revisor não escreveu o diff e não recebeu a conclusão. 0 bloqueantes, 6 ressalvas, 3 nits; 8 curados e 1 aceito (dívida: como prefixo vira dúvida, coerente com 0 usos da palavra própria)."
---

# Passada adversarial: `feat/aside-routes-reforco-nota-1120`

## O que muda

Decisão do maestro de 2026-11-20 sobre a revisão medida dos apartes (transcripts do core, 19/10 a 20/11):
- `reforço:` é reforço de ORDEM ou diretriz: aplicar já e, se durável, memória de feedback com a frase e a data.
- `nota:` vira card pelo `tm.sh item.create` no dono certo, com o número confirmado; sem `tm.sh` ou sem
  provider, `notes.md` declarado. `fyi:`/`avisa:` seguem aviso de sessão.
- Prefixo composto: até 3 rotas na ordem escrita, numa linha, sem efeito encadeado depois de `dúvida:`.
- `dpuvida:`/`dívida:` viram alias de `dúvida:`; `DÚVIDA:`/`REFORÇO:` roteiam em `LC_ALL=C`; sai `mandou bem,`.

## Achados e destino

1. RESSALVA — rótulos da bancada cortavam texto por caractere, que em C conta bytes: falha falsa em `LC_ALL=C`.
   Curado: ids ASCII. Medido: 28/28 em C e em C.UTF-8.
2. RESSALVA — a frase da nota entre aspas duplas executaria crase e `$( )`. Curado: heredoc de delimitador citado,
   contrato `b:sem-heredoc` com mutante.
3. RESSALVA — caminho sem aspas na rota. Curado: `%q`; a cópia da bancada vive num caminho com espaço e o mutante
   que tira o `%q` morre.
4. RESSALVA — `dúvida: nota: vira card?` mandava criar card. Curado: depois de dúvida, efeito não encadeia (casos
   e7/e8, mutante e7).
5. RESSALVA — `fyi:`/`avisa:` virariam card sem medição. Curado: chave própria de aviso de sessão (d8/d9).
6. RESSALVA — custo da família. Curado em parte: cada mutante roda só a sua seção; ~53 s com carga ~10.
7. NIT — mutantes vivos (teto 3, data da nota, `dpúvida`, `CDPATH`). Curado: e6 e `b:sem-data`; `dpúvida` saiu; o
   comentário do `CDPATH` agora diz o motivo real (diretório homônimo de outra raiz).
8. NIT — motivo casado por prefixo. Curado: casa com `=`.
9. NIT — `dívida: técnica…` roteia como dúvida. Aceito: 0 usos da palavra como prefixo no período.

## Bancada

Famílias isoladas: `aside_router_routes` 28/28 (em C e em C.UTF-8; 23 mutantes de motor e 2 de hook, todos mortos
pelo id certo); `aside_router` e `aside_router_hook` 9/9.
