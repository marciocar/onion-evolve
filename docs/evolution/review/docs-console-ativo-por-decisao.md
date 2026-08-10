---
branch: docs/console-ativo-por-decisao
reviewed_at: 2026-08-10
reviewed_diff_sha256: 4a89fa0472e94c1b039b693ede65601d58825a441c0350c2808823f61cbceec9
---

# O console fica ativo por decisão — e duas declarações viraram mentira

O maestro decidiu manter `console.onionevolve.com` no ar. **Não é brecha a tapar.** Mas torna
**falsas** duas afirmações que estavam no repo e em produção, ambas escritas enquanto o vhost
respondia `302`:

| onde | dizia |
|---|---|
| `/etc/caddy/conf.d/logto-console.caddy` | *"Fica DESLIGADO por padrão"* |
| `ops/bridge-auth/logto-provision.sh` | *"o vhost console.onionevolve.com está DESLIGADO por desenho"* |

**Declaração que contradiz o vivo é pior que ausência de declaração**: quem lê decide com base nela.
E o custo já se materializou nesta sessão — eu quase apresentei o console aberto ao maestro como
incidente, porque três documentos me diziam que ele deveria estar fechado.

## A ocorrência que eu NÃO mexi

`console.sh:36` — `echo "✓ console DESLIGADO — $URL não responde mais"`. É a **mensagem de saída da
ação `off`**, não afirmação de estado. Está correta e continua.

Decidir uma a uma em vez de varrer é o ponto: varredura mecânica não sabe qual ocorrência é
deliberada. Foi assim que uma varredura anterior desta mesma sessão quase inseriu um helper
exatamente onde a **ausência** dele era o teste.

## O argumento do `logto-provision.sh` sobrevive intacto

Vale registrar porque a tentação é o contrário: o script **não existe porque o console estava
fechado**. Existe porque provisionar por API é **reprodutível, auditável, versionado e idempotente**,
e clicar não é. Console aberto não enfraquece isso em nada — o script segue sendo o caminho certo.

## O que de fato muda: o raio da senha de admin

Com o painel alcançável da internet, a senha de admin do Logto vira **a credencial de maior alcance
da caixa** — plano de controle da identidade (criar apps, usuários, conectores).

E o que ela **não** alcança, medido nesta sessão:

- **não abre o cofre** — a chave de cifra do Vaultwarden deriva da senha mestra **no cliente**;
- **não alcança os segredos do bridge** — `ANTHROPIC_API_KEY` e `PERMISSION_MODE` são do serviço.

O Logto responde *quem é você*, nunca *o que você pode decifrar*. É exatamente essa fronteira que
torna a decisão defensável — e por isso ela agora está escrita nos dois arquivos, no lugar da
afirmação falsa.

## Declarado, e não coberto

O Logto OSS permite **uma só conta de administrador** (sem multi-admin). Com o console público, isso
concentra o plano de controle numa credencial única — não é regressão introduzida aqui, é limite do
produto que a decisão torna mais relevante.
