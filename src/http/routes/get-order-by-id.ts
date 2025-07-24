import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import z from 'zod'
import { prisma } from '../../lib/prisma.ts'

export const getOrderById: FastifyPluginAsyncZod = async app => {
  app.get('/order/:id', {
    schema: {
        params: z.object({ id: z.string() })
    }
  } ,async (request, reply) => {
    const { id } = request.params

    const order = await prisma.orders.findUnique({
        where: {
            id
        },
      select: {
        id: true,
        customerName: true,
        quantity: true,
        totalAmount: true,
        status: true,
        recipe: {
          select: {
            title: true,
          },
        },
      },
    })

    reply.status(200).send(order)
  })
}
