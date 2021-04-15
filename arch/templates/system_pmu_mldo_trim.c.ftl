/*******************************************************************************
  PIC32MZW1 PMU MLDO TRIMMING

  File Name:
    sys_pmu_mldo_trim.c

  Summary:
    PIC32MZW1 boot time PMU MLDO mode Configuration.

  Description:
    This interface helps configure the PMU in MLDO only mode and also trim
    the voltages in this mode to the operating range.

 *******************************************************************************/

//DOM-IGNORE-BEGIN
/*******************************************************************************
Copyright (c) 2019 released Microchip Technology Inc.  All rights reserved.

Microchip licenses to you the right to use, modify, copy and distribute
Software only when embedded on a Microchip microcontroller or digital signal
controller that is integrated into your product or third party product
(pursuant to the sublicense terms in the accompanying license agreement).

You should refer to the license agreement accompanying this Software for
additional information regarding your rights and obligations.

SOFTWARE AND DOCUMENTATION ARE PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION, ANY WARRANTY OF
MERCHANTABILITY, TITLE, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE.
IN NO EVENT SHALL MICROCHIP OR ITS LICENSORS BE LIABLE OR OBLIGATED UNDER
CONTRACT, NEGLIGENCE, STRICT LIABILITY, CONTRIBUTION, BREACH OF WARRANTY, OR
OTHER LEGAL EQUITABLE THEORY ANY DIRECT OR INDIRECT DAMAGES OR EXPENSES
INCLUDING BUT NOT LIMITED TO ANY INCIDENTAL, SPECIAL, INDIRECT, PUNITIVE OR
CONSEQUENTIAL DAMAGES, LOST PROFITS OR LOST DATA, COST OF PROCUREMENT OF
SUBSTITUTE GOODS, TECHNOLOGY, SERVICES, OR ANY CLAIMS BY THIRD PARTIES
(INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF), OR OTHER SIMILAR COSTS.
 *******************************************************************************/
//DOM-IGNORE-END

#include "device.h"
#include "definitions.h"

/*Bits [15-6] in the SPI Status register have Read data */
#define PMU_SPI_READ_MASK 0xFFFF0000

// PMU related defines
#define BUCKCFG1_ADDR 0x14
#define BUCKCFG2_ADDR 0x15
#define BUCKCFG3_ADDR 0x16
#define MLDOCFG1_ADDR 0x17
#define MLDOCFG2_ADDR 0x18
#define SPI_CMD_OFFSET 24
#define SPI_ADDR_OFFSET 16
#define TREG_DEFAULT 0x16161616
#define MLDO_ISENSE_CONFIG 0xC07
#define MLDO_ENABLE 0x00000A80
#define BUCK_PBYPASS_ENABLE 0x4
#define BUCK_SCP_TUNE 0x10
#define MLDOCFG1_DEFUALT_VAL 0x180
#define PMU_STATUS_SPIRDY 0x80
#define VREG1_BITS 0x0000001F
#define VREG2_BITS 0x00001F00
#define VREG3_BITS 0x001F0000
#define VREG4_BITS 0x1F000000
#define CORE_TIMER_FREQ 100000000

#define SG407_MASK_ID 0xA4
#define SG402_MASK_ID 0x8C
#define PMUSPI_BUCKCFG1_DEFAULT_VAL     0x5480
#define PMUSPI_BUCKCFG2_DEFAULT_VAL     0x8C28
#define PMUSPI_BUCKCFG3_DEFAULT_VAL     0x00C8
#define PMUSPI_MLDOCFG1_DEFAULT_VAL     0x0287
#define PMUSPI_MLDOCFG2_DEFAULT_VAL     0x0280
#define MLDO_HW_BP_EN 0x4

