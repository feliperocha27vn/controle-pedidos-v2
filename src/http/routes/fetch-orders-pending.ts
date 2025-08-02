import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import { prisma } from '../../lib/prisma.ts'

export const fetchOrdersPending: FastifyPluginAsyncZod = async app => {
  app.get('/orders/pending-filter', async (_, reply) => {
    const orders = await prisma.orders.findMany({
      where: {
        status: 'pending',
      },
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
