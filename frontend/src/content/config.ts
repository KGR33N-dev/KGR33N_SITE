import { defineCollection, z } from 'astro:content';

const blogCollection = defineCollection({
    type: 'content', // v2.5.0+ requires type: 'content' or 'data'
    schema: z.object({
        title: z.string(),
        description: z.string(),
        pubDate: z.date(),
        slug: z.string().optional(),
        updatedDate: z.date().optional(),
        heroImage: z.string().optional(),
    }),
});

export const collections = {
    'blog': blogCollection,
};
