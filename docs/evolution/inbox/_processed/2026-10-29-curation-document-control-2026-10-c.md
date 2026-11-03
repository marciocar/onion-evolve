---
reviewed_for_public: true  # revisado pelo core em 2026-10-29: só o id do membro, sem detalhe do hub
---

# Sinal ao core: documento controlado (document-control-2026-10)

**De:** a curadoria. **Para:** o core, com o achado também ao kg-ssot. **Data:** 2026-10-29. **Destino:** `core`.
**Estado:** proposta, revisada por agente separado. A 1ª versão foi reprovada com 10 objeções, todas curadas
(`elenxo/REVIEW.md`), e a cura do laboratório foi pré-registrada na emenda B antes de rodar. Quem decide é o maestro.

O 1º caso real é a forma do Company Brain do brain-granaai (a v2 do panorama), lida sem copiar conteúdo. O piloto,
se entrar, é do hub, pela sessão dele: o I3, um escritor por repo.

## Em uma linha

**A corrente de hashes que o contrato do grafo já tem fecha o ciclo do documento controlado sem código novo**, nos 12
casos do laboratório. Falta uma peça no selo (gravar o nó que fixa a versão aprovada). A propagação para wiki, Drive
e Slack entra como nó de cópia por camada, com um adaptador do hub.

## O que a norma pede (relido por cláusula; fontes secundárias, o texto é pago)

- **ISO 9001:2015, §7.5.2:**
  - identificação e descrição (título, data, autor ou número de referência);
  - formato e meio;
  - **revisão e aprovação** quanto à adequação, ao criar e ao atualizar.
- **ISO 9001:2015, §7.5.3:** disponibilidade, **proteção** (confidencialidade e integridade), distribuição e acesso,
  armazenamento, **controle de mudança** (a versão aparece só como exemplo), retenção e descarte, e a informação de
  origem externa. O "obsoleto" saiu na versão de 2015.
- **ISO/IEC 27001:2022, Anexo A 5.1:** a política aprovada, publicada, comunicada e **com aceite** do pessoal, e
  **revisada em intervalos planejados**. O prazo é escolha da organização; o "anual" é do mercado (GitLab, Drata,
  Vanta).
- **Anexo A 5.37:** procedimentos documentados e disponíveis. É o piloto de controle de acesso.
- **Nenhuma norma exige RACI.** A SOC 2 (CC5.3) pede responsabilidade.

## A corrente (medida no laboratório com dados sintéticos: `evidence/lab/lab_document_control.out`)

```
documento  ── provenance.sha256 do .md ─────────────► o texto        (texto mudado: trace-sha256-mismatch)
   ▲ kg-node + node_sha256
   ├── E_ da aprovação (irmão do D_ selado) ─────────► (documento regravado sem aprovar: node-sha256-mismatch)
   └── COPY_ por cópia ── FILE_ com sha256 ─────────► o PDF e o DOCX  (cópia velha, editada ou apagada: acusada)
```

| caso | o que se faz | o que o `kg_trace check` ou o `--due` dá |
|---|---|---|
| revisão vencida | `verified_at` + `reverify_every: P1Y` | `--due`: vencido há 58 dias; o JSON `kg-ssot.due/1` e o radar `STALE-EXPIRED` também mostram (é aviso, não reprovação). Sem a cadência, nada vence |
| a fonte gera as cópias | Pandoc 3.13 → HTML → WeasyPrint para o PDF; Pandoc para o DOCX | o rodapé do PDF bate com a versão **lida do nó** e o hash do nó; o rodapé com versão errada diverge (mutante); o DOCX traz a versão e o hash como propriedade |
| texto mudado depois de aprovado | "menor privilégio" vira "privilégio total de administrador" | `trace-sha256-mismatch` no documento |
| documento regravado sem nova aprovação | o hash do documento é atualizado | `node-sha256-mismatch` na aprovação e nas 2 cópias |
| cópia editada à mão, cópia apagada | — | `trace-sha256-mismatch` e `trace-target-missing` |
| mutante | a corrente sem os hashes | nada acusado |

## A tabela por peça

