---
branch: fix/selo-m8-vereditos
date: 2026-08-07
reviewed_diff_sha256: 4a68689fd1708aa3329ac6a9eb94dbcef9be42840ee66c5a73daddcd9fb8a8b9
findings_total: 24
findings_real: 24
findings_fixed: 6
tokens: 500069
duration_min: 17
verdict: TRES-TESES-CAIRAM
reviewer: Elenxo — 4 refutadores por lente + juiz (opus/high), wf_b67a7745-713
---

# Passada adversarial — a correção do selo do M8 sob ataque

**4 refutadores, lentes distintas, 24 ataques, 0 descartados** pela regra mecanizada *refutação sem
`superacao` é DESCARTADA* (todos vieram com superação concreta — o filtro rodou e não teve o que cortar).
**Nenhuma das quatro lentes falhou**, e o juiz verificou cada alegação de fato rodando comando, não
aceitando o refutador por autoridade.

## Veredito por tese

| tese | veredito |
|---|---|
| **T1** — o selo do M8 estava pela metade, e isso é defeito | **SOBREVIVE-RESTRINGIDA** — diagnóstico verdadeiro e escopo conferido (os 9 ids são exatamente a fila do motor), mas a correção reproduz o mesmo modo de falha uma camada acima, em 4 pontos |
| **T2** — a causa foi o schema não permitir antes da Fase 3a | **CAI** |
| **T3** — não superseder é correto porque o contrato exige juiz acima de 30% | **CAI** |
| **T4** — restaurar a posição apagada é exigido pela Aufhebung | **SOBREVIVE-RESTRINGIDA** — o princípio é contratual (linha 139 + o parágrafo da Aufhebung) e as acusações de scope creep e de `verified_at` em nó superado não se sustentam; mas 3 restrições medidas |
| **T5** — a Fase 3c não se justifica, o falsificador barra | **CAI** |

## As três quedas

**T2 é a mais grave, porque eu havia me absolvido com ela.** Escrevi no commit que *"o run não tinha
como selar certo"*. Falsificada por medição direta: `git show e054d69^:.claude/validation/kg-radar.sh`
mostra o enum pré-#554 com **`superseded → 0.2`** — e `superseded` é exatamente o que a linha 139 do
contrato prescreve para DRIFTED. O que o enum antigo rejeitava era **uma forma** (`status: drifted`, a
que eu escolhi), nunca a escrita prescrita. E há precedente vivo do **mesmo comando 10 dias antes**:
`m2-bridge-logto-2026-07.kg.yaml:1847`, dogfood de 2026-07-27, com o alvo em `status: superseded` sob o
schema antigo. **Alcance da desculpa: zero dos 9 vereditos.** A causa é **contrato não executado**.

**T3 caiu na leitura do arquivo.** A única ocorrência de "juiz" em `kg-freshness.md` está na linha 117,
dentro do **Passo 3** (95–133), num parágrafo que começa literalmente com `Tiering:` — escolha de
modelo/esforço, não precondição de escrita. O Passo 4 chama-se *"Fan-in, gate humano, e só então
`write(KG)`"* e não menciona juiz nenhuma vez. O gatilho de 30% aciona **tier**, não veto. Pior: eu
apliquei o veto **pela metade** — escrevi 9 status derivados dos mesmos vereditos não-adjudicados e
recusei só a operação que a tabela manda. Se o juiz travasse, travaria tudo.

**T5 inverteu a tese do próprio nó.** `onion-identity-2026-07.kg.yaml:892`, verbatim: *"o SELO NAO TEM
FORCING FUNCTION. Com NS1 escolhido, este laco E O PRODUTO operando a 21%, nao divida de higiene."* Usei
como barreira à mecanização um nó que argumenta pela mecanização. E o falsificador pede **medição** — e
a medição agora aponta ao contrário: **dois selos manuais consecutivos do mesmo run, defeituosos os dois.**

## O erro de fundo — o ponto cego que os 24 ataques não fecharam de saída

Dois refutadores viram que `ENT_whatsapp` não podia ser `drifted` por já carregar a verdade medida.
**Nenhum notou que isso vale para os quatro.** O `#552` reescreveu ou apensou o label de todos, então
nenhum diverge do vivo hoje.

Usei `status: drifted` como marcador de **PROCESSO** (*"veredito do run não adjudicado"*) num campo que
o motor define como marcador de **ESTADO** (`kg-radar.sh:78-79`). Duas consequências medidas:

