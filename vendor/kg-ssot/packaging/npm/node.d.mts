// Tipos de kg-ssot/node: os auxiliares de Node do leitor (fs e processo).
import type { Corpus, MustValidator } from './index.mjs';

/** A raiz que tem o spec/ (a pasta do pacote instalado). */
export const ROOT: string;
/** O caminho do schema MUST do contrato vigente. */
export const CONTRACT_MUST: string;
/** Compila o schema MUST com o ajv em tempo de execução (no Node; num app, use o pré-compilado da entrada). */
export function compileMust(): Promise<MustValidator>;
/** Indexa os .kg.yaml sob um diretório (os rastreados, se for repo git) para conferir as external_edges. */
export function corpusIndex(root: string): Corpus;
