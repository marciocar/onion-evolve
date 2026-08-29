# Padrão-ouro — contagem de afirmações independentes verificáveis (F0)
# Contado pelo contexto principal ANTES de despachar qualquer worker ou juiz.
# Regra: mesma do juiz — excluir proveniência histórica não-re-mensurável, declarando-a.

## C_LACUNA_E_COBERTURA (guardas-revisao) — OURO: 2
1. Existe débito de COBERTURA: guardas sem consumidor que as rode (medível: grep de invocação).
2. Existe débito de VISIBILIDADE: guardas cujo resultado ninguém vê (medível: onde o output chega).
Excluídas: 0. Nota: "não é formato" é enquadramento avaliativo, não claim medível.

## D_MEDIR_O_DONO_NAO_O_CARIMBO (guardas-revisao) — OURO: 6
1. O beacon grava owner_pid + owner_start (starttime do /proc).
2. O starttime é defesa contra reuso de PID.
3. O veredito é medido em 4 estados: live · declared · orphan · stale.
4. declared cai no TTL e BLOQUEIA (conservador).
5. orphan (dono medido morto) não bloqueia; o sweep remove.
6. Direção do erro: ausência de prova cai no comportamento antigo, NUNCA em pode-escrever.
Excluídas: 1 (a referência ao "incidente W1xW2" é proveniência histórica).

## EN_REPO (colaboracao) — OURO: 2
1. O repositório é meio de colaboração assíncrona.
2. O repositório é SSOT-de-registro.
Excluídas: 0. Nota: nó entity; claims de papel, mensuráveis por mecanismo (onde se registra/colabora).

## EN_MAESTRO (colaboracao) — OURO: 2
1. O maestro/mantenedor é dono do core.
2. É o ÚNICO que relaya sinais ao core (universal — mensurável contra o mecanismo de relay).
Excluídas: 0.

## REC_A2A_RECEIVER_GATE_BUILT (federation-reconciled) — OURO: 7
1. a2a-verify.sh existe e é executável.
2. Tem 6 camadas.
3. É fail-safe.
4. apply_mode propose-only para receptor regulado.
5. a2a-ssrf-check.sh existe.
6. JWKS com pubkeys PINADAS por kid (metagamify-1, granaai-1).
7. a2a-accept.sh fila→inbox existe.
Excluídas: 0.

## REC2_NO_CONTRACT_EVER_REGISTERED (federation-reconciled) — OURO: 6
1. Em >5 semanas nenhum contrato real registrado.
2. O ledger não tem o diretório contracts/.
3. Os únicos contratos no repo são fixtures de validação.
4. Não há registro de federation-check/rollback exercido.
5. Os 5 comandos existem e passam nos fixtures.
6. Os 3 scripts existem e passam nos fixtures.
Excluídas: 0. Nota: 5-6 poderiam fundir num só ("comandos+scripts passam"); contei separado por
serem verificações independentes — se o juiz contar 5 por fusão, é divergência de granularidade,
não desonestidade.

## C_TRES_MODELOS_DE_CONFIANCA (identidade-vps) — OURO: 7
1. O bridge valida JWT por JWKS LOCAL (busca /jwks, cacheia 1h, confere assinatura/issuer/audience).
2. O bridge nunca chama o Logto para validar (medível: conexões na 3011 = 0 com bridge ativo).
3. Logto fora → tokens já emitidos seguem valendo até expirar.
4. O cofre redireciona o navegador ao Logto; não valida nada sozinho.
5. O cofre resolve auth.onionevolve.com para o IP PÚBLICO (sai e volta pela internet, via Caddy).
6. Logto fora = SSO quebrado com login por senha mestra intacto (SSO_ONLY=false).
7. WAHA usa X-Api-Key própria, hash sha512 no container, sem relação com o Logto.
Excluídas: 2 (as duas CONSEQUÊNCIAS — "não há ponto único de queda" e "não há lugar único de
auditoria" — são derivações das 7, não mecânicas independentes).
Nota: é o nó da classe que produziu o defeito de 2026-08-12 (três modelos, dois medidos).

## Q_BACKUP_AINDA_NAO_SAI_DA_MAQUINA (identidade-vps) — OURO: 8
1. pass sem entrada restic.
2. crontab do root sem linha offsite.
3. backup-offsite.sh sai exit 3 (declara que NÃO fez).
4. Existe o backup manual onion-backup-offsite-20260811.tar.gz.
5. O backup do cofre é .tar.gpg cifrado para a MESMA chave GPG raiz do pass.
6. Tem prova de restauração (decifra e devolve banco + chave de assinatura).
7. Rotação 14, no cron.
8. Sai do MESMO disco (não há offsite mecânico).
Excluídas: 2 — o fechamento de Q_CUSTODIA (histórico/confirmação do maestro) e TODA a pesquisa
datada (restic vs borg, rsync.net, 3-2-1-1-0): são claims sobre o mundo externo, não sobre este
sistema.

# TOTAIS: 2+6+2+2+7+6+7+8 = 40 afirmações nos 8 nós-ouro.
