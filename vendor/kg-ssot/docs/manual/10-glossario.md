# 10. Glossário

[← Solução de problemas](09-problemas.md) · [Índice](README.md)

| Termo | Significado |
|---|---|
| **Adotante** | Um repositório que traz o contrato por tag e roda o gate no CI |
| **Aresta externa** | Uma aresta de `external_edges`, com uma ponta noutro grafo do mesmo repositório |
| **Carimbo (do vendor)** | O arquivo `.kg-ssot-version` com a tag, o commit e o sha256 de cada arquivo trazido |
| **Carimbo de verificação** | O par `verified_at` e `verified_against` de um nó |
| **Catraca** | Uma conferência que só deixa a medida melhorar ou ficar igual. O gate é a catraca por grafo |
| **Classe (de `method`)** | `medição`, `leitura`, `juízes`, `derivado` ou `testemunho` |
| **Código** | O identificador estável de uma violação, como `form.required.node.label` |
| **Contrato** | Os schemas MUST e SHOULD mais as regras de perfil YAML e de integridade |
| **Corpus** | O conjunto de `.kg.yaml` de um repositório |
| **Dívida herdada** | Os grafos que já reprovavam no MUST quando a base foi gravada |
| **Dívida SHOULD** | Quantos grafos (ou ocorrências) carregam cada aviso |
| **Grafo** | Um arquivo `.kg.yaml` |
| **Leitor** | Qualquer programa que lê `.kg.yaml`. O leitor de referência é o `kg_validate.py` |
| **Linha de base** | O `.kg-ssot/gate.json` com a dívida que o gate compara |
| **MUST** | Nível do contrato que reprova |
| **Nó** | Uma afirmação tipada do grafo |
| **Órfão** | Um nó sem nenhuma aresta. Reprova |
| **Perfil `gate`** | A parte mínima da release: o suficiente para rodar o gate e o check |
| **Plano** | `DEV` ou `PROD` |
| **Proveniência** | O objeto `provenance` (`source`, `locator`, `method`): de onde veio a afirmação |
| **Rampa** | Duas acepções: (1) no contrato, alertar numa versão o que vai reprovar na seguinte; (2) na adoção, subir de versão maior registrando o que passou a reprovar como dívida, e pagar aos poucos |
| **Release** | Uma tag `kg-ssot-vX.Y.Z` com a superfície listada em `spec/release.json` |
| **Runner** | O comando que expõe um leitor à suíte: `runner <caso>` imprime um JSON com o veredito |
| **SHOULD** | Nível do contrato que só alerta |
| **Suíte de conformidade** | Os casos em `spec/conformance/` que todo leitor tem de passar |
| **Testemunho** | Relato, ou medição de terceiro que você só leu |
| **Vendor** | A cópia da release dentro do adotante, em `vendor/kg-ssot`, conferida pelo `check` |
| **`x_`** | O prefixo de extensão: chaves com ele passam livres |
