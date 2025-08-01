import type { FastifyPluginAsyncZod } from 'fastify-type-provider-zod'
import z from 'zod'
import { prisma } from '../../lib/prisma.ts'

export const createNewRecipe: FastifyPluginAsyncZod = async app => {
  app.post(
    '/recipes',
    {
      schema: {
        body: z.object({
          title: z.string(),
          price: z.preprocess(value => {
            if (typeof value === 'string') {
              return value.replace(',', '.')
            }
          }, z.coerce.number()),
        }),
      },
    },
    async (request, reply) => {
      const { title, price } = request.body

      await prisma.recipes.create({
        data: {
          title,
          price,
        },
      })

      reply.status(201).send()
    }
  )
}
