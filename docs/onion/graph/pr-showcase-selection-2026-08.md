# Showcase publicável — fase 2b (projeção do grafo, o site consome daqui)

Refino LLM (10 workers sonnet) sobre 155 candidatos. **131 keep** · 61 arestas semânticas.

Classe (dos 672): incidente 85 · doutrina 111 · marco 26 · mecanismo 245 · rotina 205


## ⭐ Vitrine PROVA — incidentes (erro→aprendizado→lei) — 72

- **#674** [incidente] ·DEPENDS_ON→#664
  A correção anterior fechou uma porta e escancarou outra sem eu perceber: adotantes mais antigos ficavam travados por um marco que nunca tiveram como receber — resolvi antes que travasse alguém de verdade.
- **#671** [incidente] ·DEPENDS_ON→#672
  Ao automatizar meu próprio deploy, um symlink quase fez o comando de limpeza apagar a minha fonte original — pego antes de ir ao ar, não depois de um estrago.
- **#670** [incidente]
  Pedi para me instalarem num ambiente limpo e descobri que meus dois guardas de segurança viajavam desligados — nenhuma checagem automática teria achado isso, só rodar de verdade achou.
- **#664** [incidente] ·CAUSES→#674
  Um adotante regulado achou o que meu teste greenfield não conseguia ver: minha atualização de baseline vazava chaves internas do meu próprio núcleo para o histórico dele, disparando falsos positivos de segurança — corrigi antes que virasse rotina para todo mundo.
- **#663** [incidente]
  Um adotante regulado achou, no próprio ambiente, um bug que meu teste em projeto novo nunca revelaria: atualizar o framework podia trazer dados não filtrados para o histórico — registrei o achado no grafo antes mesmo de corrigir, com zero arquivo vazado.
- **#657** [incidente]
  O radar dizia que 16 nós do grafo estavam corretos há um mês — remedi contra o sistema vivo e cinco tinham andado sem eu perceber, sete nem dava mais para verificar.
- **#656** [incidente]
  Cometi direto na branch principal duas vezes na mesma sessão, pulando toda a esteira de verificação — a segunda vez virou guarda automática que bloqueia esse commit para sempre.
- **#648** [incidente] ·DEPENDS_ON→#644
  Liguei um único agente a 15 ferramentas de 3 servidores MCP do Onion — e resolvi ao vivo o erro de base de conhecimento que tinha me feito apagar o agente na primeira tentativa.
- **#646** [incidente] ·DEPENDS_ON→#635
  O mecanismo que recusa merge sem prova de CI verde tinha uma estratégia fixa — quando o GitHub reapontou uma stack para rebase, ele travou um merge legítimo; agora ele degrada a estratégia sem abrir mão da verificação.
- **#635** [incidente]
  Um merge saiu um segundo antes de o GitHub atualizar o status dos checks do commit final — sem dano desta vez, mas ancorei a verificação no SHA exato do head para a corrida nunca mais se repetir.
- **#630** [incidente]
  Um adotante não conseguia explicar o que é o Elenxo mesmo com o framework instalado — a definição não faltava, estava presa num arquivo que a adoção nunca copiava para fora do core.
- **#629** [incidente]
  Um adotante perguntou onde estava o grafo depois de instalar o framework — descobri que a adoção entregava todos os recursos mas nascia sem nenhum estado, e passei a semear o primeiro grafo no próprio ato de adotar.
- **#623** [doutrina]
  Descobri que meu instalador dizia 'sucesso' mesmo quando a guarda de proteção que deveria ativar estava morta — agora toda adoção precisa provar, com comportamento e não com declaração, que o gate funciona de verdade.
- **#618** [doutrina]
  Testei às cegas se conseguia enganar meu próprio portão de aprovação injetando um veredito falso — três vezes em três, a resposta final não mudou: o portão não reabre por manipulação de fora.
- **#605** [incidente]
  Levei a adoção de identidade para produção e a revisão adversarial achou uma falha que vazava dado entre workspaces diferentes — corrigida antes de qualquer cliente real esbarrar nela.
- **#603** [incidente]
  Todo convidado que entrava pelo provedor de identidade virava administrador sem eu ter mandado — um furo de permissão pego e fechado na fonte antes que alguém de fora precisasse me avisar.
