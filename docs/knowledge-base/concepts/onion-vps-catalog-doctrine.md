# Doutrina do Catálogo VPS do Onion — como uma ferramenta entra, vive e sai do catálogo

> **Versão**: 1.0.0 | **Última atualização**: 2026-08-05 | **Categoria**: Conceitos
> Nomeia e consolida o veredito F0 já ratificado (`vps-shared-tools-2026-07.kg.yaml`, nó
> `D_framing_catalogo`) sobre o que a VPS compartilhada **é** e o que ela **nunca vira**. Quarta irmã
> das doutrinas de decisão: [Modernização](onion-modernization-doctrine.md) decide *o que* refatorar;
> [Dogfooding](onion-dogfooding-doctrine.md) decide *como sei que ficou certo*; [Abstração](onion-abstraction-doctrine.md)
> decide *o que merece virar SDAAL*; **esta decide *o que entra na VPS compartilhada, e como***.

---

## 📋 Metadata

| Campo | Valor |
|-------|-------|
| **Versão** | 1.0.0 |
| **Data de Criação** | 2026-08-05 |
| **Categoria** | Conceitos |
| **Origem** | [Elenxo](onion-elenxo-doctrine.md) de framing F0 (2026-07-31, `wf_8a8eca55`, 2 steelman + 1 juiz Opus) → `D_framing_catalogo`; endurecida pela reprovação de F2 (`stack-harmonia-2026-08`) e pelo incidente de exposição de rede (2026-08-05) |
| **Comando/artefato relacionado** | `onion-vps-logto` (esqueleto de referência vivo) · `onion-vps-docker-firewall` (contenção durável) · adapters `task-manager`/`forge` (precedente 1→N sem registry) |
| **Lei (L0)** | [`integrations.md`](../../meta-specs/integrations.md) — esta KB **cita**, não recopia; **não é** um 2º site-de-edição da lei |
| **Padrão-pai** | [Doutrina de Abstração](onion-abstraction-doctrine.md) (o Teste do Eixo que cada tool corre) · `onion-adr-sdaal-nested-two-level-2026-07` (ADR de análise do core — recursão canal→solução) |
| **Irmãs** | [Modernização](onion-modernization-doctrine.md) · [Dogfooding](onion-dogfooding-doctrine.md) · [Abstração](onion-abstraction-doctrine.md) |

---

## 🎯 Por que esta doutrina existe

A VPS compartilhada (Hostinger KVM8, `srv1812846`) acumulou, entre julho e agosto de 2026, um auth
maduro (Logto), um WhatsApp vivo (whatsapp-sender), um gap nomeado (email) e uma lista de candidatos
(monitoramento, tunneling). O impulso natural — "vamos desenhar a arquitetura que harmoniza tudo isso"
— **já foi tentado e reprovado** (F2, `stack-harmonia-2026-08`): a síntese citava "9 membros" e "canal
partido para 44%" quando o grafo real tinha **12 entradas**; o percentual era fabricado. A causa-raiz
não foi má-fé — foi **premissa presumida, não medida**, propagada por uma síntese sem verificação
independente.

Sem esta doutrina, cada nova ferramenta reabre a mesma pergunta do zero: é adapter? é script? precisa
de um painel? A resposta certa já existe — foi decidida em F0, **antes** da tentativa de arquitetura
cross-tool, e sobreviveu à reprovação dela. Esta KB nomeia essa resposta para que a próxima ferramenta
(monitoramento, tunneling, o que vier) **entre pelo mesmo funil**, sem redesenhar.

---

## ⚖️ O veredito verbatim — catálogo, não plataforma

> **VEREDITO F0** (`D_framing_catalogo`, confidence 0.9, Elenxo 2-steelman-1-juiz): o conjunto é
> **CATÁLOGO** (não plataforma; **híbrido recusado** — reservaria vaga pro dead-layer com folha-de-figueira
> build-gated). É a **soma de N adapters individualmente justificados por demanda** (pull-not-push):
> cada tool = **1 SDAAL se passa o Teste do Eixo**, senão **1 script-gated**, atrás do bridge, roteado
> por `.env` como task-manager/forge.
>
> **NÃO É**: zero backend/registry/UI próprios; `members.yaml` = **única fonte de identidade**;
> **nenhuma visão agregada/cross-tool é pré-autorizada** — qualquer painel composto é capacidade **nova**,
> sujeita ao próprio pull-not-push.
>
> **Precedente vivo decisivo**: `task-manager` + `forge` já escalam **1→N sem registry central**.

