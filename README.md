# Modified-xv6
A tweaked xV6 OS(https://github.com/mit-pdos/xv6-riscv) with new syscalls and scheduling mechanisms

I have implemented the following system calls:

- int trace(uint64 mask)
- int set_priority(uint64 new_priority, uint64 pid)

The userprograms strace.c and setpriority.c make use of the above system calls respectively.

FCFS and PBS scheduling algorithms are implemented apart from the default Round Robin.
Working is explained in report.pdf

Procdump for PBS is also implemented which shows the required fields as mentioned in the assignment.

To compile with Round Robin Scheduler: `make clean` `make qemu SCHEDULER=ROUND_ROBIN`
To compile with FCFS Scheduler: `make clean` `make qemu SCHEDULER=FCFS`
To compile with PBS Scheduler: `make clean` `make qemu SCHEDULER=PBS`

The default scheduler is Round Robin unless specified.
To use strace command, the following format is used:
`strace <mask> <command>`: It shows all system calls called by `<command>` and having the index of system call set in the binary representation of `<mask>`
To use the setpriority command, the following format is used:
`setpriority <new_priority> <pid>`: It sets the static priority of process with processid = pid equal to new_priority 
