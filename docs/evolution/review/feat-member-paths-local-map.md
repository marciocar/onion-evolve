---
branch: feat/member-paths-local-map
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: eefd16ef90f66cae799fb48f99bf65a167b92869a846cabfb4808ed0359a4f55
reviewed_code_sha256: 12e6fbaadc1d37b6f57a0eb789274a40e1910e403bbf9a1b1e509064b43822f0
findings_total: 6
findings_real: 4
findings_blocking: 0
tokens: 0
duration_min: 15
findings_fixed: 4
verdict: CORRIGIDO
elenxo: nao
reviewer: agente de execução da sessão do core (passada própria, não independente; o brief proibiu subagente)
nota: "tokens 0 = não medido. Nenhum nome de cliente, de repo ou de clone entrou no diff: o mapa local e a linha do adotante ficam fora da árvore."
---

# Passada adversarial: `feat/member-paths-local-map`

## O que muda

- Nasce o resolvedor único `.claude/utils/co-evolution/member-path.sh`. O `local_path` absoluto do
  registro vence; `n/a`, vazio ou prosa caem no mapa local da conta (`member-paths.tsv`, 0600,
  `id<TAB>caminho`, fora da árvore); sem linha, ele devolve vazio e rc 1, e quem chama decide.
- Seis consumidores passam por ele: `ops/registry-pins.sh`, `co-deliver.sh`, `detect-transport.sh`,
  `door-role-parity-check.sh` (REGRA 92, Papel da porta no registro concorda com o CARIMBO dela),
  `peer-ref-check.sh` e `check-member-registered.sh`.
- Fora por desenho, declarado no cabeçalho e no grafo: as projeções e a publicação (`kg-projection`,
  `door-leak-scan`, `publish-door`), o gate a2a e o escopo do veto do adotante.
- O mapa desta máquina ganhou a linha do adotante de consultoria, fora do repo.

## Dogfood (antes e depois, com o registro do PR #1522)

- `registry-pins.sh --check --no-remote --only <id>`: antes ILEGÍVEL ("sem remoto no registro nem no
  clone; sem clone"); depois lê o clone e mostra DIVERGE (registro `6c4272252528`, carimbo da origin/main
  do clone `e4c954ebad47`). A divergência é real e fica como pergunta aberta no grafo.
- REGRA 92: antes "1 adotante(s) com clone INALCANÇÁVEL"; depois o membro é medido e o par
  standalone/adopted passa.
- `detect-transport.sh` com `auto`: `local`. `co-deliver.sh --dry-run`: resolve o destino sem `--target`.
- `check-member-registered.sh` sobre o clone: "já está no members.yaml"; sem o mapa, "NÃO REGISTRADO".

## Achados

1. **Real, curado.** A 1ª ligação no `co-deliver.sh` trocava o valor declarado pelo resultado do
   resolvedor mesmo quando ele não resolvia. Um `local_path` relativo (que o carteiro resolvia contra a
   raiz do repo) viraria vazio. Agora todo consumidor só troca o valor quando o resolvedor devolve rc 0.
2. **Real, curado.** O aviso de permissão aberta saía a cada chamada da função, e a REGRA 92 a chama uma
   vez por membro: com o mapa em 0640, o lint imprimiria o mesmo aviso dezenas de vezes. Agora só a CLI
   (`--list`) avisa; a função cala. A bancada prende as duas metades.
3. **Real, curado.** A primeira criação do mapa herdou a ACL padrão do diretório e ficou 0660 mesmo com
   `umask 077`. Foi corrigido na máquina (`setfacl -b` e `chmod 600`), e o resolvedor avisa no `--list`.
4. **Não é defeito.** Sem o arquivo do resolvedor (vendor parcial), o `source` falha, o nome da função
   não existe e o consumidor mantém o valor declarado: degrada para o comportamento anterior, com uma
   linha de erro do bash.
5. **Não é defeito.** No CI e em `env -i` o mapa não existe (sem `HOME` ou sem o arquivo): o resultado é o
   mesmo de antes (ILEGÍVEL e NÃO-MEDIDO declarados), e é determinístico.

6. **Real, curado.** Os dois nós de teto do grafo estavam `confirmed` sem `provenance`, e o contrato
   KG-SSOT do commit (o passo do CI) reprovou no `pr-finalize`. Ganharam fonte, localizador e método
   (`reading:`).

## Bancada

Família `member_path`: selftest do resolvedor (12 casos), mutante que ignora o mapa (morto), ponta a
ponta no `registry-pins.sh` com e sem mapa e na REGRA 92 com e sem mapa. Dois mutantes manuais, com
`LC_ALL=C`: desligar a ligação no `registry-pins.sh` e na REGRA 92 reprova o caso de cada um.
