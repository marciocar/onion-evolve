---
branch: feat/gloss-reminder-peer-and-prereg
pr: pendente
date: 2026-10-26
reviewed_diff_sha256: pendente
findings_total: 8
findings_real: 3
tokens: 121024
duration_min: 9
findings_fixed: 7
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "subagente general-purpose, mandato REFUTAR com foco em falso positivo, 1 passada sobre 09ceda4f"
nota: "8 achados: 3 reais (falsos positivos), 4 de fronteira e 1 não-defeito (código morto). 7 curados no mesmo laço com caso no selftest e mutante; o 8º (cabeçalho seguido de parágrafo como definição) fica declarado em Limites."
---

# Passada adversarial: `feat/gloss-reminder-peer-and-prereg`

## O que muda

Reforço do maestro de 2026-10-26: nada de sigla opaca na prosa. O lembrete da glosa (o hook
`house-code-gloss.sh`) só lia a resposta ao maestro. Agora ele também lê dois lugares que o maestro lê
sem ser a resposta:

- a mensagem entre sessões (`SendMessage`, campo `message`), que a outra sessão repassa;
- os `.md` de pré-registro e resultado de estudo: basename em CAIXA ALTA sob `docs/evolution/dissect/`
  ou `docs/evolution/research/`, exceto README (STAGE0, SYNTHESIS, RESULT, N2-PLAN, CORE-STATE,
  PROTOCOL, ELENXO…), escritos por Write ou Edit.

É o modo `tool` do mesmo hook, no PreToolUse com matcher `SendMessage|Write|Edit`. Ele usa o mesmo
motor e o mesmo glossário, devolve `additionalContext` e sai 0 sempre: é lembrete, nunca bloqueio.
O defeito foi medido antes da forja: 548 de 2.502 mensagens reais e 56 de 69 desses `.md` levavam sigla
sem glosa. Também mudou: o id de tarefa sozinho no parêntese depois do assunto conta como glosa, a sigla
definida em linha de tabela conta como glosa, e o rótulo K<n> (critério ou mutante do pré-registro)
ganhou linha no glossário.

## Achados

| # | achado | classe | desfecho |
|---|---|---|---|
| 1 | `\| K1 \| o veredito … \|` numa STAGE0 recebia lembrete | real | curado: `_table_def` (caso t7, mutante M7) |
| 2 | "Kimi K3" num SYNTHESIS real recebia K3, com "critério" 140 linhas depois | real | curado: o domínio do K exige "critério K", "mutante K" ou "K1 a K4" (caso t8, M11) |
| 3 | Edit que troca só o número de uma tarefa glosada era acusado | real | curado: o Edit é julgado pelo resultado, e só se cobra a sigla do trecho novo (caso t9, M4) |
| 4 | "veja o que está em (SAC-256)" contava como glosa | fronteira | curado: o assunto precisa de palavra de conteúdo (caso t10, M8) |
| 5 | surrogate solto no destinatário dava Traceback no stderr | fronteira | curado: saída em bytes com `errors="replace"` (caso t11, M9) |
| 6 | JSON com barra ou letra escapada passava pelo filtro de shell | fronteira | curado: o filtro casa `SendMessage` e `evolution`, sem aspas nem barras |
| 7 | custo sem teto: Write de 5 MB levava 31 s | fronteira | curado: acima de 200 KB cala (caso t11, M10) |
| 8 | ramo MultiEdit era código morto (o matcher não o casa) | não-defeito | removido |

## Mutantes

Doze, plantados com `mutate-and-restore`; os doze mordem:

- M1 sem o ramo SendMessage: t1, t10 e t11 reprovam;
- M2 sem o assunto antes do parêntese: t2, t9 e t10;
- M3 README dentro da lista: t4;
- M4 Edit julgado pelo fragmento: t5 e t9;
- M5 filtro de shell sem SendMessage: t1, t10 e t11;
- M6 sem a linha K do glossário: t3 e t7;
- M7 sem a definição por tabela: t7;
- M8 sem o filtro de palavra vazia: t10;
- M9 print cru: t11 (Traceback);
- M10 sem o teto de bytes: t11;
- M11 domínio do K largo: t8;
- M12 matcher do settings sem SendMessage: o caso `(reg)` da família `house_code_gloss`.

## Limites declarados

- O PreToolUse que não barra deixa a ferramenta rodar. A mensagem sai como foi escrita, e o lembrete
  corrige a próxima escrita.
- Um cabeçalho (`### K2`) seguido do parágrafo que o define não conta como glosa. Fica como fronteira.
- Mensagem estruturada (objeto) e Bash que escreve `.md` não são lidos. Edit cujo `old_string` não está
  no arquivo é julgado só pelo trecho novo.
- A massa de opacidade baixa (Elenxo, ids de tarefa) entra no lembrete, como no modo prompt. Das 120
  mensagens mais recentes, 77 receberiam o lembrete, numa janela dominada por sessões de dissecação. Se o
  ruído treinar a sessão a ignorá-lo, o gatilho é medir de novo e cortar a opacidade baixa do modo tool.
- A glosa é julgada por forma, não por sentido. O teto vem do motor e está no grafo da forja.
