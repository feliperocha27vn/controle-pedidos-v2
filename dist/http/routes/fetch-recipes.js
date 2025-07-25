import { prisma } from '../../lib/prisma.ts';
export const fetchRecipes = async (app) => {
    app.get('/recipes', async (_, reply) => {
        const recipes = await prisma.recipes.findMany();
        reply.status(201).send(recipes);
    });
};
