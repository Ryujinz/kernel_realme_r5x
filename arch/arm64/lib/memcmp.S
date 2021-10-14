/* SPDX-License-Identifier: GPL-2.0-only */
/*
 * Copyright (c) 2013-2020, Arm Limited.
 *
 * Adapted from the original at:
 * https://github.com/ARM-software/optimized-routines/blob/master/string/aarch64/memcmp.S
 */

#include <linux/linkage.h>
#include <asm/assembler.h>

/* Parameters and result.  */
#define src1		x0
#define src2		x1
#define limit		x2
#define result		w0

/* Internal variables.  */
#define data1		x3
#define data1w		w3
#define data2		x4
#define data2w		w4
#define tmp1		x5

/* Small inputs of less than 8 bytes are handled separately.  This allows the
   main code to be sped up using unaligned loads since there are now at least
   8 bytes to be compared.  If the first 8 bytes are equal, align src1.
   This ensures each iteration does at most one unaligned access even if both
   src1 and src2 are unaligned, and mutually aligned inputs behave as if
   aligned.  After the main loop, process the last 8 bytes using unaligned
   accesses.  */

.p2align 6
SYM_FUNC_START_WEAK_PI(memcmp)
	subs	limit, limit, 8
	b.lo	.Lless8

	/* Limit >= 8, so check first 8 bytes using unaligned loads.  */
	ldr	data1, [src1], 8
	ldr	data2, [src2], 8
	and	tmp1, src1, 7
	add	limit, limit, tmp1
	cmp	data1, data2
	bne	.Lreturn

	/* Align src1 and adjust src2 with bytes not yet done.  */
	sub	src1, src1, tmp1
	sub	src2, src2, tmp1

	subs	limit, limit, 8
	b.ls	.Llast_bytes

	/* Loop performing 8 bytes per iteration using aligned src1.
	   Limit is pre-decremented by 8 and must be larger than zero.
	   Exit if <= 8 bytes left to do or if the data is not equal.  */
	.p2align 4
.Lloop8:
	ldr	data1, [src1], 8
	ldr	data2, [src2], 8
	subs	limit, limit, 8
	ccmp	data1, data2, 0, hi  /* NZCV = 0b0000.  */
	b.eq	.Lloop8

	cmp	data1, data2
	bne	.Lreturn

	/* Compare last 1-8 bytes using unaligned access.  */
.Llast_bytes:
	ldr	data1, [src1, limit]
	ldr	data2, [src2, limit]

	/* Compare data bytes and set return value to 0, -1 or 1.  */
.Lreturn:
#ifndef __AARCH64EB__
	rev	data1, data1
	rev	data2, data2
#endif
	cmp     data1, data2
.Lret_eq:
	cset	result, ne
	cneg	result, result, lo
        ret

	.p2align 4
	/* Compare up to 8 bytes.  Limit is [-8..-1].  */
.Lless8:
	adds	limit, limit, 4
	b.lo	.Lless4
	ldr	data1w, [src1], 4
	ldr	data2w, [src2], 4
	cmp	data1w, data2w
	b.ne	.Lreturn
	sub	limit, limit, 4
.Lless4:
	adds	limit, limit, 4
	beq	.Lret_eq
.Lbyte_loop:
	ldrb	data1w, [src1], 1
	ldrb	data2w, [src2], 1
	subs	limit, limit, 1
	ccmp	data1w, data2w, 0, ne	/* NZCV = 0b0000.  */
	b.eq	.Lbyte_loop
	sub	result, data1w, data2w
	ret
SYM_FUNC_END_PI(memcmp)
