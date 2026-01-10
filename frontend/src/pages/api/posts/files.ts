
import type { APIRoute } from 'astro';
import fs from 'node:fs';
import path from 'node:path';

export const GET: APIRoute = async ({ request }) => {
    try {
        const postsDir = path.join(process.cwd(), 'public/blog/posts');

        if (!fs.existsSync(postsDir)) {
            return new Response(JSON.stringify([]), {
                status: 200,
                headers: { 'Content-Type': 'application/json' }
            });
        }

        const files = fs.readdirSync(postsDir)
            .filter(file => file.endsWith('.md'))
            .map(file => {
                const content = fs.readFileSync(path.join(postsDir, file), 'utf-8');
                // Simple frontmatter parser
                const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
                const metadata: any = {};

                if (frontmatterMatch) {
                    const frontmatter = frontmatterMatch[1];
                    frontmatter.split('\n').forEach(line => {
                        const [key, ...values] = line.split(':');
                        if (key && values.length) {
                            let value = values.join(':').trim();
                            if (value.startsWith('[') && value.endsWith(']')) {
                                // Simple array parser
                                metadata[key.trim()] = value.slice(1, -1).split(',').map(s => s.trim());
                            } else {
                                metadata[key.trim()] = value;
                            }
                        }
                    });
                }

                return {
                    name: file,
                    path: `/blog/posts/${file}`,
                    frontmatter: metadata
                };
            });

        return new Response(JSON.stringify(files), {
            status: 200,
            headers: { 'Content-Type': 'application/json' }
        });
    } catch (error) {
        return new Response(JSON.stringify({ error: 'Failed to list files' }), {
            status: 500,
            headers: { 'Content-Type': 'application/json' }
        });
    }
}