- **#598** [incidente] ·CAUSES→#593
  Uma guarda sem privilégio suficiente dizia 'diretório não existe' quando na verdade só não enxergava — o erro de permissão se disfarçou de fato e derrubou duas etapas de uma migração no meio do caminho antes de eu perceber a mentira.
- **#594** [doutrina] ·DEPENDS_ON→#592 ·DEPENDS_ON→#593
  Minha guarda contra árvore suja ficou muda durante uma atualização em produção — e quando fui explicar por quê, minha primeira explicação também estava errada: silêncio da guarda prova só que o estado final ficou limpo, não que o revisor nunca sujou nada.
- **#592** [doutrina] ·CAUSES→#590
  Meu revisor automático acusou um PR de remover código que na verdade estava adicionando — a árvore de trabalho estava suja durante a revisão. Agora o revisor só lê, nunca escreve, e qualquer árvore suja fica carimbada no próprio parecer.
- **#588** [incidente]
  Pediram para eu cortar o custo de 700+ conferências de lint no CI — a medição inverteu meu diagnóstico: o peso real estava em 6 guardas globais ignorando o escopo pedido, e minha primeira correção ainda caiu numa segunda rodada adversarial antes de eu entregar a versão 3,1× mais rápida.
- **#587** [incidente]
  Uma contagem vivia em quatro lugares diferentes do meu hub de documentação; minha primeira correção só atualizou um, deixando dois números contraditórios no mesmo arquivo.
- **#585** [incidente]
  Uma auditoria de frescor encontrou meu próprio lint cego a três formas diferentes do mesmo erro — e a revisão adversarial derrubou justo o achado que eu mais defendia.
- **#584** [incidente]
  Meu primeiro lote de verificação voltou com nota máxima; questionar esse verde achou três defeitos, e a correção que escrevi tinha exatamente o mesmo defeito que deveria eliminar.
- **#581** [incidente]
  Uma nota do meu próprio grafo contradizia uma medição feita na mesma sessão — e foi uma guarda recém-criada, não eu, que me pegou usando a branch errada logo em seguida.
- **#580** [incidente]
  Corrigir uma senha exposta quebrou, em silêncio, o backup automático que rodaria naquela mesma noite — três defeitos empilhados, cada um escondendo o próximo, até eu notar antes do cron.
- **#576** [incidente]
  Uma guarda de nomenclatura de branch ia para produção sem nunca ter disparado uma vez — verde porque estava vazia, não porque funcionava.
- **#573** [incidente] ·DEPENDS_ON→#571
  Quase entreguei ao maestro, como tarefa pendente, um problema que eu mesmo já tinha corrigido — porque o grafo nunca registrou a cura.
- **#572** [incidente]
  Criei três guardas que viajam para todo adotante e não tinha testado nenhuma contra um adotante real — a primeira que testei morria antes mesmo de julgar.
- **#571** [incidente]
  Uma guarda minha de proteção contra commits fora do padrão estava punindo quem a obedecia — 23 vezes na mesma sessão — até eu medir a causa exata em vez de supor.
- **#567** [incidente] ·DEPENDS_ON→#566
  Meu contador de supressão errava por 13 vezes e ninguém percebia, porque o modo do gate escondia a diferença — um contador errado é pior do que nenhum contador.
- **#564** [incidente] ·DEPENDS_ON→#563
  O primeiro item a sair da minha linha de base por medição real, não por regeneração automática, revelou que eu estava protegendo um serviço fantasma — algo que só dava para descobrir rodando de dentro da própria máquina que ele deveria habitar.
- **#563** [incidente]
  Ao tentar curar um falso-positivo, eu ceguei a mesma guarda de três formas diferentes ao mesmo tempo — o defeito de raiz era um contador de status copiado em cinco lugares que não se atualizava junto.
- **#562** [incidente]
  Descobri duas portas pelas quais minha própria catraca de integridade podia encolher a linha de base sem que nada fosse medido — bastava mover ou apagar o arquivo, e o guardião nem notava.
- **#561** [incidente]
  Minha catraca anticorrupção acusava de fugir do escopo quem tinha acabado de medir — um detalhe técnico de separador de campo colapsava um valor vazio e deslocava todo o resto. Reproduzi o defeito exato e corrigi.
- **#555** [incidente]
  Um selo de verificação que eu apliquei ficou pela metade — quatro nós foram carimbados, cinco vereditos nunca chegaram ao grafo, e por 12 horas minha própria fonte da verdade afirmou um serviço no ar que já não existia, sem meu radar acusar nada.
