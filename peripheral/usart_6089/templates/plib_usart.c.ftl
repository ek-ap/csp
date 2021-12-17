/*******************************************************************************
  ${USART_INSTANCE_NAME} PLIB

  Company:
    Microchip Technology Inc.

  File Name:
    plib_${USART_INSTANCE_NAME?lower_case}.c

  Summary:
    ${USART_INSTANCE_NAME} PLIB Implementation File

  Description:
    None

*******************************************************************************/

/*******************************************************************************
* Copyright (C) 2018 Microchip Technology Inc. and its subsidiaries.
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

#include "device.h"
#include "plib_${USART_INSTANCE_NAME?lower_case}.h"
<#if core.CoreSysIntFile == true>
#include "interrupts.h"
</#if>

<#--Implementation-->
// *****************************************************************************
// *****************************************************************************
// Section: ${USART_INSTANCE_NAME} Implementation
// *****************************************************************************
// *****************************************************************************

static void ${USART_INSTANCE_NAME}_ErrorClear( void )
{
    uint8_t dummyData = 0u;

   if (${USART_INSTANCE_NAME}_REGS->US_CSR & (US_CSR_USART_OVRE_Msk | US_CSR_USART_PARE_Msk | US_CSR_USART_FRAME_Msk))
   {
        /* Clear the error flags */
        ${USART_INSTANCE_NAME}_REGS->US_CR = US_CR_USART_RSTSTA_Msk;

        /* Flush existing error bytes from the RX FIFO */
        while (${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_RXRDY_Msk)
        {
            dummyData = (${USART_INSTANCE_NAME}_REGS->US_RHR & US_RHR_RXCHR_Msk);
        }
   }

    /* Ignore the warning */
    (void)dummyData;
}

<#assign useUSARTRxDMA = false>
<#assign useUSARTTxDMA = false>
<#if USART_INTERRUPT_MODE_ENABLE == true>
<#if USE_USART_RECEIVE_DMA??>
<#assign useUSARTRxDMA = USE_USART_RECEIVE_DMA>
</#if>
<#if USE_USART_TRANSMIT_DMA??>
<#assign useUSARTTxDMA = USE_USART_TRANSMIT_DMA>
</#if>

USART_OBJECT ${USART_INSTANCE_NAME?lower_case}Obj;