Três implicações práticas, direto do veredito:

1. **A soma não converge para produto.** Não existe "console do catálogo", "dashboard VPS" ou "API
   unificada de ferramentas" — cada um desses é um artefato novo que precisaria do seu próprio Teste
   do Eixo e da sua própria demanda concreta. Propor um agora, sem demanda, é **catedral** — o mesmo
   anti-padrão que [`gated-until-trigger`](onion-modernization-doctrine.md) já nomeia para abstração.
2. **A identidade não duplica.** `members.yaml` já é o SSOT de quem é federado; Logto é **projeção**
   dele (OIDC/JWKS), não uma segunda fonte de verdade paralela. Qualquer tool nova que precise saber
   "quem pode usar isto" lê `members.yaml` (direto ou via a projeção Logto) — nunca inventa sua própria
   tabela de usuários.
3. **O bridge é o único ponto de entrada.** Ferramenta compartilhada vive atrás de `onion-bridge`, nunca
   exposta direto — o incidente de 2026-08-05 (abaixo) é a prova do que acontece quando esse invariante
   é furado por baixo (Docker, não pela arquitetura declarada).

### O dissent sobrevivente (vigiar, não resolver por decreto)

O juiz do Elenxo registrou um dissent que **não vira o veredito**, mas fica de vigia
(`C_dissent_auth_transversal`): auth pode não ser "só mais um adapter-par" — é alicerce **transversal**
que whatsapp/email/monitoramento assumem como dado. O catálogo-puro trata Logto como uma entrada como
qualquer outra; se a dívida de integração ponto-a-ponto se acumular, pode valer mais que uma fina camada
compartilhada de auth. **A cura, se morder, é uma composição PUXADA pela própria demanda** — ainda
catálogo-nativa, nunca plataforma preemptiva. Não se resolve este dissent hoje; resolve-se **quando o
sintoma aparecer**, com evidência, do mesmo jeito que todo gate `gated-until-trigger` funciona.

---

## 🔁 O Teste do Eixo é recursivo aqui também

