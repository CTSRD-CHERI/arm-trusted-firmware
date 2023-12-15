/*
 * Copyright (c) 2013-2021, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <platform_def.h>

#include <arch.h>
#include <common/bl_common.h>
#include <el3_common_macros.S>
#include <lib/pmf/aarch64/pmf_asm_macros.S>
#include <lib/runtime_instr.h>
#include <lib/xlat_tables/xlat_mmu_helpers.h>

#include "cherireg.h"

	.globl	bl31_entrypoint
	.globl	bl31_warm_entrypoint

	/* -----------------------------------------------------
	 * bl31_entrypoint() is the cold boot entrypoint,
	 * executed only by the primary cpu.
	 * -----------------------------------------------------
	 */

func bl31_entrypoint
	//hlt 0x1

	/* Enable Morello instructions at EL3 */
	mrs	x2, cptr_el3
	orr	x2, x2, (1 << 9)
	msr	cptr_el3, x2
	isb

#ifdef __CHERI_PURE_CAPABILITY__
	mrs	x2, cctlr_el3
	bic	x2, x2, (1 << 2) /* DDCBO */
	bic	x2, x2, (1 << 3) /* PCCBO */
	bic	x2, x2, (1 << 4) /* ADRDPB */
	orr	x2, x2, (1 << 5) /* C64E */
	orr	x2, x2, (1 << 6) /* PERMVCT */
	orr	x2, x2, (1 << 7) /* SBL */
	msr	cctlr_el3, x2

	bx	#4
	.arch_extension c64

	/* ---------------------------------------------------------------
	 * Stash the previous bootloader arguments x0 - x3 for later use.
	 * ---------------------------------------------------------------
	 */
	cvtd	c20, x0
	cvtd	c21, x1
	cvtd	c22, x2
	cvtd	c23, x3

	ldr	x0, =~CHERI_PERMS_KERNEL_DATA
	mrs	c1, ddc
	clrperm	c1, c1, x0
	ldr	x0, =~CHERI_PERMS_KERNEL_CODE
	adr	c2, #0
	clrperm	c2, c2, x0
	bl	crt_init_globals

	/* Initialize capabilities. */
	mrs	c0, ddc
	bl	cheri_init_capabilities
#else
	/* ---------------------------------------------------------------
	 * Stash the previous bootloader arguments x0 - x3 for later use.
	 * ---------------------------------------------------------------
	 */
	mov	x20, x0
	mov	x21, x1
	mov	x22, x2
	mov	x23, x3
#endif


#if !RESET_TO_BL31
	/* ---------------------------------------------------------------------
	 * For !RESET_TO_BL31 systems, only the primary CPU ever reaches
	 * bl31_entrypoint() during the cold boot flow, so the cold/warm boot
	 * and primary/secondary CPU logic should not be executed in this case.
	 *
	 * Also, assume that the previous bootloader has already initialised the
	 * SCTLR_EL3, including the endianness, and has initialised the memory.
	 * ---------------------------------------------------------------------
	 */
	el3_entrypoint_common					\
		_init_sctlr=0					\
		_warm_boot_mailbox=0				\
		_secondary_cold_boot=0				\
		_init_memory=0					\
		_init_c_runtime=1				\
		_exception_vectors=runtime_exceptions		\
		_pie_fixup_size=BL31_LIMIT - BL31_BASE
#else

	/* ---------------------------------------------------------------------
	 * For RESET_TO_BL31 systems which have a programmable reset address,
	 * bl31_entrypoint() is executed only on the cold boot path so we can
	 * skip the warm boot mailbox mechanism.
	 * ---------------------------------------------------------------------
	 */
	el3_entrypoint_common					\
		_init_sctlr=1					\
		_warm_boot_mailbox=!PROGRAMMABLE_RESET_ADDRESS	\
		_secondary_cold_boot=!COLD_BOOT_SINGLE_CPU	\
		_init_memory=1					\
		_init_c_runtime=1				\
		_exception_vectors=runtime_exceptions		\
		_pie_fixup_size=BL31_LIMIT - BL31_BASE
#endif /* RESET_TO_BL31 */

	/* --------------------------------------------------------------------
	 * Perform BL31 setup
	 * --------------------------------------------------------------------
	 */
	mov	CAP(0), CAP(20)
#ifdef __CHERI_PURE_CAPABILITY__
	bl	cheri_convert_params
#endif
	mov	CAP(1), CAP(21)
	mov	CAP(2), CAP(22)
	mov	CAP(3), CAP(23)
	bl	bl31_setup

#if ENABLE_PAUTH
	/* --------------------------------------------------------------------
	 * Program APIAKey_EL1 and enable pointer authentication
	 * --------------------------------------------------------------------
	 */
	bl	pauth_init_enable_el3
#endif /* ENABLE_PAUTH */

	/* --------------------------------------------------------------------
	 * Jump to main function
	 * --------------------------------------------------------------------
	 */
	bl	bl31_main

	/* --------------------------------------------------------------------
	 * Clean the .data & .bss sections to main memory. This ensures
	 * that any global data which was initialised by the primary CPU
	 * is visible to secondary CPUs before they enable their data
	 * caches and participate in coherency.
	 * --------------------------------------------------------------------
	 */
	LDR_LABEL(CAP(0), __DATA_START__)
	LDR_LABEL(CAP(1), __DATA_END__)
	sub	x1, x1, x0
	bl	clean_dcache_range

	LDR_LABEL(CAP(0), __BSS_START__)
	LDR_LABEL(CAP(1), __BSS_END__)
	sub	x1, x1, x0
	bl	clean_dcache_range

	b	el3_exit
