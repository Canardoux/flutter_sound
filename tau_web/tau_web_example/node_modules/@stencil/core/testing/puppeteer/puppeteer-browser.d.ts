import type { Config } from '@stencil/core/internal';
import type * as puppeteer from 'puppeteer';
export declare function startPuppeteerBrowser(config: Config): Promise<any>;
export declare function connectBrowser(): Promise<any>;
export declare function disconnectBrowser(browser: puppeteer.Browser): Promise<void>;
export declare function newBrowserPage(browser: puppeteer.Browser): Promise<puppeteer.Page>;
