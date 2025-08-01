import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import { prisma } from '../../lib/prisma.ts'
import { getPreviousWeekRange } from '../../utils/get-previous-week-range.ts'

export const fetchPreviousOrdersLastWeek: FastifyPluginAsyncZod = async app => {
  app.get('/orders/lastWeek', async (_, reply) => {
    const { start, end } = getPreviousWeekRange()

    const ordersByDayRaw: [] = await prisma.$queryRaw`
        SELECT DATE("createdAt") as day, COUNT(*) as count
        FROM "orders"
        WHERE "createdAt" BETWEEN ${start} AND ${end}
        GROUP BY day
        ORDER BY day;
    `

    const ordersByDay = ordersByDayRaw.map((item: any) => ({
      day: item.day,
      count: Number(item.count),
    }))

    reply.status(200).send(ordersByDay)
  })
}
