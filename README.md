# OpenTitan Linting Notes (I2C IP)


This document captures the issues I faced while performing lint analysis on the I²C IP core in OpenTitan, along with the fixes I applied. It serves as a reference for future debugging.

---

## 1. Dependency Resolution

When linting an IP core, FuseSoC first loads the **dependencies** declared in the `.core` file. Each dependency may contain its own RTL files and packages.  
If the source RTL (`i2c.sv`) imports a package or module that isn’t found in any dependency, FuseSoC/Verilator throws an error.

### Example Error
%Error: src/lowrisc_ip_i2c_0.1/rtl/i2c.sv:30:10:
Package/class 'prim_alert_pkg' not found, and needs to be predeclared

perl
Copy code

### Fix
- Identify where the package actually exists:
  ```bash
  fusesoc list-cores | grep prim_alert
Add the correct dependency (e.g. lowrisc:prim:prim_alert_pkg:0.1) to i2c.core.

## 2. Example: Missing Variable (NumLcStates)
%Error: Can't find definition of variable: 'NumLcStates'
Root Cause
The i2c.core depended on lc_ctrl_pkg, but its .core file didn’t include the RTL file that defines NumLcStates.

That definition exists inside lc_ctrl_state_pkg.

Fix
Updated lc_ctrl_pkg.core to include the missing file so Verilator could see the definition.

## 3. The .tpl File Problem
After fixing the dependency, a new issue appeared:

The file containing NumLcStates is not a SystemVerilog file but a template:

swift
Copy code
hw/ip/lc_ctrl/rtl/lc_ctrl_state_pkg.sv.tpl
Templates (.tpl) must be expanded into .sv before tools like Verilator can use them.

## 4. Generating .sv from .tpl
There are two ways:

✅ A. OpenTitan’s Normal Flow (Recommended)
OpenTitan uses Bazel to generate auto-generated RTL.
Run:

bash
Copy code
./bazelisk.sh build //hw/ip/lc_ctrl:all
Then search for the generated file:

bash
Copy code
find bazel-out/ -name "lc_ctrl_state_pkg.sv"
⚙️ B. Manual Flow with regtool.py
regtool.py in util/ can also process .hjson configs and templates.

Example:

bash
Copy code
./util/regtool.py -r hw/ip/lc_ctrl/data/lc_ctrl_state.hjson --outdir hw/ip/lc_ctrl/rtl/
This writes the generated lc_ctrl_state_pkg.sv into hw/ip/lc_ctrl/rtl/.

⚠️ Note: In my case, this failed with schema errors (missing name, cip_id, bus_interfaces...).
That’s because lc_ctrl_state.hjson isn’t a simple register map but a state encoding config.
This means only Bazel (or CI pre-generated outputs) can generate the final .sv file reliably.

5. Key Takeaways
Always check dependencies with:

bash
Copy code
fusesoc list-cores | grep <keyword>
Update .core files when dependencies are missing.

Some variables/packages are not directly in .sv files but auto-generated from templates.

For those, prefer Bazel build flow to generate the final .sv.
