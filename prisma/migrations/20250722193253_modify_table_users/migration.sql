/*
  Warnings:

  - You are about to drop the column `nome` on the `users` table. All the data in the column will be lost.
  - You are about to drop the column `senha` on the `users` table. All the data in the column will be lost.
  - Added the required column `name` to the `users` table without a default value. This is not possible if the table is not empty.
  - Added the required column `password_hash` to the `users` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "users" DROP COLUMN "nome",
DROP COLUMN "senha",
ADD COLUMN     "name" TEXT NOT NULL,
ADD COLUMN     "password_hash" TEXT NOT NULL;
