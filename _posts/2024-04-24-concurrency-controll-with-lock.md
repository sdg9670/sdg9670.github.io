---
title: "락(Lock)을 이용한 동시성(Concurrency) 제어"
categories:
  - concurrency
tags:
  - nodejs
  - microservice
last_modified_at: 2024-04-25T17:00:00+09:00
---

동시성 제어의 핵심 기술 중 하나인 '락(Lock)'에 대해 다루고자 한다. 이전에 [**동시성 제어가 필요한 이유**]({% post_url 2024-04-23-concurrency-controll %})에 대해 작성한 글을 먼저 참고하면 좋을 것 같다.

# 락(Lock)

락(Lock)은 여러 프로세스 또는 스레드가 동시에 공유 자원에 접근하는 것을 방지하는 메커니즘이다. 락은 동시에 발생하는 여러 작업들 사이에서 데이터의 안정성을 보장하며, 경쟁 상태(Race Condition)와 데드락(Deadlock)과 같은 문제를 방지하는 데 중요한 역할을 한다.

# 락을 구현하는 방식

## 낙관적 락(Optimistic Lock)

### 낙관적 락이란

낙관적 락은 데이터베이스 트랜잭션에서 충돌을 최소화하면서 성능을 향상시키는 동시성 제어 전략이다. 이는 트랜잭션이 시작될 때 데이터의 버전을 확인하고, 트랜잭션 완료 시 데이터를 업데이트하기 전에 다시 버전을 확인하는 방식으로 작동한다. 만약 다른 트랜잭션에서 데이터를 업데이트하여 버전이 변경되었으면, 현재 트랜잭션은 롤백되고 다시 시도하도록 한다.

### 낙관적 락의 장점

- 성능: 충돌이 드물게 발생하는 환경에서 높은 성능을 제공한다.
- 데드락 방지: 락을 사용하지 않기 때문에 데드락 발생 가능성이 낮다.

### 낙관적 락의 단점

- 충돌 발생 시 오버헤드: 충돌 발생 시 롤백 및 재시도가 필요하여 추가적인 작업이 발생한다.
- 데이터 무결성 위험: 충돌 감지를 위한 버전 확인 과정에서 데이터 무결성 위험이 발생할 수 있다.

### 낙관적 락이 적합한 경우

충돌 발생 빈도가 낮고 데이터 무결성보다 성능을 훨 더 우선시하는 경우에 적합하다.

### 코드 구현

티켓을 구매하면 (잔여갯수: quantity)를 줄이는 방식의 예제이다.

Update 구문에서 quantity까지 where 절로 업데이트 후 반영된 행이 없으면 재시도하는 방식이다.

```typescript
async buyTicket({ ticketId, userId }: { ticketId: number; userId: number }) {
  let affectedRows: number = 0;
  let retryCount = 0; // 재시도 횟수 제한

  while (affectedRows === 0 && retryCount < 100) {
    retryCount++;

    // 티켓 조회
    const [ticket] = await this.prismaService.$queryRaw<
      { quantity: number }[]
    >`SELECT quantity FROM Ticket WHERE id = ${ticketId}`;

    // 잔여 수량이 없으면 에러 발생
    if (ticket.quantity <= 0) {
      throw new Error('Ticket sold out');
    }

    // 해당 티켓에 조회한 잔여 수량이 있으면 잔여수량 감소
    affectedRows = await this.prismaService
      .$executeRaw`UPDATE Ticket SET quantity = ${ticket.quantity} - 1 WHERE id = ${ticketId} AND quantity = ${ticket.quantity}`;

    // 티켓이 확인 안되면 재시도 (잦은 재시도로 인한 부하 방지)
    if (affectedRows === 0) {
      await this.utilService.sleep(100 + Math.random() * 400);
      continue;
    }

    try {
      // 유저 티켓 생성
      await this.prismaService
        .$executeRaw`INSERT INTO UserTicket (userId, ticketId, quantity) VALUES (${userId}, ${ticketId}, ${ticket.quantity})`;

      // 1/10 확률로 오류 발생
      if (this.utilService.getRandom(9) === 9) {
        throw new Error('Random error');
      }
    } catch (e) {
      // 오류 발생시 롤백
      // 복구하는 사이에 다른 트랜잭션이 해당 데이터를 수정할 수 있다.
      // 원자성을 보장하는 연산으로만 복구 가능함
      await this.prismaService
        .$executeRaw`UPDATE Ticket SET quantity = quantity + 1 WHERE id = ${ticketId}`;
      await this.prismaService
        .$executeRaw`DELETE FROM UserTicket WHERE userId = ${userId} AND ticketId = ${ticketId} AND quantity = ${ticket.quantity}`;
      throw e;
    }
  }
}
```

