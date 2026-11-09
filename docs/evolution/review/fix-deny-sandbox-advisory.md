---
branch: fix/deny-sandbox-advisory
pr: 1558
date: 2026-11-09
reviewed_diff_sha256: pendente
findings_total: 17
findings_real: 17
findings_blocking: 2
tokens: 0
duration_min: 0
findings_fixed: 15
verdict: FIXED
elenxo: true
reviewer: refutador independente chamado pela sessão do core, que reprovou o head c71e0600d e aprovou o c0e52ce50 com um último fecho curto, mais a passada do autor com bancada no binário real e bwrap real; o último fecho foi medido pelo autor, sem passada independente sobre ele
nota: "tokens e duração não medidos (0). As 74 regras não mudam; o defeito de origem foi medido pela curadoria em uso real."
---

# Passada adversarial: `fix/deny-sandbox-advisory`

## O que muda

Decisão do maestro de 2026-11-09, «Manter as 12 e avisar sandbox». Nenhuma regra sai do deny. Entram: o aviso de sandbox no
relatório do `--update` (`sandbox-deny-advice.sh`, que só avisa), o mecanismo de retirada (`deny-retired.tsv`, vazio por ora, com
leitor validado), e o `env-check.sh` distinguindo inexistente, ilegível (rc 4) e worktree sem `.env` (rc 5). A bancada ganha a
fase sob `bwrap` real com o leitor de verdade.

## Achados do autor

1. **A bancada do #1552 não via o defeito (curado, bloqueante).** Agora tem `gh` falso que lê o `hosts.yml` e git real com o helper,
   em três rodadas: sem deny, com deny (tem de quebrar) e com deny mais `allowRead` (volta).
2. **`env-check` cego em silêncio (curado).** Três respostas distintas, com mutantes.
3. **O aviso compara texto (declarado).** Não enxerga ferramenta própria do adotante que leia um caminho negado, nem remote que
   não seja `origin`, nem sandbox no settings do usuário. A regra aparece listada, sem dizer quem depende dela.

## Achados do refutador (head c71e0600d)

- **B, bloqueante (curado).** `env-check` decidia por `[ -r ]`, que mente sob sandbox. Agora abre o arquivo. Caso sob `bwrap` com
  regra de caminho absoluto: `test -r` responde legível, `cat` dá `Permission denied`, `env-check` responde `ilegivel` rc 4. Com
  `[ -r ]` de volta, a bancada reprova (responde `ausente` rc 0).
- **R1 (curado).** Casos para cada mutante sobrevivente; 23 mutantes de selftest mortos.
- **R2 (curado).** Hook de sessão diz ilegível e, em worktree, lê o `.env` do checkout principal.
- **R3 (curado).** Avisos de rc 4 e 5 no stderr; `--get` deixa o stdout vazio.
- **R4 (curado).** Subpasta de worktree olha o `.env` da raiz.
- **R5 (curado).** Saiu `ONION_DENY_RETIRED_FILE`; a bancada copia os scripts para uma pasta com a lista dela.
- **R6 (curado).** Leitor validado: linha malformada avisa e não retira, regra que a fonte ainda traz fica com aviso, lista ilegível
  não custa os hooks.
- **R7 (curado).** Remotes scp, alias e `git+ssh` viram ssh; `settings.local.json` conta; `allowRead` com home expandido cobre.
- **R8 (declarado).** `tm.sh` e o guarda usam `--env`, que já resolve o checkout principal, e não precisam do rc 5. Em `ilegivel` o guarda
  de API direta segue aberto: quem não sabe o provider não acusa, e sem o `.env` o token também não chega à sessão.

## Último fecho do refutador (head c0e52ce50)

- **F1 (curado).** `.env` como FIFO sem escritor pendurava `env_opens`; agora só abre arquivo regular, no script e no hook.
- **F2 (curado).** A dica do hook com caminho cru gerava JSON inválido; o texto é escapado e a dica de `source` sai citada.
- **F3 (curado).** `--test` com `.env` ilegível enviava token vazio; agora sai rc 4 antes da rede.
- **F4 (curado).** Mutantes vivos (hook com `[ -r ]`, `ENV_HINT` fixo, coluna vazia na lista) morrem por caso; 8 mutantes novos, todos mortos.

## Rebase sobre a main (2026-11-09)

Conflito no grafo das decisões, resolvido com o arquivo da origin/main mais os dois nós deste PR. Conferido: o patch dos outros 18 arquivos é idêntico ao do head aprovado, e o do grafo difere só na linha do teto, de 27 para 30 nós. Sem nova passada independente.

## O que esta passada não viu

Push por ssh de ponta a ponta, o efeito isolado do deny sobre assinatura gpg, sandbox no core real (ele não tem), login real, e a
passada independente sobre estas curas.
