import { addMonths, startOfMonth } from 'date-fns'
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import { prisma } from '../../lib/prisma.ts'

export const totalOrdersPending: FastifyPluginAsyncZod = async app => {
  app.get('/orders/pending', async (_, reply) => {
    const startMonth = startOfMonth(new Date())
    const endMonth = addMonths(startMonth, 1)

    const total = await prisma.orders.aggregate({
      _sum: {
        totalAmount: true,
      },
      where: {
        status: 'pending',
        createdAt: {
          gte: startMonth,
          lt: endMonth,
        },
      },
    })

    reply.status(200).send(total._sum)
  })
}
