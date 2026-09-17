---
title: 'Resíduo — a porta subiu nua, e a chave do cliente só não subiu por um .gitignore alheio'
date: 2026-09-17
branch: feat/door-completeness
reviewed_diff_sha256: PENDENTE
findings_total: 4
findings_real: 4
findings_fixed: 4
tokens: 0
duration_min: 0
verdict: CORRIGIDO
elenxo: nao
nota: >-
  Os quatro achados vieram da PRIMEIRA materialização REAL da porta, feita pelo maestro — não de
  leitura de código nem de refutador. É a diferença entre dogfood e simulação: os dois defeitos
  centrais só existem quando alguém publica de verdade.
---

# O que a primeira publicação real mostrou

O maestro criou o `onion-core`, rodou o `materialize-door.sh` e deu o push. Auditei **o que subiu**,
não o que eu esperava que subisse. O conteúdo estava limpo — os seis diretórios de biografia
ausentes, baselines stubados (26 → 0 linhas privadas), zero ponteiros nomeados. E mesmo assim,
quatro achados.

## 1 · A chave do cliente viajou, e só um `.gitignore` alheio a impediu de subir

```
.claude/utils/federation-transport/jwks/<membro>-1.pem   (duas, nomeando dois adotantes)
```

Estavam no bundle de 703 e **não** nos 700 publicados — porque o alvo tinha `jwks/.gitignore` com
`*.pem`. São chaves **públicas** (JWKS), não segredo; mas o **nome do arquivo é o nome do cliente**,
e ele viajava para todo adotante e para a porta pública.

**Guarda que depende do `.gitignore` do destino não é guarda.** Duas curas, porque uma só deixaria
a outra ponta aberta:

- **`_IDENTITY_EXCLUDES`** no manifesto — a chave não viaja em **nenhum** papel. Fica fora do
  `_role_cut` de propósito: o corte por papel é sobre *quanta fábrica* o alvo recebe; este é sobre
  *quem o bundle nomeia*, e a resposta é a mesma nos três.
- **`--check-bundle` (c)** — reprova qualquer arquivo cujo nome contenha um id do `members.yaml`.
  Derivado da mesma fonte da REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente), e
  fail-open declarado: sem o registro não há o que derivar.

Medido depois: **0 `.pem`** nos três papéis.

## 2 · A porta subiu sem README, LICENSE, CLAUDE.md e AGENTS.md — 4 de 4

Repo público sem README é ruim de receber. **Sem LICENSE é pior, e não por estilo:** sem licença o
padrão legal é *"todos os direitos reservados"* — o oposto exato do que uma porta existe para dizer.
E sem `CLAUDE.md` o Onion não se apresenta a quem clona.

O passo (5) do `materialize-door.sh` emite os quatro. O README **diz que é projeção e não recebe
PR** — sem isso alguém corrige aqui e a correção é sobrescrita na próxima materialização.

**E aqui o `LICENSE` nu é correto, enquanto no adotante seria errado** — a diferença é de objeto. No
repo do cliente, um `LICENSE` na raiz rege o repositório inteiro, inclusive o código que ele ainda
vai escrever; por isso o `emit-licenses.sh` entrega `LICENSE-ONION` lá. Na porta, o repositório **é**
o Onion, e um `LICENSE-ONION` seria a evasiva. O caso (d) da bancada prende as duas pontas.

## 3 · A branch da porta é `master`

O core e o resto da família usam `main`. Barato de corrigir agora, caro depois que houver clones.
**Não corrigido aqui** — é um comando no clone do maestro, e renomear a default branch de um repo
público é ato dele.

## 4 · O `ops/` não viaja, e está certo

O segundo comando do maestro falhou porque o `materialize-door.sh` não está na porta. **A porta não
se materializa a si mesma** — o script roda a partir do core, apontando para o clone dela.

## O que eu errei

Criei esta branch a partir de `main` e o dogfood reprovou com os 18 ponteiros — que já estavam
curados no **#840**, não mergeado. Esta entrega **depende** daquela; empilhei.

## Teto declarado

O `--check-bundle` (c) só enxerga id que esteja no `members.yaml`. Cliente **não registrado**
continua invisível — é a mesma lacuna que a migalha `vendor-scrub-blind-spot` nomeia, e registrar
adotante segue sendo ato de segurança.