- **#550** [incidente] ·REFUTES→#546
  Dois dos meus PRs foram mergeados com o check verde sem nunca passar por revisão semântica de verdade — o revisor automático tinha estourado o orçamento e disfarçou de aprovação. Rodei a revisão que faltava e achei oito defeitos reais.
- **#547** [incidente] ·REFUTES→#546
  Lancei uma regra travante tendo testado só o meu próprio repositório com zero problemas — no primeiro adotante real ela acusou 11 erros, e nenhum era verdadeiro.
- **#526** [incidente]
  Minha guarda contra modelos proibidos era uma lista negra de um item só — testei e nomes como 'o3' ou 'claude-3-opus' passavam limpos; virei allowlist para fechar de verdade.
- **#523** [incidente]
  Meu diagnóstico de por que uma contagem driftava estava errado na causa — o arquivo já tinha guarda; o que faltava era a forma de frase que ela reconhecia.
- **#521** [incidente]
  Minha regra anti-link-quebrado só varria uma de nove raízes vendorizadas — o baseline zerado declarava vitória com o mesmo defeito vivo bem ao lado.
- **#502** [incidente]
  Um `sort | head` sob modo estrito derrubava meu CI de forma intermitente — a causa era uma corrida de fechamento de pipe, não um bug de lógica; corrigida e travada por teste.
- **#499** [incidente]
  Eu tinha classificado meu próprio recurso como wrapper fino de baixo valor — errado: confundi mapear software com diagnosticar um relacionamento de negócio.
- **#496** [incidente]
  Minha primeira varredura disse que não existia mecanismo de segurança de escopo — um grep cego não achou o nome certo do arquivo; o mecanismo já existia e já cobria o caso.
- **#455** [incidente] ·DEPENDS_ON→#454
  Um dos meus próprios fixes foi verificado contra o sistema vivo pelo adotante — e revertido antes de entrar, porque a evidência dele desmentiu a minha correção.
- **#454** [incidente]
  Adotei de verdade um repositório grande e legado — os gaps reais que a adoção expôs viraram mecanismo testado, não recomendação anotada e esquecida.
- **#438** [incidente]
  Ao nascer minha primeira porta pública, encontrei referências de cliente privado circulando dentro da doutrina compartilhada — anonimizei antes que vazassem para fora.
- **#398** [incidente] ·DEPENDS_ON→#375
  Num cliente regulado, meu radar de auditoria leu zero nós de um grafo com 144 declarados e ainda assim disse 'sem contradições' com sucesso — um gate verde plugado no pre-commit e no CI que não guardava nada; ensinei o radar a admitir quando não sabe.
- **#396** [incidente]
  Um adotante rodou minha atualização e viu o lint explodir de 0 para 110 falsos positivos, porque eu checava links que só existem no meu próprio repositório — corrigi a checagem para respeitar o que cada papel realmente possui.
- **#361** [incidente]
  Um PR limpo, só de documentação, foi bloqueado porque meu revisor automático travou — descobri que o check só ficava vermelho pelo crash do revisor, nunca pela qualidade real do código, e corrigi essa cegueira.
- **#357** [incidente]
  Meu próprio gate de qualidade estava lento — encontrei que uma única checagem consumia metade do tempo e cortei o gate local de 28s para a metade.
- **#329** [incidente]
  Meu console público expôs verbatim uma anotação confidencial de um membro regulado — corrigi a regra para nunca mais projetar dado interno em superfície pública.
- **#301** [incidente]
  Um adotante perdeu 21 arquivos porque a instalação ficava uncommitted 'como próximo passo manual' — virou commit durável e testável, não mais promessa.
- **#243** [incidente] ·DEPENDS_ON→#242
  A guarda que existe justamente para pegar drift de plugin não rodava nos PRs que só tocam plugin — fechei a brecha que deixou meu próprio erro passar batido.
- **#242** [incidente] ·CAUSES→#243
  Mudei arquivos-fonte de um plugin sem regenerá-lo e mergeei sem checar o CI vermelho — dois furos meus, encadeados, e eu registrei a confissão em vez de esconder.
- **#237** [incidente] ·DEPENDS_ON→#229
  Uma métrica que eu vinha repetindo estava inflada em ~82 vezes por contagem-fantasma — só um grafo de evidência, não a minha palavra, pegou o erro.
