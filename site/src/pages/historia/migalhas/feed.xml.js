// RSS das migalhas — MESMA URL do feed legado (/historia/migalhas/feed.xml).
// Desde o cutover (2026-08-25) esta rota é O feed (substituiu a projeção do gerador legado);
// o campo `rss` do frontmatter (resumo curado) vira a description, como no legado.
import rss from '@astrojs/rss';
import { getCollection } from 'astro:content';

export async function GET(context) {
  const posts = (await getCollection('migalhas')).sort(
    (a, b) => b.data.date.getTime() - a.data.date.getTime()
  );
  return rss({
    title: 'Migalhas — o diário vivo do Onion Evolve',
    description:
      'O que o framework aprendeu, errou e corrigiu — em público, com carimbo de data e PR.',
    site: context.site,
    items: posts
      .filter((p) => p.data.rss)
      .map((p) => ({
        title: p.data.title,
        description: p.data.rss,
        pubDate: p.data.date,
        link: `/historia/migalhas/#post-${p.data.slug}`,
      })),
  });
}
