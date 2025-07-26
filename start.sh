#!/bin/sh
# =============================================================================
# START SCRIPT OTIMIZADO - API UM DOCE
# Melhorado com retry logic, logging e graceful shutdown
# =============================================================================

set -e  # Exit on any error

# Configurações
MAX_DB_WAIT=60
RETRY_INTERVAL=2
LOG_PREFIX="[API-UM-DOCE]"

# Função de logging estruturado
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_PREFIX $1"
}

# Função para aguardar o banco de dados com retry melhorado
wait_for_db() {
    log "🔄 Waiting for database to be ready..."
    
    local attempts=0
    local max_attempts=$((MAX_DB_WAIT / RETRY_INTERVAL))
    
    while [ $attempts -lt $max_attempts ]; do
        if npx prisma db push --accept-data-loss --schema=./prisma/schema.prisma > /dev/null 2>&1; then
            log "✅ Database connection established successfully!"
            return 0
        fi
        
        attempts=$((attempts + 1))
        log "⏳ Database not ready yet, attempt $attempts/$max_attempts..."
        sleep $RETRY_INTERVAL
    done
    
    log "❌ Database connection timeout after ${MAX_DB_WAIT}s"
    exit 1
}

# Função para executar migrações com retry
run_migrations() {
    log "🔄 Running database migrations..."
    
    local attempts=0
    local max_attempts=3
    
    while [ $attempts -lt $max_attempts ]; do
        if npx prisma migrate deploy --schema=./prisma/schema.prisma; then
            log "✅ Database migrations completed successfully!"
            return 0
        fi
        
        attempts=$((attempts + 1))
        log "⚠️  Migration attempt $attempts/$max_attempts failed, retrying..."
        sleep 3
    done
    
    log "❌ Database migrations failed after $max_attempts attempts"
    exit 1
}

# Função para verificar health da aplicação
check_app_health() {
    log "🔍 Performing application health check..."
    
    # Aguarda a aplicação inicializar
    sleep 5
    
    if command -v curl > /dev/null 2>&1; then
        if curl -f http://localhost:3333/health > /dev/null 2>&1; then
            log "✅ Application health check passed!"
            return 0
        fi
    else
        # Fallback usando node se curl não estiver disponível
        if node -e "require('http').get('http://localhost:3333/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) }).on('error', () => process.exit(1))" > /dev/null 2>&1; then
            log "✅ Application health check passed!"
            return 0
        fi
    fi
    
    log "⚠️  Application health check failed, but continuing..."
    return 0  # Não falha o startup por causa do health check
}

# Função para graceful shutdown
graceful_shutdown() {
    log "🛑 Received shutdown signal, performing graceful shutdown..."
    
    if [ ! -z "$APP_PID" ]; then
        log "📤 Sending SIGTERM to application (PID: $APP_PID)..."
        kill -TERM "$APP_PID" 2>/dev/null || true
        
        # Aguarda até 30 segundos para shutdown graceful
        local wait_time=0
        while [ $wait_time -lt 30 ] && kill -0 "$APP_PID" 2>/dev/null; do
            sleep 1
            wait_time=$((wait_time + 1))
        done
        
        # Force kill se necessário
        if kill -0 "$APP_PID" 2>/dev/null; then
            log "⚡ Force killing application..."
            kill -KILL "$APP_PID" 2>/dev/null || true
        fi
    fi
    
    log "✅ Graceful shutdown completed"
    exit 0
}

# Configurar signal handlers para graceful shutdown
trap graceful_shutdown TERM INT QUIT

# =============================================================================
# MAIN EXECUTION
# =============================================================================

log "🚀 Starting API Um Doce initialization..."
log "📊 Node.js version: $(node --version)"
log "📊 NPM version: $(npm --version)"
log "🌍 Environment: ${NODE_ENV:-development}"
log "🔌 Port: ${PORT:-3333}"

# Aguardar banco de dados
wait_for_db

# Executar migrações
run_migrations

# Aguardar estabilização dos serviços
log "⏳ Waiting for services to stabilize..."
sleep 3

# Iniciar aplicação
log "🚀 Starting application..."
log "📍 Application will be available on port ${PORT:-3333}"
log "🌐 Health check endpoint: /health"
log "🕐 Startup completed at $(date)"

# Executar aplicação em background para permitir signal handling
npm run start:production &
APP_PID=$!

# Aguardar a aplicação inicializar e fazer health check
check_app_health

log "✅ Application started successfully with PID: $APP_PID"

# Aguardar o processo da aplicação
wait $APP_PID