//Flash Area housing the PMU calibration values
unsigned int *otp_buckcfg1_data = (unsigned int *)0xBFC56FE8;
unsigned int *otp_buckcfg2_data = (unsigned int *) 0xBFC56FEC;
unsigned int *otp_buckcfg3_data = (unsigned int *) 0xBFC56FF0;
unsigned int *otp_mldocfg1_data = (unsigned int *) 0xBFC56FF4;
unsigned int *otp_mldocfg2_data = (unsigned int *) 0xBFC56FF8;
unsigned int *otp_treg3_data = (unsigned int *)0xBFC56FFC;

unsigned int *spi_status_reg = (unsigned int *)0xBF813E04;
unsigned int *spi_cntrl_reg = (unsigned int *)0xBF813E00;
unsigned int *pmu_cmode_reg = (unsigned int *)0xBF813E20;

unsigned int M_BUCKEN, M_MLDOEN, M_BUCKMODE;
unsigned int S_BUCKEN, S_MLDOEN, S_BUCKMODE;
unsigned int O_BUCKEN, O_MLDOEN, O_BUCKMODE, OVEREN;

static void DelayMs ( uint32_t delay_ms)
{
    uint32_t startCount, endCount;
    /* Calculate the end count for the given delay */
    endCount=(CORE_TIMER_FREQ/1000)*delay_ms;
    startCount=_CP0_GET_COUNT();
    while((_CP0_GET_COUNT()-startCount)<endCount);
}

static unsigned int SYS_PMU_SPI_READ(unsigned int spi_addr)
{
    unsigned int spi_val , reg_val;
    int status = 0;
    reg_val = (1 << SPI_CMD_OFFSET) | (spi_addr << SPI_ADDR_OFFSET) ;
    *spi_cntrl_reg = reg_val;
    DelayMs(20);

    while (1)
    {
        status = *spi_status_reg;
        if (status & PMU_STATUS_SPIRDY)
            break;
    }
    spi_val = ((status & PMU_SPI_READ_MASK) >> SPI_ADDR_OFFSET);
    DelayMs(20);
    return spi_val;
}

static void SYS_PMU_SPI_WRITE(unsigned int spi_addr, unsigned int reg_val)
{
    unsigned int spi_val ;
    int status = 0;
    reg_val &= 0xFFFF;
    spi_val = (spi_addr << SPI_ADDR_OFFSET) | reg_val;
    *spi_cntrl_reg = spi_val;
    DelayMs(20);
    while (1)
    {
        status = *spi_status_reg;
        if (status & PMU_STATUS_SPIRDY)
            break;
    }
    DelayMs(20);
}

/*This function will configure the PMU with
 *the tune bits from Flash.
 *
 * Flash area to read from
 * 0xBFC56FE0	BLANK
 * 0xBFC56FE4	BLANK
 * 0xBFC56FE8	BUCKCFG1 (vo_tune in bits [13:10] other bits written low
 * 0xBFC56FEC	BUCKCFG2 (default buk_curve value written to bits [6:4], other bits written low.
 * 0xBFC56FF0	BUCKCFG3 (currently BLANK, set aside for possible future use)
 * 0xBFC56FF4	MLDOCFG1 (currently BLANK until we receive MLDO trim pattern and implement calibration on ATE)
 * 0xBFC56FF8	MLDOCFG2 (currently BLANK until we receive MLDO trim pattern and implement calibration on ATE)
 * 0xBFC56FFC	TREG3 (VREG4,3,2,1) values
 *
 * Below are the configurations done here
 * Configure buk_Vo_tune<13:10> in BUCKCFG1, ADDR=0x14 register
 * Configure mldo_vtun<9:6> in the MLDOCFG1, ADDR=0x17 register
 * Configure PLDO1[4:0] in the TREG3 register
 * Configure PLDO2[12:8] in the TREG3 register
 * Configure PLDO3[20:16] in the TREG3 register
 * Configure VREGPLL1[28:24] in the TREG3 register
 */

