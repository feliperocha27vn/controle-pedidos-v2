import { compare } from 'bcryptjs';
import z from 'zod';
import { prisma } from '../../lib/prisma.ts';
export const authentication = async (app) => {
    app.post('/auth', {
        schema: {
            body: z.object({
                name: z.string(),
                password: z.string(),
            }),
        },
    }, async (request, reply) => {
        const { name, password } = request.body;
        const user = await prisma.users.findFirstOrThrow({
            where: { name },
        });
        const isPasswordValid = await compare(password, user.passwordHash);
        if (!isPasswordValid) {
            throw new Error('Invalid credentials');
        }
        reply.status(200).send({ message: 'Authenticated' });
    });
};
