---
branch: feat/caddy-service-vhosts
pr: pendente
date: 2026-11-22
reviewed_diff_sha256: pendente
findings_total: 12
findings_real: 12
findings_blocking: 2
tokens: 155444
duration_min: 6
findings_fixed: 10
verdict: REJECTED_AND_FIXED
elenxo: true
reviewer: "subagente general-purpose (opus), mandato REFUTAR, contexto isolado (só o diff e o objetivo)"
nota: "Os 2 bloqueantes foram curados, e mais 8 limites. Os 2 restantes (achados 8 e 11) ficam declarados abaixo, com o porquê."
---

# Passada adversarial: `feat/caddy-service-vhosts`

## O que muda

- **`ops/install-caddy-config.sh`** passa a instalar os vhosts que moram nos repos de serviço. São quatro: librechat, vault, waha e gokapi, listados em `ops/caddy/service-vhosts.tsv`.
  - **A fonte** é o blob commitado na ref.
  - **Adoção:** só do vivo byte a byte igual.
  - **Limite por repo:** hosts e upstreams, julgados no JSON do `caddy adapt`.
  - **Carimbo:** de serviço, distinto do carimbo do core.
  - **Pendente:** fonte ausente na ref não remove nada.
  - **Modo novo:** `--plan`, o ensaio.
- **`ops/egress-uid-fence.sh`** (ato novo) é a cerca de saída por uid do Gokapi:
  - `127.0.0.1:3050`: só `caddy` e a conta do túnel;
  - a porta interna `53842`: só o root, que é o docker-proxy.
- Também mudam:
  - `ops/moat-targets.tsv` (unit, caminhos e a linha `ato`);
  - a família nova `egress_uid_fence` no lint-selftest;
  - 4 nós em `docs/onion/graph/vps-shared-tools-2026-07.kg.yaml`.

## Achados

1. **BLOQUEIA, curado.** O guard de hosts contava chaves no texto. Chave num comentário depois de TAB, ou entre aspas, escondia um site de outro domínio. O refutador provou com `caddy adapt`.
   - **Cura:** o `adapt_guard` lê o JSON do próprio Caddy.
     - Só a app http e a tls; escuta só em :443 e :80.
     - Toda rota de nível superior tem host da lista.
     - Todo `reverse_proxy` vai para upstream da lista (coluna nova na TSV).
     - Nada de `file_server`, `templates` nem chave global.
   - O filtro de texto ficou como 1º filtro, e o comentário passou a dizer que ele se contorna.
   - **Bancada:** casos com caddy real (TAB e aspas), e o mutante C9 morre.
2. **BLOQUEIA, curado.** O vhost de serviço levava o mesmo `MANAGED_MARK` do core. A versão anterior do script remove todo vivo com esse carimbo sem fonte em `ops/caddy/conf.d`. Um revert, ou o install rodado de um checkout velho, derrubaria chat, vault, waha e transfer como órfãos.
   - **Cura:** um `SERVICE_MARK` que não contém o `MANAGED_MARK`. O script novo reconhece os dois.
   - **Bancada:** caso próprio, e o mutante C12 morre.
3. **Limite, curado.** Dentro do bloco valia qualquer coisa: `reverse_proxy` para a API admin :2019 ou para o loopback de outro serviço, `file_server` lendo o conf.d.
   - **Cura:** coluna de upstreams e a lista negra de handlers no `adapt_guard`.
   - **Bancada:** casos de :2019 e `file_server`; os mutantes C10 e C11 morrem.
4. **Limite, curado.** O `--plan` comparava a fonte crua, e o apply e o `--check` comparam o render normalizado (`printf '%s\n'`). Com fonte sem `\n` final, o plan dizia ATUALIZAR para sempre.
   - **Cura:** o plan compara com o render normalizado.
   - A receita manual do comentário ganhou a ressalva da quebra de linha.
5. **Limite, curado.** O `--plan` lia segredo de vhost de serviço com marcador, ao contrário do que o comentário dizia.
   - **Cura:** o desvio do ensaio vale para qualquer fonte com marcador (`has_markers`).
6. **Limite, curado.** O estágio e o apply recalculavam a lista de geridos. Um `git fetch` no meio daria conjuntos diferentes, e o `cp` do apply morreria pela metade.
   - **Cura:** a lista é calculada uma vez e passada ao estágio (`MANAGED_LIST`).
7. **Limite, declarado e o comentário corrigido.** A linha `ato` alcança só script de `ops/`.
   - `sudo bash /usr/local/sbin/onion-vps-egress-fence.sh down` e `sudo iptables -D OUTPUT 1` passam pelo veto (o refutador mediu no hook).
   - O comentário do `moat-targets.tsv` e o cabeçalho do script dizem isso agora.
