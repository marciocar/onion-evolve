---
branch: feat/a2a-draft-piece
pr: 1399
date: 2026-10-27
reviewed_diff_sha256: 8b38b298ca52fa8960fea8b408e0fa04f3eebccba598423d1d63c39729991293
reviewed_code_sha256: 152c2d1fceae42384156f8601934dd9c8cf3334daf20e439b658dd0d2792b070
findings_total: 9
findings_real: 6
tokens: 115980
duration_min: 4
findings_fixed: 5
verdict: CORRIGIDO
elenxo: sim
reviewer: "agente novo (general-purpose), com só o código e o contrato no brief, sem a conclusão do autor"
nota: "foco pedido pelo maestro: envio escondido e injeção. 6 achados reais: 5 curados no commit 76f3a7cf6 e 1 limite de desenho, declarado na Emenda 1 do pré-registro e mitigado só por lombada. Outras 3 eram hipóteses, julgadas sem cura."
---

# Passada adversarial: `feat/a2a-draft-piece`

## O que muda

A peça de rascunho do A2A (*Agent-to-Agent*) tem três partes:

- `a2a-rt-mcp.py`, um MCP (*Model Context Protocol*) com só `draft_message` e `read_inbox`;
- `a2a-rt-send.sh`, o envio humano, que só sai com a confirmação digitada no `/dev/tty`;
- a bancada `run_a2a_rt_selftests`.

Junto vieram a retirada `--until-jti`, o juiz `--server a2a-rt`, o instalador da sessão de teste, o selo
`D_A2A_PECA_RASCUNHO_CONSTRUIR_1027` e o card.

## Achados

O revisor recebeu o código e o contrato, sem a conclusão do autor. Ele não achou caminho de envio sem o
humano, com o modelo usando só o MCP. Conferiu:

- **path traversal** (caminho que escapa da pasta), pelo `ID_RE`, pelo `O_EXCL` e pelo `O_NOFOLLOW`;
- **symlink**;
- **TOCTOU** (o arquivo muda entre a checagem e o uso): o mesmo arquivo de corpo vai para a tela, para o hash e para a assinatura;
- **reenvio**, barrado pelo `sent.tsv`;
- **flags**, porque não há flag que pule a confirmação;
- **a config gerada**, que tem um servidor só.

Os achados reais e o que foi feito com cada um:

1. **(média) Metadado fora da moldura.** O `iss` e o `thread` iam crus ao cabeçalho. Ele provou com um envelope de assinatura válida. **Curado:** os dois passam a ter forma fechada de id, e o `iss` tem de ser o par pinado. Caso e mutante 3 do (e).
2. **(média-alta) Doc forjado no modo inbox-doc.** Ele provou com um `.md` escrito à mão. **Curado:** o doc só chega se estiver no razão de aceites do `a2a-accept.sh`, com nome e origem na forma dele, e a moldura passa a dizer `verified-crypto="false"`. Caso, caso sem o razão e mutante.
3. **(média, desenho) O portão do `/dev/tty` prova terminal, não humano.** Um processo do mesmo usuário com pty consegue confirmar. **Declarado, sem cura:** está na Emenda 1 do pré-registro. Ficou só uma lombada (recusa com `CLAUDECODE`), com caso e mutante. O portão real é o UID separado (§7).
4. **(baixa) Tela do envio desarmada byte a byte.** Passavam o C1, o bidi e o largura zero. **Curado:** o desarme agora é por codepoint, e o fim do corpo vem marcado.
5. **(baixa) `drafts/sent` com o umask do ambiente.** **Curado:** nasce 0700.
6. **(baixa) A retirada imprimia o corpo cru no terminal.** **Curado:** o controle do corpo é desarmado.

Foram julgadas e ficaram sem cura:

- O `exp` não é reconferido no `read_inbox`. A retirada já confere, e um `[ok]` antigo e não lido é dado legítimo.
- O `--settings` se soma ao `settings.json` do usuário. O P0g mede a superfície na hora do teste.
- O sem-diálogo em bypass passou a ser o esperado no juiz. Isso é intencional: é o item 8 do §5 do pré-registro.

## Mutantes

A bancada `a2a_rt` tem 28 verificações, das quais 10 são mutantes mortos:

- uma 3ª ferramenta;
- um `draft_message` que chama `curl`;
- o cursor sem persistência;
- a falta de dedupe;
- o `aprovou` que vira rascunho;
- o corpo sem moldura;
- o `iss` e o `thread` sem forma;
- o frontmatter aceito sem o razão;
- a confirmação removida;
- a lombada removida.

Nos testes offline do spike entram mais 3 mutantes:

- o `--until-jti` que não para;
- o sem-diálogo sempre suspeito;
- o prefixo fixo.

## Limites declarados

- O portão de terminal prova pty (o terminal virtual), não humano. Achado 3 e Emenda 1.
- O dogfood rodou numa máquina só e não substitui a ida e volta viva entre a VPS e o notebook
  (`Q_IDA_E_VOLTA_VPS_NOTEBOOK_MEDIDA_1027` segue aberta).
