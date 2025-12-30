#!/bin/bash

# Git 凭证切换脚本
# 用于管理和切换 Git 用户凭证

# 配置文件路径（当前目录）
CONFIG_FILE=".git-credentials"

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 初始化配置文件
init_config() {
    # 如果配置文件不存在，创建空文件
    if [ ! -f "$CONFIG_FILE" ]; then
        touch "$CONFIG_FILE" 2>/dev/null
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}错误: 无法创建配置文件 $CONFIG_FILE${NC}" >&2
            return 1
        fi
    fi
}

# 加载凭证列表
load_credentials() {
    if [ ! -f "$CONFIG_FILE" ]; then
        return 1
    fi
    cat "$CONFIG_FILE"
}

# 列出所有凭证
list_credentials() {
    echo -e "${BLUE}=== 已保存的凭证列表 ===${NC}\n"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}暂无凭证，使用 'add' 命令添加凭证${NC}"
        return
    fi
    
    local index=1
    while IFS='|' read -r name email; do
        if [ -n "$name" ] && [ -n "$email" ]; then
            # 检查是否是当前使用的凭证
            CURRENT_EMAIL=$(git config user.email 2>/dev/null)
            if [ "$email" == "$CURRENT_EMAIL" ]; then
                echo -e "${GREEN}[$index] $name <$email> ${CYAN}← 当前使用${NC}"
            else
                echo -e "[$index] $name <$email>"
            fi
            ((index++))
        fi
    done < "$CONFIG_FILE"
    
    if [ $index -eq 1 ]; then
        echo -e "${YELLOW}暂无凭证，使用 'add' 命令添加凭证${NC}"
    fi
}

# 添加凭证
add_credential() {
    local name=$1
    local email=$2
    
    if [ -z "$name" ] || [ -z "$email" ]; then
        echo -e "${RED}错误: 请提供用户名和邮箱${NC}"
        echo -e "${YELLOW}用法: $0 add \"用户名\" \"邮箱\"${NC}"
        echo -e "${YELLOW}示例: $0 add \"John Doe\" \"john@example.com\"${NC}"
        return 1
    fi
    
    # 确保配置文件存在
    if [ ! -f "$CONFIG_FILE" ]; then
        if ! init_config; then
            return 1
        fi
    fi
    
    # 检查邮箱是否已存在
    if grep -q "|$email$" "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${YELLOW}警告: 邮箱 '$email' 已存在${NC}"
        return 1
    fi
    
    # 添加凭证
    if echo "$name|$email" >> "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${GREEN}✓ 已添加凭证: $name <$email>${NC}"
    else
        echo -e "${RED}错误: 无法写入配置文件${NC}"
        return 1
    fi
}

# 删除凭证
remove_credential() {
    local identifier=$1
    
    if [ -z "$identifier" ]; then
        echo -e "${RED}错误: 请指定要删除的凭证编号或邮箱${NC}"
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}错误: 配置文件不存在，没有可删除的凭证${NC}"
        return 1
    fi
    
    # 创建临时文件
    local temp_file=$(mktemp)
    local index=1
    local found=0
    
    while IFS='|' read -r name email; do
        if [ -n "$name" ] && [ -n "$email" ]; then
            # 检查是否匹配（编号或邮箱）
            if [ "$index" == "$identifier" ] || [ "$email" == "$identifier" ]; then
                echo -e "${GREEN}✓ 已删除凭证: $name <$email>${NC}"
                found=1
            else
                echo "$name|$email" >> "$temp_file"
            fi
            ((index++))
        fi
    done < "$CONFIG_FILE"
    
    if [ $found -eq 0 ]; then
        echo -e "${RED}错误: 未找到凭证 '$identifier'${NC}"
        rm -f "$temp_file"
        return 1
    fi
    
    mv "$temp_file" "$CONFIG_FILE"
}

