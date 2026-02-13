# FCP6 Protocol

FCP6 is a custom high-speed half-duplex communication protocol designed for FPGA-based systems.  
The protocol enables framed data transfer between a master and slave using only six physical pins.

It is intended for low-pin-count, high-speed, point-to-point communication where a full parallel bus is not practical.

---

## Protocol Overview

FCP6 is a synchronous, master–slave, packet-based communication protocol operating in half-duplex mode.  
The protocol uses a small number of dedicated control and data pins while maintaining deterministic framed transactions.

The communication direction is controlled through a two-bit control bus, and data is transferred in framed packets.

The protocol supports both read and write operations within the same physical interface.

---

## Physical Interface

The protocol uses six physical pins:

- P0 : Clock
- P1 : CTRL0
- P2 : CTRL1
- P3 : ACK/NACK
- P4 : DATA1
- P5 : DATA2 

---

## Control Bus Encoding

The two control lines define the bus state.

CTRL1 CTRL0 = 00 represents bus free or idle state.  
CTRL1 CTRL0 = 01 indicates master owns the bus and performs a write transaction.  
CTRL1 CTRL0 = 10 indicates slave owns the bus and performs a read transaction.  
CTRL1 CTRL0 = 11 represents end-of-frame or stop condition.

The device that owns the bus is responsible for driving the control lines. 
---

## Frame Format

Each transaction begins with a header field.

The header contains a 7-bit data length field and a 1-bit read/write indicator.

Bits [7:1] represent the data size.  
Bit [0] indicates the operation type, where 0 represents read and 1 represents write.

---

## Write Transaction

In a write transaction, the master sends data to the slave.

The master transitions through the following states:  
IDLE, TAKE, HEADER, WAIT_ACK, DECIDE, SEND_DATA, STOP, DONE.

The slave transitions through:  
IDLE, HEADER, ACK, DECIDE, RECV_DATA, STOP, DONE.

---

## Read Transaction

In a read transaction, the slave sends data to the master.

The master transitions through:  
IDLE, TAKE, HEADER, WAIT_ACK, DECIDE, RELEASE, RECV_DATA, STOP, DONE.

The slave transitions through:  
IDLE, HEADER, ACK, DECIDE, SEND_DATA, STOP, DONE. 

---

## Data Transfer Method

The protocol uses dual-edge data transfer, allowing data to be transferred on both clock edges.  
This increases effective throughput without increasing the clock frequency.

Communication is strictly half-duplex, meaning only one side transmits data at a time.

The protocol uses framed packets with explicit start, header, data, and stop phases.

---

## Repository Structure

fcp6-protocol/

- rtl/ : Protocol RTL implementation
- tb/ : Testbenches for protocol verification
- diagrams/ : Protocol diagrams and design sketches
- README.md : Project documentation
- new_notes.txt : Development notes
- work_log.odt : Work log

---

## Development Status

The RTL implementation is currently under active development. 

---

## Simulation

The protocol can be simulated using standard Verilog simulation tools.

Compile the RTL and testbench files.  
Run the simulation and observe protocol state transitions, control signals, and data transfer behavior.


## Design Characteristics

- Six-pin physical interface
- Half-duplex communication
- Master–slave architecture
- Framed packet protocol
- Dual-edge data transfer

---

## Future Work

- Complete RTL implementation
- Hardware validation on FPGA
- Error detection and retry mechanisms
- Throughput and timing optimization
