// Entrada do pacote npm kg-ssot: o núcleo do leitor (kg.mjs, sem fs nem geração de código) com o validador MUST do
// contrato já pré-compilado (must.mjs, sem new Function nem eval). Serve a Node e a bundles de React Native/Expo.
//
//   import { verdict } from 'kg-ssot';
//   verdict(texto, { format: 'yaml' })   // { verdict: 'accept' | 'reject', codes: [...], warnings: null, detail: '' }
import validateMust from './must.mjs';
import { codes as codesWith, verdictOf } from './kg.mjs';

export * from './kg.mjs';
export { validateMust };

/** O veredito do contrato vigente para o texto de um grafo; format é 'yaml' (o default) ou 'json'. */
export function verdict(text, { format = 'yaml', corpus = null } = {}) {
  return verdictOf(text, validateMust, { format, corpus });
}

/** Os códigos MUST do texto de um grafo, ordenados e sem repetição; vazio quando passa. */
export function check(text, { format = 'yaml', corpus = null } = {}) {
  return codesWith(text, validateMust, { format, corpus });
}
