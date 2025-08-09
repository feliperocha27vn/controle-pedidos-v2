import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import z from 'zod'
import { prisma } from '../../lib/prisma.ts'

export const changeOrderDeliveryStatus: FastifyPluginAsyncZod = async app => {
  app.patch(
    '/order/change-status/:orderId',
    {
      schema: {
        params: z.object({ orderId: z.string() }),
      },
    },
    async (request, reply) => {
      const { orderId } = request.params

      await prisma.orders.update({
        where: { id: orderId },
        data: { isDelivered: true },
      })

      reply.status(200).send()
    }
  )
}
