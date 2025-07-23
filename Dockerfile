FROM node:22.15-alpine3.20 AS build

WORKDIR /usr/src

COPY package*.json ./

RUN npm i

COPY . .
COPY .env ./
COPY prisma ./

RUN npm ci --only=production cache clear
FROM node:22.15-alpine3.20

WORKDIR /usr/src

COPY --from=build /usr/src/package.json ./package.json
COPY --from=build /usr/src/node_modules ./node_modules 
COPY --from=build /usr/src/.env ./.env
COPY --from=build /usr/src/src ./src
COPY --from=build /usr/src/prisma ./prisma

EXPOSE 3333

CMD ["sh", "-c", "npx prisma migrate deploy && npm run start"]