"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AliasedMap = exports.CaseInsensitiveProxyHandler = exports.createCaseInsensitiveObject = void 0;
function createCaseInsensitiveObject() {
    return new Proxy({}, exports.CaseInsensitiveProxyHandler);
}
exports.createCaseInsensitiveObject = createCaseInsensitiveObject;
exports.CaseInsensitiveProxyHandler = {
    has: (obj, prop) => {
        return conformPropertyKey(prop) in obj;
    },
    get: (obj, prop) => {
        return obj[conformPropertyKey(prop)];
    },
    set: (obj, prop, value) => {
        obj[conformPropertyKey(prop)] = value;
        return true;
    },
    deleteProperty: (obj, prop) => {
        return delete obj[conformPropertyKey(prop)];
    },
};
const conformPropertyKey = (prop) => typeof prop === 'string' ? prop.toLowerCase() : prop;
class AliasedMap extends Map {
    getAliases() {
        const aliasmap = new Map();
        // TODO: waiting for https://github.com/Microsoft/TypeScript/issues/18562
        const aliases = [...this.entries()].filter(([, v]) => typeof v === 'string' || typeof v === 'symbol');
        aliases.forEach(([alias, cmd]) => {
            const cmdaliases = aliasmap.get(cmd) || [];
            cmdaliases.push(alias);
            aliasmap.set(cmd, cmdaliases);
        });
        return aliasmap;
    }
    resolveAlias(key) {
        const r = this.get(key);
        if (typeof r !== 'string' && typeof r !== 'symbol') {
            return r;
        }
        return this.resolveAlias(r);
    }
    keysWithoutAliases() {
        return [...this.entries()]
            .filter((entry) => typeof entry[1] !== 'string' && typeof entry[1] !== 'symbol')
            .map(([k, v]) => k);
    }
}
exports.AliasedMap = AliasedMap;
