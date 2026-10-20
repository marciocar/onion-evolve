// Entrada do pacote npm kg-ssot: o núcleo do leitor (kg.mjs, sem fs nem geração de código) com os validadores MUST e
// SHOULD do contrato já pré-compilados (must.mjs e should.mjs, sem new Function nem eval). Serve a Node e a bundles
// de React Native/Expo.
//
//   import { verdict } from 'kg-ssot';
//   verdict(texto, { format: 'yaml' })   // { verdict: 'accept' | 'reject', codes: [...], warnings: [...], detail: '' }
import validateMust from './must.mjs';
import validateShould from './should.mjs';
import { codes as codesWith, verdictOf, warnings as warningsWith } from './kg.mjs';

export * from './kg.mjs';
export { validateMust, validateShould };

/** O veredito do contrato vigente para o texto de um grafo (MUST e SHOULD); format é 'yaml' (o default) ou 'json'. */
export function verdict(text, { format = 'yaml', corpus = null } = {}) {
  return verdictOf(text, validateMust, { format, corpus, validateShould });
}

/** Os códigos SHOULD (avisos) do texto de um grafo, ordenados e sem repetição; vazio quando não há aviso. */
export function checkWarnings(text, { format = 'yaml', corpus = null } = {}) {
  return warningsWith(text, validateMust, validateShould, { format, corpus });
}

/** Os códigos MUST do texto de um grafo, ordenados e sem repetição; vazio quando passa. */
export function check(text, { format = 'yaml', corpus = null } = {}) {
  return codesWith(text, validateMust, { format, corpus });
}
