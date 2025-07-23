import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import { prisma } from '../../lib/prisma.ts'

export const totalOrdersPaid: FastifyPluginAsyncZod = async app => {
  app.get('/orders/paid', async (_, reply) => {
    const total = await prisma.orders.aggregate({
      _sum: {
        totalAmount: true,
      },
      where: {
        status: 'paid',
      },
    })

    reply.status(200).send(total._sum)
  })
}
