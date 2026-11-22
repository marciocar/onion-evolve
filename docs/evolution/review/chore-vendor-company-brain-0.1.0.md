---
branch: chore/vendor-company-brain-0.1.0
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: 35aa84d64ae6bf915aaad91798f017e8abff0db881eae3dcf7194cb4b53aef26
reviewed_code_sha256: 6c547a860923a525299454a92ec730aa4459a670588b4f6d47f11367dcb799a7
findings_total: 8
findings_real: 8
findings_blocking: 1
tokens: 152593
duration_min: 12
findings_fixed: 7
verdict: REJECTED_AND_FIXED
elenxo: true
elenxo_isolado: true
reviewer: "subagente general-purpose (opus), isolado, mandato REFUTAR o commit 504bfe859"
nota: "O achado 8 foi curado em parte: o parâmetro sources deixou de prometer links. A falta no guia e no help é padrão da casa: o /docs:build-compliance-docs também falta lá. O refutador rodou o lint-artifacts.sh, que estourou o timeout de 600 s (rc 124). As violações vieram da parte que rodou. O pr-finalize roda o lint inteiro."
---

# Passada adversarial: `chore/vendor-company-brain-0.1.0`

## O que muda

- Entra `vendor/company-brain/`: o recorte da tag `company-brain-v0.1.0` (commit 15af74dc), com `README.md`, `builder`, `spec`, `templates`, `tests` e `tools`, 64 arquivos ao todo.
- O carimbo `.company-brain-version` guarda a tag, o commit, o sha256 e o modo de cada arquivo.
- O verificador `.claude/validation/company-brain-vendor-check.py` tem três modos: `update`, `check` e `verify`. O `verify` lê os blobs da tag.
- A bancada é `run_company_brain_vendor_selftests`: 9 casos, com um mutante.
- O comando `/docs:build-company-brain-docs` entra como superfície do core, com o resolvedor `company-brain`. Ele chama o validador com `--if-present` quando não sabe se há persona, e para numa linha quando o motor falta.
- A skill `onion-company-brain-context` passa a apontar o comando.
- O grafo novo é `company-brain-vendor-2026-11`, com 5 nós.
- O inventário vai de 122 para 123, e as projeções foram regeneradas.

## Achados

1. **Bloqueia, curado.** Três projeções ficaram defasadas pelo próprio PR: `docs/backlog.md`, `kg-read-index.tsv` e `testing-inventory.md`, julgadas pelas REGRAS 62, 84 e 80. Foram regeneradas pelos geradores.
2. **Curado.** O `check` saía 0 com um link de diretório a mais, porque o `os.walk` não entra em link. Agora o link vira CBV-EXTRA (caso i).
3. **Curado.** Um carimbo malformado saía rc 1 com traceback. Agora o carimbo é validado por tipo e qualquer exceção sai rc 2 (caso j).
4. **Curado.** O `update` apagava qualquer destino, inclusive a fonte. Agora ele recusa destino sem carimbo do produto, destino com `.git` e destino igual à fonte ou que a contém (caso k).
5. **Curado.** O modo do arquivo não era conferido. Agora o sufixo `+x` vai no carimbo, e tirar o bit de execução dá CBV-SHA256 (caso i).
6. **Curado.** O `verify` conferia o `git archive`, que aplica `export-ignore` e `export-subst`. Agora lê os blobs por `ls-tree` e `cat-file`, e o `update` confere o caminho com `realpath`.
7. **Curado.** O pulo do caso (a) não era contado. Agora usa `record_skip`.
8. **Curado em parte.** O parâmetro `sources` prometia links sem ferramenta para abri-los, e foi corrigido. A falta do comando no guia e no help ficou como limite.

## Mutantes

- **(h)** Sem a comparação de sha256, o byte trocado passa calado. A cura o pega. O caso está na bancada.
- **À mão, na passada de cura:** sem o laço dos links de diretório, o `evil -> /etc` passa calado e a cura dá CBV-EXTRA.
- **Mutante do modo:** ele não cala, só muda o achado. Sem o `+x` calculado, os dois executáveis divergem do carimbo.

## Limites declarados

- **Teste do motor.** A conformidade do motor só roda verde de dentro do vendor com `GIT_WORK_TREE` (59 casos, 21 códigos). O teste faz `cd` para a raiz do repositório git. O pedido ao produto está em `Q_CBV_TESTE_SUPOE_RAIZ`.
- **Vendor não viaja.** O vendor não viaja para portas e adotantes, porque a lista do que viaja (`vendor-manifest.sh`) é guarda. Sem o motor, o comando para. A decisão é do maestro (`Q_CBV_VENDOR_NAO_VIAJA`).
- **Validador v1.** O validador v1 do core recusa o arquivo v2 que o comando gera. A migração está em `Q_CBV_MIGRAR_VALIDADOR_V1`, e o comando declara esse limite.
- **Repo privado.** O repo do produto é privado, e o vendor torna públicos os 64 arquivos do recorte. Isso é efeito do selo de vendorizar por tag. O recorte não traz dado de empresa.
- **Guia e help.** O comando ainda não aparece em `docs/onion/commands-guide.md` nem em `.claude/commands/docs/help.md`.
