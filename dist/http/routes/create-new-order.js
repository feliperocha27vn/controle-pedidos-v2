import z from 'zod';
import { prisma } from '../../lib/prisma.ts';
export const createNewOrder = async (app) => {
    app.post('/orders', {
        schema: {
            body: z.object({
                idRecipe: z.uuid(),
                customerName: z.string(),
                quantity: z.coerce.number(),
                status: z.enum(['pending', 'paid']),
            }),
        },
    }, async (request, reply) => {
        const { idRecipe, customerName, quantity, status } = request.body;
        const recipe = await prisma.recipes.findUniqueOrThrow({
            where: {
                id: idRecipe,
            },
        });
        await prisma.orders.create({
            data: {
                customerName,
                quantity,
                totalAmount: recipe.price.mul(quantity),
                status,
                recipesId: idRecipe,
            },
        });
        reply.status(201).send();
    });
};
