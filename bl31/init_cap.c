/*-
 * Copyright (c) 2023 Ruslan Bukin <br@bsdpad.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#include <stdint.h>
#include <export/common/bl_common_exp.h>

#include "aarch64/cherireg.h"

#define	cheri_setaddress(x, y)	__builtin_cheri_address_set((x), (y))
#define	cheri_setbounds(x, y)	__builtin_cheri_bounds_set((x), (y))
#define	cheri_clearperm(x, y)	__builtin_cheri_perms_and((x), ~(y))

struct local_data {
	struct bl_params local_bl_params;
	struct bl_params_node local_params_node;
	struct image_info local_image_info;
	struct entry_point_info local_ep_info;
};

static struct local_data d[32];

void *kernel_root_cap = (void *)(intptr_t) - 1;

#if __has_feature(capabilities)
void
cheri_init_capabilities(void * __capability kroot)
{

	kernel_root_cap = cheri_clearperm(kroot,
	    (CHERI_PERM_SEAL | CHERI_PERM_UNSEAL));
	kernel_root_cap = kroot;
}

void *
cheri_convert_params_once(struct bl_params_node64 *node64, int index)
{
	//struct image_info *image_info;
	struct image_info64 *image_info64;
	struct entry_point_info64 *ep_info64;
	struct bl_params_node *node;

	image_info64 = cheri_setaddress(kernel_root_cap, node64->image_info);
	ep_info64 = cheri_setaddress(kernel_root_cap, node64->ep_info);

	node = &d[index].local_params_node;
	node->image_id = node64->image_id;

	node->image_info = &d[index].local_image_info;
	node->image_info->h = image_info64->h;
	node->image_info->image_base = (uintptr_t)
	    cheri_setaddress(kernel_root_cap, image_info64->image_base);
	node->image_info->image_size = image_info64->image_size;
	node->image_info->image_max_size = image_info64->image_max_size;

	node->ep_info = &d[index].local_ep_info;
	node->ep_info->h = ep_info64->h;
	node->ep_info->pc = (uintptr_t)cheri_setaddress(kernel_root_cap, ep_info64->pc);
	node->ep_info->spsr = ep_info64->spsr;
	node->ep_info->args = ep_info64->args;

	return (node);
}

void *
cheri_convert_params(bl_params64_t *params64)
{
	struct bl_params *params;
	struct bl_params_node64 *node64;
	struct bl_params_node *node, *prev_node;
	int index;

	index = 0;

	node64 = cheri_setaddress(kernel_root_cap, params64->head);
	node = cheri_convert_params_once(node64, index);

	params = &d[index].local_bl_params;
	params->h = params64->h;
	params->head = node;

	while (node64->next_params_info != 0) {
		index += 1;
		prev_node = node;
		node64 = cheri_setaddress(kernel_root_cap,
		    node64->next_params_info);
		node = cheri_convert_params_once(node64, index);
		prev_node->next_params_info = node;
	}

	return (params);
}
#endif

uintptr_t
make_cap(uint64_t addr)
{
	uintptr_t cap;

#ifdef __CHERI_PURE_CAPABILITY__
	cap = (uintptr_t)cheri_setaddress(kernel_root_cap, addr);
#else
	cap = (uintptr_t)addr;
#endif

	return (cap);
}

uintptr_t
set_bounds(uintptr_t cap0, uint64_t size)
{
	uintptr_t cap;

	cap = cheri_setbounds(cap0, size);

	return (cap);
}

uintptr_t
make_cap_size(uint64_t addr, uint64_t size)
{
	uintptr_t cap;

	cap = make_cap(addr);
	cap = cheri_setbounds(cap, size);

	return (cap);
}
