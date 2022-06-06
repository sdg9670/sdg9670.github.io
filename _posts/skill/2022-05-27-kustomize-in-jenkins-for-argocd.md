---
title: "Kustomize와 Jenkins를 이용한 ArgoCD 배포"
date: 2022-05-27T00:02:15.040Z
categories:
  - microservice
  - kubernetes
---

# k8s와 argoCD의 버전 동기화 문제

기존 배포 수행시 도커 이미지 빌드 후 아래와 같은 이미지 변경 명령어를 사용하여 쿠버네티스에 배포를 했었다.

```bash
kubectl set image deployment.v1.apps/nginx-deployment nginx=nginx:1.16.1
```

이번에 ArgoCD 도입 이후 Git 저장소와 K8S의 deployment 이미지 버전을 동기화시켜야되는 일이 생긴 것이다. 물론 수동으로 이미지 버전을 수정하여 커밋할 수 있지만 이런 것까지 하기는 매우 귀찮다.

# 요구사항

일단 아래와 같은 간단한? 요구사항이 있다.

1. 배포 환경을 분리할 것 (production, test 등)
2. 배포용 브랜치를 분리할 것
3. 쿠버네티스 오브젝트 중복은 최소화

# Kustomize

Kustomize는 쿠버네티스 오브젝트를 사용자가 원하는 대로 변경할 수 있는 도구이다. 한마디로 명령어나 설정파일로 yaml 파일을 마음 껏 변경할 수 있다는 것! ~~이것을 알기 전에는 yaml 파일을 sed 같은 찾아바꾸기로 하려 했었다.~~ 또한 기본 base 오브젝트를 두어 overlay 오브젝트로 덮어쓸 수 있다. 덮어쓰는 기능을 사용하면 코드 중복을 줄일 수 있다.

# Jenkins

젠킨스는 아주 유명한 빌드 자동화 도구이다. 이번에는 pipeline을 사용해보려고 한다. pipeline은 jenkins에서도 작성할 수 있지만 git 저장소에서 관리할 수도 있다. 소스코드 관리를 위해 git 저장소에서 관리하도록 한다.

# ArgoCD

ArgoCD는 Git을 사용하여 쿠버네티스 배포를 자동화한다. 그리고 원 소스코드인 Git을 참조하기에 배포속도가 빠르고 변경기록을 남기기에 안정성이 높다. (GitOps)

# Sampe Repository

