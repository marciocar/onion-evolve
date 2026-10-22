---
branch: feat/docker-engine-migrate
pr: pendente
date: 2026-10-22
reviewed_diff_sha256: pendente
findings_total: 5
findings_real: 5
tokens: 0
duration_min: 60
findings_fixed: 5
verdict: CORRIGIDO
elenxo: nao
reviewer: "fork da sessão principal (claude-opus-5-5), passada própria"
nota: "tokens não medidos (passada no próprio fork, sem subagente)"
---

# Passada adversarial: `feat/docker-engine-migrate`

## O que muda

- `ops/docker-engine-migrate.sh` (novo, core-only): `plan` (inventário só leitura em
  `/var/backups/onion-docker-migrate/plan-<ts>`), `apply` (plan recente, alvo fixado, chave da Docker por fingerprint,
  fonte deb822, uma transação apt que instala as versões fixas e remove o docker.io/containerd/runc/compose-v2 do
  Ubuntu sem purge, `apt-mark hold`, daemon.json fixando o image store do plan, contenção DOCKER-USER reaplicada,
  espera dos containers e verify) e `verify` (Engine 29.9.2 no cliente e no servidor, containers que rodavam de volta
  e os healthy ainda healthy, image store igual, DOCKER-USER igual, as 9 rotas com o mesmo código do plan).
- `ops/moat-targets.tsv`: units docker, containerd e onion-vps-docker-firewall; `/etc/docker`, a fonte e a chave do
  apt e o diretório de estado passam a ter o wrapper.
- `.claude/validation/lint-selftest.sh`: família `docker_engine_migrate` (19 casos, 12 mutantes).

## Achados

1. O `plan` morria em silêncio no vivo: o `dpkg-query` sai 1 quando algum nome da lista não está instalado, e o
   `pipefail` matava o script. O stub da bancada saía 0 e escondia isso. Curado no script e no stub, que agora sai
   como o real.
2. O template do Go não interpreta `\t`: o `engine.tsv` saía com a barra literal. Trocado por espaço.
3. O teste de "plan só lê" acusava `systemctl is-enabled` como mutação: a régua agora separa leitura de escrita.
5. Dois `produtor | grep -q` no apply (madison e dpkg-query) eram sítios novos da classe EPIPE que o pré-voo acusa:
   viraram here-string e comparação direta.
4. Duas guardas (plan de outro alvo e image store trocado) não tinham caso nem mutante: ganharam os dois.

## Mutantes

- 12 guardas derrubadas numa cópia: noplan, planage, pinned, plantarget, gpg, available, running, healthy, version,
  store, fw, routes — todas mortas pela bancada.
- Gate MOAT provado pelo hook com JSON: o wrapper passa (rc 0); `systemctl restart docker|containerd|onion-vps-docker-firewall`,
  `tee` na fonte do apt e `cp` para `/etc/docker` são barrados (rc 2); `docker ps` e `docker inspect` seguem livres.

## Limites declarados

- O `apply` NÃO rodou no vivo (é da janela do maestro). A bancada usa stubs; o comportamento do apt e do dockerd
  novos só se prova na janela, pelo `verify`.
- O containerd.io 2.4.2 migra o metadado do containerd para a frente; voltar ao 2.2.1 do Ubuntu não é garantido. O
  rollback de pacotes é impresso, mas a rede de segurança é o snapshot da VPS antes da janela.
- O compose fica no 2.40.3 (plugin oficial da mesma versão); o compose 5.x é outra decisão.
