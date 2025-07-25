import fastifyCors from '@fastify/cors';
import { fastify } from 'fastify';
import { serializerCompiler, validatorCompiler, } from 'fastify-type-provider-zod';
import { env } from './env.ts';
import { appRoutes } from './http/app-routes.ts';
const app = fastify({
    logger: {
        level: 'info',
        transport: {
            target: 'pino-pretty',
            options: {
                colorize: true,
            },
        },
    },
}).withTypeProvider();
app.register(fastifyCors, {
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
});
app.setSerializerCompiler(serializerCompiler);
app.setValidatorCompiler(validatorCompiler);
app.get('/health', async (request, reply) => {
    try {
        return {
            status: 'ok',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            memory: process.memoryUsage(),
        };
    }
    catch (error) {
        reply.status(503);
        return {
            status: 'error',
            timestamp: new Date().toISOString(),
            error: error instanceof Error ? error.message : 'Unknown error',
        };
    }
});
app.register(appRoutes);
const gracefulShutdown = async (signal) => {
    console.log(`Received ${signal}, shutting down gracefully...`);
    try {
        await app.close();
        console.log('Server closed successfully');
        process.exit(0);
    }
    catch (error) {
        console.error('Error during shutdown:', error);
        process.exit(1);
    }
};
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
const start = async () => {
    try {
        await app.listen({
            port: env.PORT,
            host: '0.0.0.0',
        });
        console.log(`🦅 Server is running on port ${env.PORT}`);
    }
    catch (error) {
        console.error('Error starting server:', error);
        process.exit(1);
    }
};
start();
