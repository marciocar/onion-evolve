# Voz do Cliente

> ⚠️ **Gap conhecido:** o Onion não tem base de clientes externos ainda. Este arquivo é **N=1 (maestro) + 4 adotantes de campo + sinais da pesquisa**, não voz-de-mercado. Enriquecer quando houver campo. Majoritariamente `[INFERIDO]`.

---

## Temas de elogio (o que gera valor)

- **Contexto explícito acaba com retrabalho** — o efeito medido (40%↓erro, 55%↑veloc com contexto bem mantido — Anthropic) é o núcleo do valor percebido.
- **Continuidade** — workflows faseados retomáveis; pausar/retomar sem perder o fio (validado no dogfood, ex.: `/catch-up`, sessions).
- **Auto-evolução** — o framework se audita e se corrige; adotante de campo achou+corrigiu bug do core (prova viva). `[INFERIDO como diferencial percebido]`

## Reclamações frequentes / atrito

- **Curva de entrada** — 3 dimensões, muitos comandos/agentes; "qual uso agora?" (mitigado por `/onion`, mas real).
- **Claude Code-only** — barreira para quem usa outras ferramentas (é escolha deliberada, mas custa alcance).
- **Complexidade para leigo** — bloqueia P6 (Onion Pessoal) inteiramente hoje.

## Padrões de pedido (feature requests)

- Facilitação / onboarding do mini (o próprio maestro pediu — "entrega gradual totalmente facilitada").
- `[TO BE COMPLETED — sem base externa]`

## Comparações competitivas (como o cliente compara)

- vs **Claude Code puro**: "dá estrutura, papéis e continuidade que o puro não dá".
- vs **Spec Kit / Agent OS / SuperClaude / BMAD**: "esses cobrem engenharia; o Onion cobre também produto e **compliance** como pares". (Whitespace — ver `strategy.md`.)

## Terminologia do cliente (léxico Onion)

Termos nativos que a IA **deve** usar com este público: _maestro_, _dogfood_, _spec-as-code_, _dimensões peer_, _workflow faseado retomável_, _federação_, _adotante_, _doutrina_, _co-evolução_, _SSOT_, _SDAAL_, _worklog_.

**Evitar:** jargão de "produto SaaS" (assentos, MRR) enquanto o modelo comercial não estiver decidido (`D1`); prometer distribuição pública (é privado).

## Padrões de comunicação

- Idioma: **pt-BR** para chat/docs/mensagens; inglês para código/commits (`language-standards`).
- Tom: direto, denso, técnico; evidência acima de afirmação.

---

_§template: o adotante popula isto com issues, suporte, reviews e depoimentos reais dos seus clientes._
