ARG ubuntu_version
ARG timezone
ARG web_server_port
ARG app_code_path_container

# https://hub.docker.com/_/ubuntu/
FROM ubuntu:${ubuntu_version}

ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=ja_JP.UTF-8
ENV LC_CTYPE=ja_JP.UTF-8
ENV LANGUAGE=ja_JP:jp
ENV TZ $timezone
ENV WEB_SERVER_PORT $web_server_port
ENV APP_CODE_PATH_CONTAINER $app_code_path_container

# Ubuntu base setting (locale and timezone and devtool)
RUN apt-get update \
    && apt-get -y -q install \
    # Lang ja
    language-pack-ja-base language-pack-ja apt-transport-https \
    # devtool
    vim netcat vim git curl wget zip unzip make sudo gcc libc-dev clang net-tools \
    xserver-xorg pkg-config libgtk-3-dev cmake ninja-build gnupg software-properties-common \
    && locale-gen ja_JP.UTF-8 \
    && localedef -f UTF-8 -i ja_JP ja_JP.utf8 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && echo "${TZ}" > /etc/timezone \
    && rm /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata

# requisites software
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && add-apt-repository ppa:maarten-fonville/android-studio
RUN apt-get update && \
    apt-get -y -q install \
    xz-utils libglu1-mesa openjdk-8-jdk google-chrome-stable android-studio \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Prepare Android directories and system variables
WORKDIR /usr/local
RUN mkdir -p Android/sdk
ENV ANDROID_SDK_ROOT /usr/local/Android/sdk
RUN mkdir -p .android && touch .android/repositories.cfg
RUN wget -O sdk-tools.zip https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip
RUN unzip sdk-tools.zip && rm sdk-tools.zip
RUN mv tools Android/sdk/tools
RUN cd Android/sdk/tools/bin && yes | ./sdkmanager --licenses
RUN cd Android/sdk/tools/bin && ./sdkmanager "build-tools;29.0.2" "patcher;v4" "platform-tools" "platforms;android-29" "sources;android-29"
ENV PATH "$PATH:/usr/local/Android/sdk/platform-tools"

# Dart
RUN sh -c 'curl https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list'
RUN apt-get update && \
    apt-get -y -q install \
    dart \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git
ENV PATH "$PATH:/usr/local/flutter/bin"

RUN flutter config --enable-web
RUN flutter doctor

EXPOSE ${WEB_SERVER_PORT}
