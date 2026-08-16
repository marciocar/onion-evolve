---
branch: docs/corpus-transfer-measured
pr: 621
date: 2026-08-16
reviewed_diff_sha256: 7c8bc6c4a17bed098f0a6371693c2894611b167a8735ab0dc0c2e6f82008932d
findings_total: 2
findings_real: 2
findings_fixed: 2
tokens: 0
duration_min: 25
verdict: CONFORME-COM-ACHADO-CONTRA-O-CORE
reviewer: passada sobre o DESENHO da medição — porque aqui um zero mal interpretado acusaria o adotante por uma falha nossa
REVISOU: true
---

# Resíduo — `docs/corpus-transfer-measured`

A medição valia pouco se os zeros não fossem desambiguados. Foi nisso que a passada rendeu.

**Achado 1 — ausência ≠ vazio, e aqui invertia a conclusão.** A primeira varredura devolveu
"0 resíduos R56, 0 diários, 0 grafos" em quase todos. Lido cru, isso diz "adotante não usa a
metodologia". Refeito distinguindo **diretório ausente** de **diretório vazio**, e depois
verificando **o que foi vendorizado**, o quadro virou: `review-artifact-check.sh` **nunca foi
embarcado em nenhum adotante**. O zero era **nosso**, não deles. A medição que o revisor
sugeriu ("contar .kg.yaml e docs/evolution/review/ nos adotantes") teria produzido a
conclusão errada com números certos.

**Achado 2 — o número que decide não era nenhum dos sugeridos.** Não é quantos grafos
existem: é **quantos adotantes rodam a maquinaria em CI** — 1 de 7. Guarda presente como
arquivo e ausente do CI é guarda inalcançável, classe que o core já registrou em si mesmo
(2026-08-02). Sem isso, ter 40 scripts vendorizados é inventário, não capacidade.

**Limite declarado:** medi o **disco local** dos adotantes, que pode estar atrás do remoto
deles (o metagamify, por exemplo, tem `.claude` tocado por último em 25/07). Um adotante
pode ter CI e prática no remoto que meu clone não vê. Para virar veredito definitivo, a
mesma contagem precisa rodar contra os remotos — está nomeado, não feito.
