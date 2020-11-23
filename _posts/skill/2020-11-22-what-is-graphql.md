---
title: "GraphQL이 뭐죠? (RESTful API와 비교)"
date: 2020-11-22T03:34:20.758Z
categories:
  - graphql
tags:
  - graph
  - REST
  - RESTful
  - API
---

> Facebook은 2012년 RESTful API를 사용하는 기존의 모바일 앱을 다시 만들어야겠다고 판단한다. 그 이유는 성능도 좋지 않았고 앱은 충돌이 자주났기 때문이다. 이 때 데이터를 전송하는 방식을 개선해야된다고 깨닫게 된다. 이 후 데이터를 다른 시각으로 바라보게 되고 GraphQL을 만들기 시작하여 2015년 7월에 GraphQL 레퍼런스를 공개하였다. 현재 페이스북 내부 데이터는 GraphQL을 이용하여 전송하며 IBM, Airbnb, Intuit 등 다른 회사에서도 사용한다.

![](/assets/images/2020-11-22-what-is-graphql-1.png)

**GraphQL은 Graph 이론을 기반으로 만든 API를 만들 때 사용하는 SQL 언어이다. 데이터에 대한 스키마 정의를 한 기준으로 쿼리를 실행하여 데이터를 불러오는 방식이다.**

# 간단한 예

아래 사진을 보면 위쪽 공간에는 히어로의 이름을 불러오는 쿼리를 작성하였고 아래쪽은 그 쿼리에 대한 결과 데이터이다.

![](/assets/images/2020-11-22-what-is-graphql-2.png)

# GraphQL 특징

## 데이터 형태 정의

데이터 형태를 미리 정의 함으로써 쿼리가 반환하는 데이터 내용을 미리 예측할 수 있고 앱에서 필요한 데이터에 대한 쿼리를 작성할 수 있다.

## 계층적

GraphQL은 자연스럽게 객체와의 관계를 따르게 된다. 필드 안에 다른 필드가 중첩될 수 있는 것이다. 그렇기에 GraphQL은 그래프 구조의 인터페이스와 잘 어울린다.

## 엄격한 타입

GraphQL은 스키마 정의로 엄격하게 타입을 정의한다. 이로 인해 유효성 검사를 하게되며 오류 메시지도 제공한다.

## 저장소가 아닌 프로토콜

GraphQL은 저장소 계층을 사용하지 않는다. 저장소에서 데이터를 불러오는 비즈니스 로직이 구현된 어플리케이션 계층을 사용하여 데이터를 제공한다.

# Rest

Rest는 자원을 중심으로 행위를 4가지 행동(GET, POST, PUT, DELETE)를 정의를 한다. 과거에는 더욱 더 복잡한 데이터를 다루기 위한 혁신적인 새로운 방법이었다. 이 Rest는 웹 개발에 큰 영향을 미치고 지금 까지도 많이 사용된다.

| Task             | Method | Path       |
| ---------------- | ------ | ---------- |
| 게시글 목록 보기 | GET    | /post      |
| 특정 게시글 보기 | GET    | /post/{id} |
| 게시글 작성      | POST   | /post      |
| 게시글 수정      | PUT    | /post/{id} |
| 게시글 삭제      | DELETE | /post/{id} |

# GraphQL vs Rest

페이스북은 왜 새로운 데이터 전송 방식을 만들었을까?

스타워즈 API인 swapi를 이용하여 알아보자.

# Rest의 단점

## Overfetcing

특정 인물에 대한 이름, 키, 몸무게를 불러와야된다고 가정해보자.

기존 Rest 방식으로는 아래와 같은 데이터를 받을 수 있다.

**요청**

https://swapi.dev/api/people/1

**결과**

