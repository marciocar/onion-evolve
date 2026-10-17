---
branch: fix/bridge-wrappers-unmeasured-rc
pr: pendente
date: 2026-10-17
reviewed_diff_sha256: pendente
findings_total: 2
findings_real: 2
tokens: 143957
duration_min: 11
findings_fixed: 2
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose (opus), mandato de refutar; passada 2 sobre as curas
nota: "tokens e duração da 1ª passada do refutador; a 2ª passada e a autoria não foram somadas"
---

# Passada adversarial: `fix/bridge-wrappers-unmeasured-rc`

## O que muda

O `ops/update-bridge.sh` (#1174) já saía rc 1 quando um verify do pós-update reprovava ou não media, mas o RÓTULO mentia: os dois wrappers que ele chama devolviam rc 1 também quando o `sudo -n` falhava, e o update-bridge escrevia "o verify REPROVOU". Medido com os wrappers reais em produção e um `sudo` falso que sai 1 ("a password is required"): em `origin/main`, o `bridge-hardening.sh verify` saiu rc 1, e o `chat-runner.sh verify` saiu rc 1 AFIRMANDO "fonte com SYMLINK no caminho" sobre um arquivo que ninguém leu.

**rc escolhido: 2 = não pude medir.** É a convenção da casa (`review-gate-health.sh`, `a2a-doctor.sh`), e o `EXIT:` dos dois wrappers já reservava o 2 para "trava, sudo, unit, health", com o 3 para uso inválido: não há colisão, o defeito era o código não cumprir o próprio contrato. O update-bridge já mapeava todo rc diferente de 0 e 1 para NÃO MEDIU; agora o rc 2 chega.

- `bridge-hardening.sh`: o `verify_live` exige a linha `n_fail=N`, que o sh de checagem sempre imprime por último. Sem ela, o sh não rodou até o fim: rc 2. Exceção (curada na passada 1): se já há uma linha FALHA, é rc 1. O `systemctl show` do DropInPaths que falha é rc 2, não "NÃO está carregado". No `install --apply`, o NOOP com o verify não medido sai rc 2 sem reiniciar.
- `chat-runner.sh`: em produção, sonda `sudo -n true` e `sudo -n -u onion true` antes de qualquer leitura, e sai rc 2.
- `update-bridge.sh`: o JWKS medido uma vez NÃO é corrida no update, porque o veredito do `jwksSelfCheck` sai na MESMA linha do "auth: enforce" que a fase 5 espera, e cada /chat re-busca sozinho no bridge. No NOOP, porém, o boot vivo pode ter dias: o journal é lido com `-o short-iso`, e a linha passa a dar a data do "JWKS OK" e a dizer que a alcançabilidade de agora não é re-medida.

Nó: `E_VERIFY_DO_BRIDGE_SEPARA_NAO_MEDIU_DE_REPROVOU_1016` no grafo r12, SUPPORTS `E_DEPLOY_DO_BRIDGE_REPROVA_O_QUE_NAO_PROVOU_1016`.

## Achados

1ª passada (2, ambos reais e curados):

1. **MÉDIO, curado.** Uma FALHA medida antes de o sh morrer (fork negado pelo limite de processos da conta, OOM) virava rc 2, e o NÃO MEDI escondia uma reprovação real. Medido pelo refutador com o wrapper real e um nsenter falso. Agora, sem `n_fail`, uma linha FALHA vale rc 1. Caso (h31).
2. **BAIXO, anterior ao diff, curado.** O `install --apply` tratava o rc 2 como 1: no NOOP reiniciava o serviço de produção sem ter medido nada, e depois do restart dizia "reprovou". Agora o NOOP sai rc 2 sem restart (h32), e a falha depois do restart diz "NÃO MEDIU (rc 2)" ou "reprovou" (sai 1 com o rollback, porque o restart já aconteceu).

2ª passada (sobre as curas): nada refutado. Medido em produção na sandbox: sudo falhando dá rc 2, `n_fail=1` dá rc 1, FALHA seguida de "Cannot fork" dá rc 1. O `die 2` do NOOP vem antes do `/health`, sem regressão. Lacuna menor declarada: nenhum caso confere o texto "NÃO MEDIU (rc 2)" do `fail_after` pós-restart (o mutante de h23 só tira a chamada).

Teses que resistiram: o JWKS (confirmado no código servido, com teto de 5 s no fetch, dentro da espera da fase 5), o `-o short-iso` (forma do journalctl 255 igual à do falso, greps intactos), a sonda do runner (depois do parse e do rc 3, pulada no modo de teste, sem falso NÃO MEDIU com o sudoers NOPASSWD medido), e os casos r24b/r24c (o mutante só chama o sudo falso e morre no read_sources).

Efeito colateral declarado pelo refutador: um install dele em produção com sudo falso abriu por instantes a trava real `/tmp/onion-update-bridge.lock` (vazia, sem efeito).

## Mutantes

Cada caso novo tem mutante pelo `_prove_mutation` da família: (h29), (h30), (h31), (h32), (r24b), (r24c), (u22), (u23). Os casos (h19), (h23), (h26) e (u9) tiveram a âncora atualizada para o código novo. Seis mutantes plantados por `ops/mutate-and-restore.sh` nos arquivos reais, com `LC_ALL=C`, derrubaram casos intactos: sem a linha n_fail (h29), sem a sonda do runner (r24b, r24c), rc 2 mapeado para REPROVOU (u3, u5, u22), sem o `-o short-iso` (u23), sem a FALHA antes do corte (h31) e sem o `die 2` do NOOP (h32).

## Limites declarados

- A sonda do runner prova o sudo no início. Um sudo que passe a falhar no meio ainda cai no veredito da checagem, e um sudoers que liberasse só uma lista de comandos sem `true` daria NÃO MEDI sempre (hoje é NOPASSWD: ALL, medido).
- Não medido: o verify verde contra o serviço real, que é proibido nesta tarefa. O próximo deploy real é a prova.
- O JWKS de agora segue sem medida no NOOP. A linha diz isso, e o teto é o fio Q_JWKS_REFETCH_STORM.
