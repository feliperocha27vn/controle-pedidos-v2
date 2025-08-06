import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import z from 'zod'
import { prisma } from '../../lib/prisma.ts'

export const createNewOrder: FastifyPluginAsyncZod = async app => {
  app.post(
    '/orders',
    {
      schema: {
        body: z.object({
          idRecipe: z.uuid(),
          customerName: z.string(),
          quantity: z.coerce.number(),
          status: z.enum(['pending', 'paid']),
          isDelivered: z.boolean(),
          deliveryDate: z.coerce.date(),
        }),
      },
    },
    async (request, reply) => {
      const {
        idRecipe,
        customerName,
        quantity,
        status,
        isDelivered,
        deliveryDate,
      } = request.body

      const recipe = await prisma.recipes.findUniqueOrThrow({
        where: {
          id: idRecipe,
        },
      })

      await prisma.orders.create({
        data: {
          customerName,
          quantity,
          totalAmount: recipe.price.mul(quantity),
          status,
          recipesId: idRecipe,
          isDelivered,
          deliveryDate,
        },
      })

      reply.status(201).send()
    }
  )
}
