import z from 'zod';
import { prisma } from '../../lib/prisma.ts';
export const changeOrderStatus = async (app) => {
    app.patch('/order/:orderId/change-status', {
        schema: {
            params: z.object({ orderId: z.string() }),
            body: z.object({ status: z.string('paid') })
        }
    }, async (request, reply) => {
        const { status } = request.body;
        const { orderId } = request.params;
        await prisma.orders.update({
            where: { id: orderId },
            data: { status }
        });
        reply.status(200).send();
    });
};
