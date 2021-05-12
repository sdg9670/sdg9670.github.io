---
title: "Typescript Class에서 필드 불러올 때 undefiend 해결법 (With Babel)"
date: 2021-05-12T03:34:20.758Z
categories:
  - nodejs
tags:
  - typscript
  - babel
---

# 문제를 발견하게 된 계기

Sequelize ORM을 사용하는데 DB에서 불러온 데이터를 모델에 담는데 까지는 성공했다. 개발환경(ts-node) 환경에서는 문제가 없었는데 Babel로 빌드를 한 후 특정 Class에서 필드를 호출하면 undefined가 발생하는 문제가 있었다.

```javascript
const simDdong = People.findAll({ where: { name: "SimDdong" } });

console.log(simDdong, simDdong.name);

// ts-node
// {name: 'simDdong'} simDdong

// Babel 빌드
// {name: 'simDdong'} undefined
```

어이없게도 Babel로 빌드 후에 인스턴스 안에 데이터는 있는데 특정 필드를 불러올 때 undefined로 나온다. ~~이것땜에 시간 날리고 스트레스도 엄청 받았다.~~

# 문제가 무엇일까

문제를 찾기 위해 폭풍 구글링을 했다. `@babel/proposal-class-properties` 해당 플러그인을 사용시 문제가 발생한다. 위 플러러그인은 Class에서 필드 초기화와 static 필드에 대한 변환을 제공한다. 이 플러그인이 변환시 특정 조건에서 문제가 발생하는 것 같다.

# 어떤 조건에서 문제가 발생하는가?

```javascript
class MyClass {
  number: number;
}

MyClass.prototype.number = 3;

const myClass = new MyClass();
console.log(myClass, myClass.number);

// ts-node
// {number: 3} 3

// Babel 빌드
// {number: 3} undefined
```

위와 같이 Flow 타입으로 class를 작성하고 결과를 봤더니.. 바벨 빌드 후 실행에서 문제가 생긴다. Flow 형식으로 작성된 곳에서 바벨 `@babel/proposal-class-properties` 플러그인이 변환하는 과정에서 undefined(void 0)으로 변환을 한 것이다.

# 어떻게 해결하지?

원인을 찾았다. 그럼 `@babel/proposal-class-properties` 플러그인이 변환하기 전에 Flow 타입 클레스을 알맞게 먼저 바꿔주면 될 것이다. 바벨 컨피그에서 `@babel/transform-flow-strip-types` 플러그인을 추가한다. 물론 `@babel/proposal-class-properties`보다 먼저 추가해야한다.

```javascript
{
  "presets": [...],
  "plugins": ["@babel/transform-flow-strip-types", "@babel/proposal-class-properties", ...],
}
```

다시 빌드해서 실행했더니 우리가 원했던대로 정상적으로 동작한다.

여러분들은 ~~개~~고생하지 않았으면..
