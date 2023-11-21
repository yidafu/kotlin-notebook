FROM jupyter/base-notebook:notebook-7.0.6

# Add a "USER root" statement followed by RUN statements to install system packages using apt-get,
# change file permissions, etc.
USER root

# update sources list
RUN rm /etc/apt/sources.list \
  && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse" >> /etc/apt/sources.list \
  && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list \
  && echo "deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse" >> /etc/apt/sources.list

# Kotlin Jupyter requires Java 11 to be installed.
# See https://github.com/Kotlin/kotlin-jupyter/pull/394 and https://github.com/Kotlin/kotlin-jupyter/pull/394/commits/5ebb0b020fe8b9b2fb0173b3c1d2e45087f3f8bc
RUN apt-get update \
  && apt-get install -yq --no-install-recommends vim curl unzip zip git make build-essential python3 openjdk-19-jdk

# RUN  curl -s "https://get.sdkman.io" | bash \
#   && source "$HOME/.sdkman/bin/sdkman-init.sh" \
#   && sdk version \
#   # && sdk install kotlin \
#   && sdk install java 19 open

# install kotlinc
COPY binary/* .
# RUN curl  --fail --location --progress-bar https://github.com/JetBrains/kotlin/releases/download/v1.9.20/kotlin-compiler-1.9.20.zip > kotlin-compiler-1.9.20.zip \
RUN java --version \
  && mkdir -p /usr/local/share/kolin \
  && unzip -qo kotlin-compiler-1.9.20.zip -d /usr/local/share/kotlin \
  && echo "export PATH=$PATH:/usr/local/share/kotlin/bin\n" > .bashrc \
  && rm kotlin-compiler-1.9.20.zip && ls /usr/local/share/kotlin

# install nvm node ijavascript
# https://github.com/nvm-sh/nvm#manual-install
RUN export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/ \
  && export NVM_DIR="$HOME/.nvm"  \
  && git clone https://gitee.com/mirrors/nvm.git "$NVM_DIR" \
  && cd "$NVM_DIR" \
  && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)` \
  && echo -e "export NVM_DIR=\"$HOME/.nvm\"\n" >> .bashrc \
  && echo -e "[ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\"\n" >> .bashrc \
  && source "$NVM_DIR/nvm.sh" \
  && npm config set registry https://registry.npmmirror.com \
  && nvm install v20.9.0 \
  && npm i -g pnpm \
  && echo -e "export PNPM_HOME=\"/home/jovyan/.pnpm\"\n" >> /home/jovyan/.bashrc \
  && export PNPM_HOME="/home/jovyan/.pnpm" \
  && echo -e "export PATH=\"$PNPM_HOME:$PATH\"\n" >> /home/jovyan/.bashrc \
  && export PATH="$PNPM_HOME:$PATH" \
  && pnpm config set registry https://registry.npmmirror.com \
  && pnpm install -g ijavascript --registry https://registry.npmmirror.com \
  && ijsinstall && chown -R $NB_UID:$NB_UID $HOME/.local

ENV JUPYTER_ENABLE_LAB=yes,GRANT_SUDO=yes

# If you do switch to root, always be sure to add a "USER $NB_USER" command at the end of the
# file to ensure the image runs as a unprivileged user by default.
USER $NB_UID

COPY requirements.txt .

RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple \
  &&  pip install kotlin-jupyter-kernel -r requirements.txt
