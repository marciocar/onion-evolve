# === onion — vendor + SSOT gerado (provisionado por /meta:adopt; não remover) ===
.claude/
docs/meta-specs/
docs/sdaal/
docs/knowledge-base/
# contrato do .kg.yaml vendorizado: o .kg-ssot-version guarda o sha256 de cada arquivo, e reformatar o faria mentir (SAC-149)
vendor/kg-ssot/
# SSOT gerado por máquina (inventory.sh) — precisa bater byte-a-byte com o lint; prettier quebra o match
docs/onion/inventory.md
