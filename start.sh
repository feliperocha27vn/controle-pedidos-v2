#!/bin/sh

# Função para aguardar o banco de dados
wait_for_db() {
    echo "🔄 Waiting for database to be ready..."
    
    # Aguarda até 30 segundos pelo banco
    for i in $(seq 1 30); do
        if npx prisma db push --accept-data-loss > /dev/null 2>&1; then
            echo "✅ Database is ready!"
            return 0
        fi
        echo "⏳ Database not ready yet, waiting... ($i/30)"
        sleep 1
    done
    
    echo "❌ Database connection timeout"
    exit 1
}

# Aguarda o banco estar pronto
wait_for_db

# Executa as migrações
echo "🔄 Running database migrations..."
npx prisma migrate deploy --schema=./prisma/schema.prisma

# Aguarda um pouco para garantir que tudo está pronto
echo "⏳ Waiting for services to stabilize..."
sleep 2

# Inicia a aplicação
echo "🚀 Starting application..."
echo "📍 Application will be available on port $PORT"
echo "🌐 Health check endpoint: /health"

exec npm run start:production