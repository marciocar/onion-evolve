---
branch: fix/client-terms-default-core-only
date: 2026-10-13
reviewed_diff_sha256: 265413917e05d4bac586822a49cb53a08162a3d1e7dc4da69f8bef3ab9c372f3
reviewed_code_sha256: b731c0bf5befcccb1b7ff689879adfcf8a9c560667fb46489d940a5ae17f8698
findings_total: 7
findings_real: 3
findings_fixed: 2
tokens: 0
duration_min: 30
verdict: CORRIGIDO
reviewer: passada adversarial própria (sem subagente), default reprovado na dúvida. Gate mecânico: família client_terms (11/11), vizinhas projection_safety/vendor_scrub/vendor_scrub_form (39/39), consumed-mode-check, radar e contrato do grafo, lint na cópia do adotante
---

# O default da fonte privada de termos só vale na fonte

**Defeito (medido em 2026-10-13, update do adotante brain-granaai, papel hub, pin bd769f168411):**
desde o `e2757e56` a linha `CLIENT_TERMS_FILE="${ONION_CLIENT_TERMS_FILE:-$HOME/.config/onion/client-terms.txt}"`
do `projection-safety.sh` (P8) resolvia a lista de clientes DO CORE em qualquer repo da máquina. No
adotante, a REGRA 36 (Superfície VENDORIZADA sem nome comercial de cliente) acusou HARD em arquivos
PRÓPRIOS dele (a KB das integrações). Antes do `e2757e56` a lista morava dentro do core e não existia
no adotante: a P8 mudou o lugar da lista e, sem querer, o alcance dela.

**Cura (P9):** o papel vem do stamp do CWD, com a mesma leitura do `onion-version.sh`. O default do
HOME vale no papel `source` (sem stamp ou `role: source`) e em porta (`kind: door`, qualquer papel).
Fora disso o default é vazio, e a lista só entra explícita. Modo novo `--ct-state` (`source-default |
explicit | role-off`), `--emit-declared` sai rc 4 em role-off, e o lint declara
`[vendor-scrub/LISTA-EXTERNA]` (SOFT) quando um repo que não é a fonte passa a lista explícita.

## Passada adversarial

1. **O core continua protegido?** Sim. Sem stamp → `source-default` (medido no worktree). O CI do core
   passa `ONION_CLIENT_TERMS_FILE` explícita (secret) → `explicit` em qualquer papel, então nem um stamp
   falso na árvore desliga a guarda no CI. Caso (g) e mutante (g-MUT) provam o default na fonte.
2. **A porta materializada pelo core continua passando pela lista?** **ACHADO REAL, curado.** A 1ª
   versão lia só o papel: a porta standalone (carimbo `standalone`) teria saído da lista no lint dela.
   Agora `kind: door` volta a ser fonte em qualquer papel (medido: `role: standalone` + `kind: door` →
   `source-default`; `role: hub` → `role-off`; caso (h) o cobre). O `publish-door.sh` (5a) chama o helper com
   `cd "${CORE}"`, logo papel source, e não muda.
3. **Adotante que é FORK do core ou que se diz `source`?** Erra para o lado de acusar: sem stamp ou com
   `role: source`, lê a lista do HOME se ela existir na máquina. Teto declarado
   (`C_TETO_P9_PAPEL_DECLARADO_PELO_STAMP`). O sentido de calar exige um stamp de adotante no core, que
   o core não carrega por desenho, e mesmo assim o CI usa a lista explícita.
4. **A REGRA 36 deveria olhar só os arquivos do manifesto, e não os próprios?** Não neste PR. A regra
   varre as raízes de `vendor-manifest.sh --emit-scrub-roots` por desenho: a KB de um hub viaja para os
   projetos dele, e os ids de adotante continuam valendo ali. A falha veio só da lista. Menor raio de
   mudança: o recorte é pela LISTA.
5. **Em role-off, calar o NAO-VERIFICADO é fail-open?** Não. A lista do core não é objeto do adotante.
   Declarar "não verifiquei a lista de outro repo" seria o mesmo erro com cara de honestidade. O estado
   fica legível por `--ct-state`. Medido no adotante: SOFT inalterado (13), HARD 5 → 0.
6. **O modo novo tem caso?** **ACHADO REAL, curado.** O 1º dogfood no adotante acusou a REGRA 59 (Modo que
   a produção consome é exercitado pela bancada) `MODO-SEM-TESTE [--ct-state]`. O caso (h) exercita o
   modo pela borda do helper, escrito na forma que o join da REGRA 59 resolve (sem outro `${…}` antes da
   invocação na linha). `consumed-mode-check.sh` passou a 0 para `--ct-state`.

Casos: (e) hub + HOME falso com termo + arquivo próprio → 0 acusação; (e-MUT) portão trocado por
`true` → acusa. (f) hub + explícita → acusa, declara LISTA-EXTERNA, não ecoa o termo; (f-MUT) tag
trocada → a declaração some. (g) source + HOME falso → acusa; (g-MUT) default desligado → cala.
(h) os três estados + rc 4. Os casos usam papel `hub`, e não `adopted`: a folha sai da REGRA 36 antes de
ler qualquer lista (`IS_LEAF`), e um caso nela passaria por vacuidade. HOME temporário em todos, então a
lista real nunca é tocada.

Registro: `brain-granaai` carimbado `bd769f168411` por `ops/registry-pins.sh --seal --only brain-granaai`.
O update foi mergeado no adotante (PR #1571 da GranaAi/granaai, merge dd0ea769a na `onion/develop`), e
o pin está vivo no carimbo do remoto: o `--check` dá `ok`.

Registro novo: `bomtexto` (standalone, greenfield, remoto PÚBLICO desde 2026-10-13). Registrar é ato de
segurança, porque a REGRA 36 só deriva ids do registro e o nome não começa com `onion-`. Antes de
registrar, medi que o id não aparece em nenhuma raiz que o `vendor-manifest.sh --emit-scrub-roots`
emite. `members-validate.sh`: válido (28 membros). **Achado (o 7º, fora do diff):** o `registry-pins.sh`
dá DIVERGE de PAPEL nesse membro. O pin bate (`bd769f168411`), mas o carimbo vivo diz `role: standalone`,
e para adotante o par permitido é registro standalone com carimbo `adopted` (REGRA 92, Papel da porta no
registro concorda com o CARIMBO dela). Carimbo `standalone` liga o modo porta no lint. A cura é da sessão
dele (`/meta:adopt --update --role adopted`). O registro fica no tier certo e declara o desacordo num
comentário, sem carimbar por cima.
