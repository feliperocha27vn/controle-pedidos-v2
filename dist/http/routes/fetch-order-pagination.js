import z from 'zod';
import { prisma } from '../../lib/prisma.ts';
export const fetchOrdersPagination = async (app) => {
    app.get('/orders/:page', {
        schema: {
            params: z.object({
                page: z.coerce.number(),
            }),
        },
    }, async (request, reply) => {
        const { page } = request.params;
        const orders = await prisma.orders.findMany({
            select: {
                id: true,
                customerName: true,
                quantity: true,
                totalAmount: true,
                status: true,
                createdAt: true,
                recipe: {
                    select: {
                        title: true,
                    },
                },
            },
            take: 5,
            skip: (page - 1) * 5,
        });
        const totalOrder = await prisma.orders.count();
        const totalPages = Math.ceil(totalOrder / 5);
        reply.status(200).send({
            orders,
            totalPages,
        });
    });
};
