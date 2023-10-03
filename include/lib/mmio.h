/*
 * Copyright (c) 2013-2014, ARM Limited and Contributors. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#ifndef MMIO_H
#define MMIO_H

#include <arch_helpers.h>
#include <stdint.h>

static inline void mmio_write_8(uintptr_t addr, uint8_t value)
{
	uintptr_t cap;

	cap = make_cap(addr);

	*(volatile uint8_t*)cap = value;
}

static inline uint8_t mmio_read_8(uintptr_t addr)
{
	uintptr_t cap;

	cap = make_cap(addr);

	return *(volatile uint8_t*)cap;
}

static inline void mmio_write_16(uintptr_t addr, uint16_t value)
{
	uintptr_t cap;

	cap = make_cap(addr);

	*(volatile uint16_t*)cap = value;
}

static inline uint16_t mmio_read_16(uintptr_t addr)
{
	uintptr_t cap;

	cap = make_cap(addr);

	return *(volatile uint16_t*)cap;
}

static inline void mmio_clrsetbits_16(uintptr_t addr,
				uint16_t clear,
				uint16_t set)
{
	uintptr_t cap;

	cap = make_cap(addr);

	mmio_write_16(cap, (mmio_read_16(cap) & ~clear) | set);
}

static inline void mmio_write_32(uintptr_t addr, uint32_t value)
{
	uintptr_t cap;

	cap = make_cap(addr);

	*(volatile uint32_t*)cap = value;
}

static inline uint32_t mmio_read_32(uintptr_t addr)
{
	uintptr_t cap;

	cap = make_cap(addr);

	return *(volatile uint32_t*)cap;
}

static inline void mmio_write_64(uintptr_t addr, uint64_t value)
{
	uintptr_t cap;

	cap = make_cap(addr);

	*(volatile uint64_t*)cap = value;
}

static inline uint64_t mmio_read_64(uintptr_t addr)
{
	uintptr_t cap;

	cap = make_cap(addr);

	return *(volatile uint64_t*)cap;
}

static inline void mmio_clrbits_32(uintptr_t addr, uint32_t clear)
{
	uintptr_t cap;

	cap = make_cap(addr);

	mmio_write_32(cap, mmio_read_32(cap) & ~clear);
}

static inline void mmio_setbits_32(uintptr_t addr, uint32_t set)
{
	uintptr_t cap;

	cap = make_cap(addr);

	mmio_write_32(cap, mmio_read_32(cap) | set);
}

static inline void mmio_clrsetbits_32(uintptr_t addr,
				uint32_t clear,
				uint32_t set)
{
	uintptr_t cap;

	cap = make_cap(addr);

	mmio_write_32(cap, (mmio_read_32(cap) & ~clear) | set);
}

#endif /* MMIO_H */
