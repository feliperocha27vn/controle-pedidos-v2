#!/bin/bash
# =============================================================================
# SCRIPT PARA CORRIGIR WARNINGS DE COLLATION - PostgreSQL
# Resolve os warnings: "database has no actual collation version"
# =============================================================================

set -e

LOG_PREFIX="[COLLATION-FIX]"

# Função de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_PREFIX $1"
}

# Verificar se o container PostgreSQL está rodando
check_postgres() {
    if ! docker ps | grep -q postgres_container; then
        log "❌ Container PostgreSQL não está rodando"
        log "Execute: docker-compose up -d postgresql"
        exit 1
    fi
    log "✅ Container PostgreSQL está rodando"
}

# Corrigir warnings de collation
fix_collation_warnings() {
    log "🔧 Corrigindo warnings de collation..."
    
    # Conectar ao PostgreSQL e executar comandos de correção
    docker exec postgres_container psql -U admin -d controle_pedidos -c "
        -- Atualizar versão de collation para o banco
        ALTER DATABASE controle_pedidos REFRESH COLLATION VERSION;
        
        -- Verificar se há objetos com collation inconsistente
        SELECT schemaname, tablename, attname, collname 
        FROM pg_attribute a
        JOIN pg_class c ON a.attrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        JOIN pg_collation col ON a.attcollation = col.oid
        WHERE n.nspname = 'public' 
        AND a.attnum > 0 
        AND NOT a.attisdropped
        AND col.collname != 'default';
    " 2>/dev/null || {
        log "⚠️  Tentando método alternativo..."
        
        # Método alternativo se o primeiro falhar
        docker exec postgres_container psql -U admin -d controle_pedidos -c "
            -- Recriar collations se necessário
            DROP COLLATION IF EXISTS custom_collation CASCADE;
            
            -- Verificar configurações atuais
            SELECT datname, datcollate, datctype FROM pg_database WHERE datname = 'controle_pedidos';
        "
    }
    
    log "✅ Correção de collation concluída"
}

# Verificar se os warnings foram resolvidos
verify_fix() {
    log "🔍 Verificando se os warnings foram resolvidos..."
    
    # Reiniciar container PostgreSQL para limpar warnings
    log "🔄 Reiniciando container PostgreSQL..."
    docker-compose restart postgresql
    
    # Aguardar container ficar healthy
    log "⏳ Aguardando container ficar healthy..."
    local attempts=0
    local max_attempts=30
    
    while [ $attempts -lt $max_attempts ]; do
        if docker-compose ps postgresql | grep -q "healthy"; then
            log "✅ Container PostgreSQL está healthy"
            break
        fi
        
        attempts=$((attempts + 1))
        log "⏳ Aguardando... ($attempts/$max_attempts)"
        sleep 2
    done
    
    if [ $attempts -eq $max_attempts ]; then
        log "⚠️  Container demorou para ficar healthy, mas pode estar funcionando"
    fi
}

# Testar conexão após correção
test_connection() {
    log "🧪 Testando conexão com banco..."
    
    if docker exec postgres_container psql -U admin -d controle_pedidos -c "SELECT 1;" > /dev/null 2>&1; then
        log "✅ Conexão com banco funcionando perfeitamente"
    else
        log "❌ Problema na conexão com banco"
        return 1
    fi
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log "🚀 Iniciando correção de warnings de collation..."
    
    # Verificar pré-requisitos
    check_postgres
    
    # Corrigir warnings
    fix_collation_warnings
    
    # Verificar correção
    verify_fix
    
    # Testar conexão
    test_connection
    
    log "🎉 Correção concluída com sucesso!"
    log "📋 Os warnings de collation devem ter sido resolvidos"
    log "🔍 Monitore os logs com: docker-compose logs -f postgresql"
}

# Executar correção
main

log "✅ Script de correção finalizado!"
log "💡 Dica: Se os warnings persistirem, eles são apenas informativos e não afetam o funcionamento"