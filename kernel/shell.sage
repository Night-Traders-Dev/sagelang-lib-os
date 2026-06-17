gc_disable()

# sh.sage — Minimal SageOS Shell
# Provides a terminal-based interface for user interaction.

import console
import keyboard
import syscall

proc print_prompt():
    console.set_color(console.LIGHT_CYAN, console.BLACK)
    console.print_str("sage@os")
    console.set_color(console.WHITE, console.BLACK)
    console.print_str(":")
    console.set_color(console.LIGHT_BLUE, console.BLACK)
    console.print_str("~")
    console.set_color(console.WHITE, console.BLACK)
    console.print_str("$ ")

proc handle_command(cmd):
    if cmd == "":
        return
    
    if cmd == "help":
        console.print_line("Available commands:")
        console.print_line("  help     - Show this help message")
        console.print_line("  ls       - List files (simulated)")
        console.print_line("  clear    - Clear the screen")
        console.print_line("  version  - Show SageOS version")
        console.print_line("  exit     - Exit the shell")
        return
    
    if cmd == "ls":
        console.print_line("bin/  etc/  home/  kernel.bin")
        return
    
    if cmd == "clear":
        console.clear_screen(console.BLACK)
        return
    
    if cmd == "version":
        console.print_line("SageOS v3.8.1 (x86_64)")
        return
    
    if cmd == "exit":
        console.print_line("Shutting down...")
        syscall.sys_exit(0)
        return
    
    console.print_line("sh: command not found: " + cmd)

proc sh_main():
    console.print_line("SageOS Shell v3.8.1")
    console.print_line("Type 'help' for available commands.")
    console.print_line("")
    
    let cmd_buffer = ""
    while true:
        print_prompt()
        
        # Read line from keyboard
        cmd_buffer = ""
        let reading = true
        while reading:
            let ch = keyboard.get_char()
            if ch != nil:
                if ch == chr(10): # Enter
                    console.newline()
                    reading = false
                elif ch == chr(8): # Backspace
                    if len(cmd_buffer) > 0:
                        # Simple backspace: move cursor back, print space, move back
                        let pos = console.get_cursor()
                        if pos["x"] > 0:
                            console.set_cursor(pos["x"] - 1, pos["y"])
                            console.print_str(" ")
                            console.set_cursor(pos["x"] - 1, pos["y"])
                            # Truncate cmd_buffer
                            let new_cmd = ""
                            for i in range(len(cmd_buffer) - 1):
                                new_cmd = new_cmd + cmd_buffer[i]
                            cmd_buffer = new_cmd
                else:
                    cmd_buffer = cmd_buffer + ch
                    console.print_str(ch)
            # Yield to other tasks if multi-tasking was enabled
            syscall.builtin_yield(nil)
        
        handle_command(cmd_buffer)
