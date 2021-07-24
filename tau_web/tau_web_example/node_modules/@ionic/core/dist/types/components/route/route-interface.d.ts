export declare type NavigationHookCallback = () => NavigationHookResult | Promise<NavigationHookResult>;
export declare type NavigationHookResult = boolean | NavigationHookOptions;
export interface NavigationHookOptions {
  redirect: string;
}
