# coding: utf-8
"""*****************************************************************************
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
*****************************************************************************"""

def updateDSCON(symbol, event):
    DSCON_Value = symbol.getValue()

    if event["id"] == "DS_RTCC_ENABLE":
        bitPos = 12
        if event["value"] == False:
            DSCON_Value |= 1 << bitPos
        else:
            DSCON_Value &= ~(1 << bitPos)        
    elif event["id"] == "DS_RTCC_WAKEUP_DISABLE":
        bitPos = 8
        if event["value"] == False:
            DSCON_Value |= 1 << bitPos
        else:
            DSCON_Value &= ~(1 << bitPos)         
    elif event["id"] == "DS_EXTENDED_REG_ENABLE":
        bitPos = 13
        if event["value"] == True:
            DSCON_Value |= 1 << bitPos
        else:
            DSCON_Value &= ~(1 << bitPos)
    else:
        return

    symbol.setValue(DSCON_Value, 2)

###################################################################################################
########################################## Component ##############################################
###################################################################################################
global dsModuleName

def instantiateComponent(powerComponent):
    # DRMEN symbol
    if "PIC32M" in Variables.get("__PROCESSOR"):
        clkValGrp_OSCCON__DRMEN = ATDF.getNode('/avr-tools-device-file/modules/module@[name="OSC"]/value-group@[name="OSCCON__DRMEN"]')
    else:
        clkValGrp_OSCCON__DRMEN = ATDF.getNode('/avr-tools-device-file/modules/module@[name="CRU"]/value-group@[name="OSCCON__DRMEN"]')
    
    if clkValGrp_OSCCON__DRMEN is not None:
        dreamModeExist = powerComponent.createBooleanSymbol("DREAM_MODE_EXIST", None)
        dreamModeExist.setDefaultValue(True)
        dreamModeExist.setVisible(False)

    if ATDF.getNode('/avr-tools-device-file/modules/module@[name="DSCON"]') is not None:
        dsModuleName = "DSCON"
    elif ATDF.getNode('/avr-tools-device-file/modules/module@[name="DSCTRL"]') is not None:
        dsModuleName = "DSCTRL"
    else:
        dsModuleName = "None"

    if dsModuleName != "None":
        deepSleepSymMenu = powerComponent.createMenuSymbol("DEEP_SLEEP_MODE_MENU", None)
        deepSleepSymMenu.setLabel("Deep Sleep Mode Configuration")

        deepSleepSymExist = powerComponent.createBooleanSymbol("DEEP_SLEEP_MODE_EXIST", deepSleepSymMenu)
        deepSleepSymExist.setVisible(False)
        deepSleepSymExist.setDefaultValue(True)

        deepSleepSym_RTCDIS = powerComponent.createBooleanSymbol("DS_RTCC_ENABLE", deepSleepSymMenu)
        deepSleepSym_RTCDIS.setLabel("Enable RTCC during Deep Sleep")
        deepSleepSym_RTCDIS.setDefaultValue(True)
        
        deepSleepSym_RTCCWDIS = powerComponent.createBooleanSymbol("DS_RTCC_WAKEUP_DISABLE", deepSleepSymMenu)
        deepSleepSym_RTCCWDIS.setLabel("Enable Deep Sleep Wakeup from RTCC")
        deepSleepSym_RTCCWDIS.setDefaultValue(True)

        deepSleepSym_DSGPREN = powerComponent.createBooleanSymbol("DS_EXTENDED_REG_ENABLE", deepSleepSymMenu)
        if dsModuleName == "DSCTRL":
            deepSleepSym_DSGPREN.setLabel("Enable General Purpose Registers 1 to 32")
        elif dsModuleName == "DSCON":
            deepSleepSym_DSGPREN.setLabel("Enable Extended Semaphore Registers")
        deepSleepSym_DSGPREN.setDefaultValue(False)
        
        deepSleepSym_DSCON_RegValue = powerComponent.createHexSymbol("DSCON_VALUE", deepSleepSymMenu)
        deepSleepSym_DSCON_RegValue.setDefaultValue(0x00000000)
        deepSleepSym_DSCON_RegValue.setVisible(False)
        deepSleepSym_DSCON_RegValue.setDependencies(updateDSCON, ["DS_EXTENDED_REG_ENABLE", "DS_RTCC_WAKEUP_DISABLE", "DS_RTCC_ENABLE"])

        dswakeRegister = ATDF.getNode('/avr-tools-device-file/modules/module@[name="'+dsModuleName+'"]/register-group@[name="'+dsModuleName+'"]/register@[name="DSWAKE"]')

        deepSleepSym_ResetCount = powerComponent.createIntegerSymbol("DS_WAKEUP_CAUSE_COUNT", deepSleepSymMenu)
        deepSleepSym_ResetCount.setDefaultValue(len(dswakeRegister.getChildren()))
        deepSleepSym_ResetCount.setVisible(False)

        for id in range(len(dswakeRegister.getChildren())):
            deepSleepSym_Cause = powerComponent.createKeyValueSetSymbol("DS_WAKEUP_CAUSE_" + str(id), deepSleepSymMenu)
            deepSleepSym_Cause.setLabel(str(dswakeRegister.getChildren()[id].getAttribute("name")))
            deepSleepSym_Cause.addKey(dswakeRegister.getChildren()[id].getAttribute("name"), str(id), dswakeRegister.getChildren()[id].getAttribute("caption"))
            deepSleepSym_Cause.setOutputMode("Key")
            deepSleepSym_Cause.setDisplayMode("Description")
            deepSleepSym_Cause.setVisible(False)

    ###################################################################################################
    ####################################### Code Generation  ##########################################
    ###################################################################################################

    configName = Variables.get("__CONFIGURATION_NAME")

    #DEVCFG2.DSEN configuration bit should be enabled to enter deep sleep mode
    Database.setSymbolValue("core", "CONFIG_DSEN", "ON", 1)

    power_HeaderFile = powerComponent.createFileSymbol("POWER_HEADER", None)
    if (("PIC32MZ" in Variables.get("__PROCESSOR")) and ("W" in Variables.get("__PROCESSOR"))):
        power_HeaderFile.setSourcePath("../peripheral/power/templates/plib_power_pic32mzw.h.ftl")
    elif "PIC32M" in Variables.get("__PROCESSOR"):
        power_HeaderFile.setSourcePath("../peripheral/power/templates/plib_power.h.ftl")        
    else:
        power_HeaderFile.setSourcePath("../peripheral/power/templates/plib_power_pic32c.h.ftl")
    power_HeaderFile.setOutputName("plib_power.h")
    power_HeaderFile.setDestPath("peripheral/power/")
    power_HeaderFile.setProjectPath("config/" + configName + "/peripheral/power/")
    power_HeaderFile.setType("HEADER")
    power_HeaderFile.setMarkup(True)

    power_SourceFile = powerComponent.createFileSymbol("POWER_SOURCE", None)
    if (("PIC32MZ" in Variables.get("__PROCESSOR")) and ("W" in Variables.get("__PROCESSOR"))):
        power_SourceFile.setSourcePath("../peripheral/power/templates/plib_power_pic32mzw.c.ftl")
    elif "PIC32M" in Variables.get("__PROCESSOR"):
        power_SourceFile.setSourcePath("../peripheral/power/templates/plib_power.c.ftl")        
    else:
        power_SourceFile.setSourcePath("../peripheral/power/templates/plib_power_pic32c.c.ftl")
    power_SourceFile.setOutputName("plib_power.c")
    power_SourceFile.setDestPath("peripheral/power/")
    power_SourceFile.setProjectPath("config/" + configName + "/peripheral/power/")
    power_SourceFile.setType("SOURCE")
    power_SourceFile.setMarkup(True)

    if dsModuleName != "None":
        dsctrl_SystemInitFile = powerComponent.createFileSymbol("POWER_INIT", None)
        dsctrl_SystemInitFile.setType("STRING")
        dsctrl_SystemInitFile.setOutputName("core.LIST_SYSTEM_INIT_C_SYS_INITIALIZE_CORE1")
        dsctrl_SystemInitFile.setSourcePath("../peripheral/power/templates/system/initialization.c.ftl")
        dsctrl_SystemInitFile.setMarkup(True)

    power_SystemDefFile = powerComponent.createFileSymbol("POWER_SYS_DEF", None)
    power_SystemDefFile.setType("STRING")
    power_SystemDefFile.setOutputName("core.LIST_SYSTEM_DEFINITIONS_H_INCLUDES")
    power_SystemDefFile.setSourcePath("../peripheral/power/templates/system/definitions.h.ftl")
    power_SystemDefFile.setMarkup(True)
