---
title: "WebAssembly in Action (웹어셈블리 인 액션)"
date: 2021-12-19T00:02:15.040Z
categories:
  - webassembly
  - book
tags:
  - webassembly
  - javascript
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

![](/assets/images/2021-12-19-web-assembly-in-action-0.jpg)

- 웹 어셈블리 인 액션
- Gerard Gallent 지음, 이일웅 옮김
- [상세정보보기](http://www.kyobobook.co.kr/product/detailViewKor.laf?mallGb=KOR&ejkGb=KOR&barcode=9791162243473)

# 읽고 나서

작성 중..