일단 모든 소스코드는 [github](https://github.com/sdg9670/argocd-test-app)에 있다. 참고하면 좋다.

# Kustomize 설정

## Kustomization.yaml

일단 쿠버네티스 오브젝트를 관리하기 위해 Kustomize를 세팅한다. 설치방법은 [설치링크](https://kubectl.docs.kubernetes.io/installation/kustomize/)를 참고하여 설치하기로 한다.

폴더 구조는 아래와 같이 생겼다.

![](/assets/images/2022-05-27-kustomize-in-jenkins-for-argocd-1.png)

deploy폴더에 쿠버네티스 오브젝트 파일을 두었으며, `Base` 기반이 될 오브젝트이고, `Overlays` 폴더에는 운영 환경에 따라 폴더(development, production)을 두고 각 환경마다 변하는 오브젝트 설정을 정의하면 된다. 최종적으로는 base에 overlays에서 해당 환경에 맞는 오브젝트가 merge 된다.

- base/deployment.yaml

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-test-app-deployment
spec:
  startegy:
    type: RollingUpdate
  replicas: 3
  selector:
    matchLabels:
      app: argocd-test-app
  template:
    spec:
      containers:
      - name: argocd-test-app
        image: argocd-test-app
        ports:
        - containerPort: 80
```

위 소스를 보면 공통적으로 사용하는 값만 정의해놨다. image 태그같은건 정의하지 않았다. `base/service.yaml`도 마찬가지라 생략한다.

- base/kustomization.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: argocd-test-app
commonLabels:
  app: argocd-test-app

images:
  - name: argocd-test-app

resources:
  - ./deployment.yaml
  - ./service.yaml
```

Kustomaze 정의 파일이다. 공통 namespace와 label을 정의했으며 image name도 정의했다. resources는 사용할 오브젝트 목록이다.

- overlays/development/deployment-patches.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: argocd-test-app-deployment
spec:
  replicas: 2
```

이제 개발 환경에서 쓸 오브젝트이다. metadata.name이랑 같은 base폴더의 오브젝트가 매칭된다. 그래서 metadata.name은 서로 일치해야 한다. 그리고 개발환경에서의 레플리카 수는 많이 필요 없기에 2개로 변경했다.

- overlays/development/kustomazation.yaml

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: argocd-test-app-dev
commonLabels:
  app: argocd-test-app-dev
nameSuffix: -dev

patches:
  - ./deployment-patches.yaml
  - ./service-patches.yaml

images:
  - name: argocd-test-app

resources:
  - ../../base
```

나는 개발환경에서 사용하는 오브젝트들은 마지막에 `-dev`를 붙이려고 한다. 그래서 namespace와 라벨을 재정의했으며 `nameSuffix: -dev`도 추가했다. `nameSuffix`는 name 마지막에 해당 문자를 추가한다. `patches`는 patch할 파일 목록이다. `resources`는 patch를 반영할 목록이다.

## Kustomize Build

아직 kustomazation.yaml에 이미지 태그 정보가 없다. 그래서 이미지 태그 정보를 명령어로 입력하자. 나중엔 이 명령어를 jenkins 빌드시에 사용할 것이다.

```bash
# now path: deploy/overlays/development
kustomize edit set image argocd-test-app=argocd-test-app-dev:1
```

그러면 `deploy/overlays/development/kustomization.yaml`의 image 부근에 newName하고 newTage가 생긴다.

```yaml
images:
  - name: argocd-test-app
    newName: argocd-test-app-dev
    newTag: "1"
```

아래 입력하면 빌드된 결과를 console에 출력한다.

```bash
# now path: deploy/overlays/development
kustomize build .
```

```yaml
# 결과
apiVersion: v1
kind: Service
metadata:
  labels:
    app: argocd-test-app-dev
  name: argocd-test-app-service-dev
  namespace: argocd-test-app-dev
spec:
  ports:
    - port: 80
      protocol: TCP
      targetPort: 80
  selector:
    app: argocd-test-app-dev
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: argocd-test-app-dev
  name: argocd-test-app-deployment-dev
  namespace: argocd-test-app-dev
spec:
  replicas: 2
  selector:
    matchLabels:
      app: argocd-test-app-dev
  startegy:
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: argocd-test-app-dev
    spec:
      containers:
        - image: argocd-test-app-dev:1
          name: argocd-test-app
          ports:
            - containerPort: 80
```

난 이 결과물을 `deploy/overlays/development/output/deploy.yaml` 파일로 관리하려 한다. 그래서 아래 명령어를 사용한다.

```bash
# now path: deploy/overlays/development
kustomize build . > output/deploy.yaml
```

이제 Kustomize 설정은 끝이 난다.

# Jenkins 설정

## pipeline

일단 `jenkins/development.Jenkinsfile`이란 파일을 생성했다. 이 파일에 파이프라인을 작성할 것이다. 처음 작성해봤기에 로직 참고만 하면 좋을 것 같다.

```Groovy
pipeline {
    agent any

    stages {
        // 메인 브렌치에 체크아웃
        stage('checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/sdg9670/argocd-test-app.git'
            }
        }

        // 도커파일 빌드
        stage('docker build') {
            steps {
                sh 'docker build -t docker.registry.com/argocd-test-app-dev:${BUILD_NUMBER} .'
            }
        }

        // 도커파일 푸시
        stage('docker push') {
            steps {
                sh 'docker push docker.registry.com/argocd-test-app-dev:${BUILD_NUMBER}'
            }
        }

        // deploy할 브랜치에 체크아웃
        stage('git checkout deploy branch') {
            steps {
                sh 'git checkout deploy-development'
            }
        }

        // 기존 deploy 폴더 삭제 후 main 브랜치에서 deploy 폴더를 풀 받음
        stage('copy deploy file from master') {
            steps {
                sh 'rm -rf deploy'
                sh 'git checkout main -- deploy'
            }
        }

        // output 폴더 생성 후 kustomize를 이용해 이미지 태그 변경 후 deploy.yaml로 빌드한다.
        stage('k8s config update') {
            steps {
                dir('deploy/overlays/development') {
                    sh 'mkdir -p output'
                    sh 'kustomize edit set image argocd-test-app=argocd-test-app-dev:${BUILD_NUMBER}'
                    sh 'kustomize build . > output/deploy.yaml'
                }
            }
        }

        // 빌드한 결과를 커밋하고 푸시한다.
        stage('k8s config commit and push') {
            steps {
                sh 'git config --global user.email "jenkins@jinhakapply.com"'
                sh 'git config --global user.name "jenkins"'
                sh 'git add -A'
                sh 'git commit -m "update! version: ${BUILD_NUMBER}"'
                withCredentials([
                    usernamePassword(
                        credentialsId: 'sdg_git',
                        usernameVariable: 'GIT_USERNAME',
                        passwordVariable: 'GIT_PASSWORD'
                    )]) {
                    sh("git push http://$GIT_USERNAME:$GIT_PASSWORD@github.com/sdg9670/argocd-test-app.git")
                }
            }
        }

        // 끝
        stage('deploy') {
            steps {
                echo 'deploy skip!'
            }
        }
    }

    // 파이프라인 종료 후 워크스페이스 초기화
    post {
        always {
            cleanWs()
        }
    }
}
```

자 이렇게 설정하고 Jenkins에서 pipeline 프로젝트 생성 후 pipeline의 definition을 `Pipeline script from SCM`으로 설정해야 git 저장소에서 pipeline을 불러올 수 있다.

# ArgoCD 설정

일단 기본적인 설정방법은 기존 설정하고 동일하고 Source 부분만 보도록 하겠다.

![](/assets/images/2022-05-27-kustomize-in-jenkins-for-argocd-2.png)

`Revision`은 각 운영환경에 맞는 deploy 브랜치를 입력하고 path도 운영환경에 맞게 output 경로를 설정하면 설정이 끝난다.

# 배포시마다 git 저장소 변경사항 추적

커밋별로 변경사항을 봄으로 배포시 변경된 사항을 추적할 수 있다.

![](/assets/images/2022-05-27-kustomize-in-jenkins-for-argocd-3.png)

# 결과적으로

위 과정이 좀 복잡할 수 있다. 그러나 위와 같이 관리를 함으로써 얻는 장점은 엄청나다. kubernets 오브젝트를 git에서 관리하므로 오브젝트 파일의 관리요소가 줄어들고 오브젝트 별 버전관리가 가능하다. kustomize로 base와 운영 환경별 오브젝트 설정을 나눔으로 오브젝트가 환경별로 중복되어 관리해야되는 부분이 사라진다. 또한 운영 환경별로 브랜치를 분리함으로써 개별 기록 추적에 용이하다. 이를 베이스로 응용하면 더 나은 배포 환경을 구성할 수 있을 것이다.