```json
{
  "name": "Luke Skywalker",
  "height": "172",
  "mass": "77",
  "hair_color": "blond",
  "skin_color": "fair",
  "eye_color": "blue",
  "birth_year": "19BBY",
  "gender": "male",
  "homeworld": "http://swapi.dev/api/planets/1/",
  "films": [
    "http://swapi.dev/api/films/1/",
    "http://swapi.dev/api/films/2/",
    "http://swapi.dev/api/films/3/",
    "http://swapi.dev/api/films/6/"
  ],
  "species": [],
  "vehicles": [
    "http://swapi.dev/api/vehicles/14/",
    "http://swapi.dev/api/vehicles/30/"
  ],
  "starships": [
    "http://swapi.dev/api/starships/12/",
    "http://swapi.dev/api/starships/22/"
  ],
  "created": "2014-12-09T13:50:51.644000Z",
  "edited": "2014-12-20T21:17:56.891000Z",
  "url": "http://swapi.dev/api/people/1/"
}
```

불필요한 데이터가 너무 많이 포함되어 전송됬다.

GraphQL을 이용하여 데이터를 불러와보자

**요청**

https://graphql.org/swapi-graphql

```graphql
query {
  person(personID: 1) {
    name
    height
    mass
  }
}
```

**결과**

```json
{
  "data": {
    "person": {
      "name": "Luke Skywalker",
      "height": 172,
      "mass": 77
    }
  }
}
```

Rest와 달리 필요한 필드만 불러올 수 있다. 여기서 서버에서 전송하는 데이터 양을 줄여 성능을 높일 수 있다.

## Underfetcing

특정 인물이 등장한 영화 이름들이 필요하다고 가정해보자.

Rest의 경우 특정 인물에 대해 요청하고 그 결과에 있는 영화들을 다시 불러와야 된다.

**요청**

https://swapi.dev/api/people/1

**결과**

```json
{
  "name": "Luke Skywalker",
  "height": "172",
  "mass": "77",
  "hair_color": "blond",
  "skin_color": "fair",
  "eye_color": "blue",
  "birth_year": "19BBY",
  "gender": "male",
  "homeworld": "http://swapi.dev/api/planets/1/",
  "films": [
    "http://swapi.dev/api/films/1/",
    "http://swapi.dev/api/films/2/",
    "http://swapi.dev/api/films/3/",
    "http://swapi.dev/api/films/6/"
  ],
  "species": [],
  "vehicles": [
    "http://swapi.dev/api/vehicles/14/",
    "http://swapi.dev/api/vehicles/30/"
  ],
  "starships": [
    "http://swapi.dev/api/starships/12/",
    "http://swapi.dev/api/starships/22/"
  ],
  "created": "2014-12-09T13:50:51.644000Z",
  "edited": "2014-12-20T21:17:56.891000Z",
  "url": "http://swapi.dev/api/people/1/"
}
```

위 결과에서 films의 필드에 있는 api를 다시 불러와야 된다.

**요청**

http://swapi.dev/api/films/1/

http://swapi.dev/api/films/2/

http://swapi.dev/api/films/3/

http://swapi.dev/api/films/6/

**결과 (4개)**

