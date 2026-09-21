# 🔬 Harness Leg-1 — dogfood de telemetria de sessão

> Aparato **reproduzível** do estudo `interface-state-of-art` (NOTE-05 + NOTE-06). **Não é código de produto** —
> é o instrumento pra rodar a Leg-1 (provar que o *loop* observa recorrência de atrito). Versionado aqui só para
> durabilidade; as capturas (dados de sessão) **não** são versionadas (ver `.gitignore`).

## Os 3 scripts

| Arquivo | O quê |
|---|---|
| `otlp_sink.py` | Sink OTLP/HTTP-JSON local (~50 linhas, sem deps). Escuta `127.0.0.1:4318`, de-chunka, grava ndjson por sinal. Local-first — nada sai da máquina. |
| `leg1-claude.sh` | Wrapper que abre `claude` **INTERATIVO** instrumentado (só estrutura; conteúdo OFF). Uma execução = uma sessão. |
| `leg1_analyze.py` | Análise na **ordem fixa** do pré-registro (NOTE-06 §2): passo-0 filtro `claude_code.*`/`gen_ai.*` → baseline por-sessão → recorrência (≥3 sessões) → held-out. Heurístico de loop **v2** (episódio de ferramentas, não span-name — NOTE-06 §8). |

## Fluxo (rode você mesmo)

Caminhos relativos à **raiz do repo**. `H=docs/discussions/interface-state-of-art/harness`.

**1. Suba o sink** (uma vez; deixa rodando):
```bash
H=docs/discussions/interface-state-of-art/harness
python3 "$H/otlp_sink.py" "$H/capture" &
ss -ltn | grep :4318   # confirma LISTENING
```

**2. Para cada sessão** (num terminal separado, no diretório onde vai trabalhar de verdade):
```bash
/ABS/PATH/AO/REPO/docs/discussions/interface-state-of-art/harness/leg1-claude.sh
# → claude interativo instrumentado. Faça trabalho REAL e VARIADO, com gates reais. Feche. Repita.
```
> **Pré-registro (NOTE-06):** N≥4 = **3 descobrem** + **≥1 held-out confirma**. Tarefas **distintas**. Bater em
> gates reais é o que gera `blocked_on_user` (headless flatlina — NOTE-05 achado A). Conteúdo fica OFF: intake=estrutura.

**3. Analise** (quando ≥4 sessões caírem):
```bash
python3 "$H/leg1_analyze.py" "$H/capture"
```
Depois: **refutador obrigatório** (NOTE-06 §4) sobre qualquer candidato — só sobrevive o que resiste a "é o atrito do Marcio, não um padrão".

## ⚠️ O flush, e por que `/exit` importa (medido 2026-09-21)

Na **1ª rodada interativa real**, 5 sessões produziram **apenas** `claude_code.session.count` — zero
traces, zero `blocked_on_user`, zero `tool_decision`. No mesmo dia e mesmo sink, 5 sessões **headless**
trouxeram os três sinais.

A diferença **não é o binário**: o 2.1.278 tem `TracerProvider`, `startSpan`, `BatchSpanProcessor` e os
nomes dos sinais (medido com `strings`). É o **encerramento** — processo headless *termina* e o SDK
descarrega o buffer; sessão interativa *fechada* pode morrer antes do flush periódico.

- os intervalos caíram de **5000/3000 ms → 1000/500 ms** para encurtar a janela de perda;
- **saia com `/exit`**, não fechando o terminal: `SIGKILL` mata o buffer e o dado da sessão **se perde**;
- e o analisador agora **sai com `rc=2`** se ler 0 sessões, em vez de imprimir "nenhum atrito". Captura
  perdida e loop-sem-atrito **não podem sair iguais** — o segundo é a conclusão que este estudo testa.

## Limites (declarados)

- **Interativo-only**: `-p` headless serve só pra validar o instrumento, **não** conta como sessão Leg-1.
- **Intra-órbita**: sessões do Marcio têm independência fraca (NOTE-06 §5). N≥4-Marcio prova "o padrão do Marcio", não geral.
- **Loop v2 não decide stuck-vs-produtivo sozinho** — o refutador é o backstop.
- Mesmo Leg-1 OK **não** promove os invariantes (isso é Leg-2, estudo à parte).
