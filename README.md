# MDB-KCP: Persistence Framework for In-Memory Database using CRIU-based Container Checkpoint in Kubernetes

> SCIE 저널 논문 게재  
> Journal of Cloud Computing (Springer)  
> "MDB-KCP: Persistence Framework of In-Memory Database with CRIU-based Container Checkpoint in Kubernetes"
>
> DOI: https://doi.org/10.1186/s13677-024-00687-9
---

## 1. 연구 배경

In-Memory Database는 높은 성능을 제공하지만, 프로세스 종료 또는 Pod 재시작 시 데이터가 소실되는 휘발성 특성을 가진다.

Kubernetes 환경에서 Redis와 같은 In-Memory DB는 일반적으로 다음과 같은 방식으로 영속성을 보장한다:

- RDB (SAVE / BGSAVE)
- AOF (Append Only File)
- Volume 기반 스토리지

그러나 이러한 방식은 다음과 같은 한계를 가진다:

- 복구 시 데이터 재로딩으로 인한 긴 복구 시간
- SAVE 수행 시 서비스 중단
- BGSAVE 수행 시 Copy-on-Write 메모리 오버헤드
- StatefulSet 기반 재시작 시 cold restart 문제

본 연구는 이러한 한계를 해결하기 위해
**CRIU 기반 컨테이너 체크포인트를 활용한 In-Memory Database Persistence Framework (MDB-KCP)** 를 제안한다.

---

## 2. 제안 방식 (MDB-KCP)

MDB-KCP는 Kubernetes 환경에서 컨테이너 단위 체크포인트를 수행하여 In-Memory DB의 프로세스 상태를 그대로 보존한다.

### 핵심 아이디어

- CRIU를 활용하여 프로세스 메모리 상태를 dump
- 파일 디스크립터 및 네임스페이스 상태까지 포함
- 체크포인트 결과를 TAR로 생성 후 OCI 이미지로 변환
- 복구 시 메모리 로딩 과정 없이 즉시 서비스 가능

즉, 단순 데이터 파일 저장이 아니라 **프로세스 상태 기반 Persistence 전략**을 적용하였다.

---

## 3. 시스템 아키텍처

1. Redis Pod 실행
2. Checkpoint 트리거 발생
3. CRIU 기반 컨테이너 상태 저장
4. TAR 이미지 생성
5. OCI 이미지 변환
6. 필요 시 해당 이미지로 컨테이너 복구

이 방식은 Kubernetes 환경에서 In-Memory DB의 새로운 백업 및 복구 전략을 제시한다.

---

## 4. 실험 구성

### Testbed Setup

| Category | Specification |
|----------|--------------|
| Cluster Configuration | Single-node Kubernetes cluster |
| CPU | Intel Xeon Silver 4208 @ 2.10 GHz |
| CPU Cores | 8 Physical Cores / 16 Logical Cores (Hyper-Threading Enabled) |
| Storage | Dell 2TB 7.2K RPM SATA 6Gbps 512n HDD |
| Operating System | CentOS 9 |
| Kernel Version | Linux Kernel 5.14 |
| Kubernetes Version | v1.28.1 |
| Container Runtime | CRI-O |



### Application Setup

| Category | Specification |
|----------|--------------|
| In-Memory Database | Redis 7.2.1 |
| Persistence Mechanism | RDB (Redis Database Snapshot) |
| Data Loading Method | Redis `DEBUG POPULATE` |
| Dataset Sizes | 10M, 20M, 40M, 80M, and 160M records |

---



## 5. 실험 1 — 워크로드별 메모리 오버헤드 분석

Read/Write 비율을 변경하며 기존 In-Memory DB의 영속성 유지 방식이 메모리 사용량에 미치는 영향을 분석하였다.

#### https://github.com/jeongmin99/MDB-KCP/tree/main/experiments/01_cow_memory_overhead/README.md

### 결과 요약

- 레코드 수가 증가할수록 **CoW 메모리 오버헤드 증가**
- Update 비율이 높을수록 **추가 메모리 사용량 급증**
- Write 중심 워크로드에서 **메모리 증폭 현상이 가장 크게 발생**

> 즉, fork 기반 체크포인트는 write-intensive 환경에서  
> 상당한 메모리 부담을 유발할 수 있음을 확인하였다.

이를 통해 Kubernetes 환경에서의 In-Memory DB 영속성 유지 시 자원 사용 특성을 정량적으로 분석하였다.

---

## 6. 실험 2 — SAVE / BGSAVE / MDB-KCP 비교

Redis 기본 Persistence 전략과 MDB-KCP를 비교하였다.

#### https://github.com/jeongmin99/MDB-KCP/tree/main/experiments/02_checkpoint_comparison/README.md 

### 비교 대상

- SAVE
- BGSAVE
- MDB-KCP

### 주요 비교 항목

- 체크포인트 생성 시간
- 서비스 다운타임
- 복구 시간

### 결과 요약

- SAVE → 다운타임이 가장 큼
- BGSAVE → 서비스 유지 가능하나 메모리 오버헤드 존재
- MDB-KCP → 생성 시간은 길지만 복구 속도 우수

특히 MDB-KCP는 기존 RDB 기반 방식 대비 **최대 11.3배 빠른 복구 속도**를 보였다.

이는 복구 시간(RTO)을 단축하는 전략으로서 운영 환경에서 큰 의미를 가진다.

---

## 7. 연구의 의의

본 연구는 단순한 성능 개선이 아니라,

- Kubernetes 환경에서의 In-Memory DB의 백업 및 복구 전략 제시
- 컨테이너 레벨 상태 복구 메커니즘 검증
- 복구 시간 중심 Persistence 전략 비교 분석

이라는 점에서 의미를 가진다.

특히, RTO가 중요한 실시간 서비스 환경에서 컨테이너 체크포인트 기반 Persistence의 가능성을 실험적으로 입증하였다.

---

## 8. 기술적으로 배운 점

본 연구를 통해 다음을 깊이 이해하게 되었다:

- Linux 프로세스 구조 및 메모리 관리
- CRIU 동작 원리
- Container Runtime과 Kubernetes의 상호작용
- Copy-on-Write 메커니즘
- Stateful 서비스의 복구 전략 설계
- 운영 관점에서의 가용성(RTO) 분석

---

## 9. 한계 및 향후 연구

- 체크포인트 생성 시 이미지 변환 오버헤드 존재
- 커널 및 런타임 의존성 문제
- 대규모 분산 환경에서의 확장성 검증 필요

향후 연구에서는 자동화된 스케줄링 전략 및 대규모 클러스터 환경에서의 적용 가능성 검증이 필요하다.

---

## 10. 결론

MDB-KCP는 Kubernetes 환경에서 In-Memory Database의 휘발성 문제를 해결하기 위한 컨테이너 기반 Persistence Framework이다.

전통적인 파일 기반 스냅샷 방식과 달리, 프로세스 상태 기반 복구 전략을 적용함으로써 복구 시간 단축이라는 운영상의 이점을 확인하였다.

---


