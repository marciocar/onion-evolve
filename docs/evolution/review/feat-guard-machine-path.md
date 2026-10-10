---
reviewed_diff_sha256: 618b70ecc025d4f0243ca75f3f1b8f7af0f10430a8924210388246f3fa630b20
reviewed_code_sha256: ce1242b3a22fb065e95cf3c85f9655ea67ad82d86a78fa0b93720b1f23d53ee6
findings_total: 11
findings_real: 6
tokens: 106308
duration_min: 5
verdict: APROVADO
elenxo: sim
nota: >
  Refutador opus com mandato de FALSO POSITIVO (a doutrina da guarda: falso positivo treina a sessão
  a ignorar o veto), sobre bfaee623. Veredito dele: APROVA COM RESSALVAS — zero falso positivo em nó
  do corpus; uma classe de falso positivo medida na prosa do repo; quatro falsos negativos baratos.
  Cinco curados no mesmo laço, e a cura do segmento único expôs um sexto (no corpus), também curado.
  As outras classes são de frase sintética, sem ocorrência no repo, e ficaram declaradas como teto.
  APROVADO é o estado depois das curas. Depois do 1º push, o CI (kg-fixture-paths (c)) acusou uma
  string de TESTE no selftest que imitava o grep-próprio de fixture; trocada por outro glob relativo
  (só o caso cala: glob relativo mudou; revisto por mim, sem efeito na classe).
---

# Resíduo — `feat/guard-machine-path`

A REGRA 99 (Nó de .kg.yaml sem caminho de máquina, julgado pela classe), forjada pelo
`/meta:forge-guard` para o SAC-103 (selo P3 da onda O5). A classe mora em
`.claude/utils/kg/machine_path.py`.

## A passada adversarial (caça ao falso positivo)

O refutador montou um banco de frases realistas, entre elas comandos de slash sem dois-pontos, rotas,
URLs sem scheme, frações, datas, `~` de aproximação, globs, regex, citações de CHANGELOG e caminhos de
contêiner. Usou também a prosa de 227 `.md` de `docs/knowledge-base` e `docs/evolution/research` como
proxy, porque o corpus de grafos já foi limpo pela mesma classe e "zero lá" não prova nada.

| # | lado | achado | desfecho |
|---|---|---|---|
| F1 | FP, **medido na prosa** (2) | a crase que FECHA seguida de raiz no sentido de "ou" (`` `plane:`/`status:`/etc. ``, `` `onion`/root ``) | curado: a crase só abre token quando ela abre; casos novos no selftest e mutante |
| F2 | FP sintético | rota HTTP ou chave de config com nome de raiz (`/home` do site, `/media/upload`, stage `/dev`) | **teto** `C_TETO_ROTA_COM_NOME_DE_RAIZ`: calar a raiz nua abriria FN real |
| F3 | FP sintético | tag de fechamento (`</var>`, `</root>`) | curado: `<` não abre token; `< /etc/x` com espaço segue acusado |
| F4 | FP sintético | padrão ancorado de `.gitignore` | teto (indistinguível de caminho real) |
| F5 | FP sintético | `~linear/quadrático` | não curado: os 3 casos reais de `~palavra/` são acertos; o risco é hipotético |
| F6 | menores | `sed 's\|/tmp\|x\|'`; raiz app depois de verbo de shell; `/home:x` | teto (no mesmo nó do F2) |
| F7 | FN | `cd /workspace` (1 segmento) calava | curado: o argumento de shell aceita um segmento; mutante |
| F8 | FN | `‘/tmp’` e `→/home` calavam | curado: `‘` e `→` abrem token |
| F9 | FN | hostname em maiúsculas calava | curado: `re.I`; mutante |
| F10 | FN | shebang cala | declarado (genérico, não é desta máquina) |
| F11 | **FP exposto pela cura F7, no corpus** | `ls -la docs/<dominio-t2>/graph/…` em colaboracao-onion-2026-07: o `>` que fecha o placeholder, depois de um dígito, era lido como `2>` | curado: o redirecionamento exige que o dígito ABRA o token; caso e mutante |

Achados reais curados: F1, F3, F7, F8, F9 e F11. Ficaram como teto declarado: F2, F4, F5, F6 e F10.

## Antes e depois, medidos

- **Corpus vivo:** 147 grafos, 0 acusações e 3 nós isentos (9 ocorrências: 2 nós com `citação`, 1 com `receita`).
- **Corpus pré-ondas** (`e03952c2`, 2026-10-08): 247 ocorrências em 180 nós, iguais antes e depois das curas.
  - Contra a regex antiga (O7): 201 valores casados pelas duas, 0 só pela antiga e 1 só pela nova.
- **`--selftest`:** 44 casos.
- **Bancada:** `kg_machine_path` com 28/28, sendo 20 mutantes de classe; `kg_contract_check` e `kg_migrate_v3` verdes.
- **Mutantes de produção, aplicados à mão, todos mordem:** o dispatcher, `worse_mp`, `mp_before` e a catraca.

## Os `confirmed` do grafo que este PR edita

- **`E_REEXECUCAO_DOS_COMANDOS_REAIS`** (vetos-por-tokens-2026-10). Só o literal do caminho no label foi reescrito pela forma (⟨outro repo por caminho absoluto⟩). A afirmação não muda e o literal segue nos rótulos `_case` da bancada.
- **Os `confirmed` novos de `machine-path-2026-10`** são todos medidos nesta sessão, com o comando no `verified_against`.

## O que fica de fora, dito

Os tetos do grafo: `C_TETO_RAIZ_QUE_NAO_E_DE_SISTEMA`, `C_TETO_VARIAVEL_WINDOWS_E_FORA_DE_NO`,
`C_TETO_HOSTNAME_DE_OUTRA_MAQUINA`, `C_TETO_MARCADOR_AUTODECLARADO`, `C_TETO_VERBOS_DE_SHELL_SAO_LISTA`,
`C_TETO_FALAR_DA_FORMA_EXIGE_PERIFRASE` e `C_TETO_ROTA_COM_NOME_DE_RAIZ`.
