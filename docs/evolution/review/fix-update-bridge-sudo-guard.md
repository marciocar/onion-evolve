---
branch: fix/update-bridge-sudo-guard
pr: pendente
date: 2026-08-14
reviewed_diff_sha256: 7883960cfecb5c0c15ee7de513f0051d9321d3cedbb7bc5770cdea12a9253fee
findings_total: 1
findings_real: 1
findings_fixed: 1
tokens: 0
duration_min: 8
verdict: CORRIGIDO
reviewer: o próprio mecanismo (2 deploys abortados) + medição direta (test -d como marcio = false; sudo test -d = true) — diff de 2 linhas + carimbo de KG
---

# Resíduo — `fix/update-bridge-sudo-guard`

O guard `[ -d node_modules ]` do update-bridge rodava SEM sudo — marcio não atravessa
/home/onion (750) e o guard mentia DIR-AUSENTE com o diretório são. Matou o deploy do G0
(que diagnostiquei ERRADO como "npm transiente" — a F0 subiu por triagem manual) e o da F2,
até a medição direta reconhecer a classe: a MESMA lição já escrita em prosa no
bridge-backup.sh ("o teste TAMBÉM passa por sudo — senão o guard mente"). Cura: sudo test
nos dois sítios. O diff inclui o carimbo F2→done/PROD no KG do programa (provas: threads
401 sem token, SPA fallback, bench 22 testes, gzip 253KiB) com o 13º Elenxo registrado.
