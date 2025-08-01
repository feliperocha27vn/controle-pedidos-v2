import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import z from 'zod'
import { prisma } from '../../lib/prisma.ts'

export const updateRecipe: FastifyPluginAsyncZod = async app => {
  app.put(
    '/recipes/:idRecipe',
    {
      schema: {
        params: z.object({
          idRecipe: z.uuid(),
        }),
        body: z.object({
          title: z.string().optional(),
          price: z
            .preprocess(value => {
              if (typeof value === 'string') {
                return value.replace(',', '.')
              }
            }, z.coerce.number())
            .optional(),
        }),
      },
    },
    async (request, reply) => {
      const { idRecipe } = request.params
      const { title, price } = request.body

      await prisma.recipes.update({
        data: {
          price,
          title,
        },
        where: { id: idRecipe },
      })

      reply.status(200).send()
    }
  )
}