O Teste do Eixo ([Doutrina de Abstração §🧭](onion-abstraction-doctrine.md#-o-teste-do-eixo--as-3-condições-todas-obrigatórias))
— **≥2 implementações reais** · **escolha do consumidor via `.env`** · **consumidor cego à escolha** —
se aplica a cada tool do catálogo, **e recursivamente dentro dela**, exatamente como o
o ADR de SDAAL aninhado (`onion-adr-sdaal-nested-two-level-2026-07`, análise do core) já formalizou para
mensageria: canal → solução, cada nível correndo o teste **por si**.

**Aninhar não relaxa o gate — multiplica-o.** O caso WhatsApp é o worked example: o nível-1 (canal:
whatsapp/sms/email) e o nível-2 (solução: WAHA · Cloud API · whatsapp-web.js não-oficial) são graus de
liberdade distintos, e cada um precisa do seu próprio 2º provider real antes de graduar — o 1º provider
real nunca basta (§Teste do Gatilho, mesma KB-mãe).

Isso significa, na prática do catálogo VPS:

- Uma tool com **1 solução real** é **script atrás do bridge**, nunca SDAAL prematuro — mesmo que exista
  a intenção declarada de adicionar uma 2ª solução no futuro.
- Uma tool que **já tem 2 soluções reais** intercambiáveis graduma a SDAAL, com o eixo (canal, provider,
  tier — o que for) escolhido pelo `.env`, nunca pelo autor do código.
- O default de cada eixo é **declarado por domínio**, não simétrico por decreto — o mesmo precedente que
  `task-manager` (`api` default) e `forge` (`cli` default) já cravam (`integrations.md` §1.0).

---

## 🧪 O gate "premissas medidas, nunca presumidas" — a lição de stack-harmonia

F2 (`stack-harmonia-2026-08`) tentou desenhar a arquitetura cross-tool ("4 Leis") em cima do catálogo e
foi **reprovada pelo crítico adversarial**, com verificação independente confirmando o motivo:

| Premissa da síntese | O que a verificação achou |
|---|---|
| "9 membros" → "canal partido para **44%**" | `grep -c '^  - id:'` no grafo real = **12 entradas**. O percentual era **fabricado** |
| Conclusões sobre "o que o bridge faz" tiradas do `main` | o artefato que **roda** em produção (07-27) **não é** o do repo (07-31) — toda conclusão sobre comportamento do bridge lida do checkout podia estar errada |

A causa-raiz nomeada no próprio SYNTHESIS: **"o 'fix' veio de um `ls` lido ao contrário"** — inferência
por cima de dado não conferido, não má intenção. A regra que fica, e que esta doutrina herda como gate
obrigatório para qualquer arquitetura cross-tool futura:

> **Toda premissa numérica ou estrutural usada para decidir a forma do catálogo precisa vir de uma
> medição — comando executado, grafo lido, artefato invocado — nunca de recall ou extrapolação.**
> Verificação independente do ponto decisivo (não só do resultado final) é parte do Elenxo, não opcional.

Isto é a instância desta doutrina do mesmo invariante que [Dogfooding §🚦 item 4](onion-dogfooding-doctrine.md#-o-que-a-doutrina-exige-e-nunca-dispensa)
já nomeia: veredito de síntese/revisor é **hipótese a verificar com evidência**, nunca ordem.

---

## 🏷️ Convenção de nomenclatura — `onion-vps-`

Ferramentas que são **do Onion e padrão da VPS** (a espinha compartilhada, não um adotante específico)
usam o prefixo **`onion-vps-`** — ex.: `onion-vps-waha`, `onion-vps-logto`, `onion-vps-logto-postgres`,
`onion-vps-bridge`. Distingue de:

- `onion-adopt-<nome>-*` — stacks pertencentes a um **adotante** (ex.: `onion-adopt-<nome>-redis`);
- nomes próprios do adotante quando o serviço é dele, não do padrão-VPS.

A convenção foi aplicada em 2026-08-05 (renomes: `onion-vps-waha`, `onion-vps-logto`,
`onion-vps-logto-postgres`, `onion-vps-bridge.service`) via método seguro — só `container_name` muda
(dir/projeto/service-name mantidos), para não quebrar volumes/redes já vivos. É dogfoodada no artefato
de contenção `onion-vps-docker-firewall` (abaixo).

**Repo-por-ferramenta** é o padrão de casa para o esqueleto de cada entrada do catálogo: `onion-vps-logto`
(vivo em `/home/marcio/onion-vps-logto/`) é a referência — README, `docker-compose.yml`, `up.sh` que lê
segredo via `pass`+`direnv` com `${VAR:?}` fail-closed, `upgrade.sh`, `check-version.sh`, `backup.sh`,
`console.sh`, `.envrc`, `.gitignore`. Segredo da casa é **sempre `pass`(GPG)+`direnv`, nunca `.env`
plaintext** — o mesmo invariante que o incidente de 2026-08-05 reforçou por outro ângulo (superfície
exposta não pode depender de disciplina, precisa de mecanismo).

---

## 🚨 O incidente que testou o invariante "atrás do bridge"

Em 2026-08-05, o Docker furou o `ufw`: a chain `DOCKER-FORWARD` roda **antes** do `ufw` no `iptables`, e
`DOCKER-USER` estava vazia — resultado, data stores de adotantes (`onion-adopt-<nome>-*`: redis,
postgres, milvus/minio/attu) ficaram **expostos à internet pública** em `179.197.65.94`, apesar do `ufw`
"achar" que estava fechando as portas. Contido por uma regra `DOCKER-USER` default-deny (`-i eth0`)
persistida em `onion-vps-docker-firewall.service` (systemd oneshot, `After=docker.service`, idempotente).

**Por que isto pertence a esta doutrina, não só ao registro do incidente**
(`onion-vps-network-exposure-2026-08` (core-only)): o veredito F0 diz *"atrás do bridge"* como
propriedade arquitetural — mas o Docker ignorava o `ufw` no nível de rede, por baixo de qualquer
decisão de aplicação. A contenção por systemd unit é **mecanismo**, não disciplina — o padrão que
`fix-must-become-mechanism` já exige em outras doutrinas do core: todo ajuste que vem
do uso real vira mecanismo que se repete sozinho, nunca conselho para lembrar depois. A **cura durável
na fonte** (ainda pendente à data desta KB) é rebindar as portas do compose de `0.0.0.0` para `127.0.0.1`
— o firewall é a contenção; o rebind é o fechamento correto do buraco.

**Regra prática derivada para toda tool nova do catálogo**: declarar "atrás do bridge" no README não
basta — o `docker-compose.yml` precisa **bindar em `127.0.0.1`**, não em `0.0.0.0`, e a persistência do
firewall (`onion-vps-docker-firewall`) precisa cobrir a interface externa. Sem isso, a propriedade
"atrás do bridge" é **declarada, não verificada** — o mesmo anti-padrão #3 que a Doutrina de Abstração já
nomeia (env switch fictício), só que na camada de rede em vez de configuração.

---

## 📡 Radar honesto — ledger por-tool

| Tool | Status no Teste do Eixo | Forma | Gatilho para o próximo passo |
|---|---|---|---|
| **Auth/Identidade (Logto)** | N/A — é projeção de `members.yaml`, não adapter multi-provider | **Projeção** (self-hosted, OIDC/JWKS, flip AUTH_TOKEN→OIDC já executado) | Dissent `C_dissent_auth_transversal` — vigiar acúmulo de dívida ponto-a-ponto; sem gatilho hoje |
| **WhatsApp** | Nível-1 (canal) 1 real hoje; nível-2 (solução) **2 reais decididas** (whatsapp-web.js não-oficial mantido + WAHA como padrão) | **SDAAL-gated** (dogfood-first — wiring segue gated até o 2º provider estar de fato ativo em produção, não só decidido) | Ativar o adapter WAHA em produção e trocar `.env` de fato |
| **Email** | 1 solução planejada (SMTP self-host), sem 2ª solução real | **SCRIPT** (`logto-provision.sh --smtp` já existe) | 2º provider real de email (ex.: transacional SaaS) — hoje não há demanda medida |
| **Observabilidade** | Sem pesquisa concluída; "P2" ainda não esclarecido com o maestro | **Gated** — nem script nem SDAAL: falta até o framing (Langfuse × OpenTelemetry × outro) | `Q_p2_clarify` resolvido + pesquisa `verify-external-for-current` concluída |
| **Chat multiusuário (LibreChat)** | N/A — é FACE de consulta/distribuição (multi-LLM, OIDC, RAG), não adapter; consome as ferramentas do catálogo (Logto SSO, Caddy) | **Instalação em curso** (2026-08-20, plano aprovado: `onion-vps-librechat`, 5 serviços pinados, escopo completo c/ RAG) — pesquisa: `docs/evolution/research/librechat-2026-08/` | Subida verificada por comportamento (F4) + integrações Onion por valor (skillSync → Onion-KB → MCP onion-kg, gated por F4b) |
| **Tunneling** | Candidato nomeado (ngrok), sem caso de uso decidido vs. Caddy já vivo | **Gated** — falta o "para quê" (dev-preview? webhook inbound? adotante sem servidor?) | Caso de uso concreto nomeado + Elenxo curto (ngrok × Cloudflare Tunnel × Tailscale Funnel × Caddy-só) |

> **Como ler esta tabela**: cada linha é uma miniatura do Teste do Eixo aplicado hoje — não uma promessa.
> Uma tool sobe de `Gated`→`Script`→`SDAAL-gated`→`SDAAL` só quando o gatilho da própria linha acontece,
> nunca por simetria com a vizinha ("já que o WhatsApp tem 2 providers, o email também deveria" **não é
> gatilho** — é o mesmo anti-simetria que a Doutrina de Abstração já recusa).

---

## 📚 Fontes

- **Veredito F0 (SSOT do framing):** `docs/onion/graph/vps-shared-tools-2026-07.kg.yaml`, nós
  `D_framing_catalogo` · `C_dissent_auth_transversal` · `Q_catalog_vs_platform`.
- **Reprovação de F2 (a lição de premissas medidas):**
  `docs/evolution/research/stack-harmonia-2026-08/SYNTHESIS.md`.
- **Incidente de rede (o invariante "atrás do bridge" testado):**
  `onion-vps-network-exposure-2026-08` (core-only).
- **Esqueleto de referência vivo (repo-por-ferramenta):** `/home/marcio/onion-vps-logto/`.
- **Critério de graduação (o Teste do Eixo/Gatilho, citado não recopiado):**
  [Doutrina de Abstração do Onion](onion-abstraction-doctrine.md).
- **Recursão canal→solução (citado não recopiado):**
  `onion-adr-sdaal-nested-two-level-2026-07` (ADR de análise do core).
- **Lei (L0 — não recopiada aqui):** [`integrations.md`](../../meta-specs/integrations.md).
- **Irmãs:** [Modernização](onion-modernization-doctrine.md) · [Dogfooding](onion-dogfooding-doctrine.md) ·
  [Abstração](onion-abstraction-doctrine.md).
