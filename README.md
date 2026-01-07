# YLink Protocol

YLink is a custom high-speed communication protocol designed to support half-duplex transfer using only 6 physical pins

## Physical Interface 
| Pin | Function |
|----|---------  |
| P0 | Clock	 |
| P1 | CTRL0 	 |
| P2 | CTRL1 	 |
| P3 | ACK/NACK  |
| P4 | DATA1 	 |
| P5 | DATA2 	 |

## Control Bus Encoding

| CTRL1 | CTRL0 | Meaning | State |
|-----|-----|----------------------------|------|
| 0 | 0 | Bus Free | IDLE |
| 0 | 1 | Master Owns Bus (Write) | WRITE (M → S) |
| 1 | 0 | Slave Owns Bus (Read) | READ (S → M) |
| 1 | 1 | End Of Frame | STOP |

**Rule:** Whoever owns the bus drives the CTRL lines.

## Frame Format

| Bit | Description |
|----|-------------|
| [7:1] | Data Size (7-bit length field) |
| [0] | R/W (0 = Write, 1 = Read) |

## Write Transaction Flow (Master → Slave)

**Master FSM**
IDLE → TAKE → HEADER → WAIT_ACK → DECIDE → SEND_DATA → STOP → DONE

**Slave FSM**
IDLE → HEADER → ACK → DECIDE → RECV_DATA → STOP → DONE

## Read Transaction Flow (Slave → Master)

**Master FSM**
IDLE → TAKE → HEADER → WAIT_ACK → DECIDE → RELEASE → RECV_DATA → STOP → DONE  

**Slave FSM**
IDLE → HEADER → ACK → DECIDE → SEND_DATA → STOP → DONE

## Features
- Dual-edge data transfer
- Half duplex modes
- Framed packet based communication
- Master–Slave architecture

## Status
Specification & RTL under active development.

Author : Yash 
