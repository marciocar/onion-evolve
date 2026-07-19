# Manuseio de Segredos pelo Agente — nunca em texto claro no chat

> **Origem (crédito):** uma instância adotante (T1 hub), aplicado ao vivo em 2026-07-03
> (instalação com sudo + dump de RDS de produção) — sinal upstream
> `docs/evolution/inbox/_processed/2026-07-03-secret-handling-pattern.md`. Triado e promovido pelo
> core em 2026-07-03. Spec no espírito SDAAL: markdown executável — o agente lê e segue.

## A regra dura

**O agente NUNCA solicita nem aceita segredos em texto claro na conversa** (senhas, tokens,
chaves). Uma vez digitado no chat, o segredo persiste no transcript, no histórico de shell e em
logs — vaza mesmo se apagado depois. O agente **projeta o fluxo para não precisar ver o segredo**.

## Receituário (ordem de preferência)

1. **Capability-split (preferido):** o passo privilegiado roda **no terminal do usuário** (o
   segredo nunca sai de lá); o agente faz todo o resto. Ex.: usuário roda `sudo apt install …`;
   o agente roda o `pg_dump` (que não exige sudo). É o "ato 3" (gate humano) aplicado a privilégio:
   a ação sensível é deliberada, do humano, com migalha de rastreio.
2. **Terminal real para prompt interativo:** shell de agente / `!` sem TTY **não consegue** pedir
   senha (`sudo: a terminal is required`) — prompt interativo de segredo só em terminal do usuário.
3. **Credencial em cache / curta duração:** `sudo -v` (cache ~15 min, por-tty) ou token efêmero —
   o agente opera na janela sem ver o segredo. Ressalva: `tty_tickets` pode não compartilhar cache
   entre o shell do usuário e o do agente.
4. **Segredo fora-de-banda:** ler de fonte protegida (`.env` restrito, variável de ambiente,
   secret manager) — o agente referencia a **fonte**, nunca imprime o valor.
5. **Container como isolador:** ferramenta privilegiada/versão específica dentro de container
   (ex.: `docker run postgres:16 pg_dump …`) — evita instalação com sudo E resolve versão.

## Anti-padrões (o agente NÃO faz)

- Pedir "me passa a senha" / aceitar senha colada no chat.
- `echo '<senha>' | sudo -S …` montado pelo agente (segredo entra em comando + histórico).
- Guardar segredo em memória persistente, variável de conversa ou arquivo versionado.
- Imprimir o valor lido de `.env`/ambiente em output, log ou commit.

## Checklist-gate (reusável em qualquer comando/agente)

> Precisa de segredo? → **capability-split primeiro** → prompt interativo? terminal real →
> tooling faltando? container → só então fonte fora-de-banda — e **nunca** texto claro no chat.

## Relações

- **Gate humano (ato 3):** ação privilegiada em produção é deliberada e do maestro — este padrão
  é a projeção disso para credenciais.
- **Governança DEV↔PROD** ([knowledge-graph-sdaal](knowledge-graph-sdaal.md)): operação
  privilegiada no plane PROD sempre com migalha de rastreio.
- **Fallback gracioso** (CLAUDE.md §Task Manager): "não inventar valores" é o mesmo princípio —
  a variável ausente se reporta, nunca se fabrica; aqui, o segredo ausente se contorna por
  desenho, nunca se pede.
