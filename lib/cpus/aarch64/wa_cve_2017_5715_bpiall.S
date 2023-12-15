/*
 * Copyright (c) 2017-2022, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <arch.h>
#include <asm_macros.S>
#include <context.h>
#include <services/arm_arch_svc.h>

	.globl	wa_cve_2017_5715_bpiall_vbar

#define EMIT_BPIALL		0xee070fd5
#define EMIT_SMC		0xe1600070
#define ESR_EL3_A64_SMC0	0x5e000000

	.macro	apply_cve_2017_5715_wa _from_vector
	/*
	 * Save register state to enable a call to AArch32 S-EL1 and return
	 * Identify the original calling vector in w2 (==_from_vector)
	 * Use w3-w6 for additional register state preservation while in S-EL1
	 */

	/* Save GP regs */
	stp	PTR(0), PTR(1), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X0]
	stp	PTR(2), PTR(3), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X2]
	stp	PTR(4), PTR(5), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X4]
	stp	PTR(6), PTR(7), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X6]
	stp	PTR(8), PTR(9), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X8]
	stp	PTR(10), PTR(11), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X10]
	stp	PTR(12), PTR(13), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X12]
	stp	PTR(14), PTR(15), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X14]
	stp	PTR(16), PTR(17), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X16]
	stp	PTR(18), PTR(19), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X18]
	stp	PTR(20), PTR(21), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X20]
	stp	PTR(22), PTR(23), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X22]
	stp	PTR(24), PTR(25), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X24]
	stp	PTR(26), PTR(27), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X26]
	stp	PTR(28), PTR(29), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X28]

	/* Identify the original exception vector */
	mov	w2, \_from_vector

	/* Preserve 32-bit system registers in GP registers through the workaround */
	mrs	x3, esr_el3
	mrs	x4, spsr_el3
	mrs	x5, scr_el3
	mrs	x6, sctlr_el1

	/*
	 * Preserve LR and ELR_EL3 registers in the GP regs context.
	 * Temporarily use the CTX_GPREG_SP_EL0 slot to preserve ELR_EL3
	 * through the workaround. This is OK because at this point the
	 * current state for this context's SP_EL0 is in the live system
	 * register, which is unmodified by the workaround.
	 */
	mrs	x7, elr_el3
	stp	PTR(30), PTR(7), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_LR]

	/*
	 * Load system registers for entry to S-EL1.
	 */

	/* Mask all interrupts and set AArch32 Supervisor mode */
	movz	w8, SPSR_MODE32(MODE32_svc, SPSR_T_ARM, SPSR_E_LITTLE, SPSR_AIF_MASK)

	/* Switch EL3 exception vectors while the workaround is executing. */
	adr	PTR(9), wa_cve_2017_5715_bpiall_ret_vbar

	/* Setup SCTLR_EL1 with MMU off and I$ on */
	ldr	x10, stub_sel1_sctlr

	/* Land at the S-EL1 workaround stub */
	adr	PTR(11), aarch32_stub

	/*
	 * Setting SCR_EL3 to all zeroes means that the NS, RW
	 * and SMD bits are configured as expected.
	 */
	msr	scr_el3, xzr
	msr	spsr_el3, x8
	msr	vbar_el3, x9
	msr	sctlr_el1, x10
	msr	elr_el3, x11

	eret
	.endm

	/* ---------------------------------------------------------------------
	 * This vector table is used at runtime to enter the workaround at
	 * AArch32 S-EL1 for Sync/IRQ/FIQ/SError exceptions.  If the workaround
	 * is not enabled, the existing runtime exception vector table is used.
	 * ---------------------------------------------------------------------
	 */
vector_base wa_cve_2017_5715_bpiall_vbar

	/* ---------------------------------------------------------------------
	 * Current EL with SP_EL0 : 0x0 - 0x200
	 * ---------------------------------------------------------------------
	 */
vector_entry bpiall_sync_exception_sp_el0
	b	sync_exception_sp_el0
	nop	/* to force 8 byte alignment for the following stub */

	/*
	 * Since each vector table entry is 128 bytes, we can store the
	 * stub context in the unused space to minimize memory footprint.
	 */
stub_sel1_sctlr:
	.quad	SCTLR_AARCH32_EL1_RES1 | SCTLR_I_BIT

aarch32_stub:
	.word	EMIT_BPIALL
	.word	EMIT_SMC

end_vector_entry bpiall_sync_exception_sp_el0

vector_entry bpiall_irq_sp_el0
	b	irq_sp_el0
end_vector_entry bpiall_irq_sp_el0

vector_entry bpiall_fiq_sp_el0
	b	fiq_sp_el0
end_vector_entry bpiall_fiq_sp_el0

vector_entry bpiall_serror_sp_el0
	b	serror_sp_el0
