---
title: "Infra/VPS no Onion — o maestro selou B integral, com o dado da VPS fora do pacote"
date: 2026-10-05
kg: docs/evolution/research/infra-vps-2026-10/infra-vps-2026-10.kg.yaml
run_id: wf_b5f60320-80d
tokens: 6501367
agents: 104
duration_min: 16
---

# Decisão selada

`D_INFRA_VPS_TREATMENT` → **B integral**, selada pelo maestro em 2026-10-05: grafo de domínio da VPS
como SSOT viva, censo determinístico que mede o vivo contra ele, e comando `/ops:vps`, tudo core-only.
O Elenxo recomendava a **B enxuta** (sem comando, sem hook), e o selo foi além disso por escolha do
maestro.

O mesmo selo trouxe uma restrição, em forma de pergunta: **o dado da VPS não viaja para adotante.**
Medido no `vendor-manifest.sh`: `docs/onion/`, `docs/evolution/` e `ops/` não viajam; `.claude/commands/`
e `.claude/validation/` viajam. Logo o censo mora em `ops/`, e o comando sai do pacote por corte, com caso
de bancada que reprova se ele aparecer.

## O que a pesquisa mediu

- **Relatar sem alterar é o estado da arte** em censo de host (`checkrestart`, Lynis): casa com "reboot
  e upgrade são decisão humana".
- **Medir o vivo contra um grafo declarado** é o diferencial da B; as ferramentas existentes medem só o
  vivo.
- **Exposição se mede na cadeia DOCKER-USER/FORWARD**, não no `ufw status` — confirma de fora o incidente
  `CL_net_exposure_incident` que o corpus já tinha.
- **`/var/run/reboot-required` pode faltar** mesmo com kernel novo: o censo compara o kernel em execução
  com o do `/boot`.
- **Objeções do Elenxo que sobreviveram:** o `checkrestart` citado nem está instalado aqui (o
  `needrestart` está); o `exit 2` não é argumento a favor de censo, que é leitura e não veto.

## Achado novo desta rodada

`Q_VPS_EXPOSURE_CHECK_VAZA_TOPOLOGIA`: a guarda `vps-exposure-check.sh` já existente mora numa raiz que
viaja e carrega caminhos fixos desta VPS. Chegou a três adotantes e à porta pública `onion-core`. A cura
entra na forja da B.

## Mercado

Sem sinal. As três claims de capital (custo de plataforma interna) foram **refutadas** no voto
adversarial; uma delas era recomendação de quem vende a camada comprada. O argumento contra C e D veio
da doutrina (pull-not-push, CORE≠FAMÍLIA), não do mercado.

## NÃO-VERIFICADOS

| Categoria | Quantidade |
|---|---|
| refutadas no voto | 8 |
| não verificadas por orçamento (`maxVerify` 25) | 26 |
| cortadas por orçamento de fetch | 33 |
| sem veredito | 0 |

A recomendação do Elenxo chegou **truncada** ao escritor do grafo, e as objeções são de um agente só,
sem votação (confiança ≤ 0,6).

## Valeu a pena

6.501.367 tokens ÷ 42 nós ≈ **155 mil por nó**. Fica entre os dois pontos medidos da casa: a varredura
`decision` de 2026-09-13 (≈291 mil/nó) e o modo `primaries` (≈42 mil/nó). Era o modo certo: as lacunas
não tinham nome.
