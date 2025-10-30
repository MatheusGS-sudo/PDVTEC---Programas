#!/bin/bash

# --- CONFIGURAÇÃO ---
read -p "Digite o usuário SSH : " USUARIO_SSH
read -s -p "Digite a senha SSH (e sudo) para $USUARIO_SSH: " SENHA_SSH
echo ""

export SSHPASS="$SENHA_SSH"
ARQUIVO_IPS="ips.txt"
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"

# --- DEFINIÇÃO DAS ROTINAS ---
# (Suas rotinas rotina_clisitef, atualizar_linha_cfg, rotina_ecf9a,
# rotina_restg, rotina_zmws1600... estão aqui, sem alterações)

# ROTINA 1: Editar CliSiTef.ini
rotina_clisitef() {
    echo "[Rotina 1] Verificando CliSiTef.ini..."
    local ARQUIVO="/Zanthus/Zeus/pdvJava/CliSiTef.ini"
    local CHAVE_COMPLETA="IdentificaMensagens=1"
    local CHAVE_BUSCA="IdentificaMensagens=" # Apenas a chave, sem o valor
    local SECAO_REGEX="^\[Geral\]"      # Regex para encontrar a sessão

    if [ ! -f "$ARQUIVO" ]; then
        echo "  AVISO: Arquivo $ARQUIVO não encontrado."
        return
    fi

    echo "  AÇÃO: Corrigindo quebras de linha do Windows (CRLF)..."
    sed -i.bak 's/\r$//' "$ARQUIVO"

    # 1. Verifica se a CHAVE (IdentificaMensagens=) JÁ EXISTE no arquivo
    if grep -q "^${CHAVE_BUSCA}" "$ARQUIVO"; then
        # A CHAVE existe. Vamos garantir que o VALOR está correto.
        echo "  AÇÃO: Chave '$CHAVE_BUSCA' encontrada. Atualizando linha..."
        sed -i "s|^${CHAVE_BUSCA}.*$|${CHAVE_COMPLETA}|" "$ARQUIVO"
        echo "  Concluído."
    else
        # A CHAVE não existe. Vamos adicioná-la DEPOIS da linha [Geral]
        echo "  AÇÃO: Chave '$CHAVE_BUSCA' não encontrada. Adicionando..."

        sed -i "/$SECAO_REGEX/s/.*/&\n$CHAVE_COMPLETA/" "$ARQUIVO"

        # Verificação final
        if grep -q "^${CHAVE_BUSCA}" "$ARQUIVO"; then
            echo "  Concluído: Chave adicionada com sucesso."
        else
            echo "  ERRO: Falha ao adicionar a chave com o 'sed'. A seção [Geral] foi encontrada?"
        fi
    fi
}
# FUNÇÃO AJUDANTE para a Rotina 2 (ECF9A.CFG)
atualizar_linha_cfg() {
    local ARQUIVO="$1"
    local CHAVE_BUSCA="$2" # Ex: "tecla:121"
    local LINHA_COMPLETA="$3" # Ex: "tecla:121=30 # Tecla y..."

    # Verifica se a chave (ex: "tecla:121=") existe no arquivo
    if grep -q "^${CHAVE_BUSCA}=" "$ARQUIVO"; then
        # Existe. Vamos substituir a linha inteira
        sed -i "s|^${CHAVE_BUSCA}=.*$|${LINHA_COMPLETA}|" "$ARQUIVO"
        echo "  OK: Linha para '${CHAVE_BUSCA}' atualizada."
    else
        # Não existe. Vamos adicionar no final do arquivo.
        echo "$LINHA_COMPLETA" >> "$ARQUIVO"
        echo "  OK: Linha para '${CHAVE_BUSCA}' adicionada."
    fi
}

# ROTINA 2: Editar ECF9A.CFG
rotina_ecf9a() {
    echo "[Rotina 2] Verificando ECF9A.CFG..."
    local ARQUIVO="/Zanthus/Zeus/pdvJava/ECF9A.CFG"

    if [ ! -f "$ARQUIVO" ]; then
        echo "  AVISO: Arquivo $ARQUIVO não encontrado. Criando..."
        touch "$ARQUIVO" # Cria o arquivo se não existir
    fi

    # Chama a função ajudante para cada linha
    atualizar_linha_cfg "$ARQUIVO" "tecla:121" "tecla:121=30  # Tecla y     VENDEDOR"
    atualizar_linha_cfg "$ARQUIVO" "tecla:89"  "tecla:89=30   # Tecla y     VENDEDOR"
    atualizar_linha_cfg "$ARQUIVO" "tecla:231" "tecla:231=64  # Tecla ç     CONSULTA MERCADORIA POR DESCRICAO"
    atualizar_linha_cfg "$ARQUIVO" "tecla:199" "tecla:199=64  # Tecla Ç     CONSULTA MERCADORIA POR DESCRICAO"
}

