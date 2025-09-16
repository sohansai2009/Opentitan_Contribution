# Proposal: I²C Glitch Filter for OpenTitan

## Overview
This repository documents my **proposed glitch filter design** for the [OpenTitan](https://opentitan.org) project.  
The goal of this work is to improve the robustness of the I²C core by filtering out short glitches on the **SCL** (clock) and **SDA** (data) lines before they are processed by the state machine.

This contribution is currently a **design proposal** and has not yet been submitted as a pull request.

---

## Motivation
The I²C bus is widely used but vulnerable to:
- Electrical noise and crosstalk.
- Switching transients from external devices.
- Spurious glitches on the SCL and SDA lines.

Without filtering, these glitches can cause:
- False START/STOP detection.
- Corrupted data transfers.
- Protocol-level errors.

A glitch filter mitigates these risks by ensuring that only **stable signals** are passed to the core logic.

---

## Design Concept
- **Input Sampling**: The SCL and SDA inputs are sampled every clock cycle.  
- **Stability Requirement**: A signal must remain stable for a programmable number of cycles before being accepted.  
- **Programmability**: Separate parameters are used for SCL (`n1`) and SDA (`n2`) to allow tuning.  
- **State Machine Based Filtering**: Dedicated FSMs monitor transitions and update outputs only when stability conditions are met.  

### Example Behavior
- If `n1 = 5` for SCL: the input must remain stable for 5 cycles to be recognized.  
- Any glitch shorter than 5 cycles is discarded.  
- The same applies for SDA with parameter `n2`.  

This ensures that only genuine bus events are considered by the I²C controller.

---

## Current Status
- The design has been completed and verified at the **standalone RTL level**.  
- No pull request has been opened yet in the OpenTitan repository.  

### Potential Next Steps
- Integrate the glitch filter into `i2c_core.sv`.  
- Add a configuration register in `i2c_reg_top.sv` to control filter duration.  
- Create testbenches to validate behavior under different noise/glitch scenarios.  
- Submit the design proposal for upstream review.  

---

## Learning Outcome
Through this project, I gained experience in:
- Designing **input filtering mechanisms** for communication protocols.  
- Understanding how small design changes can improve **system-level reliability**.  
- Working with FSM-driven designs as part of larger open-source IP cores.  

---

## Summary
This repository contains my **proposed glitch filter design** for OpenTitan’s I²C core.  
The design improves robustness against spurious noise on the SCL and SDA lines and serves as an exploration of how to strengthen I²C reliability in noisy environments.
