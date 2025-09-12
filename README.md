# OpenTitan Linting Notes (using fusesoc) (I2C IP)

This document captures the issues I faced while performing lint analysis on the I²C IP core in OpenTitan, along with the fixes I applied. It serves as a reference for future debugging.

---

## 1. Environment Setup

- Cloned the OpenTitan repo:
  ```bash
  git clone https://github.com/lowRISC/opentitan.git
Created a Python virtual environment and installed dependencies from:

Copy code
python-requirements.txt
Installed tools like FuseSoC, Verilator, and required Python packages:

mako, semantic_version, tabulate, mistletoe, etc.

## 2. Running Lint on the I²C Core
Ran:

bash
fusesoc --cores-root . run --target=lint lowrisc:ip:i2c:0.1
Faced multiple dependency errors (missing packages or cores).

## 3. Debugging Core Dependency Errors

Example Error

❌ PKGNODECL: Package/class 'top_pkg' not found


Cause
The required package wasn’t listed in the "depend:" section of i2c.core.

Fix

Found which core provides top_pkg:

fusesoc list-cores | grep top_pkg


Added the correct core: lowrisc:earlgrey_constants:top_pkg:0 to the dependency list in i2c.core.

## 4. Dependency Resolution (General Case)

When linting an IP core, FuseSoC first loads the dependencies declared in the .core file.
If the source RTL (i2c.sv) imports a package or module that isn’t found in any dependency, FuseSoC/Verilator throws an error.

Example Error

❌ src/lowrisc_ip_i2c_0.1/rtl/i2c.sv:30:10: 
Package/class 'prim_alert_pkg' not found, and needs to be predeclared


Fix

Identify where the package exists:

fusesoc list-cores | grep prim_alert


Add the correct dependency (e.g. lowrisc:prim:prim_alert_pkg:0.1) to i2c.core.

## 5. Example: Missing Variable (NumLcStates)

Error

❌ Can't find definition of variable: 'NumLcStates'


Root Cause

The i2c.core depended on lc_ctrl_pkg, but the corresponding .core file didn’t include the RTL file that defines NumLcStates.

That definition exists inside lc_ctrl_state_pkg.

Fix

Updated lc_ctrl_pkg.core to include the missing RTL file.

After this change, Verilator was able to see the definition and the error was resolved.

## 6. The .tpl File Problem

After fixing the dependency, a new issue appeared:

Error

❌ hw/ip/lc_ctrl/rtl/lc_ctrl_state_pkg.sv.tpl
Templates (.tpl) must be expanded into .sv before tools like Verilator can use them.

## 7. Generating .sv from .tpl
There are two ways to generate the final lc_ctrl_state_pkg.sv:

✅ A. OpenTitan’s Normal Flow (Recommended)
OpenTitan uses Bazel to generate auto-generated RTL.

Run:

bash
./bazelisk.sh build //hw/ip/lc_ctrl:all
Then search for the generated file:

find bazel-out/ -name "lc_ctrl_state_pkg.sv"
⚙️ B. Manual Flow with regtool.py
regtool.py in util/ can also process .hjson configs and templates.

Example:

./util/regtool.py -r hw/ip/lc_ctrl/data/lc_ctrl_state.hjson --outdir hw/ip/lc_ctrl/rtl/
This writes the generated lc_ctrl_state_pkg.sv into:

hw/ip/lc_ctrl/rtl/
⚠️ Note:
In my case, this failed with schema errors (missing name, cip_id, bus_interfaces, …).
That’s because lc_ctrl_state.hjson isn’t a simple register map but a state encoding config.
➡️ This means only Bazel (or CI pre-generated outputs) can reliably generate the final .sv file.

## 8. Key Takeaways
Always check dependencies with:

fusesoc list-cores | grep <keyword>
Update .core files when dependencies are missing.

Some variables/packages are not directly in .sv files but auto-generated from templates.

For those, prefer Bazel build flow to generate the final .sv.
