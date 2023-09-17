FROM mcr.microsoft.com/devcontainers/jekyll:latest

RUN sudo apt-get update

# install nodejs
RUN sudo apt-get install -y ca-certificates curl gnupg
RUN sudo mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
ENV NODE_MAJOR=20
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
RUN sudo apt-get update
RUN sudo apt-get install nodejs -y

# install dev env about nodejs
RUN sudo npm install -g prettier husky lint-staged
RUN npx husky install

RUN curl https://raw.githubusercontent.com/git/git/v$(git version | cut -d ' ' -f 3)/contrib/completion/git-completion.bash > ~/.git-completion.bash
RUN echo "if [ -f ~/.git-completion.bash ]; then\n    . ~/.git-completion.bash\nfi" >> ~/.bashrc

RUN git config --global user.email "sdg9670@naver.com"
RUN git config --global user.name "SimDdong"
RUN git config --global pull.rebase false