8. **Limite, declarado.** A cerca não falha fechada no boot: se o `up` falhar, o Docker sobe mesmo assim.
   - Amarrar o Docker à cerca (`RequiredBy`) derrubaria todos os containers por causa de um. O `verify` acusa.
   - O `restart` da unit abre janela, e por isso a unit ganhou `ExecReload = up`, sem janela. O cabeçalho orienta a usar o reload.
9. **Limite, curado.** A sonda do caddy ficava verde se nem rodasse ("não mexeu no REJECT").
   - **Cura:** ela exige que o RETURN `gokapi-loopback-allow-caddy` conte.
   - **Prova:** no netns, a sonda do caddy conta no RETURN.
10. **Limite, curado.** O pré-voo aceitava rc 1, ambíguo com sudo sem credencial. O `down` e o `undo` concluíam "removida" com a listagem falhando.
    - **Cura:** `need_fw` confere o `sudo -n true` e a leitura do OUTPUT antes de up, down, verify, install e undo.
    - **Bancada:** caso 8b; o mutante E9 morre.
11. **Limite, declarado.** A regra da porta interna não tem destino. Conta comum leva RST em TCP para a 53842 de qualquer host, e todo uid 0 passa ali, inclusive container `--network host` de quem está no grupo docker.
    - As redes do Docker mudam de faixa, e casar uma sub-rede deixaria buraco. O colateral é aceito e está no cabeçalho.
12. **Limite, curado.** O verify só reprovava escuta em `[::]`, `*` e `0.0.0.0`.
    - **Cura:** reprova qualquer escuta na porta que não seja `127.0.0.1:3050`.

## Mutantes

Todos plantados por `ops/mutate-and-restore.sh`, com `LC_ALL=C`, contra a bancada embutida de cada script.

- **install-caddy-config: 12 de 12 mortos.**
  - C1, adoção sem `cmp`;
  - C2, host fora da lista aceito no filtro de texto;
  - C3, pendente vira órfão;
  - C4, symlink aceito (morto depois de a bancada passar a exigir a razão da recusa);
  - C5, árvore de trabalho em vez do blob;
  - C6, caminho da lista sem filtro;
  - C7, diretiva solta no nível superior (idem C4);
  - C8, nome duplicado entre core e serviço;
  - C9, `adapt_guard` sem conferir host (morre no caso de aspas com caddy real);
  - C10, upstream sem lista;
  - C11, `file_server` aceito;
  - C12, serviço com o carimbo do core.
- **egress-uid-fence: 10 de 10 mortos.**
  - E1, salto no fim do OUTPUT;
  - E2, sem REJECT no loopback;
  - E3, sem REJECT na porta interna;
  - E4, restore falho seguido;
  - E5, pré-voo de extensão ignorado;
  - E6, cópias do salto ficam;
  - E7, install falho não desfaz;
  - E8, install sem `--apply`;
  - E9, listagem falha ignorada;
  - E10, reload que derruba.
- **Sobreviventes das rodadas anteriores (C4, C7, C9):**
  - C4 e C7 sobreviveram porque o filtro de hosts recusava as mesmas entradas, por redundância. A bancada passou a exigir a razão da recusa, e os dois morreram na rodada seguinte.
  - C9 sobreviveu porque o caso de aspas usava `respond "{"`, Caddyfile inválido: o adapt recusava pela sintaxe, não pelo host. O caso trocou para `respond "a{b"` (válido, e engana a contagem), a bancada passou a exigir a mensagem do `adapt_guard`, e o C9 morreu.

## Limites declarados

- **Sem caddy na máquina (o CI),** os casos que dependem do lexer real (TAB e aspas) são pulados e ditos (⊘). O dublê do adapt monta o JSON das linhas e não vê aspas. O C9 só morre onde há caddy.
- **A sonda comportamental do verify** (contadores) não roda no sandbox, porque `PROBE=0`. A prova dela é o dogfood no netns: `nobody` levou RST, e caddy e marcio conectaram pelo RETURN de cada um.
- **Os achados 7, 8 e 11** ficam como limite (acima).
- **A conta do túnel é a do maestro (`marcio`).** Qualquer processo dela passa, inclusive sessões de agente. Fechar isso pede uma conta dedicada ao túnel, e a decisão é do maestro.
- **Não rodei** `--check` nem o install no vivo, porque o `--check` lê os segredos do gmill para renderizar. Também não rodei a cerca no firewall vivo: as duas coisas são do maestro.
- **Defasagem nomeada, fora do caminho:** o Caddy do host é 2.11.4, e a última é v2.11.9 (2026-11-05). Subir é deploy do maestro.
