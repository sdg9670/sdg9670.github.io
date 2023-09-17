npx husky install

curl https://raw.githubusercontent.com/git/git/v$(git version | cut -d ' ' -f 3)/contrib/completion/git-completion.bash > ~/.git-completion.bash
echo -e "if [ -f ~/.git-completion.bash ]; then\n    . ~/.git-completion.bash\nfi" >> ~/.bashrc

git config --global user.email "sdg9670@naver.com"
git config --global user.name "SimDdong"
git config --global pull.rebase false

source ~/.bashrc