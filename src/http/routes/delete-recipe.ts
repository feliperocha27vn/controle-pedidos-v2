import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import z from 'zod'
import { prisma } from '../../lib/prisma.ts'

export const deleteRecipe: FastifyPluginAsyncZod = async app => {
  app.delete(
    '/recipes/:idRecipe',
    {
      schema: {
        params: z.object({
          idRecipe: z.uuid(),
        }),
      },
    },
    async (request, reply) => {
      const { idRecipe } = request.params

      await prisma.recipesOrder.deleteMany({
        where: {
          recipesId: idRecipe,
        },
      })

      await prisma.recipes.delete({
        where: { id: idRecipe },
      })

      reply.status(200).send()
    }
  )
}
