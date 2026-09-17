# Esqueleto de Repo-por-Ferramenta VPS — Knowledge Base

> **Versão**: 1.0.0 | **Última atualização**: 2026-08-05 | **Categoria**: Tools
> Convenção **existente** do repo-por-ferramenta VPS, registrada a partir da referência viva
> (`onion-vps-logto`) — não inaugura padrão, documenta o que já é praticado. Irmã da
> [Doutrina do Catálogo VPS](../concepts/onion-vps-catalog-doctrine.md) (a doutrina decide *o que entra*;
> este esqueleto descreve *como o repo do serviço se estrutura*).

Convenção **existente** para o repo de cada ferramenta compartilhada da VPS do core (`srv1812846`),
documentada aqui a partir da referência viva. Este documento não inaugura o padrão — ele o registra
para que o próximo repo-de-ferramenta nasça reto sem reconstruir a decisão do zero.

**Referência viva**: `/home/marcio/onion-vps-logto/` (fora deste repo — instância
local, não submódulo). Todo exemplo abaixo é citado dali. Quando este documento e o repo divergirem,
**o repo vivo é a fonte de verdade**; atualize este KB para refletir a divergência.

---

## 1. Onde isto se encaixa (framing F0)

A VPS é **catálogo**, não plataforma: soma de N ferramentas justificadas 1-a-1 por demanda
(pull-not-push), nunca um backend próprio (docs/onion/graph/vps-shared-tools-2026-07.kg.yaml,
nó `D_framing_catalogo`). Cada ferramenta compartilhada passa pelo **Teste-do-Eixo** SDAAL
([onion-abstraction-doctrine.md](../concepts/onion-abstraction-doctrine.md)): se há troca de provider
justificada, vira adapter (`.env`-roteado, como task-manager/forge); se não, é um **script-gated**
atrás do bridge. Este esqueleto governa o **repo de infraestrutura** da ferramenta em si — o processo
que sobe o serviço, guarda seus segredos e o mantém em dia — **não** o lado Onion da integração.

### 1.1 Dois artefatos distintos — não confundir

| | Esqueleto repo-por-ferramenta (este doc) | Adapter SDAAL (`integrations.md` §2) |
|---|---|---|
| **Governa** | o repo do **serviço** (infra: subir, versionar, migrar, cifrar segredo, fazer backup) | o **consumo** do serviço a partir do Onion (`.claude/utils/<dominio>/`) |
| **Vive em** | repo próprio, um por ferramenta (`onion-vps-logto`, `onion-vps-waha`, …) | dentro do repo Onion consumidor, em `.claude/utils/` |
| **Roteamento** | nenhum — cada repo é UMA ferramenta, sem troca de provider dentro dele | `factory.md` lê `<DOMINIO>_PROVIDER` do `.env` e escolhe o adapter |
| **Exemplo** | `onion-vps-logto/docker-compose.yml`, `up.sh`, `logto-provision.sh` | `.claude/utils/task-manager/adapters/jira.md` |
| **Pergunta que resolve** | "como este serviço sobe, atualiza e não vaza segredo?" | "qual provider está ativo e como o Onion fala com ele?" |

Um serviço pode ter os dois ao mesmo tempo (ex.: Logto tem o repo-esqueleto **e**, quando o bridge
o consome como IdP, um adapter do lado Onion) — são camadas ortogonais, não uma escolha exclusiva.

### 1.2 Convenção de nomenclatura — prefixo `onion-vps-`

Serviços do padrão-VPS (Onion + infraestrutura de casa) usam o prefixo **`onion-vps-`** em **tudo o
que os nomeia** — container, serviço systemd **e o repo**: `onion-vps-waha`, `onion-vps-logto`,
`onion-vps-logto-postgres`, `onion-vps-vaultwarden`, `onion-vps-bridge`,
`onion-vps-docker-firewall`. Distingue de:

- `onion-adopt-<nome>-*` — recursos de um adotante específico hospedado na mesma VPS;
- nomes próprios do adotante (recursos com nome próprio do adotante não levam prefixo `onion-`).

