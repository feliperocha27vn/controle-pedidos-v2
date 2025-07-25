import z from 'zod';
import { prisma } from '../../lib/prisma.ts';
export const createNewRecipe = async (app) => {
    app.post('/recipes', {
        schema: {
            body: z.object({
                title: z.string(),
                price: z.coerce.number(),
            }),
        },
    }, async (request, reply) => {
        const { title, price } = request.body;
        await prisma.recipes.create({
            data: {
                title,
                price,
            },
        });
        reply.status(201).send();
    });
};