1. nós corretos e recém-medidos ocupando o topo do radar, afundando drift real;
2. a aresta `SUPERSEDES` recém-criada ficou **invisível** à seção RECONCILIAÇÃO, porque
   `kg-radar.sh:233` só conta quando o superseder está `confirmed`. O refutador provou em sandbox com
   o status como única variável: **MUT A** (superseder `drifted`) → `✅ nenhum alvo por reconciliar`
   (falso-verde); **MUT B** (`confirmed`) → dispara o `⚠`.

**O `✅` que a 1ª passada citou como verificação não podia reprovar.** Fail-open dentro do PR que
existe para curar fail-open.

## A única acusação em que o artefato afirmava algo que o mundo desmente

O nó restaurado canonizava, em label **e** em `verified_against`, que a medição *"não achou processo,
container, unit nem diretorio"*. Verifiquei eu mesmo no host, sem tomar o refutador como fonte:

```
$ sudo find /home/onion/onion-bridge/workspaces -maxdepth 2 -name whatsapp-sender
/home/onion/onion-bridge/workspaces/7f2a16301adad917/whatsapp-sender     ← EXISTE
$ sudo ls -d /home/onion/whatsapp-sender
ls: cannot access '/home/onion/whatsapp-sender': No such file or directory
```

O diretório **existe**; o que não existe é o **serviço**, e o caminho que a afirmação superada dava. E o
próprio grafo, 200 linhas acima, já registrava a ressalva — `grep -c 'nem diretorio'` dava **2**: uma
linha afirmando, outra negando. Aufhebung preserva a posição superada; **não ressuscita a medição errada
que a superou.**

## O que foi corrigido, na ordem que o juiz estabeleceu

| # | correção | verificação |
|---|---|---|
| 1 | a cláusula falsa, nos 2 campos do nó e no corpo do commit | `grep -c 'nem diretorio'` cai de 2 para 1 (só a que nega) |
| 2 | os 4 `drifted` → `confirmed`; `C_dominio_bridge_vivo_ate_0806` + aresta (a Aufhebung do 2º apagamento) | RECONCILIAÇÃO passa a **acusar** sob mutação — o `✅` deixou de ser vácuo |
| 3 | UNVERIFIABLE completo: `confidence` 1.0→0.5 + `question` + `DEPENDS_ON`; proveniência nos 3 nós faltantes | 9/9 nomeiam o run (eram 6/9) |
| 4 | contrato + KB alinhados ao motor | motor aceitava 6 status, docs documentavam 5 — vão aberto pelo **#554, meu** |
| 5 | a dívida sai da prosa do commit e vira nó | `Q_juiz_adversarial_nao_rodou_m8`, `Q_email_logto_conector_nunca_medido` |

**Uma alegação de fato foi REJEITADA pelo juiz:** a de que o `#552` teria reescrito **quatro** labels. A
classificação mecânica (*o label novo começa com o antigo?*) dá **2 reescritos** (`ENT_substrate`,
`ENT_whatsapp`) e **2 apensos**, que preservam o texto antigo como prefixo — nos apensos não há posição
a restaurar. Restaurei 2, não 4.

E o radar pegou um defeito meu **durante** a correção: `Q_juiz_adversarial_nao_rodou_m8` nasceu órfão
(grau 0), `--integrity` exit 1. Ligado por `CONSTRAINS` aos dois nós que a dúvida constrange.

## Fios que saem daqui, declarados e não escondidos

- **Fase 3c — `kg-seal-check.sh`**, agora com gatilho **provado por medição** (dois selos manuais
  consecutivos, defeituosos os dois), não por vontade. Teste de aceite declarado **antes** de construir:
  rodado contra `964ab1c` + o ledger do M8 tem de acusar **9/9**; contra esta branch, só o resíduo. *Se
  não acusar 9/9, o gatilho não estava provado e a guarda não entra.*
- **Calibração de `kg-radar.sh:233`** — estender a contagem de SUPERSEDES a superseder `drifted` (é nó
  vivo, fator 1.3, não é o caso `open` que o comentário justifica), com caso de selftest reproduzindo a
  MUT A. Mudança de **motor**, fora deste PR.
- **Rodar o juiz adversarial** sobre os 4 vereditos, agora com razão reforçada: o worker do M8 **errou de
  fato** numa medição, e foi leitura humana que pegou. Um contraditório teria pego mais barato.
