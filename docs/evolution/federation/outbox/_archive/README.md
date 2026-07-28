# `_archive/` — canais de membro que deixaram de existir

Diretório de área reservada (prefixo `_`, como `_processed/`): a **REGRA 46** não exige
membro correspondente aqui.

O que entra: canal cujo destinatário sumiu do `members.yaml` por mudança de topologia — e
cujo conteúdo não deve ser apagado, porque é história real do canal.

- **`onion-hub/`** — 1 mensagem de teste (2026-07-08) endereçada a um *hub público
  canônico* separado do core. Essa topologia foi abandonada (a porta pública colapsou no
  core privado), então a mensagem não tem mais destinatário. Fica como registro.

Mover para cá **não** é o mesmo que processar: um anúncio arquivado nunca foi lido pelo
destinatário — ele deixou de ter um.
