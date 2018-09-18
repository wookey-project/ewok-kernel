/* \file soc-dma-regs.h
 *
 * Copyright 2018 The wookey project team <wookey@ssi.gouv.fr>
 *   - Ryad     Benadjila
 *   - Arnauld  Michelizza
 *   - Mathieu  Renard
 *   - Philippe Thierry
 *   - Philippe Trebuchet
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 *     Unless required by applicable law or agreed to in writing, software
 *     distributed under the License is distributed on an "AS IS" BASIS,
 *     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *     See the License for the specific language governing permissions and
 *     limitations under the License.
 *
 */
#ifndef SOC_DMA_REGS_H
#define  SOC_DMA_REGS_H

/* TODO: DMA1 + DMA2 */
#define DMA1_BASE			0x40026000
#define DMA2_BASE			0x40026400
#define DMA_BASE(n)			(n == 1 ? DMA1_BASE : DMA2_BASE)

#define r_CORTEX_M_DMA_LISR(ctrl)		REG_ADDR(DMA_BASE(ctrl) + 0x00)
#define r_CORTEX_M_DMA_HISR(ctrl)		REG_ADDR(DMA_BASE(ctrl) + 0x04)
#define r_CORTEX_M_DMA_LIFCR(ctrl)		REG_ADDR(DMA_BASE(ctrl) + 0x08)
#define r_CORTEX_M_DMA_HIFCR(ctrl)		REG_ADDR(DMA_BASE(ctrl) + 0x0c)
#define r_CORTEX_M_DMA_SxCR(ctrl, stream)	REG_ADDR(DMA_BASE(ctrl) + 0x10 + (stream * 0x18))
#define r_CORTEX_M_DMA_SxNDTR(ctrl, stream)	REG_ADDR(DMA_BASE(ctrl) + 0x14 + (stream * 0x18))
#define r_CORTEX_M_DMA_SxPAR(ctrl, stream)	REG_ADDR(DMA_BASE(ctrl) + 0x18 + (stream * 0x18))
#define r_CORTEX_M_DMA_SxM0AR(ctrl, stream)	REG_ADDR(DMA_BASE(ctrl) + 0x1c + (stream * 0x18))
#define r_CORTEX_M_DMA_SxM1AR(ctrl, stream)	REG_ADDR(DMA_BASE(ctrl) + 0x20 + (stream * 0x18))
/* Note: in the reference manual rev 12, the section 10.5.10 says that the
 * offset of DMA_SxFCR register is 0x24 + 0x24 * stream. However, this is an
 * error ! The offset is 0x24 + 0x18 * stream. This is verified in section
 * 10.5.11 of the manual.
 */
#define r_CORTEX_M_DMA_SxFCR(ctrl, stream)	REG_ADDR(DMA_BASE(ctrl) + 0x24 + (stream * 0x18))

/* DMA low interrupt status register */
#define DMA_LISR_stream_base(stream)	(stream == 0 ? 0 : (stream == 1 ? 6 : (stream == 2 ? 16 : 22)))

#define DMA_LISR_FEIFx_Pos(stream)	(DMA_LISR_stream_base(stream))
#define DMA_LISR_FEIFx_Msk(stream)	((uint32_t)1 << DMA_LISR_FEIFx_Pos(stream))
#define DMA_LISR_DMEIFx_Pos(stream)	(DMA_LISR_stream_base(stream) + 2)
#define DMA_LISR_DMEIFx_Msk(stream)	((uint32_t)1 << DMA_LISR_DMEIFx_Pos(stream))
#define DMA_LISR_TEIFx_Pos(stream)	(DMA_LISR_stream_base(stream) + 3)
#define DMA_LISR_TEIFx_Msk(stream)	((uint32_t)1 << DMA_LISR_TEIFx_Pos(stream))
#define DMA_LISR_HTIFx_Pos(stream)	(DMA_LISR_stream_base(stream) + 4)
#define DMA_LISR_HTIFx_Msk(stream)	((uint32_t)1 << DMA_LISR_HTIFx_Pos(stream))
#define DMA_LISR_TCIFx_Pos(stream)	(DMA_LISR_stream_base(stream) + 5)
#define DMA_LISR_TCIFx_Msk(stream)	((uint32_t)1 << DMA_LISR_TCIFx_Pos(stream))