| peça | o que roda no Onion (medido) | proposta |
|---|---|---|
| dono e RACI | `owner` no contrato (o A); `x_raci` aninhado (`responsible`, `accountable`, `consulted`, `informed`), lido pelo `--where x_raci.responsible=X` da 4.39.0 (medido) | **entra** como convenção **do adotante**, na forma que o kg-ssot pediu; vira perfil canônico quando dois adotantes usarem a mesma forma |
| identificação e versão | o id do nó, o `x_doc_version` e o `node_sha256` | **entra**; a tabela de revisões no documento, como faz a comply, é opcional do adotante |
| revisão periódica | `reverify_every`, `--due` e radar | **entra sem código novo**. O gatilho é o radar ou o `/warm-up` na sessão do hub, porque o hub não tem CI. É aviso, não reprovação |
| aprovação que fixa a versão | o par de nós (`D_` com o testemunho e `E_` irmão com o `node_sha256`, aresta `E_ SUPPORTS D_`), medido; o `--decision` da 4.39.0 lista o `E_` como o que sustenta a aprovação | **entra com uma peça nova**: um `--pin <caminho#ID>` no `kg-decide-seal.sh` que grava o `E_` irmão, sem mexer na proveniência do testemunho. **O desenho passa pelo kg-ssot antes.** O aprovador é o A do documento; o CODEOWNERS exigiria branch protection, que dá 403 em repo privado sem GitHub Pro |
| uma fonte gera as cópias | Pandoc e WeasyPrint, medidos | **entra** como receita do adotante |
| cópia desatualizada, editada ou apagada | `COPY_` + `FILE_` por cópia, medidos | **entra sem código próprio**: o checador de cópias da 1ª versão saiu |
| propagação para wiki, Drive e Slack (a maior dor) | nada | **piloto do hub**: um `COPY_` por camada, com `x_copy_layer`, `x_copy_url` e o hash do que foi publicado. O adaptador do hub publica e regrava. No Drive, o `files.update` com conversão mantém o mesmo `fileId` e o link (doc da API, não medido). **Não cobertos:** os comentários em 3 canais e o Slack |
| aceite pelo pessoal | nada | **do hub**: é exigência da 27001 (A 5.1) quando aplicável. O mercado usa SaaS (Drata, Vanta), que não entra no núcleo |
| proteção e público × privado | o grafo do hub fica no hub | **do hub**; o core recebe só a forma |
| obsoleto e retenção | `retain_for`, `superseded` com `SUPERSEDES` | **entra** com o que existe |
| evidência contínua | o vigia de eventos, decisão aberta no core | **sai** deste estudo |

**Superação buscada:** a strongdm/comply (aberta, gera PDF por Pandoc) está dormente desde 2022 e não tem dono,
aprovação nem cadência. Não bate o desenho; dela vêm a tabela de revisões e o mapa documento → controle.

## Achado da 4.39.0 para o kg-ssot

O `--revisit` **não acende** quando o documento muda depois da aprovação, nem com o hash regravado (medido). Pelo
código, ele julga só a cadência vencida e o REFUTES. O `upstream_changed` compara o **status**, não o hash, e só de
apoio em outro repositório. A mudança de conteúdo depois da aprovação só aparece no `kg_trace check`
(`node-sha256-mismatch`). A proposta ao kg-ssot é um motivo de revisita "o hash fixado mudou", para a aprovação
aparecer na fila de revisão, e não só no check.

## O que o core decide

1. O `--pin` no `kg-decide-seal.sh`, que grava o nó irmão. Antes, levar o desenho ao kg-ssot.
2. Que `x_raci`, `x_doc_version` e `x_copy_*` ficam como convenção do adotante por ora, como o kg-ssot propôs.
3. Levar ao hub a receita do piloto, nesta ordem:
   1. o procedimento de controle de acesso como nó com dono e RACI;
   2. a cadência;
   3. a fonte gerando PDF e DOCX;
   4. o `COPY_` por camada;
   5. a aprovação com o par de nós.

## Capitalizar

Quem fatura no mercado é o SaaS de compliance (Vanta, Drata, Secureframe), por assinatura: o cliente paga para passar
na auditoria. O Onion faz o ciclo local, sem dependência externa. A via de bilhetagem é o hub vendendo o Company
Brain auditável, decisão do maestro.

## Não verificado

- O texto verbatim da ISO 9001:2015 e do Anexo A da 27001:2022 (só reprodução secundária).
- O RACI no PMBOK.
- O rodapé visível do DOCX (exige o Word).
- O `files.update` do Drive mantendo o link (doc, não medido).
- A perda de comentários no Docs.
- A doc do DocuSign.
- As rodadas e os valuations da Vanta, da Drata e da Secureframe.
- Se o hub tem branch protection.
