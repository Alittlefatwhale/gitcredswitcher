# Git 凭证切换工具

一个简单易用的脚本，用于管理和切换 Git 用户凭证。支持动态添加、删除和切换任意数量的凭证。

## 功能特性

- ✅ 查看当前 Git 凭证配置（全局和本地）
- ✅ 动态添加新凭证
- ✅ 删除已有凭证
- ✅ 列出所有已保存的凭证
- ✅ 通过编号、名称或邮箱快速切换凭证
- ✅ 支持全局和本地配置
- ✅ 自动识别当前使用的凭证
- ✅ 彩色输出，易于阅读

## 快速开始

### 查看当前凭证

```bash
./git-cred-switcher.sh show
# 或简写
./git-cred-switcher.sh
./git-cred-switcher.sh s
```

### 列出所有凭证

```bash
./git-cred-switcher.sh list
# 或简写
./git-cred-switcher.sh ls
./git-cred-switcher.sh l
```

### 添加新凭证

```bash
./git-cred-switcher.sh add "用户名" "邮箱"
# 示例
./git-cred-switcher.sh add "John Doe" "john@example.com"
```

### 删除凭证

```bash
# 通过编号删除
./git-cred-switcher.sh remove 1
# 或通过邮箱删除
./git-cred-switcher.sh remove "john@example.com"
# 简写
./git-cred-switcher.sh rm 2
```

### 切换凭证

```bash
# 通过编号切换（本地配置，仅影响当前仓库）
./git-cred-switcher.sh switch 1
# 或简写
./git-cred-switcher.sh sw 1

# 通过名称切换
./git-cred-switcher.sh switch "John Doe"

# 通过邮箱切换
./git-cred-switcher.sh switch "john@example.com"

# 切换到凭证 2（全局配置，影响所有仓库）
./git-cred-switcher.sh switch 2 --global
# 或
./git-cred-switcher.sh sw 2 -g
```

### 查看帮助

```bash
./git-cred-switcher.sh help
```

## 完整命令列表

| 命令 | 简写 | 说明 |
|------|------|------|
| `show` | `s` | 显示当前凭证配置 |
| `list` | `ls`, `l` | 列出所有已保存的凭证 |
| `add <name> <email>` | - | 添加新凭证 |
| `remove <id\|email>` | `rm` | 删除凭证 |
| `switch <id\|name\|email>` | `sw` | 切换到指定凭证 |
| `help` | `h` | 显示帮助信息 |

## 工作原理

### 凭证存储

凭证保存在当前目录的 `.git-credentials` 文件中，格式为：
```
用户名|邮箱
```

### 配置优先级

- **本地配置** (`--local`): 只影响当前 Git 仓库，优先级高于全局配置
- **全局配置** (`--global`): 影响所有 Git 仓库（除非被本地配置覆盖）

脚本会显示：
1. 全局配置
2. 本地配置（如果有）
3. 实际生效的配置（Git 会优先使用本地配置）

## 使用场景

### 场景 1: 添加多个工作账户

```bash
# 添加工作账户
./git-cred-switcher.sh add "工作账户" "work@company.com"

# 添加个人账户
./git-cred-switcher.sh add "个人账户" "personal@gmail.com"

# 查看所有凭证
./git-cred-switcher.sh list
```

### 场景 2: 为不同项目使用不同凭证

```bash
# 进入工作项目
cd ~/projects/work-project
./git-cred-switcher.sh switch "工作账户"

# 进入个人项目
cd ~/projects/personal-project
./git-cred-switcher.sh switch "个人账户"
```

### 场景 3: 设置默认全局凭证

```bash
# 设置全局默认凭证
./git-cred-switcher.sh switch 1 --global

# 为特定项目覆盖
cd ~/projects/special-project
./git-cred-switcher.sh switch 2
```

### 场景 4: 管理凭证列表

```bash
# 查看所有凭证
./git-cred-switcher.sh list

# 删除不需要的凭证
./git-cred-switcher.sh remove "old@email.com"

# 添加新凭证
./git-cred-switcher.sh add "新账户" "new@email.com"
```

## 安装（可选）

### 方法 1: 添加到 PATH

将脚本复制到系统 PATH 中的目录：

```bash
sudo cp git-cred-switcher.sh /usr/local/bin/git-cred-switcher
```

然后就可以在任何地方使用：

```bash
git-cred-switcher show
git-cred-switcher sw 1
```

### 方法 2: 创建别名

在你的 `~/.zshrc` 或 `~/.bashrc` 中添加：

```bash
alias gcs='/Users/michaelbradley/Desktop/gitcredswitcher/git-cred-switcher.sh'
```

然后重新加载 shell：

```bash
source ~/.zshrc  # 或 source ~/.bashrc
```

现在可以使用：

```bash
gcs show
gcs sw 1
gcs add "新用户" "new@example.com"
```

## 注意事项

- 本地配置只对当前 Git 仓库有效
- 如果设置了本地配置，它会覆盖全局配置
- 删除本地配置可以使用：`git config --local --unset user.name` 和 `git config --local --unset user.email`
- 凭证配置文件位置：当前目录下的 `.git-credentials` 文件
- 首次运行会自动创建空的配置文件，需要手动添加凭证

## 配置文件格式

凭证文件 (`.git-credentials`) 格式：

```
用户名1|邮箱1
用户名2|邮箱2
用户名3|邮箱3
```

你可以手动编辑此文件，但建议使用脚本命令来管理，以避免格式错误。
