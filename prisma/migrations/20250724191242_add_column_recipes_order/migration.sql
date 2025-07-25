-- CreateTable
CREATE TABLE "recipes_order" (
    "id" TEXT NOT NULL,
    "quantity" INTEGER NOT NULL,
    "orders_id" TEXT NOT NULL,
    "recipe_id" TEXT NOT NULL,

    CONSTRAINT "recipes_order_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "recipes_order" ADD CONSTRAINT "recipes_order_orders_id_fkey" FOREIGN KEY ("orders_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "recipes_order" ADD CONSTRAINT "recipes_order_recipe_id_fkey" FOREIGN KEY ("recipe_id") REFERENCES "recipes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
