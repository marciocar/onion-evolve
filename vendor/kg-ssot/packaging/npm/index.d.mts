// Tipos do pacote kg-ssot: a entrada (verdict, check, validateMust) e o núcleo que ela reexporta.

/** O formato do texto: 'yaml' para .kg.yaml (o default) ou 'json' para .kg.json. */
export type Format = 'yaml' | 'json';

/** O corpus para conferir a ponta externa das external_edges: caminho do .kg.yaml → ids dos nós dele. */
export type Corpus = Map<string, Set<string>>;

export interface Options {
  format?: Format;
  corpus?: Corpus | null;
}

/** O veredito no contrato de runner da suíte: codes são os MUST (reprovam) e warnings os SHOULD (só avisam). */
export interface Verdict {
  verdict: 'accept' | 'reject';
  codes: string[];
  /** Os avisos SHOULD; null só no verdictOf sem validateShould (o leitor não mediu o SHOULD). */
  warnings: string[] | null;
  detail: string;
}

/** Um validador de schema compilado (o pré-compilado do pacote ou um do ajv), MUST ou SHOULD. */
export interface MustValidator {
  (data: unknown): boolean;
  errors?: unknown[] | null;
}

/** O validador MUST do contrato vigente, pré-compilado sem new Function nem eval. */
export const validateMust: MustValidator;

/** O validador SHOULD do contrato vigente, pré-compilado sem new Function nem eval. */
export const validateShould: MustValidator;

/** O veredito do contrato vigente para o texto de um grafo, com os avisos SHOULD. */
export function verdict(text: string, options?: Options): Verdict;

/** Os códigos MUST do texto de um grafo, ordenados e sem repetição; vazio quando passa. */
export function check(text: string, options?: Options): string[];

/** Os códigos SHOULD (avisos) do texto de um grafo, ordenados e sem repetição; vazio quando não há aviso. */
export function checkWarnings(text: string, options?: Options): string[];

/** O veredito com um validador MUST qualquer (o núcleo, para quem compila o schema); com validateShould, mede também
 * os avisos. */
export function verdictOf(text: string, validate: MustValidator,
  options?: Options & { validateShould?: MustValidator }): Verdict;

/** Os avisos de coerência de um documento já lido (integrity.testimony-in-prod, verified-before-fact, untraced-decision, refutes-unreconciled).
 * Com o corpus, a REFUTES que chega de outro grafo pelas external_edges também conta. */
export function coherenceCodes(doc: Record<string, unknown>, corpus?: Corpus | null): string[];

/** Os avisos do perfil JSON num .kg.yaml já lido (yaml.unsafe-integer, yaml.lone-surrogate, yaml.depth-over-128). */
export function yamlProfileCodes(doc: unknown): string[];

/** Os códigos SHOULD com os validadores MUST e SHOULD quaisquer. */
export function warnings(text: string, validate: MustValidator, validateShould: MustValidator,
  options?: Options): string[];

/** Os códigos MUST com um validador MUST qualquer. */
export function codes(text: string, validate: MustValidator, options?: Options): string[];

/** O parse no perfil do formato: { doc } quando lê, { code } com o código parse.* quando não. */
export function parse(text: string, format?: Format): { doc?: Record<string, unknown>; code?: string };

/** O corpus a partir de pares [caminho, texto .kg.yaml]. */
export function indexTexts(items: Iterable<[string, string]>): Corpus;
