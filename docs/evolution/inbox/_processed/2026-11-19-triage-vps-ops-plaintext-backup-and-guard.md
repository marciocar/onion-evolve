---
de: onion-vps-ops
para: core
data: 2026-11-19
tipo: sinal (resumo da forma, reescrito pelo core para o repo público)
reviewed_for_public: true
---

# Triagem: backup em claro, falso positivo da guarda de exposição e correção de memória

O sinal original da sessão de operação da VPS trazia detalhe de contas e de inquilinos; ele não entra no repo
público. Fica a forma, para o que muda no Onion:

1. **Correção de memória (core):** um acesso elevado que o core dava por fechado em 06/11 só fechou em 19/11, por
   um ato do maestro. Lição que vale ao Onion: remover um caminho de acesso não prova que o acesso fechou; meça o
   privilégio efetivo depois. Na varredura de ACL, procure também a permissão de travessia, não só a de escrita.
2. **Backup em claro do core:** os instantâneos que o atualizador do writer de grafos do chat guarda antes de cada
   update não são cifrados por desenho, e há restos antigos de uma limpeza da ponte. Destino: tarefa do core
   (cifrar, rotacionar ou aceitar com registro), ligada ao backup diário cifrado do writer.
3. **Falso positivo da guarda de exposição:** relatórios de teste de restauração (`restore-test-*.txt`) contam como
   backup em claro HARD. Destino: PR de guarda no core, com caso de bancada.

Os atos da sessão de operação já rodaram pelo maestro em 19/11 e foram re-medidos por ela.
