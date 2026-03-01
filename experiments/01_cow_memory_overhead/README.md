# 01 — CoW 메모리 오버헤드 평가 실험

## 실험 목적

본 실험은 Kubernetes 환경에서 실행되는 컨테이너 기반 In-Memory 데이터베이스(Redis)의  
fork 기반 체크포인트 수행 시 발생하는 **Copy-on-Write(CoW)로 인한 추가 메모리 사용량** 을 정량적으로 분석하는 것을 목표로 한다.

**YCSB(Yahoo! Cloud Serving Benchmark)** 를 활용하여 다양한 read/write 비율의 워크로드를 생성하고,  
체크포인트 수행 중 발생하는 메모리 오버헤드를 측정하였다.

---

## 실험 환경

- 컨테이너 기반 Redis 배포
- Kubernetes 환경에서 실행
- Redis fork 기반 체크포인트 (BGSAVE)
- YCSB (Yahoo! Cloud Serving Benchmark) 사용


#### YCSB Tool Configuration

| Parameter           | Values                     |
|--------------------|---------------------------|
| Record Count       | 1M, 2M, 4M, 8M, 16M        |
| Update Ratio       | 10%, 50%, 90%              |
| Record Size        | Default (YCSB 기본값)      |
| Number of Threads  | 16                         |
| Distribution       | Zipfian                    |

---

## 실험 변수

다음 두 가지 변수를 조정하여 실험을 수행하였다.

1. 데이터 레코드 수 (record count)
2. 업데이트 연산 비율 (update ratio)

| 워크로드 유형 | Read 비율 | Update 비율 |
|--------------|-----------|------------|
| Read 중심   | 90%       | 10%        |
| 균형형       | 50%       | 50%        |
| Write 중심  | 10%       | 90%        |

레코드 크기는 YCSB 기본 설정값을 사용하였다.

---

## 수행 과정


### 1 단계 — YCSB를 이용한 Bulk Load

```bash
./bin/ycsb load redis \
  -s \
  -P workloads/workloada \
  -p redis.host=<REDIS_HOST> \
  -p redis.port=6379 \
  -p recordcount=<RECORD_COUNT> \
  -p threadcount=16
```

### 2 단계 — 워크로드 실행

예시: Read 50% / Update 50%

```bash
./bin/ycsb run redis \
  -s \
  -P workloads/workloada \
  -p redis.host=<REDIS_HOST> \
  -p redis.port=6379 \
  -p readproportion=0.5 \
  -p updateproportion=0.5 \
  -p threadcount=16
```

### 3 단계 — Fork 기반 체크포인트 수행

워크로드 실행 중 Redis의 fork 기반 체크포인트를 수행한다.

```bash
redis-cli BGSAVE
```

## 실험 결과

 Read 중심 워크로드 (Update 10%)

- 최대 **22% 추가 메모리 사용**
- 기존 Redis 인스턴스 메모리 사용량 대비 증가

균형형 워크로드 (Update 50%)

- 최대 **55% 추가 메모리 사용**

Write 중심 워크로드 (Update 90%)

- 최대 **70% 추가 메모리 사용**

---

## 주요 분석 결과

- 레코드 수가 증가할수록 **CoW 메모리 오버헤드 증가**
- Update 비율이 높을수록 **추가 메모리 사용량 급증**
- Write 중심 워크로드에서 **메모리 증폭 현상이 가장 크게 발생**

> 즉, fork 기반 체크포인트는 write-intensive 환경에서  
> 상당한 메모리 부담을 유발할 수 있음을 확인하였다.

---

## 시사점

Fork 기반 체크포인트는 서비스 중단 없이 스냅샷을 수행할 수 있다는 장점이 있다.

그러나 운영 인스턴스와 체크포인트 수행 인스턴스가 분리된 환경에서는 체크포인트 인스턴스의 일시적 중단이 서비스 가용성에 영향을 주지 않는다.

이러한 구조에서 fork 기반 체크포인트로 인한 높은 메모리 오버헤드를 감수하는 것은 비효율적이다.

따라서 운영 인스턴스와 체크포인트 인스턴스가 분리된 환경에서는  
보다 **메모리 효율적인 체크포인트/복구 메커니즘이 필요하다.**
