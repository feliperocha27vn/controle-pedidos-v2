import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import { prisma } from '../../lib/prisma.ts'

export const fetchOrdersByDelivery: FastifyPluginAsyncZod = async app => {
  app.get('/orders/delivery', async (_, reply) => {
    const order = await prisma.orders.findMany({
      where: {
        isDelivered: false,
      },
      select: {
        id: true,
        customerName: true,
        totalAmount: true,
        status: true,
        deliveryDate: true,
      },
    })

    reply.status(200).send(order)
  })
}