```json
{
  "title": "A New Hope",
  "episode_id": 4,
  "opening_crawl": "It is a period of civil war.\r\nRebel spaceships, striking\r\nfrom a hidden base, have won\r\ntheir first victory against\r\nthe evil Galactic Empire.\r\n\r\nDuring the battle, Rebel\r\nspies managed to steal secret\r\nplans to the Empire's\r\nultimate weapon, the DEATH\r\nSTAR, an armored space\r\nstation with enough power\r\nto destroy an entire planet.\r\n\r\nPursued by the Empire's\r\nsinister agents, Princess\r\nLeia races home aboard her\r\nstarship, custodian of the\r\nstolen plans that can save her\r\npeople and restore\r\nfreedom to the galaxy....",
  "director": "George Lucas",
  "producer": "Gary Kurtz, Rick McCallum",
  "release_date": "1977-05-25",
  "characters": [
    "http://swapi.dev/api/people/1/",
    "http://swapi.dev/api/people/2/",
    "http://swapi.dev/api/people/3/",
    "http://swapi.dev/api/people/4/",
    "http://swapi.dev/api/people/5/",
    "http://swapi.dev/api/people/6/",
    "http://swapi.dev/api/people/7/",
    "http://swapi.dev/api/people/8/",
    "http://swapi.dev/api/people/9/",
    "http://swapi.dev/api/people/10/",
    "http://swapi.dev/api/people/12/",
    "http://swapi.dev/api/people/13/",
    "http://swapi.dev/api/people/14/",
    "http://swapi.dev/api/people/15/",
    "http://swapi.dev/api/people/16/",
    "http://swapi.dev/api/people/18/",
    "http://swapi.dev/api/people/19/",
    "http://swapi.dev/api/people/81/"
  ],
  "planets": [
    "http://swapi.dev/api/planets/1/",
    "http://swapi.dev/api/planets/2/",
    "http://swapi.dev/api/planets/3/"
  ],
  "starships": [
    "http://swapi.dev/api/starships/2/",
    "http://swapi.dev/api/starships/3/",
    "http://swapi.dev/api/starships/5/",
    "http://swapi.dev/api/starships/9/",
    "http://swapi.dev/api/starships/10/",
    "http://swapi.dev/api/starships/11/",
    "http://swapi.dev/api/starships/12/",
    "http://swapi.dev/api/starships/13/"
  ],
  "vehicles": [
    "http://swapi.dev/api/vehicles/4/",
    "http://swapi.dev/api/vehicles/6/",
    "http://swapi.dev/api/vehicles/7/",
    "http://swapi.dev/api/vehicles/8/"
  ],
  "species": [
    "http://swapi.dev/api/species/1/",
    "http://swapi.dev/api/species/2/",
    "http://swapi.dev/api/species/3/",
    "http://swapi.dev/api/species/4/",
    "http://swapi.dev/api/species/5/"
  ],
  "created": "2014-12-10T14:23:31.880000Z",
  "edited": "2014-12-20T19:49:45.256000Z",
  "url": "http://swapi.dev/api/films/1/"
}
```

위 데이터에서 title만 필요한 상황이다.

만약 특정 인물은 5명이 필요하고 특정 인물당 10번 영화에 등장했다고 하면 `50(5*10)`번의 요청이 필요하다. 여기서 영화 데이터에서는 title만 필요하니 불필요한 데이터가 너무 많기도 하다.

이번엔 GraphQL을 이용하여 요청해보자.

**요청**

```graphql
query {
  person(personID: 1) {
    filmConnection {
      films {
        title
      }
    }
  }
}
```

**결과**

```json
{
  "data": {
    "person": {
      "filmConnection": {
        "films": [
          {
            "title": "A New Hope"
          },
          {
            "title": "The Empire Strikes Back"
          },
          {
            "title": "Return of the Jedi"
          },
          {
            "title": "Revenge of the Sith"
          }
        ]
      }
    }
  }
}
```

Rest와 확연한 차이가 보인다. Rest는 여러 번 요청한 것에 비해 GraphQL은 한 번의 요청으로 원하는 데이터를 불러오고 불필요한 데이터는 제외시켰다.

## Rest의 Endpoint

Rest에서 위에서 봤던 Overfetching과 Underfetching 문제를 해결하기 위해 custom endpoint 를 사용하기도 한다. `/api/character-wtih-movie-title`과 같은 endpoint가 많이 생길 것이다. 이렇게 되면 custom endpoint를 이해하기 위해 백앤드팀과 프론트앤드팀은 많은 커뮤니케이션이 필요하고 개발 속도도 느려질 것이다.

GraphQL에서는 하나의 endpoint를 스키마 정의를 통해 도큐먼트를 생성해 백앤드팀과 프론트앤드팀의 커뮤니케이션 시간이 줄어들어 빠른 개발이 가능할 것이다.

# 결론

GraphQL이 좋은가? RESTful이 좋은가? 이에 대한 답은 없다. 웹이 발전해나가면서 일부 부하가 걸리는 문제를 해결하는 좋은 방법을 GraphQL은 제공할 뿐이다.
