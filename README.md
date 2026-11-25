# HDL Portfolio

![tests](https://github.com/ssemike/hdl-portfolio/actions/workflows/tests.yml/badge.svg)

Synthesisable Verilog modules, each verified with a self-checking testbench in Icarus Verilog and checked with Verilator lint. I built them as self-study (October–November 2026), moving from board-level hardware and embedded firmware towards analogue and mixed-signal IC design. The interface blocks were chosen because they are the digital side of the power-management and sensor chips I work with.

## Modules

| Module | What it shows | Why it matters |
| :--- | :--- | :--- |
| [`alu`](rtl_alu/alu) | Parameterised combinational ALU with flags; exhaustive test at N = 4, 1,000 seeded random vectors at N = 8 | Datapath basics and exhaustive self-checking verification |
| [`counter`](rtl_counter/counter) | Synchronous counter with reset and parallel load | Timing and sequencing in control logic |
| [`tick_gen`](rtl_tick_gen/tick_gen) | Periodic single-cycle strobe | Clock enables that let slower logic run in one clock domain |
| [`debouncer`](rtl_debouncer/debouncer) | Tick-driven debouncer with a two-flip-flop synchroniser | Bringing an asynchronous input safely into a clocked design |
| [`pwm`](rtl_pwm/pwm) | Programmable period and duty cycle | The digital half of a DC-DC converter or motor controller |
| [`uart_tx`](rtl_uart_tx/uart_tx) | 8N1 transmitter driven by a baud strobe | Serial debug and telemetry links |
| [`uart_rx`](rtl_uart_rx/uart_rx) | 8N1 receiver with oversampling, mid-bit sampling and framing-error detection | Receiving from an asynchronous sender |
| [`spi_master`](rtl_spi_master/spi_master) | Full-duplex SPI master, configurable width and clock divider | How ADCs and sensor front ends are read |
| [`i2c_master`](rtl_i2c_master/i2c_master) | Single-byte I2C write with START/STOP framing and ACK checking | How PMICs, fuel gauges and sensors are configured |

Each module folder holds `rtl/` (design), `tb/` (testbench), `docs/` (waveform screenshot), a `Makefile` and a README with the interface, design notes, verification and limitations.

## Running the tests

Requirements: [Icarus Verilog](https://github.com/steveicarus/iverilog), [Verilator](https://www.veripool.org/verilator/) and `make` (tested on Ubuntu under WSL2).

```bash
make lint    # Verilator lint on every module
make test    # build and run every testbench
```

Each testbench compares the design against expected values, counts errors and prints `TEST PASSED` or `TEST FAILED`. `make test` fails if any module does not print `TEST PASSED`. GitHub Actions runs the same tests on every push.

To run a single module, `cd` into its folder, for example `rtl_pwm/pwm`, and run `make test`.

## Repository layout

```text
hdl-portfolio/
├── Makefile                    runs lint/test across all modules
├── .github/workflows/tests.yml
└── rtl_<module>/<module>/
    ├── rtl/      design
    ├── tb/       self-checking testbench
    ├── docs/     waveform screenshot
    ├── Makefile
    └── README.md
```

## Next

Next I'm moving to transistor-level analogue design with open-source tools (xschem, ngspice, Magic, Netgen) on the GF180MCU process. That work will go in a separate repository.
