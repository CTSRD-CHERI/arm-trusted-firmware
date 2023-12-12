/*
 * Copyright (c) 2013-2023, Arm Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <arch.h>
#include <asm_macros.S>
#include <assert_macros.S>
#include <context.h>
#include <el3_common_macros.S>

#if CTX_INCLUDE_EL2_REGS
	.global	el2_sysregs_context_save_common
	.global	el2_sysregs_context_restore_common
#if CTX_INCLUDE_MTE_REGS
	.global	el2_sysregs_context_save_mte
	.global	el2_sysregs_context_restore_mte
#endif /* CTX_INCLUDE_MTE_REGS */
#endif /* CTX_INCLUDE_EL2_REGS */

	.global	el1_sysregs_context_save
	.global	el1_sysregs_context_restore
#if CTX_INCLUDE_FPREGS
	.global	fpregs_context_save
	.global	fpregs_context_restore
#endif /* CTX_INCLUDE_FPREGS */
	.global	prepare_el3_entry
	.global	restore_gp_pmcr_pauth_regs
	.global save_and_update_ptw_el1_sys_regs
	.global	el3_exit
#if ENABLE_MORELLO_CAP
	.global save_ddc_el0
#endif

#if CTX_INCLUDE_EL2_REGS

/* -----------------------------------------------------
 * The following functions strictly follow the AArch64
 * PCS to use x9-x16 (temporary caller-saved registers)
 * to save/restore EL2 system register context.
 * el2_sysregs_context_save/restore_common functions
 * save and restore registers that are common to all
 * configurations. The rest of the functions save and
 * restore EL2 system registers that are present when a
 * particular feature is enabled. All functions assume
 * that 'x0' is pointing to a 'el2_sys_regs' structure
 * where the register context will be saved/restored.
 *
 * The following registers are not added.
 * AMEVCNTVOFF0<n>_EL2
 * AMEVCNTVOFF1<n>_EL2
 * ICH_AP0R<n>_EL2
 * ICH_AP1R<n>_EL2
 * ICH_LR<n>_EL2
 * -----------------------------------------------------
 */
