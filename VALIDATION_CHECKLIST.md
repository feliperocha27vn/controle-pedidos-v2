# =============================================================================
# CHECKLIST DE VALIDAÇÃO - API UM DOCE
# Comandos para testar e validar as configurações otimizadas
# =============================================================================

## 🔍 PRÉ-MIGRAÇÃO - Verificações Obrigatórias

### 1. Backup de Dados
```bash
# Criar backup do banco de dados
docker exec postgres_container pg_dump -U admin -d controle_pedidos > backup_$(date +%Y%m%d_%H%M%S).sql

# Verificar tamanho do backup
ls -lh backup_*.sql

# Backup dos volumes Docker
docker run --rm -v controle_pedidos_db:/data -v $(pwd):/backup alpine tar czf /backup/db_backup_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

### 2. Verificar Estado Atual
```bash
# Status dos containers
docker-compose ps

# Uso de recursos atual
docker stats --no-stream

# Logs atuais
docker-compose logs --tail=50

# Verificar volumes existentes
docker volume ls | grep controle_pedidos
```

## 🚀 MIGRAÇÃO - Aplicar Otimizações

### 1. Executar Migração Segura
```bash
# Executar script de migração
./migrate.sh

# OU manualmente:
# 1. Parar serviços
docker-compose down

# 2. Fazer backup
mkdir -p backups/$(date +%Y%m%d_%H%M%S)
cp docker-compose.yaml backups/$(date +%Y%m%d_%H%M%S)/
cp Dockerfile backups/$(date +%Y%m%d_%H%M%S)/

# 3. Aplicar otimizações
cp docker-compose.optimized.yaml docker-compose.yaml
cp Dockerfile.optimized Dockerfile
cp start.optimized.sh start.sh
cp .dockerignore.optimized .dockerignore

# 4. Rebuild e iniciar
docker-compose build --no-cache
docker-compose up -d
```

## ✅ PÓS-MIGRAÇÃO - Validações Obrigatórias

### 1. Verificar Containers
```bash
# Status dos containers
docker-compose ps

# Verificar se estão healthy
docker-compose ps | grep "Up (healthy)"

# Logs em tempo real
docker-compose logs -f
```

### 2. Verificar API
```bash
# Health check da API
curl -f http://localhost:3333/health

# Verificar resposta detalhada
curl -v http://localhost:3333/health

# Teste com timeout
timeout 10 curl http://localhost:3333/health
```

### 3. Verificar Banco de Dados
```bash
# Conectar ao banco
docker exec -it postgres_container psql -U admin -d controle_pedidos

# Verificar tabelas (dentro do psql)
\dt

# Verificar dados (exemplo)
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM recipes;
SELECT COUNT(*) FROM orders;

# Sair do psql
\q
```

### 4. Verificar Performance
```bash
# Uso de recursos
docker stats --no-stream

# Verificar limites aplicados
docker inspect postgres_container | grep -A 10 "Resources"
docker inspect api_um_doce_container | grep -A 10 "Resources"

# Verificar logs estruturados
docker-compose logs --tail=20 | grep -E "(ERROR|WARN|INFO)"
```

### 5. Verificar Rede e Volumes
```bash
# Verificar rede
docker network ls | grep controle_pedidos
docker network inspect controle_pedidos_network

# Verificar volumes (CRÍTICO - devem estar preservados)
docker volume ls | grep db
docker volume inspect controle_pedidos_db
```

## 🔧 TESTES FUNCIONAIS

### 1. Teste de Conectividade
```bash
# Teste de conectividade entre containers
docker exec api_um_doce_container ping -c 3 postgresql

# Teste de conexão com banco
docker exec api_um_doce_container npx prisma db push --accept-data-loss
```

### 2. Teste de Restart
```bash
# Restart dos serviços
docker-compose restart

# Aguardar e verificar
sleep 30
docker-compose ps
curl http://localhost:3333/health
```

### 3. Teste de Graceful Shutdown
```bash
# Enviar SIGTERM para o container da API
docker kill --signal=TERM api_um_doce_container

# Verificar logs de shutdown
docker-compose logs api-um-doce | tail -20

# Reiniciar
docker-compose up -d api-um-doce
```

## 🚨 TROUBLESHOOTING

### 1. Se API não responder
```bash
# Verificar logs detalhados
docker-compose logs api-um-doce

# Verificar processo dentro do container
docker exec api_um_doce_container ps aux

# Verificar portas
docker exec api_um_doce_container netstat -tlnp
```

### 2. Se banco não conectar
```bash
# Verificar logs do PostgreSQL
docker-compose logs postgresql

# Verificar conectividade
docker exec api_um_doce_container nc -zv postgresql 5432

# Verificar variáveis de ambiente
docker exec api_um_doce_container env | grep DB_
```

### 3. Se houver problemas de memória
```bash
# Verificar uso de memória
docker stats --no-stream

# Verificar limites
docker inspect api_um_doce_container | grep -A 5 Memory

# Ajustar se necessário no docker-compose.yaml
```

## 🔄 ROLLBACK (Se necessário)

### 1. Rollback Rápido
```bash
# Usar script de rollback
./migrate.sh rollback /path/to/backup/directory

# OU manualmente:
docker-compose down
cp backups/YYYYMMDD_HHMMSS/docker-compose.yaml ./
cp backups/YYYYMMDD_HHMMSS/Dockerfile ./
docker-compose build --no-cache
docker-compose up -d
```

### 2. Restaurar Banco (Se necessário)
```bash
# Restaurar do backup SQL
docker exec -i postgres_container psql -U admin -d controle_pedidos < backup_YYYYMMDD_HHMMSS.sql

# OU restaurar volume
docker-compose down
docker volume rm controle_pedidos_db
docker run --rm -v controle_pedidos_db:/data -v $(pwd):/backup alpine tar xzf /backup/db_backup_YYYYMMDD_HHMMSS.tar.gz -C /data
docker-compose up -d
```

## ✅ CHECKLIST FINAL

- [ ] **Containers rodando**: `docker-compose ps` mostra todos "Up (healthy)"
- [ ] **API respondendo**: `curl http://localhost:3333/health` retorna 200
- [ ] **Banco conectado**: Consegue executar queries
- [ ] **Dados preservados**: Tabelas e dados existem
- [ ] **Logs estruturados**: Logs aparecem formatados
- [ ] **Resource limits**: Containers respeitam limites de CPU/memória
- [ ] **Health checks**: Funcionando nos intervalos corretos
- [ ] **Graceful shutdown**: Containers param corretamente
- [ ] **Performance**: Aplicação responde em tempo adequado
- [ ] **Monitoramento**: Logs e métricas disponíveis

## 📊 MONITORAMENTO CONTÍNUO

### Comandos para monitoramento diário:
```bash
# Status geral
docker-compose ps && docker stats --no-stream

# Health checks
curl -s http://localhost:3333/health | jq .

# Logs recentes
docker-compose logs --tail=50 --since=1h

# Uso de disco
df -h && docker system df
```