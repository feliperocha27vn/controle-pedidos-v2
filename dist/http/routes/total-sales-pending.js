import { prisma } from '../../lib/prisma.ts';
export const totalOrdersPending = async (app) => {
    app.get('/orders/pending', async (_, reply) => {
        const total = await prisma.orders.aggregate({
            _sum: {
                totalAmount: true,
            },
            where: {
                status: 'pending',
            },
        });
        reply.status(200).send(total._sum);
    });
};
