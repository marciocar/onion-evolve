# Vendored assets — kg-console rich renderer

Estes arquivos são JS de terceiro **vendorizado** (não npm, não build): o `kg-console.sh`
os `cat`-inclui inline no HTML autocontido (CSP-safe, zero rede). Congelados por proveniência.

| Arquivo | Versão | Origem | SHA-256 | bytes |
|---|---|---|---|---|
| cytoscape.min.js | 3.34.0 | https://unpkg.com/cytoscape@3.34.0/dist/cytoscape.min.js | `9c2a3bf2592e0b14a1f7bec07c03a54f16dedf32af9cd0af155c716aa6c87bc3` | 435328 |

## Por que só o Cytoscape core (sem fcose/expand-collapse)

O layout `cose` é **embutido** no core — dá a física de entrada que "respira" sem extensão.
Foco de vizinhança, filtros, colapso-por-cluster, glow/pulse e partículas são implementados à
mão sobre a API do Cytoscape (`.neighborhood()`, classes, canvas layer) no template do
kg-console.sh. Isso mantém o vendoring em **um único arquivo** — fiel ao ethos "um artefato"
do Onion e sem a cadeia frágil de dependências do fcose (cose-base + layout-base).

## Atualizar

Rebaixar/subir versão é ato deliberado: rebuscar a URL, conferir o SHA, atualizar esta tabela.
Licença: MIT (The Cytoscape Consortium). Mantida no cabeçalho do próprio .min.js.
