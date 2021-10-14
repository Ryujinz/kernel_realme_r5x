/*
 * memchr - find a character in a memory zone
 *
 * Copyright (c) 2014-2019, Arm Limited.
 * SPDX-License-Identifier: MIT
 */

/* Assumptions:
 *
 * ARMv8-a, AArch64
 * Neon Available.
 */

#include <linux/linkage.h>
#include <asm/assembler.h>

/* Arguments and results.  */
#define srcin		x0
#define chrin		w1
#define cntin		x2

#define result		x0

#define src		x3
#define	tmp		x4
#define wtmp2		w5
#define synd		x6
#define soff		x9
#define cntrem		x10

#define vrepchr		v0
#define vdata1		v1
#define vdata2		v2
#define vhas_chr1	v3
#define vhas_chr2	v4
#define vrepmask	v5
#define vend		v6

/*
 * Core algorithm:
 *
 * For each 32-byte chunk we calculate a 64-bit syndrome value, with two bits
 * per byte. For each tuple, bit 0 is set if the relevant byte matched the
 * requested character and bit 1 is not used (faster than using a 32bit
 * syndrome). Since the bits in the syndrome reflect exactly the order in which
 * things occur in the original string, counting trailing zeros allows to
 * identify exactly which byte has matched.
 */
SYM_FUNC_START_WEAK_PI(memchr)
	and	w1, w1, #0xff
1:	subs	x2, x2, #1
	b.mi	2f
	ldrb	w3, [x0], #1
	cmp	w3, w1
	b.ne	1b
	sub	x0, x0, #1
	ret

Lzero_length:
	mov	result, #0
	ret
SYM_FUNC_END_PI(memchr)
