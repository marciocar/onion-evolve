---
branch: docs/arquitetura-identidade-onion-vps
date: 2026-08-11
reviewed_diff_sha256: 2c6f070b5fe2edddae822aafa96c0aa065f440bdf4b0cde3d9044f5a5b8796d6
findings_total: 11
findings_real: 6
findings_fixed: 5
tokens: 0
duration_min: 0
verdict: ELENXO-DERRUBOU-CINCO-AFIRMACOES-MINHAS-E-ACHOU-UMA-BOMBA-RELOGIO
reviewer: quatro frentes de pesquisa (estado da arte datado, medicao do vivo, Sourcegraph reenquadrado pelo maestro, capital/M&A) + passada adversarial Elenxo sobre seis afirmacoes centrais + inventario de exposicao
---

# A arquitetura de identidade, e o que ela custou para ficar honesta

## O que entra

`docs/onion/identidade-onion-vps.md` (prosa) e `docs/onion/graph/identidade-onion-vps-2026-08.kg.yaml`
(SSOT, 21 nós, radar exit 0), mais os casos `(b5b)`/`(b5c)` resgatados de uma sessão que morreu com o
trabalho na árvore — bancada **verde, 0 falhas**.

## A tese

**O Logto responde *quem é você*; ele não responde *o que você pode decifrar*.** Isso inverte a
expectativa comum: integrar ao IdP **não tira um segredo do mundo, adiciona um sistema ao caminho**.
E é o que torna o console público uma decisão defensável — o raio dele é o plano de **controle** da
identidade, não os segredos das ferramentas.

O desenho tem **três modelos de confiança distintos** (JWKS local no bridge, redirect no cofre, API
key no WAHA) e **três redes Docker sem nada em comum**. Não há ponto único cuja queda derrube tudo —
e também **não há lugar único onde auditar acesso**. Esse é o custo, e ele é consciente.

## Cinco correções de afirmações minhas

Ficam registradas porque **como um fato foi estabelecido decide quanto se pode confiar nele depois**.

| # | eu afirmei | a medição mostrou |
|---|---|---|
| 1 | "SSO provado ponta a ponta" | testei só o **front-channel**; o back-channel eu nunca exercitei |
| 2 | "um desconhecido chega a um POST de ter conta" | repassei achado de agente que **parou antes desse POST** |
| 3 | cadastro fechado, provado por `404` no submit | o portão é `403` no `/identification`; meu `404` era **artefato de sessão mal formada** |
| 4 | "metade do bridge não passa por review" | **é repo git limpo**, remote privado, `ls-remote` rc=0 |
| 5 | "o bridge tem o mesmo vetor de container" | **não tem** — porta publicada pelo Docker escapa do `ufw INPUT`; processo do host não |

E um incidente: o `upgrade.sh` **derrubou o Logto** porque `deploy 2>&1 | tail -20 || exit 1` lia o
exit do `tail`. **Guarda que lê o exit errado é pior que guarda ausente: ela afirma ter verificado.**

## A bomba-relógio que ninguém tinha visto

A stack viva do adotante dependia de um override em `/tmp/.../scratchpad/`, sob UUID de **sessão
morta**. `/tmp` é limpo no boot: no próximo `up`, o Logto dele voltaria a 3011/3012 e **colidiria com
o Logto do core**, derrubando `auth.onionevolve.com`. Movido, versionado, com o porquê escrito.

## O que a pesquisa externa mudou no desenho

- **Recuperação é o elo fraco, não o MFA** — MFA sem recuperação **troca invasão por lockout**, e com
  admin único sem e-mail o lockout é o mais provável. **Inverte a ordem das etapas.**
- **Fronteira lógica não é fronteira de segurança** — o CVE-2026-43912 quebrou isolamento entre
  organizações do Vaultwarden **em produção real**.
- **Não há patch para os 6 CVEs do Logto.** A proteção é *"zero conectores upstream"* — **condição**,
  não cura. Ligar login social **arma os seis**.
- **O dinheiro diz que memória de agente é commodity** (0,6% do capital agentic, zero M&A) e que
  **dado vertical proprietário** é o que vale — confirma o norte NS1 em vez de pedir mudança.

## Declarado, e não coberto

O cofre **está vazio** e o SSO não completa: a identidade no Logto tem `primary_email` vazio, então o
`id_token` não carrega a claim que o Vaultwarden exige. Isso é a W1, não este PR.

---

## Segunda rodada — W0, W1, W2 e W3 executadas

### A guarda que nasceu, e por que ela NÃO é uma REGRA do lint

`.claude/validation/vps-exposure-check.sh` vigia as **duas condições que armam risco** e que nada
observava:

1. **porta publicada em `0.0.0.0`** — medido que ela é alcançável de outro container (o caminho é
   DNAT/FORWARD e escapa do `ufw INPUT`), enquanto `127.0.0.1` dá timeout;
2. **conector upstream no Logto** — o evento que **arma os 6 CVEs do VU#492466**, que **não têm
   patch** (a CERT registra que a mantenedora não foi alcançada).

Ela checa **estado vivo**, não código — por isso **cala** (exit 0) fora da VPS, e por isso o lugar
dela é um **timer systemd diário**, não o CI, onde não existe docker. Guarda que reprova por estar no
lugar errado vira ruído e é desligada.

**Par acusa/cala provado por mutação**: com um container-sonda em `0.0.0.0:39999` a guarda sai **1**
nomeando o container; removida a sonda, sai **0**.

### A regra que eu decidi NÃO construir

O plano previa um lint exigindo `pipefail` em script com pipe a montante de `||`/`$?`. Varri o repo:
**dois candidatos, ambos falso-positivo** — num o `|` que casou era do próprio `||`, no outro o
`|| true` liga ao `grep`, que **é** o último elemento.

