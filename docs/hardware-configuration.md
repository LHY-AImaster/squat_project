# 🔌 Hardware Configuration

본 문서는 SquatMate의 허리 및 허벅지 측정 모듈의 하드웨어 구성, 센서 연결 방식, Bluetooth 통신 프로토콜을 설명합니다.

## 1. Hardware Overview

SquatMate는 허리와 허벅지의 움직임을 각각 측정하기 위해 두 개의 독립적인 센서 모듈을 사용합니다.

| 구분 | 하드웨어 구성 |
|---|---|
| 허리 측정 모듈 | Arduino Uno + MPU6050 + BT-05 |
| 허벅지 측정 모듈 | Arduino Nano + MPU6050 + BT-05 |

각 모듈은 MPU6050을 통해 가속도 데이터를 수집하고, BT-05 블루투스 모듈을 통해 스마트폰으로 전송합니다.

두 모듈은 독립적으로 데이터를 수집하고 전송하며, 앱에서는 패킷에 포함된 식별자를 기준으로 허리와 허벅지 데이터를 구분합니다.

### Actual Hardware

| Waist Sensor Module                             | Thigh Sensor Module                              |
|-------------------------------------------------|--------------------------------------------------|
| ![Waist Sensor](docs/images/waistUnoSensor.jpg) | ![Thigh Sensor](docs/images/thighNanoSensor.jpg) |
| Arduino Uno + MPU6050 + BT-05                   | Arduino Nano + MPU6050 + BT-05                   |

## 2. Circuit & Pin Configuration

두 측정 모듈은 동일한 연결 구성을 사용합니다. 각 센서와 블루투스 모듈은 해당 Arduino 보드의 전원 및 통신 핀에 연결됩니다.

### MPU6050 Connection

| MPU6050 Pin | Arduino Pin | 설명 |
|---|---|---|
| VCC | 5V | 전원 공급 |
| GND | GND | 공통 접지 |
| SDA | A4 | I2C 데이터 |
| SCL | A5 | I2C 클럭 |

MPU6050은 I2C 통신을 통해 가속도 데이터를 전달합니다. 각 Arduino에 센서가 하나씩 연결되어 있으므로 기본 I2C 주소인 `0x68`을 사용합니다.

### BT-05 Connection

| BT-05 Pin | Arduino Pin | 설명 |
|---|---|---|
| VCC | 5V | 전원 공급 |
| GND | GND | 공통 접지 |
| TXD | D2 | Arduino 수신(RX) |
| RXD | D3 | Arduino 송신(TX) |

블루투스 통신에는 `SoftwareSerial(2, 3)`을 사용합니다. Arduino의 D2를 수신 핀으로, D3을 송신 핀으로 설정하여 PC 디버깅용 하드웨어 시리얼과 Bluetooth 통신을 분리했습니다.

현재 BT-05의 RXD와 Arduino D3은 별도의 전압 분배 회로 없이 직접 연결되어 있습니다. 다만 BT-05 기판의 입력 허용 전압에 따라 5V 신호가 부담이 될 수 있으므로, 향후 모듈의 전기적 사양을 확인하고 적절한 전압 변환 회로를 적용할 필요가 있습니다.

## 3. Bluetooth Communication Protocol

각 Arduino는 센서에서 읽은 X, Y, Z축 가속도 데이터를 정해진 패킷 형식으로 Bluetooth를 통해 전송합니다.

### Packet Format

| 구분 | 허리 모듈 | 허벅지 모듈 |
|---|---|---|
| 패킷 식별자 | `$W` | `$T` |
| 데이터 형식 | `$W\|x,y,z` | `$T\|x,y,z` |
| 전송 속도 | 9600 baud | 9600 baud |
| 데이터 전송 간격 | 약 20ms | 약 20ms |

패킷 예시는 다음과 같습니다.

```text
$W|1.23,0.45,9.81
$T|-0.12,4.56,8.90
```

### Packet Delimiter

| 구분자 | 의미 | 설명 |
|---|---|---|
| `$` | 패킷 시작 | 새로운 데이터 패킷의 시작 |
| `W`, `T` | 센서 식별자 | 허리 또는 허벅지 데이터 구분 |
| `\|` | 데이터 구분자 | 센서 식별자와 가속도 데이터 분리 |
| `,` | 축 구분자 | X, Y, Z축 데이터 구분 |
| 줄바꿈 | 패킷 종료 | `println()`을 통해 한 줄의 데이터 전송 완료 |

앱에서는 패킷 식별자를 확인하여 허리와 허벅지 데이터를 구분하고, 쉼표를 기준으로 각 축의 가속도 값을 파싱합니다.

### Sampling Interval

Arduino 펌웨어에서는 `delay(20)`을 사용하여 데이터 전송 사이에 약 20ms의 대기 시간을 설정했습니다.

이를 기준으로 이론상 약 50Hz의 데이터 수집 및 전송 주기를 목표로 합니다.

실제 수신 주기는 센서 데이터 읽기, 시리얼 전송 및 Bluetooth 통신 처리 시간에 따라 달라질 수 있습니다.

## 4. Design Considerations

### Independent Sensor Modules

초기에는 하나의 Arduino Nano에 두 개의 MPU6050을 연결하는 구조를 고려했습니다. 이 방식에서는 두 센서의 I2C 주소를 `0x68`과 `0x69`로 분리하여 하나의 I2C 버스에서 구분할 수 있습니다.

그러나 개발 과정에서 허리와 허벅지 센서를 각각 독립적인 Arduino와 Bluetooth 모듈에 연결하는 구조로 변경했습니다.

최종적으로 허리에는 Arduino Uno, 허벅지에는 Arduino Nano를 사용했으며, 이는 특정 보드 조합이 필수였기 때문이 아니라 개발 당시 보유하고 있던 하드웨어를 활용한 결과입니다.

### Future Improvement

현재 구조에서 Arduino는 센서의 가속도 데이터를 수집하고 Bluetooth를 통해 스마트폰으로 전달하는 역할을 담당합니다.

향후에는 필요한 센서 연결 및 통신 기능을 충족하는 더 저렴한 마이크로컨트롤러를 검토하여 하드웨어 비용을 줄일 수 있습니다. 이는 향후 개선 가능성으로, 현재 구현하거나 성능을 검증한 사항은 아닙니다.