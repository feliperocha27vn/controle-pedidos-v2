/*
  Warnings:

  - You are about to drop the `Recipes` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropTable
DROP TABLE "Recipes";

-- CreateTable
CREATE TABLE "recipes" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "price" DECIMAL(65,30) NOT NULL,
    "created" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recipes_pkey" PRIMARY KEY ("id")
);
