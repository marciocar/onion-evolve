# Probe — PreModelSwitch/PostModelSwitch disparam? (medido 2026-09-02)

Sonda não-bloqueante registrada em .claude/settings.json (exit 0, só log), sessão interativa reiniciada de 2.1.247 → 2.1.258, maestro trocou Opus 5 → Fable 5.1 pelo picker. Sonda REMOVIDA após a medição (o adopt copia .claude/ — não pode propagar). Linhas do log, verbatim:

```
2026-09-02T12:56:07+00:00 | {"session_id":"a331b306-887c-4fed-990f-0e08a8cc6a10","transcript_path":"/home/marcio/.claude/projects/-home-marcio-onion-evolve/a331b306-887c-4fed-990f-0e08a8cc6a10.jsonl","cwd":"/home/marcio/onion-evolve","scratchpad_dir":"/tmp/claude-1000/-home-marcio-onion-evolve/a331b306-887c-4fed-990f-0e08a8cc6a10/scratchpad","prompt_id":"292ec053-1d40-436b-8db0-33f65d258043","hook_event_name":"PreModelSwitch","from_model":"claude-opus-5[1m]","to_model":"claude-fable-5-1","requested_model":"claude-fable-5-1[1m]","source":"picker","context_tokens":156746,"prompt_cache_warm":true,"cache_ttl":"1h","estimated_cache_write_usd":3.1349,"pricing":"catalog"}
2026-09-02T12:56:07+00:00 | {"session_id":"a331b306-887c-4fed-990f-0e08a8cc6a10","transcript_path":"/home/marcio/.claude/projects/-home-marcio-onion-evolve/a331b306-887c-4fed-990f-0e08a8cc6a10.jsonl","cwd":"/home/marcio/onion-evolve","scratchpad_dir":"/tmp/claude-1000/-home-marcio-onion-evolve/a331b306-887c-4fed-990f-0e08a8cc6a10/scratchpad","prompt_id":"292ec053-1d40-436b-8db0-33f65d258043","hook_event_name":"PostModelSwitch","from_model":"claude-opus-5[1m]","to_model":"claude-fable-5-1","requested_model":"claude-fable-5-1[1m]","source":"picker","context_tokens":156746,"prompt_cache_warm":true,"cache_ttl":"1h","estimated_cache_write_usd":3.1349,"pricing":"catalog"}
```

## Pré-condição descoberta na medição

A 1ª tentativa (antes do reinício) não disparou nada: a sessão rodava o binário 2.1.247 (**deletado do disco** pelo auto-updater; disco já em 2.1.258) e os eventos nasceram em 2.1.251. O picker mostrava 'Fable 5.1 (disabled) — Update to 2.1.255+' num sistema já atualizado: o picker reflete a versão do PROCESSO, não do disco. Sessões abaixo de 2.1.255 medidas naquele momento: PIDs 466218/596690 (2.1.247), 769133 (2.1.246), 1418393 (2.1.252).

## Observações (não conclusões)

- `requested_model: claude-fable-5-1[1m]` mas `to_model: claude-fable-5-1` — o sufixo [1m] pedido não sobreviveu à resolução; a mensagem do picker no binário velho dizia 'claude-fable-5-1[1m]' e no novo 'Fable 5.1'.
- `estimated_cache_write_usd: 3.13` com `context_tokens: 156746`: a troca invalida o prompt cache — custo que uma guarda pode gatear. `pricing: catalog` confirma o achado da pesquisa (custo é catálogo).
- O binário 2.1.258 contém 'model switch blocked by a PreModelSwitch hook' e 'A PreModelSwitch hook asked you to confirm' — o Pre pode VETAR ou pedir confirmação, não só registrar.