endfunc bl31_entrypoint

	/* --------------------------------------------------------------------
	 * This CPU has been physically powered up. It is either resuming from
	 * suspend or has simply been turned on. In both cases, call the BL31
	 * warmboot entrypoint
	 * --------------------------------------------------------------------
	 */
func bl31_warm_entrypoint

#ifdef __CHERI_PURE_CAPABILITY__
	/* Enable Morello instructions at EL3 */
	mrs	x2, cptr_el3
	orr	x2, x2, (1 << 9)
	msr	cptr_el3, x2
	isb

	mrs	x2, cctlr_el3
	bic	x2, x2, (1 << 2) /* DDCBO */
	bic	x2, x2, (1 << 3) /* PCCBO */
	bic	x2, x2, (1 << 4) /* ADRDPB */
	orr	x2, x2, (1 << 5) /* C64E */
	orr	x2, x2, (1 << 6) /* PERMVCT */
	orr	x2, x2, (1 << 7) /* SBL */
	msr	cctlr_el3, x2

	bx	#4
	.arch_extension c64
#endif

#if ENABLE_RUNTIME_INSTRUMENTATION

	/*
	 * This timestamp update happens with cache off.  The next
	 * timestamp collection will need to do cache maintenance prior
	 * to timestamp update.
	 */
	pmf_calc_timestamp_addr rt_instr_svc, RT_INSTR_EXIT_HW_LOW_PWR
	mrs	x1, cntpct_el0
	str	x1, [x0]
#endif

	/*
	 * On the warm boot path, most of the EL3 initialisations performed by
	 * 'el3_entrypoint_common' must be skipped:
	 *
	 *  - Only when the platform bypasses the BL1/BL31 entrypoint by
	 *    programming the reset address do we need to initialise SCTLR_EL3.
	 *    In other cases, we assume this has been taken care by the
	 *    entrypoint code.
	 *
	 *  - No need to determine the type of boot, we know it is a warm boot.
	 *
	 *  - Do not try to distinguish between primary and secondary CPUs, this
	 *    notion only exists for a cold boot.
	 *
	 *  - No need to initialise the memory or the C runtime environment,
	 *    it has been done once and for all on the cold boot path.
	 */
	el3_entrypoint_common					\
		_init_sctlr=PROGRAMMABLE_RESET_ADDRESS		\
		_warm_boot_mailbox=0				\
		_secondary_cold_boot=0				\
		_init_memory=0					\
		_init_c_runtime=0				\
		_exception_vectors=runtime_exceptions		\
		_pie_fixup_size=0

	/*
	 * We're about to enable MMU and participate in PSCI state coordination.
	 *
	 * The PSCI implementation invokes platform routines that enable CPUs to
	 * participate in coherency. On a system where CPUs are not
	 * cache-coherent without appropriate platform specific programming,
	 * having caches enabled until such time might lead to coherency issues
	 * (resulting from stale data getting speculatively fetched, among
	 * others). Therefore we keep data caches disabled even after enabling
	 * the MMU for such platforms.
	 *
	 * On systems with hardware-assisted coherency, or on single cluster
	 * platforms, such platform specific programming is not required to
	 * enter coherency (as CPUs already are); and there's no reason to have
	 * caches disabled either.
	 */
#if HW_ASSISTED_COHERENCY || WARMBOOT_ENABLE_DCACHE_EARLY
	mov	x0, xzr
#else
	mov	x0, #DISABLE_DCACHE
#endif
	bl	bl31_plat_enable_mmu

#if ENABLE_RME
	/*
	 * At warm boot GPT data structures have already been initialized in RAM
	 * but the sysregs for this CPU need to be initialized. Note that the GPT
	 * accesses are controlled attributes in GPCCR and do not depend on the
	 * SCR_EL3.C bit.
	 */
	bl	gpt_enable
	cbz	x0, 1f
	no_ret plat_panic_handler
1:
#endif

#if ENABLE_PAUTH
	/* --------------------------------------------------------------------
	 * Program APIAKey_EL1 and enable pointer authentication
	 * --------------------------------------------------------------------
	 */
	bl	pauth_init_enable_el3
#endif /* ENABLE_PAUTH */

	bl	psci_warmboot_entrypoint

#if ENABLE_RUNTIME_INSTRUMENTATION
	pmf_calc_timestamp_addr rt_instr_svc, RT_INSTR_EXIT_PSCI
	mov	x19, x0

	/*
	 * Invalidate before updating timestamp to ensure previous timestamp
	 * updates on the same cache line with caches disabled are properly
	 * seen by the same core. Without the cache invalidate, the core might
	 * write into a stale cache line.
	 */
	mov	x1, #PMF_TS_SIZE
	mov	x20, x30
	bl	inv_dcache_range
	mov	x30, x20

	mrs	x0, cntpct_el0
	str	x0, [CAP(19)]
#endif
	b	el3_exit
endfunc bl31_warm_entrypoint
