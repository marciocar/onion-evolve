# Onion Company Brain: o motor

Produto opcional sobre o core Onion: dá a uma empresa uma persona de serviço, um Brain que qualquer pessoa da empresa
consulta, mesmo quem não é dev. **Nem todo projeto precisa de um Company Brain**: sem uma persona de serviço
declarada, nada aqui é cobrado e o core funciona igual.

## O que o motor traz

| Pasta | O que é |
|---|---|
| `spec/voice-conduct/v2.schema.yaml` | Esquema do arquivo de voz e conduta da persona. A v1 segue aceita para migração |
| `tools/voice_conduct_check.py` | Validador. Saída 0 vale; 1 tem achados; 2 não pôde julgar, e isso nunca é verde |
| `spec/conformance/voice-conduct/` | Casos sintéticos: válidos e mutantes, cada mutante com o código que ele precisa disparar |
| `templates/company-brain-context/` | Template da página de contexto e do arquivo de regras |
| `builder/build-company-brain-docs.md` | Especificação do comando construtor. A superfície entra no core por PR do core |
| `tests/voice-conduct-conformance.sh` | Roda a conformidade e faz parte do gate local (`ops/local-gate.sh`) |

## Distribuição

O motor sai por tag, e o core o vendoriza em `vendor/company-brain` com versão fixada. Cada lado fixa a versão do
outro; nenhum código é compartilhado. O dado de cada empresa fica no Brain dela. Ao produto volta só o sinal de
forma (padrão, métrica, dor, lacuna), sem conteúdo e sem nome de cliente.

## Para quem chama o validador

- Projeto que pode não ter Company Brain: `--if-present`. Sem o arquivo, a saída é 0 e nada é cobrado.
- Rascunho do construtor antes do aceite do dono: `--allow-draft`. Sem a flag, rascunho é achado (`VC-NOT-APPROVED`).
- Saída 2 é «não deu para julgar» e nunca conta como verde.

## Conferir

```bash
bash tests/voice-conduct-conformance.sh
python3 -I tools/voice_conduct_check.py <pasta-do-contexto>/voice-conduct.yaml
```