Convenção adotada em 2026-08-05 pelo maestro.

> **CORREÇÃO 2026-08-10 — a assimetria caiu, e ela era um erro deste documento.** A v1.0.0 declarava
> que o *container* levava `onion-vps-` mas o *repo* era `onion-<ferramenta>`, e chamava isso de
> "assimetria intencional". Não era: era o padrão descrito pela metade a partir de um único exemplo
> vivo. O maestro corrigiu — **é ferramenta da VPS, o prefixo vale para o nome inteiro**. Os dois
> repos existentes foram migrados (`onion-logto` → `onion-vps-logto`, `onion-waha` →
> `onion-vps-waha`); o retrofit foi feito, não adiado, porque a divergência estava na DOUTRINA e
> doutrina errada replica em cada ferramenta nova.
>
> ⚠️ **A migração tem uma armadilha que quase custou o IdP inteiro, e quem for repetir precisa
> saber:** o Compose deriva o nome do projeto do **nome do diretório**, e os volumes são
> prefixados por ele (`onion-logto_logto-postgres-data`). Renomear a pasta faz o Compose procurar
> um volume que não existe, **criar um vazio, e subir limpo — sem erro nenhum**. A cura é fixar
> `name:` no topo do `docker-compose.yml` **antes** de renomear, o que preserva o projeto e os
> volumes. Verificado por comportamento nos dois: Logto com as 10 aplicações intactas, WAHA com a
> sessão `WORKING`. Bind mounts relativos (`./sessions`) seguem a pasta e não precisam de nada.

---

## 2. O esqueleto

Cada ferramenta compartilhada vive em seu próprio repo, nomeado `onion-vps-<ferramenta>` (ex.:
`onion-vps-logto`), com esta forma mínima:

```
onion-<ferramenta>/
├── README.md              # por quê existe, como está montado, operação, lições
├── docker-compose.yml     # bind 127.0.0.1 sempre; público só via Caddy reverso
├── .env.example           # versionado — placeholders, nunca segredo real
├── .envrc                 # não versionado — direnv, lê do pass em runtime
├── .gitignore             # .envrc, .env, backups/, dumps
├── up.sh                  # idempotente: pass → sudo -E docker compose
├── down.sh                # idempotente: par de up.sh
├── provision.sh           # idempotente, dry-run default, --apply explícito
├── check-version.sh       # relatório de frescor do pin (exit 0/1/2)
├── upgrade.sh              # executa o salto de versão na ordem correta
└── backup.sh               # dump + verificação de integridade + rotação
```

Nem toda ferramenta precisa de todos os arquivos (uma ferramenta sem API de provisionamento não
tem `provision.sh`) — mas os que existem seguem a forma abaixo.

---

## 3. README.md

Estrutura observada em `onion-vps-logto/README.md` (seções, não conteúdo a copiar):

1. **Por quê** — que problema este serviço resolve, por que este host e não um SaaS
2. **Como está montado** — topologia (portas, volumes, rede), o que é público vs loopback-only
3. **Operação** — comandos do dia a dia (`up.sh`, `console.sh`, `backup.sh`, `check-version.sh`)
4. **O que aprendemos com [origem]** (quando o compose foi destilado de outro projeto) — crédito
   explícito + o que se corrigiu ao herdar
5. **O que erramos nesta montagem** — erros reais encontrados em produção, registrados como regra
6. **Por que pin e não `latest`** (quando aplicável) — a decisão de versionamento e seu porquê
7. **Planos** — o que falta, gated ou não
8. **Referências** — runbooks, ADRs, KG nodes relacionados

O README não é changelog nem manual genérico de Docker — é a **narrativa de decisão** do serviço
específico: por que ele está do jeito que está, que incidente moldou cada guarda.

---

## 4. docker-compose.yml — bind 127.0.0.1 sempre

**Regra dura, motivada por incidente real** (`onion-vps-network-exposure-2026-08` (core-only)):
o Docker fura o `ufw` por padrão (injeta regras em `DOCKER-FORWARD` **antes** da cadeia do ufw) —
uma porta publicada sem bind explícito fica exposta à internet mesmo com o firewall de host
"fechado". A contenção perimetral (`DOCKER-USER` default-deny) é rede de segurança, **não** a cura
na fonte. A cura na fonte é o compose:

