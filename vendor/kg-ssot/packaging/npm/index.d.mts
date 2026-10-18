// Tipos do pacote kg-ssot: a entrada (verdict, check, validateMust) e o núcleo que ela reexporta.

/** O formato do texto: 'yaml' para .kg.yaml (o default) ou 'json' para .kg.json. */
export type Format = 'yaml' | 'json';

/** O corpus para conferir a ponta externa das external_edges: caminho do .kg.yaml → ids dos nós dele. */
export type Corpus = Map<string, Set<string>>;

export interface Options {
  format?: Format;
  corpus?: Corpus | null;
}

/** O veredito no contrato de runner da suíte. Este leitor mede só o MUST: warnings é sempre null. */
export interface Verdict {
  verdict: 'accept' | 'reject';
  codes: string[];
  warnings: null;
  detail: string;
}

/** Um validador do schema MUST compilado (o pré-compilado do pacote ou um do ajv). */
export interface MustValidator {
  (data: unknown): boolean;
  errors?: unknown[] | null;
}

/** O validador MUST do contrato vigente, pré-compilado sem new Function nem eval. */
export const validateMust: MustValidator;

/** O veredito do contrato vigente para o texto de um grafo. */
export function verdict(text: string, options?: Options): Verdict;

/** Os códigos MUST do texto de um grafo, ordenados e sem repetição; vazio quando passa. */
export function check(text: string, options?: Options): string[];

/** O veredito com um validador MUST qualquer (o núcleo, para quem compila o schema). */
export function verdictOf(text: string, validate: MustValidator, options?: Options): Verdict;

/** Os códigos MUST com um validador MUST qualquer. */
export function codes(text: string, validate: MustValidator, options?: Options): string[];

/** O parse no perfil do formato: { doc } quando lê, { code } com o código parse.* quando não. */
export function parse(text: string, format?: Format): { doc?: Record<string, unknown>; code?: string };

/** O corpus a partir de pares [caminho, texto .kg.yaml]. */
export function indexTexts(items: Iterable<[string, string]>): Corpus;