/* DMA high interrupt status register */
#define DMA_HISR_stream_base(stream)	(stream == 4 ? 0 : (stream == 5 ? 6 : (stream == 6 ? 16 : 22)))

#define DMA_HISR_FEIFx_Pos(stream)	(DMA_HISR_stream_base(stream))
#define DMA_HISR_FEIFx_Msk(stream)	((uint32_t)1 << DMA_HISR_FEIFx_Pos(stream))
#define DMA_HISR_DMEIFx_Pos(stream)	(DMA_HISR_stream_base(stream) + 2)
#define DMA_HISR_DMEIFx_Msk(stream)	((uint32_t)1 << DMA_HISR_DMEIFx_Pos(stream))
#define DMA_HISR_TEIFx_Pos(stream)	(DMA_HISR_stream_base(stream) + 3)
#define DMA_HISR_TEIFx_Msk(stream)	((uint32_t)1 << DMA_HISR_TEIFx_Pos(stream))
#define DMA_HISR_HTIFx_Pos(stream)	(DMA_HISR_stream_base(stream) + 4)
#define DMA_HISR_HTIFx_Msk(stream)	((uint32_t)1 << DMA_HISR_HTIFx_Pos(stream))
#define DMA_HISR_TCIFx_Pos(stream)	(DMA_HISR_stream_base(stream) + 5)
#define DMA_HISR_TCIFx_Msk(stream)	((uint32_t)1 << DMA_HISR_TCIFx_Pos(stream))

/* DMA low interrupt flag clear register */
#define DMA_LIFCR_stream_base(stream)	(stream == 0 ? 0 : (stream == 1 ? 6 : (stream == 2 ? 16 : 22)))

#define DMA_LIFCR_CFEIFx_Pos(stream)	(DMA_LIFCR_stream_base(stream))
#define DMA_LIFCR_CFEIFx_Msk(stream)	((uint32_t)1 << DMA_LIFCR_CFEIFx_Pos(stream))
#define DMA_LIFCR_CDMEIFx_Pos(stream)	(DMA_LIFCR_stream_base(stream) + 2)
#define DMA_LIFCR_CDMEIFx_Msk(stream)	((uint32_t)1 << DMA_LIFCR_CDMEIFx_Pos(stream))
#define DMA_LIFCR_CTEIFx_Pos(stream)	(DMA_LIFCR_stream_base(stream) + 3)
#define DMA_LIFCR_CTEIFx_Msk(stream)	((uint32_t)1 << DMA_LIFCR_CTEIFx_Pos(stream))
#define DMA_LIFCR_CHTIFx_Pos(stream)	(DMA_LIFCR_stream_base(stream) + 4)
#define DMA_LIFCR_CHTIFx_Msk(stream)	((uint32_t)1 << DMA_LIFCR_CHTIFx_Pos(stream))
#define DMA_LIFCR_CTCIFx_Pos(stream)	(DMA_LIFCR_stream_base(stream) + 5)
#define DMA_LIFCR_CTCIFx_Msk(stream)	((uint32_t)1 << DMA_LIFCR_CTCIFx_Pos(stream))

/* DMA high interrupt flag clear register */
#define DMA_HIFCR_stream_base(stream)	(stream == 4 ? 0 : (stream == 5 ? 6 : (stream == 6 ? 16 : 22)))

#define DMA_HIFCR_CFEIFx_Pos(stream)	(DMA_HIFCR_stream_base(stream))
#define DMA_HIFCR_CFEIFx_Msk(stream)	((uint32_t)1 << DMA_HIFCR_CFEIFx_Pos(stream))
#define DMA_HIFCR_CDMEIFx_Pos(stream)	(DMA_HIFCR_stream_base(stream) + 2)
#define DMA_HIFCR_CDMEIFx_Msk(stream)	((uint32_t)1 << DMA_HIFCR_CDMEIFx_Pos(stream))
#define DMA_HIFCR_CTEIFx_Pos(stream)	(DMA_HIFCR_stream_base(stream) + 3)
#define DMA_HIFCR_CTEIFx_Msk(stream)	((uint32_t)1 << DMA_HIFCR_CTEIFx_Pos(stream))
#define DMA_HIFCR_CHTIFx_Pos(stream)	(DMA_HIFCR_stream_base(stream) + 4)
#define DMA_HIFCR_CHTIFx_Msk(stream)	((uint32_t)1 << DMA_HIFCR_CHTIFx_Pos(stream))
#define DMA_HIFCR_CTCIFx_Pos(stream)	(DMA_HIFCR_stream_base(stream) + 5)
#define DMA_HIFCR_CTCIFx_Msk(stream)	((uint32_t)1 << DMA_HIFCR_CTCIFx_Pos(stream))

