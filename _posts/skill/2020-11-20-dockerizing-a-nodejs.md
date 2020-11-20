---
title: "Node.js 프로그램을 도커 이미지로 빌드하기"
date: 2020-11-20T07:45:46.246Z
categories: 
  - docker
  - nodejs
tags:
  - 빌드
---

예제 프로젝트 깃허브: [Example Dockerizing Express Github](https://github.com/sdg9670/example-dockerizing-express)

## Dockerfile 구성

![](/assets/images/2020-11-20-dockerizing-a-nodejs-1.png)

빌드되는 Docker 이미지는 위와 같은 구성이다.

**명령어를 구성을 할때 중요한 점이 Docker의 Cache 기능을 최대한 활용하여 빌드 속도를 빠르게 하고 용량을 줄이는 것이 핵심**

## 도커 이미지 구성

**Base**
> Base 이미지는 빌드 및 실행에 쓸 기본적인 `Node 환경을 구성`
> - Alpine 리눅스에 Node가 탑재된 node-alpine 이미지를 사용
> - Node는 이미 설치되어있기에 기타 부가적으로 필요한 패키지를 설치
> - 작업을 할 폴더를 구성
> - 로컬에서 package.json 복사

**Dependensies**
> Dependensies 이미지는 Base 이미지 기반으로 빌드 및 실행에 쓰일 `Node Modules을 설치`
> - package.json에 구성된 dependencies를 우선 설치
> - dependencies를 다른 폴더에 복사
> - 이미 dependencies가 설치 됬기에 devDependencies 항목만 설치

**Build**
> Build 이미지는 Dependensies 이미지 기반으로 `소스코드 빌드`
> - 빌드에 필요한 설정파일 및 소스코드 복사
> - 빌드 명령어 실행

**Release**
> Release 이미지는 base 이미지 기반으로 `빌드파일을 실행`
> - Build Args 설정 및 환경변수 설정
> - Dependensies 이미지에서 devDependencies를 제외한 dependencies만 복사
> - 빌드에 필요한 설정파일 및 소스코드 복사
> - 환경변수에 맞는 빌드 명령어 실행

## Dockerfile 예제

```yaml
# ---- Base ----
FROM node:12.16.1-alpine AS base
# install os package
RUN apk add --no-cache make gcc g++ python
# set working directory
RUN mkdir /example-dockerizing-express
WORKDIR /example-dockerizing-express
# copy project file
COPY package.json .

# ---- Dependencies ----
FROM base AS dependencies
# install node modules
RUN npm set progress=false && npm config set depth 0
RUN npm install --only=production
# copy production node_modules aside
RUN cp -R node_modules prod_node_modules
# install all node_modules, including 'devDependencies'
RUN npm install

# ---- Builder ----
FROM dependencies AS builder
COPY --from=dependencies /example-dockerizing-express/node_modules ./node_modules
COPY ./.babelrc ./.babelrc
COPY ./lib ./lib
COPY ./test ./test
RUN npm run build
RUN npm run test

# ---- Release ----
FROM base AS release
# set env
ARG NODE_ENV
ENV NODE_ENV=${NODE_ENV}
# copy production node_modules
COPY --from=dependencies /example-dockerizing-express/prod_node_modules ./node_modules
# copy app sources
COPY --from=builder /example-dockerizing-express/dist ./dist
# expose port and define CMD
EXPOSE 3000
CMD ["sh", "-c", "npm run start:${NODE_ENV}"]
```

## Dockerfile Build

본 게시글 상단의 예제 프로젝트로 진행한다.

```bash
# 예제 프로젝트 Clone
git clone https://github.com/sdg9670/example-dockerizing-express.git

# 프로젝트 폴더 이동
cd example-dockerizing-express

# 예제 프로젝트 경로에서 아래의 명령어를 알맞게 입력한 후 실행
# NODE_ENV: dev, test, production
docker build --build-arg NODE_ENV=옵션 -t 이미지이름 .

# 3000포트를 바인딩 후 이미지를 컨테이너로 실행
docker run -p 3000:3000 --name 컨테이너이름 이미지이름
```


위 명령어를 실행하신 후 http://localhost:3000/ 에 접속하시면 본인이 설정한 NODE_ENV를 출력한다.

![](/assets/images/2020-11-20-dockerizing-a-nodejs-2.png)

성공적으로 빌드되고 실행된 것을 확인할 수 있다.

이렇게 되면 생성된 이미지로 언제든 컨테이너를 생성할 수 있다.

> 다음 포스팅: [Docker & Jenkins 구성 및 자동배포 (With Github Webhook)]({% post_url skill/2020-11-20-docker-jenkins-ci-cd %})