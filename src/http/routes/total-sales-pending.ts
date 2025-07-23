import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import { prisma } from '../../lib/prisma.ts'

export const totalOrdersPending: FastifyPluginAsyncZod = async app => {
  app.get('/orders/pending', async (_, reply) => {
    const total = await prisma.orders.aggregate({
      _sum: {
        totalAmount: true,
      },
      where: {
        status: 'pending',
      },
    })

    reply.status(200).send(total._sum)
  })
}
