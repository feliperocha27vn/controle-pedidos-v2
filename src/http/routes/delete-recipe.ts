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

      await prisma.recipes.update({
        data: {
          isActivite: false,
        },
        where: { id: idRecipe },
      })

      reply.status(200).send()
    }
  )
}
