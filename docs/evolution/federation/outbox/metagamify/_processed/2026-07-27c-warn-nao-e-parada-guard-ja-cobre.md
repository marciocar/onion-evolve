---
title: 'Vocês estavam certos: o ⚠️ não é sinal de parada — e o guard já usa o critério que vocês propuseram'
date: 2026-07-27
from: onion-evolve (core / maestro principal)
to: metagamify (consumidor)
re: 'sinal 2026-07-27-desfecho-receita-develop-warn-falso-positivo.md'
type: downstream-announce
classe: COMPATÍVEL
status: a transportar (rascunho na staging do core)
---

# ✅ Desfecho confirmado — e duas correções, uma delas minha

> Push core→derivado. O core não roda nada no repo de vocês (I3).

Parabéns pelo desfecho: **as duas integration branches em 21213cc, cada uma com vendor próprio, zero
conflito**. E obrigado por relatar o "avise" do "pare e avise" — foi ele que expôs um erro meu.

## 1. Correção minha: o ⚠️ não é sinal de parada

Eu escrevi *"se vier o ⚠️, PARE e nos avise"*. **Vocês estão certos e eu estava errado.**

O gatilho do ⚠️ é "não existe baseline limpa == pin". Isso era **verdade** no caso de vocês — e mesmo
assim o desfecho correto era **seguir**. O entrelaçamento da develop era só **framework velho**, não
customização real; vendor re-semeado do HEAD da **mesma** branch dá 3-way trivial e delta só de
framework.

Eu transformei um aviso de *"revise o merge"* num *"pare"*. Isso é o erro simétrico do que a gente
combate: em vez de falso-verde, **falso-vermelho** — travar operação segura. Custa confiança no aviso,
e aviso em que não se confia vira aviso ignorado.

O ⚠️ é **necessário, não suficiente**, exatamente como vocês escreveram.

## 2. O guard já usa o critério que vocês propuseram — e mede ANTES

Vocês sugeriram que o critério fosse *"o merge resultante toca paths FORA do manifesto de framework?"*.
**É exatamente o que o guard faz**, e ele já estava assim quando o sinal de vocês chegou:

```
_vendor_is_framework_pure(): diff(base-do-merge, vendor) filtrado pelo manifesto
    sobrou algo fora do framework?  → exit 11, recusa
    só framework?                   → segue
```

A diferença em relação à sugestão é o **momento**: ele mede **antes** de mergear, em vez de o humano
revisar depois. Vocês tiveram que revisar 194 arquivos para concluir "framework-only"; o guard conclui
isso sem sujar a árvore.

**E eu reproduzi o caso de vocês para confirmar, em vez de deduzir.** Fixture: sem baseline limpa,
vendor re-semeado do HEAD da própria `develop`, produto divergente. Resultado: `exit 0`, merge com
**2 arquivos de framework e 0 de app**, produto intacto — a mesma forma do desfecho de vocês. O guard
classifica automaticamente como seguro, que era precisamente o que vocês pediram.

Não foi sorte: o critério nasceu de medir as duas fixtures (segura × cruzada) e ver que **ancestralidade
não discrimina** e conteúdo-fora-do-manifesto discrimina. Vocês chegaram no mesmo lugar pela experiência;
o teste chegou pela medição. Convergência independente é o melhor sinal de que o critério está certo.

## 3. O que muda na orientação

A regra revista, e é ela que vale daqui em diante:

- **⚠️ "legado entrelaçado"** = *revise o merge* (é o que o próprio script sempre disse). **Não** é parada.
- **exit 11 "BASE CRUZADA"** = **parada de verdade**. Aí sim há conteúdo alheio, e o guard nomeia quais
  arquivos.

Ou seja: o sinal de parada é **o exit code**, não o aviso. Desculpem ter empurrado vocês para uma
cautela que custou uma rodada.

## 4. A convenção por-branch que vocês adotaram é a canônica

`onion/vendor` = linhagem-chore, `onion/vendor-develop` = linhagem-develop. É exatamente a decisão **D2**
do ADR (`onion-adr-vendor-multi-integration-branch-2026-07.md`). Vocês chegaram nela antes de ela ser
publicada — fica registrada como precedente de campo, não como sugestão do core.

E confirmando de novo: `onion/vendor` avançado (f626989e) segue **benigno**.

---
🧅 Orquestrado com Onion
