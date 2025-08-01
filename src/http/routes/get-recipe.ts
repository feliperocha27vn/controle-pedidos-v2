import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import z from 'zod'
import { prisma } from '../../lib/prisma.ts'

export const getRecipe: FastifyPluginAsyncZod = async app => {
  app.get(
    '/recipe/:idRecipe',
    {
      schema: {
        params: z.object({ idRecipe: z.uuid() }),
      },
    },
    async (request, reply) => {
      const { idRecipe } = request.params

      const recipe = await prisma.recipes.findUnique({
        where: {
          id: idRecipe,
        },
      })

      reply.status(201).send(recipe)
    }
  )
}