/* DMA stream x configuration register */
#define DMA_SxCR_EN_Pos	0
#define DMA_SxCR_EN_Msk	((uint32_t)1 << DMA_SxCR_EN_Pos)
#define DMA_SxCR_DMEIE_Pos	1
#define DMA_SxCR_DMEIE_Msk	((uint32_t)1 << DMA_SxCR_DMEIE_Pos)
#define DMA_SxCR_TEIE_Pos	2
#define DMA_SxCR_TEIE_Msk	((uint32_t)1 << DMA_SxCR_TEIE_Pos)
#define DMA_SxCR_HTIE_Pos	3
#define DMA_SxCR_HTIE_Msk	((uint32_t)1 << DMA_SxCR_HTIE_Pos)
#define DMA_SxCR_TCIE_Pos	4
#define DMA_SxCR_TCIE_Msk	((uint32_t)1 << DMA_SxCR_TCIE_Pos)
#define DMA_SxCR_PFCTRL_Pos	5
#define DMA_SxCR_PFCTRL_Msk	((uint32_t)1 << DMA_SxCR_PFCTRL_Pos)
#	define DMA_SxCR_PFCTRL_DMA_FLOW_CONTROLLER	0
#	define DMA_SxCR_PFCTRL_PERIPH_FLOW_CONTROLLER	1
#define DMA_SxCR_DIR_Pos	6
#define DMA_SxCR_DIR_Msk	((uint32_t)3 << DMA_SxCR_DIR_Pos)
#	define DMA_SxCR_DIR_PERIPH_TO_MEM		0
#	define DMA_SxCR_DIR_MEM_TO_PERIPH		1
#	define DMA_SxCR_DIR_MEM_TO_MEM			2
#define DMA_SxCR_CIRC_Pos	8
#define DMA_SxCR_CIRC_Msk	((uint32_t)1 << DMA_SxCR_CIRC_Pos)
#define DMA_SxCR_PINC_Pos	9
#define DMA_SxCR_PINC_Msk	((uint32_t)1 << DMA_SxCR_PINC_Pos)
#	define DMA_SxCR_PINC_ADDR_FIXED			0
#	define DMA_SxCR_PINC_ADDR_INCREMENTED		1
#define DMA_SxCR_MINC_Pos	10
#define DMA_SxCR_MINC_Msk	((uint32_t)1 << DMA_SxCR_MINC_Pos)
#	define DMA_SxCR_MINC_ADDR_FIXED			0
#	define DMA_SxCR_MINC_ADDR_INCREMENTED		1
#define DMA_SxCR_PSIZE_Pos	11
#define DMA_SxCR_PSIZE_Msk	((uint32_t)3 << DMA_SxCR_PSIZE_Pos)
#	define DMA_SxCR_PSIZE_BYTE			0
#	define DMA_SxCR_PSIZE_HALF_WORD			1
#	define DMA_SxCR_PSIZE_WORD			2
#define DMA_SxCR_MSIZE_Pos	13
#define DMA_SxCR_MSIZE_Msk	((uint32_t)3 << DMA_SxCR_MSIZE_Pos)
#	define DMA_SxCR_MSIZE_BYTE			0
#	define DMA_SxCR_MSIZE_HALF_WORD			1
#	define DMA_SxCR_MSIZE_WORD			2
#define DMA_SxCR_PINCOS_Pos	15
#define DMA_SxCR_PINCOS_Msk	((uint32_t)1 << DMA_SxCR_PINCOS_Pos)
#	define DMA_SxCR_PINCOS_LINKED_PSIZE		0
#	define DMA_SxCR_PINCOS_FIXED_4			1
#define DMA_SxCR_PL_Pos	16
#define DMA_SxCR_PL_Msk	((uint32_t)3 << DMA_SxCR_PL_Pos)
#	define DMA_SxCR_PL_LOW				0
#	define DMA_SxCR_PL_MEDIUM			1
#	define DMA_SxCR_PL_HIGH				2
#	define DMA_SxCR_PL_VERY_HIGH			3
#define DMA_SxCR_DBM_Pos	18
#define DMA_SxCR_DBM_Msk	((uint32_t)1 << DMA_SxCR_DBM_Pos)
#define DMA_SxCR_CT_Pos	19
#define DMA_SxCR_CT_Msk	((uint32_t)1 << DMA_SxCR_CT_Pos)
#define DMA_SxCR_PBURST_Pos	21
#define DMA_SxCR_PBURST_Msk	((uint32_t)3 << DMA_SxCR_PBURST_Pos)
#	define DMA_SxCR_PBURST_SINGLE			0
#	define DMA_SxCR_PBURST_INCR4			1
#	define DMA_SxCR_PBURST_INCR8			2
#	define DMA_SxCR_PBURST_INCR16			3
#define DMA_SxCR_MBURST_Pos	23
#define DMA_SxCR_MBURST_Msk	((uint32_t)3 << DMA_SxCR_MBURST_Pos)
#	define DMA_SxCR_MBURST_SINGLE			0
#	define DMA_SxCR_MBURST_INCR4			1
#	define DMA_SxCR_MBURST_INCR8			2
#	define DMA_SxCR_MBURST_INCR16			3
#define DMA_SxCR_CHSEL_Pos	25
#define DMA_SxCR_CHSEL_Msk	((uint32_t)7 << DMA_SxCR_CHSEL_Pos)

