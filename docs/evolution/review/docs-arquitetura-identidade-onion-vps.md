---
branch: docs/arquitetura-identidade-onion-vps
date: 2026-08-11
reviewed_diff_sha256: e6d1e3a943c984ba6a2694de95824a2ac6edb3420d9cabcbfd5123cb65a59eed
findings_total: 6
findings_real: 5
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
