gc_disable()

# ioctl.sage — Linux ioctl command builder
#
# Generate ioctl command numbers and handler dispatch code.
# Follows the Linux _IO/_IOR/_IOW/_IOWR macros.

# ----- Direction bits -----
let IOC_NONE = 0
let IOC_WRITE = 1
let IOC_READ = 2
let IOC_READWRITE = 3

# ----- Shift/mask values (Linux convention) -----
let IOC_NRSHIFT = 0
let IOC_TYPESHIFT = 8
let IOC_SIZESHIFT = 16
let IOC_DIRSHIFT = 30

# ========== Command number calculation ==========

# _IO(type, nr) — no data transfer
proc io_cmd(cmd_type, nr):
    let type_val = cmd_type
    if type(cmd_type) == "string":
        type_val = ord(cmd_type)
    return (IOC_NONE * 1073741824) + (type_val * 256) + nr

# _IOR(type, nr, size) — read from device
proc ior_cmd(cmd_type, nr, size):
    let type_val = cmd_type
    if type(cmd_type) == "string":
        type_val = ord(cmd_type)
    return (IOC_READ * 1073741824) + (size * 65536) + (type_val * 256) + nr

# _IOW(type, nr, size) — write to device
proc iow_cmd(cmd_type, nr, size):
    let type_val = cmd_type
    if type(cmd_type) == "string":
        type_val = ord(cmd_type)
    return (IOC_WRITE * 1073741824) + (size * 65536) + (type_val * 256) + nr

# _IOWR(type, nr, size) — read+write
proc iowr_cmd(cmd_type, nr, size):
    let type_val = cmd_type
    if type(cmd_type) == "string":
        type_val = ord(cmd_type)
    return (IOC_READWRITE * 1073741824) + (size * 65536) + (type_val * 256) + nr

# ========== Command descriptor ==========

proc create_ioctl_cmd(name, direction, cmd_type, nr, data_size):
    let cmd = {}
    cmd["name"] = name
    cmd["direction"] = direction
    cmd["type"] = cmd_type
    cmd["nr"] = nr
    cmd["data_size"] = data_size
    if direction == IOC_NONE:
        cmd["number"] = io_cmd(cmd_type, nr)
    if direction == IOC_READ:
        cmd["number"] = ior_cmd(cmd_type, nr, data_size)
    if direction == IOC_WRITE:
        cmd["number"] = iow_cmd(cmd_type, nr, data_size)
    if direction == IOC_READWRITE:
        cmd["number"] = iowr_cmd(cmd_type, nr, data_size)
    return cmd

# ========== Ioctl handler set ==========

proc create_ioctl_set(magic_type):
    let s = {}
    s["type"] = magic_type
    s["commands"] = []
    s["next_nr"] = 0
    return s

proc ioctl_add_cmd(s, name, direction, data_size):
    let cmd = create_ioctl_cmd(name, direction, s["type"], s["next_nr"], data_size)
    append(s["commands"], cmd)
    s["next_nr"] = s["next_nr"] + 1
    return s

proc ioctl_add_read(s, name, data_size):
    return ioctl_add_cmd(s, name, IOC_READ, data_size)

proc ioctl_add_write(s, name, data_size):
    return ioctl_add_cmd(s, name, IOC_WRITE, data_size)

proc ioctl_add_rw(s, name, data_size):
    return ioctl_add_cmd(s, name, IOC_READWRITE, data_size)

proc ioctl_add_none(s, name):
    return ioctl_add_cmd(s, name, IOC_NONE, 0)

# ========== C code generation ==========

proc emit_ioctl_header(s):
    let nl = chr(10)
    let code = ""
    code = code + "#ifndef _IOCTL_CMDS_H" + nl
    code = code + "#define _IOCTL_CMDS_H" + nl + nl
    code = code + "#include <linux/ioctl.h>" + nl + nl

    let type_char = chr(39) + s["type"] + chr(39)
    let i = 0
    while i < len(s["commands"]):
        let cmd = s["commands"][i]
        let macro_name = ""
        if cmd["direction"] == IOC_NONE:
            macro_name = "_IO"
        if cmd["direction"] == IOC_READ:
            macro_name = "_IOR"
        if cmd["direction"] == IOC_WRITE:
            macro_name = "_IOW"
        if cmd["direction"] == IOC_READWRITE:
            macro_name = "_IOWR"

        code = code + "#define " + cmd["name"] + " "
        if cmd["direction"] == IOC_NONE:
            code = code + macro_name + "(" + type_char + ", " + str(cmd["nr"]) + ")" + nl
        else:
            code = code + macro_name + "(" + type_char + ", " + str(cmd["nr"]) + ", " + str(cmd["data_size"]) + ")" + nl
        i = i + 1

    code = code + nl + "#endif" + nl
    return code

proc emit_ioctl_handler(s, device_name):
    let nl = chr(10)
    let q = chr(34)
    let code = ""

    code = code + "static long " + device_name + "_ioctl(struct file *filp, unsigned int cmd, unsigned long arg) {" + nl
    code = code + "    switch (cmd) {" + nl

    let i = 0
    while i < len(s["commands"]):
        let cmd = s["commands"][i]
        code = code + "    case " + cmd["name"] + ":" + nl
        code = code + "        pr_info(" + q + device_name + ": ioctl " + cmd["name"] + q + ");" + nl
        code = code + "        break;" + nl
        i = i + 1

    code = code + "    default:" + nl
    code = code + "        return -ENOTTY;" + nl
    code = code + "    }" + nl
    code = code + "    return 0;" + nl
    code = code + "}" + nl

    return code
