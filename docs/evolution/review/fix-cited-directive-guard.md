---
reviewed_diff_sha256: bb8a5da0d2708e309b522ac10a1af25fdc047721f17c2fcd67c014692442a9b6
findings_total: 10
findings_real: 10
tokens: 139447
duration_min: 8
verdict: APROVADO
elenxo: sim
nota: >
  Elenxo opus em worktree isolada REPROVOU a 1a versão da REGRA 98: falso positivo estrutural
  depois de diretiva-bloco, um terço do motor nunca rodando, e 184 divergências por fuzz entre a
  transcrição Python e o binário. A cura de raiz foi trocar a transcrição por CÓPIA LITERAL das
  funções do binário, em node. Os dez achados foram curados ou declarados no teto; doze mutantes
  mordem, inclusive os quatro que sobreviviam. APROVADO é o estado depois das curas.
---

# Resíduo — `fix/cited-directive-guard`

A REGRA 98 (Diretiva de injeção escrita como CITAÇÃO não pode estar VIVA), forjada pelo
`/meta:forge-guard` sobre o defeito datado de 2026-10-04 (o `/meta:create-skill` rodava `git diff`
a cada invocação).

## O que o refutador derrubou, e o que foi feito

| # | sev | achado | desfecho |
|---|---|---|---|
| F1 | alta | a cerca de fechamento de uma diretiva-bloco ABRIA bloco: toda diretiva real depois era acusada | curado — toda cerca alterna; caso (c2) |
| F2 | alta | a regex de bloco era compilada e nunca usada: bloco citado em cerca de 4 crases e bloco em prosa passavam | curado — motor é o `bGn` do binário; casos (b1), (b2) |
| F3 | média | cerca recuada, cerca de til e bloco por recuo escapavam; til com crase interna invertia o estado | curado (recuo/til, mesmo caractere e comprimento); **bloco por recuo de 4 espaços declarado no TETO** |
| F4 | média | transcrição infiel: 184 divergências por fuzz; comando reportado errado | curado na raiz — cópia literal em node; paridade conferida nos dois lados |
| F5 | média | crase dupla em qualquer ponto da linha contaminava a diretiva real | curado — o span tem de CONTER a diretiva; caso (c3) |
| F6 | média | motor que morre saía rc=1 calado e o dispatcher só escalava rc≥2 | curado nos dois lados (helper e dispatcher); caso (e) da família |
| F7 | média | M4/M5/M6/M9 sobreviviam; o dispatcher desligado deixava a família verde | curado — casos (d) produção e (f) paridade; 12/12 mutantes |
| F8 | baixa | blockquote e comentário HTML executam e não eram vistos | curado — casos (b5), (b6) |
| F9 | baixa | arquivo não-UTF-8 virava ILEGÍVEL HARD | curado — node lê com substituição, como o harness; declarado no TETO |
| F10 | baixa | comentários da REGRA 96 ainda diziam que bloco cercado e crase dupla são citação | curado — os três trechos corrigidos |

## O que fica de fora, dito

Bloco de código por recuo de 4 espaços (exige parser de markdown; um falso positivo ali vetaria toda
lista com diretiva). Diretiva montada por `$ARGUMENTS`. CRLF não foi medido.

## Os `confirmed` do grafo que este PR edita

- `E_DEFEITO_CITACAO_EXECUTADA` (impacto 5) — o defeito datado; a guarda o acusa contra o estado
  anterior à cura e cala depois dela. Revisto: continua verdadeiro.
- `E_DOZE_MUTANTES_DEPOIS_DO_ELENXO` (impacto 5) — os doze mutantes que mordem; nasceu substituindo
  `E_SEIS_MUTANTES_MORDERAM`, a afirmação falsa da 1ª versão, preservada como `superseded`.
- `C_TETO_REGEX_TRANSCRITAS_DE_UMA_VERSAO` e `C_TETO_PROSA_NUA_E_AGENTES` — os tetos, agora sobre a
  cópia literal; o 1º ganhou a paridade nos dois lados e, no CI sem binário, o lado da cópia.