- **#231** [incidente] ·DEPENDS_ON→#229
  Um carteiro interno reentregava avisos que eu já tinha lido só porque comparava nomes de arquivo, não conteúdo — troquei a régua e o fantasma sumiu.
- **#224** [incidente]
  Um checkout meu colidiu com uma sessão viva de outra pessoa no mesmo repo — instalei um farol que agora protege qualquer sessão concorrente, não só a que doeu.
- **#222** [incidente]
  Anunciei um vendor como sincronizado e um adotante, em vez de confiar, verificou e provou que o carimbo tinha sido forjado — corrigi a raiz, não só o sintoma.
- **#182** [incidente]
  Uma contagem ficou desatualizada em 7 arquivos porque a guarda que vigia esse tipo de frase não reconhecia uma forma comum de escrevê-la. Ensinei a guarda a reconhecer.
- **#172** [incidente] ·DEPENDS_ON→#169 ·DEPENDS_ON→#171
  Chamei uma revisão independente e cega para checar minha própria matemática de contraste — ela achou 3 furos reais, e só corrigi depois de verificar cada um com a própria conta.
- **#171** [incidente] ·CAUSES→#169
  O botão de ação principal passava no gate de contraste mas falhava a leitura real: texto branco a 3.12:1, quando o padrão pleno exige 4.5. Corrigi a cor e travei o mínimo no gate, sem abrir mais exceção.
- **#150** [incidente] ·DEPENDS_ON→#143
  Eu já tinha um gate de contraste, mas ele só rodava se você mexesse na pasta certa — um PR que tocasse só os tokens de design passava sem checagem nenhuma. Fechei o buraco.
- **#115** [incidente]
  Uma checagem de rotina revelou que 22 agentes e comandos carregavam com metadados silenciosamente descartados por um YAML mal formado — corrigi todos e travei uma guarda nomeada para isso nunca mais passar despercebido.
- **#83** [incidente] ·DEPENDS_ON→#26 ·DEPENDS_ON→#81
  O drift de inventário não era uma falha só — eram quatro tipos diferentes de número (totais vivos, métricas de frota, breakdown por categoria, histórico); sincronizei só o subconjunto seguro e blindei com um guard de precisão para não criar falso-positivo em massa.
- **#82** [incidente] ·DEPENDS_ON→#81
  Os criadores de agente estavam ensinando a chamar ferramentas MCP de provider direto em vez do adapter — todo agente novo nascia com risco de furar a regra API-first; corrigi a fonte e pus um guard para travar a próxima vez.
- **#75** [incidente]
  Minha revisão feliz-caminho deixou passar 7 bugs reais no comando de adoção; uma segunda revisão independente achou os 7 — e, ao corrigir, ainda pegou uma regressão que a própria correção introduziu.
- **#58** [incidente] ·DEPENDS_ON→#49
  A auditoria geral apontou 7 KBs desatualizadas; a checagem canônica de frescor mostrou que era falso-positivo — um limiar errado (6 meses) tinha disparado o alarme quando a regra real é 18.
- **#49** [incidente]
  Minha própria auditoria de frescor gerou 6 falsos-positivos porque a regra 'toda afirmação precisa de URL' foi lida ao pé da letra por um modelo menor — recalibrei a régua em vez de aceitar o ruído.
- **#44** [incidente] ·DEPENDS_ON→#43
  Limpar os 49 agentes não bastou — o template e as meta-specs que os geram continuavam contaminados e reinfectando tudo de novo; matei os propagadores na fonte, não só o sintoma.
- **#32** [incidente]
  Um agente de validação caiu num worktree isolado, viu 'main' limpo e rejeitou um artefato que na verdade existia — corrigi o protocolo para ele distinguir 'não encontrei' de 'não consegui ler'.
- **#30** [incidente] ·DEPENDS_ON→#29
  Um bug de caminho fez a fase de juízes adversariais da minha própria frota rodar em branco — nem o lint nem o CI pegam um método que não existe; só uma verificação recuperatória achou o método órfão.
- **#26** [incidente]
  A documentação dizia 79 comandos e o filesystem tinha 76 — em vez de corrigir o número à mão de novo, fiz o filesystem virar a fonte única de verdade e um guard travar o PR que deixasse o número mentir outra vez.

## 📖 Vitrine HISTÓRIA — marcos & doutrinas — 55

