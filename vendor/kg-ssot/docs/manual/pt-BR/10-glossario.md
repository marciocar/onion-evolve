<!-- translation-of: docs/manual/10-glossary.md sha256:c532eae5bd6ff412 -->
# 10. Glossário

[English](../10-glossary.md) | **Português (Brasil)**

<sub>Tradução do original em inglês; quando os dois divergirem, vale o inglês.</sub>

[← Solução de problemas](09-problemas.md) · [Índice](README.md)

| Termo | Significado |
|---|---|
| **Adotante** | Um repositório que traz o contrato por tag e roda o gate no CI |
| **Aresta externa** | Uma aresta de `external_edges`, com uma ponta noutro grafo do mesmo repositório |
| **Carimbo de verificação** | O par `verified_at` e `verified_against` de um nó |
| **Carimbo do vendor** | O arquivo `.kg-ssot-version` com a tag, o commit, a versão, o contrato e o sha256 de cada arquivo trazido |
| **Catraca** | Uma conferência que só deixa a medida melhorar ou ficar igual. O gate é a catraca por grafo |
| **Classe (de `method`)** | `medição`, `leitura`, `juízes`, `derivado` ou `testemunho` |
| **Código** | O identificador estável de uma violação, como `form.required.node.label` |
| **Contrato** | Os schemas MUST e SHOULD, mais as regras de perfil YAML e as regras de integridade |
| **Corpus** | O conjunto de grafos (`.kg.yaml` e `.kg.json`) de um repositório |
| **Critério pré-registrado** | Uma régua fixada antes do dado, um nó por versão (`x_criterion`, com o `sha256` dela); o resultado cita a versão sob a qual foi medido (`x_measured_under`), e a mudança depois de ver o dado é uma emenda datada, desde o v4.12 |
| **Dívida herdada** | Os grafos que já reprovavam no MUST quando a base foi gravada |
| **Dívida SHOULD** | Quantos grafos (ou ocorrências) carregam cada aviso |
| **Grafo** | Um arquivo `.kg.yaml`, ou a forma JSON dele, um arquivo `.kg.json` |
| **Leitor** | Qualquer programa que lê `.kg.yaml` (ou `.kg.json`). O leitor de referência é o `kg_validate.py` |
| **Linha de base** | A pasta `.kg-ssot/gate/` com a dívida contra a qual o gate compara: a identidade do contrato e um registro por grafo (até a 4.15.1, o arquivo único `.kg-ssot/gate.json`) |
| **MUST** | O nível do contrato que reprova |
| **Nó** | Uma afirmação tipada do grafo |
| **Órfão** | Um nó sem nenhuma aresta. Reprova |
| **Pacote de auditoria** | Uma linha por item de questionário, com a pergunta, a resposta, o veredito, a evidência datada, os pedidos de evidência, o dono e as lacunas calculadas, em CSV, XLSX ou JSON (`kg_audit.py`), desde a 4.22.0 |
| **Perfil canônico** | A forma que o SHOULD dá a uma chave `x_` que os adotantes repetem (`x_term`, `x_mirror`, `x_severity`...), desde o v4.11; `x_criterion` e `x_measured_under` desde o v4.12. Só julga a chave presente, e só alerta |
| **Perfil `gate`** | A parte mínima da release: o suficiente para rodar o gate e o check |
| **Plano** | `DEV` ou `PROD` |
| **Proveniência** | O objeto `provenance` (`source`, `locator`, `method`): de onde veio a afirmação |
| **Rampa** | Duas acepções: (1) no contrato, um aviso numa versão sobre o que vai reprovar na seguinte; (2) na adoção, subir de versão maior registrando o que passou a reprovar como dívida, e pagar aos poucos |
| **Release** | Uma tag `kg-ssot-vX.Y.Z` com a superfície listada em `spec/release.json` |
| **Runner** | O comando que expõe um leitor à suíte: `runner <caso>` imprime um JSON com o veredito |
| **SHOULD** | O nível do contrato que só alerta |
| **Suíte de conformidade** | Os casos em `spec/conformance/` que todo leitor tem de passar |
| **Sinônimo** | Um item de `x_term.labels`: outro jeito de escrever o termo, `alt` ou `hidden`, com fonte, versão do documento e data de conferência próprias |
| **Termo** | Um nó com o perfil `x_term`: o rótulo preferido de um conceito num vocabulário de domínio, com os sinônimos |
| **Testemunho** | A classe `testemunho`: o relato de alguém, ou a medição de terceiro que você só leu |
| **Vendor** | A cópia da release dentro do adotante, em `vendor/kg-ssot`, conferida pelo `check` |
| **`x_`** | O prefixo de extensão: chaves que começam com ele passam livres |
