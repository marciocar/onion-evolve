---
type: co-evolution-signal
direction: upstream   # sinal → core
from: instância rhilo-metagamify (dogfood ao vivo)
to: Onion core / Mestre
date: 2026-07-03
subject: Padrão de segurança — manuseio de segredos pelo agente (nunca em texto no chat)
status: proposta-para-avaliação
maturity: aplicado ao vivo (instalação sudo + dump de RDS de produção)
---

# Sinal ao Mestre — manuseio seguro de segredos pelo agente

> Nasceu na prática hoje: eu precisava de `sudo` (senha do usuário) para instalar um cliente e dumpar um
> RDS de produção. A tentação óbvia — "me passa a senha" — é **errada**. Proponho formalizar o padrão no
> core, como **spec SDAAL** (markdown executável), pra toda instância Onion herdar o comportamento seguro.

## O princípio (regra dura)

**O agente NUNCA deve solicitar nem aceitar segredos em texto claro na conversa** (senhas, tokens, chaves).
Uma vez digitado no chat, o segredo fica no transcript, no histórico de shell e em logs — vaza mesmo se
apagado depois. O agente deve **projetar o fluxo para não precisar ver o segredo**.

## Os padrões que funcionaram (e viram receituário SDAAL)

1. **Capability-split (o preferido):** o passo privilegiado é executado **pelo usuário** no terminal dele
   (o segredo nunca sai do terminal dele); o agente faz **todo o resto** (o trabalho sem privilégio). Ex.:
   usuário roda `sudo apt install …` num terminal real; o agente roda o `pg_dump` (que não precisa de sudo).
2. **Terminal real p/ prompts interativos:** um `!` sem TTY (ou o shell do agente) **não consegue** pedir
   senha (`sudo: a terminal is required`). Prompts interativos de segredo têm que rodar num terminal do
   usuário — não no canal do agente. (Aprendido ao vivo: o `!` desta sessão não tem TTY.)
3. **Credencial em cache / de curta duração:** `sudo -v` (cache ~15 min, por-tty) ou tokens efêmeros —
   o agente opera dentro da janela sem nunca ver o segredo. Ressalva: `tty_tickets` pode não compartilhar
   entre o shell do usuário e o do agente.
4. **Segredo fora-de-banda:** ler de arquivo protegido (`.env` com permissão restrita, `PGPASSWORD` do
   ambiente, secret manager) — o agente referencia a **fonte**, nunca o valor. (Já fazemos: lemos
   `RHILLO_ADMIN_PASSWORD` de `~/…/.env`, sem imprimir.)
5. **Container como isolador de versão/tooling:** rodar a ferramenta privilegiada/específica dentro de um
   container (ex.: `docker run postgres:16 pg_dump …`) evita instalação com sudo **e** resolve versão.

## Anti-padrões (o que o agente NÃO faz)

- Pedir "me passa a senha" / aceitar senha colada no chat.
- `echo 'senha' | sudo -S …` **montado pelo agente** (o segredo entra no comando/histórico).
- Guardar segredo em variável de conversa, memória, ou arquivo versionado.

## Proposta ao core

- Formalizar como **spec SDAAL** em `docs/knowledge-base/concepts/secret-handling-agent.md` (markdown executável),
  referenciada pelo [SDAAL](../../../knowledge-base/concepts/specification-driven-ai-abstraction-layer.md) e pelas
  regras de agente (`.claude/`). O agente passa a, por default: detectar necessidade de segredo → escolher
  o padrão (1–5) → **nunca** pedir texto claro.
- Casar com a governança **DEV↔PROD** (sinal anterior, 2026-07-02): ação privilegiada em produção é
  deliberada, do usuário, com migalha de rastreio.
- Um checklist curto ("precisa de segredo? → capability-split primeiro; container p/ tooling; nunca no
  chat") como gate reusável.

## Evidência (dogfood de hoje)

Recusei receber a senha; propus capability-split (usuário instala via sudo, agente dumpa) + Docker como
alternativa sem sudo. O `!` sem TTY confirmou o padrão 2 (prompt interativo só em terminal real). Tudo com
o segredo **fora do chat**.

*Rode `/meta:co-evolve` para gerenciar este sinal.*
