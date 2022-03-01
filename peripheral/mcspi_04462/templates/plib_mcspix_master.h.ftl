/*******************************************************************************
  MCSPI PLIB

  Company:
    Microchip Technology Inc.

  File Name:
    plib_${MCSPI_INSTANCE_NAME?lower_case}_master.h

  Summary:
    ${MCSPI_INSTANCE_NAME} Master PLIB Header File

  Description:
    This file has prototype of all the interfaces provided for particular
    MCSPI peripheral.

*******************************************************************************/

/*******************************************************************************
* Copyright (C) 2022 Microchip Technology Inc. and its subsidiaries.
*
* Subject to your compliance with these terms, you may use Microchip software
* and any derivatives exclusively with Microchip products. It is your
* responsibility to comply with third party license terms applicable to your
* use of third party software (including open source software) that may
* accompany Microchip software.
*
* THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
* EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
* WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
* PARTICULAR PURPOSE.
*
* IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
* INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
* WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
* BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
* FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
* ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
* THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
*******************************************************************************/

#ifndef PLIB_${MCSPI_INSTANCE_NAME}_MASTER_H
#define PLIB_${MCSPI_INSTANCE_NAME}_MASTER__H

#include "device.h"
#include "plib_mcspi_master_common.h"

/* Provide C++ Compatibility */
#ifdef __cplusplus

    extern "C" {

#endif

/****************************** ${MCSPI_INSTANCE_NAME} Interface *********************************/

void ${MCSPI_INSTANCE_NAME}_Initialize( void );

bool ${MCSPI_INSTANCE_NAME}_WriteRead( void* pTransmitData, size_t txSize, void* pReceiveData, size_t rxSize );

bool ${MCSPI_INSTANCE_NAME}_Write( void* pTransmitData, size_t txSize );

bool ${MCSPI_INSTANCE_NAME}_Read( void* pReceiveData, size_t rxSize );

bool ${MCSPI_INSTANCE_NAME}_TransferSetup( MCSPI_TRANSFER_SETUP *setup, uint32_t mcspiSourceClock );

bool ${MCSPI_INSTANCE_NAME}_IsTransmitterBusy( void );

<#if MCSPI_NUM_CSR != 1>
void ${MCSPI_INSTANCE_NAME}_ChipSelectSetup(MCSPI_CHIP_SELECT chipSelect);
</#if>

<#if MCSPI_INTERRUPT_MODE == true>
bool ${MCSPI_INSTANCE_NAME}_IsBusy( void );

void ${MCSPI_INSTANCE_NAME}_CallbackRegister( const MCSPI_CALLBACK callback, uintptr_t context );

</#if>

/* Provide C++ Compatibility */
#ifdef __cplusplus

    }

#endif

#endif // PLIB_${MCSPI_INSTANCE_NAME}_MASTER_H

/*******************************************************************************
 End of File
*/