## 비관적 락(Pessimistic Lock)

### 비관적 락이란

비관적 락은 데이터베이스 트랜잭션에서 데이터 접근을 제어하여 충돌을 방지하고 데이터 무결성을 보장하는 동시성 제어 전략이다. 이는 트랜잭션이 시작되기 전에 필요한 데이터에 대한 락을 획득하고, 트랜잭션 종료 시 락을 해제하는 방식으로 작동한다. 락을 획득하지 못한 트랜잭션은 대기 큐에 저장되고, 락이 해제되는 대기하게 된다.

### 비관적 락의 장점

- 데이터 무결성 보장: 데이터를 읽는 동안 다른 트랜잭션이 해당 데이터를 변경할 수 없어 일관성을 강력하게 보장한다.
- 데이터 손실 방지: 부분적으로 완료된 트랜잭션으로 인한 데이터 손실을 방지한다.

### 비관적 락의 단점

- 성능 저하: 잦은 락 획득/해제 작업으로 인해 시스템 성능이 저하될 수 있다.
- 데드락 발생 가능성: 여러 트랜잭션이 서로의 락을 잡고 있는 경우 데드락이 발생할 수 있다.

### 비관적 락이 적합한 경우

데이터의 무결성이 중요하고 충돌 가능성이 높은 금융 시스템과 같은 환경에서 사용한다.

### 코드 구현

티켓을 구매하면 (잔여갯수: quantity)를 줄이는 방식의 예제이다.

트랜잭션 안의 Select 구문에서 `SELECT .. FOR UPDATE` 구문으로 해당 행의 X락을 획득한다. X락을 획득하면 다른 트랜잭션에서 해당 행을 읽거나 쓸 수 없다.

```typescript
async buyTicket({ ticketId, userId }: { ticketId: number; userId: number }) {
  // 하나의 트랜잭션으로 처리
  await this.prismaService.$transaction(async (prisma) => {
    // 티켓 조회 (X락)
    const [ticket] = await prisma.$queryRaw<
      { quantity: number }[]
    >`SELECT quantity FROM Ticket WHERE id = ${ticketId} FOR UPDATE`;

    // 잔여 수량이 없으면 에러 발생
    if (ticket.quantity <= 0) {
      throw new Error('Ticket sold out');
    }

    // 해당 티켓 잔여수량 감소
    await prisma.$executeRaw`UPDATE Ticket SET quantity = ${ticket.quantity} - 1 WHERE id = ${ticketId}`;

    // 유저 티켓 생성
    await prisma.$executeRaw`INSERT INTO UserTicket (userId, ticketId, quantity) VALUES (${userId}, ${ticketId}, ${ticket.quantity})`;

    // 1/10 확률로 오류 발생
    if (this.utilService.getRandom(9) === 9) {
      throw new Error('Random error');
    }
  });
}
```

## 분산 락(Distributed Lock)

### 분산 락이란

분산 락은 여러 컴퓨터 또는 노드로 구성된 분산 시스템에서 공유 자원에 대한 동시 접근을 제어하는 메커니즘이다. 이는 데이터 무결성을 보장하고 경쟁 조건을 방지하는 데 중요한 역할을 한다.

### 분산 락의 장점

- 원자성 보장: 분산 환경에서 여러 서버가 공통된 자원에 접근할 때 원자성을 보장한다.
- 확장성: 서비스가 확장되어도 일관된 동시성 제어가 가능하다.

### 단점

- 구현 복잡성: 분산 락을 구현하고 관리하는 것은 복잡하며, 오류 발생 시 시스템 전체에 영향을 줄 수 있다.
- 부하: 락을 관리하는 외부 시스템에 부하가 집중될 수 있습니다.
- 정합성: 외부 시스템에 구현하기에 외부 시스템에 문제(브레인 스필릿 등)과 같은 문제가 생길 수 있다.

### 고려 사항

여러 서버가 동일한 자원에 접근해야 하는 대규모 분산 시스템에서 사용된다. 예를 들어, 선착순 신청 시스템과 같이 동시성 이슈에 민감한 도메인에서 유용하다.

### 코드 구현

티켓을 구매하면 (잔여갯수: quantity)를 줄이는 방식의 예제이다.

Redis의 Pub/Sub을 사용해 분산락을 구현하였으며 `tryLock` 함수로 언락에 관한 메시지를 구독하고 대기하고 언락 메시지를 받으면 락 획득을 시도한다. 이 과정에서 락을 획득하지 못하면 다시 언락 메시지를 받을 때 까지 대기한다.