end_vector_entry bpiall_serror_sp_el0

	/* ---------------------------------------------------------------------
	 * Current EL with SP_ELx: 0x200 - 0x400
	 * ---------------------------------------------------------------------
	 */
vector_entry bpiall_sync_exception_sp_elx
	b	sync_exception_sp_elx
end_vector_entry bpiall_sync_exception_sp_elx

vector_entry bpiall_irq_sp_elx
	b	irq_sp_elx
end_vector_entry bpiall_irq_sp_elx

vector_entry bpiall_fiq_sp_elx
	b	fiq_sp_elx
end_vector_entry bpiall_fiq_sp_elx

vector_entry bpiall_serror_sp_elx
	b	serror_sp_elx
end_vector_entry bpiall_serror_sp_elx

	/* ---------------------------------------------------------------------
	 * Lower EL using AArch64 : 0x400 - 0x600
	 * ---------------------------------------------------------------------
	 */
vector_entry bpiall_sync_exception_aarch64
	apply_cve_2017_5715_wa 1
end_vector_entry bpiall_sync_exception_aarch64

vector_entry bpiall_irq_aarch64
	apply_cve_2017_5715_wa 2
end_vector_entry bpiall_irq_aarch64

vector_entry bpiall_fiq_aarch64
	apply_cve_2017_5715_wa 4
end_vector_entry bpiall_fiq_aarch64

vector_entry bpiall_serror_aarch64
	apply_cve_2017_5715_wa 8
end_vector_entry bpiall_serror_aarch64

	/* ---------------------------------------------------------------------
	 * Lower EL using AArch32 : 0x600 - 0x800
	 * ---------------------------------------------------------------------
	 */
vector_entry bpiall_sync_exception_aarch32
	apply_cve_2017_5715_wa 1
end_vector_entry bpiall_sync_exception_aarch32

vector_entry bpiall_irq_aarch32
	apply_cve_2017_5715_wa 2
end_vector_entry bpiall_irq_aarch32

vector_entry bpiall_fiq_aarch32
	apply_cve_2017_5715_wa 4
end_vector_entry bpiall_fiq_aarch32

vector_entry bpiall_serror_aarch32
	apply_cve_2017_5715_wa 8
end_vector_entry bpiall_serror_aarch32

	/* ---------------------------------------------------------------------
	 * This vector table is used while the workaround is executing.  It
	 * installs a simple SMC handler to allow the Sync/IRQ/FIQ/SError
	 * workaround stubs to enter EL3 from S-EL1.  It restores the previous
	 * EL3 state before proceeding with the normal runtime exception vector.
	 * ---------------------------------------------------------------------
	 */
vector_base wa_cve_2017_5715_bpiall_ret_vbar

	/* ---------------------------------------------------------------------
	 * Current EL with SP_EL0 : 0x0 - 0x200 (UNUSED)
	 * ---------------------------------------------------------------------
	 */
vector_entry bpiall_ret_sync_exception_sp_el0
	b	report_unhandled_exception
end_vector_entry bpiall_ret_sync_exception_sp_el0

vector_entry bpiall_ret_irq_sp_el0
	b	report_unhandled_interrupt
end_vector_entry bpiall_ret_irq_sp_el0

vector_entry bpiall_ret_fiq_sp_el0
	b	report_unhandled_interrupt
end_vector_entry bpiall_ret_fiq_sp_el0

vector_entry bpiall_ret_serror_sp_el0
	b	report_unhandled_exception
end_vector_entry bpiall_ret_serror_sp_el0

	/* ---------------------------------------------------------------------
	 * Current EL with SP_ELx: 0x200 - 0x400 (UNUSED)
	 * ---------------------------------------------------------------------
	 */
vector_entry bpiall_ret_sync_exception_sp_elx
	b	report_unhandled_exception
end_vector_entry bpiall_ret_sync_exception_sp_elx

vector_entry bpiall_ret_irq_sp_elx
	b	report_unhandled_interrupt
end_vector_entry bpiall_ret_irq_sp_elx

vector_entry bpiall_ret_fiq_sp_elx
	b	report_unhandled_interrupt
end_vector_entry bpiall_ret_fiq_sp_elx

vector_entry bpiall_ret_serror_sp_elx
	b	report_unhandled_exception
end_vector_entry bpiall_ret_serror_sp_elx

	/* ---------------------------------------------------------------------
	 * Lower EL using AArch64 : 0x400 - 0x600 (UNUSED)
	 * ---------------------------------------------------------------------
	 */
vector_entry bpiall_ret_sync_exception_aarch64
	b	report_unhandled_exception
end_vector_entry bpiall_ret_sync_exception_aarch64

vector_entry bpiall_ret_irq_aarch64
	b	report_unhandled_interrupt
end_vector_entry bpiall_ret_irq_aarch64

