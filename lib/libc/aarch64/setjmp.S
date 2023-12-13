/*
 * Copyright (c) 2018-2019, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <asm_macros.S>
#include <assert_macros.S>
#include <setjmp.h>

	.globl	setjmp
	.globl	longjmp

/*
 * int setjmp(jmp_buf env);
 */
func setjmp
	mov	PTR(7), PTRN(sp)

	stp	PTR(19), PTR(20), [PTR(0), #JMP_CTX_X19]
	stp	PTR(21), PTR(22), [PTR(0), #JMP_CTX_X21]
	stp	PTR(23), PTR(24), [PTR(0), #JMP_CTX_X23]
	stp	PTR(25), PTR(26), [PTR(0), #JMP_CTX_X25]
	stp	PTR(27), PTR(28), [PTR(0), #JMP_CTX_X27]
	stp	PTR(29), PTR(30), [PTR(0), #JMP_CTX_X29]
	stp	PTR(7), ZR, [PTR(0), #JMP_CTX_SP]

	mov	x0, #0
	ret
endfunc setjmp


/*
 * void longjmp(jmp_buf env, int val);
 */
func longjmp
	ldp	PTR(7), ZR, [PTR(0), #JMP_CTX_SP]

#if ENABLE_ASSERTIONS
	/*
	 * Since we're unwinding the stack, assert that the stack being reset to
	 * is shallower.
	 */
	mov	PTR(19), PTRN(sp)
	cmp	x7, x19
	ASM_ASSERT(ge)
#endif

	ldp	PTR(19), PTR(20), [PTR(0), #JMP_CTX_X19]
	ldp	PTR(21), PTR(22), [PTR(0), #JMP_CTX_X21]
	ldp	PTR(23), PTR(24), [PTR(0), #JMP_CTX_X23]
	ldp	PTR(25), PTR(26), [PTR(0), #JMP_CTX_X25]
	ldp	PTR(27), PTR(28), [PTR(0), #JMP_CTX_X27]
	ldp	PTR(29), PTR(30), [PTR(0), #JMP_CTX_X29]

	mov	PTRN(sp), PTR(7)

	ands	x0, x1, x1 /* Move val to x0 and set flags */
	cinc	x0, x0, eq /* If val is 0, return 1 */
	ret
endfunc longjmp
