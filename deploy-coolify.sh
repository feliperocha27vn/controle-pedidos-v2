#!/bin/bash
# =============================================================================
# 🚀 SCRIPT DE DEPLOY OTIMIZADO PARA COOLIFY
# Deploy seguro com backup automático e validação
# =============================================================================

set -e

# Configurações
COMPOSE_FILE="docker-compose-coolify.yaml"
BACKUP_DIR="./backups"
LOG_FILE="./deploy.log"
APP_NAME="api-um-doce"
HEALTH_ENDPOINT="https://api.umdoce.dev.br/health"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função de logging
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Função para criar backup
create_backup() {
    log "🔄 Creating backup..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup do docker-compose atual
    if [ -f "$COMPOSE_FILE" ]; then
        cp "$COMPOSE_FILE" "$BACKUP_DIR/docker-compose-$(date +%Y%m%d_%H%M%S).yaml"
        success "✅ Docker compose backed up"
    fi
    
    # Backup dos dados do banco (se existir)
    if docker volume ls | grep -q "controle_pedidos_db"; then
        log "📦 Creating database backup..."
        docker run --rm \
            -v controle_pedidos_db:/data \
            -v "$PWD/$BACKUP_DIR":/backup \
            alpine:latest \
            tar czf "/backup/db-backup-$(date +%Y%m%d_%H%M%S).tar.gz" -C /data .
        success "✅ Database backup created"
    fi
}

# Função para validar configuração
validate_config() {
    log "🔍 Validating configuration..."
    
    # Verificar se o arquivo compose existe
    if [ ! -f "$COMPOSE_FILE" ]; then
        error "❌ Docker compose file not found: $COMPOSE_FILE"
        exit 1
    fi
    
    # Validar sintaxe do docker-compose
    if ! docker-compose -f "$COMPOSE_FILE" config > /dev/null 2>&1; then
        error "❌ Invalid docker-compose configuration"
        exit 1
    fi
    
    success "✅ Configuration validated"
}

# Função para fazer deploy
deploy() {
    log "🚀 Starting deployment..."
    
    # Parar serviços existentes
    log "🛑 Stopping existing services..."
    docker-compose -f "$COMPOSE_FILE" down --remove-orphans || true
    
    # Limpar imagens antigas
    log "🧹 Cleaning old images..."
    docker image prune -f || true
    
    # Build e start dos serviços
    log "🔨 Building and starting services..."
    docker-compose -f "$COMPOSE_FILE" up -d --build --force-recreate
    
    success "✅ Services started"
}

# Função para verificar health
check_health() {
    log "🏥 Checking application health..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "🔍 Health check attempt $attempt/$max_attempts..."
        
        # Verificar se o container está rodando
        if docker-compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
            # Verificar health check interno
            if docker-compose -f "$COMPOSE_FILE" ps | grep -q "healthy"; then
                # Verificar endpoint externo (se disponível)
                if curl -f -s "$HEALTH_ENDPOINT" > /dev/null 2>&1; then
                    success "✅ Application is healthy and accessible!"
                    return 0
                else
                    warning "⚠️  Internal health OK, but external endpoint not accessible yet..."
                fi
            else
                log "⏳ Waiting for internal health check..."
            fi
        else
            warning "⚠️  Container not running yet..."
        fi
        
        sleep 10
        attempt=$((attempt + 1))
    done
    
    error "❌ Health check failed after $max_attempts attempts"
    return 1
}

# Função para rollback
rollback() {
    error "🔄 Performing rollback..."
    
    # Parar serviços atuais
    docker-compose -f "$COMPOSE_FILE" down --remove-orphans || true
    
    # Restaurar backup mais recente
    local latest_backup=$(ls -t "$BACKUP_DIR"/docker-compose-*.yaml 2>/dev/null | head -n1)
    if [ -n "$latest_backup" ]; then
        cp "$latest_backup" "$COMPOSE_FILE"
        log "📦 Restored from backup: $latest_backup"
        
        # Tentar subir com a configuração anterior
        docker-compose -f "$COMPOSE_FILE" up -d
        warning "⚠️  Rollback completed. Please check the application."
    else
        error "❌ No backup found for rollback"
    fi
}

# Função para mostrar logs
show_logs() {
    log "📋 Showing application logs..."
    docker-compose -f "$COMPOSE_FILE" logs --tail=50 "$APP_NAME"
}

# Função principal
main() {
    log "🚀 Starting Coolify deployment process..."
    
    # Criar backup
    create_backup
    
    # Validar configuração
    validate_config
    
    # Fazer deploy
    deploy
    
    # Verificar health
    if check_health; then
        success "🎉 Deployment completed successfully!"
        log "🌐 Application available at: $HEALTH_ENDPOINT"
        
        # Mostrar status final
        log "📊 Final status:"
        docker-compose -f "$COMPOSE_FILE" ps
        
    else
        error "❌ Deployment failed health check"
        show_logs
        
        # Perguntar sobre rollback
        read -p "Do you want to rollback? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rollback
        fi
        exit 1
    fi
}

# Verificar se docker e docker-compose estão disponíveis
if ! command -v docker &> /dev/null; then
    error "❌ Docker not found. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    error "❌ Docker Compose not found. Please install Docker Compose first."
    exit 1
fi

# Executar função principal
main "$@"