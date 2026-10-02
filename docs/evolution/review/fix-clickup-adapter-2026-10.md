---
reviewed_diff_sha256: a19346a555d11ffdf3db56651fd1a1187ade73b112c868cba4bffa65a2bf8c57
findings_total: 19
findings_real: 19
tokens: 242623
duration_min: 34
verdict: REPROVADO_E_CURADO
elenxo: sim
---

# Resíduo da passada adversarial — `fix/clickup-adapter-2026-10` (PR #902)

Refutador `opus/high` em **worktree isolada**, mandato REFUTAR, default REPROVADO na dúvida.
**19 achados, 19 reais** — 14 provados por execução, 5 por citação decisiva no próprio artefato.
Veredito do refutador: **REPROVADO**. Todos os 19 foram curados nesta branch, por isso
`REPROVADO_E_CURADO`.

## A medição que dá sentido ao resto

O lint saiu **0 HARD no `d5a00fc6`**, árvore limpa — **com os 19 achados presentes**. É a prova
executada de que `exit 0` é declaração sobre o que as guardas **cobrem**, não sobre o código estar
certo. Cada achado alto está num ponto cego nomeável:

| Achado | Por que o gate não viu |
|---|---|
| `review → testing` na List medida | não há guarda sobre o **conteúdo** de um adapter |
| `STATUS_MAPPING.clickup` sobrevivente em `types.md` | idem — e `types.md` é lido ANTES do adapter |
| `_RES_STAGED` morto | o `:-` calou o `set -u`, o único mecanismo que gritaria |
| regra `16` em vez de `8` na tabela | o `grep -qF` do caso `(a)` é **substring** |
| lente da REGRA 31 fora da tabela | nenhum `.kg.yaml` foi tocado neste PR — bastou tocar um |

## Teses que SOBREVIVERAM à refutação

- **Cura do `.tpl`**: bancada adversarial de **14 cenários** (`package.json` vazio, JSON inválido,
  diretório, sem permissão, `.lintstagedrc.js` sem `package.json`, `packageManager` maiúsculo /
  escopado / vazio / duplicado, `lint-staged` que falha e que passa) — **todos rc=0 com skip
  gracioso**, nenhum fechador precoce restante. O irmão `install-onion-githook.sh` não tem `set -e`,
  logo não tem a mesma classe.
- **Globs do escopo da REGRA 22**: `inbox/x.md` isento · `inbox/_processed/x.md` **julgado** ·
  `inbox/sub/sub2/x.md` **julgado** · espelho em `inbound/`.
- **Mutantes**: M1 (volta o pipeline antigo) → `(g)` reprova · M2 (detecção arrancada) → `(h)`
  reprova · M3 (escopo removido do lint) → a fixture acusa 3 HARD. Nenhum caso é decorativo.

## Os 4 bloqueantes, e o que cada um ensinou

1. **`review` resolvia para `testing`; `pull request` ficou fora dos sinônimos.** O adendo do
   adotante lista a List real e **propõe** `pull request`; eu pus `testing` antes e omiti o nome
   certo. Eu havia trocado um `400` por um **status errado e silencioso** — pior, porque o 400 avisa.
2. **`types.md` ainda publicava `STATUS_MAPPING.clickup`**, byte-a-byte o mapa que este PR dizia ter
   abolido. Lição de classe: **abolir um mapa no consumidor e deixá-lo na SSOT não aboliu nada** — e
   a SSOT é o que viaja vendorizado e o que a sessão lê primeiro.
3. **`_RES_STAGED` era código morto** desde o commit anterior, já em `main`. A atribuição foi
   apagada e o consumidor virou `${_RES_STAGED:-}`. O `:-` num consumidor transforma
   variável-que-sumiu em string vazia **plausível**, e plausível é o que nenhum gate questiona.
4. **O caso `(a)` da bancada era cego a número errado** (`21` casa em `21x`). Um caso que cobre
   metade do que anuncia é pior que nenhum: ele dá licença.

## Reincidência admitida

Ao ancorar o match dos pares, escrevi a linha da lente **também como substring** — o mutante M3
passou verde e me pegou, no mesmo patch em que eu curava exatamente essa classe. Está ancorada, e o
comentário no código registra a reincidência em vez de esconder.

## nota:
Dois itens mudam POSTURA e não consertam defeito, e estão nomeados no PR para veto do maestro:
(a) `can_correct_to: [onion-evolve]` para `brain-granaai` — o gate de topologia devolvia
`🚫 BLOQUEADO` para um ato que ele já praticou duas vezes em 48h (declarado≠verificado com
consequência mecânica); critério idêntico ao precedente de 2026-07-06, `trust` elevado e nunca
`role`. (b) A REGRA 5 virou HARD a 994 linhas depois das curas, e aí a fragmentação da §14.5 passou
a se justificar: `clickup-operacao.md` nasceu com exemplos, bulk, hierarquia, checklists e
troubleshooting; o adapter ficou com contrato e implementação, em 876 linhas. As **Notas
Operacionais** ficaram no adapter de propósito — ali vivem as medições, que são contrato e não
receita. TETO: a re-medição ao vivo (leitura e escrita, inclusive a List sem `review`) é do adotante;
eu provei o `.tpl` por execução e o resto pelo gate.
