---
title: "GraphQL의 QL (Query Language, 쿼리어)"
categories:
  - graphql
tags:
  - graphql
  - http
last_modified_at: 2023-09-04T08:40:00+09:00
---

# 쿼리 (Query)

쿼리 작업은 API에 데이터를 요청하는 것이다. 쿼리에는 필드로 구성되어 있으며 이 필드는 서버에서 받아 오는 JSON 데이터의 키 값이다. 필드 값은 GraphQL은 `Int`, `Float`, `String`, `Boolean`의 5가지 스칼라 타입과 스칼라 타입들을 그룹으로 묶은 `객체` 형태로 사용할 수 있다.

## 기본 쿼리 예제

실습할 API는 Moon Highway에서 제공하는 스노투스 산에 있는 가상의 스키 리조트 API를 사용한다.

링크: [Snowtooth Playground](https://snowtooth.moonhighway.com/)

- 리프트의 이름과 상태 불러오기

```graphql
query {
  allLifts {
    name
    status
  }
}
```

- 결과

```json
{
  "data": {
    "allLifts": [
      {
        "name": "Astra Express",
        "status": "OPEN"
      },
      {
        "name": "Jazz Cat",
        "status": "OPEN"
      },
      ...
    ]
  }
}
```

- 개장한 리프트의 갯수, 이름 및 상태, 코스 이름 및 난이도 불러오기

```graphql
query liftsAndTrails {
  liftCount(status: "OPEN")
  allLifts {
    name
    status
  }
  allTrails {
    name
    difficulty
  }
}
```

- 결과

```json
{
  "data": {
    "liftCount": 6,
    "allLifts": [
      {
        "name": "Astra Express",
        "status": "OPEN"
      },
      {
        "name": "Jazz Cat",
        "status": "OPEN"
      },
      ...
    ],
    "allTrails": [
      {
        "name": "Blue Bird",
        "difficulty": "intermediate"
      },
      {
        "name": "Blackhawk",
        "difficulty": "intermediate"
      },
      ...
    ]
  }
}
```

- dance-fight 코스의 관리 여부와 코스로 접근 가능한 리프트 찾기

```graphql
query liftToAccessTrail {
  Trail(id: "dance-fight") {
    groomed
    accessedByLifts {
      name
      capacity
    }
  }
}
```

- 결과

```json
{
  "data": {
    "Trail": {
      "groomed": true,
      "accessedByLifts": [
        {
          "name": "Jolly Roger",
          "capacity": 6
        }
      ]
    }
  }
}
```

## 프래그먼트 (Fragment)

프래그먼트는 셀렉션 세트의 일종으로 재사용 가능하다.

아래와 같이 Fragment를 리프트 타입의 LiftInfo라는 프래그먼트를 정의한다.

```graphql
fragment LiftInfo on Lift {
  name
  status
  capacity
}
```

그리고 미리 정의된 프래그먼트를 사용 가능한다. 마치 javascript에서 object spread 같다.

```graphql
query {
  Lift(id: "jazz-cat") {
    ...liftInfo
    trailAccess {
      name
      difficulty
    }
  }
  Trail(id: "river-run") {
    name
    difficulty
    accessByLifts {
      ...liftInfo
    }
  }
}
```

## 유니언 타입 (Union type)

지금까지의 리스트의 반환은 한 가지 타입만 반환을 했는데 여러 개의 타입을 리스트에 담을 수도 있다.

아래와 같이 유니언 타입을 정의를 하면

```graphql
union SearchResult = Human | Droid | Starship
```

타입 이름과 각 해당하는 타입에 맞게 필드를 불러온다.

```graphql
query {
  search(text: "an") {
    __typename
    ... on Human {
      name
      height
    }
    ... on Droid {
      name
      primaryFunction
    }
    ... on Starship {
      name
      length
    }
  }
}
```

또한 정의된 Fragment를 사용할 수 있다.

```graphql
query {
  search(text: "an") {
    __typename
    ...Human
    ...Droid
    ...Starship
  }
}
```

## 인터페이스 (Interface)

인터페이스는 유사한 객체를 여러 개 만들기 위해 필드를 모아논 것이다.

인터페이스를 아래와 같이 정의하고

```graphql
interface Character {
  id: ID!
  name: String!
  friends: [Character]
  appearsIn: [Episode]!
}
```

인터페이스를 상속받아 인터페이스에서 자식이 가져야하는 필드를 정의한다.

```graphql
type Human implements Character {
  id: ID!
  name: String!
  friends: [Character]
  appearsIn: [Episode]!
  starships: [Starship]
  totalCredits: Int
}

type Droid implements Character {
  id: ID!
  name: String!
  friends: [Character]
  appearsIn: [Episode]!
  primaryFunction: String
}
```

아래와 같이 불러오면 primaryFunction은 Droid에만 있기에 에러가 난다.

```graphql
query HeroForEpisode($ep: Episode!) {
  hero(episode: $ep) {
    name
    primaryFunction
  }
}
```

interface와 구분을 시켜야 된다.

```graphql
query HeroForEpisode($ep: Episode!) {
  hero(episode: $ep) {
    name
    ... on Droid {
      primaryFunction
    }
  }
}
```

# 뮤테이션 (Mutation)

Mutation은 데이터를 생성하거나 수정 및 삭제할 때 사용합니다. 또한 매개변수를 줄 수 있어 동적인 값을 입력할 수 있습니다. 또한 실행 후 반환할 데이터도 정의할 수 있습니다.

- 에피소드에 대한 리뷰 생성 (매개변수: ep, review)

```graphql
mutation CreateReviewForEpisode($ep: Episode!, $review: ReviewInput!) {
  createReview(episode: $ep, review: $review) {
    stars
    commentary
  }
}
```

- 매개변수

```json
{
  "ep": "JEDI",
  "review": {
    "stars": 5,
    "commentary": "This is a great movie!"
  }
}
```

- 결과 (stars, commentary 반환)

```json
{
  "data": {
    "createReview": {
      "stars": 5,
      "commentary": "This is a great movie!"
    }
  }
}
```
