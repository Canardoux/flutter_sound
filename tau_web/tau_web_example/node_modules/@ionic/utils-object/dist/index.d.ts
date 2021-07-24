export declare function createCaseInsensitiveObject<T>(): {
    [key: string]: T;
};
export declare const CaseInsensitiveProxyHandler: ProxyHandler<any>;
export declare type AliasedMapKey = string | symbol;
export declare class AliasedMap<K, V> extends Map<AliasedMapKey | K, AliasedMapKey | V> {
    getAliases(): Map<AliasedMapKey, AliasedMapKey[]>;
    resolveAlias(key: AliasedMapKey | K): V | undefined;
    keysWithoutAliases(): K[];
}
