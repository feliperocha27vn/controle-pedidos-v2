-- AlterTable
ALTER TABLE "orders" ADD COLUMN     "delivery_date" TIMESTAMP(3),
ADD COLUMN     "isDelivered" BOOLEAN NOT NULL DEFAULT true;
