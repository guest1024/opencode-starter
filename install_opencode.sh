#!/bin.bash 
cd ~

#curl -sSLk https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-py310_23.11.0-2-Linux-x86_64.sh  -o Miniconda3-py310_23.11.0-2-Linux-x86_64.sh && \
#    bash ./Miniconda3-py310_23.11.0-2-Linux-x86_64.sh -b -p /usr/local/miniconda3 

curl -sSLk https://unofficial-builds.nodejs.org/download/release/v22.22.2/node-v22.22.2-linux-x64-glibc-217.tar.gz -o node-v22.22.2-linux-x64-glibc-217.tar.gz && \
    tar -xzf node-v22.22.2-linux-x64-glibc-217.tar.gz -C /usr/local/ && \
    ln -sf /usr/local/node-v22.22.2-linux-x64-glibc-217/bin/node /usr/local/bin/node && \
    ln -sf /usr/local/node-v22.22.2-linux-x64-glibc-217/bin/npm /usr/local/bin/npm && \
    rm -rf /node-v22.22.2-linux-x64-glibc-217.tar.gz

npm i -g opencode-ai --registry https://mirrors.cloud.tencent.com/npm/

ln -sf  /usr/local/node-v22.22.2-linux-x64-glibc-217/bin/npm  /usr/bin/opencode 

# 安装 Bun
curl -fsSL https://bun.sh/install | bash

# 重新加载 shell 配置
source ~/.zshrc  # 或 exec /usr/bin/zsh

# 验证安装
bun --version

npm i -g opencode-ai --registry https://mirrors.cloud.tencent.com/npm/

 # cp -r ./container/helix-config /root/.config/helix

