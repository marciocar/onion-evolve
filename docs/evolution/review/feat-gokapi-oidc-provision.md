---
branch: feat/gokapi-oidc-provision
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: f3cacffa1b3168c6a334f4144c3b8f98c1691bb539cb1fbc5978cb8623b8fa16
reviewed_code_sha256: ccc0b24190a86f29b245e89254b0e127e7bb10515789923f31a19c8f6e757f89
findings_total: 6
findings_real: 6
findings_blocking: 3
tokens: 127339
duration_min: 4
findings_fixed: 6
verdict: FIXED
elenxo: false
reviewer: general-purpose opus (refutador isolado, mandato refutar: vazamento de segredo e idempotência)
nota: "A bancada foi de 26 para 30 casos com as curas; mutantes por ops/mutate-and-restore.sh: 19 plantadas, 18 mortes de primeira; o sobrevivente virou o caso 3b e morreu na replantação."
---

# Passada adversarial: `feat/gokapi-oidc-provision`

## O que muda

- `ops/bridge-auth/gokapi-oidc-provision.sh` (novo): o ato que cria o app «Traditional web» `onion-vps-gokapi` no
  tenant `default` do Logto pela Management API e grava o client id e o client secret no credstore do systemd
  (600 root, escrita atômica, valor só por builtin). Dry-run por padrão, `--apply`, `--check` e `--undo`.
- `ops/bridge-auth/logto-mapi.sh` (novo): o pré-flight do bootstrap circular, o token do `m-default`, o `api` e o
  `mutate` saem do molde para uma biblioteca, com o secret do `m-default`, o Bearer e o corpo das chamadas fora do
  argv do curl e um modo de teste (Logto simulado em 127.0.0.1, raiz em /tmp, sem docker nem sudo).
- `ops/bridge-auth/logto-provision.sh`: faz source da biblioteca; a senha gerada e o SMTP_PASS saem do argv do jq.
- `ops/testing/gokapi-oidc-provision-selftest.sh` (novo) e a família `run_gokapi_oidc_selftests` no lint.
- Nós `D_GOKAPI_OIDC_BY_API_2026_11` e `E_TEST_FALLBACK_READ_REAL_MDEF_SECRET_2026_11` no grafo do M2.

## Achados

1. **(bloqueia, curado) Estado ambíguo recusado só depois de mutar.** Com o app existente em deriva e dois secrets
   válidos sem «Default secret», o ato fazia o PATCH dos redirects, o PUT da ACL e o PATCH do controle e só então
   saía rc 8. Cura: o secret se resolve logo depois do `find_app`, antes de qualquer mutação. O caso 10 da bancada
   agora tem deriva, ACL vazia e controle desligado, e confere zero mutação.
2. **(bloqueia, curado) O trap do `cred_put` não limpava o temporário.** O `_tmp` era `local`, e sob `set -e` o bash
   desfaz a função antes do trap de EXIT: com o chmod falhando, sobrava `.onion-vps-gokapi.XXXXXX` com o valor dentro.
   Cura: variável global `_CRED_TMP`. Caso novo 5b com chmod falso que falha.
3. **(bloqueia, curado) O modo de teste ainda alcançava o docker real.** Já cortado o sudo (ver o incidente em
   «Limites»), o `_dk` chamava o docker do PATH; o operador está no grupo docker. Cura: no modo de teste a biblioteca
   não toca docker nem sudo, o secret de mentira vem de `ONION_LOGTO_MAPI_MDEF_SECRET`; a bancada registra qualquer
   chamada ao docker ou ao sudo falsos, e o caso 13 reprova se houver alguma.
4. **(limite, curado) O PATCH dos redirects apagava o resto do `oidcClientMetadata`** (o Logto 1.46 substitui o
   objeto). Cura: manda o objeto atual com os dois campos trocados. Caso novo com `logoUri` preservado.
5. **(limite, curado) A raiz de teste aceitava `..`** (`/tmp/..` virava o credstore real). Cura: `realpath -m`
   antes de conferir o prefixo. Caso novo.
6. **(limite, curado) Segredos do molde seguiam em argv**: o corpo das chamadas (`-d "$b"`, com a senha gerada do
   usuário) e o `jq --arg` do SMTP_PASS e da senha. Cura: `--data-binary @<(printf …)` na biblioteca e os segredos
   ao jq pelo ambiente.

Tentado e não refutado pelo revisor: secret do app em argv ou na saída (só builtins, `cmp` por process
substitution, mensagens de erro só com `.code/.message`); Bearer e secret do `m-default` pelo `-K -` com escape;
dry-run sem mutação e sem arquivo; re-rodar sem mutação, mesmo inode e mtime; permissões 600/700; recusas antes de
mutar (dois apps, outro tipo, operador ausente); molde equivalente e com o dry-run de pé.

## Mutantes

Todos por `ops/mutate-and-restore.sh` contra a bancada (`LC_ALL=C`). A guarda do dry-run no `cred_put` SOBREVIVEU na 1ª plantação (o dry-run de tenant vazio nunca chega a ela); virou o caso 3b e morreu na replantação. Mortos (18 mutantes distintos):
guarda do dry-run no `cred_put`; comparação que evita reescrever; `cred_matches` sem `cmp`; recusa de dois apps;
recusa de outro tipo; eco do secret; PATCH do controle de acesso; PATCH da deriva; recusa do operador ausente;
escolha inequívoca do secret; Bearer em argv; secret do `m-default` em argv (`-u`); fallback de docker no teste;
trap do temporário; leitura antecipada do secret; merge do `oidcClientMetadata`; `realpath` da raiz; docker no
teste (2ª forma). Cinco deles ficam permanentes na família do lint.

Não plantados, de propósito: desligar a guarda das variáveis de teste, a do loopback e a do root. Sem elas o ato
cai no caminho de produção e falaria com o Logto real ou com a internet; a guarda é coberta pelos casos 14, 15, 16
sem mutante.

## Limites declarados

- **Incidente na 1ª rodada da bancada:** o docker falso que falhava fez o fallback `sudo -n docker` real ler o
  secret REAL do `m-default` e mandá-lo, em HTTP no loopback, ao Logto simulado. Não foi impresso, não foi para
  argv, e o diretório da bancada foi apagado pelo trap; mas foi leitura do banco do Logto que o brief proibia.
  Curado (achado 3) e registrado em `E_TEST_FALLBACK_READ_REAL_MDEF_SECRET_2026_11`. Rotação do secret fica com
  o maestro.
- O `--apply` real e o dry-run real NÃO rodaram: o dry-run real já lê o secret do `m-default` do banco.
- O contrato do Logto vem do código da imagem 1.46.0, não de chamada ao vivo; a bancada simula esse contrato.
- O auto-cadastro em si é do tenant (signInMode): o ato só avisa; fechar o tenant é ato à parte.
- `--data-binary` no corpo do molde não tem caso que o exercite com segredo (o dry-run do molde não faz POST).
