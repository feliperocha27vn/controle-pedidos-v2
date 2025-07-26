import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import z from 'zod'
import { prisma } from '../../lib/prisma.ts'

export const fetchOrdersByName: FastifyPluginAsyncZod = async app => {
  app.get(
    '/orders/search',
    {
      schema: {
        querystring: z.object({
          search: z.string().optional(),
        }),
      },
    },
    async (request, reply) => {
      const { search } = request.query

      const orders = await prisma.orders.findMany({
        where: {
          customerName: {
            search: search?.trim(),
          },
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
    }
  )
}
