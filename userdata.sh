#!/bin/bash -xe
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
apt update
apt install -y --no-install-recommends \
    build-essential \
    consul \
    docker.io \
    fzf \
    git \
    gcc \
    jq \
    libfuse2 \
    lxc \
    make \
    mc \
    mosh \
    net-tools \
    nomad \
    ripgrep \
    terraform \
    tzdata \
    unzip \
    vault \
    vim \
    wget \
    zsh
usermod -a -G docker ubuntu

cat >> /home/ubuntu/.ssh/id_ed25519 <<EOF
${ssh_private_key}
EOF
cat >> /home/ubuntu/.ssh/id_ed25519.pub <<EOF
${ssh_public_key}
EOF
chmod 0400 /home/ubuntu/.ssh/id*
export HOME="/home/ubuntu"
git config --global user.email "470696+pkazmierczak@users.noreply.github.com"
git config --global user.name "pkazmierczak"
ssh-keyscan github.com >> /home/ubuntu/.ssh/known_hosts
chown -R ubuntu:ubuntu /home/ubuntu

cat > /home/ubuntu/nomad.hcl <<EOF
${nomad_conf}
EOF

ln -fs /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v0.42.0/lazygit_0.42.0_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
install lazygit /usr/local/bin
curl -L https://github.com/helix-editor/helix/releases/download/25.01.1/helix-25.01.1-x86_64.AppImage -o /usr/bin/hx
chmod 0755 /usr/bin/hx
curl -L https://github.com/neovim/neovim/releases/download/v0.10.4/nvim-linux-x86_64.appimage -o /usr/bin/nvim
chmod 0755 /usr/bin/nvim
rm -f /usr/bin/vim
ln -s /usr/bin/nvim /usr/bin/vim
git clone https://github.com/robbyrussell/oh-my-zsh.git /home/ubuntu/.oh-my-zsh
cp /home/ubuntu/.oh-my-zsh/templates/zshrc.zsh-template /home/ubuntu/.zshrc
cat >> /home/ubuntu/.zshrc <<EOF
export PATH=~/go/bin:/usr/local/go/bin:$PATH
export GOTOOLCHAIN=go1.24.1
EOF
usermod -s /bin/zsh ubuntu
curl -L https://go.dev/dl/go1.24.1.linux-amd64.tar.gz | tar -C /usr/local -zxv
sudo -u ubuntu git clone git@github.com:hashicorp/nomad.git /home/ubuntu/nomad
sudo -u ubuntu git clone git@github.com:hashicorp/nomad-enterprise.git /home/ubuntu/nomad-enterprise
sudo -u ubuntu git clone git@github.com:pkazmierczak/configs.git /home/ubuntu/configs
mkdir -p /home/ubuntu/.config/nvim
ln -s /home/ubuntu/configs/.config/nvim/init.lua /home/ubuntu/.config/nvim/init.lua
ln -s /home/ubuntu/configs/.config/helix /home/ubuntu/.config/helix
sudo -u ubuntu /usr/local/go/bin/go install golang.org/x/tools/gopls@latest
chown -R ubuntu:ubuntu /home/ubuntu
