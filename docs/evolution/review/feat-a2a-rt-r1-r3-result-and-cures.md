---
branch: feat/a2a-rt-r1-r3-result-and-cures
pr: pendente
date: 2026-10-28
reviewed_diff_sha256: 1f6a0f975ad9b9e2c87c9ce2ebb5ddb8dbe1ac4840f3a3b6500df9134ef3cb39
reviewed_code_sha256: 6249125ef8b5fd1a69c91602eb8d6c9146c259bbe3df0ae5e838a8a0f2d49b1c
findings_total: 8
findings_real: 5
tokens: 106689
duration_min: 3
findings_fixed: 5
verdict: REPROVADO_E_CURADO
elenxo: sim
reviewer: "agente novo (general-purpose), só leitura, com o diff e o contexto do sistema no brief, sem a conclusão do autor"
nota: "A passada reprovou a 1ª versão da cura (c) com um defeito grave medido no vivo: o razão de aceites da VPS é gravável por outro usuário do sistema por ACL, e a linha não amarrava o conteúdo do doc, então o verified-crypto=true afirmava o que ninguém conferia. Os 5 achados reais foram curados neste PR, com caso e mutante; 2 hipóteses foram curadas também, por serem baratas (o O_NOFOLLOW com fstat e o rc do grep); 1 ressalva ficou sem cura (servidor com ponto no nome dá rc 2, o que falha fechado)."
---

# Passada adversarial: `feat/a2a-rt-r1-r3-result-and-cures`

## O que muda

O resultado das rodadas R1 a R3 da ida e volta A2A (*Agent-to-Agent*) entre a VPS e o notebook vai para o grafo e
para o §10 do pré-registro, e os seis achados das rodadas são curados: a foto de permissões, o comando de envio na
resposta do `draft_message`, o carimbo de cripto do modo inbox-doc, o razão de aceites ausente, a linha do dry-run
do envio do core e o card do maestro.

## Achados

O revisor recebeu o diff e o contexto, e não a conclusão. Ele confirmou que não há injeção pelo texto do comando de
envio: os ids passam por forma fechada e os caminhos por `shlex.quote`. Também confirmou que o razão ausente,
sozinho, não entrega doc forjado.

1. **(alta, real) ACL no razão.** A checagem olhava só os bits de modo. O `getfacl` no razão vivo mostra escrita por
   ACL de outro usuário do sistema, e a pasta e o inbox têm a mesma ACL. **Curado:** o razão só carimba se for
   privado, sem escrita de grupo, sem escrita de outros e sem ACL. Senão, o doc chega com `false` e o motivo. Caso
   com `setfacl` e `chmod 660`, e um mutante. Tirar a ACL do vivo fica com o maestro.
2. **(alta, real) O carimbo não amarrava o conteúdo.** A linha do razão ligava o jti só ao nome do doc. **Curado:**
   o `a2a-accept.sh` grava o sha256 do doc como 4ª coluna e cria o razão 0600, e o MCP recusa o doc que mudou depois
   do aceite. A linha antiga, de 3 colunas, chega com `false`. Há casos e mutantes nas duas pontas: a
   `run_a2a_accept_selftests` e a `run_a2a_rt_selftests`.
3. **(hipótese) TOCTOU no `lstat` seguido de `open`.** **Curado:** o arquivo abre com `O_NOFOLLOW` e o `fstat` é feito
   no próprio descritor.
4. **(baixa, real) Marcadores com metacaractere de shell.** Com a config incompleta, o comando trazia `<`, `|` e `>`.
   **Curado:** os marcadores agora são `CAMINHO_DO_CHECKOUT`, `LADO`, `SEU_ID` e `ENDPOINT_A2A`, e a variável que
   falta vai dita antes do `rode:`. Tem caso.
5. **(baixa, real) Razão ausente com docs na caixa.** A resposta dizia «nunca houve aceite». **Curado:** agora sai um
   AVISO, e nada é entregue. Tem caso.
6. **(hipótese) `|| true` engolia o rc 2 do grep.** **Curado:** só o rc 1 passa. O mutante foi ajustado.
7. **(hipótese) Curinga largo (`mcp__a2a-*`) não contava.** **Curado:** o curinga que cobre um servidor do teste conta.
   Tem caso. Ressalva sem cura: servidor com ponto no nome dá rc 2, e isso falha fechado.
8. **(real) Cobertura.** Faltavam casos para a ACL, para o conteúdo e para a config incompleta. **Curado:** entram os
   três.

## Mutantes

A `a2a_rt` passou de 28 para 44 verificações. Os mutantes novos estão todos mortos:

- a sugestão antiga de envio;
- o carimbo sempre `false`;
- o carimbo sem as amarras;
- o sha do doc não conferido;
- o razão ausente que recusa;
- a linha corrompida ignorada;
- o filtro do dry-run removido;
- a mensagem antiga do dry-run;
- o casamento fixo em `^mcp__a2a-spike`;
- o card com o doctor nu.

Na `a2a_accept` entrou o mutante da linha sem o sha do doc. Um mutante vazio que já existia, o «corpo sem moldura»
do caso (e), cuja âncora tinha sumido em 2026-10-27, ganhou a âncora certa e a exigência do arquivo.

## Limites declarados

O mesmo UID forja o razão e o doc. Esse limite está no §1 e no §7 do pré-registro, e a cura dele é o UID separado.
A ACL do vivo é decisão do maestro.
