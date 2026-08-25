// RSS das migalhas — MESMA URL do feed legado (/historia/migalhas/feed.xml).
// No cutover (F2), esta rota substitui a projeção feed.xml do migalhas-generate.sh;
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