# 获取凭证信息
get_credential() {
    local identifier=$1
    
    if [ -z "$identifier" ]; then
        return 1
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        return 1
    fi
    
    local index=1
    while IFS='|' read -r name email; do
        if [ -n "$name" ] && [ -n "$email" ]; then
            # 检查是否匹配（编号或邮箱或名称）
            if [ "$index" == "$identifier" ] || [ "$email" == "$identifier" ] || [ "$name" == "$identifier" ]; then
                echo "$name|$email"
                return 0
            fi
            ((index++))
        fi
    done < "$CONFIG_FILE"
    
    return 1
}

# 显示当前凭证
show_current_credentials() {
    echo -e "${BLUE}=== 当前 Git 凭证配置 ===${NC}\n"
    
    # 检查是否在 Git 仓库中
    if [ ! -d .git ]; then
        echo -e "${YELLOW}警告: 当前目录不是 Git 仓库${NC}\n"
    fi
    
    echo -e "${GREEN}全局配置:${NC}"
    GLOBAL_NAME=$(git config --global user.name 2>/dev/null)
    GLOBAL_EMAIL=$(git config --global user.email 2>/dev/null)
    
    if [ -z "$GLOBAL_NAME" ] && [ -z "$GLOBAL_EMAIL" ]; then
        echo "  未设置"
    else
        echo "  user.name:  ${GLOBAL_NAME:-未设置}"
        echo "  user.email: ${GLOBAL_EMAIL:-未设置}"
    fi
    
    echo ""
    echo -e "${GREEN}本地配置 (当前仓库):${NC}"
    LOCAL_NAME=$(git config --local user.name 2>/dev/null)
    LOCAL_EMAIL=$(git config --local user.email 2>/dev/null)
    
    if [ -z "$LOCAL_NAME" ] && [ -z "$LOCAL_EMAIL" ]; then
        echo "  未设置 (将使用全局配置)"
    else
        echo "  user.name:  ${LOCAL_NAME:-未设置}"
        echo "  user.email: ${LOCAL_EMAIL:-未设置}"
    fi
    
    echo ""
    echo -e "${GREEN}实际生效的配置:${NC}"
    EFFECTIVE_NAME=$(git config user.name 2>/dev/null)
    EFFECTIVE_EMAIL=$(git config user.email 2>/dev/null)
    echo "  user.name:  ${EFFECTIVE_NAME:-未设置}"
    echo "  user.email: ${EFFECTIVE_EMAIL:-未设置}"
    
    # 识别当前使用的是哪个凭证
    echo ""
    echo -e "${BLUE}=== 凭证识别 ===${NC}"
    if [ -n "$EFFECTIVE_EMAIL" ] && [ -f "$CONFIG_FILE" ]; then
        local index=1
        local found=0
        while IFS='|' read -r name email; do
            if [ -n "$name" ] && [ -n "$email" ] && [ "$email" == "$EFFECTIVE_EMAIL" ]; then
                echo -e "${GREEN}当前使用: [$index] $name <$email>${NC}"
                found=1
                break
            fi
            ((index++))
        done < "$CONFIG_FILE"
        
        if [ $found -eq 0 ]; then
            echo -e "${YELLOW}当前凭证不在已保存的列表中${NC}"
        fi
    else
        echo -e "${YELLOW}未设置凭证${NC}"
    fi
}

