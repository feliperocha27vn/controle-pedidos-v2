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
  logger: false, // Desabilita logs para inicialização mais rápida
  disableRequestLogging: true,
  trustProxy: true
}).withTypeProvider<ZodTypeProvider>()

app.register(fastifyCors, {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS']
})

app.setSerializerCompiler(serializerCompiler)
app.setValidatorCompiler(validatorCompiler)

// Health check endpoint - simples e rápido
app.get('/health', async () => {
  return { status: 'ok', timestamp: Date.now() }
})

// Registrar rotas da aplicação
app.register(appRoutes)

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
  } catch (error) {
    console.error('Error starting server:', error)
    process.exit(1)
  }
}

start()