---
title: "[도서] WebAssembly in Action (웹어셈블리 인 액션)"
categories:
  - webassembly
tags:
  - webassembly
  - book
last_modified_at: 2023-09-10T08:40:00+09:00
---

# 들어가기 앞서

웹 어셈블리를 한 번쯤은 들어보긴 했을 것이다. 우리가 기존에 아는 어셈블리는 아래와 같을 것이다.

```nasm
; Hello World 출력 프로그램
section .data
	msg db "hello world", 0x0A

_main :
	mov rax, 1
	mov rdi, 1
	mov rsi, msg
	mov rdx, 12
	syscall
	mov rax, 60
	mov rdi, 0
	syscall

section .text
	global _main
```

우리는 고급 언어(High-Level Language)에 익숙해져있어 위 어셈블리 코드만으로는 어떤 기능을 동작하는지 한눈에 파악하기 어렵다.
난 여태까지 이런 어셈블리어로 코딩한 것은 javascript에 적용시키는게 웹 어셈블리인 줄 알았다. 그러나 놀랍게도 아니여서 나에겐 문화충격이었다.. (난 바본가..ㅠ)

# 책 정보

![](/assets/images/posts/2023-09-10-web-assembly-in-action-0.jpg)

- 웹 어셈블리 인 액션
- Gerard Gallent 지음, 이일웅 옮김
- [상세 정보](http://www.kyobobook.co.kr/product/detailViewKor.laf?mallGb=KOR&ejkGb=KOR&barcode=9791162243473)

# 읽고 나서

일단 여기서 말하는 웹 어셈블리는 C언어를 어셈블리어로 빌드한 결과물을 Javascript로 실행하는 것이다. 이전까지 웹 어셈블리가 어셈블리어로 직접 작성하는 줄 알고 괜히 겁먹었었다.

![](/assets/images/posts/2023-09-10-web-assembly-in-action-1.jpg)

전체적인 과정은 C언어 소스코드를 Emscripten을 이용해 wasm으로 변환 후 Javascript를 이용하여 wasm을 불러온다.

책에서는 기본적인 설치방법부터 소스코드 작성 후 실행까지 직접 실습해볼 수 있다. 소스코드 작성부분은 엄청 디테일하게 나와있어 이해하기 쉬웠다.
어려웠던 점은 C언어에 익숙치 않다는 것과 엠스크립튼 변환을 위해 사전에 선언해야되는 것들이 있고 그로인해 변수 및 함수 선언 방식이 불편하다고 느꼈다. 놀라웠던 점은 링킹을 통해 모듈화가 가능하다는 것이다. `또한 쓰레드 사용이 가능하단 것이다!!` 그럼으로써 소스코드의 재활용 및 체계적인 관리가 가능할 것이다. 또한 이미 소스크는 컴파일됐으므로 실행속도는 자바스크립트보다 어마어마하게 빠르다.

이 책은 개념하나를 실습으로 설명한다. 소스코드가 주 내용인게 조금 아쉽다. 그러나 차근차근 한 단계식 실습해보고 싶은 분, 웹 어셈블리가 처음인 분에게 이 책을 추천한다.

# 추가적으로

이제 웹 어셈블리는 발전하고 있는 단계이며 여러 기여자가 다양한 언어 및 프레임워크로 웹 어셈블리를 작성할 수 있게 노력 중이다.
웹 어셈블리를 작성가능한 언어 목록을 다루는 git repo가 있다. 생각보다 여러 언어로 작성가능해서 놀랍다.

> [AWESOME WASM LANGS](https://github.com/appcypher/awesome-wasm-langs)