func el2_sysregs_context_save_common
	mrs	x9, actlr_el2
	mrs	x10, afsr0_el2
	stp	x9, x10, [PTR(0), #CTX_ACTLR_EL2]

	mrs	x11, afsr1_el2
	mrs	x12, amair_el2
	stp	x11, x12, [PTR(0), #CTX_AFSR1_EL2]

	mrs	x13, cnthctl_el2
	mrs	x14, cntvoff_el2
	stp	x13, x14, [PTR(0), #CTX_CNTHCTL_EL2]

	mrs	x15, cptr_el2
	str	x15, [PTR(0), #CTX_CPTR_EL2]

#if CTX_INCLUDE_AARCH32_REGS
	mrs	x16, dbgvcr32_el2
	str	x16, [PTR(0), #CTX_DBGVCR32_EL2]
#endif /* CTX_INCLUDE_AARCH32_REGS */

	mrs	x9, elr_el2
	mrs	x10, esr_el2
	stp	x9, x10, [PTR(0), #CTX_ELR_EL2]

	mrs	x11, far_el2
	mrs	x12, hacr_el2
	stp	x11, x12, [PTR(0), #CTX_FAR_EL2]

	mrs	x13, hcr_el2
	mrs	x14, hpfar_el2
	stp	x13, x14, [PTR(0), #CTX_HCR_EL2]

	mrs	x15, hstr_el2
	mrs	x16, ICC_SRE_EL2
	stp	x15, x16, [PTR(0), #CTX_HSTR_EL2]

	mrs	x9, ICH_HCR_EL2
	mrs	x10, ICH_VMCR_EL2
	stp	x9, x10, [PTR(0), #CTX_ICH_HCR_EL2]

	mrs	x11, mair_el2
	mrs	x12, mdcr_el2
	stp	x11, x12, [PTR(0), #CTX_MAIR_EL2]

	mrs	x14, sctlr_el2
	str	x14, [PTR(0), #CTX_SCTLR_EL2]

	mrs	x15, spsr_el2
	mrs	x16, sp_el2
	stp	x15, x16, [PTR(0), #CTX_SPSR_EL2]

	mrs	x9, tcr_el2
	mrs	x10, tpidr_el2
	stp	x9, x10, [PTR(0), #CTX_TCR_EL2]

	mrs	x11, ttbr0_el2
	mrs	x12, vbar_el2
	stp	x11, x12, [PTR(0), #CTX_TTBR0_EL2]

	mrs	x13, vmpidr_el2
	mrs	x14, vpidr_el2
	stp	x13, x14, [PTR(0), #CTX_VMPIDR_EL2]

	mrs	x15, vtcr_el2
	mrs	x16, vttbr_el2
	stp	x15, x16, [PTR(0), #CTX_VTCR_EL2]
	ret
endfunc el2_sysregs_context_save_common

func el2_sysregs_context_restore_common
	ldp	x9, x10, [PTR(0), #CTX_ACTLR_EL2]
	msr	actlr_el2, x9
	msr	afsr0_el2, x10

	ldp	x11, x12, [PTR(0), #CTX_AFSR1_EL2]
	msr	afsr1_el2, x11
	msr	amair_el2, x12

	ldp	x13, x14, [PTR(0), #CTX_CNTHCTL_EL2]
	msr	cnthctl_el2, x13
	msr	cntvoff_el2, x14

	ldr	x15, [PTR(0), #CTX_CPTR_EL2]
	msr	cptr_el2, x15

#if CTX_INCLUDE_AARCH32_REGS
	ldr	x16, [PTR(0), #CTX_DBGVCR32_EL2]
	msr	dbgvcr32_el2, x16
#endif /* CTX_INCLUDE_AARCH32_REGS */

	ldp	x9, x10, [PTR(0), #CTX_ELR_EL2]
	msr	elr_el2, x9
	msr	esr_el2, x10

	ldp	x11, x12, [PTR(0), #CTX_FAR_EL2]
	msr	far_el2, x11
	msr	hacr_el2, x12

	ldp	x13, x14, [PTR(0), #CTX_HCR_EL2]
	msr	hcr_el2, x13
	msr	hpfar_el2, x14

	ldp	x15, x16, [PTR(0), #CTX_HSTR_EL2]
	msr	hstr_el2, x15
	msr	ICC_SRE_EL2, x16

	ldp	x9, x10, [PTR(0), #CTX_ICH_HCR_EL2]
	msr	ICH_HCR_EL2, x9
	msr	ICH_VMCR_EL2, x10

	ldp	x11, x12, [PTR(0), #CTX_MAIR_EL2]
	msr	mair_el2, x11
	msr	mdcr_el2, x12

	ldr	x14, [PTR(0), #CTX_SCTLR_EL2]
	msr	sctlr_el2, x14

	ldp	x15, x16, [PTR(0), #CTX_SPSR_EL2]
	msr	spsr_el2, x15
	msr	sp_el2, x16

	ldp	x9, x10, [PTR(0), #CTX_TCR_EL2]
	msr	tcr_el2, x9
	msr	tpidr_el2, x10

	ldp	x11, x12, [PTR(0), #CTX_TTBR0_EL2]
	msr	ttbr0_el2, x11
	msr	vbar_el2, x12

	ldp	x13, x14, [PTR(0), #CTX_VMPIDR_EL2]
	msr	vmpidr_el2, x13
	msr	vpidr_el2, x14

	ldp	x15, x16, [PTR(0), #CTX_VTCR_EL2]
	msr	vtcr_el2, x15
	msr	vttbr_el2, x16
	ret
endfunc el2_sysregs_context_restore_common

#if CTX_INCLUDE_MTE_REGS
func el2_sysregs_context_save_mte
	mrs	x9, TFSR_EL2
	str	x9, [PTR(0), #CTX_TFSR_EL2]
	ret
endfunc el2_sysregs_context_save_mte

func el2_sysregs_context_restore_mte
	ldr	x9, [PTR(0), #CTX_TFSR_EL2]
	msr	TFSR_EL2, x9
	ret
endfunc el2_sysregs_context_restore_mte
#endif /* CTX_INCLUDE_MTE_REGS */

#endif /* CTX_INCLUDE_EL2_REGS */

/* ------------------------------------------------------------------
 * The following function strictly follows the AArch64 PCS to use
 * x9-x17 (temporary caller-saved registers) to save EL1 system
 * register context. It assumes that 'x0' is pointing to a
 * 'el1_sys_regs' structure where the register context will be saved.
 * ------------------------------------------------------------------
 */
func el1_sysregs_context_save

	mrs	x9, spsr_el1
	mrs	PTR(10), PTRN(elr_el1)
	str	x9, [PTR(0), #CTX_SPSR_EL1]
	str	PTR(10), [PTR(0), #CTX_ELR_EL1]

#if !ERRATA_SPECULATIVE_AT
	mrs	x15, sctlr_el1
	mrs	x16, tcr_el1
	stp	x15, x16, [PTR(0), #CTX_SCTLR_EL1]
#endif /* ERRATA_SPECULATIVE_AT */

	mrs	x17, cpacr_el1
	mrs	x9, csselr_el1
	stp	x17, x9, [PTR(0), #CTX_CPACR_EL1]

	mrs	PTR(10), PTRN(sp_el1)
	mrs	x11, esr_el1
	str	x10, [PTR(0), #CTX_SP_EL1]
	str	x11, [PTR(0), #CTX_ESR_EL1]

	mrs	x12, ttbr0_el1
	mrs	x13, ttbr1_el1
	stp	x12, x13, [PTR(0), #CTX_TTBR0_EL1]

	mrs	x14, mair_el1
	mrs	x15, amair_el1
	stp	x14, x15, [PTR(0), #CTX_MAIR_EL1]

	mrs	x16, actlr_el1
	mrs	PTR(17), PTRN(tpidr_el1)
	str	x16, [PTR(0), #CTX_ACTLR_EL1]
	str	PTR(17), [PTR(0), #CTX_TPIDR_EL1]

	mrs	PTR(9), PTRN(tpidr_el0)
	mrs	x10, tpidrro_el0
	str	PTR(9), [PTR(0), #CTX_TPIDR_EL0]
	str	x10, [PTR(0), #CTX_TPIDRRO_EL0]

	mrs	x13, par_el1
	mrs	x14, far_el1
	stp	x13, x14, [PTR(0), #CTX_PAR_EL1]

	mrs	x15, afsr0_el1
	mrs	x16, afsr1_el1
	stp	x15, x16, [PTR(0), #CTX_AFSR0_EL1]

	mrs	x17, contextidr_el1
	mrs	x9, vbar_el1
	stp	x17, x9, [PTR(0), #CTX_CONTEXTIDR_EL1]

	/* Save AArch32 system registers if the build has instructed so */
#if CTX_INCLUDE_AARCH32_REGS
	mrs	x11, spsr_abt
	mrs	x12, spsr_und
	stp	x11, x12, [PTR(0), #CTX_SPSR_ABT]

	mrs	x13, spsr_irq
	mrs	x14, spsr_fiq
	stp	x13, x14, [PTR(0), #CTX_SPSR_IRQ]

	mrs	x15, dacr32_el2
	mrs	x16, ifsr32_el2
	stp	x15, x16, [PTR(0), #CTX_DACR32_EL2]
#endif /* CTX_INCLUDE_AARCH32_REGS */

	/* Save NS timer registers if the build has instructed so */
#if NS_TIMER_SWITCH
	mrs	x10, cntp_ctl_el0
	mrs	x11, cntp_cval_el0
	stp	x10, x11, [PTR(0), #CTX_CNTP_CTL_EL0]

	mrs	x12, cntv_ctl_el0
	mrs	x13, cntv_cval_el0
	stp	x12, x13, [PTR(0), #CTX_CNTV_CTL_EL0]

	mrs	x14, cntkctl_el1
	str	x14, [PTR(0), #CTX_CNTKCTL_EL1]
#endif /* NS_TIMER_SWITCH */

	/* Save MTE system registers if the build has instructed so */
#if CTX_INCLUDE_MTE_REGS
	mrs	x15, TFSRE0_EL1
	mrs	x16, TFSR_EL1
	stp	x15, x16, [PTR(0), #CTX_TFSRE0_EL1]

	mrs	x9, RGSR_EL1
	mrs	x10, GCR_EL1
	stp	x9, x10, [PTR(0), #CTX_RGSR_EL1]
#endif /* CTX_INCLUDE_MTE_REGS */

	ret
endfunc el1_sysregs_context_save

/* ------------------------------------------------------------------
 * The following function strictly follows the AArch64 PCS to use
 * x9-x17 (temporary caller-saved registers) to restore EL1 system
 * register context.  It assumes that 'x0' is pointing to a
 * 'el1_sys_regs' structure from where the register context will be
 * restored
 * ------------------------------------------------------------------
 */
func el1_sysregs_context_restore

	ldr	x9, [PTR(0), #CTX_SPSR_EL1]
	ldr	PTR(10), [PTR(0), #CTX_ELR_EL1]
	msr	spsr_el1, x9
	msr	PTRN(elr_el1), PTR(10)

#if !ERRATA_SPECULATIVE_AT
	ldp	x15, x16, [PTR(0), #CTX_SCTLR_EL1]
	msr	sctlr_el1, x15
	msr	tcr_el1, x16
#endif /* ERRATA_SPECULATIVE_AT */

	ldp	x17, x9, [PTR(0), #CTX_CPACR_EL1]
	msr	cpacr_el1, x17
	msr	csselr_el1, x9

	ldr	PTR(10), [PTR(0), #CTX_SP_EL1]
	ldr	x11, [PTR(0), #CTX_ESR_EL1]
	msr	PTRN(sp_el1), PTR(10)
	msr	esr_el1, x11

	ldp	x12, x13, [PTR(0), #CTX_TTBR0_EL1]
	msr	ttbr0_el1, x12
	msr	ttbr1_el1, x13

	ldp	x14, x15, [PTR(0), #CTX_MAIR_EL1]
	msr	mair_el1, x14
	msr	amair_el1, x15

	ldr 	x16, [PTR(0), #CTX_ACTLR_EL1]
	ldr 	PTR(17), [PTR(0), #CTX_TPIDR_EL1]
	msr	actlr_el1, x16
	msr	PTRN(tpidr_el1), PTR(17)

	ldr	PTR(9), [PTR(0), #CTX_TPIDR_EL0]
	ldr	x10, [PTR(0), #CTX_TPIDRRO_EL0]
	msr	PTRN(tpidr_el0), PTR(9)
	msr	tpidrro_el0, x10

	ldp	x13, x14, [PTR(0), #CTX_PAR_EL1]
	msr	par_el1, x13
	msr	far_el1, x14

	ldp	x15, x16, [PTR(0), #CTX_AFSR0_EL1]
	msr	afsr0_el1, x15
	msr	afsr1_el1, x16

	ldp	x17, x9, [PTR(0), #CTX_CONTEXTIDR_EL1]
	msr	contextidr_el1, x17
	msr	vbar_el1, x9

	/* Restore AArch32 system registers if the build has instructed so */
#if CTX_INCLUDE_AARCH32_REGS
	ldp	x11, x12, [PTR(0), #CTX_SPSR_ABT]
	msr	spsr_abt, x11
	msr	spsr_und, x12

	ldp	x13, x14, [PTR(0), #CTX_SPSR_IRQ]
	msr	spsr_irq, x13
	msr	spsr_fiq, x14

	ldp	x15, x16, [PTR(0), #CTX_DACR32_EL2]
	msr	dacr32_el2, x15
	msr	ifsr32_el2, x16
#endif /* CTX_INCLUDE_AARCH32_REGS */

	/* Restore NS timer registers if the build has instructed so */
#if NS_TIMER_SWITCH
	ldp	x10, x11, [PTR(0), #CTX_CNTP_CTL_EL0]
	msr	cntp_ctl_el0, x10
	msr	cntp_cval_el0, x11

	ldp	x12, x13, [PTR(0), #CTX_CNTV_CTL_EL0]
	msr	cntv_ctl_el0, x12
	msr	cntv_cval_el0, x13

	ldr	x14, [PTR(0), #CTX_CNTKCTL_EL1]
	msr	cntkctl_el1, x14
#endif /* NS_TIMER_SWITCH */

	/* Restore MTE system registers if the build has instructed so */
#if CTX_INCLUDE_MTE_REGS
	ldp	x11, x12, [PTR(0), #CTX_TFSRE0_EL1]
	msr	TFSRE0_EL1, x11
	msr	TFSR_EL1, x12

	ldp	x13, x14, [PTR(0), #CTX_RGSR_EL1]
	msr	RGSR_EL1, x13
	msr	GCR_EL1, x14
#endif /* CTX_INCLUDE_MTE_REGS */

	/* No explict ISB required here as ERET covers it */
	ret
endfunc el1_sysregs_context_restore

/* ------------------------------------------------------------------
 * The following function follows the aapcs_64 strictly to use
 * x9-x17 (temporary caller-saved registers according to AArch64 PCS)
 * to save floating point register context. It assumes that 'x0' is
 * pointing to a 'fp_regs' structure where the register context will
 * be saved.
 *
 * Access to VFP registers will trap if CPTR_EL3.TFP is set.
 * However currently we don't use VFP registers nor set traps in
 * Trusted Firmware, and assume it's cleared.
 *
 * TODO: Revisit when VFP is used in secure world
 * ------------------------------------------------------------------
 */
#if CTX_INCLUDE_FPREGS
func fpregs_context_save
	stp	q0, q1, [PTR(0), #CTX_FP_Q0]
	stp	q2, q3, [PTR(0), #CTX_FP_Q2]
	stp	q4, q5, [PTR(0), #CTX_FP_Q4]
	stp	q6, q7, [PTR(0), #CTX_FP_Q6]
	stp	q8, q9, [PTR(0), #CTX_FP_Q8]
	stp	q10, q11, [PTR(0), #CTX_FP_Q10]
	stp	q12, q13, [PTR(0), #CTX_FP_Q12]
	stp	q14, q15, [PTR(0), #CTX_FP_Q14]
	stp	q16, q17, [PTR(0), #CTX_FP_Q16]
	stp	q18, q19, [PTR(0), #CTX_FP_Q18]
	stp	q20, q21, [PTR(0), #CTX_FP_Q20]
	stp	q22, q23, [PTR(0), #CTX_FP_Q22]
	stp	q24, q25, [PTR(0), #CTX_FP_Q24]
	stp	q26, q27, [PTR(0), #CTX_FP_Q26]
	stp	q28, q29, [PTR(0), #CTX_FP_Q28]
	stp	q30, q31, [PTR(0), #CTX_FP_Q30]

	mrs	x9, fpsr
	str	x9, [PTR(0), #CTX_FP_FPSR]

	mrs	x10, fpcr
	str	x10, [PTR(0), #CTX_FP_FPCR]

#if CTX_INCLUDE_AARCH32_REGS
	mrs	x11, fpexc32_el2
	str	x11, [PTR(0), #CTX_FP_FPEXC32_EL2]
#endif /* CTX_INCLUDE_AARCH32_REGS */
	ret
endfunc fpregs_context_save

/* ------------------------------------------------------------------
 * The following function follows the aapcs_64 strictly to use x9-x17
 * (temporary caller-saved registers according to AArch64 PCS) to
 * restore floating point register context. It assumes that 'x0' is
 * pointing to a 'fp_regs' structure from where the register context
 * will be restored.
 *
 * Access to VFP registers will trap if CPTR_EL3.TFP is set.
 * However currently we don't use VFP registers nor set traps in
 * Trusted Firmware, and assume it's cleared.
 *
 * TODO: Revisit when VFP is used in secure world
 * ------------------------------------------------------------------
 */
func fpregs_context_restore
	ldp	q0, q1, [PTR(0), #CTX_FP_Q0]
	ldp	q2, q3, [PTR(0), #CTX_FP_Q2]
	ldp	q4, q5, [PTR(0), #CTX_FP_Q4]
	ldp	q6, q7, [PTR(0), #CTX_FP_Q6]
	ldp	q8, q9, [PTR(0), #CTX_FP_Q8]
	ldp	q10, q11, [PTR(0), #CTX_FP_Q10]
	ldp	q12, q13, [PTR(0), #CTX_FP_Q12]
	ldp	q14, q15, [PTR(0), #CTX_FP_Q14]
	ldp	q16, q17, [PTR(0), #CTX_FP_Q16]
	ldp	q18, q19, [PTR(0), #CTX_FP_Q18]
	ldp	q20, q21, [PTR(0), #CTX_FP_Q20]
	ldp	q22, q23, [PTR(0), #CTX_FP_Q22]
	ldp	q24, q25, [PTR(0), #CTX_FP_Q24]
	ldp	q26, q27, [PTR(0), #CTX_FP_Q26]
	ldp	q28, q29, [PTR(0), #CTX_FP_Q28]
	ldp	q30, q31, [PTR(0), #CTX_FP_Q30]

	ldr	x9, [PTR(0), #CTX_FP_FPSR]
	msr	fpsr, x9

	ldr	x10, [PTR(0), #CTX_FP_FPCR]
	msr	fpcr, x10

#if CTX_INCLUDE_AARCH32_REGS
	ldr	x11, [PTR(0), #CTX_FP_FPEXC32_EL2]
	msr	fpexc32_el2, x11
#endif /* CTX_INCLUDE_AARCH32_REGS */

	/*
	 * No explict ISB required here as ERET to
	 * switch to secure EL1 or non-secure world
	 * covers it
	 */

	ret
endfunc fpregs_context_restore
#endif /* CTX_INCLUDE_FPREGS */

	/*
	 * Set SCR_EL3.EA bit to enable SErrors at EL3
	 */
	.macro enable_serror_at_el3
	mrs     x8, scr_el3
	orr     x8, x8, #SCR_EA_BIT
	msr     scr_el3, x8
	.endm

	/*
	 * Set the PSTATE bits not set when the exception was taken as
	 * described in the AArch64.TakeException() pseudocode function
	 * in ARM DDI 0487F.c page J1-7635 to a default value.
	 */
	.macro set_unset_pstate_bits
	/*
	 * If Data Independent Timing (DIT) functionality is implemented,
	 * always enable DIT in EL3
	 */
#if ENABLE_FEAT_DIT
#if ENABLE_FEAT_DIT == 2
	mrs	x8, id_aa64pfr0_el1
	and	x8, x8, #(ID_AA64PFR0_DIT_MASK << ID_AA64PFR0_DIT_SHIFT)
	cbz	x8, 1f
#endif
	mov     x8, #DIT_BIT
	msr     DIT, x8
1:
#endif /* ENABLE_FEAT_DIT */
	.endm /* set_unset_pstate_bits */

/* ------------------------------------------------------------------
 * The following macro is used to save and restore all the general
 * purpose and ARMv8.3-PAuth (if enabled) registers.
 * It also checks if the Secure Cycle Counter (PMCCNTR_EL0)
 * is disabled in EL3/Secure (ARMv8.5-PMU), wherein PMCCNTR_EL0
 * needs not to be saved/restored during world switch.
 *
 * Ideally we would only save and restore the callee saved registers
 * when a world switch occurs but that type of implementation is more
 * complex. So currently we will always save and restore these
 * registers on entry and exit of EL3.
 * clobbers: x18
 * ------------------------------------------------------------------
 */
	.macro save_gp_pmcr_pauth_regs
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
	mrs	PTR(18), PTRN(sp_el0)
	str	PTR(18), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_SP_EL0]

	/* PMUv3 is presumed to be always present */
	mrs	x9, pmcr_el0
	str	x9, [PTRN(sp), #CTX_EL3STATE_OFFSET + CTX_PMCR_EL0]
	/* Disable cycle counter when event counting is prohibited */
	orr	x9, x9, #PMCR_EL0_DP_BIT
	msr	pmcr_el0, x9
	isb
#if CTX_INCLUDE_PAUTH_REGS
	/* ----------------------------------------------------------
 	 * Save the ARMv8.3-PAuth keys as they are not banked
 	 * by exception level
	 * ----------------------------------------------------------
	 */
	add	x19, sp, #CTX_PAUTH_REGS_OFFSET

	mrs	x20, APIAKeyLo_EL1	/* x21:x20 = APIAKey */
	mrs	x21, APIAKeyHi_EL1
	mrs	x22, APIBKeyLo_EL1	/* x23:x22 = APIBKey */
	mrs	x23, APIBKeyHi_EL1
	mrs	x24, APDAKeyLo_EL1	/* x25:x24 = APDAKey */
	mrs	x25, APDAKeyHi_EL1
	mrs	x26, APDBKeyLo_EL1	/* x27:x26 = APDBKey */
	mrs	x27, APDBKeyHi_EL1
	mrs	x28, APGAKeyLo_EL1	/* x29:x28 = APGAKey */
	mrs	x29, APGAKeyHi_EL1

	stp	x20, x21, [x19, #CTX_PACIAKEY_LO]
	stp	x22, x23, [x19, #CTX_PACIBKEY_LO]
	stp	x24, x25, [x19, #CTX_PACDAKEY_LO]
	stp	x26, x27, [x19, #CTX_PACDBKEY_LO]
	stp	x28, x29, [x19, #CTX_PACGAKEY_LO]
#endif /* CTX_INCLUDE_PAUTH_REGS */
	.endm /* save_gp_pmcr_pauth_regs */

/* -----------------------------------------------------------------
 * This function saves the context and sets the PSTATE to a known
 * state, preparing entry to el3.
 * Save all the general purpose and ARMv8.3-PAuth (if enabled)
 * registers.
 * Then set any of the PSTATE bits that are not set by hardware
 * according to the Aarch64.TakeException pseudocode in the Arm
 * Architecture Reference Manual to a default value for EL3.
 * clobbers: x17
 * -----------------------------------------------------------------
 */
func prepare_el3_entry
	save_gp_pmcr_pauth_regs
	enable_serror_at_el3
	/*
	 * Set the PSTATE bits not described in the Aarch64.TakeException
	 * pseudocode to their default values.
	 */
	set_unset_pstate_bits
	ret
endfunc prepare_el3_entry

/* ------------------------------------------------------------------
 * This function restores ARMv8.3-PAuth (if enabled) and all general
 * purpose registers except x30 from the CPU context.
 * x30 register must be explicitly restored by the caller.
 * ------------------------------------------------------------------
 */
func restore_gp_pmcr_pauth_regs
#if CTX_INCLUDE_PAUTH_REGS
 	/* Restore the ARMv8.3 PAuth keys */
	add	x10, sp, #CTX_PAUTH_REGS_OFFSET

	ldp	x0, x1, [x10, #CTX_PACIAKEY_LO]	/* x1:x0 = APIAKey */
	ldp	x2, x3, [x10, #CTX_PACIBKEY_LO]	/* x3:x2 = APIBKey */
	ldp	x4, x5, [x10, #CTX_PACDAKEY_LO]	/* x5:x4 = APDAKey */
	ldp	x6, x7, [x10, #CTX_PACDBKEY_LO]	/* x7:x6 = APDBKey */
	ldp	x8, x9, [x10, #CTX_PACGAKEY_LO]	/* x9:x8 = APGAKey */

	msr	APIAKeyLo_EL1, x0
	msr	APIAKeyHi_EL1, x1
	msr	APIBKeyLo_EL1, x2
	msr	APIBKeyHi_EL1, x3
	msr	APDAKeyLo_EL1, x4
	msr	APDAKeyHi_EL1, x5
	msr	APDBKeyLo_EL1, x6
	msr	APDBKeyHi_EL1, x7
	msr	APGAKeyLo_EL1, x8
	msr	APGAKeyHi_EL1, x9
#endif /* CTX_INCLUDE_PAUTH_REGS */

	/* PMUv3 is presumed to be always present */
	ldr	PTR(0), [PTRN(sp), #CTX_EL3STATE_OFFSET + CTX_PMCR_EL0]
	msr	pmcr_el0, x0
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
	ldr	PTR(28), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_SP_EL0]
	msr	PTRN(sp_el0), PTR(28)
	ldp	PTR(28), PTR(29), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_X28]
	ret
endfunc restore_gp_pmcr_pauth_regs

/*
 * In case of ERRATA_SPECULATIVE_AT, save SCTLR_EL1 and TCR_EL1
 * registers and update EL1 registers to disable stage1 and stage2
 * page table walk
 */
func save_and_update_ptw_el1_sys_regs
	/* ----------------------------------------------------------
	 * Save only sctlr_el1 and tcr_el1 registers
	 * ----------------------------------------------------------
	 */
	mrs	x29, sctlr_el1
	str	x29, [PTRN(sp), #(CTX_EL1_SYSREGS_OFFSET + CTX_SCTLR_EL1)]
	mrs	x29, tcr_el1
	str	x29, [PTRN(sp), #(CTX_EL1_SYSREGS_OFFSET + CTX_TCR_EL1)]

	/* ------------------------------------------------------------
	 * Must follow below order in order to disable page table
	 * walk for lower ELs (EL1 and EL0). First step ensures that
	 * page table walk is disabled for stage1 and second step
	 * ensures that page table walker should use TCR_EL1.EPDx
	 * bits to perform address translation. ISB ensures that CPU
	 * does these 2 steps in order.
	 *
	 * 1. Update TCR_EL1.EPDx bits to disable page table walk by
	 *    stage1.
	 * 2. Enable MMU bit to avoid identity mapping via stage2
	 *    and force TCR_EL1.EPDx to be used by the page table
	 *    walker.
	 * ------------------------------------------------------------
	 */
	orr	x29, x29, #(TCR_EPD0_BIT)
	orr	x29, x29, #(TCR_EPD1_BIT)
	msr	tcr_el1, x29
	isb
	mrs	x29, sctlr_el1
	orr	x29, x29, #SCTLR_M_BIT
	msr	sctlr_el1, x29
	isb

	ret
endfunc save_and_update_ptw_el1_sys_regs

/* ------------------------------------------------------------------
 * This routine assumes that the SP_EL3 is pointing to a valid
 * context structure from where the gp regs and other special
 * registers can be retrieved.
 * ------------------------------------------------------------------
 */
func el3_exit
#if ENABLE_ASSERTIONS
	/* el3_exit assumes SP_EL0 on entry */
	mrs	x17, spsel
	cmp	x17, #MODE_SP_EL0
	ASM_ASSERT(eq)
#endif /* ENABLE_ASSERTIONS */

	/* ----------------------------------------------------------
	 * Save the current SP_EL0 i.e. the EL3 runtime stack which
	 * will be used for handling the next SMC.
	 * Then switch to SP_EL3.
	 * ----------------------------------------------------------
	 */
	mov	PTR(17), PTRN(sp)
	msr	spsel, #MODE_SP_ELX
	str	PTR(17), [PTRN(sp), #CTX_EL3STATE_OFFSET + CTX_RUNTIME_SP]

#if IMAGE_BL31
	/* ----------------------------------------------------------
	 * Restore CPTR_EL3.
	 * ZCR is only restored if SVE is supported and enabled.
	 * Synchronization is required before zcr_el3 is addressed.
	 * ----------------------------------------------------------
	 */
	ldr	x19, [PTRN(sp), #CTX_EL3STATE_OFFSET + CTX_CPTR_EL3]
	ldr	x20, [PTRN(sp), #CTX_EL3STATE_OFFSET + CTX_ZCR_EL3]
	msr	cptr_el3, x19

	ands	x19, x19, #CPTR_EZ_BIT
	beq	sve_not_enabled

	isb
	msr	S3_6_C1_C2_0, x20 /* zcr_el3 */
sve_not_enabled:
#endif /* IMAGE_BL31 */

#if IMAGE_BL31 && DYNAMIC_WORKAROUND_CVE_2018_3639
	/* ----------------------------------------------------------
	 * Restore mitigation state as it was on entry to EL3
	 * ----------------------------------------------------------
	 */
	ldr	PTR(17), [PTRN(sp), #CTX_CVE_2018_3639_OFFSET + CTX_CVE_2018_3639_DISABLE]
	cbz	x17, 1f
	blr	PTR(17)
1:
#endif /* IMAGE_BL31 && DYNAMIC_WORKAROUND_CVE_2018_3639 */

/*
 * This is a hot path, so we don't want to do some actual FEAT_RAS runtime
 * detection here. The "esb" is a cheaper variant, so using "dsb" in the
 * ENABLE_FEAT_RAS==2 case is not ideal, but won't hurt.
 */
#if IMAGE_BL31 && ENABLE_FEAT_RAS == 1
	/* ----------------------------------------------------------
	 * Issue Error Synchronization Barrier to synchronize SErrors
	 * before exiting EL3. We're running with EAs unmasked, so
	 * any synchronized errors would be taken immediately;
	 * therefore no need to inspect DISR_EL1 register.
 	 * ----------------------------------------------------------
	 */
	esb
#else
	dsb	sy
#endif /* IMAGE_BL31 && ENABLE_FEAT_RAS */

	/* ----------------------------------------------------------
	 * Restore SPSR_EL3, ELR_EL3 and SCR_EL3 prior to ERET
	 * ----------------------------------------------------------
	 */
	ldr	x18, [PTRN(sp), #CTX_EL3STATE_OFFSET + CTX_SCR_EL3]
	ldr	x16, [PTRN(sp), #CTX_EL3STATE_OFFSET + CTX_SPSR_EL3]
	ldr	x17, [PTRN(sp), #CTX_EL3STATE_OFFSET + CTX_ELR_EL3]

	msr	scr_el3, x18
	msr	spsr_el3, x16
#if ENABLE_MORELLO_CAP
	/* Restore the saved DDC_EL0 value. */
	ldr	c24, [sp, #CTX_EL3STATE_OFFSET + CTX_DDC_EL0]
	msr	ddc_el0, c24
	cvtp	c17, x17
	msr	celr_el3, c17
#else
	msr	elr_el3, x17
#endif

	restore_ptw_el1_sys_regs

	/* ----------------------------------------------------------
	 * Restore general purpose (including x30), PMCR_EL0 and
	 * ARMv8.3-PAuth registers.
	 * Exit EL3 via ERET to a lower exception level.
 	 * ----------------------------------------------------------
 	 */
	bl	restore_gp_pmcr_pauth_regs
	ldr	PTR(30), [PTRN(sp), #CTX_GPREGS_OFFSET + CTX_GPREG_LR]

#ifdef IMAGE_BL31
	str	xzr, [PTRN(sp), #CTX_EL3STATE_OFFSET + CTX_IS_IN_EL3]
#endif /* IMAGE_BL31 */

	exception_return

endfunc el3_exit

#if ENABLE_MORELLO_CAP
func save_ddc_el0
	/* This function should be called only when SP is SP_EL0 */
	mrs c1, ddc
	str c1, [c0]
	ret
endfunc save_ddc_el0
#endif
