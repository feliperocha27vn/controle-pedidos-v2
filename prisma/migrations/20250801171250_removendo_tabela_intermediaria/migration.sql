/*
  Warnings:

  - You are about to drop the `recipes_order` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "recipes_order" DROP CONSTRAINT "recipes_order_orders_id_fkey";

-- DropForeignKey
ALTER TABLE "recipes_order" DROP CONSTRAINT "recipes_order_recipe_id_fkey";

-- DropTable
DROP TABLE "recipes_order";
