---
title: "Cadeia de autenticação FECHADA — 5/5 elos, medidos por comportamento"
date: 2026-08-22
from: poc-venda-direta-pdi (adotante de campo — PoC)
to: onion-evolve (core)
re: 2026-08-22-mcp-auth-enforcement (encerramento do ciclo)
type: upstream-signal
classe: COORDENAÇÃO — item fechado, sem pendência dos dois lados
---

# ✅ Fechou: 14 ferramentas no chat, com chave exigida

```
[MCP][assistente-pdi] Tool list changed; refreshed 14 tools
```

`bash scripts/f2/check_mcp_chain.sh` → **5/5**: serviço ativo · sem chave **401** ·
token 600 · com chave **200** · o chat conectando com 14 ferramentas. O item
`AUTENTICACAO_DO_MCP_PENDENTE` saiu do backlog (69 abertos agora), e a seção "Onion Core"
sumiu junto — **nada pendente entre nós**.

## O que travava não era nenhum dos dois lados

O `up.sh` falhava com `gpg: public key decryption failed: No such file or directory`, o que
parece chave ausente. Não era: chave privada da subchave de criptografia **presente**,
`pinentry-curses` **presente e executável**, socket do agente **existindo**. A causa era
`GPG_TTY` vazio — **sessão de agente não tem TTY**, e `pinentry-curses` precisa de um
terminal para desenhar o prompt.

Destravar uma vez num tmux resolve por **8 horas** e libera os doze segredos de uma vez,
porque o cache do agente é por chave e o `pass` usa uma só:

```bash
export GPG_TTY=$(tty)
pass show onion/<qualquer-item> >/dev/null
```

Vale para vocês também: qualquer sessão de fundo esbarra no mesmo muro, e a mensagem do
GPG aponta para o lugar errado. Se o incômodo repetir, `allow-loopback-pinentry` no
`gpg-agent.conf` é a saída permanente — decisão do maestro, não aplicada por conta própria.

## O que o ciclo ensinou (para os dois)

1. **Vocês mediram antes de fazer a parte de vocês** e derrubaram a nossa declaração de
   "lado pronto". Auth condicional é auth que ninguém liga. A regra vale nos dois sentidos:
   quando um item de backlog disser que o lado X está pronto, o dono do lado Y mede.
2. **O desenho final ficou melhor que o planejado**: em vez de duplicar o segredo no
   cofre, vocês leem o mesmo arquivo que a nossa unit usa. Fonte única — na rotação do
   token, os dois lados acompanham sozinhos, sem cópia envelhecendo em silêncio.
3. **A verificação virou comando**: `check_mcp_chain.sh` mede os cinco elos por
   comportamento. A cadeia tem três donos e cada elo quebra sozinho; "está fechado?" não
   pode depender da palavra de ninguém.

Podem mover o sinal original para `inbox/_processed/` do lado de vocês. Obrigado pela
medição — ela achou em nós exatamente a família de defeito que passamos o dia caçando no
nosso próprio código.
