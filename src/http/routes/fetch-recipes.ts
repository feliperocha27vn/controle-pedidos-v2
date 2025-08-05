import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import { prisma } from '../../lib/prisma.ts'

export const fetchRecipes: FastifyPluginAsyncZod = async app => {
  app.get('/recipes', async (_, reply) => {
    const recipes = await prisma.recipes.findMany({
      where: {
        isActivite: true,
      },
    })

    reply.status(201).send(recipes)
  })
}
