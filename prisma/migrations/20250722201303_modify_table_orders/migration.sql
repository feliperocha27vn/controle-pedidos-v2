/*
  Warnings:

  - Added the required column `recipes_id` to the `orders` table without a default value. This is not possible if the table is not empty.

*/
-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "recipes_id" TEXT NOT NULL;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_recipes_id_fkey" FOREIGN KEY ("recipes_id") REFERENCES "recipes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
