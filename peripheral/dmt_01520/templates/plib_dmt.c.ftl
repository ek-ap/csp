/*******************************************************************************
  Deadman Timer (${DMT_INSTANCE_NAME}) PLIB

  Company:
    Microchip Technology Inc.

  File Name:
    plib_${DMT_INSTANCE_NAME?lower_case}.c

  Summary:
    ${DMT_INSTANCE_NAME} PLIB Implementation file

  Description:
    This file defines the interface to the deadman timer (DMT) peripheral library.
    This library provides ability to clear the DMT counter.

*******************************************************************************/

// DOM-IGNORE-BEGIN
/*******************************************************************************
* Copyright (C) 2019 Microchip Technology Inc. and its subsidiaries.
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
// DOM-IGNORE-END

// *****************************************************************************
// *****************************************************************************
// Section: Included Files
// *****************************************************************************
// *****************************************************************************

#include "plib_${DMT_INSTANCE_NAME?lower_case}.h"

// *****************************************************************************
// *****************************************************************************
// Section: ${DMT_INSTANCE_NAME} Implementation
// *****************************************************************************
// *****************************************************************************

<#if (CONFIG_FDMTEN?? && CONFIG_FDMTEN == "OFF") || (CONFIG_DMTEN?? && CONFIG_DMTEN == "OFF")>
void ${DMT_INSTANCE_NAME}_Enable( void )
{
    /* ON = 1 */
    DMTCONbits.ON = 1;
}

</#if>
void ${DMT_INSTANCE_NAME}_Clear( void )
{
    /* Clear STEP1 */
    DMTPRECLRbits.STEP1 = 0x40;

    /* Clear STEP2 */
    DMTCLRbits.STEP2 = 0x08;
}

bool ${DMT_INSTANCE_NAME}_ClearWindowStatusGet( void )
{
    /* Clear window open status */
    return (bool) DMTSTATbits.WINOPN;
}

uint32_t ${DMT_INSTANCE_NAME}_CounterGet( void )
{
    /* Current counter value */
    return (uint32_t) DMTCNT;
}

uint32_t ${DMT_INSTANCE_NAME}_TimeOutCountGet( void )
{
    /* Maximum count selected */
    return (uint32_t) DMTPSCNT;
}

uint32_t ${DMT_INSTANCE_NAME}_WindowIntervalGet( void )
{
    /* Window interval value */
    return (uint32_t) DMTPSINTV;
}