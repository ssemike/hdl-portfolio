# 8N1 UART Receiver

![tests](https://github.com/ssemike/hdl-portfolio/actions/workflows/tests.yml/badge.svg)

**What it is:** A parameterized 8N1 UART receiver (`uart_rx`) using 2-FF input synchronization and `OS_FACTOR` oversampling in Verilog.

**Why it matters:** Pairing a receiver with `uart_tx` completes full-duplex asynchronous serial communication and demonstrates midpoint sampling and framing-error detection.

## Interface

| Port | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `clk` | `input` | `1` | System clock input (active on rising edge) |
| `rst` | `input` | `1` | Synchronous active-high reset |
| `sample_tick` | `input` | `1` | Oversampling strobe (`OS_FACTOR` ticks per bit period) |
| `rx` | `input` | `1` | Asynchronous serial input line (idle high `1`) |
| `rx_data` | `output` | `DATA_BITS` | Received parallel word (LSB first); updated only on a valid frame |
| `rx_valid` | `output` | `1` | Single-cycle pulse (`1`) when a frame completes with a valid (high) stop bit |
| `frame_err` | `output` | `1` | Single-cycle pulse (`1`) when the stop bit is sampled low; `rx_data` is not updated |

## Design

- Synchronizes `rx` through two flip-flops (`rx_sync_0`, `rx_sync_1`) before FSM and shift logic.
- Confirms the start bit at half the oversampling count (a high line there is treated as a false start), samples data bits LSB-first at bit centers, and checks the stop bit.
- `rx_valid` and `frame_err` are both one-clock event pulses. A system that needs to remember an error should latch `frame_err` itself.

## Verification

- Lint-clean with `verilator --lint-only -Wall` (`make lint`).
- Self-checking testbench (`make test`) verifying reset, valid 8N1 frame reception (`8'hA5`), and stop-bit framing error detection.
- The testbench latches `rx_valid` and `frame_err` in a separate monitor while each frame is being sent, so their one-clock pulses cannot be missed.

## Results

- Prints `TEST PASSED` with 0 errors.

![UART RX waveform](docs/waveform.png)

## Limitations and next steps

- Fixed 8N1-style framing (no parity bit or FIFO); assumes `sample_tick` rate matches the sender's baud rate.
- After a framing error the line may still be low, and the receiver returns to idle straight away, so it can read that low level as a new start bit. A fuller design would wait for the line to return high before re-arming.
- Next: add a parity option, and a test with a small baud-rate mismatch between sender and receiver.
