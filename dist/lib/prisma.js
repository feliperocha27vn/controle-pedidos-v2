import { PrismaClient } from '@prisma/client';
export const prisma = new PrismaClient({
    log: ['error', 'warn'],
    datasources: {
        db: {
            url: process.env.DATABASE_URL,
        },
    },
});
prisma
    .$connect()
    .then(() => {
    console.log('✅ Database connected successfully');
})
    .catch(error => {
    console.error('❌ Database connection failed:', error);
    process.exit(1);
});
process.on('beforeExit', async () => {
    await prisma.$disconnect();
    console.log('🔌 Database disconnected');
});
