FROM mcr.microsoft.com/devcontainers/jekyll:latest

RUN sudo apt-get update

# install dev env about nodejs
RUN sudo npm install -g prettier husky lint-staged
RUN npx husky install

RUN curl https://raw.githubusercontent.com/git/git/v$(git version | cut -d ' ' -f 3)/contrib/completion/git-completion.bash > ~/.git-completion.bash
RUN echo "if [ -f ~/.git-completion.bash ]; then\n    . ~/.git-completion.bash\nfi" >> ~/.bashrc

RUN git config --global user.email "sdg9670@naver.com"
RUN git config --global user.name "SimDdong"
RUN git config --global pull.rebase false
