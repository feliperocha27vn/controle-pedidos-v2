#!/bin/sh

# Função para aguardar o banco de dados
wait_for_db() {
    echo "🔄 Waiting for database to be ready..."
    
    # Aguarda até 60 segundos pelo banco
    for i in $(seq 1 60); do
        if npx prisma db push --accept-data-loss > /dev/null 2>&1; then
            echo "✅ Database is ready!"
            return 0
        fi
        echo "⏳ Database not ready yet, waiting... ($i/60)"
        sleep 1
    done
    
    echo "❌ Database connection timeout"
    exit 1
}

# Aguarda o banco estar pronto
wait_for_db

# Executa as migrações
echo "🔄 Running database migrations..."
npx prisma migrate deploy

# Inicia a aplicação
echo "🚀 Starting application..."
exec npm run start:production