vector_entry bpiall_ret_fiq_aarch64
	b	report_unhandled_interrupt
end_vector_entry bpiall_ret_fiq_aarch64

vector_entry bpiall_ret_serror_aarch64
	b	report_unhandled_exception
end_vector_entry bpiall_ret_serror_aarch64

	/* ---------------------------------------------------------------------
	 * Lower EL using AArch32 : 0x600 - 0x800
	 * ---------------------------------------------------------------------
	 */
vector_entry bpiall_ret_sync_exception_aarch32
	/*
	 * w2 indicates which SEL1 stub was run and thus which original vector was used
	 * w3-w6 contain saved system register state (esr_el3 in w3)
	 * Restore LR and ELR_EL3 register state from the GP regs context
	 */
	ldp	x30, x7, [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_LR]

	/* Apply the restored system register state */
	msr	esr_el3, x3
	msr	spsr_el3, x4
	msr	scr_el3, x5
	msr	sctlr_el1, x6
	msr	elr_el3, x7

	/*
	 * Workaround is complete, so swap VBAR_EL3 to point
	 * to workaround entry table in preparation for subsequent
	 * Sync/IRQ/FIQ/SError exceptions.
	 */
	adr	PTR(0), wa_cve_2017_5715_bpiall_vbar
	msr	vbar_el3, x0

	/*
	 * Restore all GP regs except x2 and x3 (esr).  The value in x2
	 * indicates the type of the original exception.
	 */
	ldp	PTR(0), PTR(1), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X0]
	ldp	PTR(2), PTR(3), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X2]
	ldp	PTR(4), PTR(5), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X4]
	ldp	PTR(6), PTR(7), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X6]
	ldp	PTR(8), PTR(9), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X8]
	ldp	PTR(10), PTR(11), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X10]
	ldp	PTR(12), PTR(13), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X12]
	ldp	PTR(14), PTR(15), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X14]
	ldp	PTR(16), PTR(17), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X16]
	ldp	PTR(18), PTR(19), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X18]
	ldp	PTR(20), PTR(21), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X20]
	ldp	PTR(22), PTR(23), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X22]
	ldp	PTR(24), PTR(25), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X24]
	ldp	PTR(26), PTR(27), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X26]
	ldp	PTR(28), PTR(29), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X28]

	/* Fast path Sync exceptions.  Static predictor will fall through. */
	tbz	w2, #0, workaround_not_sync

	/*
	 * Check if SMC is coming from A64 state on #0
	 * with W0 = SMCCC_ARCH_WORKAROUND_1 or W0 = SMCCC_ARCH_WORKAROUND_3
	 *
	 * This sequence evaluates as:
	 *    (W0==SMCCC_ARCH_WORKAROUND_1) || (W0==SMCCC_ARCH_WORKAROUND_3) ?
	 *    (ESR_EL3==SMC#0) : (NE)
	 * allowing use of a single branch operation
	 */
	orr	w2, wzr, #SMCCC_ARCH_WORKAROUND_1
	cmp	w0, w2
	orr	w2, wzr, #SMCCC_ARCH_WORKAROUND_3
	ccmp	w0, w2, #4, ne
	mov_imm	w2, ESR_EL3_A64_SMC0
	ccmp	w3, w2, #0, eq
	/* Static predictor will predict a fall through */
	bne	1f
	eret
1:
	/* restore x2 and x3 and continue sync exception handling */
	b	bpiall_ret_sync_exception_aarch32_tail
end_vector_entry bpiall_ret_sync_exception_aarch32

vector_entry bpiall_ret_irq_aarch32
	b	report_unhandled_interrupt

	/*
	 * Post-workaround fan-out for non-sync exceptions
	 */
workaround_not_sync:
	tbnz	w2, #3, bpiall_ret_serror
	tbnz	w2, #2, bpiall_ret_fiq
	/* IRQ */
	ldp	PTR(2), PTR(3), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X2]
	b	irq_aarch64

bpiall_ret_fiq:
	ldp	PTR(2), PTR(3), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X2]
	b	fiq_aarch64

bpiall_ret_serror:
	ldp	PTR(2), PTR(3), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X2]
	b	serror_aarch64
end_vector_entry bpiall_ret_irq_aarch32

vector_entry bpiall_ret_fiq_aarch32
	b	report_unhandled_interrupt
end_vector_entry bpiall_ret_fiq_aarch32

vector_entry bpiall_ret_serror_aarch32
	b	report_unhandled_exception
end_vector_entry bpiall_ret_serror_aarch32

	/*
	 * Part of bpiall_ret_sync_exception_aarch32 to save vector space
	 */
func bpiall_ret_sync_exception_aarch32_tail
	ldp	x2, x3, [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X2]
	b	sync_exception_aarch64
endfunc bpiall_ret_sync_exception_aarch32_tail
