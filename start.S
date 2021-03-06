#include "platform.h"

	# size of each hart's stack is 2048(RV32) or 4096(RV64) bytes
#ifdef RV32
	.equ	STACK_SIZE, 2048
#else
	.equ	STACK_SIZE, 4096
#endif

	.global	_start

	.text
_start:
    # park harts with id != 0
    csrr    t0, mhartid # read current hart id
    mv  tp, t0          # keep CPU's hartid in its tp for later usage.
    bnez    t0, park    # if we're not on the hart 0, park the hart

    # Set all bytes in the BSS section to zero.
	la	a0, _bss_start
	la	a1, _bss_end
	bgeu	a0, a1, 2f
1:
	sw	zero, (a0)
	addi	a0, a0, 4
	bltu	a0, a1, 1b

2:
	# Setup stacks, the stack grows from bottom to top, so we put the
	# stack pointer to the very end of the stack range.
#ifdef RV32
	slli	t0, t0, 11		# shift left the hart id by 2048
#else
	slli	t0, t0, 12		# shift left the hart id by 4096
#endif
	la	sp, stacks + STACK_SIZE	# set the initial stack pointer
					# to the end of the first stack space
	add	sp, sp, t0		# move the current hart stack pointer
					# to its place in the stack space

    # At the end of start_kernel, schedule() will call MRET to switch
	# to the first task, so we parepare the mstatus here.
	# Notice: default mstatus is 0
	# Set mstatus.MPP to 3, so we still run in Machine mode after MRET.
	# Set mstatus.MPIE to 1, so MRET will enable the interrupt.
	li	t0, 3 << 11 | 1 << 7
	csrr	a1, mstatus
	or	t0, t0, a1
	csrw	mstatus, t0

    j	start_kernel		# hart 0 jump to c

park:
    wfi
    j   park

stacks:
	.skip	STACK_SIZE * MAXNUM_CPU # allocate space for all the harts stacks

	.end				# End of file