/* DMA stream x number of data register */
#define DMA_SxNDTR_NDT_Pos	0
#define DMA_SxNDTR_NDT_Msk	((uint32_t)0xffff << DMA_SxNDTR_NDT_Pos)

/* DMA stream x peripheral adderss register */
#define DMA_SxPAR_PAR_Pos	0
#define DMA_SxPAR_PAR_Msk	((uint32_t)0xffffffff << DMA_SxPAR_PAR_Pos)

/* DMA stream x memory 0 address register */
#define DMA_SxM0AR_M0A_Pos	0
#define DMA_SxM0AR_M0A_Msk	((uint32_t)0xffffffff << DMA_SxM0AR_M0A_Pos)

/* DMA stream x memory 1 address register */
#define DMA_SxM1AR_M1A_Pos	0
#define DMA_SxM1AR_M1A_Msk	((uint32_t)0xffffffff << DMA_SxM1A_M1AR_Pos)

/* DMA stream x FIFO control register */
#define DMA_SxFCR_FTH_Pos	0
#define DMA_SxFCR_FTH_Msk	((uint32_t)3 << DMA_SxFCR_FTH_Pos)
#	define DMA_SxFCR_FTH_1DIV4_FULL			0
#	define DMA_SxFCR_FTH_1DIV2_FULL			1
#	define DMA_SxFCR_FTH_3DIV4_FULL			2
#	define DMA_SxFCR_FTH_FULL			3
#define DMA_SxFCR_DMDIS_Pos	2
#define DMA_SxFCR_DMDIS_Msk	((uint32_t)1 << DMA_SxFCR_DMDIS_Pos)
#define DMA_SxFCR_FS_Pos	3
#define DMA_SxFCR_FS_Msk	((uint32_t)7 << DMA_SxFCR_FS_Pos)
#	define DMA_SxFCR_FS_LESS_1DIV4			0
#	define DMA_SxFCR_FS_LESS_1DIV2			1
#	define DMA_SxFCR_FS_LESS_3DIV4			2
#	define DMA_SxFCR_FS_LESS_FULL			3
#	define DMA_SxFCR_FS_EMPTY			4
#	define DMA_SxFCR_FS_FULL			5
#define DMA_SxFCR_FEIE_Pos	7
#define DMA_SxFCR_FEIE_Msk	((uint32_t)1 << DMA_SxFCR_FEIE_Pos)

#endif /* !SOC_DMA_REGS_H */
