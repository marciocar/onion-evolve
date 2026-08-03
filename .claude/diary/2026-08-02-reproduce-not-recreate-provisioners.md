---
date: 2026-08-02
instance: onion-evolve
type: learning
classification: collective
tags: [provisionamento, idempotencia, diff-vazio, logto, smtp, producao]
affects: [engineering, meta]
breadcrumb_for: []
share_with: []
next_recommended: "Ao versionar configuração que já existe viva: NUNCA escreva o conteúdo de memória. Extraia do vivo (`GET` + `jq`), cole verbatim, e deixe o comando de extração no comentário. A prova de que o script REPRODUZ em vez de redefinir é o diff vazio: snapshot antes → aplicar → snapshot depois → `diff` sem saída. Custa 3 comandos e é a única prova honesta. Se o recurso é único por tenant (conector de e-mail do Logto, webhook, DNS), a idempotência é de SEGURANÇA, não de elegância: consulte antes e faça PATCH, porque criar o segundo quebra o canal em silêncio."
review_after: 2026-10-31
conflict_class: static
kg: docs/evolution/research/email-logto-2026-08/email-logto-2026-08.kg.yaml
significance: "Ia sobrescrever produção com texto que escrevi de memória. Os templates que 'lembrava' divergiam do vivo em dois pontos, e um --apply teria trocado os dois em silêncio. Reproduzir ≠ recriar — e a diferença se prova com diff vazio."
---

## Signal

**Script de provisionamento que "melhora" o que encontra é script que corrompe.** Ao versionar
configuração que já existe viva, o conteúdo tem de vir **do vivo**, não da memória — e a prova de que
o script *reproduz* em vez de *redefinir* é o **diff vazio**.

## Evidência

O conector SMTP do Logto existia só no banco (criado ad-hoc em 2026-08-01 via Management API). Ao
levá-lo para `logto-provision.sh --smtp`, escrevi os 5 templates de `usageType` **de memória**. Eles
divergiam do vivo em dois pontos:

| template | eu escrevi | o vivo diz |
|---|---|---|
| `Register` | "cadastro" | "**confirmação**" |
| `OrganizationInvitation` | 1 linha | **2 linhas** (`\n\n`) |

Um `--apply` teria **sobrescrito produção em silêncio** — o script não erraria, não avisaria, e o
texto que chega ao usuário final mudaria. Cura: os 5 extraídos **verbatim** do conector vivo, com o
comando de extração deixado no comentário para a próxima pessoa não repetir a invenção.

**A prova, e ela é barata:**

```
snapshot do config vivo  →  --apply  →  snapshot depois  →  diff
                                                            (vazio)
```

Aplicar não mudou um byte. Três comandos.

E um segundo eixo que o caso ensinou: **o Logto aceita 1 conector de e-mail ativo por tenant.** Criar
um segundo quebraria o canal *em silêncio*. Aqui idempotência não é elegância — é a diferença entre
o script ser seguro de rodar duas vezes e ele derrubar autenticação.

## O que fecha

Fecha o único fio da sessão que era **irreversível**: se o Logto caísse, o conector sumia e ninguém
sabia refazer. Agora vive em script que já era versionado — reuso, não invenção (nenhum mecanismo
novo, que é o portão que a casa aplica a toda adoção de substrato).

## Fronteira honesta

O diff vazio prova que o script **reproduz o estado atual**. Não prova que o estado atual está
**certo** — se o conector vivo tivesse um template errado, o script agora versiona o erro com
fidelidade. E a ressalva que o próprio modo imprime: **aceite SMTP ≠ entrega**. O Logto é
fire-and-forget; INBOX-vs-spam nenhuma API mostra.