# 切换凭证
switch_credentials() {
    local identifier=$1
    local scope=$2
    
    if [ -z "$identifier" ]; then
        echo -e "${RED}错误: 请指定凭证编号、名称或邮箱${NC}"
        echo -e "${YELLOW}提示: 使用 'list' 命令查看所有凭证${NC}"
        return 1
    fi
    
    if [ -z "$scope" ]; then
        scope="local"
    fi
    
    if [ "$scope" != "local" ] && [ "$scope" != "global" ]; then
        echo -e "${RED}错误: 作用域必须是 local 或 global${NC}"
        return 1
    fi
    
    # 检查是否在 Git 仓库中（local 模式需要）
    if [ "$scope" == "local" ] && [ ! -d .git ]; then
        echo -e "${RED}错误: 当前目录不是 Git 仓库，无法设置本地配置${NC}"
        echo -e "${YELLOW}提示: 使用 --global 参数设置全局配置${NC}"
        return 1
    fi
    
    # 获取凭证信息
    local cred_info=$(get_credential "$identifier")
    if [ -z "$cred_info" ]; then
        echo -e "${RED}错误: 未找到凭证 '$identifier'${NC}"
        echo -e "${YELLOW}提示: 使用 'list' 命令查看所有凭证${NC}"
        return 1
    fi
    
    local name=$(echo "$cred_info" | cut -d'|' -f1)
    local email=$(echo "$cred_info" | cut -d'|' -f2)
    
    # 设置凭证
    git config --$scope user.name "$name"
    git config --$scope user.email "$email"
    
    echo -e "${GREEN}✓ 已切换到: $name <$email>${NC}"
    echo -e "  作用域: $scope"
    echo -e "  user.name:  $name"
    echo -e "  user.email: $email"
}

# 显示帮助信息
show_help() {
    echo -e "${BLUE}Git 凭证切换工具${NC}\n"
    echo "用法:"
    echo "  $0 [命令] [参数] [选项]"
    echo ""
    echo "命令:"
    echo "  show, status, s          显示当前凭证配置"
    echo "  list, ls, l              列出所有已保存的凭证"
    echo "  add <name> <email>      添加新凭证"
    echo "  remove, rm <id|email>   删除凭证（通过编号或邮箱）"
    echo "  switch, sw <id|name|email>  切换到指定凭证 (默认: local)"
    echo "  help, h                  显示此帮助信息"
    echo ""
    echo "选项 (用于 switch 命令):"
    echo "  --global, -g             设置全局配置 (默认: local)"
    echo "  --local, -l              设置本地配置 (默认)"
    echo ""
    echo "示例:"
    echo "  $0 show                           # 显示当前凭证"
    echo "  $0 list                           # 列出所有凭证"
    echo "  $0 add \"John Doe\" \"john@example.com\"  # 添加新凭证"
    echo "  $0 remove 1                        # 删除编号为 1 的凭证"
    echo "  $0 remove \"john@example.com\"      # 通过邮箱删除凭证"
    echo "  $0 switch 1                        # 切换到凭证 1 (本地)"
    echo "  $0 switch \"John Doe\" --global     # 通过名称切换 (全局)"
    echo "  $0 switch \"john@example.com\"      # 通过邮箱切换 (本地)"
    echo ""
    echo "配置文件位置: $CONFIG_FILE"
}

# 主函数
main() {
    # 初始化配置
    init_config
    
    case "$1" in
        show|status|s|"")
            show_current_credentials
            ;;
        list|ls|l)
            list_credentials
            ;;
        add)
            shift
            add_credential "$1" "$2"
            ;;
        remove|rm)
            shift
            remove_credential "$1"
            ;;
        switch|sw)
            SCOPE="local"
            IDENTIFIER=""
            # 解析选项
            shift
            # 先处理所有选项
            for arg in "$@"; do
                case "$arg" in
                    --global|-g)
                        SCOPE="global"
                        ;;
                    --local|-l)
                        SCOPE="local"
                        ;;
                    *)
                        if [ -z "$IDENTIFIER" ]; then
                            IDENTIFIER="$arg"
                        else
                            echo -e "${RED}错误: 未知参数 '$arg'${NC}"
                            show_help
                            exit 1
                        fi
                        ;;
                esac
            done
            # 检查是否指定了凭证标识
            if [ -z "$IDENTIFIER" ]; then
                echo -e "${RED}错误: 请指定凭证编号、名称或邮箱${NC}"
                echo -e "${YELLOW}提示: 使用 'list' 命令查看所有凭证${NC}"
                show_help
                exit 1
            fi
            # 执行切换
            switch_credentials "$IDENTIFIER" "$SCOPE"
            ;;
        help|h|--help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}错误: 未知命令 '$1'${NC}\n"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
