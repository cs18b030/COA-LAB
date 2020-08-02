/**
here we will perform the following actions:
1.) We will update the medeleg reg to handle traps in S mode.
2.) We will change the mpp bits to go to user mode (M->U).
3.) We will perform 3 dummy system calls, namely bite, cite(2 times) and kite.
4.) In each system call, all the arguments will be stored in stack and return back to the callee function.
*/
_start:
    # set sp and stvec. stvec = system_calls so that when we perform ecall,
    # it can jump to system_calls 
    li      sp, 0x10011000
	la      t0, system_calls
	csrw    stvec, t0
    # here, set the medeleg register to handle traps in S mode
    andi    t0, t0, 0
    li      t0, 0xffff
    csrs    medeleg, t0
    # update mpp bits in mstatus register: 11(M) -> 00(U)
    li      t0, 0x1800
    csrrc   zero,mstatus, t0    # clear the 11th and 12th bit in mstatus
    # update mepc : user_mode
    la      t0, user_mode
    csrw    mepc, t0
    mret
    # exit the machine mode

user_mode:
    # perform the system calls here using ecall
    # 1.) bite(10, 95, 66)
    addi    sp, sp, -32*3
    li      a0, 10
    sd      a0, 1*8(sp)
    li      a0, 95
    sd      a0, 2*8(sp)
    li      a0, 66
    sd      a0, 3*8(sp)
    li      a0, 0
    # switch case number for bite: 0
    nop
    ecall

    # 2.) cite(23, 67)
    addi    sp, sp, -32*2
    li      a0, 23
    sd      a0, 1*8(sp)
    li      a0, 67
    sd      a0, 2*8(sp)
    li      a0, 1
    # switch case number for cite: 1
    nop
    ecall

    # 2.) cite(23, 67)
    addi    sp, sp, -32*2
    li      a0, 23
    sd      a0, 1*8(sp)
    li      a0, 67
    sd      a0, 2*8(sp)
    li      a0, 1
    # switch case number for cite: 1
    nop
    ecall

    # 3.) kite (35, 99, 12, 13, 0, 4, 5, 9, 12, 1, 2, 2, 3, 9)
    addi    sp, sp, -32*14
    li      a0, 35
    sd      a0, 1*8(sp)
    li      a0, 99
    sd      a0, 2*8(sp)
    li      a0, 12
    sd      a0, 3*8(sp)
    li      a0, 13
    sd      a0, 4*8(sp)
    li      a0, 0
    sd      a0, 5*8(sp)
    li      a0, 4
    sd      a0, 6*8(sp)
    li      a0, 5
    sd      a0, 7*8(sp)
    li      a0, 9
    sd      a0, 8*8(sp)
    li      a0, 12
    sd      a0, 9*8(sp)
    li      a0, 1
    sd      a0, 10*8(sp)
    li      a0, 2
    sd      a0, 11*8(sp)
    li      a0, 2
    sd      a0, 12*8(sp)
    li      a0, 3
    sd      a0, 13*8(sp)
    li      a0, 9
    sd      a0, 14*8(sp)
    li      a0, 2
    # switch case number for kite: 2
    nop
    ecall
    ebreak
    nop

system_calls:
    # a0 register has the switch case value.

    # set sepc:= sepc + 4
    csrr    t0, sepc
    addi    t0, t0, 4
    csrw    sepc, t0

    # check for switch cases
    mv      a1, x0
    # Case 0: bite
    beq     a1, a0, _bite
    addi    a1, a1, 1
    # Case 1: cite
    beq     a1, a0, _cite
    addi    a1, a1, 1
    # Case 2: kite
    beq     a1, a0, _kite
    # go back to user mode, specifically, 
    # to the next line of the instruction which performed the system call.

_bite: #0
	la      t0, _data
	lw      t1, 0(t0)
	addi    t1, t1, 1
	sw      t1, 0(t0)
    sret

_cite: #1
	la      t0, _data
	lw      t1, 4(t0)
	addi    t1, t1, 1
	sw      t1, 4(t0)
    sret

_kite: #2
	la      t0, _data
	lw      t1, 8(t0)
	addi    t1, t1, 1
	sw      t1, 8(t0)
    sret

.section .data
.p2align 0x2
_data:
    .word   0 # store number of "bite" system calls
    .word   0 # store number of "cite" system calls
    .word   0 # store number of "kite" system calls