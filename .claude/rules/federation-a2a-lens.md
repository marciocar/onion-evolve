---
name: federation-a2a-lens
description: A lente do transporte A2A — carrega ao tocar os motores de federation-transport.
paths:
  - .claude/utils/federation-transport/**
---

# 🔐 Você está tocando o transporte A2A

Superfície: [`/meta:federation-a2a`](../commands/meta/federation-a2a.md). Doutrina inteira em
[`common:prompts:federation-a2a-doctrine`](../commands/common/prompts/federation-a2a-doctrine.md) —
**leia antes de mudar um motor**. O que mais custa esquecer aqui, medido:

1. **O gate veta na dúvida, e o doctor separa "errado" (rc 1) de "não sei" (rc 2).** Nenhuma mudança
   pode fazer ferramenta ausente, registro ilegível ou relógio sem fonte virar `ok`.
2. **Segredo nunca em argv, no chat ou no git.** Token por arquivo de cabeçalho 0600; corpo por
   `--rawfile`; chave privada 0600 num diretório 0700 e fora do repo. Teste com um `curl` stub que
   grava o argv, não com amostragem de `ps` (corrida em CI de 2 cores).
3. **O `--dry-run` do gate consome o jti.** Conferir só com envelope sintético e estado descartável.
4. **O kid vira nome de arquivo** (`jwks/<kid>.pem`): forma fechada `[A-Za-z0-9._-]`, sem `.` inicial,
   e `<membro>-<N>` no registro, sem kid de dois donos.
5. **A bancada é `run_federation_a2a_selftests`** (com a `run_a2a_verify_selftests`, a
   `run_a2a_accept_selftests` e a `run_a2a_ssrf_selftests`), sob `LC_ALL=C`, e todo caso novo tem mutante provado.
6. **O arquivo de convites se escreve só pelo `a2a-invite.sh`**, e se julga pelas regras do guard do
   bridge: o bridge o recusa inteiro se tiver outro dono, symlink, escrita de grupo/outros ou
   diretório inseguro, e `revoked` só vale como `false` literal. A validade é ISO 8601 com hora e
   fuso, com paridade medida contra o `Date.parse` do V8: sem `date -d`, que só existe no GNU.
8. **O receptor é a rota, e é id do registro** (F3): `--receiver` tem forma fechada (1º caractere letra
   ou dígito, sem `/` nem `..`, porque vira nome do arquivo de jti) e só recebe quem é `role: source` ou
   `hub` e não é porta. `aud` é obrigatório: sem ele, o envelope de um receptor valeria no outro.
7. **Estes motores não viajam para standalone, plugins nem mini** (corte por prefixo no transporte):
   texto que manda o membro rodá-los aponta o pacote de entrada da trilha 2, não o caminho do core.
