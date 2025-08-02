import type { FastifyInstance } from 'fastify'
import { authentication } from './routes/authentication.ts'
import { changeOrderStatus } from './routes/change-order-status.ts'
import { createNewOrder } from './routes/create-new-order.ts'
import { createNewRecipe } from './routes/create-new-recipe.ts'
import { deleteRecipe } from './routes/delete-recipe.ts'
import { fetchOrdersPagination } from './routes/fetch-order-pagination.ts'
import { fetchOrdersByName } from './routes/fetch-orders-by-name.ts'
import { fetchOrdersPending } from './routes/fetch-orders-pending.ts'
import { fetchPreviousOrdersLastWeek } from './routes/fetch-previous-orders-last-week.ts'
import { fetchRecipes } from './routes/fetch-recipes.ts'
import { getOrderById } from './routes/get-order-by-id.ts'
import { getRecipe } from './routes/get-recipe.ts'
import { register } from './routes/register-user.ts'
import { totalOrdersPaid } from './routes/total-sales-paid.ts'
import { totalOrdersPending } from './routes/total-sales-pending.ts'
import { totalOrders } from './routes/total-sales.ts'
import { updateRecipe } from './routes/update-recipe.ts'

export function appRoutes(app: FastifyInstance) {
  // Users
  app.register(authentication)
  app.register(register)
  // Recipes
  app.register(createNewRecipe)
  app.register(fetchRecipes)
  app.register(deleteRecipe)
  app.register(getRecipe)
  app.register(updateRecipe)
  // Orders
  app.register(createNewOrder)
  app.register(fetchOrdersByName)
  app.register(totalOrders)
  app.register(totalOrdersPending)
  app.register(totalOrdersPaid)
  app.register(changeOrderStatus)
  app.register(getOrderById)
  app.register(fetchOrdersPagination)
  app.register(fetchPreviousOrdersLastWeek)
  app.register(fetchOrdersPending)
}