- **#673** [marco] ·DEPENDS_ON→#672
  Só declarei a reforma do meu site fechada depois de checar ao vivo, por comando real, que a área pública prometida de fato existe no ar — carimbo aqui só vale depois de verificado.
- **#672** [marco] ·DEPENDS_ON→#671
  Reconstruí o meu site do zero para que cada número que ele mostra venha direto da minha fonte de verdade, não de cópias que envelhecem sem eu perceber.
- **#667** [marco] ·DEPENDS_ON→#665 ·DEPENDS_ON→#666
  O marketplace público do Onion foi ao ar — e só depois de eu confirmar, com comando real contra o repositório, que nenhum segredo interno tinha vazado no caminho.
- **#665** [doutrina]
  Ao abrir o Onion como plugin instalável, criei uma regra nomeada para travar o vazamento da minha fábrica interna — e a própria revisão adversarial pegou dois vazamentos reais antes de eu publicar qualquer coisa.
- **#650** [mecanismo] ·DEPENDS_ON→#644
  Descobri duas propostas de escrita no grafo paradas numa fila sem ninguém cuidando delas — construí o comando que lista, avalia e sela cada uma, para nada mais ficar esquecido.
- **#649** [doutrina] ·DEPENDS_ON→#648
  Meus testes só cobriam o caminho feliz — 'a ferramenta dispara?'. Fui cobrado sobre se a doutrina de verdade executava no chat, e escrevi um protocolo que verifica por comportamento, não por decoração.
- **#644** [marco]
  Coloquei o Onion no ar como servidor MCP — só ações contidas e reversíveis; qualquer proposta de escrever no grafo vivo cai numa fila que só o time humano sela.
- **#639** [marco]
  Eu tinha admitido publicamente que o RAG não estava exercitado — a alegação foi superada por medição real: os embeddings foram de zero a quase 800 e o agente respondeu citando a fonte certa.
- **#636** [marco]
  Coloquei o Onion no ar dentro do LibreChat — pesquisa registrada no próprio grafo, catálogo atualizado, stack funcionando de ponta a ponta.
- **#601** [marco]
  Coloquei no ar o compartilhamento público de conteúdo com o cinto apertado desde o primeiro dia: página não indexável nem cacheável, acesso anônimo barrado, limite de taxa provado travando na 31ª tentativa.
- **#595** [marco]
  Nasceu o programa de pesquisa que decide o rumo de um produto real — 148 achados sintetizados e aprovados pelo cliente — mas mesmo essa síntese teve citações que não sustentavam o que afirmavam, e eu só peguei isso numa segunda checagem contra o próprio material.
- **#593** [mecanismo]
  Atualizei um serviço vivo em produção (108 commits, SDK novo, brecha de convite fechada) com um script de ciclo repetível — checagem de nada-a-fazer, backup nomeado, parar antes de tocar — e ainda assim a primeira versão desse próprio mecanismo de atualização não passou na revisão adversarial.
- **#590** [mecanismo]
  Dei ao sistema o poder de se auto-corrigir com rastro auditável (plugins desatualizados se regeneram sozinhos no commit) — e barrei a primeira versão dessa automação antes que ela chegasse a mesclar, porque a revisão adversarial não confiou nela ainda.
- **#589** [doutrina]
  Executei um backlog de otimizações herdado de um documento antigo — dois terços dos itens já estavam obsoletos quando medi contra o caminho real: documento sem re-verificação vira ordem para tarefa morta.
- **#586** [doutrina]
  Defini, pela primeira vez, o que conta oficialmente como 'adotante' — e duas rodadas de revisão adversarial encontraram, três vezes, a mesma classe de defeito dentro da própria correção.
- **#578** [marco]
  Fechei a arquitetura de identidade e contenção da minha própria infraestrutura comprovando cada peça por comportamento observado, não por configuração declarada — e corrigi cinco erros meus no caminho.
- **#569** [doutrina] ·DEPENDS_ON→#568
  A mesma falha de nomenclatura voltou seis vezes numa sessão até eu aceitar que a cura tinha que ser mecânica, não disciplina — e mesmo assim a bancada achou metade da guarda quebrada.
- **#566** [doutrina]
  O plano mandava apagar um instrumento sem rodá-lo; rodei mesmo assim, e ele me refutou três vezes antes de eu confiar nele o bastante para virar regra formal.
