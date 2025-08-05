import { addDays } from 'date-fns'
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import z from 'zod'
import { prisma } from '../../lib/prisma.ts'

export const fetchOrderByDate: FastifyPluginAsyncZod = async app => {
  app.get(
    '/orders-by-date',
    {
      schema: {
        querystring: z.object({
          date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/), // Exige formato YYYY-MM-DD
        }),
      },
    },
    async (request, reply) => {
      const { date } = request.query

      const startOfDayDate = new Date(date)
      const startOfNextDay = addDays(startOfDayDate, 1)
      const orders = await prisma.orders.findMany({
        where: {
          createdAt: {
            gte: startOfDayDate,
            lt: startOfNextDay,
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

      reply.status(200).send({ orders })
    }
  )
}
