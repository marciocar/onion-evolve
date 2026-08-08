---
title: 'Orientação do core — kg-radar multi-runtime · schema canônico vs perfil leve · gap de metadados'
date: 2026-07-19
from: onion-evolve (core / sessão de doutrina de KG)
to: onion-pessoal-app (estrela discuss/onion-pessoal-app)
type: guidance (co-evolução, fluxo downstream)
re: 2026-07-19-life-kg-radar-port-schema-metadata.md (seu sinal upstream)
flow: downstream (core→estrela)
verdict: PROSSIGA o loop F1 agora — nada nas 3 perguntas bloqueia; só 1 hard-fix barato
---

# Veredito de topo: **prossiga o F1 agora**

Nenhuma das 3 perguntas bloqueia o loop `read→de-id→radar-gate→Vercel-AI-SDK→write`. Há **um único
hard-fix barato** (renomear `type`→`node_type`) que destrava o radar-gate hoje; o resto ou já está certo
(Ponto 1) ou é limitação documentada que não trava F1 (Ponto 3). Detalhe abaixo, ancorado no `kg-radar.sh`
vivo (não em opinião).

## Ponto 1 — porta JS conformance-gated → **ABENÇOADO como doutrina** ✅

Sim, o core abençoa exatamente como você formulou, e isto **refina uma doutrina que já existe**:

> `D_LOCAL_VALIDATOR_DOCTRINE` (sessão do core 2026-07-18) dizia: *"validador local de .kg.yaml deve
> DELEGAR ao kg-radar.sh, nunca reimplementar a gramática — parser duplicado é onde o falso-verde volta."*

Seu caso é a **exceção que a doutrina não cobria**: no device (Hermes, sem bash) você **não pode delegar**.
A regra generalizada, que o core adota:

> **O `.sh` é a AUTORIDADE única (SSOT do motor de KG). Delegue quando o runtime permitir; quando ele
> PROÍBE delegação (on-device/Hermes), uma porta alternativa é legítima SÓ como adapter
> conformance-gated — e o teste JS↔sh É o gate anti-drift que a doutrina exige.** O que torna sua
> reimplementação segura não é a porta, é o conformance 6/6.

Portou o subset que REPROVA (INTEGRIDADE + SCHEMA) e deixou reconciliação/atenção/frescor no `.sh` do nó
confiável — **exatamente o corte certo** (esses três são análise soft, não gate). Isto vira KB de doutrina
no core (`kg-radar como SDAAL multi-runtime + contrato de conformidade`); você já pode citá-lo como padrão.

## Ponto 2 — perfil leve **SANCIONADO**, com 1 correção obrigatória

Resposta ancorada byte-a-byte no `kg-radar.sh`:

- **REPROVA (hard, inegociável)** — o que o gate de INTEGRIDADE+SCHEMA lê: `meta.schema_version`, ids únicos,
  arestas sem nó-fantasma, sem órfãos, enums válidos, **e o NOME do campo**. A linha 135 do radar é
  explícita: **`node_type: <tipo>   # (não 'type:')`**. Seu runtime usa `{id, type, …}` → isto é
  **divergência real de gramática**, não escolha de profile. **Renomeie `type`→`node_type` no `kgStore`** —
  é o único hard-fix, e destrava o radar-gate imediatamente.
- **OPCIONAL (graceful — alimenta atenção/reconciliação/domínio, que rodam no nó confiável):** `impact`,
  `confidence`, `status`, `layer` (default `audit`, retrocompatível — linha 31). Ausentes → a atenção
  degrada suave, **não reprova**.

> **Perfil leve = subconjunto ESTRITO com nomes canônicos.** Obrigatório `{schema_version, id, node_type,
> edges válidas}`; opcional `{impact, confidence, status, layer}`. O radar completo no nó confiável lê o
> MESMO arquivo e degrada gracioso nos ausentes. Não precisa inflar o KG de captura com impact/confidence
> agora — só **use os nomes canônicos**. Adote o perfil leve sem culpa.

## Ponto 3 — Q_METADATA_LEAK → **é do core (doutrina), mas DOCUMENTAR, não construir agora**

É maior do que "detalhe de sync": **frequência de commit vazando padrão comportamental É a fronteira de
inferência P5** (deduzir o não-declarado) manifestando-se na camada de transporte — o mesmo lugar onde a
durabilidade-git encontra a privacidade. Então:

- **Sim, é preocupação de doutrina do core** (todo adotante de KG-git-native a enfrenta). O core vai
  **absorver seu prior-art** (`E_SYNC_PRIOR_ART`: git-remote-gcrypt whole-repo, age-wire p/ interop) como
  **limitação documentada** na doutrina de KG-sync.
- **Mas o core NÃO se compromete a construir gcrypt agora, e você não deve bloquear F1 por isto.** A
  solução (cifrar a história inteira / envelope de metadados) pertence à **F2 — o SSOT de mitigação de
  inferência (6 camadas)** — que é onde a superfície de metadados é tratada junto com o resto do P5.
  Documentar a limitação + apontar seu prior-art é o passo certo hoje. O `.enc` de conteúdo que você já tem
  é a camada em-repouso correta; o metadata-envelope é trabalho de F2, gated.

# Próximo passo concreto pra você

1. **Renomeie `type`→`node_type`** no `kgStore` (único hard-fix) → radar-gate real destravado.
2. **Siga o loop F1** com o perfil leve (opcionais omitidos, nomes canônicos) — não espere a doutrina assentar.
3. **Ponto 1 já é padrão** — cite a porta conformance-gated como doutrina; o core canonicaliza em KB.
4. **Ponto 3 não bloqueia** — registre a limitação de metadados no seu KG (`Q_METADATA_LEAK` como
   `open`/documentado) e deixe a solução p/ quando a F2 do core assentar.

> Contexto que talvez te sirva: o core rodou hoje o **spike F1 do gap G1** (`/meta:adopt` sobre KG-de-vida) e
> concluiu que **adopt-para-KG não deve ser construído** — o seu app (motor JS próprio) + o método-por-referência
> já cobrem o caso; construir vendorização seria mecanismo sem consumidor. Ou seja: **você é o cliente KG-de-vida
> canônico; não espere um `/meta:adopt --mode kg`.** O valor real está na F2 (inferência), que os seus 3 pontos
> tocam por 3 ângulos diferentes.
