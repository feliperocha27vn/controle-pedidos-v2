import fastifyCors from '@fastify/cors'
import { fastify } from 'fastify'
import {
  serializerCompiler,
  validatorCompiler,
  type ZodTypeProvider,
} from 'fastify-type-provider-zod'
import { env } from './env.ts'
import { appRoutes } from './http/app-routes.ts'

const app = fastify({
  logger: {
    level: 'info',
  },
  disableRequestLogging: false,
  trustProxy: true,
}).withTypeProvider<ZodTypeProvider>()

app.register(fastifyCors, {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
})

app.setSerializerCompiler(serializerCompiler)
app.setValidatorCompiler(validatorCompiler)

// Health check endpoint - simples e rápido
app.get('/health', async () => {
  return {
    status: 'ok',
    timestamp: Date.now(),
    port: env.PORT,
    environment: process.env.NODE_ENV || 'development',
  }
})

// Root endpoint para debug
app.get('/', async () => {
  return {
    message: 'API Um Doce está funcionando!',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      auth: '/auth',
      register: '/register',
      recipes: '/recipes',
      orders: '/orders',
    },
  }
})

// Registrar rotas da aplicação
app.register(appRoutes)

// Error handler
app.setErrorHandler(async (error, request, reply) => {
  console.error('Error:', error)
  reply.status(500).send({
    error: 'Internal Server Error',
    message: error.message,
  })
})

// Graceful shutdown handling
const gracefulShutdown = async (signal: string) => {
  console.log(`Received ${signal}, shutting down gracefully...`)
  try {
    await app.close()
    console.log('Server closed successfully')
    process.exit(0)
  } catch (error) {
    console.error('Error during shutdown:', error)
    process.exit(1)
  }
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'))
process.on('SIGINT', () => gracefulShutdown('SIGINT'))

// Start server with better error handling
const start = async () => {
  try {
    await app.listen({
      port: env.PORT,
      host: '0.0.0.0',
    })
    console.log(`🦅 Server is running on port ${env.PORT}`)
    console.log(`📍 Health check: http://localhost:${env.PORT}/health`)
    console.log(`🌐 API root: http://localhost:${env.PORT}/`)
  } catch (error) {
    console.error('Error starting server:', error)
    process.exit(1)
  }
}

start()
