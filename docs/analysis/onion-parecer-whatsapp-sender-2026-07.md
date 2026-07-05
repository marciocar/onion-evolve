# Parecer — `feature/whatsapp-sender`: destino do trabalho nascido no mobile

> **Status: PROPOSTO** — o parecer apresenta; o maestro decide (topologia W6: propor→confirmar).
> **Data:** 2026-07-05 · **Origem do artefato:** commit `17a90cb` (30/jun), criado **via
> Onion-Bridge/PWA** na linhagem `vps-bridge` — a primeira feature da história do ecossistema
> autorada de um celular. Resgatada à origin em 2026-07-05 (operação registrada no
> [diário](../../.claude/diary/2026-07-05-vps-lineage-odyssey.md) e no `members.yaml`).

## 1. O que é (examinado em primeira mão)

`whatsapp-sender/` na **raiz do repo** — ferramenta Node standalone, 6 arquivos (~150 linhas):

| Arquivo | Papel |
|---|---|
| `client.js` | cliente `whatsapp-web.js` compartilhado (LocalAuth persistida, Puppeteer headless) + normalização de número |
| `login.js` | autenticação única por QR code no terminal |
| `send.js` | CLI: `node send.js <numero> "<mensagem>"` |
| `README.md` | docs pt-BR **honestas**: avisa que a lib é não-oficial, risco de **ban do número**, e recomenda WhatsApp Business Cloud API/Twilio para produção |
| `package.json` + `.gitignore` | deps: `whatsapp-web.js@1.26`, `qrcode-terminal`; ignora sessão local |

Qualidade: código limpo, comentários pt-BR, caveats corretos. **Não é lixo — é ferramenta útil de
propósito estreito.**

## 2. O problema: onde ela vive

A identidade canônica ([CLAUDE.md](../../CLAUDE.md) / [onion-review-2026-05](onion-review-2026-05.md))
é taxativa: o core é **framework template em `.claude/`** — não é produto, não carrega código de
aplicação. `whatsapp-sender/` é **aplicação Node na raiz** do repo do framework:

- **D6 do `/meta:evolve` flagraria** na próxima rodada (resíduo fora do padrão framework);
- todo adotante que rodar `/meta:adopt` **não** a recebe (adoção copia `.claude/`) — ela ficaria
  órfã no core sem chegar a ninguém;
- a lib é **não-oficial com risco de ban** — inaceitável como capacidade *do framework* (que
  outros adotam confiando na curadoria), aceitável como ferramenta *pessoal* consciente do risco.

## 3. Régua P0-P3 (toolbox-lifecycle)

- **P0 — Já existe?** Não há eixo de mensageria no Onion. O padrão SDAAL (task-manager, forge,
  trust, de-identification) COMPORTARIA um futuro eixo `messenger/notification` — mas adapter
  SDAAL é **spec markdown** executada pela IA, não app Node vendorizado; e o 1º provider de um
  eixo sério seria a API oficial (Meta Cloud/Twilio), não automação de WhatsApp Web.
- **P1 — Determinístico ou juízo?** A ferramenta é determinística e autossuficiente — não precisa
  do Transformer. Mais um sinal de que é *tool*, não artefato de framework.
- **P2 — Semântica?** Nenhuma: não é comando, agente, skill nem KB. É produto de usuário final.
- **P3 — Irreversível?** Envio de mensagem real a terceiros = ação outward-facing com risco
  (ban, spam) — jamais entraria no framework sem human-gate; como tool pessoal, o gate é o dono.

## 4. Opções e veredito

| Opção | Veredito |
|---|---|
| **(A) Repo próprio `marciocar/whatsapp-sender`** | ✅ **RECOMENDADA** — preserva a ferramenta funcionando (inclusive no VPS, onde a sessão QR já vive), zero contaminação da identidade do core, e o histórico nasce limpo (`git subtree split` ou cópia + commit inicial citando a origem `17a90cb`) |
| (B) Mover para `.claude/utils/` ou `tools/` no core | ❌ viola a identidade (código de aplicação no template); adotantes não a usam; lib não-oficial sob a marca do framework |
| (C) Eixo SDAAL `messenger` agora | ❌ construir à frente do gatilho (anti-v4.0). **Registrar como costura**: se surgir demanda real de notificação em 2+ contextos, o eixo nasce com provider oficial (Meta/Twilio) e este tool vira, no máximo, um adapter `whatsapp-web-unofficial` com aviso de risco |
| (D) Descartar | ❌ funciona, tem uso e custou trabalho; o resgate já foi feito |

**Pós-execução da opção A:** apagar `feature/whatsapp-sender` da origin do core (o conteúdo
migrou; o commit `17a90cb` fica preservado no reflog/histórico do novo repo) e registrar no
`members.yaml` que a linhagem `vps-bridge` voltou a espelhar a main.

## 5. O achado maior que a feature

Este parecer documenta também o precedente: **o Onion-Bridge não é só leitura** — a linhagem do
VPS produziu código real de um celular (SDK com `bypassPermissions` + git local). Consequências:

1. **Toda linhagem com escritor é meia-instância** (3ª ocorrência: rhilo develop/main, agora
   vps-bridge) — o rito de update DEVE checar `git status`/branch antes de pull (já gravado no
   `members.yaml` e na memória da sessão).
2. **Trabalho nascido no mobile precisa de rota de volta** — hoje foi resgate manual via SSH;
   se o padrão se repetir, candidato a costura: o bridge commitar em branch própria (`bridge/*`)
   e sinalizar via inbox (gated: 2ª ocorrência real).

## 6. Decisão do maestro

- [ ] Aprovar opção A (repo próprio) — posso executar: criar repo, migrar com atribuição,
      apagar a branch do core, atualizar registro
- [ ] Outra rota (indicar)