```yaml
ports:
  - '127.0.0.1:3011:3011'
  - '127.0.0.1:3012:3012'
```

— nunca `'3011:3011'` (que o Docker expande para `0.0.0.0:3011:3011`). O serviço só fica alcançável
de fora do host através de um **reverso público explícito** (Caddy), que decide o quê exportar e com
TLS. Portas administrativas (console, management API) ficam **loopback-only** mesmo quando o serviço
tem um vhost público para outra função (ex.: Logto: `auth.*` público via OIDC, `console.*` desligado
por desenho, acessível só por túnel/`--resolve` quando preciso).

Outras convenções observadas no compose de referência:

- **Container names com prefixo `onion-vps-`** (§1.2)
- **Healthcheck** batendo no bind loopback (`http://127.0.0.1:PORT/...`), nunca em hostname externo
- **Pin de versão explícito** da imagem (nunca `latest`) quando o serviço tem migração de schema —
  ver §6
- **Comentário de proveniência** no topo do arquivo quando o compose foi destilado de outro repo:
  origem, o que foi corrigido, e a lição que sobra (ex.: pin herdado sem questionamento — "ao herdar
  artefato de outro projeto, a versão é parte do que se audita, não um detalhe de transporte")

---

## 5. Segredos — princípio invariante, mecanismo por modelo de serviço

**Princípio da casa, sem exceção:** nenhum segredo em **plaintext em repouso**; leitura **fail-closed**
(faltou o segredo → o serviço NÃO sobe, nunca com default fraco); o segredo **nunca** entra no
artefato versionado (`.env.example` só placeholders).

O **mecanismo** depende de **como o serviço sobe** — porque `pass`+GPG é **interativo** (um humano
destrava a chave) e por isso **não serve** para um serviço que sobe sozinho no boot:

| Modelo de serviço | Mecanismo | Exemplo |
|---|---|---|
| **Humano-rodado** (compose subido por `up.sh`/`direnv`) | **`pass`(GPG) + direnv** — o humano já destravou o GPG na sessão | `onion-vps-logto`, `onion-vps-waha` |
| **systemd não-atendido** (sobe no boot, sem humano) | **systemd encrypted credentials** (`LoadCredentialEncrypted`, decifra com chave do host) — `pass` NÃO se aplica | `onion-vps-bridge` |

> **Não force `pass` num serviço systemd** (premissa medida 2026-08-05): o `onion-vps-bridge` sobe por
> systemd como user `onion`, que não tem GPG destravado no boot. Enquanto for **N=1 operador**, o `.env`
> modo 600 legível só por `onion`/root é **aceito** (sem `docker inspect`, sem rede — risco baixo);
> a migração p/ `systemd-creds` fica **gated** ao gatilho **multi-operador** (ou à janela da limpeza do
> `dual-legacy`, 2026-08-10). Isto é `pull-not-push`: não migrar por simetria com o WAHA.

O detalhe abaixo é o mecanismo **humano-rodado** (o mais comum no catálogo — `pass`+direnv):

- **`.env.example`** — versionado, só placeholders/estrutura (nomes de variável, comentário do que
  cada uma é). Nunca um valor real, nem de dev.
- **`.envrc`** — **não** versionado (`.gitignore`), lido por `direnv` para a sessão de humano:
  ```bash
  export LOGTO_DB_PASSWORD="$(pass show onion/logto-db-password)"
  export SECRET_VAULT_KEK="$(pass show onion/logto-secret-vault-kek | head -1)"
  ```
  `direnv allow` no diretório carrega automaticamente; a variável nunca é literal no arquivo.
- **`up.sh`** repete a mesma leitura para uso não-interativo (agente, cron, CI) sem depender de
  `direnv` estar carregado na shell do chamador — ver §6.
- **`.gitignore`** cobre `.envrc`, `.env` e qualquer diretório de dump/backup (`backups/`) — um
  dump de Postgres de um IdP contém hashes de credencial e nunca deve entrar no git.

---

## 6. up.sh / down.sh — idempotentes, fail-closed

Modelo (`onion-vps-logto/up.sh`, verbatim):

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
export LOGTO_DB_PASSWORD="$(pass show onion/logto-db-password)"
export SECRET_VAULT_KEK="$(pass show onion/logto-secret-vault-kek | head -1)"
if [ "$#" -eq 0 ]; then set -- up -d; fi
exec sudo -E docker compose "$@"
```

Pontos que valem a pena reter como padrão, não acidente de implementação:

- **`${VAR:?}` / leitura direta do `pass` sem fallback** — se o `pass show` falhar (entrada
  ausente, GPG bloqueado), o `set -e` interrompe antes de subir o serviço com segredo vazio ou
  default fraco. **Fail-closed**, nunca silenciosamente inseguro.
- **`sudo -E`** propaga as variáveis exportadas para o `docker compose` rodando como root (Docker
  na VPS roda via `sudo`) — sem `-E`, o compose não veria os segredos exportados.
- **`set -- up -d` como default, preservando `"$@"`** — permite `./up.sh logs -f` ou
  `./up.sh down` reusando o mesmo script para qualquer subcomando do compose, sem duplicar a
  lógica de leitura de segredo. O comentário no próprio script registra um bug já corrigido:
  `"${@:-up -d}"` colapsava em um único token e o compose rejeitava o comando — `set --` é a forma
  que preserva o splitting de argumentos corretamente.
- **`exec`** no comando final — substitui o processo shell em vez de spawnar um filho, para sinais
  (Ctrl-C, timeout de orquestrador) chegarem ao `docker compose` direto.

`down.sh` é o par simétrico (mesma leitura de segredo se o compose exigir, `docker compose down`).
Ambos são **idempotentes**: rodar `up.sh` sobre um stack já no ar não duplica nem quebra.

---

## 7. provision.sh — idempotente, dry-run default, `--apply` explícito

Quando a ferramenta expõe uma API de administração que o Onion precisa provisionar (usuários, apps,
scopes), o provisionamento é um script separado do `up.sh`, seguindo o modelo de
`ops/bridge-auth/logto-provision.sh` (deste repo, não do `onion-vps-logto/` — ele provisiona o *consumo*
do Logto pelo bridge):

- **Uso**: `bash provision.sh [--apply] [outras flags]` — **sem `--apply` é dry-run**: mostra o que
  faria, não muta nada. Só `--apply` executa.
- **Idempotente por construção**: cada passo **consulta antes de criar** (ex.: "esse app M2M já
  existe? se sim, não recria"). Rodar de novo não duplica recurso.
- **Templates verbatim provados por diff vazio** — quando o script gera configuração a partir de um
  template (ex.: um payload JSON para a Management API), o template embutido no script deve ser
  **idêntico** ao que se aplicaria manualmente — provado comparando a saída gerada com uma referência
  conhecida via `diff` vazio, não por inspeção visual.
- **Segredo gerado nunca no stdout/transcript** — quando o script cria uma credencial nova (senha de
  usuário, client secret), ela é escrita **só** num arquivo de permissão restrita (`0600`, dono
  `root`), nunca impressa no terminal nem persistida em log de sessão de agente.
- **Comentário de proveniência do "porquê"** no topo — que alternativa mais óbvia (ex.: "clique no
  console") foi descartada e por quê, com a medição que sustentou a decisão.

---

## 8. backup.sh

Modelo (`onion-vps-logto/backup.sh`):

- **Uso**: `./backup.sh [rótulo]` — rótulo default (`diario`) para cron; rótulo explícito
  (`pre-upgrade`) para backups que não devem expirar.
- **Nome do arquivo carrega a versão do serviço no momento do dump** (`logto-1.41.0-diario-<ts>.sql`)
  — permite restaurar sabendo contra qual schema o dump foi tirado.
- **Verificação de integridade pós-dump** — um dump que não teria como restaurar não é backup;
  o script confere um marcador mínimo esperado no output (ex.: `grep -q 'CREATE TABLE public.users'`)
  e falha alto (`exit 1`, mensagem explícita) se o dump saiu suspeito, em vez de reportar sucesso
  cego.
- **Retenção diferenciada**: dumps rotulados (`diario`) envelhecem e rotacionam (ex.: manter os
  últimos 14); dumps com rótulo especial (`pre-upgrade-*`) **nunca** são apagados pela rotação
  automática.

---

## 9. check-version.sh / upgrade.sh

Par que resolve o mesmo problema que motivou o pin de versão no compose (§4): **pin sem verificador
envelhece em silêncio**; `latest` troca isso por upgrade sem decisão — nenhuma das duas é aceitável
sozinha.

- **`check-version.sh`** — relatório de frescor do pin: compara a versão fixada no compose contra a
  mais recente disponível upstream, reporta quantos releases de distância e o que mudou no meio.
  Contrato de saída pensado para automação: `--quiet` (só fala se atrasado, para rodar via cron) e
  **exit code semântico** — `0` em dia, `1` atrasado, `2` não conseguiu consultar (rede/API fora,
  não confundir com "está em dia").
- **`upgrade.sh`** — executa o salto de versão **na ordem correta** do serviço (ex., para o Logto:
  troca de imagem → `db alteration deploy` → restart). Existe precisamente porque, para serviços com
  migração de schema, pular a ordem correta — ou rodar migração dentro do próprio entrypoint de start,
  em vez de como etapa explícita anterior — já causou indisponibilidade real em produção (lição
  herdada de outro projeto, registrada no README da referência viva).

---

## 10. .gitignore

Mínimo observado: `.envrc`, `.env`, e qualquer diretório de artefato sensível gerado em runtime
(`backups/` — dumps de banco). O critério: **nada que contenha segredo ou dado de identidade real
entra no git**, mesmo que o repo em si não seja público.

---

## 11. Quando NÃO usar este esqueleto

- Ferramenta que **não** passa no Teste-do-Eixo como serviço hospedado — se é consumida via SaaS de
  terceiro sem componente rodando na VPS, isso é um adapter SDAAL puro (§1.1), sem repo-esqueleto.
- Script-gated simples (ex.: provisionamento de e-mail via `logto-provision.sh --smtp`) que não sobe
  um serviço próprio — vive dentro do repo consumidor (`ops/`), não em repo dedicado.

---

## 12. Não retrofitar por simetria

Este esqueleto descreve uma convenção **existente**, extraída da referência viva. **Não** é gatilho
para reescrever repos-de-ferramenta já criados só para bater 100% com esta lista — isso é cerimônia,
não capacidade ganha. Aplique o esqueleto (ou a correção de uma peça faltante, como o prefixo
`onion-vps-` de §1.2) **no próximo toque real** daquele repo — quando ele for tocado por outro motivo
(upgrade, incidente, nova feature) — nunca como uma varredura dedicada de "alinhar tudo agora".

---

## Referências

- [`onion-abstraction-doctrine.md`](../concepts/onion-abstraction-doctrine.md) — Teste-do-Eixo SDAAL
- [`integrations.md`](../../meta-specs/integrations.md) §2 — estrutura obrigatória de adapter
  (o lado Onion, ver §1.1 deste doc para a distinção)
- `docs/onion/graph/vps-shared-tools-2026-07.kg.yaml` — F0 framing catálogo (nó `D_framing_catalogo`)
- `onion-vps-network-exposure-2026-08` (core-only) — incidente que motivou a regra de bind
  `127.0.0.1` (§4)
- `onion-adr-sdaal-nested-two-level-2026-07` (core-only) — recursão canal→solução (contexto de
  quando um domínio vira adapter aninhado, ex. `MESSAGING_PROVIDER`/`MESSAGING_WHATSAPP_PROVIDER`)
- `/home/marcio/onion-vps-logto/` — referência viva citada em todo este documento
- `/home/marcio/onion-evolve/ops/bridge-auth/logto-provision.sh` — referência de `provision.sh`
  (lado Onion consumidor, não o repo-esqueleto)
