---
title: "Docker & Jenkins 구성 및 자동배포 (With Github Webhook)"
date: 2020-11-20T08:01:00.246Z
categories:
  - docker
  - jenkins
tags:
  - webhook
---

> 이전 포스팅: [Dockerizing a Node.js]({% post_url skill/2020-11-20-dockerizing-a-nodejs %})

이전에 만든 Docker를 이용해 Jenkins에서 자동배포를 해보자.

# Github Fork

일단 본인 소유의 예제 프로젝트가 필요하다.

깃허브에서 프로젝트 `fork`를 한다.
깃허브: [Example Dockerizing Express Github](https://github.com/sdg9670/example-dockerizing-express)
![](/assets/images/2020-11-20-docker-jenkins-ci-cd-0.png)

그러면 본인 소유의 repository가 생성된다.

# Jenkins 구성

Jenkins를 설치해야되는데 설치하기가 귀찮다.
Docker 이미지를 이용하여 간단하게 실행시켜본다.

먼저 `빈 폴더를 생성`한다.

## Dockerfile 작성

`Dockerfile을 생성`한 후 아래와 같이 `입력`한다.

```yaml
FROM jenkins/jenkins:lts

USER root

RUN apt-get update && \
apt-get -y install apt-transport-https \
ca-certificates \
curl \
gnupg2 \
zip \
unzip \
software-properties-common && \
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey && \
add-apt-repository \
"deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
$(lsb_release -cs) \
stable" && \
apt-get update && \
apt-get -y install docker-ce
```

## docker-compose.yml 작성

`docker-compose.yml을 생성`한다.

아래 문서를 보고 `docker-compose를 구성`한다.

[Jenkins Docker Documentation](https://github.com/jenkinsci/docker/blob/master/README.md)

아래는 윈도우 환경일 경우이다. 리눅스 경우는 volumes를 수정하시면 된다.

```yaml
# docker-compose.yml
version: '3.7'

services:
  jenkins:
    build:
      context: .
    container_name: jenkins
    user: root
    ports:
      - 8080:8080
      - 50000:50000
    container_name: jenkins
    volumes:
      - ./jenkins_home:/var/jenkins_home
      - //var/run/docker.sock:/var/run/docker.sock
```

## Jenkins 이미지 실행

위와 같이 파일을 작성하고 해당 폴더에서 아래 명령어를 실행한다.

```bash
docker-compose up
```

그럼 젠킨스가 실행된다.

## Jenkins 설정

`http://localhost:8080` 에 접속하고 설정을 해야한다.

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-1.png)

위 패스워드는 젠킨스 폴더에서 `jenkins_home/secrets/initialAdminPassword` 파일을 열면 확인할 수 있다.

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-2.png)

`Install suggested plugins`를 선택한다.
조금만 기다리시면 플러그인 설치가 끝이 난다.
계정 생성 해주시고 기본적인 설정을 진행해야한다.

## 프로젝트 구성

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-3.png)

메인에서 `새로운 Item` 클릭 클릭한다.

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-4.png)

프로젝트 이름 입력 후 OK를 클릭한다.

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-5.png)

`이 빌드는 매개변수가 있습니다`를 선택 후 위와 같이 입력한다.

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-6.png)

소스 코드 관리에서 git을 선택한 후 본인이 fork하여 생성된 repository url을 입력한다.

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-7.png)

빌드에서 `Add build step` 클릭 후 `Execute shell` 선택 후 위와 같이 입력한다.

위 `매개변수가 있습니다`에서 설정한 파라미터를 환경변수를 받은 후 build shell에서 사용할 수 있다. 또한 기본 환경변수를 제공한다. (JOB_NAME: 작업이름, BUILD_NUMBER: 빌드번호)

docker rm 부분에서 `| true`는 이미지가 없을 경우 삭제를 할 시 오류가 발생하기에 항상 오류가 안나도록 처리한다.

## 빌드 실행

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-8.png)

Build with Parameters를 클릭한다.

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-9.png)

원하는 NODE_ENV를 입력한다. (dev, test, production)

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-10.png)

왼쪽 하단에 빌드번호와 함께 빌드가 완료된 파란색 동그라미가 나타난다.

로컬에서 `docker images`와 `docker ps`를 실행하면 생성된 이미지와 실행된 컨테이너를 확인할 수 있다.

# push시 Github webhook 자동 빌드

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-11.png)

프로젝트 구성에서 위 Github hook ~~을 체크하고 저장한다.

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-13.png)

`Add Webhook` 클릭하고 비밀번호를 입력한다.

![](/assets/images/2020-11-20-docker-jenkins-ci-cd-12.png)

위와 같이 설정 후 `Add webhook`을 클릭한다.

이제 github에 push할 시 github에서 jenkins로 webhook을 보내 자동 빌드를 한다.

위의 기본 webhook 말고 다른 github 플러그인을 사용할 수 있다.
