import { prisma } from '../../lib/prisma.ts';
export const totalOrders = async (app) => {
    app.get('/orders/total', async (_, reply) => {
        const total = await prisma.orders.aggregate({
            _sum: {
                totalAmount: true,
            },
        });
        reply.status(200).send(total._sum);
    });
};
