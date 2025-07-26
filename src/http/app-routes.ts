import type { FastifyInstance } from 'fastify'
import { authentication } from './routes/authentication.ts'
import { changeOrderStatus } from './routes/change-order-status.ts'
import { createNewOrder } from './routes/create-new-order.ts'
import { createNewRecipe } from './routes/create-new-recipe.ts'
import { fetchOrdersPagination } from './routes/fetch-order-pagination.ts'
import { fetchOrdersByName } from './routes/fetch-orders-by-name.ts'
import { fetchRecipes } from './routes/fetch-recipes.ts'
import { getOrderById } from './routes/get-order-by-id.ts'
import { register } from './routes/register-user.ts'
import { totalOrdersPaid } from './routes/total-sales-paid.ts'
import { totalOrdersPending } from './routes/total-sales-pending.ts'
import { totalOrders } from './routes/total-sales.ts'

export function appRoutes(app: FastifyInstance) {
  // Users
  app.register(authentication)
  app.register(register)
  // Recipes
  app.register(createNewRecipe)
  app.register(fetchRecipes)
  // Orders
  app.register(createNewOrder)
  app.register(fetchOrdersByName)
  app.register(totalOrders)
  app.register(totalOrdersPending)
  app.register(totalOrdersPaid)
  app.register(changeOrderStatus)
  app.register(getOrderById)
  app.register(fetchOrdersPagination)
}
