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
import {
  error,
  log,
} from '@mplab_harmony/harmony-plugin-core-service/build/log/CustomConsole';
import SymbolConfig from './SymbolConfig';
// import simpleSymbolConfig from './symbol-config.json';

export class PluginService {
  private readonly pluginConfig: any;
  private readonly _initArgs: Map<string, object>;
  private _symbolConfig!: SymbolConfig;

  constructor() {
    this.pluginConfig = (window as any).pluginConfig;

    try {
      this._initArgs = this.pluginConfig.initArgs();
    } catch (errr) {
      log('init args error : ' + errr);
      this._initArgs = new Map();
      return;
    }

    const symbolConfigPath = JSON.parse(
      JSON.stringify(this.initArgs.get('symbol_config'))
    ) as string;

    // this._symbolConfig = simpleSymbolConfig;

    this._symbolConfig = this.readJSON(
      this.absolutePath(symbolConfigPath)
    ) as SymbolConfig;
    // this.printSymbolConfig();
  }

  private printSymbolConfig(): void {
    log('symbol config : full ' + JSON.stringify(this._symbolConfig));
  }

  private async readJSONAsync(url: string) {
    try {
      const response = await fetch(url);
      const json = await response.json();
      log('Successfully read JSON from ' + url);
      return json;
    } catch (err) {
      error('Unable to fetch URL : ' + url + '\n' + err);
    }
  }

  // resolves the provided relative path with Framework Root Path
  // relative path should start with a word(file or folder name).
  // e.g. 'csp/peripheral/dma_03639/plugin/symbol-config.json'
  // it should not start with . or ./ or / or ../
  public absolutePath(relativePath: string): string {
    return this.frameworkRoot() + '/' + relativePath;
  }

  public frameworkRoot(): string {
    const { protocol, host } = document.location;
    return protocol + '//' + host;
  }

  private readJSON(path: string): object {
    const request = new XMLHttpRequest();
    request.open('GET', path, false);
    request.send(null);

    if (request.status === 200) {
      return JSON.parse(request.responseText);
    } else {
      throw new Error('Unable to read url : ' + path);
    }
  }

  get symbolConfig(): SymbolConfig {
    return this._symbolConfig;
  }

  get initArgs(): Map<string, object> {
    return this._initArgs;
  }
}

export const pluginService = new PluginService();
