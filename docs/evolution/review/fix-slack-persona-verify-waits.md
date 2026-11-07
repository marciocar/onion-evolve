---
branch: fix/slack-persona-verify-waits
pr: pendente
date: 2026-11-07
reviewed_diff_sha256: 4ab6cfc97f86f7e93fcfa4002b28881019400f88737ca02b07dc5ef00a829967
reviewed_code_sha256: 14d361de046d703cb489938397cb54dbbdcd2274d8d0dd2f6ec62723adec9782
findings_total: 3
findings_real: 2
findings_blocking: 0
tokens: 0
duration_min: 15
findings_fixed: 0
verdict: APROVADO
elenxo: sim
reviewer: "o agente de execução que escreveu a cura, com mandato de refutar: cada mutante aplicado à mão para ver em QUAL asserção morre, e o laço lido contra o original linha a linha"
nota: "tokens = 0 porque a passada rodou dentro do agente, sem agente medido à parte. Os dois achados reais são limites (não bloqueiam) e vão abaixo; o terceiro foi refutado pela leitura."
---

# Passada adversarial: `fix/slack-persona-verify-waits`

## O que muda

- `ops/slack-persona.sh`: o laço de espera do `start` (até 45 leituras, sai cedo se a unit falhou) virou a função
  `wait_connected` com o teto em `CONNECT_WAIT_S=45`. O `verify` passa a usá-la no lugar da leitura única de
  `connected_in_invocation`, e a falha diz o teto ("sem a linha de conexão desta invocação em 45 s"). O `start` usa a
  mesma função, sem laço duplicado.
- `ops/testing/slack-persona-selftest.sh`: o `systemctl` falso ganhou o marcador `active` e responde `DynamicUser=yes`
  ao `show` que o pede; o `journalctl` falso conta as leituras e só imprime a conexão depois de `jdelay` leituras.
  Dois casos novos: conexão depois de 5 leituras passa (e foram exatamente 6 leituras); ausente até o teto reprova
  com rc 1, diz "45 s" e leu o teto inteiro.
- `.claude/validation/lint-selftest.sh`, família `slack_persona`: 23 → 25 casos e dois mutantes novos.

## Achados

1. **Real, limite.** A mensagem do `start` diz "não vi a conexão desta invocação em 45 s" também quando o laço saiu
   cedo porque a unit falhou. Já era assim antes (o texto era literal); agora o número vem da variável. Não muda o
   rc nem o rollback impresso, e o journal das últimas 20 linhas sai logo acima.
2. **Real, limite.** O `sleep` da bancada é falso: o caso prova que o verify LÊ o journal até o teto (45 leituras),
   não que espera 45 s de relógio. O relógio real é `sleep 1` por leitura, igual ao `start` que já rodava em produção.
3. **Refutado.** Suspeita: com `Restart=on-failure`, a unit pode reiniciar durante a espera e a InvocationID mudar.
   A função relê a InvocationID a cada volta, então julga sempre a invocação viva, que é o que o verify promete.

## Mutantes

- `if wait_connected; then say "✓ ativa e conectada` → `if connected_in_invocation; …` (o verify sem espera, o
  defeito de 07/11): morre em "verify: conexão que aparece depois de 5 leituras passa" e no caso do teto.
- `for i in $(seq 1 "${CONNECT_WAIT_S}"); do` → `seq 1 1` (teto de uma leitura): morre nos dois casos do verify.
- Os 9 mutantes antigos da família seguem mortos (`--families=slack_persona`: 0 falhas).

## Limites declarados

- O verify agora pode levar até ~45 s quando a unit está ativa mas não conecta. É o preço de não dar ✗ falso logo
  após um restart; o caso conectado responde na primeira leitura em que a linha existir.
- A cura não foi rodada contra a unit real (ordem: não reiniciar a unidade). O dogfood real é o maestro rodar
  `ops/slack-persona.sh verify` logo depois de um restart.
