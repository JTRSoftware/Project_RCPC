# AlfaCalc - High-Precision Arbitrary Computing Engine

**AlfaCalc** is a professional-grade computing tool designed for high-performance arithmetic operations with virtually unlimited numerical precision. It serves as a specialized bridge between three distinct numbering systems, offering real-time synchronization and a robust "Infinity Display" interface.

Developed by **JTR Software**, AlfaCalc embodies the philosophy:  
> *"It is simple to look complicated, the complicated part is looking simple."*

---

## 🚀 Advanced Feature Set

### 1. The "Infinity Display" Architecture
Standard GUI labels fail when rendered with thousands of digits. AlfaCalc solves this using a custom-configured `TEdit` array (Decimal, Hex, and Alfadecimal) that provides:
- **Smooth Horizontal Scrolling**: Navigate millions of digits using arrow keys or mouse drag.
- **Copy-Paste Capability**: Directly copy extremely large values to use in other scientific or engineering tools.
- **Zero-Glitch Rendering**: Standard label flickering and truncation are eliminated.

### 2. Triple-Base Synchronized Engine
Perform a calculation in one base and see the conversion in the other two instantly:
- **Decimal (Base-10)**: Standard [0-9] arithmetic.
- **Hexadecimal (Base-16)**: [0-9][A-F] support for computer science applications.
- **Alfadecimal (Base-36)**: [0-9][A-Z] support, allowing for highly dense numerical representation.

### 3. Disk-Based "Swap" Arithmetic
When numbers become too large for standard memory buffers, AlfaCalc can utilize its unique **Swap Memory** system:
- It processes arithmetic using temporary file streams (`TFileStream`).
- Enables calculations that would normally crash standard calculator software due to RAM overflow.
- *Note: Multi-gigabyte calculations are supported in this mode.*

### 4. Performance & The "Turbo Mode"
Scientific computing is resource-heavy. AlfaCalc includes a **Performance Throttle (Auto-Convert Checkbox)**:
- **Enabled**: All three bases update in real-time as you type (ideal for small to medium values).
- **Disabled (Turbo)**: Only the active display updates, showing `🚫` in the inactive ones to prioritize CPU cycle for the main calculation. Conversion happens on-demand when switching bases.

---

## ⌨️ Keyboard Interface (Hotkeys)

AlfaCalc is designed for touch-typists and keyboard power users:
- **Numeric Input**: `0-9`, `A-F` (Hex), `G-Z` (Alfa).
- **Decimal Separator**: Both `.` and `,` are accepted.
- **Arithmetic Operators**: `+`, `-`, `*`, `/`.
- **Execution**: `Enter` or `=`.
- **Clear All (AC)**: `Escape` key.
- **Base Selection**: Use mouse interaction to lock/unlock numerical ranges.

---

## 🛠 Project Architecture (Unit Breakdown)

The engine is modularized into several high-performance Object Pascal units:
- `sMath.pas`: Core string-based Decimal arithmetic.
- `sHexMath.pas`: Specialized Base-16 logic.
- `sAlfaMath.pas`: Full Base-36 implementations.
- `sSwapMath / sHexSwapMath / sAlfaSwapMath`: Disk-based overflow handling using `TFileStream`.
- `uMainAlfa.pas`: Visual logic, keyboard hooking, and synchronized UI state management.

---

## 🛡️ Stability & Safety Features
1. **Scale Locking**: Once an operator is selected, the numerical base is locked to prevent logical errors during the calculation.
2. **Invalid Character Protection**: The UI automatically disables buttons and ignores keys that don't belong to the active base (e.g., typing 'Z' while in Decimal mode).
3. **Single Separator Enforcement**: Prevents accidental syntax errors by blocking multiple decimal points.

---

## 📦 How to Build

1. Download the **Lazarus IDE** (at least version 3.0+).
2. Ensure you have the project directory structure intact.
3. Open `AlfaCalc.lpi`.
4. Press `F9` (Compile and Run).

---
*KISS - Keep It Simple and Stable.*  
Project maintained for the **RCPC** repository.  
Copyright © 2026 **JTR Software**.