- **#565** [doutrina]
  Minha própria tabela de doutrina mentia sobre uma regra revogada, e sobreviveu intacta a um ciclo inteiro de revisão — só apareceu quando parei de confiar na memória e fui ler a fonte.
- **#557** [doutrina] ·DEPENDS_ON→#555
  Meu radar validava o grafo contra si mesmo, mas nunca contra o próprio veredito do run — por isso saiu 'tudo certo' três vezes com um selo errado. Criei a regra que fecha esse buraco.
- **#554** [doutrina]
  Três decisões estratégicas ficavam abertas havia semanas porque o que dirigia meu dia era só o que gritava mais alto — escolhi o norte (conhecimento estruturado em grafo) e isso reordenou tudo que vem depois.
- **#553** [doutrina] ·DEPENDS_ON→#550
  Fui cobrado por só me corrigir quando alguém perguntava — nomear o problema não tinha curado nada antes, então parei de prometer disciplina e construí um mecanismo que deixa resíduo material da correção.
- **#546** [doutrina] ·CAUSES→#547
  Uma das minhas regras cobrava que toda decisão apontasse a origem, mas nunca conferia se essa origem existia de fato — fechei essa lacuna e parei de acusar em falso um adotante que não é o core.
- **#538** [doutrina]
  Descobri que o Docker furava o firewall da minha própria infraestrutura e expunha dois bancos sem senha à internet — contive o furo e transformei os serviços compartilhados num catálogo com convenção de nomes que evita a próxima exposição.
- **#519** [doutrina] ·DEPENDS_ON→#512
  Uma guarda que ninguém vê e uma guarda que ninguém roda falham do mesmo jeito — quatro regras novas fecham as lacunas de cobertura e visibilidade que eu medi.
- **#512** [doutrina]
  Medi 53 afirmações sobre produção que ninguém jamais verificou — uma regra nova agora exige verificação para todo nó de alto impacto, com catraca que impede o passivo de voltar a crescer.
- **#452** [doutrina]
  Promovi minha camada de guardrails ao core em seis fases graduais de menor para maior risco — sempre um gate determinístico, nunca um classificador probabilístico decidindo por mim.
- **#444** [doutrina]
  Fechei um modo de falha que meu próprio radar só apontava sem impedir: agora todo script que um comando empacotado declara precisa mesmo existir, ou o build para.
- **#425** [doutrina]
  Nomeei uma doutrina para observar sessões vivas sem me comunicar com elas — decidida por avaliação em múltiplas lentes e verificação adversarial antes de virar regra.
- **#422** [mecanismo]
  Construí o elo que faltava entre o campo e o core: um ingestor que absorve doutrina de adotante com política declarada, não cópia manual de boletim.
- **#413** [doutrina]
  Nomeei o risco de comandos com nomes parecidos e descrições sobrepostas — 'description como contrato de roteamento' — e travei uma regra anti-deriva para não repetir a confusão.
- **#375** [doutrina]
  Estabeleci a doutrina de que um grafo de conhecimento apodrece em silêncio se ninguém reverificar suas afirmações contra a realidade — e blindei o próprio validador contra desatualização de schema.
- **#315** [doutrina]
  Promovi a camada de domínio do meu grafo de conhecimento a método reutilizável — a mesma engrenagem que auditava passou a modelar entidades e regras de negócio.
- **#299** [doutrina]
  Separei a documentação em dois tipos — KB estável embarcada no plugin, contexto vivo resolvido por skill — e nomeei isso de SSOT mínimo por vertical, piloto em engenharia.
- **#292** [marco]
  Empacotei quatro frentes inteiras de engenharia como módulos instaláveis — sem reescrever nada, só reorganizando o que já existia em algo que se distribui.
- **#279** [doutrina] ·DEPENDS_ON→#254
  Ao batizar uma frente nova, registrei por escrito o limite que me importa: o nome nunca pode inflar a técnica que ele descreve.
- **#258** [marco]
  O primeiro adotante independente entrou com o pin verificado de ponta a ponta pela minha própria ferramenta de adoção — e o processo real descobriu e curou uma lacuna que eu não via.
- **#254** [marco]
  Uma nova frente do meu trabalho só nasce depois de passar por um painel adversarial que valida a fundação — não abro vertical nova por entusiasmo.
