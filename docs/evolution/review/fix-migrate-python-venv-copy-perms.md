---
branch: fix/migrate-python-venv-copy-perms
pr: pendente
date: 2026-10-27
reviewed_diff_sha256: 869965d7f2f29b0298581d01d8a72e6d8107262fd7a3fbd9eac65e6f7fe2b4a5
reviewed_code_sha256: cf9ea3cd1b287430d15ac40a40da8315784bed4c3e1051e32d16a402fd51dd0a
findings_total: 9
findings_real: 9
tokens: 146220
duration_min: 7
findings_fixed: 6
verdict: CORRIGIDO
elenxo: sim
reviewer: subagente general-purpose, model opus, 1 passada curta com mandato de refutar, sobre o diff do wrapper, da bancada e do grafo; rodou os heredocs Python reais num venv de fixture e leu o estado vivo (sem escrever)
nota: "Nenhum achado ALTO. Curados: o hardlink barrado ANTES do chown (antes a guarda só nomeava o dano), o discard-venv que liberava o rm sem medir, a falha do sudo -u como 'permissão', zero distribuições como 'faltam pinos', a dica do runtime fora do lugar e o texto do discard-venv. Declarados: a leitura da stdlib pelo usuário do serviço, a bancada que não roda o Python real da prova, e o fix_root_loose que age na raiz inteira."
---

# Passada adversarial: `fix/migrate-python-venv-copy-perms`

## O que muda

- `ops/migrate-python-service.sh`: `UV_LINK_MODE=copy`, `chmod -R a+rX,go-w` e `setfacl -R -b` depois do chown. O `venv_gate` confere dono, links>1, leitura para outros, leitura real e import como o usuário do serviço, e os pinos com a falha de leitura nomeada. Ele roda antes do marcador e no reuso. Entram o modo `discard-venv --yes` e o runtime conferindo e fechando a raiz `/opt/onion-python` sem reinstalar.
- A bancada `migrate_python_service`: os falsos reproduzem o uv medido (hardlink sem copy, cópia que preserva o 0640, `.lock` 0666) e abrem os arquivos de verdade. São 15 casos novos com mutante (h1–h8, h3b, d1–d4, rt1, rt2), e o a10 e o a13 têm a âncora nova.
- O grafo `sinais-de-campo-2026-09`: a evidência `E_PY315_APPLY_GRANAAI_HARDLINK_PERM_1027` CONSTRAINS `D_PY315_EXECUCAO_POR_OPS_E_OPT_1027`.

## Achados

1. **MÉDIA, curado.** O hardlink só era detectado depois do `chown`, quando os inodes do cache já tinham virado root. Agora a busca de links>1 roda como o operador antes do chown e morre sem mudar dono (caso h3, mutante na guarda nova). A guarda do `venv_gate` fica para o reuso (caso h3b).
2. **MÉDIA, curado.** O `discard-venv` liberava o `rm -rf` quando não conseguia medir: o MainPID falhando, ou o cmdline e o environ ilegíveis. Agora isso sai com rc 2. Ele confere também o ExecStart e o Environment carregados (qualquer `.conf`, não só o drop-in daqui), em defesa dupla com a checagem do drop-in. O caso d2 exige a mensagem do drop-in, para o mutante dele não ser mascarado.
3. **MÉDIA, curado.** A falha do `sudo -n -u` aparecia como "permissão", e a dica mandaria descartar um venv bom. Agora o pré-voo roda `as_svc true` e sai com rc 2. Teto: a bancada não exercita o ramo do sudo.
4. **MÉDIA, declarado.** A leitura como usuário do serviço cobre o venv, não a stdlib do intérprete base, e o selftest e a paridade rodam como o operador. Hoje o `User=` das duas units é o próprio operador, que é exatamente quem roda o selftest, e o `runtime` é instalado por root com umask de root.
5. **BAIXA, curado.** Um site-packages ilegível dava zero distribuições, com rc 0 e "faltam pinos". Agora zero distribuições é falha de leitura (rc 3).
6. **BAIXA, declarado.** O python falso da bancada casa os heredocs por texto e não roda a prova Python real. O revisor rodou os dois heredocs reais num venv de fixture com modo 000 e um `bin/python` ausente, e eles se comportaram como o esperado. A prova Python real em produção é o apply do maestro (teto declarado da família).
7. **BAIXA, curado.** A dica "a raiz frouxa se fecha com runtime apply" saía junto de qualquer problema do runtime. Agora sai só com `RAIZ-FROUXA`.
8. **BAIXA, declarado.** O `fix_root_loose` age em tudo o que estiver frouxo em `/opt/onion-python`, inclusive num intérprete de outro patch. Ele só fecha a escrita de grupo e de outros e o dono de root, e não reinstala nem apaga nada: num intérprete instalado pelo wrapper, isso é o estado devido.
9. **BAIXA, curado.** O cabeçalho dizia que o `discard-venv` descarta o venv "QUEBRADO", mas ele descarta o venv alvo sem uso, quebrado ou não. O texto foi corrigido. A recusa é por uso, não por saúde: um venv saudável sem uso é remontável pelo apply.

Sobre a base: o revisor apontou a worktree atrás da `origin/main`. A branch foi rebaseada antes do PR.
