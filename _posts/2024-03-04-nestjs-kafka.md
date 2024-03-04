---
title: "Nest.js에서 Kafka 사용하기"
categories:
  - nodejs
tags:
  - nodejs
  - nestjs
  - microservice
  - kafka
last_modified_at: 2023-03-04T20:00:00+09:00
---

![](/assets/images/posts/2024-03-04-nestjs-kafka-1.png)

# Nest.js에서 Kafka를 사용하려면?

Nest.js에서 Microservice 패키지에 Kafka가 포함되어 있다. ([공식문서](https://docs.nestjs.com/microservices/kafka)) 내부적으로 Kafka.js를 사용하므로 Kafka.js도 설치가 필요하다.

```bash
$ npm install @nestjs/microservices kafkajs
```

# Nest.js 앱에 Kafka 연결

우선 Nest.js 앱에 Kafka를 연결해야된다. 기존 웹 앱에 Nest.js의 Microservice를 사용하겠다.

```typescript
// src/constants.ts
const KAFKA_OPTION: KafkaOptions = {
  transport: Transport.KAFKA,
  options: {
    client: {
      clientId: "nestjs",
      brokers: ["localhost:9092"],
    },
    consumer: {
      groupId: "nestjs-consumer",
    },
  },
};

// src/main.ts
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  // Kafka 등록
  app.connectMicroservice<MicroserviceOptions>({
    ...KAFKA_OPTION,
  });
  await app.listen(3000);
}
```

Consumer 그룹과 client 이름은 접미사 `-server`가 붙어 `nestjs-consumer-server`, `nestjs-server`로 생성된다. 위와 같이 등록한 Kafka는 `@MessagePattern`, `@EventPattern` 데코레이션 함수에 쓰인다.

# Kafka Client 구현

메시지를 생산하기 위해 사용된다. `ClientModule.register`로 모듈에 import하면 된다.

```typescript
// src/app.module.ts
@Module({
  imports: [
    ClientsModule.register([
      {
        name: 'KAFKA_CLIENT',
        transport: Transport.KAFKA,
        options: KAFKA_OPTION,
      },
    ]),
  ],
  ...
})
export class AppModule {}
```

위와 같이 import하면 `@Inject("KAFKA_CLIENT")`로 사용할 수 있다. 또한 consumer 그룹과 클라이언트 이름은 접미사 `-client`가 붙어 `nestjs-consumer-client`, `nestjs-client`로 생성된다.

# 메시지 생산

http 요청이 들어오면 메시지가 생산하도록 만들어 보자. 아래의 3가지 기능을 만들 것이다.

- 숫자들의 최댓값을 응답하는 `max`
- 숫자들의 합을 응답하는 `sum`
- 콘솔에 메시지를 출력하는 `print`

## 의존성 주입 및 클라이언트 초기화 (connect & close)

일단 생성자에 kafkaClient를 사용하기 위해 의존성을 주입한다.

```typescript
// src/app.controller.ts
constructor(
  @Inject('KAFKA_CLIENT') private readonly kafkaClient: ClientKafka,
) {}
```

`onModuleInit`, `onModuleDestroy`에서 클라이언트를 초기화 할 것이다. implement하도록 한다.

```typescript
// src/app.controller.ts

export class AppController implements OnModuleInit, OnModuleDestroy {
  ...
  async onModuleInit(): Promise<void> {
    const topics = ['sum', 'max'];
    topics.forEach((topic) => this.kafkaClient.subscribeToResponseOf(topic));
    await this.kafkaClient.connect();
  }

  async onModuleDestroy(): Promise<void> {
    await this.kafkaClient.close();
  }
  ...
}
```

위 코드에서 `subscribeToResponseOf` 함수가 있다. 이 함수는 해당 topic에 생산된 메시지의 reply topic을 구독한다. `this.kafkaClient.subscribeToResponseOf('sum')` 코드는 접미사 `.reply`가 붙어 `sum.reply`를 구독하는 코드가 된다.

## 메시지 생산을 위한 HTTP 요청 함수 작성

3가지의 함수(max, sum, print)를 작성했다. kafkaClient의 `send`, `emit`으로 메시지를 생산한다.

- send: 메시지를 생산하고 구독한 reply topic의 소비를 대기하고 반환한다.
- emit: 메시지를 생산하고 생산한 메시지에 대한 메타데이터를 반환한다.

Nest.js의 경우 Rxjs의 Observable로도 응답이 가능하다.

```typescript
// src/app.controller.ts

/* return Observable<number> */
@Post('sum')
sum(@Body() body: number[]): Observable<number> {
  return this.kafkaClient.send<number>('sum', { value: body });
}

/* return Promise<number> */
@Post('max')
async max(@Body() body: number[]): Promise<number> {
  const response = await lastValueFrom(
    this.kafkaClient.send<number>('max', { value: body }),
  );

  return response;
}

@Post('print')
print(
  @Body() { message }: { message: string },
): Observable<RecordMetadata[]> {
  return this.kafkaClient.emit<RecordMetadata[]>('print', { value: message });
}
```

send 함수로 메시지를 생산하면 메시지 헤더에 아래와 같은 정보가 같이 생산된다.

```typescript
{
  "kafka_replyPartition": "0",
  "kafka_correlationId": "128a3cea12fe99f96ac30",
  "kafka_replyTopic": "topic.reply"
}
```

해당 요청에 대한 reply 메시지를 찾기 위한 정보이다.

emit의 반환 값은 아래와 같다. 메시지에 대한 메타데이터를 반환한다.

```typescript
// RecordMetadata[]
{
  topicName: string
  partition: number
  errorCode: number
  offset?: string
  timestamp?: string
  baseOffset?: string
  logAppendTime?: string
  logStartOffset?: string
}[]
```

# 메시지 소비

메시지를 소비하는 코드는 별도의 controller(app.message.controller.ts)로 작성했다. 같은 Nest.js 앱이 아닌 생산, 소비가 분리된 앱이여도 적용이 가능하다.

## 의존성 주입 및 클라이언트 초기화 (connect & close)

Reply topic을 구독할 필요가 없기에 `subscribeToResponseOf` 함수는 사용하지 않았다.

```typescript
// src/app.message.controller.ts
export class AppMessageController implements OnModuleInit, OnModuleDestroy {
  constructor(
    @Inject('KAFKA_CLIENT') private readonly kafkaClient: ClientKafka,
  ) {}

  async onModuleInit(): Promise<void> {
    await this.kafkaClient.connect();
  }

  async onModuleDestroy(): Promise<void> {
    await this.kafkaClient.close();
  }
  ...
}
```

## 메시지 소비 및 응답 생성을 위한 함수 작성

Topic에 대한 메시지를 소비하려면 2가지 데코레이터(`@MessagePattern`, `@EventPattern`)이 사용된다.

- @MessagePattern: 해당 topic을 소비하고 반환 값을 reply topic에 생산한다.
- @EventPattern: 해당 topic을 소비한다. 자체적으로 메시지를 생산하지는 않는다. (이벤트 기반 통신에 적합)

```typescript
// src/app.message.controller.ts

@MessagePattern('sum')
replySum(@Payload() message: number[]): number {
  return message.reduce((a, b) => a + b);
}

@MessagePattern('max')
replyMax(@Payload() message: number[]): number {
  return Math.max(...message);
}

@EventPattern('print')
printEvent(@Payload() message: string): void {
  console.log('print:', message);
}
```

MessagePattern에서 생성된 메시지의 헤더에는 아래와 같은 값이 들어있다.

```json
{
  "kafka_correlationId": "128a3cea12fe99f96ac30",
  "kafka_nest-is-disposed": "\u0000"
}
```

이로서 Nest.js의 Kafka client에서 send 함수의 비밀을 알 수 있다. 생산한 메시지의 헤더의 값들을 기준으로 응답 값을 찾을 수 있는 것이다. Reply topic의 `kafka_correlationId` 값이 같은 것을 반환하는 것이다.

## 수동 commit

기본적으로 auto commit이 활성화되어 있다. 수동으로 옵션을 변경해서 수동으로 commit 할 수 있다.

```typescript
// src/constants.ts
export const KAFKA_OPTION: KafkaOptions["options"] = {
  client: {
    clientId: "nestjs",
    brokers: ["localhost:9092"],
  },
  consumer: {
    groupId: "nestjs-consumer",
  },
  run: {
    autoCommit: false, // Auto commit 비활성화
  },
};
```

수동으로 커밋하려면 `@Ctx` 데코레이터로 message의 context를 가져와야 된다. 위 print topic을 예제로 들겠다.

```typescript
  @EventPattern('print')
  async printEvent(
    @Payload() message: string,
    @Ctx() context: KafkaContext,
  ): Promise<void> {
    console.log('print:', message);
    const { offset } = context.getMessage();
    const partition = context.getPartition();
    const topic = context.getTopic();
    await this.kafkaClient.commitOffsets([{ topic, partition, offset }]);
  }
```

현재 topic, partition, offset 정보를 받아서 `commitOffsets`함수로 커밋한다.

# 예제 프로젝트

위 내용에 대한 전체 코드는 Github에 공개되어 있으므로 참고하면 좋을 것이다. Kafka, Kafka UI도 도커로 작성해두었다. 간단히 설치하고 실습해볼 수 있다.

[nestjs-kafka](https://github.com/sdg9670/nestjs-kafka)

# 마치며

위 기능을 사용하면 Event driven 아키텍처를 쉽게 구현할 수 있다. Nest.js에 Kafka뿐만 아니라 마이크로서비스를 위한 많은 기능들이 있다. 다른 기능들도 참고하면 좋을 것 같다.

# 참고

- [Nest.js Kafka 공식 문서](https://docs.nestjs.com/microservices/kafka)
- [Nest.js Github Integration 테스트 코드](https://github.com/nestjs/nest/tree/master/integration/microservices/src)
