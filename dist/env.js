import z from 'zod';
const envSchema = z.object({
    PORT: z.coerce.number().default(3333),
    DATABASE_URL: z.string().optional(),
    DB_HOST: z.string().optional(),
    DB_PORT: z.coerce.number().optional(),
    DB_USER: z.string().optional(),
    DB_PASSWORD: z.string().optional(),
    DB_NAME: z.string().optional(),
});
export const env = envSchema.parse(process.env);
