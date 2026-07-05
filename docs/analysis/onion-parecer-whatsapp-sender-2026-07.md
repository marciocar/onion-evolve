# Parecer — `feature/whatsapp-sender`: destino do trabalho nascido no mobile

> **Status: DECIDIDO E EXECUTADO (2026-07-05)** — maestro aprovou a opção A com reenquadramento
> de princípio (ver §4-C e §6). Extração concluída: repo privado `marciocar/whatsapp-sender`
> (história preservada via `git subtree split`, autoria do commit original intacta + nota de
> proveniência), ferramenta reinstalada no VPS (`~onion/whatsapp-sender`; sessão QR não
> sobreviveu ao checkout — re-scan no 1º uso), branch removida da origin após verificação
> byte a byte da migração.
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
| (C) Eixo SDAAL `messenger` agora | ❌ construir à frente do gatilho (anti-v4.0). **Costura registrada com o princípio do maestro (2026-07-05)**: a *capacidade* de mensagear encaixa em muitas ações do Onion (notificação de co-evolução, gates humanos, prompts pedagógicos/autorregulatórios — ver [semente SRL/PLEA](onion-research-seed-srl-plea-2026-07.md) Q3), mas quando o gatilho disparar (demanda real em 2+ contextos) o eixo nasce **à moda Onion: dogfoodando com SDAAL — LLM como VM; MD/KG/grafos/scripts como bytecode**. Interface/adapters em markdown executável pela VM-Transformer, migalhas guiando em runtime, scripts só onde o determinismo paga, provider oficial primeiro (Meta Cloud/Twilio); a ferramenta extraída é possível *backend* de um adapter `whatsapp-web-unofficial` com aviso de risco — nunca código vendorizado no core |
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

- [x] **Opção A aprovada e executada (2026-07-05)** — repo privado `marciocar/whatsapp-sender`
      criado, história migrada com atribuição, branch do core apagada, registro atualizado.
      Reenquadramento de princípio incorporado ao §4-C: capacidade reconhecida; implementação
      futura spec-first (SDAAL, LLM-as-VM, bytecodes MD/KG/grafos/scripts).
- [x] **Pesquisa futura plantada**: [onion-research-seed-srl-plea-2026-07.md](onion-research-seed-srl-plea-2026-07.md)
      (Autorregulação da Aprendizagem + PLEA de Pedro Rosário × loop de auto-evolução do Onion).
