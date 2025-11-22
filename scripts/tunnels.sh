#!/bin/bash
# Script pour gérer les tunnels SSH vers les services Data Platform

set -e

SSH_KEY="$HOME/.ssh/id_ed25519"
SERVER="root@135.181.211.227"
PID_FILE="/tmp/data-platform-tunnels.pid"

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function start_tunnels() {
    local FOREGROUND=$1
    echo -e "${BLUE}🚀 Démarrage des tunnels SSH...${NC}"
    echo ""
    
    # Vérifier si tunnels déjà actifs (seulement si pas en mode foreground)
    if [ -z "$FOREGROUND" ] && [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  Tunnels déjà actifs (PID: $PID)${NC}"
            echo "Utilisez './tunnels.sh stop' puis './tunnels.sh start' pour redémarrer"
            exit 1
        fi
    fi
    
    SSH_OPTS="-o ServerAliveInterval=60 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o ExitOnForwardFailure=yes"
    
    if [ -n "$FOREGROUND" ]; then
        # Mode foreground pour launchd
        echo "Mode foreground activé..."
        ssh -N $SSH_OPTS \
            -L 8080:10.10.0.101:30098 \
            -L 9001:10.10.0.101:30901 \
            -L 9000:10.10.0.101:30900 \
            -L 8200:10.10.0.101:30820 \
            -L 5050:10.10.0.101:30500 \
            -L 5051:10.10.0.101:30501 \
            -L 8081:10.10.0.101:31285 \
            -i "$SSH_KEY" \
            "$SERVER"
    else
        # Mode background (défaut)
        # Créer le tunnel multi-ports
        ssh -N -f $SSH_OPTS \
            -L 8080:10.10.0.101:30098 \
            -L 9001:10.10.0.101:30901 \
            -L 9000:10.10.0.101:30900 \
            -L 8200:10.10.0.101:30820 \
            -L 5050:10.10.0.101:30500 \
            -L 5051:10.10.0.101:30501 \
            -L 8081:10.10.0.101:31285 \
            -L 8082:10.10.0.101:30080 \
            -i "$SSH_KEY" \
            "$SERVER"
        
        # Sauvegarder le PID
        TUNNEL_PID=$(pgrep -f "ssh.*-L 8080:10.10.0.101:30098")
        echo $TUNNEL_PID > "$PID_FILE"
        
        sleep 2
        
        echo -e "${GREEN}✅ Tunnels créés avec succès !${NC}"
        echo ""
        show_status
    fi
}

function stop_tunnels() {
    echo -e "${BLUE}🛑 Arrêt des tunnels SSH...${NC}"
    echo ""
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            kill $PID
            rm "$PID_FILE"
            echo -e "${GREEN}✅ Tunnels arrêtés${NC}"
        else
            echo -e "${YELLOW}⚠️  Aucun tunnel actif${NC}"
            rm "$PID_FILE"
        fi
    else
        # Essayer de killer tous les tunnels
        pkill -f "ssh.*-L.*10.10.0.101" 2>/dev/null && echo -e "${GREEN}✅ Tunnels arrêtés${NC}" || echo -e "${YELLOW}⚠️  Aucun tunnel actif${NC}"
    fi
}

function show_status() {
    echo -e "${BLUE}📊 Status des tunnels:${NC}"
    echo ""
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Tunnels actifs (PID: $PID)${NC}"
        else
            echo -e "${RED}❌ Tunnels inactifs${NC}"
            rm "$PID_FILE"
            return
        fi
    else
        # Check if running via launchd (might not have PID file but process exists)
        if pgrep -f "ssh.*-L 8080:10.10.0.101:30098" > /dev/null; then
             echo -e "${GREEN}✅ Tunnels actifs (via LaunchAgent/Foreground)${NC}"
        else
             echo -e "${RED}❌ Tunnels inactifs${NC}"
             return
        fi
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}🌐 Services disponibles:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo -e "${GREEN}1. Headlamp (Kubernetes UI)${NC}"
    echo "   🔗 http://localhost:8080"
    echo "   🔑 Token dans: headlamp-token.txt"
    echo ""
    echo -e "${GREEN}2. MinIO Console (S3 Storage)${NC}"
    echo "   🔗 http://localhost:9001"
    echo "   👤 User: minioadmin"
    echo "   🔒 Pass: minioadmin123"
    echo ""
    echo -e "${GREEN}3. MinIO API${NC}"
    echo "   🔗 http://localhost:9000"
    echo "   📦 Endpoint pour Spark/apps"
    echo ""
    echo -e "${GREEN}4. Vault UI (Secrets Management)${NC}"
    echo "   🔗 http://localhost:8200"
    echo "   🔑 Token: root"
    echo ""
    echo -e "${GREEN}5. Docker Registry${NC}"
    echo "   🔗 http://localhost:5050 (API)"
    echo "   📦 Push: docker push localhost:5050/image:tag"
    echo ""
    echo -e "${GREEN}6. Docker Registry UI${NC}"
    echo "   🔗 http://localhost:5051"
    echo "   📦 Interface web pour gérer les images"
    echo ""
    echo -e "${GREEN}7. Trino UI (SQL Query Engine)${NC}"
    echo "   🔗 http://localhost:8081"
    echo "   👤 User: admin"
    echo ""
    echo -e "${GREEN}8. ArgoCD (GitOps)${NC}"
    echo "   🔗 http://localhost:8082"
    echo "   👤 User: admin"
    echo "   🔑 Pass: (voir commande: kubectl -n argocd get secret argocd-initial-admin-secret ...)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

function open_services() {
    echo -e "${BLUE}🌐 Ouverture des services dans le navigateur...${NC}"
    echo ""
    
    open "http://localhost:8080" 2>/dev/null || echo "Headlamp: http://localhost:8080"
    sleep 1
    open "http://localhost:9001" 2>/dev/null || echo "MinIO: http://localhost:9001"
    sleep 1
    open "http://localhost:8200" 2>/dev/null || echo "Vault: http://localhost:8200"
    sleep 1
    open "http://localhost:8081" 2>/dev/null || echo "Trino: http://localhost:8081"
    sleep 1
    open "http://localhost:8082" 2>/dev/null || echo "ArgoCD: http://localhost:8082"
    
    echo ""
    echo -e "${GREEN}✅ Services ouverts dans le navigateur${NC}"
}

function show_help() {
    echo "Usage: ./tunnels.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start [--foreground]  Démarrer les tunnels SSH (option --foreground pour launchd)"
    echo "  stop                  Arrêter les tunnels SSH"
    echo "  restart               Redémarrer les tunnels SSH"
    echo "  status                Afficher le status des tunnels"
    echo "  open                  Ouvrir les services dans le navigateur"
    echo "  help                  Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  ./tunnels.sh start"
    echo "  ./tunnels.sh status"
    echo "  ./tunnels.sh open"
}

# Main
case "${1:-help}" in
    start)
        if [ "$2" == "--foreground" ]; then
            start_tunnels "true"
        else
            start_tunnels
        fi
        ;;
    stop)
        stop_tunnels
        ;;
    restart)
        stop_tunnels
        sleep 1
        start_tunnels
        ;;
    status)
        show_status
        ;;
    open)
        open_services
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ Commande inconnue: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac

