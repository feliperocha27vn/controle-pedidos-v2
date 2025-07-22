import type { FastifyInstance } from 'fastify'
import { authentication } from './routes/authentication.ts'
import { createNewOrder } from './routes/create-new-order.ts'
import { createNewRecipe } from './routes/create-new-recipe.ts'
import { fetchOrders } from './routes/fetch-orders.ts'
import { fetchRecipes } from './routes/fetch-recipes.ts'
import { register } from './routes/register-user.ts'

export function appRoutes(app: FastifyInstance) {
  // Users
  app.register(authentication)
  app.register(register)
  // Recipes
  app.register(createNewRecipe)
  app.register(fetchRecipes)
  // Orders
  app.register(createNewOrder)
  app.register(fetchOrders)
}
