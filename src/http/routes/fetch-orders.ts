import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import { prisma } from '../../lib/prisma.ts'

export const fetchOrders: FastifyPluginAsyncZod = async app => {
  app.get('/orders', async (_, reply) => {
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
    })

    reply.status(200).send(orders)
  })
}
