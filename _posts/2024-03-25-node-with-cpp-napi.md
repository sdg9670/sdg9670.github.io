---
title: "Node.js와 C++의 만남 (N-API)"
categories:
  - nodejs
tags:
  - nodejs
  - napi
  - c++
last_modified_at: 2024-03-25T18:00:00+09:00
---

![](/assets/images/posts/2024-03-25-node-with-cpp-napi-1.png)

# Node.js와 C++의 관계

Node.js는 C++로 만들어져 있다. Node.js를 이용하여 수 년동안 개발을 했다. 단순히 C++로 Node.js가 만들어졌으며 V8, Libuv 라이브러리 등을 이용하여 구현되어 있다는 사실만 알고 있었다. 최근 오픈소스 코드를 분석하다가 C++로 짜여진 코드를 봤다.

> [node-rdkafka](https://github.com/Blizzard/node-rdkafka)
> Node.js에서 카프카를 이용할 수 있는 라이브러리이다. src 폴더를 보면 C++로 구성된 것을 볼 수 있다.
> 이 라이브러리는 `Confluent`의 [librdkafka](https://github.com/confluentinc/librdkafka) 라이브러리를 Node.js에 사용할 수 있게 랩핑한 것이다.

위의 코드를 봤고 C++로 구현된 부분을 직접 이용할 수 있다는 사실을 알았다.

# C++ 환경에서 사용할 수 있는 API

Node.js는 C++로 만들어졌다고 했다. 그럼 Node.js에서 C++를 어떻게 사용할 수 있을까? 바로 Nodejs 제공하는 [C++ Addon](https://nodejs.org/api/addons.html)이 있다.

C++에서 제공하는 Node.js 헤더는 아래와 같이 있다.

- node.h: Node.js의 C++ API를 직접 호출할 수 있다. V8 엔진과 직접 상호작용하며 Node.js의 버전별로 각각 빌드해야된다는 불편함이 있다. 제공하는 API 중에 가장 원시적인 방법이라 할 수 있다.
- nan.h: V8과 Node.js 버전에 대응하는 추상화된 API를 제공한다. 버전별로 일관된 API로 개발할 수 있으나 Node.js의 버전별로 각각 빌드해야된다는 단점은 여전히 존재한다.
- node_api.h: C 스타일(구조체)로 API를 제공한다. ABI(Application Binary Interface) 호환을 지원하므로 Node.js의 다양한 버전에 호환이 가능하다.
- napi.h: C++ 스타일(객체)로 API를 제공한다. ABI(Application Binary Interface) 호환을 지원하므로 Node.js의 다양한 버전에 호환이 가능하다.

C++을 이용하여 개발한다면 napi.h 헤더를 사용하는 것을 추천한다. N-Api는 Node-API의 약자로 자세한 내용은 [N-API 공식문서](https://nodejs.org/api/n-api.html)에서 확인 가능하다.

# 계산기 구현해보기

N-API를 이용하여 간단한 사칙연산 계산기를 구현해보자.

- C++ style napi.h 사용
- 빌드툴은 [node-gyp](https://github.com/nodejs/node-gyp), [CMake.js](https://github.com/cmake-js/cmake-js) 중 node-gyp를 사용할 것이다.
- [node-bindings](https://github.com/TooTallNate/node-bindings) 라이브러리로 C++파일을 Node.js에 import 한다.

## 환경 구성

napi.h는 [node-addon-api](https://github.com/nodejs/node-addon-api) 패키지에 포함되어 있다. 아래의 패키지들을 설치하도록 한다.

```bash
$ npm install node-addon-api node-gyp bindings
```

node-gyp로 빌드하기 위한 설정파일을 생성한다

```python
# ./binding.gyp
{
  "targets": [
    {
      "target_name": "addon",
      "sources": [ "addon.cpp", "calculator.cpp" ],
      "include_dirs": [
        "<!@(node -p \"require('node-addon-api').include\")"
      ],
      "defines": [ 'NAPI_DISABLE_CPP_EXCEPTIONS' ],
    }
  ]
}
```

target_name은 바인딩 파일 이름(addon.node 생성)이고 sources는 빌드할 파일, include_dirs은 빌드시 필요한 헤더 위치이다. 간단한 예제를 만들 것이므로 defines에서 NAPI에서 예외처리 하는 기능은 끌 것이다.

## C++ 작성

소스코드 작성 부분은 간략히 이런게 있구나 정도로 보면 좋을 것이다.

Napi::ObjectWrap 객체를 상속하여 Calculator를 정의하였다.

```c++
// calculator.h
#ifndef CALCULATOR_H
#define CALCULATOR_H

#include <napi.h>

class Calculator : public Napi::ObjectWrap<Calculator> {
 public:
  // Javascript 함수 레퍼런스
  static Napi::FunctionReference* functionRef;
  // Javasciprt 클래스 생성 및 초기화
  static Napi::Function Init(Napi::Env env);
  // 팩토리 함수
  static Napi::Object From(Napi::Env env, Napi::Value arg);
  // 생성자
  Calculator(const Napi::CallbackInfo& info);

 private:
  Napi::Value GetValue(const Napi::CallbackInfo& info);
  Napi::Value Add(const Napi::CallbackInfo& info);
  Napi::Value Subtract(const Napi::CallbackInfo& info);
  Napi::Value Multiply(const Napi::CallbackInfo& info);
  Napi::Value Divide(const Napi::CallbackInfo& info);

  double value_;
};

#endif
```

C++ 객체를 Javascript에서 사용하기 위해 Class를 정의한다. DefineClass는 ObjectWrap에서 상속받은 함수이다.

```c++
// calculator.cpp, Napi::Function Calculator::Init
Napi::Function Calculator::Init(const Napi::Env env) {
  // Javascript 클래스 생성
  Napi::Function func =
      DefineClass(env, "Calculator",
                  {InstanceMethod("add", &Calculator::Add),
                   InstanceMethod("subtract", &Calculator::Subtract),
                   InstanceMethod("multiply", &Calculator::Multiply),
                   InstanceMethod("divide", &Calculator::Divide),
                   InstanceMethod("getValue", &Calculator::GetValue)});

  // 클래스 생성 후 functionRef에 저장 (Persistent 함수는 GC 대상 제외시킴)
  *Calculator::functionRef = Napi::Persistent(func);

  return func;
}
```

functionRef에 저장된 Class를 이용하여 객체를 생성한다.

```c++
// calculator.cpp, Napi::Object Calculator::From
// 팩토리 함수
Napi::Object Calculator::From(Napi::Env env, Napi::Value arg) {
  Napi::Object obj = Calculator::functionRef->New({arg});
  return obj;
}
```

생성자 함수 중간을 보면 Napi::CallbackInfo로 Javascript 함수의 인자를 이용할 수 있다.

```c++
// calculator.cpp, Calculator::Calculator
// 생성자
Calculator::Calculator(const Napi::CallbackInfo& info)
    : Napi::ObjectWrap<Calculator>(info) {
  Napi::Env env = info.Env();

  // 인자가 없거나 숫자가 아닌 경우 에러 처리
  int length = info.Length();
  if (length <= 0 || !info[0].IsNumber()) {
    Napi::TypeError::New(env, "Number expected").ThrowAsJavaScriptException();
    return;
  }

  Napi::Number value = info[0].As<Napi::Number>();
  this->value_ = value.DoubleValue();
}
```

Javscript의 Number, String 등을 이용하려면 Napi에 있는 객체를 이용하여야 한다.

```c++
// calculator.cpp, Napi::Value Calculator::GetValue
Napi::Value Calculator::GetValue(const Napi::CallbackInfo& info) {
  double num = this->value_;

  // c++의 double을 Napi:Number로 변환
  return Napi::Number::New(info.Env(), num);
}
```

```c++
// calculator.cpp, Napi::Value Calculator::Add
Napi::Value Calculator::Add(const Napi::CallbackInfo& info) {
  Napi::Env env = info.Env();

  int length = info.Length();
  if (length <= 0 || !info[0].IsNumber()) {
    Napi::TypeError::New(env, "Number expected").ThrowAsJavaScriptException();
    return env.Null();
  }

  const Napi::Number value = info[0].As<Napi::Number>();
  // Napi::Number를 C++의 double로 변환
  this->value_ = this->value_ + value.DoubleValue();

  return Calculator::GetValue(info);
}
```

위와 같은 방식으로 나머지 Calculator 함수도 작성하였다.

아래와 같이 Calculator 객체를 export 해준다. (Javascript의 module.export와 같은 기능)

```c++
// addon.cpp
#include <napi.h>

#include "calculator.h"

Napi::Value CreateCalculator(const Napi::CallbackInfo& info) {
  return Calculator::From(info.Env(), info[0]);
}

Napi::Object InitAll(Napi::Env env, Napi::Object exports) {
  exports.Set("Calculator", Calculator::Init(env));
  exports.Set("createCalculator", Napi::Function::New(env, CreateCalculator));
  return exports;
}

NODE_API_MODULE(addon, InitAll)

/*
  Like...
  module.exports = {
    Caculator: CaculatorClass,
    createCalculator: (arg: number) => CaculatorClass
  };
*/
```

## Javascript 코드 작성

```javascript
// index.js

// binding.gyp의 target_name과 동일한 이름으로 모듈 바인딩
const addon = require("bindings")("addon");

console.log("Calculator", addon.Calculator);
console.log("createCalculator", addon.createCalculator);

const calculator = new addon.Calculator(0);
console.log(calculator.add(10)); // 10
console.log(calculator.subtract(5)); // 5
console.log(calculator.multiply(8)); // 40
console.log(calculator.divide(4)); // 10
console.log(calculator.getValue()); // 10

const calculator2 = addon.createCalculator(0);
console.log(calculator2.add(10)); // 10
console.log(calculator2.subtract(5)); // 5
console.log(calculator2.multiply(8)); // 40
console.log(calculator2.divide(4)); // 10
console.log(calculator2.getValue()); // 10
```

## 예제

코드 결과물은 [Github Repository](https://github.com/sdg9670/node-api-calculator)에서 확인할 수 있다. 또한 [Node Addon Example Repository](https://github.com/nodejs/node-addon-examples)에 많은 예제가 있으니 학습시 참고하는 것을 추천한다.

## 빌드 및 실행

```bash
# bindings.gyp 파일을 토대로 빌드 환경 구성
$ npx node-gyp configure

# 빌드
$ npx node-gyp build

# 실행
$ node index.js
```

# 그래서 어디에 활용할 수 있을까?

앞서 말한대로 수많은 C 라이브러리를 래핑해서 Node에서 사용할 수 있다. 또한 Node.js 처리하기 힘든 고성능 작업들도 처리할 수 있다. 이러한 Node Addon은 공식적으로 C++을 지원한다. 또한 유저들이만든 Rust 언어를 사용한 [node-rs](https://github.com/napi-rs/node-rs)이 존재한다. 다음에는 node-rs도 경험을 해볼 예정이다.

# 참고

- [Node Addon 공식문서](https://nodejs.org/api/addons.html)
- [N-API 공식문서](https://nodejs.org/api/n-api.html)
- [Node Addon Example Repository](https://github.com/nodejs/node-addon-examples)
