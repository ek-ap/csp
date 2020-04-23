/**
 * \file
 *
 * \brief IAR linker script (flash) for ${DEVICE_NAME}
 *
 * Copyright (c) 2019 Microchip Technology Inc.
 *
 * \license_start
 *
 * \page License
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * \license_stop
 *
 */

/*###ICF### Section handled by ICF editor, don't touch! ****/
/*-Editor annotation file-*/
/* IcfEditorFile="$TOOLKIT_DIR$\config\ide\IcfEditor\cortex_v1_0.xml" */
/*-Specials-*/
define symbol __ICFEDIT_intvec_start__     = ${IROM1_START};
/*-Memory Regions-*/
define symbol __ICFEDIT_region_RAM_start__ = ${IRAM1_START};
define symbol __ICFEDIT_region_RAM_end__   = ${IRAM1_END};
define symbol __ICFEDIT_region_ROM_start__ = ${IROM1_START};
define symbol __ICFEDIT_region_ROM_end__   = ${IROM1_END};
/*-Sizes-*/
if (!isdefinedsymbol(__ICFEDIT_size_cstack__)) {
  define symbol __ICFEDIT_size_cstack__    = ${IAR_USR_STACK_SIZE};
}
if (!isdefinedsymbol(__ICFEDIT_size_heap__)) {
  define symbol __ICFEDIT_size_heap__      = ${IAR_HEAP_SIZE};
}
/**** End of ICF editor section. ###ICF###*/

define memory mem with size = 4G;
define region RAM_region    = mem:[from __ICFEDIT_region_RAM_start__ to __ICFEDIT_region_RAM_end__];
define region ROM_region    = mem:[from __ICFEDIT_region_ROM_start__ to __ICFEDIT_region_ROM_end__];

define block CSTACK with alignment = 8, size = __ICFEDIT_size_cstack__ { };
define block HEAP   with alignment = 8, size = __ICFEDIT_size_heap__   { };

initialize by copy  { readwrite };


place at address mem:__ICFEDIT_intvec_start__ { readonly section .intvec };
place in ROM_region                           { readonly };
place in RAM_region                           { readwrite, block HEAP };
place at end of RAM_region                    { block CSTACK };
