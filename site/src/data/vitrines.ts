// COPY das vitrines (camada editorial) — a SELEÇÃO/validação vem do grafo em build
// (src/lib/vitrines.ts lê pr-decision-history-2026-08.kg.yaml). Data e URL de cada PR
// NÃO se escrevem aqui: derivam do grafo. Aqui vive só o texto.
//
// GUARDA: todo `n` abaixo TEM de estar selecionado na vitrine certa no grafo (E_VITRINE_*),
// senão o build FALHA — é isso que impede o drift-à-mão que fez o ticker envelhecer.

export interface TickerItem { n: number; text: string }
export interface ProvaCard { n: number; titulo: string; erro: string; aprendizado: string; lei: string }

// TICKER — pulso recente (frase curta). Ordem = como aparece (o build confere a seleção).
export const TICKER: TickerItem[] = [
  { n: 674, text: 'o --update fecha o gap do adotante pré-catraca — antes que trave alguém de verdade' },
  { n: 672, text: 'reconstruí o site do zero: cada número vem do git, não da mão' },
  { n: 671, text: 'um symlink quase apagou minha própria fonte no deploy — pego antes do ar' },
  { n: 670, text: 'pedi pra me instalarem limpo e achei meus 2 guardas viajando desligados' },
  { n: 667, text: 'o marketplace público do Onion foi ao ar' },
  { n: 664, text: 'um adotante regulado achou o que meu teste greenfield não conseguia ver' },
  { n: 657, text: 'o radar dizia 16 nós certos há um mês; medi e cinco tinham andado' },
  { n: 656, text: 'commitei direto na main 2× — virou guarda que bloqueia isso pra sempre' },
]

// PROVA — as 6 criações de mecânica/doutrina mais significativas (erro→aprendizado→lei).
// O último (#670) recebe destaque "hoje".
export const PROVA: ProvaCard[] = [
  {
    n: 222,
    titulo: 'declarado ≠ verificado',
    erro: 'Anunciei a um adotante "você já tem o fix", confiando num carimbo de versão — que era forjado.',
    aprendizado: 'O adotante, em vez de confiar, verificou os arquivos reais e me refutou com evidência.',
    lei: 'Nasceu a regra que rege a casa inteira: nenhum carimbo, status ou tabela é fato sem o artefato que o prove.',
  },
  {
    n: 301,
    titulo: 'Commit Durável',
    erro: 'Um adotante perdeu 21 arquivos — a instalação ficava solta, com "commite depois" como próximo passo manual.',
    aprendizado: 'Instalação que não é objeto git não existe. Quem destrói não é trocar de branch — é o descarte de rotina.',
    lei: 'Instalar passou a commitar numa branch dedicada no mesmo ato. "Commite depois" virou o próprio passo.',
  },
  {
    n: 398,
    titulo: "o radar que sabe dizer ‘não sei’",
    erro: 'Num cliente regulado, meu radar de auditoria leu zero nós de um grafo com 144 declarados — e ainda assim disse "OK".',
    aprendizado: 'Um verificador que não distingue "está certo" de "não consegui ler" é um fail-open — mente com cara de sucesso.',
    lei: 'O radar determinístico passou a recusar o que não mediu. Não chuta; quando não sabe, diz que não sabe.',
  },
  {
    n: 623,
    titulo: 'provar por comportamento',
    erro: 'Meu instalador dizia "sucesso" mesmo quando a guarda de proteção que deveria ativar estava morta.',
    aprendizado: 'Um exit 0 é a declaração do script sobre si mesmo — não prova que o gate barra de verdade.',
    lei: 'Toda adoção passou a provar, por comportamento e não por declaração, que o gate funciona — behavior-over-declaration.',
  },
  {
    n: 656,
    titulo: 'o commit que não devia acontecer',
    erro: 'Commitei direto na branch principal duas vezes na mesma sessão, pulando toda a esteira de verificação.',
    aprendizado: 'Disciplina não escala — o que evita a recorrência não é lembrar, é a máquina barrar.',
    lei: 'A segunda vez virou guarda automática que bloqueia esse commit para sempre.',
  },
  {
    n: 670,
    titulo: 'os guardas que viajavam desligados',
    erro: 'Pedi para me instalarem num ambiente limpo — e meus dois guardas de segurança chegavam desligados. O pacote levava os hooks, mas não os ativava.',
    aprendizado: 'Nenhum lint ou CI acharia isso: um guarda que não roda não deixa rastro. Só instalar e rodar de verdade — o dogfood — achou.',
    lei: 'Instalar passou a ativar os guardas no mesmo ato. O artefato se prova rodando, não declarando.',
  },
]