# ROTINA 3: Criar arquivos RESTG026[1,2,3].CFG
rotina_restg() {
    echo "[Rotina 3] Criando e modificando arquivos RESTG..."
    local DIR_PDV="/Zanthus/Zeus/pdvJava"
    local ARQUIVO1="$DIR_PDV/RESTG0261.CFG"
    local ARQUIVO2="$DIR_PDV/RESTG0262.CFG"
    local ARQUIVO3="$DIR_PDV/RESTG0263.CFG"
    local ARQUIVO4="$DIR_PDV/RESTG0000.CFG"

    # --- Parte 1: Criar os 3 arquivos ---
    echo "  AÇÃO: Criando $ARQUIVO1..."
    cat > "$ARQUIVO1" << 'EOF'
endereco=geocosmeticos.zanthusonline.com.br
path=/manager/restfull/pdv/comunicacao_pdv.php5
timeout=30
opcoes=63
SSL=1
FLAGS=1
EOF

    echo "  AÇÃO: Copiando para $ARQUIVO2 e $ARQUIVO3..."
    cp "$ARQUIVO1" "$ARQUIVO2"
    cp "$ARQUIVO1" "$ARQUIVO3"

    echo "  AÇÃO: Dando permissão de execução..."
    chmod +x "$ARQUIVO1"
    chmod +x "$ARQUIVO2"
    chmod +x "$ARQUIVO3"

    echo "  OK: Arquivos RESTG0261, 262, e 263 criados/atualizados."

    # --- Parte 2: Modificar o RESTG0000.CFG (Adicionado) ---
    echo "  AÇÃO: Verificando $ARQUIVO4 para alterar o timeout..."
    if [ ! -f "$ARQUIVO4" ]; then
        echo "  AVISO: Arquivo $ARQUIVO4 não encontrado. Pulando modificação do timeout."
    else
        sed -i.bak 's/^\s*timeout\s*=\s*30\s*$/timeout=5/' "$ARQUIVO4"
        echo "  OK: $ARQUIVO4 atualizado (timeout alterado de 30 para 5)."
    fi
}

# ROTINA 4: Editar ZMWS1600.cfg
rotina_zmws1600() {
    echo "[Rotina 4] Criando/Atualizando ZMWS1600.CFG..."
    local ARQUIVO="/Zanthus/Zeus/pdvJava/ZMWS1600.CFG"

    # 'cat' vai sobrescrever o arquivo se ele existir, ou criar um novo.
    cat > "$ARQUIVO" << 'EOF'
endereco=127.0.0.1:9090
path_forcado=/moduloPHPPDV/index.php
path=/moduloPHPPDV/index.php
timeout=30
opcoes=3
SSL=0
FLAGS=0
EOF

    echo "  OK: Arquivo ZMWS1600.CFG criado/atualizado."
}


# --- PONTO DE ENTRADA REMOTO ---
executar_rotinas_remotas() {
    echo "Conectado, iniciando execução de rotinas..."

    rotina_clisitef
    rotina_ecf9a
    rotina_restg
    rotina_zmws1600

    echo "Execução remota concluída."
}


if ! command -v sshpass &> /dev/null; then
    echo "ERRO: O utilitário 'sshpass' não está instalado."
    unset SSHPASS
    exit 1
fi

if [ ! -f "$ARQUIVO_IPS" ]; then
    echo "ERRO: Arquivo de IPs '$ARQUIVO_IPS' não encontrado."
    unset SSHPASS
    exit 1
fi

total_pdvs=0
sucesso_pdvs=0
falha_pdvs=0
ips_falha=() # Array Bash para guardar IPs com falha

echo "Iniciando atualização em massa..."

# 3. Lê o arquivo de IPs linha por linha
while IFS= read -r ip || [[ -n "$ip" ]]; do
    # Pula linhas vazias ou comentários
    [[ -z "$ip" ]] && continue
    [[ "$ip" =~ ^# ]] && continue

    ((total_pdvs++)) # Incrementa o contador total de PDVs

    echo ""
    echo "=================================================="
    echo ">>> Processando máquina: $ip ($total_pdvs)"
    echo "=================================================="

    SCRIPT_BLOCO="$(typeset -f); executar_rotinas_remotas"

    { echo "$SSHPASS"; echo "$SCRIPT_BLOCO"; } | sshpass -e ssh $SSH_OPTS "${USUARIO_SSH}@${ip}" "sudo -S bash"

    STATUS_SAIDA=$?

    if [ $STATUS_SAIDA -eq 0 ]; then
        echo ">>> SUCESSO: Máquina $ip atualizada."
        ((sucesso_pdvs++)) # --- (NOVO) Incrementa sucesso
    elif [ $STATUS_SAIDA -eq 1 ]; then
        echo ">>> ERRO: Falha ao processar $ip. Verifique a senha do SUDO ou permissões."
        ((falha_pdvs++)) # --- (NOVO) Incrementa falha
        ips_falha+=("$ip") # --- (NOVO) Adiciona IP ao array de falhas
    else
        echo ">>> ERRO: Falha ao processar a máquina $ip (Código de saída: $STATUS_SAIDA)."
        ((falha_pdvs++))
        ips_falha+=("$ip")
    fi

done < "$ARQUIVO_IPS"

# Limpa a senha da variável de ambiente por segurança
unset SSHPASS


echo ""
echo "=================================================="
echo "               RESUMO DA ATUALIZAÇÃO              "
echo "=================================================="
echo "Total de PDVs processados:   $total_pdvs"
echo "PDVs atualizados com sucesso: $sucesso_pdvs"
echo "PDVs com falha:              $falha_pdvs"

if [ $falha_pdvs -gt 0 ]; then
    echo ""
    echo "IPs que falharam:"
    # Loop para imprimir cada IP do array de falhas
    for ip_falhado in "${ips_falha[@]}"; do
        echo "  - $ip_falhado"
    done
fi

echo ""
echo "=================================================="
echo "Script concluído."
echo "=================================================="