---
title: "Incidente de exposição de rede na VPS — Docker furando o firewall do host (contido)"
date: 2026-08-05
status: contido (contenção aplicada + persistida); follow-up durável pendente
scope: vps-shared-tools / segurança
kg: docs/onion/graph/onion-vps-consolidation-2026-08.kg.yaml
related:
  - docs/discussions/vps-shared-tools/SEED.md
  - docs/evolution/research/stack-harmonia-2026-08/
---

# Incidente — data stores expostos à internet (Docker contorna o firewall do host)

> **Versão generalizada (2026-10-13).** O core ficou público por decisão do maestro, e este documento
> perdeu o que só servia a um atacante: o endereço do host, a tabela de serviços expostos (nomes,
> portas, estado de autenticação, tenant) e o passo a passo do contorno. Fica a lição. O detalhe medido
> segue no histórico do git e no grafo `onion-vps-consolidation-2026-08`.

## Achado (medido ao vivo 2026-08-05, não fabricado)

Na VPS compartilhada, as portas publicadas por containers Docker ficavam **alcançáveis da internet
mesmo com o firewall do host ativo**. É um comportamento conhecido do Docker quando ele gerencia o
`iptables`: as regras que ele cria para as portas publicadas são avaliadas antes das do firewall do
host, e o ponto de controle que o próprio Docker reserva ao operador estava vazio. **O firewall do host
não protege nenhuma porta publicada por Docker.**

O que estava exposto: data stores de **mais de um tenant** da VPS (adotantes e projetos próprios), dois
deles **sem autenticação** — o caso crítico, porque data store sem senha exposto é comprometimento, não
só exposição. O WhatsApp padrão da VPS (`onion-vps-waha`) estava em loopback e nunca foi o vetor de rede.

**Correção de enquadramento (maestro):** o WAHA **não é órfão a parar** — é o **WhatsApp padrão da VPS**
(keeper). Mantém rodando (loopback + a contenção cobrem a rede), renomeia para `onion-vps-waha`, migra
segredos para `pass`; o wiring SDAAL segue gated (dogfood-first). Número dedicado, não pessoal: cliente
não-oficial tem risco de ban.

## Contenção aplicada (2026-08-05, reversível)

Uma regra global **default-deny para tráfego externo** no ponto de controle que o Docker reserva ao
operador, preservando conexões estabelecidas, loopback e container-a-container. Não toca a entrada do
host (ssh/mosh/Caddy intactos, zero risco de lockout) e nenhum `docker-compose` de adotante foi alterado.

**Persistência:** `onion-vps-docker-firewall.service` (systemd oneshot depois do `docker.service`,
idempotente) — re-aplica no boot, depois que o Docker cria as próprias regras.

**Sanidade pós-contenção:** serviços de identidade e o bridge saudáveis, loopback ok.

## Follow-up durável (decisão: conter agora, notificar depois)

1. **Cura durável (por tenant, no próximo toque no repo):** publicar as portas em `127.0.0.1` e não em
   `0.0.0.0` — o padrão que o `onion-logto` já usa. A contenção é rede de segurança; o rebind é a cura
   na fonte, e independe do firewall.
2. **Notificar os donos:** a exposição é dos serviços DELES; o achado e a cura de rebind vão downstream
   (co-announce/inbound). Feito para o adotante cliente no mesmo dia.
3. **Confirmação externa** (opcional, definitiva): sondar a porta de um host de fora da VPS.
4. **Auditar os demais `0.0.0.0`** que não são data store — a regra global já os cobre; avaliar se algum
   era intencionalmente público (via Caddy, nunca cru).

## A lição

- **Firewall do host ≠ proteção de container.** Numa VPS com Docker, "ufw ativo" é declaração; o que
  protege é o bind em loopback na fonte e a regra no ponto de controle do Docker, medidos por sondagem.
- **Data store sem senha é o que transforma exposição em comprometimento** — senha sempre, mesmo atrás
  de loopback (defesa em profundidade).
- **Acesso externo real vai por proxy reverso com autenticação/TLS**, nunca por porta crua.
- Virou mecanismo: a regra de bind do esqueleto de ferramenta da VPS
  (`docs/knowledge-base/tools/vps-tool-repo-skeleton.md`) e a REGRA 64 (Compose sem bind local ou com segredo em fallback literal).

## Convenção de nomenclatura (decisão do maestro, 2026-08-05)

Ferramentas/serviços que são **do Onion e padrão da VPS** usam o prefixo **`onion-vps-`**
(ex.: `onion-vps-waha`, `onion-vps-logto`, `onion-vps-bridge`). Distingue de:
- `onion-adopt-<nome>-*` — stacks de adotante;
- nomes próprios do adotante.

Já dogfoodada no artefato de contenção (`onion-vps-docker-firewall`). **Renomes aplicados
(2026-08-05):** `onion-vps-waha`, `onion-vps-logto`, `onion-vps-logto-postgres`,
`onion-vps-bridge.service`. Método seguro: só `container_name` (dir/projeto/service-name mantidos →
volumes nomeados preservados, DB de identidade intacto); refs `docker exec/inspect` em
`backup.sh`/`upgrade.sh` atualizadas; bridge via rename de systemd unit com verify+rollback.
Bug de dogfood corrigido: `onion-logto/up.sh` (`"${@:-up -d}"` → `set -- up -d`).
