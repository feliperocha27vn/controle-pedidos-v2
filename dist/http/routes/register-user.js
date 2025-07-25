import { hash } from 'bcryptjs';
import z from 'zod';
import { prisma } from '../../lib/prisma.ts';
export const register = async (app) => {
    app.post('/register', {
        schema: {
            body: z.object({
                name: z.string(),
                password: z.string(),
            }),
        },
    }, async (request, reply) => {
        const { name, password } = request.body;
        const passwordHash = await hash(password, 6);
        await prisma.users.create({
            data: {
                name,
                passwordHash,
            },
        });
        reply.status(201).send();
    });
};
