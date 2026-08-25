// Coleção das migalhas — os posts JÁ nasceram "Astro-shaped de propósito"
// (site/historia/migalhas/README.md): o glob aponta para onde eles SEMPRE viveram,
// para o pipeline legado (migalhas-generate.sh) seguir funcionando até o cutover (F2).
import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const migalhas = defineCollection({
  loader: glob({ pattern: '*.md', base: './historia/migalhas/posts' }),
  schema: z.object({
    slug: z.string(),
    type: z.string(),
    date: z.coerce.date(),
    review_after: z.coerce.date().optional(),
    title: z.string(),
    rss: z.string().optional(),
    prs: z
      .array(
        z.object({
          label: z.string(),
          status: z.string(),
          meta: z.string().optional(),
        })
      )
      .optional(),
  }),
});

export const collections = { migalhas };