void PMU_Initialize(void)
{
    unsigned int nvm_flash_data, otp_treg_val;
    unsigned int mldocfg1, mldocfg2, buckcfg1, buckcfg2, buckcfg3;
    unsigned int vreg1, vreg2, vreg3, vreg4;

    if(((DEVID & 0x0FF00000) >> 20) == SG407_MASK_ID)
    {
       if ((RCONbits.BOR == 1) || (RCONbits.POR == 1))
       {
        // SPI Cock (Max=20M), SRC=System(PB1), Div=5
        // Buck Clock SRC=FRC, DIV=8
        // BACWD=0, restriction due to BUG (SG407-110)
        // BACWD=1, is efficient on time but intermittent failures due to (SG407-110) bug
        PMUCLKCTRL = 0x00004885;

        buckcfg1 = *otp_buckcfg1_data;
        if((buckcfg1 == 0x00000000) || (buckcfg1 == 0xFFFFFFFF))
        buckcfg1 = PMUSPI_BUCKCFG1_DEFAULT_VAL;

        SYS_PMU_SPI_WRITE(BUCKCFG1_ADDR, buckcfg1);

        buckcfg2 = *otp_buckcfg2_data;
        if((buckcfg2 == 0x00000000) || (buckcfg2 == 0xFFFFFFFF))
            buckcfg2 = PMUSPI_BUCKCFG2_DEFAULT_VAL;

        SYS_PMU_SPI_WRITE(BUCKCFG2_ADDR, buckcfg2);


        buckcfg3 = *otp_buckcfg3_data;
        if((buckcfg3 == 0x00000000) || (buckcfg3 == 0xFFFFFFFF))
            buckcfg3 = PMUSPI_BUCKCFG3_DEFAULT_VAL;

        SYS_PMU_SPI_WRITE(BUCKCFG3_ADDR, buckcfg3);

        //printf("Perform MLDOCFGX calibration \n");
        mldocfg1 = *otp_mldocfg1_data;
        if((mldocfg1 == 0x00000000) || (mldocfg1 == 0xFFFFFFFF)) {
            mldocfg1 = PMUSPI_MLDOCFG1_DEFAULT_VAL;
           // printf("PMU MLDOCFG1 not calibrated : Using MLDOCFG1 = %x \n", PMUSPI_MLDOCFG1_DEFAULT_VAL);
        }
        SYS_PMU_SPI_WRITE(MLDOCFG1_ADDR, mldocfg1);

        mldocfg2 = *otp_mldocfg2_data;
        if((mldocfg2 == 0x00000000) || (mldocfg2 == 0xFFFFFFFF)) {
            mldocfg2 = PMUSPI_MLDOCFG2_DEFAULT_VAL;
           // printf("PMU MLDOCFG2 not calibrated : Using MLDOCFG2 = %x \n", PMUSPI_MLDOCFG2_DEFAULT_VAL);
        }
        SYS_PMU_SPI_WRITE(MLDOCFG2_ADDR, mldocfg2);

       // printf("Read VREG values from flash and populate MODE control regs \n");
        otp_treg_val = *otp_treg3_data;
        if((otp_treg_val == 0xFFFFFFFF) || (otp_treg_val == 0x00000000))
        {
            otp_treg_val = TREG_DEFAULT;
        }
        vreg4 = otp_treg_val & VREG1_BITS;
        vreg3 = (otp_treg_val & VREG2_BITS) >> 8;
        vreg2 = (otp_treg_val & VREG3_BITS) >> 16;
        vreg1 = (otp_treg_val & VREG4_BITS) >> 24;

       // printf("Configure  MODE control 1\n");
        // Mission mode PMU Mode #1 register

        M_BUCKEN = 1;
        M_MLDOEN = 0;
        M_BUCKMODE = 1; // PMU-Buck PWM Mode
        PMUMODECTRL1 = ((M_BUCKEN << 31) | (M_MLDOEN << 30) | (M_BUCKMODE << 29) |
                (vreg1 << 24) | (vreg2 <<16) | (vreg3 << 8) | vreg4);

        //printf("Configure  MODE control 2\n");
        // Sleep mode PMU Mode #2 register
        // TODO - When available, use the Sleep Mode Calibration values
        S_BUCKEN = 1;
        S_MLDOEN = 0;
        S_BUCKMODE = 0; // PMU-Buck PSM Mode
        PMUMODECTRL2 = ((S_BUCKEN << 31) | (S_MLDOEN << 30) | (S_BUCKMODE << 29) |
                (vreg1 << 24) | (vreg2 <<16) | (vreg3 << 8) | vreg4);

        //printf("Put the PMU in SW Override Mode\n");
         // For HUT Code keeping the PMU in SW Override Mode
        // OVEREN = 1, triggers the mode change
        O_BUCKEN = 1;
        O_MLDOEN = 0;
        O_BUCKMODE = 1;
        OVEREN = 1; // PMU-Buck PWM Mode
        PMUOVERCTRL = ((O_BUCKEN << 31) | (O_MLDOEN << 30) | (O_BUCKMODE << 29) |
                (OVEREN << 23) | (vreg1 << 24) | (vreg2 <<16) | (vreg3 << 8) | vreg4);

        // Trigger PMU Mode Change, with CLKCTRL.BACWD=0
        //printf("Trigger PMU Mode Change, with CLKCTRL.BACWD=0\n");
        PMUOVERCTRLbits.PHWC = 0;

        // Poll for Buck switching to be complete
        while (!((PMUCMODEbits.CBUCKEN) && (PMUCMODEbits.CBUCKMODE) && !(PMUCMODEbits.CMLDOEN)));
        //printf("Switch to BUCK mode complete PMUCMODE: %x \n", PMUCMODE);

        //printf("PMU REG BUCKCFG1 after config: 0x%x\n", pmu_spi_read(BUCKCFG1_ADDR));
        //printf("PMU REG BUCKCFG2 after config: 0x%x \n", pmu_spi_read(BUCKCFG2_ADDR));
        //printf("PMU REG BUCKCFG3 after config: 0x%x \n", pmu_spi_read(BUCKCFG3_ADDR));
        //printf("PMU REG MLDOCFG1 after config: 0x%x \n", pmu_spi_read(MLDOCFG1_ADDR));
        //printf("PMU REG MLDOCFG2 after config: 0x%x \n", pmu_spi_read(MLDOCFG2_ADDR));

        // Post process the Buck switching if Calibration values are not present
        // VTUNE[3:0]=0x0 if no calibration
        buckcfg1 = *otp_buckcfg1_data;
        if((buckcfg1 == 0x00000000) || (buckcfg1 == 0xFFFFFFFF)) {
            SYS_PMU_SPI_WRITE(BUCKCFG1_ADDR, (SYS_PMU_SPI_READ(BUCKCFG1_ADDR) & 0xEBFF));
           // printf("PMU BUCKCFG1 not calibrated : Using BUCKCFG1 = %x \n", pmu_spi_read(BUCKCFG1_ADDR));
        }

        // BUCKCFG2 0x8C28 - If no calibration, we need to update buk_scp_tune at the least to 2?b10, so update it o 0x8D28
        buckcfg2 = *otp_buckcfg2_data;
        if((buckcfg2 == 0x00000000) || (buckcfg2 == 0xFFFFFFFF)) {
            SYS_PMU_SPI_WRITE(BUCKCFG2_ADDR, (SYS_PMU_SPI_READ(BUCKCFG2_ADDR) | BUCK_SCP_TUNE));
           // printf("PMU BUCKCFG2 not calibrated : Using BUCKCFG2 = %x \n", pmu_spi_read(BUCKCFG2_ADDR));
        }

        // BUCKCFG3 check - If no calibration, skip, use PMU Default
        buckcfg3 = *otp_buckcfg3_data;
        if ((buckcfg3 == 0x00000000) || (buckcfg3 == 0xFFFFFFFF)) {
            //printf("PMU BUCKCFG3 not calibrated : Using BUCKCFG3 = %x \n",
            //        pmu_spi_read(BUCKCFG3_ADDR));

        }

        //Post calibration attempt complete and Buck switch is complete, need to put MLDO VTUNE in serial mode : mldo_hw_bp=1
        //printf("BUCKCFG1 before mldo_hw_bp configuration  0x%x\n", pmu_spi_read(BUCKCFG1_ADDR));
        SYS_PMU_SPI_WRITE(BUCKCFG1_ADDR, ((SYS_PMU_SPI_READ(BUCKCFG1_ADDR) | MLDO_HW_BP_EN)));
        //printf("BUCKCFG1 after mldo_hw_bp configuration  0x%x\n", pmu_spi_read(BUCKCFG1_ADDR));
       }
    }
    else if(((DEVID & 0x0FF00000) >> 20) == SG402_MASK_ID)
    {
    //PMU_MLDO_Cfg()
    {
        //Read MLDOCFG1 Value
        mldocfg1 = SYS_PMU_SPI_READ(MLDOCFG1_ADDR);
        if(mldocfg1 == 0x0)
        {
            mldocfg1 = *otp_mldocfg1_data;
            if((mldocfg1 == 0xFFFFFFFF) || (mldocfg1 == 0x00000000))
            {
                mldocfg1 = MLDOCFG1_DEFAULT_VAL | MLDO_ISENSE_CONFIG;
            }
            else
            {
                 mldocfg1 |= MLDO_ISENSE_CONFIG;
            }
        }
		else
        {
            mldocfg1 = *otp_mldocfg1_data | MLDO_ISENSE_CONFIG;
        }
        SYS_PMU_SPI_WRITE(MLDOCFG1_ADDR, mldocfg1);
        /* make sure mldo_cfg2 register is zero, nothing is enabled. */
        mldocfg2 = 0;
        SYS_PMU_SPI_WRITE(MLDOCFG2_ADDR, mldocfg2);
    }

    //PMU_MLDO_Enable()
    {
        mldocfg2 = SYS_PMU_SPI_READ(MLDOCFG2_ADDR);
        mldocfg2 |= MLDO_ENABLE;
        SYS_PMU_SPI_WRITE(MLDOCFG2_ADDR, mldocfg2);
    }

    //PMU_MLDO_Set_ParallelBypass()
    {
        buckcfg1 = SYS_PMU_SPI_READ(BUCKCFG1_ADDR);
        buckcfg1 |= BUCK_PBYPASS_ENABLE;
        SYS_PMU_SPI_WRITE(BUCKCFG1_ADDR, buckcfg1);
    }

    {
        nvm_flash_data = *otp_treg3_data;
        if((nvm_flash_data == 0xFFFFFFFF) || (nvm_flash_data == 0x00000000))
        {
            nvm_flash_data = TREG_DEFAULT;
        }
        vreg4 = nvm_flash_data & VREG1_BITS;
        vreg3 = (nvm_flash_data & VREG2_BITS) >> 8;
        vreg2 = (nvm_flash_data & VREG3_BITS) >> 16;
        vreg1 = (nvm_flash_data & VREG4_BITS) >> 24;

        PMUOVERCTRLbits.OBUCKEN = 0;	//Disable Buck mode
        PMUOVERCTRLbits.OMLDOEN = 1;	//Enable MLDO mode

		/* Configure Output Voltage Control Bits */
        PMUOVERCTRLbits.VREG4OCTRL = vreg4;
        PMUOVERCTRLbits.VREG3OCTRL = vreg3;
        PMUOVERCTRLbits.VREG2OCTRL = vreg2;
        PMUOVERCTRLbits.VREG1OCTRL = vreg1;

        PMUOVERCTRLbits.PHWC = 0;	//Disable Power-up HW Control
        PMUOVERCTRLbits.OVEREN = 1;	//set override enable bit
        }
    }
}