**Zero casos reais.** Construir seria guarda nascida verde-vazia — o defeito que a própria
`kg-grammar` desta casa registra. A cura real (`upgrade.sh`) já foi feita e vive **fora** do repo,
onde lint de repo não alcançaria de qualquer forma.

### O que mudou em produção

| onda | o que | verificação |
|---|---|---|
| W0 | 13 portas do adotante → loopback | `waha → :3022` de **302** para **timeout** |
| W0 | bootstrap do IdP do adotante fechado | `/register` → `/unknown-session`, `PUT Register` → **400** |
| W0 | `/admin` do cofre fora da internet | **200 → 404**, loopback ainda `200` |
| W1 | `primary_email` nas 2 identidades | destrava recuperação **e** a claim do cofre |
| W1 | Postmark no tenant `admin` | era conta pública sem caminho de volta |
| W1 | `factors: [Totp, BackupCode]` | API viva confirma |
| W2 | workspace por `identity.subject` | boot limpo, `app` **200**, **23 → 2** workspaces |

### Correções de gravidade que eu tinha declarado a mais

- **Os 23 workspaces não eram vazamento entre pessoas** — 21 eram cascas de 8K. É perda de
  continuidade e lixo em disco, não incidente de isolamento.
- **O `working_dir` do postgres do core era falso positivo** — o compose enxerga os dois containers,
  porque o `name:` fixado faz o projeto ser achado por label, não por diretório.

### Declarado, e não coberto

O laço do SSO fecha com **login real de navegador** — `sso_users` só sai de 0 quando alguém entrar.
Está **destravado, não provado**. E o backup (W4) segue cifrado no mesmo disco.

---

## Passada adversarial contra este PR

Cinco afirmações atacadas. **Quatro sobrevivem por medição repetida; uma cai como não-provada.**

| # | afirmação | veredito |
|---|---|---|
| 1 | 13 portas em loopback | **SOBREVIVE** — 0 containers públicos após todos os restarts |
| 2 | vetor container→IdP fechado | **SOBREVIVE** — `waha → :3022` segue **timeout** |
| 3 | `/admin` fora da internet | **SOBREVIVE** — **404**, com `/alive` ainda **200** |
| 4 | timer sobrevive a reboot | **SOBREVIVE** — `enabled`, agendado |
| 5 | **chave nova do workspace** | **NÃO PROVADA** |

### O que cai, e por quê importa

Os **2 workspaces em disco foram criados pela chave ANTIGA**. A nova só produz diretório quando
alguém **autenticado** chamar — e `/chat` sem credencial responde `401`, barrando antes de
`ensureWorkspace`.

O que está provado: o serviço **boota** com o código novo (o `tsx` interpreta direto, então erro de
sintaxe derrubaria) e `app.onionevolve.com` responde `200`. O que **não** está: que a chave por `sub`
produza o diretório certo em uso real.

**É exatamente a classe de erro que este PR corrige em cinco lugares** — verificar que o processo
está de pé e chamar isso de comportamento verificado. Fica declarado em vez de arredondado.

**Como provar quando houver login**: duas chamadas separadas por um refresh de token devem produzir
**um** diretório, não dois — e o nome dele não pode ser `sha256` de nenhum token.

---

## Terceira rodada — os dois achados do revisor viraram mecanismo

### 1. Branch em pt-BR — a guarda existia, a LISTA é que não tinha as palavras

O revisor acusou `docs/arquitetura-identidade-onion-vps`. A guarda de nome de branch **existe e
funciona**; o que faltava era o vocabulário: `grep -cx arquitetura` e `identidade` devolviam **0**.

Acrescentadas 14 palavras mantendo o critério da lista — **pt-BR sem homógrafo em inglês** (`total`,
`local`, `normal` ficam fora de propósito, senão acusariam identificador inglês legítimo).

**Provado contra o caso real:** o mesmo comando que criou esta branch agora é acusado, nomeando as
palavras. O achado virou mecanismo, não desculpa.

### 2. Guarda nova sem fixture — e o aparato de teste falhou TRÊS vezes

Bloco `(a)`/`(b)`/`(c)` na bancada. Mas o caminho até ele é a parte que ensina:

| # | defeito | onde estava |
|---|---|---|
| i | `PATH=/nonexistent bash` — sumiu com o próprio `bash`, exit **127** matou a suíte | meu aparato |
| ii | função **definida depois de chamada** (9182 chama, 9419 define) | meu aparato |
| iii | `sed` de mutação no-op, escape perdido no heredoc | meu aparato |
| iv | **substituí o `sed` de OUTRO teste** (`migalhas-generate`) | **código alheio** |

**Nenhum estava na guarda** — todos no aparato que a testa. A guarda funcionava desde a primeira
medição contra o vivo.

O (iv) é o mais grave: usei `re.search` para achar minha linha e o regex casou o **primeiro** `sed`
do arquivo, quatro mil linhas antes. É a classe de `rename-verifica-por-ausencia-da-palavra` —
varredura que casa mais do que modelei. A conferência certa era trivial: `grep -n` mostraria **duas**
ocorrências, não uma. Restaurado e verificado por ausência.

**E o que impediu o falso-verde nas três primeiras foram guardas-da-guarda que a casa já tinha**: o
detector de abort (*"NÃO leia esta saída como verde"*) e o `GUARDA-DA-GUARDA: a mutação NÃO foi
aplicada`. Sem eles: 390 verdes com a guarda nova nunca tendo rodado.

**Bancada 790 / 0 falharam / 0 pularam**, sha estável, e o teste que eu havia danificado passa.
