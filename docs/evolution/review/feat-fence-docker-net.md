---
branch: feat/fence-docker-net
pr: pendente
date: 2026-11-23
reviewed_diff_sha256: 9330ee83ed4f94c95b98bfd3959aa25c03cbc11914e65d5c6ab4e8f55f02bd53
reviewed_code_sha256: 404be8d700352d35992bc195c132f749e85928780d47405adac14c7b3dc921a4
findings_total: 15
findings_real: 13
findings_blocking: 3
tokens: 212229
duration_min: 40
findings_fixed: 12
verdict: FIXED
elenxo: true
elenxo_isolado: true
reviewer: subagente general-purpose (opus), isolado, duas rodadas; mandato REFUTAR, só leitura
nota: "duas rodadas do mesmo revisor isolado (a 2ª conferiu as curas da 1ª e revisou do zero o ufw-orphan-rules.sh); tokens = soma das duas rodadas"
---

# Passada adversarial: `feat/fence-docker-net`

## O que muda

- `ops/egress-uid-fence.sh`: a 3ª parte da cerca de saída por uid, para a **rede dos containers**. Medição da vps-ops
  (só leitura, 2026-11-23): da conta comum da VPS, quase todas as portas de container abriam pelo IP do container;
  só o docker-proxy (root) precisa. Conexão NOVA com destino original em 172.16.0.0/12, sem DNAT e fora dos endereços
  do host: root passa; as demais contas conforme o modo da unit: `log` (padrão: só registra quem seria barrado, com
  limite por destino), `reject` (RST) ou `off`. O `verify` confere que toda rede de bridge do Docker está na faixa.
- `ops/ufw-orphan-rules.sh` (novo): apaga, por regra exata, 4 regras do ufw sem serviço (SAC-465), re-mede a escuta
  na hora, grava o desfazer (comentário original, root 600) ANTES de apagar, e re-adiciona pelo `undo`.
- `lint-selftest.sh`: a família `ufw_orphan_rules`.

## Achados (rodada 1, só a cerca)

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 1 | O verify e o reinstall ignoravam o modo gravado na unit: depois de um install em reject, o verify pelo shell dava vermelho falso e um reinstall sem flag voltava ao log em silêncio | sim | sim | Curado: o modo vem da unit quando não é dito; testes «install reject → verify e reinstall sem flag» |
| 2 | O limite do LOG era global: um cliente barulhento calaria o registro de outro destino e a semana de ensaio sairia «limpa» | sim | sim | Curado: hashlimit por IP e porta de destino (6/min cada); o contador da regra é a prova de volume |
| 3 | A faixa 172.16/12 está quase cheia; a próxima rede do Docker cairia em 192.168/16 fora da cerca | sim | não | Curado: o verify confere cada rota de bridge contra a faixa e reprova a que estiver fora |
| 4 | O `addrtype` olha o destino depois do DNAT; uma porta publicada no gateway casaria a regra | sim | não | Curado: `! --ctstate DNAT` na regra e texto corrigido |
| 5 | Mutantes que passavam (limit, ordem no reject, pré-voo das extensões novas) | sim | não | Curado: grep do hashlimit inteiro, teste de ordem no reject, pré-voo com extensão ausente |
| 6 | «Só o docker-proxy» é, de fato, «todo processo root» | nota | não | Texto corrigido |

## Achados (rodada 2: curas da cerca e o ufw-orphan-rules.sh do zero)

| # | achado | real? | bloq.? | destino |
|---|---|---|---|---|
| 7 | A conferência de rotas aceitava `ip` falhando como «tudo dentro», não rodava no selftest, repetia a faixa à mão e não via bridge de nome próprio | sim | sim | Curado: função própria com rc conferido (falha = reprova), faixa derivada de `$DOCKER_NET`, bridge de nome próprio pelo `docker network`, `ip` e `docker` de mentira no selftest |
| 8 | Comentário dizia «10 por minuto» | sim | não | Corrigido |
| 9 | Unit editada à mão com modo inválido gravaria modo vazio | sim | não | Curado: o install recusa modo inválido de qualquer origem |
| 10 | A ordem «desfazer antes de apagar» não tinha teste | sim | não | Curado: teste com `tee` que falha; nenhuma regra sai |
| 11 | O undo re-adiciona no fim da lista, não na posição original | sim | não | Declarado no cabeçalho (sem efeito nestas portas sem serviço) |
| 12 | Desfazer com uma linha adulterada parava no meio, com parte re-adicionada | sim | não | Curado: o arquivo inteiro é conferido antes da 1ª regra; teste |
| 13 | O «pega o mais novo» do undo não era exercitado | sim | não | Curado: teste com dois arquivos |
| 14 | Grep da porta, conferência final e apagar por regra | não | não | Corretos, conferidos pelo revisor |
| 15 | Família nova no lint-selftest | não | não | Segue o molde e está registrada |

## Mutantes

- `ops/egress-uid-fence.sh --selftest`: 68 pass / 0 fail. `ops/ufw-orphan-rules.sh --selftest`: 20 pass / 0 fail.
- `lint-selftest.sh --families egress_uid_fence,ufw_orphan_rules`: rc 0.
- Medido na VPS (só leitura): as 15 redes de bridge do Docker estão dentro de 172.16.0.0/12 (`bridges_outside` vazio).

## Limites declarados

- Não verificado contra o ufw real: o formato de `ufw show added` com o comentário e se `ufw delete <regra>` sem o
  comentário apaga a regra comentada. O `plan` (ensaio) mostra antes do ato se cada regra é achada.
- Não verificado: quem, fora do root, usa IP de container hoje. É para isso que o modo `log` roda uma semana antes do `reject`.
- O revisor rodou um `sudo -n iptables -t nat -S` (só leitura) na 1ª rodada, contra o mandato; nada mudou.
