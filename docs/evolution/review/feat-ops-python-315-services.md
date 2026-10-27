---
branch: feat/ops-python-315-services
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: a4b0d5f4a3c54feffac99af05d7c615952af24b7aafb6925491d1c052ef9fded
reviewed_code_sha256: 55d0d0afb1e620d9f0383d9e4c125201fd8928cb19ed0c1aa86f7d2ef259ff50
findings_total: 13
findings_real: 10
tokens: 152773
duration_min: 7
findings_fixed: 8
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: subagente general-purpose, model opus, 1 passada com mandato de refutar, sobre o diff inteiro (wrapper, chat-runner, bancada, alvos do MOAT e grafo)
nota: "O achado ALTO (o marcador de ambiente do requirements travava o apply e o verify no 3.15) foi medido pelo revisor num venv 3.15.2 real e curado com caso e mutante. Declarados sem cura: a janela entre o merge e o passo do runner (falha fechada), o backup do escritor com o serviço vivo (o molde do update-kg-writer), o venv endereçado pelo hash do requirements (subir o pino pede rollback e apply) e o EnvironmentFile, que não li (segredos), mas cuja sobreposição do PATH o verify agora pega pelo processo vivo."
---

# Passada adversarial: `feat/ops-python-315-services`

## O que muda

- `ops/migrate-python-service.sh` (novo): `<serviço> plan|apply --yes|rollback --yes|verify` para `runtime`, `granaai`, `writer` e `chat-runner` (só plan e verify).
- `ops/chat-runner.sh`: o `RUNNER_PY` de `/opt` na allowlist, no `--check-config`, no efetivo, no pré-voo e no contrato SDK↔lançador.
- A bancada: a família `migrate_python_service`, com 28 casos e um mutante cada, mais 3 casos sem mutante (a11b, c2, c3), e o r67 e o r68 no `chat_runner`.
- `ops/moat-targets.tsv`, com os alvos do intérprete, dos venvs e dos drop-ins.
- Os grafos: a evidência, a pergunta com gatilho e os quatro selos no `sinais-de-campo`; o selo do `Q_COORD_MAESTRO_FECHAR_SESSOES_ANTIGAS` e a ligação da pendência do 3.15 no grafo de coordenação.

## Achados

1. **ALTA, curado.** O `req_pins` lia `typing-extensions==4.16.0 ; python_version < "3.13"` como pino exigido, mas o instalador não o instala no 3.15. Com isso, o apply abortava sempre e o verify reprovava sempre. O revisor mediu num venv 3.15.2 real. Agora o marcador é avaliado contra o `PY_VERSION`, e um marcador fora da forma faz o wrapper recusar. Caso a12 com mutante.
2. **MÉDIA, curado.** O marcador de venv completo nascia antes do `chown`. Se o sudo falhasse, o venv ficava com o marcador e na conta do operador. Agora o marcador nasce depois da entrega, pelas mãos do dono, e o reuso confere dono e modo. Caso a13 com mutante.
3. **MÉDIA, curado.** Um `PATH=` no `EnvironmentFile=` vence o `Environment=` do drop-in, e o verify lia só a propriedade da unit. Agora ele lê o PATH do processo vivo, em `/proc/<pid>/environ`, e só a linha do PATH: o token nunca é impresso. Caso v6 com mutante. O `.conf` não foi lido, porque tem segredos.
4. **MÉDIA, curado.** A raiz de teste `/` passava, porque o realpath tira a barra final e `//` não casa com `/`. Caso u3 com mutante.
5. **MÉDIA, curado.** A exigência de falsos olhava o nome, e o uv real (em `~/.local/bin`) passava. Agora o destino tem de morar ao lado da raiz de sandbox. Caso u1, com a âncora nova.
6. **MÉDIA, curado em parte.** O root executava o uv da home do operador. Agora ele roda uma cópia de dono root, apagada no fim. O dono da pasta-mãe (`/opt/onion-python` e `/opt/onion-venvs`) entra na conferência. Teto: com o sudo NOPASSWD da conta, quem escreve na home já vira root, e isso não é deste wrapper.
7. **MÉDIA, declarado.** Entre o merge e o passo 4 do card, o `chat-runner.sh verify` acusa o runner vivo, e o `install` recusa o template velho. É falha fechada, e está no card.
8. **BAIXA, curado.** A paridade media só os `.kg.yaml`. Agora mede todos os `.yaml` das fixtures: as 431, com as 36 do perfil estrito. Ao medir os `.kg.json`, achei uma divergência real: o json da stdlib do 3.13 em diante aponta outra linha em 2 fixtures, com o mesmo veredito e o mesmo código. Os serviços só julgam `.kg.yaml`, então o `.kg.json` fica fora da paridade, declarado no código e no nó E.
9. **BAIXA, curado.** O rc 1 de um traceback contava como veredito. Agora só conta a saída na forma `kg-ssot.verdict/1`. Caso a11 (traceback) com mutante; o a11b (rc 2) está em defesa dupla.
10. **BAIXA, declarado.** O backup do escritor é feito com o serviço vivo, no molde do `update-kg-writer.sh`.
11. **BAIXA, curado em parte.** O pré-voo do runner aceitava qualquer python ≥ 3.12. Agora, em produção, exige o patch do caminho. Teto: no modo de teste, o `/opt` não existe e o sandbox não exercita o 3.15. A prova é o `install` (ensaio) na VPS.
12. **BAIXA, declarado.** O venv é endereçado pelo hash do requirements. Subir o pino deixa o verify vermelho até um rollback e um apply, e o gatilho em `Q_PYYAML_604_CP315_GATILHO_1027` diz isso.
13. **BAIXA, curado.** O rollback do runtime olhava só o disco. Agora olha também o processo vivo das duas units.

## O que o dogfood achou antes do revisor

- A paridade do verify antes da migração dava "igual" sem o venv, porque a perna nova caía no python3 do sistema. Curado com `[ -x bin/python3 ]`, caso v5 com mutante.
- O vendor da worktree servida do leitor (`71d804eb0`) não tem `--format`, e o pino dela (`rpds-py 2026.6.3`) é anterior ao wheel cp315. A worktree sobe para a `origin/main` antes do apply, e isso entrou no card.

## Limites declarados

- O uv, o sudo e o systemd de verdade não rodam na bancada. O que roda de verdade, sem privilégio: o plan e o verify nas units vivas, e o ensaio dos passos 2 e 3 num venv 3.15.2 com o pino por hash. Ele deu 34/34 no leitor, 65/65 no escritor, e paridade igual nas fixtures e no radar.
