---
branch: ops/gpg-key-protect-durable
pr: 612
date: 2026-08-15
reviewed_diff_sha256: 60b50b64604ede2e64a55a940833ebea1eb2e89548eec2d04fab022a04d3a18b
findings_total: 3
findings_real: 3
findings_fixed: 3
tokens: 0
duration_min: 6
verdict: CONFORME
reviewer: passada própria sobre o script novo, com execução real das guardas (não leitura) — o defeito que originou o PR foi reproduzido e barrado
REVISOU: true
---

# Resíduo — `ops/gpg-key-protect-durable`

Script de operação sensível (mexe na chave GPG raiz) + um nó no grafo de fios abertos.
A revisão foi por **execução**, não leitura — que é o único jeito honesto de revisar
uma guarda:

1. **`--check` não muda nada**: rodado → `✓ chave 160D65435B1F12C8 PROTEGIDA — 2/2`,
   rc=0. Confirma também que o trabalho de 2026-08-11 está de pé (nada a refazer).
2. **Guarda de permissão** (o defeito que originou tudo): arquivo criado com `chmod 644`
   → **recusado** com a instrução do `umask 077`, rc=1 — e o arquivo foi **destruído
   pelo trap mesmo na recusa** (o caminho de erro não deixa segredo para trás).
3. **Ciência de estado**: rodado sobre o `/tmp/np.txt` real (chave já protegida, sem
   arquivo de senha atual) → recusou com o comando correto de troca, rc=1, e o arquivo
   exposto saiu por `shred -u`. **O mecanismo encerrou o próprio incidente que o motivou.**

Achados corrigidos durante a escrita (por isso `findings_fixed: 3`): a v1 assumia senha
antiga **vazia** (falharia obscuro com a chave já protegida — virou detecção por
comportamento); não tinha guarda de permissão (virou `stat` + máscara `077`); e não
tinha modo de conferência sem efeito colateral (virou `--check`).

Limite declarado: a troca de passphrase em si (chave protegida → nova senha) **não foi
exercida** — exigiria a senha atual do maestro. O caminho está escrito e guardado, mas
sua primeira execução real é dele.
