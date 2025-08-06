import { addDays, endOfDay, startOfDay } from 'date-fns'
import { toZonedTime } from 'date-fns-tz'
import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import z from 'zod'
import { prisma } from '../../lib/prisma.ts'

const timeZone = 'America/Sao_Paulo'

export const fetchOrdersDeliveryByDate: FastifyPluginAsyncZod = async app => {
  app.get(
    '/orders/delivery/by-date',
    {
      schema: {
        querystring: z.object({
          date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
        }),
      },
    },
    async (request, reply) => {
      try {
        const { date } = request.query

        // Converte a data recebida para o timezone local
        const zonedDate = toZonedTime(new Date(date), timeZone)

        // Calcula o início e o fim do dia no timezone local usando date-fns-tz
        const startOfDayDate = startOfDay(zonedDate)
        const endOfDayDate = endOfDay(zonedDate)

        const orders = await prisma.orders.findMany({
          where: {
            isDelivered: false,
            deliveryDate: {
              gte: startOfDayDate,
              lt: addDays(endOfDayDate, 1),
            },
          },
          select: {
            id: true,
            customerName: true,
            totalAmount: true,
            status: true,
            deliveryDate: true,
          },
        })

        reply.status(200).send(orders)
      } catch (error) {
        request.log.error(error)
        reply.status(500).send({ message: 'Erro interno no servidor' })
      }
    }
  )
}
