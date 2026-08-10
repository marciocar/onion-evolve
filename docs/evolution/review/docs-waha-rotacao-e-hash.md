---
branch: docs/waha-rotacao-e-hash
date: 2026-08-10
reviewed_diff_sha256: e08ef73fbd1e3bae27ff61593f2038b12a78c74335399cc0299d150177a640c8
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 0
verdict: SEM-ELENXO-EXECUCAO-EM-PRODUCAO-VERIFICADA-NAS-QUATRO-PONTAS
reviewer: sem passada adversarial — mudança de dados; a verificação foi comportamental, em produção
---

# A chave do WAHA foi rotacionada e o container deixou de vê-la

Backlog: **1 → 0 abertos**.

## O que foi executado

| ponta | verificação |
|---|---|
| `docker inspect` | `WAHA_API_KEY=sha512:7e1a3ebb…` — **hash**, não credencial |
| chave nova (texto puro do `pass`) | **200** |
| chave **antiga** | **401** — rotação efetiva, não decorativa |
| sessão do WhatsApp | `default` / **`WORKING`**, mesmo número |

Container `running`, `restarts=0`.

O `pass` (GPG) segue guardando o texto puro — que é o que os **clientes** enviam. O `.envrc` e o
`up.sh` calculam o hash na hora: `sha512:$(printf %s "$(pass show …)" | sha512sum | cut -d' ' -f1)`.

**`printf %s`, nunca `echo`** — está no comentário dos dois arquivos porque a quebra de linha do
`echo` entra no hash e quebraria a auth **em silêncio**. Medido: os dois digests divergem.

## Por que rotacionar ANTES do hash

O vetor original (`docker inspect`, raio **root**) não justificava sozinho — root já lê tudo. O que
justificou foi a busca por consumidores achar a chave **em claro em dois transcripts** de sessão
anterior: `600` em diretório `700`, outro usuário negado, mas **durável em disco** e fora do password
store.

Rotacionar primeiro tornou aquele valor **inerte** (401). Os arquivos seguem lá; o que contêm não
serve mais.

## O que foi medido ANTES de agir

- **o WAHA aceita hash** — `ApiKeyAuthFactory`: `apiKey.startsWith('sha512:')` → `HashAuth`;
- **a forma exata** — `createHash('sha512').update(plain).digest('hex')`, conferida contra o `node`
  **do próprio container**;
- **zero consumidores vivos** — porta em `127.0.0.1:3999`, sem conexões, sem proxy, menções no repo
  só em docs/research;
- **a sessão sobrevive** — *bind mount* no host (`onion-waha/sessions`, 36M), não no container. Era a
  única incógnita que eu havia declarado, e virou medição antes de virar risco.

## As duas vezes que a MINHA medição errou, e as duas por método

**1 · "A credencial só existe no container; recriar perde."** **Falso.** Procurei o **valor** dentro
de arquivos — e um password store guarda **cifrado**. O método não podia achar, e eu li a ausência
como fato sobre o mundo. A fonte é o `pass`, viva, e conferi que o valor batia com o do container.

**2 · "Matei o shell preso."** **Falso.** Rodei `pkill` com um padrão e verifiquei com **outro** — a
verificação deu zero porque olhava para coisa diferente da que eu alegava ter feito. Quem viu foi o
maestro, na tela. O laço nunca terminaria sozinho: `pgrep -fc` sem processo imprime `0` **e sai 1**,
então o `|| echo 0` disparava junto e a substituição virava `"0\n0"`, que nunca é igual a `"0"`.
**A guarda que protegia contra falha do comando foi a que criou a armadilha.**

## Limite de produto, sem cura por configuração

**`WAHA_DASHBOARD_PASSWORD` é comparado em texto puro.** `apps/app_sdk/auth.js` usa `password.value`
direto num mapa de basic-auth; `sha512` existe **só** no `ApiKeyAuthFactory`. Não há configuração que
resolva.

Mitigação possível, **não cura**: rotacionar também a senha, para que o valor exposto ao
`docker inspect` ao menos não seja o que já circulou.

Por isso o nó foi **colhido** e não mantido aberto: item sem cura possível que fica `open` para
sempre é o cemitério que o `meta:` deste arquivo proíbe. O limite vive no rótulo.

## O que NÃO foi feito, declarado

- **Sem passada adversarial**: mudança de dados e de duas linhas de shell, verificada em produção
  pelas quatro pontas acima.
- **Os transcripts com a chave antiga não foram apagados** — ela vale 401, mas os arquivos seguem.
- **A senha do dashboard não foi rotacionada** nesta passada.
