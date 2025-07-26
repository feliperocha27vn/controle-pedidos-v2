#!/bin/bash
# =============================================================================
# PLANO DE MIGRAÇÃO SEGURA - API UM DOCE
# Script para aplicar otimizações sem perda de dados
# =============================================================================

set -e

LOG_PREFIX="[MIGRATION]"
BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
COMPOSE_FILE="docker-compose.yaml"

# Função de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_PREFIX $1"
}

# Função para criar backup
create_backup() {
    log "📦 Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    # Backup do docker-compose atual
    if [ -f "$COMPOSE_FILE" ]; then
        cp "$COMPOSE_FILE" "$BACKUP_DIR/docker-compose.yaml.backup"
        log "✅ Docker Compose backed up"
    fi
    
    # Backup do Dockerfile atual
    if [ -f "Dockerfile" ]; then
        cp "Dockerfile" "$BACKUP_DIR/Dockerfile.backup"
        log "✅ Dockerfile backed up"
    fi
    
    # Backup do start.sh atual
    if [ -f "start.sh" ]; then
        cp "start.sh" "$BACKUP_DIR/start.sh.backup"
        log "✅ Start script backed up"
    fi
    
    # Backup do .dockerignore atual
    if [ -f ".dockerignore" ]; then
        cp ".dockerignore" "$BACKUP_DIR/.dockerignore.backup"
        log "✅ .dockerignore backed up"
    fi
    
    log "📦 All files backed up to: $BACKUP_DIR"
}

# Função para backup do banco de dados
backup_database() {
    log "🗄️  Creating database backup..."
    
    # Verificar se o container do PostgreSQL está rodando
    if docker ps | grep -q postgres_container; then
        docker exec postgres_container pg_dump -U admin -d controle_pedidos > "$BACKUP_DIR/database_backup.sql"
        log "✅ Database backup created: $BACKUP_DIR/database_backup.sql"
    else
        log "⚠️  PostgreSQL container not running, skipping database backup"
    fi
}

# Função para verificar pré-requisitos
check_prerequisites() {
    log "🔍 Checking prerequisites..."
    
    # Verificar se Docker está rodando
    if ! docker info > /dev/null 2>&1; then
        log "❌ Docker is not running"
        exit 1
    fi
    
    # Verificar se docker-compose está disponível
    if ! command -v docker-compose > /dev/null 2>&1; then
        log "❌ docker-compose is not installed"
        exit 1
    fi
    
    # Verificar espaço em disco (mínimo 2GB)
    available_space=$(df . | tail -1 | awk '{print $4}')
    if [ "$available_space" -lt 2097152 ]; then  # 2GB em KB
        log "⚠️  Warning: Less than 2GB available disk space"
    fi
    
    log "✅ Prerequisites check passed"
}

# Função para aplicar otimizações
apply_optimizations() {
    log "🚀 Applying optimizations..."
    
    # Parar serviços atuais
    log "🛑 Stopping current services..."
    docker-compose down
    
    # Substituir arquivos pelos otimizados
    log "📝 Updating configuration files..."
    
    if [ -f "docker-compose.optimized.yaml" ]; then
        cp "docker-compose.optimized.yaml" "$COMPOSE_FILE"
        log "✅ Docker Compose updated"
    fi
    
    if [ -f "Dockerfile.optimized" ]; then
        cp "Dockerfile.optimized" "Dockerfile"
        log "✅ Dockerfile updated"
    fi
    
    if [ -f "start.optimized.sh" ]; then
        cp "start.optimized.sh" "start.sh"
        chmod +x "start.sh"
        log "✅ Start script updated"
    fi
    
    if [ -f ".dockerignore.optimized" ]; then
        cp ".dockerignore.optimized" ".dockerignore"
        log "✅ .dockerignore updated"
    fi
}

# Função para rebuild e restart
rebuild_and_start() {
    log "🔨 Rebuilding and starting services..."
    
    # Rebuild da imagem
    docker-compose build --no-cache api-um-doce
    
    # Iniciar serviços
    docker-compose up -d
    
    # Aguardar serviços ficarem healthy
    log "⏳ Waiting for services to become healthy..."
    sleep 30
    
    # Verificar status dos serviços
    if docker-compose ps | grep -q "Up (healthy)"; then
        log "✅ Services are running and healthy"
    else
        log "⚠️  Some services may not be healthy yet, check with: docker-compose ps"
    fi
}

# Função para validar migração
validate_migration() {
    log "🔍 Validating migration..."
    
    # Verificar se API está respondendo
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f http://localhost:3333/health > /dev/null 2>&1; then
            log "✅ API health check passed"
            break
        fi
        
        log "⏳ Attempt $attempt/$max_attempts - API not ready yet..."
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log "❌ API health check failed after $max_attempts attempts"
        return 1
    fi
    
    # Verificar logs por erros
    log "📋 Checking application logs..."
    docker-compose logs --tail=50 api-um-doce | grep -i error || log "✅ No errors found in logs"
    
    return 0
}

# Função para rollback
rollback() {
    log "🔄 Performing rollback..."
    
    # Parar serviços
    docker-compose down
    
    # Restaurar arquivos do backup
    if [ -f "$BACKUP_DIR/docker-compose.yaml.backup" ]; then
        cp "$BACKUP_DIR/docker-compose.yaml.backup" "$COMPOSE_FILE"
        log "✅ Docker Compose restored"
    fi
    
    if [ -f "$BACKUP_DIR/Dockerfile.backup" ]; then
        cp "$BACKUP_DIR/Dockerfile.backup" "Dockerfile"
        log "✅ Dockerfile restored"
    fi
    
    if [ -f "$BACKUP_DIR/start.sh.backup" ]; then
        cp "$BACKUP_DIR/start.sh.backup" "start.sh"
        chmod +x "start.sh"
        log "✅ Start script restored"
    fi
    
    if [ -f "$BACKUP_DIR/.dockerignore.backup" ]; then
        cp "$BACKUP_DIR/.dockerignore.backup" ".dockerignore"
        log "✅ .dockerignore restored"
    fi
    
    # Rebuild e restart com configuração antiga
    docker-compose build --no-cache api-um-doce
    docker-compose up -d
    
    log "✅ Rollback completed"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "🚀 Starting migration process..."
    
    # Verificar pré-requisitos
    check_prerequisites
    
    # Criar backups
    create_backup
    backup_database
    
    # Aplicar otimizações
    apply_optimizations
    
    # Rebuild e iniciar
    rebuild_and_start
    
    # Validar migração
    if validate_migration; then
        log "🎉 Migration completed successfully!"
        log "📁 Backups available at: $BACKUP_DIR"
        log "🔍 Monitor with: docker-compose logs -f"
    else
        log "❌ Migration validation failed, initiating rollback..."
        rollback
        exit 1
    fi
}

# Verificar se deve fazer rollback
if [ "$1" = "rollback" ]; then
    if [ -z "$2" ]; then
        log "❌ Please specify backup directory for rollback"
        log "Usage: $0 rollback /path/to/backup/directory"
        exit 1
    fi
    BACKUP_DIR="$2"
    rollback
    exit 0
fi

# Executar migração principal
main

log "✅ Migration process completed!"
log "📋 Next steps:"
log "   1. Monitor logs: docker-compose logs -f"
log "   2. Check health: curl http://localhost:3333/health"
log "   3. Verify database: docker exec postgres_container psql -U admin -d controle_pedidos -c '\\dt'"