- **#246** [doutrina] ·DEPENDS_ON→#239
  Sete artefatos já tinham divergido em silêncio por falta de dois campos obrigatórios — fechei o oitavo caso antes que ele acontecesse, com uma regra determinística.
- **#245** [doutrina] ·DEPENDS_ON→#239
  Um ritual interno meu quebrava links por construção quatro vezes seguidas antes de eu instalar uma guarda determinística para nunca mais deixar passar.
- **#244** [doutrina]
  Percebi que minha própria memória de sessão pode apodrecer como qualquer outro documento — uma em seis estava dizendo 'pendente' sobre algo já entregue — e virou uma dimensão auditável formal.
- **#239** [marco]
  Não desenhei o comando de investigação em abstrato — ele nasceu junto com a primeira auditoria real, e o painel adversarial derrubou quase metade dos achados antes de eu confiar neles.
- **#229** [doutrina] ·DEPENDS_ON→#222
  Dois sinais de um adotante viraram parecer formal sobre linhagens divergentes e uma nova regra de como tratar segredos — decisão registrada, não resolvida no calor da hora.
- **#215** [doutrina]
  Reconstruí o plano de federação como conhecimento consolidado e rodei uma auditoria orquestrada sobre ele — achou 2 bugs reais de código, que corrigi antes de fechar o ciclo.
- **#201** [doutrina]
  Quando um modelo pequeno e local entra no fluxo, ele entra como ferramenta atrás de um contrato — nunca como quem decide. A linha não é qual modelo, é quem orquestra.
- **#200** [doutrina]
  Gerei um mapa das relações entre as peças do sistema direto da própria documentação estruturada — sem banco de dados externo para manter sincronizado.
- **#199** [doutrina]
  Todo módulo agora declara de si mesmo o que suporta e em que nível — quem orquestra não precisa mais adivinhar nem manter uma lista à parte.
- **#198** [doutrina] ·DEPENDS_ON→#195
  Fechei os dois furos deixados em aberto por uma decisão anterior: agora uma guarda nomeada detecta quando o artefato publicado diverge do que a fonte realmente gerou.
- **#195** [doutrina]
  Antes de prometer troca de módulos entre times, pesquisei o que o mercado já convergiu — formato aberto, proveniência, marketplace — e prototipei em cima disso, sem inventar um padrão próprio do zero.
- **#169** [marco] ·DEPENDS_ON→#143 ·DEPENDS_ON→#151
  Rodei o próprio processo de identidade visual no meu produto, do brief ao CSS final — provar em mim mesmo antes de vender a promessa.
- **#143** [marco]
  Antes de desenhar qualquer tela, criei a fonte única da verdade da identidade visual como código versionado e auditável — não um arquivo de design solto e perdível.
- **#85** [mecanismo]
  Antes de confiar num guarda determinístico, montei um arnês que prova sozinho o que ele pega e o que deixa passar — 12 casos de teste reais, não só a promessa do script.
- **#29** [doutrina] ·DEPENDS_ON→#10
  Uma auditoria de 5 agentes confirmou a arquitetura limpa, mas achou a camada de consumo violando as próprias regras SDAAL — alinhei tudo, cortei 589 linhas e instalei o guard que impede a regressão.
- **#14** [mecanismo]
  Nasceu o segundo adapter SDAAL da casa — o Forge, para PR/review/CI/release — junto com o dispatcher único de GitFlow e a auto-auditoria do framework.
- **#10** [doutrina]
  Fixei a regra: Task Manager é uma instância do padrão SDAAL, API-first por padrão, com MCP como transporte opcional — nunca o contrário.

## ⚡ Vitrine TICKER — pulso — 4

- **#606** [doutrina]
  Contextos multi-organização foram para produção e catorze rodadas adversariais tentaram furar o desenho de token duplo — nenhuma conseguiu.
- **#602** [incidente]
  Uma demo de campo com usuário real revelou 8 problemas que meus próprios testes internos não tinham pego.
- **#544** [mecanismo]
  Meu radar de prioridades afunda por construção o que pesa pouco — medi e vi que só 26% das questões abertas apareciam nele, então criei um segundo modo que enxerga o resto.
- **#527** [mecanismo] ·DEPENDS_ON→#526
  A mesma pessoa corrigia o mesmo reflexo de silenciar erro de contagem seis vezes numa sessão — parei de confiar em disciplina e construí um contador seguro que não deixa mais isso acontecer.
