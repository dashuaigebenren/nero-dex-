#!/bin/bash

# NERO DEX 项目安装脚本

echo "🚀 开始安装NERO DEX项目..."

# 检查Node.js版本
echo "📦 检查Node.js版本..."
node_version=$(node -v)
echo "当前Node.js版本: $node_version"

if ! command -v node &> /dev/null; then
    echo "❌ 错误: 请先安装Node.js (推荐版本 >= 16.0.0)"
    exit 1
fi

# 安装依赖
echo "📦 安装项目依赖..."
npm install

# 检查是否安装成功
if [ $? -eq 0 ]; then
    echo "✅ 依赖安装成功!"
else
    echo "❌ 依赖安装失败，请检查网络连接或权限设置"
    exit 1
fi

# 复制环境配置文件
echo "📄 创建环境配置文件..."
if [ ! -f .env ]; then
    cp env.example .env
    echo "✅ 已创建 .env 文件，请编辑其中的配置"
else
    echo "⚠️  .env 文件已存在，跳过创建"
fi

# 编译合约
echo "🔨 编译智能合约..."
npm run compile

if [ $? -eq 0 ]; then
    echo "✅ 合约编译成功!"
else
    echo "❌ 合约编译失败"
    exit 1
fi

# 显示后续步骤
echo ""
echo "🎉 NERO DEX项目安装完成！"
echo ""
echo "📋 下一步操作："
echo "1. 编辑 .env 文件，填入您的配置信息："
echo "   - PRIVATE_KEY: 您的私钥"
echo "   - NERO_TESTNET_RPC: NERO测试网RPC地址"
echo "   - NERO_MAINNET_RPC: NERO主网RPC地址"
echo ""
echo "2. 部署到测试网："
echo "   npm run deploy:testnet"
echo ""
echo "3. 验证合约："
echo "   npm run verify"
echo ""
echo "4. 运行测试："
echo "   npm run test"
echo ""
echo "📚 更多信息请查看 README.md 文件"
echo "" 