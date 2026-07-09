# 🧩 interface — federation-transport (ITransport)

> Contrato SDAAL: **o quê** o transporte faz. O *adapter* define o **como**. A cognição do LLM "executa"
> esta spec tipada (ver `docs/knowledge-base/concepts/specification-driven-ai-abstraction-layer.md`).

```typescript
/** Um sinal de co-evolução em trânsito (upstream=projeto→core · downstream=core→projeto). */
interface Signal {
  id: string;                 // <AAAA-MM-DD>-<slug> (estável, dedup)
  direction: 'upstream' | 'downstream';
  from: string;               // member id emissor
  to: string;                 // member id destinatário
  kind: 'signal' | 'announce' | 'report' | 'ack';
  classification: 'public' | 'protected' | 'peer' | 'downstream' | 'collective';  // trust/types.md
  body_path: string;          // markdown do envelope (o conteúdo NÃO viaja tipado — é doc)
}

interface DeliveryResult {
  transport: TransportKind;   // via usada (types.md)
  delivered: boolean;         // entregue no canal do destino?
  committed: boolean;         // SEMPRE false p/ entrega-sem-commit (I3) — o destino commita
  gated: boolean;             // aceitação pendente do gate humano/tipo (nunca auto-aplica)
  note: string;
}

interface ITransport {
  /** Resolve a via p/ um membro (delega a detect-transport.sh — determinístico). */
  detect(memberId: string): TransportKind;

  /** Entrega um sinal ao destino pela via resolvida. NUNCA commita no repo alheio (I3);
   *  NUNCA auto-aplica (gated:true até o gate humano). Idempotente por Signal.id. */
  deliver(signal: Signal): DeliveryResult;

  /** Coleta sinais recebidos (poll do canal local — git-async/local) ou entregues via webhook (a2a-live).
   *  Read-only: não muta estado do emissor. */
  receive(memberId: string): Signal[];
}
```

## Regras invariantes (herdadas de RFC-0001/0004)

1. **`deliver` nunca faz `commit` no repo do destino** — entrega-sem-commit (I3); o destino commita/tria.
2. **`deliver` nunca auto-aplica** — `gated:true` até o gate humano/tipo (`members.yaml` = policy).
3. **Fail-safe** (federation-check): sem gate válido / sem output tipado = veto (não entrega como aprovado).
4. **git-async é o fallback** de `deliver`/`receive` se a via resolvida falhar (degrada, não quebra).
5. **a2a-live** só transporta `Signal` (sinal gated), **nunca** conversa autônoma agente↔agente.
