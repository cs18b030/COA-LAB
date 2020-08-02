_start:	
	li      sp, 0x10011000
	la      t0, s_to_m_mode
	csrw    mtvec, t0
    # set sp and set t mtvec to s_to_m_mode. we will use mtvec later for "S->M"

    # for going from higher privlage levels to lower privilage levels
    # we update the mpp bits and spp bits to do so.
    # for the reverse(U->S->M) we use trap delegation and ecall.

    # we are in M mode. increment counter of M
    la      t0, _data
    lw      t1, 0(t0)
    addi    t1, t1, 1
    sw      t1, 0(t0)
    # here, set the medeleg register to handle traps in S mode
    andi    t0, t0, 0
    li      t0, 0xffff
    csrs    medeleg, t0
    # now set the mpp bits to "01" and change the mepc value to m_to_s_mode
    li      t0, 0x1800
    csrrc   zero,mstatus, t0    # clear the 11th and 12th bit in mstatus
	li      t0, 0x0800
	csrs    mstatus, t0         # set mpp (previous mode) with supervisor mode
	la      t0, m_to_s_mode     # set mepc value 
	csrw    mepc, t0
	mret                        # mode changed

m_to_s_mode:
    # we are in S mode. increment counter of S
    la      t0, _data
    lw      t1, 4(t0)
    addi    t1, t1, 1
    sw      t1, 4(t0)
    # here, set the stvec to u_to_s_mode. Later when we do a ecall, it will jump 
    # to that location because we have set the medeleg register to handle traps in S mode
    la      t0, u_to_s_mode
    csrw    stvec, t0 
    # now set the spp bit to 0 and update the sepc value
    li      t0, 0x0100
	csrc    sstatus, t0          # set spp (previous mode) with user mode
	la      t0, s_to_u_mode      # set sepc value correctly
	csrw    sepc, t0
	sret

s_to_u_mode:
    # we are in U mode. increment counter of U
    la      t0, _data
    lw      t1, 8(t0)
    addi    t1, t1, 1
    sw      t1, 8(t0)
    # we switch back to S mode using ecall. medeleg is already set to handle traps in S mode.
    nop
    ecall
    # we jump to stvec: u_to_s_mode

u_to_s_mode:
    # we are in S mode, increment counter of S
    la      t0, _data
    lw      t1, 4(t0)
    addi    t1, t1, 1
    sw      t1, 4(t0)
    # now, to jump to M mode, we perform another ecall.
    # it has to be handled in M mode.
    # so we jump to mtvec: s_to_m_mode
    nop
    ecall

.p2align 0x2
s_to_m_mode:
    # we are in M mode. increment counter of M
    la      t0, _data
    lw      t1, 0(t0)
    addi    t1, t1, 1
    sw      t1, 0(t0)

    ebreak

.section .data
.p2align 0x2
_data:
	.word   0 # store the number of times the program was in machine(M) mode
	.word   0 # store the number of times the program was in supervisor(S) mode
    .word   0 # store the number of times the program was in user(U) mode 