<#if useUSARTRxDMA == false>
static void ${USART_INSTANCE_NAME}_ISR_RX_Handler( void )
{
    uint16_t rxData = 0;

    if(${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus == true)
    {
        while((${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_RXRDY_Msk) && (${USART_INSTANCE_NAME?lower_case}Obj.rxSize > ${USART_INSTANCE_NAME?lower_case}Obj.rxProcessedSize))
        {
            rxData = ${USART_INSTANCE_NAME}_REGS->US_RHR & US_RHR_RXCHR_Msk;
            if (${USART_INSTANCE_NAME}_REGS->US_MR & US_MR_USART_MODE9_Msk)
            {
                ((uint16_t*)${USART_INSTANCE_NAME?lower_case}Obj.rxBuffer)[${USART_INSTANCE_NAME?lower_case}Obj.rxProcessedSize++] = (uint16_t)rxData;
            }
            else
            {
                ${USART_INSTANCE_NAME?lower_case}Obj.rxBuffer[${USART_INSTANCE_NAME?lower_case}Obj.rxProcessedSize++] = (uint8_t)rxData;
            }
        }

        /* Check if the buffer is done */
        if(${USART_INSTANCE_NAME?lower_case}Obj.rxProcessedSize >= ${USART_INSTANCE_NAME?lower_case}Obj.rxSize)
        {
            ${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus = false;

            /* Disable Read, Overrun, Parity and Framing error interrupts */
            ${USART_INSTANCE_NAME}_REGS->US_IDR = (US_IDR_USART_RXRDY_Msk | US_IDR_USART_FRAME_Msk | US_IDR_USART_PARE_Msk | US_IDR_USART_OVRE_Msk);

            if(${USART_INSTANCE_NAME?lower_case}Obj.rxCallback != NULL)
            {
                ${USART_INSTANCE_NAME?lower_case}Obj.rxCallback(${USART_INSTANCE_NAME?lower_case}Obj.rxContext);
            }
        }
    }
    else
    {
        /* Nothing to process */
        ;
    }
}

</#if>
<#if useUSARTTxDMA == false>
static void ${USART_INSTANCE_NAME}_ISR_TX_Handler( void )
{
    if(${USART_INSTANCE_NAME?lower_case}Obj.txBusyStatus == true)
    {
        while((${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_TXRDY_Msk) && (${USART_INSTANCE_NAME?lower_case}Obj.txSize > ${USART_INSTANCE_NAME?lower_case}Obj.txProcessedSize))
        {
            if (${USART_INSTANCE_NAME}_REGS->US_MR & US_MR_USART_MODE9_Msk)
            {
                ${USART_INSTANCE_NAME}_REGS->US_THR = ((uint16_t*)${USART_INSTANCE_NAME?lower_case}Obj.txBuffer)[${USART_INSTANCE_NAME?lower_case}Obj.txProcessedSize++] & US_THR_TXCHR_Msk;
            }
            else
            {
                ${USART_INSTANCE_NAME}_REGS->US_THR = ${USART_INSTANCE_NAME?lower_case}Obj.txBuffer[${USART_INSTANCE_NAME?lower_case}Obj.txProcessedSize++] & US_THR_TXCHR_Msk;
            }
        }

        /* Check if the buffer is done */
        if(${USART_INSTANCE_NAME?lower_case}Obj.txProcessedSize >= ${USART_INSTANCE_NAME?lower_case}Obj.txSize)
        {
            ${USART_INSTANCE_NAME?lower_case}Obj.txBusyStatus = false;

            ${USART_INSTANCE_NAME}_REGS->US_IDR = US_IDR_USART_TXRDY_Msk;

            if(${USART_INSTANCE_NAME?lower_case}Obj.txCallback != NULL)
            {
                ${USART_INSTANCE_NAME?lower_case}Obj.txCallback(${USART_INSTANCE_NAME?lower_case}Obj.txContext);
            }
        }
    }
    else
    {
        /* Nothing to process */
        ;
    }
}

</#if>
void ${USART_INSTANCE_NAME}_InterruptHandler( void )
{
    /* Error status */
    uint32_t errorStatus = (${USART_INSTANCE_NAME}_REGS->US_CSR & (US_CSR_USART_OVRE_Msk | US_CSR_USART_FRAME_Msk | US_CSR_USART_PARE_Msk));

    if(errorStatus != 0)
    {
        /* Save the error to be reported later */
        ${USART_INSTANCE_NAME?lower_case}Obj.errorStatus = (USART_ERROR)errorStatus;

        /* Clear error flags and flush the error data */
        ${USART_INSTANCE_NAME}_ErrorClear();

        /* Disable Read, Overrun, Parity and Framing error interrupts */
        <#if useUSARTRxDMA == true>
        ${USART_INSTANCE_NAME}_REGS->US_PTCR = US_PTCR_RXTDIS_Msk;
        ${USART_INSTANCE_NAME}_REGS->US_IDR = (US_IDR_USART_ENDRX_Msk | US_IDR_USART_FRAME_Msk | US_IDR_USART_PARE_Msk | US_IDR_USART_OVRE_Msk);
        <#else>
        ${USART_INSTANCE_NAME}_REGS->US_IDR = (US_IDR_USART_RXRDY_Msk | US_IDR_USART_FRAME_Msk | US_IDR_USART_PARE_Msk | US_IDR_USART_OVRE_Msk);
        </#if>

        ${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus = false;

        /* USART errors are normally associated with the receiver, hence calling
         * receiver callback */
        if( ${USART_INSTANCE_NAME?lower_case}Obj.rxCallback != NULL )
        {
            ${USART_INSTANCE_NAME?lower_case}Obj.rxCallback(${USART_INSTANCE_NAME?lower_case}Obj.rxContext);
        }
    }

    <#if useUSARTRxDMA == true>
    if ((${USART_INSTANCE_NAME}_REGS->US_PTSR & US_PTSR_RXTEN_Msk) && (${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_ENDRX_Msk))
    {
        if(${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus == true)
        {
            ${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus = false;
            ${USART_INSTANCE_NAME}_REGS->US_PTCR = US_PTCR_RXTDIS_Msk;
            ${USART_INSTANCE_NAME}_REGS->US_IDR = (US_IDR_USART_ENDRX_Msk | US_IDR_USART_FRAME_Msk | US_IDR_USART_PARE_Msk | US_IDR_USART_OVRE_Msk);

            if( ${USART_INSTANCE_NAME?lower_case}Obj.rxCallback != NULL )
            {
                ${USART_INSTANCE_NAME?lower_case}Obj.rxCallback(${USART_INSTANCE_NAME?lower_case}Obj.rxContext);
            }
        }
    }
    <#else>
    
    /* Receiver timeout  */
    if (${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_TIMEOUT_Msk)
    {
        if(${USART_INSTANCE_NAME?lower_case}Obj.rxTimeoutCallback != NULL)
        {
            ${USART_INSTANCE_NAME?lower_case}Obj.rxTimeoutCallback(${USART_INSTANCE_NAME?lower_case}Obj.rxTimeoutContext);
        }
    }

    /* Receiver status */
    if (${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_RXRDY_Msk)
    {
        ${USART_INSTANCE_NAME}_ISR_RX_Handler();
    }
    </#if>

    <#if useUSARTTxDMA == true>
    if ((${USART_INSTANCE_NAME}_REGS->US_PTSR & US_PTSR_TXTEN_Msk) && (${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_ENDTX_Msk))
    {
        if(${USART_INSTANCE_NAME?lower_case}Obj.txBusyStatus == true)
        {
            ${USART_INSTANCE_NAME?lower_case}Obj.txBusyStatus = false;
            ${USART_INSTANCE_NAME}_REGS->US_PTCR = US_PTCR_TXTDIS_Msk;
            ${USART_INSTANCE_NAME}_REGS->US_IDR = US_IDR_USART_ENDTX_Msk;

            if( ${USART_INSTANCE_NAME?lower_case}Obj.txCallback != NULL )
            {
                ${USART_INSTANCE_NAME?lower_case}Obj.txCallback(${USART_INSTANCE_NAME?lower_case}Obj.txContext);
            }
        }
    }
    <#else>
    /* Transmitter status */
    if ( (${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_TXRDY_Msk) && (${USART_INSTANCE_NAME}_REGS->US_IMR & US_IMR_USART_TXRDY_Msk) )
    {
        ${USART_INSTANCE_NAME}_ISR_TX_Handler();
    }
    </#if>
}
</#if>

void ${USART_INSTANCE_NAME}_Initialize( void )
{
    /* Reset ${USART_INSTANCE_NAME} */
    ${USART_INSTANCE_NAME}_REGS->US_CR = (US_CR_USART_RSTRX_Msk | US_CR_USART_RSTTX_Msk | US_CR_USART_RSTSTA_Msk);

    /* Enable ${USART_INSTANCE_NAME} */
    ${USART_INSTANCE_NAME}_REGS->US_CR = (US_CR_USART_TXEN_Msk | US_CR_USART_RXEN_Msk);

    /* Configure ${USART_INSTANCE_NAME} mode */
    <#if USART_MR_MODE9 == true>
    ${USART_INSTANCE_NAME}_REGS->US_MR = (US_MR_USART_USCLKS_${USART_CLK_SRC} | US_MR_USART_MODE9_Msk | US_MR_USART_PAR_${USART_MR_PAR} | US_MR_USART_NBSTOP_${USART_MR_NBSTOP} | (${USART_MR_OVER?string} << US_MR_USART_OVER_Pos));
    <#else>
    ${USART_INSTANCE_NAME}_REGS->US_MR = (US_MR_USART_USCLKS_${USART_CLK_SRC} | US_MR_USART_CHRL_${USART_MR_CHRL} | US_MR_USART_PAR_${USART_MR_PAR} | US_MR_USART_NBSTOP_${USART_MR_NBSTOP} | (${USART_MR_OVER?string} << US_MR_USART_OVER_Pos));
    </#if>

    /* Configure ${USART_INSTANCE_NAME} Baud Rate */
    ${USART_INSTANCE_NAME}_REGS->US_BRGR = US_BRGR_CD(${BRG_VALUE});
<#if USART_INTERRUPT_MODE_ENABLE == true>

    /* Initialize instance object */
    ${USART_INSTANCE_NAME?lower_case}Obj.rxBuffer = NULL;
    ${USART_INSTANCE_NAME?lower_case}Obj.rxSize = 0;
    ${USART_INSTANCE_NAME?lower_case}Obj.rxProcessedSize = 0;
    ${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus = false;
    ${USART_INSTANCE_NAME?lower_case}Obj.rxCallback = NULL;
    ${USART_INSTANCE_NAME?lower_case}Obj.txBuffer = NULL;
    ${USART_INSTANCE_NAME?lower_case}Obj.txSize = 0;
    ${USART_INSTANCE_NAME?lower_case}Obj.txProcessedSize = 0;
    ${USART_INSTANCE_NAME?lower_case}Obj.txBusyStatus = false;
    ${USART_INSTANCE_NAME?lower_case}Obj.txCallback = NULL;
    ${USART_INSTANCE_NAME?lower_case}Obj.errorStatus = USART_ERROR_NONE;
</#if>
}

<#if USART_INTERRUPT_MODE_ENABLE == true>
USART_ERROR ${USART_INSTANCE_NAME}_ErrorGet( void )
{
    USART_ERROR errors = ${USART_INSTANCE_NAME?lower_case}Obj.errorStatus;

    ${USART_INSTANCE_NAME?lower_case}Obj.errorStatus = USART_ERROR_NONE;

    /* All errors are cleared, but send the previous error state */
    return errors;
}
<#else>
USART_ERROR ${USART_INSTANCE_NAME}_ErrorGet( void )
{
    USART_ERROR errors = USART_ERROR_NONE;

    uint32_t status = ${USART_INSTANCE_NAME}_REGS->US_CSR;

    errors = (USART_ERROR)(status & (US_CSR_USART_OVRE_Msk | US_CSR_USART_PARE_Msk | US_CSR_USART_FRAME_Msk));

    if(errors != USART_ERROR_NONE)
    {
        ${USART_INSTANCE_NAME}_ErrorClear();
    }

    /* All errors are cleared, but send the previous error state */
    return errors;
}
</#if>

bool ${USART_INSTANCE_NAME}_SerialSetup( USART_SERIAL_SETUP *setup, uint32_t srcClkFreq )
{
    uint32_t baud = setup->baudRate;
    uint32_t brgVal = 0;
    uint32_t overSampVal = 0;
    uint32_t usartMode;
    bool status = false;

<#if USART_INTERRUPT_MODE_ENABLE == true>
    if((${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus == true) || (${USART_INSTANCE_NAME?lower_case}Obj.txBusyStatus == true))
    {
        /* Transaction is in progress, so return without updating settings */
        return false;
    }

</#if>
    if (setup != NULL)
    {
        baud = setup->baudRate;
        if(srcClkFreq == 0)
        {
            srcClkFreq = ${USART_INSTANCE_NAME}_FrequencyGet();
        }

        /* Calculate BRG value */
        if (srcClkFreq >= (16 * baud))
        {
            brgVal = (srcClkFreq / (16 * baud));
        }
        else if (srcClkFreq >= (8 * baud))
        {
            brgVal = (srcClkFreq / (8 * baud));
            overSampVal = US_MR_USART_OVER(1);
        }
        else
        {
            return false;
        }

        if (brgVal > 65535)
        {
            /* The requested baud is so low that the ratio of srcClkFreq to baud exceeds the 16-bit register value of CD register */
            return false;
        }

        /* Configure ${USART_INSTANCE_NAME} mode */
        usartMode = ${USART_INSTANCE_NAME}_REGS->US_MR;
        usartMode &= ~(US_MR_USART_CHRL_Msk | US_MR_USART_MODE9_Msk | US_MR_USART_PAR_Msk | US_MR_USART_NBSTOP_Msk | US_MR_USART_OVER_Msk);
        ${USART_INSTANCE_NAME}_REGS->US_MR = usartMode | ((uint32_t)setup->dataWidth | (uint32_t)setup->parity | (uint32_t)setup->stopBits | (uint32_t)overSampVal);

        /* Configure ${USART_INSTANCE_NAME} Baud Rate */
        ${USART_INSTANCE_NAME}_REGS->US_BRGR = US_BRGR_CD(brgVal);
        status = true;
    }

    return status;
}

bool ${USART_INSTANCE_NAME}_Read( void *buffer, const size_t size )
{
    bool status = false;
<#if USART_INTERRUPT_MODE_ENABLE == false>
    uint32_t errorStatus = 0;
    size_t processedSize = 0;
</#if>
    uint8_t* pBuffer = (uint8_t *)buffer;

    if(pBuffer != NULL)
    {
<#if USART_INTERRUPT_MODE_ENABLE == false>
        /* Clear errors that may have got generated when there was no active read request pending */
        ${USART_INSTANCE_NAME}_ErrorClear();

        while( size > processedSize )
        {
            while (!(${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_RXRDY_Msk));

            /* Read error status */
            errorStatus = (${USART_INSTANCE_NAME}_REGS->US_CSR & (US_CSR_USART_OVRE_Msk | US_CSR_USART_FRAME_Msk | US_CSR_USART_PARE_Msk));

            if(errorStatus != 0)
            {
                break;
            }

            if (${USART_INSTANCE_NAME}_REGS->US_MR & US_MR_USART_MODE9_Msk)
            {
                *((uint16_t*)pBuffer) = (${USART_INSTANCE_NAME}_REGS->US_RHR & US_RHR_RXCHR_Msk);
                pBuffer += 2;
            }
            else
            {
                *pBuffer++ = (${USART_INSTANCE_NAME}_REGS->US_RHR & US_RHR_RXCHR_Msk);
            }

            processedSize++;
        }

        if(size == processedSize)
        {
            status = true;
        }
<#else>
        /* Check if receive request is in progress */
        if(${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus == false)
        {
            /* Clear errors that may have got generated when there was no active read request pending */
            ${USART_INSTANCE_NAME}_ErrorClear();

            /* Clear the errors related to pervious read requests */
            ${USART_INSTANCE_NAME?lower_case}Obj.errorStatus = USART_ERROR_NONE;

            ${USART_INSTANCE_NAME?lower_case}Obj.rxBuffer = pBuffer;
            ${USART_INSTANCE_NAME?lower_case}Obj.rxSize = size;
            ${USART_INSTANCE_NAME?lower_case}Obj.rxProcessedSize = 0;
            ${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus = true;

            status = true;

            <#if useUSARTRxDMA == true>
            ${USART_INSTANCE_NAME}_REGS->US_RPR = (uint32_t)buffer;
            ${USART_INSTANCE_NAME}_REGS->US_RCR = (uint32_t)size;
            ${USART_INSTANCE_NAME}_REGS->US_PTCR = US_PTCR_RXTEN_Msk;
            ${USART_INSTANCE_NAME}_REGS->US_IER = (US_IER_USART_ENDRX_Msk | US_IER_USART_FRAME_Msk | US_IER_USART_PARE_Msk | US_IER_USART_OVRE_Msk);
            <#else>
            /* Enable Read, Overrun, Parity and Framing error interrupts */
            ${USART_INSTANCE_NAME}_REGS->US_IER = (US_IER_USART_RXRDY_Msk | US_IER_USART_FRAME_Msk | US_IER_USART_PARE_Msk | US_IER_USART_OVRE_Msk);
            </#if>
        }
</#if>
    }

    return status;
}

bool ${USART_INSTANCE_NAME}_Write( void *buffer, const size_t size )
{
    bool status = false;
<#if USART_INTERRUPT_MODE_ENABLE == false>
    size_t processedSize = 0;
</#if>
    uint8_t* pBuffer = (uint8_t *)buffer;

    if(NULL != pBuffer)
    {
<#if USART_INTERRUPT_MODE_ENABLE == false>
        while( size > processedSize )
        {
            while (!(${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_TXRDY_Msk));

            if (${USART_INSTANCE_NAME}_REGS->US_MR & US_MR_USART_MODE9_Msk)
            {
                ${USART_INSTANCE_NAME}_REGS->US_THR = ((uint16_t*)pBuffer)[processedSize++] & US_THR_TXCHR_Msk;
            }
            else
            {
                ${USART_INSTANCE_NAME}_REGS->US_THR = pBuffer[processedSize++] & US_THR_TXCHR_Msk;
            }
        }

        status = true;
<#else>
        /* Check if transmit request is in progress */
        if(${USART_INSTANCE_NAME?lower_case}Obj.txBusyStatus == false)
        {
            ${USART_INSTANCE_NAME?lower_case}Obj.txBuffer = pBuffer;
            ${USART_INSTANCE_NAME?lower_case}Obj.txSize = size;
            ${USART_INSTANCE_NAME?lower_case}Obj.txProcessedSize = 0;
            ${USART_INSTANCE_NAME?lower_case}Obj.txBusyStatus = true;
            status = true;

            <#if useUSARTTxDMA == true>
            ${USART_INSTANCE_NAME}_REGS->US_TPR = (uint32_t)buffer;
            ${USART_INSTANCE_NAME}_REGS->US_TCR = (uint32_t)size;
            ${USART_INSTANCE_NAME}_REGS->US_PTCR = US_PTCR_TXTEN_Msk;
            ${USART_INSTANCE_NAME}_REGS->US_IER = US_IER_USART_ENDTX_Msk;
            <#else>
            /* Initiate the transfer by writing as many bytes as possible */
            while ((${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_TXRDY_Msk) && (${USART_INSTANCE_NAME?lower_case}Obj.txProcessedSize < ${USART_INSTANCE_NAME?lower_case}Obj.txSize))
            {
                if (${USART_INSTANCE_NAME}_REGS->US_MR & US_MR_USART_MODE9_Msk)
                {
                    ${USART_INSTANCE_NAME}_REGS->US_THR = ((uint16_t*)pBuffer)[${USART_INSTANCE_NAME?lower_case}Obj.txProcessedSize++] & US_THR_TXCHR_Msk;
                }
                else
                {
                    ${USART_INSTANCE_NAME}_REGS->US_THR = pBuffer[${USART_INSTANCE_NAME?lower_case}Obj.txProcessedSize++] & US_THR_TXCHR_Msk;
                }
            }

            ${USART_INSTANCE_NAME}_REGS->US_IER = US_IER_USART_TXRDY_Msk;

            </#if>
        }
</#if>
    }

    return status;
}

<#if USART_INTERRUPT_MODE_ENABLE == false>
int ${USART_INSTANCE_NAME}_ReadByte( void )
{
    return(${USART_INSTANCE_NAME}_REGS->US_RHR & US_RHR_RXCHR_Msk);
}

void ${USART_INSTANCE_NAME}_WriteByte( int data )
{
    while (!(${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_TXRDY_Msk));

    ${USART_INSTANCE_NAME}_REGS->US_THR = (US_THR_TXCHR(data) & US_THR_TXCHR_Msk);
}

bool ${USART_INSTANCE_NAME}_TransmitterIsReady( void )
{
    if(${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_TXRDY_Msk)
    {
        return true;
    }

    return false;
}

bool ${USART_INSTANCE_NAME}_TransmitComplete( void )
{
    if(${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_TXEMPTY_Msk)
    {
        return true;
    }

    return false;
}

bool ${USART_INSTANCE_NAME}_ReceiverIsReady( void )
{
    if(${USART_INSTANCE_NAME}_REGS->US_CSR & US_CSR_USART_RXRDY_Msk)
    {
        return true;
    }

    return false;
}

</#if>

<#if USART_INTERRUPT_MODE_ENABLE == true>
void ${USART_INSTANCE_NAME}_WriteCallbackRegister( USART_CALLBACK callback, uintptr_t context )
{
    ${USART_INSTANCE_NAME?lower_case}Obj.txCallback = callback;

    ${USART_INSTANCE_NAME?lower_case}Obj.txContext = context;
}

void ${USART_INSTANCE_NAME}_ReadCallbackRegister( USART_CALLBACK callback, uintptr_t context )
{
    ${USART_INSTANCE_NAME?lower_case}Obj.rxCallback = callback;

    ${USART_INSTANCE_NAME?lower_case}Obj.rxContext = context;
}

void ${USART_INSTANCE_NAME}_ReadTimeoutCallbackRegister( USART_CALLBACK callback, uintptr_t context )
{
    ${USART_INSTANCE_NAME?lower_case}Obj.rxTimeoutCallback = callback;

    ${USART_INSTANCE_NAME?lower_case}Obj.rxTimeoutContext = context;
}

bool ${USART_INSTANCE_NAME}_WriteIsBusy( void )
{
    return ${USART_INSTANCE_NAME?lower_case}Obj.txBusyStatus;
}

bool ${USART_INSTANCE_NAME}_ReadIsBusy( void )
{
    return ${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus;
}

bool ${USART_INSTANCE_NAME}_ReadAbort(void)
{
    if (${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus == true)
    {
        /* Disable Read, Overrun, Parity and Framing error interrupts */
        ${USART_INSTANCE_NAME}_REGS->US_IDR = (US_IDR_USART_RXRDY_Msk | US_IDR_USART_FRAME_Msk | US_IDR_USART_PARE_Msk | US_IDR_USART_OVRE_Msk);

        ${USART_INSTANCE_NAME?lower_case}Obj.rxBusyStatus = false;

        /* If required application should read the num bytes processed prior to calling the read abort API */
        ${USART_INSTANCE_NAME?lower_case}Obj.rxSize = ${USART_INSTANCE_NAME?lower_case}Obj.rxProcessedSize = 0;
    }

    return true;
}

size_t ${USART_INSTANCE_NAME}_WriteCountGet( void )
{
    <#if useUSARTTxDMA == true>
    return (${USART_INSTANCE_NAME?lower_case}Obj.txSize - ${USART_INSTANCE_NAME}_REGS->US_TCR);
    <#else>
    return ${USART_INSTANCE_NAME?lower_case}Obj.txProcessedSize;
    </#if>
}

size_t ${USART_INSTANCE_NAME}_ReadCountGet( void )
{
    <#if useUSARTRxDMA == true>
    return (${USART_INSTANCE_NAME?lower_case}Obj.rxSize - ${USART_INSTANCE_NAME}_REGS->US_RCR);
    <#else>
    return ${USART_INSTANCE_NAME?lower_case}Obj.rxProcessedSize;
    </#if>
}

</#if>