```typescript
async buyTicket({ ticketId, userId }: { ticketId: number; userId: number }) {
  const lockKey = `lock:buyTicket:${ticketId}`;
  let lockValue: string | null = null;
  try {
    // 락 획득
    lockValue = await this.tryLock(lockKey, 500, 15000);

    // 티켓 조회
    const [ticket] = await this.prismaService.$queryRaw<
      { quantity: number }[]
    >`SELECT quantity FROM Ticket WHERE id = ${ticketId}`;

    // 잔여 수량이 없으면 에러 발생
    if (ticket.quantity <= 0) {
      throw new Error('Ticket sold out');
    }

    // 해당 티켓에 조회한 잔여 수량이 있으면 잔여수량 감소
    await this.prismaService
      .$executeRaw`UPDATE Ticket SET quantity = ${ticket.quantity} - 1 WHERE id = ${ticketId} AND quantity = ${ticket.quantity}`;

    try {
      // 유저 티켓 생성
      await this.prismaService
        .$executeRaw`INSERT INTO UserTicket (userId, ticketId, quantity) VALUES (${userId}, ${ticketId}, ${ticket.quantity})`;

      // 1/10 확률로 오류 발생
      if (this.utilService.getRandom(9) === 9) {
        throw new Error('Random error');
      }
    } catch (e) {
      // 오류 발생시 롤백 (해당 로우에 대한 락을 이미 가지고 있으므로 원자성을 보장 안해도 됨)
      await this.prismaService
        .$executeRaw`UPDATE Ticket SET quantity = ${ticket.quantity} + 1 WHERE id = ${ticketId}`;
      await this.prismaService
        .$executeRaw`DELETE FROM UserTicket WHERE userId = ${userId} AND ticketId = ${ticketId} AND quantity = ${ticket.quantity}`;
      throw e;
    }
  } finally {
    if (lockValue !== null) {
      // 언락
      await this.unlock(lockKey, lockValue);
    }
  }
}

// 락 획득 시도
private async tryLock(key: string, ttl: number, timeoutMs: number) {
  const value: string = new Date().getTime().toString();
  const startTime = new Date().getTime();

  // 락 후 락 여부 반환
  const lock = async (key: string, ttl: number) => {
    const result = await this.redisClient.set(key, value, {
      NX: true,
      PX: ttl,
    });
    return result === 'OK';
  };

  // 락획득할 때까지 반복
  while ((await lock(key, ttl)) === false) {
    // 언락 메시지 대기
    await this.waitUnlock(key, ttl);

    // 타임아웃 체크
    if (new Date().getTime() - startTime > timeoutMs) {
      throw new Error('timeout');
    }
  }

  return value;
}

// 언락 대기
private async waitUnlock(key: string, ttl: number) {
  try {
    await firstValueFrom(
      this.unlockSubject.pipe(
        filter((message) => message === key), // 락 키 값 필터
        timeout({
          each: ttl,
          with: () => throwError(() => new Error('timeout')),
        }), // ttl 동안 unlock 메시지가 오지 않으면 구독 중지
        take(1), // 1건 받으면 종료
      ),
    );
  } catch (e) {
    // ttl동안 unlock 메시지가 오지 않으면 재시도하기 위해 timeout 에러 무시
    // (구독 전에 언락 됬을 수도 있기 때문)
    if (e?.message !== 'timeout') {
      throw e;
    }
  }
}

// 언락
private async unlock(key: string, value: string) {
  // 키와 값이 일치할 때만 삭제하는 Lua 스크립트
  const script = `
  if redis.call("get",KEYS[1]) == ARGV[1] then
      return redis.call("del",KEYS[1])
  else
      return 0
  end
  `;

  // 언락
  const delCount = parseInt(
    (await this.redisClient.eval(script, {
      keys: [key],
      arguments: [value],
    })) as string,
  );

  if (delCount > 0) {
    // 언락 경우만 unlock 메시지 발행
    await this.redisClient.publish(this.UNLOCK_CHANNEL, key);
  }
}
```

# 결론

락(Lock)을 구현하는 방법은 여러가지가 있다. 공통적으로 자원 획득을 위한 락 및 언락에 대한 일관성이 보장되어야 하며 특정 작업이 언락을 하지 않아 무제한 점유를 할 수도 있기에 타임아웃 등으로 인한 강제 언락도 고려해야된다. 또한 어플리케이션의 상황에 따라 오버엔지니어링이 되지 않도록 적절한 락 방식을 구현해야한다.

그리고 위 예제들의 코드는 [Github 저장소](https://github.com/sdg9670/concurrency-controll-with-lock)에서 확인하고 테스트할 수 있다.
