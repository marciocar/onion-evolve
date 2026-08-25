// Config Astro do onionevolve.com — F1 da reforma 2026-08 (ADR D1: SSG-git, repo como SSOT).
// A fonte é este diretório; a derivação é dist/ (gitignored), publicada por ops/deploy-site.sh.
import { defineConfig } from 'astro/config';

export default defineConfig({
  site: 'https://onionevolve.com',
  // pt-BR é a língua da casa (brand voice); EN existe SÓ nas páginas-chave
  // compartilháveis (/en/doutrinas/, /en/maquinaria/) — decisão do maestro 2026-08-25.
  i18n: {
    defaultLocale: 'pt-br',
    locales: ['pt-br', 'en'],
    routing: { prefixDefaultLocale: false },
  },
});
