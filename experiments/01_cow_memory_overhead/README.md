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
- YCSB Redis Binding 사용
- thread count: 16으로 고정

thread 수를 16으로 고정한 이유는 체크포인트 수행 중 데이터베이스에 생성되는 명령 수를 일정하게 유지하기 위함이다.

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
