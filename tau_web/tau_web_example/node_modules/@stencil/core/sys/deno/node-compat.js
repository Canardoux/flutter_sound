/*! Copyright 2018-2020 the Deno authors. All rights reserved. MIT license.
 *  https://github.com/denoland/deno/blob/master/LICENSE
 *  https://deno.land/  */
function assertPath(e) {
 if ("string" != typeof e) throw new TypeError(`Path must be a string. Received ${JSON.stringify(e)}`);
}

function isPosixPathSeparator(e) {
 return 47 === e;
}

function isPathSeparator(e) {
 return isPosixPathSeparator(e) || 92 === e;
}

function isWindowsDeviceRoot(e) {
 return e >= 97 && e <= 122 || e >= 65 && e <= 90;
}

function normalizeString(e, t, n, r) {
 let i, o = "", s = 0, a = -1, l = 0;
 for (let c = 0, u = e.length; c <= u; ++c) {
  if (c < u) i = e.charCodeAt(c); else {
   if (r(i)) break;
   i = 47;
  }
  if (r(i)) {
   if (a === c - 1 || 1 === l) ; else if (a !== c - 1 && 2 === l) {
    if (o.length < 2 || 2 !== s || 46 !== o.charCodeAt(o.length - 1) || 46 !== o.charCodeAt(o.length - 2)) {
     if (o.length > 2) {
      const e = o.lastIndexOf(n);
      -1 === e ? (o = "", s = 0) : (o = o.slice(0, e), s = o.length - 1 - o.lastIndexOf(n)), 
      a = c, l = 0;
      continue;
     }
     if (2 === o.length || 1 === o.length) {
      o = "", s = 0, a = c, l = 0;
      continue;
     }
    }
    t && (o.length > 0 ? o += `${n}..` : o = "..", s = 2);
   } else o.length > 0 ? o += n + e.slice(a + 1, c) : o = e.slice(a + 1, c), s = c - a - 1;
   a = c, l = 0;
  } else 46 === i && -1 !== l ? ++l : l = -1;
 }
 return o;
}

function _format(e, t) {
 const n = t.dir || t.root, r = t.base || (t.name || "") + (t.ext || "");
 return n ? n === t.root ? n + r : n + e + r : r;
}

function assert(e, t = "") {
 if (!e) throw new DenoStdInternalError(t);
}

function resolve$2(...e) {
 let t = "", n = "", r = !1;
 for (let i = e.length - 1; i >= -1; i--) {
  let o;
  if (i >= 0) o = e[i]; else if (t) {
   if (null == globalThis.Deno) throw new TypeError("Resolved a relative path without a CWD.");
   o = Deno.env.get(`=${t}`) || Deno.cwd(), void 0 !== o && o.slice(0, 3).toLowerCase() === `${t.toLowerCase()}\\` || (o = `${t}\\`);
  } else {
   if (null == globalThis.Deno) throw new TypeError("Resolved a drive-letter-less path without a CWD.");
   o = Deno.cwd();
  }
  assertPath(o);
  const s = o.length;
  if (0 === s) continue;
  let a = 0, l = "", c = !1;
  const u = o.charCodeAt(0);
  if (s > 1) if (isPathSeparator(u)) if (c = !0, isPathSeparator(o.charCodeAt(1))) {
   let e = 2, t = e;
   for (;e < s && !isPathSeparator(o.charCodeAt(e)); ++e) ;
   if (e < s && e !== t) {
    const n = o.slice(t, e);
    for (t = e; e < s && isPathSeparator(o.charCodeAt(e)); ++e) ;
    if (e < s && e !== t) {
     for (t = e; e < s && !isPathSeparator(o.charCodeAt(e)); ++e) ;
     e === s ? (l = `\\\\${n}\\${o.slice(t)}`, a = e) : e !== t && (l = `\\\\${n}\\${o.slice(t, e)}`, 
     a = e);
    }
   }
  } else a = 1; else isWindowsDeviceRoot(u) && 58 === o.charCodeAt(1) && (l = o.slice(0, 2), 
  a = 2, s > 2 && isPathSeparator(o.charCodeAt(2)) && (c = !0, a = 3)); else isPathSeparator(u) && (a = 1, 
  c = !0);
  if (!(l.length > 0 && t.length > 0 && l.toLowerCase() !== t.toLowerCase()) && (0 === t.length && l.length > 0 && (t = l), 
  r || (n = `${o.slice(a)}\\${n}`, r = c), r && t.length > 0)) break;
 }
 return n = normalizeString(n, !r, "\\", isPathSeparator), t + (r ? "\\" : "") + n || ".";
}

function normalize$2(e) {
 assertPath(e);
 const t = e.length;
 if (0 === t) return ".";
 let n, r = 0, i = !1;
 const o = e.charCodeAt(0);
 if (t > 1) if (isPathSeparator(o)) if (i = !0, isPathSeparator(e.charCodeAt(1))) {
  let i = 2, o = i;
  for (;i < t && !isPathSeparator(e.charCodeAt(i)); ++i) ;
  if (i < t && i !== o) {
   const s = e.slice(o, i);
   for (o = i; i < t && isPathSeparator(e.charCodeAt(i)); ++i) ;
   if (i < t && i !== o) {
    for (o = i; i < t && !isPathSeparator(e.charCodeAt(i)); ++i) ;
    if (i === t) return `\\\\${s}\\${e.slice(o)}\\`;
    i !== o && (n = `\\\\${s}\\${e.slice(o, i)}`, r = i);
   }
  }
 } else r = 1; else isWindowsDeviceRoot(o) && 58 === e.charCodeAt(1) && (n = e.slice(0, 2), 
 r = 2, t > 2 && isPathSeparator(e.charCodeAt(2)) && (i = !0, r = 3)); else if (isPathSeparator(o)) return "\\";
 let s;
 return s = r < t ? normalizeString(e.slice(r), !i, "\\", isPathSeparator) : "", 
 0 !== s.length || i || (s = "."), s.length > 0 && isPathSeparator(e.charCodeAt(t - 1)) && (s += "\\"), 
 void 0 === n ? i ? s.length > 0 ? `\\${s}` : "\\" : s.length > 0 ? s : "" : i ? s.length > 0 ? `${n}\\${s}` : `${n}\\` : s.length > 0 ? n + s : n;
}

function resolve$1(...e) {
 let t = "", n = !1;
 for (let r = e.length - 1; r >= -1 && !n; r--) {
  let i;
  if (r >= 0) i = e[r]; else {
   if (null == globalThis.Deno) throw new TypeError("Resolved a relative path without a CWD.");
   i = Deno.cwd();
  }
  assertPath(i), 0 !== i.length && (t = `${i}/${t}`, n = 47 === i.charCodeAt(0));
 }
 return t = normalizeString(t, !n, "/", isPosixPathSeparator), n ? t.length > 0 ? `/${t}` : "/" : t.length > 0 ? t : ".";
}

function normalize$1(e) {
 if (assertPath(e), 0 === e.length) return ".";
 const t = 47 === e.charCodeAt(0), n = 47 === e.charCodeAt(e.length - 1);
 return 0 !== (e = normalizeString(e, !t, "/", isPosixPathSeparator)).length || t || (e = "."), 
 e.length > 0 && n && (e += "/"), t ? `/${e}` : e;
}

function normalizeGlob(e, {globstar: t = !1} = {}) {
 if (e.match(/\0/g)) throw new Error(`Glob contains invalid characters: "${e}"`);
 if (!t) return normalize(e);
 const n = SEP_PATTERN.source, r = new RegExp(`(?<=(${n}|^)\\*\\*${n})\\.\\.(?=${n}|$)`, "g");
 return normalize(e.replace(r, "\0")).replace(/\0/g, "..");
}

function fromHexChar(e) {
 if (48 <= e && e <= 57) return e - 48;
 if (97 <= e && e <= 102) return e - 97 + 10;
 if (65 <= e && e <= 70) return e - 65 + 10;
 throw function t(e) {
  return new Error("encoding/hex: invalid byte: " + (new TextDecoder).decode(new Uint8Array([ e ])));
 }(e);
}

function notImplemented(e) {
 throw new Error(e ? `Not implemented: ${e}` : "Not implemented");
}

function normalizeEncoding$1(e) {
 return null == e || "utf8" === e || "utf-8" === e ? "utf8" : function t(e) {
  switch (e.length) {
  case 4:
   if ("UTF8" === e) return "utf8";
   if ("ucs2" === e || "UCS2" === e) return "utf16le";
   if ("utf8" === (e = `${e}`.toLowerCase())) return "utf8";
   if ("ucs2" === e) return "utf16le";
   break;

  case 3:
   if ("hex" === e || "HEX" === e || "hex" === `${e}`.toLowerCase()) return "hex";
   break;

  case 5:
   if ("ascii" === e) return "ascii";
   if ("ucs-2" === e) return "utf16le";
   if ("UTF-8" === e) return "utf8";
   if ("ASCII" === e) return "ascii";
   if ("UCS-2" === e) return "utf16le";
   if ("utf-8" === (e = `${e}`.toLowerCase())) return "utf8";
   if ("ascii" === e) return "ascii";
   if ("ucs-2" === e) return "utf16le";
   break;

  case 6:
   if ("base64" === e) return "base64";
   if ("latin1" === e || "binary" === e) return "latin1";
   if ("BASE64" === e) return "base64";
   if ("LATIN1" === e || "BINARY" === e) return "latin1";
   if ("base64" === (e = `${e}`.toLowerCase())) return "base64";
   if ("latin1" === e || "binary" === e) return "latin1";
   break;

  case 7:
   if ("utf16le" === e || "UTF16LE" === e || "utf16le" === `${e}`.toLowerCase()) return "utf16le";
   break;

  case 8:
   if ("utf-16le" === e || "UTF-16LE" === e || "utf-16le" === `${e}`.toLowerCase()) return "utf16le";
   break;

  default:
   if ("" === e) return "utf8";
  }
 }(e);
}

function checkEncoding$1(e = "utf8", t = !0) {
 if ("string" != typeof e || t && "" === e) {
  if (!t) return "utf8";
  throw new TypeError(`Unkown encoding: ${e}`);
 }
 const n = normalizeEncoding$1(e);
 if (void 0 === n) throw new TypeError(`Unkown encoding: ${e}`);
 return notImplementedEncodings.includes(e) && notImplemented(`"${e}" encoding`), 
 n;
}

function promisify(e) {
 function t(...t) {
  return new Promise(((r, i) => {
   e.call(this, ...t, ((e, ...t) => {
    if (e) return i(e);
    if (void 0 !== n && t.length > 1) {
     const e = {};
     for (let r = 0; r < n.length; r++) e[n[r]] = t[r];
     r(e);
    } else r(t[0]);
   }));
  }));
 }
 if ("function" != typeof e) throw new NodeInvalidArgTypeError$1("original", "Function", e);
 if (e[kCustomPromisifiedSymbol]) {
  const t = e[kCustomPromisifiedSymbol];
  if ("function" != typeof t) throw new NodeInvalidArgTypeError$1("util.promisify.custom", "Function", t);
  return Object.defineProperty(t, kCustomPromisifiedSymbol, {
   value: t,
   enumerable: !1,
   writable: !1,
   configurable: !0
  });
 }
 const n = e[kCustomPromisifyArgsSymbol];
 return Object.setPrototypeOf(t, Object.getPrototypeOf(e)), Object.defineProperty(t, kCustomPromisifiedSymbol, {
  value: t,
  enumerable: !1,
  writable: !1,
  configurable: !0
 }), Object.defineProperties(t, Object.getOwnPropertyDescriptors(e));
}

function isBooleanObject(e) {
 return _isObjectLike(e) && "[object Boolean]" === _toString.call(e);
}

function isNumberObject(e) {
 return _isObjectLike(e) && "[object Number]" === _toString.call(e);
}

function isBigIntObject(e) {
 return _isObjectLike(e) && "[object BigInt]" === _toString.call(e);
}

function isStringObject(e) {
 return _isObjectLike(e) && "[object String]" === _toString.call(e);
}

function isSymbolObject(e) {
 return _isObjectLike(e) && "[object Symbol]" === _toString.call(e);
}

function validateIntegerRange(e, t, n = -2147483648, r = 2147483647) {
 if (!Number.isInteger(e)) throw new Error(`${t} must be 'an integer' but was ${e}`);
 if (e < n || e > r) throw new Error(`${t} must be >= ${n} && <= ${r}.  Value was ${e}`);
}

function createIterResult(e, t) {
 return {
  value: e,
  done: t
 };
}

function isFileOptions(e) {
 return !!e && (null != e.encoding || null != e.flag || null != e.mode);
}

function getEncoding$1(e) {
 if (!e || "function" == typeof e) return null;
 return ("string" == typeof e ? e : e.encoding) || null;
}

function checkEncoding(e) {
 if (!e) return null;
 if (e = e.toLowerCase(), [ "utf8", "hex", "base64" ].includes(e)) return e;
 if ("utf-8" === e) return "utf8";
 if ("binary" === e) return "binary";
 throw [ "utf16le", "latin1", "ascii", "ucs2" ].includes(e) && notImplemented(`"${e}" encoding`), 
 new Error(`The value "${e}" is invalid for option "encoding"`);
}

function getOpenOptions(e) {
 if (!e) return {
  create: !0,
  append: !0
 };
 let t;
 switch (e) {
 case "a":
  t = {
   create: !0,
   append: !0
  };
  break;

 case "ax":
  t = {
   createNew: !0,
   write: !0,
   append: !0
  };
  break;

 case "a+":
  t = {
   read: !0,
   create: !0,
   append: !0
  };
  break;

 case "ax+":
  t = {
   read: !0,
   createNew: !0,
   append: !0
  };
  break;

 case "r":
  t = {
   read: !0
  };
  break;

 case "r+":
  t = {
   read: !0,
   write: !0
  };
  break;

 case "w":
  t = {
   create: !0,
   write: !0,
   truncate: !0
  };
  break;

 case "wx":
  t = {
   createNew: !0,
   write: !0
  };
  break;

 case "w+":
  t = {
   create: !0,
   write: !0,
   truncate: !0,
   read: !0
  };
  break;

 case "wx+":
  t = {
   createNew: !0,
   write: !0,
   read: !0
  };
  break;

 case "as":
  t = {
   create: !0,
   append: !0
  };

 case "as+":
  t = {
   create: !0,
   read: !0,
   append: !0
  };

 case "rs+":
  t = {
   create: !0,
   read: !0,
   write: !0
  };

 default:
  throw new Error(`Unrecognized file system flag: ${e}`);
 }
 return t;
}

function closeRidIfNecessary(e, t) {
 e && -1 != t && Deno.close(t);
}

function validateEncoding(e) {
 if (e) if ("string" == typeof e) {
  if ("utf8" !== e) throw new Error("Only 'utf8' encoding is currently supported");
 } else if (e.encoding && "utf8" !== e.encoding) throw new Error("Only 'utf8' encoding is currently supported");
}

function getResolvedMode(e) {
 if ("number" == typeof e) return e;
 if ("string" == typeof e && !allowedModes.test(e)) throw new Error("Unrecognized mode: " + e);
 return parseInt(e, 8);
}

function maybeDecode(e, t) {
 const n = new Buffer(e.buffer, e.byteOffset, e.byteLength);
 return t && "binary" !== t ? n.toString(t) : n;
}

function readFile$1(e, t, n) {
 let r;
 e = e instanceof URL ? fromFileUrl(e) : e, r = "function" == typeof t ? t : n;
 const i = getEncoding$1(t), o = Deno.readFile(e);
 r && o.then((e => {
  if (i && "binary" !== i) {
   const t = maybeDecode(e, i);
   return r(null, t);
  }
  const t = maybeDecode(e, i);
  r(null, t);
 })).catch((e => r && r(e)));
}

function maybeEncode(e, t) {
 return "buffer" === t ? (new TextEncoder).encode(e) : e;
}

function getEncoding(e) {
 if (e && "function" != typeof e) {
  if (e.encoding) {
   if ("utf8" === e.encoding || "utf-8" === e.encoding) return "utf8";
   if ("buffer" === e.encoding) return "buffer";
   notImplemented();
  }
  return null;
 }
 return null;
}

function writeFile$1(e, t, n, r) {
 const i = n instanceof Function ? n : r, o = n instanceof Function ? void 0 : n;
 if (!i) throw new TypeError("Callback must be a function.");
 e = e instanceof URL ? fromFileUrl(e) : e;
 const s = isFileOptions(o) ? o.flag : void 0, a = isFileOptions(o) ? o.mode : void 0, l = checkEncoding(getEncoding$1(o)) || "utf8", c = getOpenOptions(s || "w");
 "string" == typeof t && (t = Buffer.from(t, l));
 const u = "number" == typeof e;
 let f, h = null;
 (async () => {
  try {
   f = u ? new Deno.File(e) : await Deno.open(e, c), !u && a && ("windows" === Deno.build.os && notImplemented('"mode" on Windows'), 
   await Deno.chmod(e, a)), await Deno.writeAll(f, t);
  } catch (e) {
   h = e;
  } finally {
   !u && f && f.close(), i(h);
  }
 })();
}

function arch() {
 return Deno.build.arch;
}

function endianness() {
 const e = new ArrayBuffer(2);
 return new DataView(e).setInt16(0, 256, !0), 256 === new Int16Array(e)[0] ? "LE" : "BE";
}

function freemem() {
 notImplemented(SEE_GITHUB_ISSUE);
}

function homedir() {
 notImplemented(SEE_GITHUB_ISSUE);
}

function hostname() {
 notImplemented(SEE_GITHUB_ISSUE);
}

function platform() {
 return process.platform;
}

function release() {
 return Deno.osRelease();
}

function totalmem() {
 notImplemented(SEE_GITHUB_ISSUE);
}

function type() {
 notImplemented(SEE_GITHUB_ISSUE);
}

function uptime() {
 notImplemented(SEE_GITHUB_ISSUE);
}

function parse(e, t = "&", n = "=", {decodeURIComponent: r = unescape, maxKeys: i = 1e3} = {}) {
 const o = e.split(t).map((e => e.split(n).map(r))), s = {};
 let a = 0;
 for (;(Object.keys(s).length !== i || !i) && o[a]; ) {
  const [e, t] = o[a];
  s[e] ? Array.isArray(s[e]) ? s[e].push(t) : s[e] = [ s[e], t ] : s[e] = t, a++;
 }
 return s;
}

function stringify(e, t = "&", n = "=", {encodeURIComponent: r = escape} = {}) {
 const i = [];
 for (const t of Object.entries(e)) if (Array.isArray(t[1])) for (const e of t[1]) i.push(r(t[0]) + n + r(e)); else "object" != typeof t[1] && void 0 !== t[1] ? i.push(t.map(r).join(n)) : i.push(r(t[0]) + n);
 return i.join(t);
}

function normalizeEncoding(e) {
 const t = normalizeEncoding$1(null != e ? e : null);
 if (t && t in NotImplemented && notImplemented(t), !t && "string" == typeof e && "raw" !== e.toLowerCase()) throw new Error(`Unknown encoding: ${e}`);
 return String(t);
}

function utf8CheckByte(e) {
 return e <= 127 ? 0 : e >> 5 == 6 ? 2 : e >> 4 == 14 ? 3 : e >> 3 == 30 ? 4 : e >> 6 == 2 ? -1 : -2;
}

function utf8FillLastComplete(e) {
 const t = this.lastTotal - this.lastNeed, n = function r(e, t) {
  if (128 != (192 & t[0])) return e.lastNeed = 0, "�";
  if (e.lastNeed > 1 && t.length > 1) {
   if (128 != (192 & t[1])) return e.lastNeed = 1, "�";
   if (e.lastNeed > 2 && t.length > 2 && 128 != (192 & t[2])) return e.lastNeed = 2, 
   "�";
  }
 }(this, e);
 return void 0 !== n ? n : this.lastNeed <= e.length ? (e.copy(this.lastChar, t, 0, this.lastNeed), 
 this.lastChar.toString(this.encoding, 0, this.lastTotal)) : (e.copy(this.lastChar, t, 0, e.length), 
 void (this.lastNeed -= e.length));
}

function utf8FillLastIncomplete(e) {
 if (this.lastNeed <= e.length) return e.copy(this.lastChar, this.lastTotal - this.lastNeed, 0, this.lastNeed), 
 this.lastChar.toString(this.encoding, 0, this.lastTotal);
 e.copy(this.lastChar, this.lastTotal - this.lastNeed, 0, e.length), this.lastNeed -= e.length;
}

function utf8Text(e, t) {
 const n = function r(e, t, n) {
  let r = t.length - 1;
  if (r < n) return 0;
  let i = utf8CheckByte(t[r]);
  return i >= 0 ? (i > 0 && (e.lastNeed = i - 1), i) : --r < n || -2 === i ? 0 : (i = utf8CheckByte(t[r]), 
  i >= 0 ? (i > 0 && (e.lastNeed = i - 2), i) : --r < n || -2 === i ? 0 : (i = utf8CheckByte(t[r]), 
  i >= 0 ? (i > 0 && (2 === i ? i = 0 : e.lastNeed = i - 3), i) : 0));
 }(this, e, t);
 if (!this.lastNeed) return e.toString("utf8", t);
 this.lastTotal = n;
 const i = e.length - (n - this.lastNeed);
 return e.copy(this.lastChar, 0, i), e.toString("utf8", t, i);
}

function utf8End(e) {
 const t = e && e.length ? this.write(e) : "";
 return this.lastNeed ? t + "�" : t;
}

function utf8Write(e) {
 if (0 === e.length) return "";
 let t, n;
 if (this.lastNeed) {
  if (t = this.fillLast(e), void 0 === t) return "";
  n = this.lastNeed, this.lastNeed = 0;
 } else n = 0;
 return n < e.length ? t ? t + this.text(e, n) : this.text(e, n) : t || "";
}

function base64Text(e, t) {
 const n = (e.length - t) % 3;
 return 0 === n ? e.toString("base64", t) : (this.lastNeed = 3 - n, this.lastTotal = 3, 
 1 === n ? this.lastChar[0] = e[e.length - 1] : (this.lastChar[0] = e[e.length - 2], 
 this.lastChar[1] = e[e.length - 1]), e.toString("base64", t, e.length - n));
}

function base64End(e) {
 const t = e && e.length ? this.write(e) : "";
 return this.lastNeed ? t + this.lastChar.toString("base64", 0, 3 - this.lastNeed) : t;
}

function simpleWrite(e) {
 return e.toString(this.encoding);
}

function simpleEnd(e) {
 return e && e.length ? this.write(e) : "";
}

function fileURLToPath(e) {
 if ("string" == typeof e) e = new URL(e); else if (!(e instanceof URL)) throw new Deno.errors.InvalidData("invalid argument path , must be a string or URL");
 if ("file:" !== e.protocol) throw new Deno.errors.InvalidData("invalid url scheme");
 return isWindows$1 ? function t(e) {
  const t = e.hostname;
  let n = e.pathname;
  for (let e = 0; e < n.length; e++) if ("%" === n[e]) {
   const t = n.codePointAt(e + 2) || 32;
   if ("2" === n[e + 1] && 102 === t || "5" === n[e + 1] && 99 === t) throw new Deno.errors.InvalidData("must not include encoded \\ or / characters");
  }
  if (n = n.replace(forwardSlashRegEx, "\\"), n = decodeURIComponent(n), "" !== t) return `\\\\${t}${n}`;
  {
   const e = 32 | n.codePointAt(1), t = n[2];
   if (e < 97 || e > 122 || ":" !== t) throw new Deno.errors.InvalidData("file url path must be absolute");
   return n.slice(1);
  }
 }(e) : function n(e) {
  if ("" !== e.hostname) throw new Deno.errors.InvalidData("invalid file url hostname");
  const t = e.pathname;
  for (let e = 0; e < t.length; e++) if ("%" === t[e]) {
   const n = t.codePointAt(e + 2) || 32;
   if ("2" === t[e + 1] && 102 === n) throw new Deno.errors.InvalidData("must not include encoded / characters");
  }
  return decodeURIComponent(t);
 }(e);
}

function pathToFileURL(e) {
 let t = resolve(e);
 const n = e.charCodeAt(e.length - 1);
 (47 === n || isWindows$1 && 92 === n) && t[t.length - 1] !== sep && (t += "/");
 const r = new URL("file://");
 return t.includes("%") && (t = t.replace(percentRegEx, "%25")), !isWindows$1 && t.includes("\\") && (t = t.replace(backslashRegEx, "%5C")), 
 t.includes("\n") && (t = t.replace(newlineRegEx, "%0A")), t.includes("\r") && (t = t.replace(carriageReturnRegEx, "%0D")), 
 t.includes("\t") && (t = t.replace(tabRegEx, "%09")), r.pathname = t, r;
}

function stat(e) {
 if (e = toNamespacedPath(e), null !== statCache) {
  const t = statCache.get(e);
  if (void 0 !== t) return t;
 }
 try {
  const t = Deno.statSync(e).isFile ? 0 : 1;
  return null !== statCache && statCache.set(e, t), t;
 } catch (e) {
  if (e instanceof Deno.errors.PermissionDenied) throw new Error("CJS loader requires --allow-read.");
  return -1;
 }
}

function updateChildren(e, t, n) {
 const r = e && e.children;
 !r || n && r.includes(t) || r.push(t);
}

function createNativeModule(e, t) {
 const n = new Module(e);
 return n.exports = t, n.loaded = !0, n;
}

function readPackage(e) {
 const t = resolve(e, "package.json"), n = packageJsonCache.get(t);
 if (void 0 !== n) return n;
 let r;
 try {
  r = (new TextDecoder).decode(Deno.readFileSync(toNamespacedPath(t)));
 } catch (e) {}
 if (void 0 === r) return packageJsonCache.set(t, null), null;
 try {
  const e = JSON.parse(r), n = {
   name: e.name,
   main: e.main,
   exports: e.exports,
   type: e.type
  };
  return packageJsonCache.set(t, n), n;
 } catch (e) {
  throw e.path = t, e.message = "Error parsing " + t + ": " + e.message, e;
 }
}

function tryPackage(e, t, n, r) {
 const i = function o(e) {
  const t = readPackage(e);
  return t ? t.main : void 0;
 }(e);
 if (!i) return tryExtensions(resolve(e, "index"), t);
 const s = resolve(e, i);
 let a = tryFile(s) || tryExtensions(s, t) || tryExtensions(resolve(s, "index"), t);
 if (!1 === a && (a = tryExtensions(resolve(e, "index"), t), !a)) {
  const e = new Error(`Cannot find module '${s}'. Please verify that the package.json has a valid "main" entry`);
  throw e.code = "MODULE_NOT_FOUND", e;
 }
 return a;
}

function tryFile(e, t) {
 return 0 === stat(e) && toRealPath(e);
}

function toRealPath(e) {
 let t = e;
 for (;;) try {
  t = Deno.readLinkSync(t);
 } catch (e) {
  break;
 }
 return resolve(e);
}

function tryExtensions(e, t, n) {
 for (let n = 0; n < t.length; n++) {
  const r = tryFile(e + t[n]);
  if (r) return r;
 }
 return !1;
}

function resolveExports(e, t, n) {
 if (!n) {
  const [, n, r = ""] = t.match(EXPORTS_PATTERN) || [];
  return n ? function r(e, t) {
   const n = `.${t}`;
   let r = function i(e) {
    const t = readPackage(e);
    return t ? t.exports : void 0;
   }(e);
   if (null == r) return resolve(e, n);
   if (function o(e, t) {
    if ("string" == typeof e) return !0;
    if (Array.isArray(e)) return !0;
    if ("object" != typeof e) return !1;
    let n = !1, r = !0;
    for (const t of Object.keys(e)) {
     const e = "." !== t[0];
     if (r) r = !1, n = e; else if (n !== e) throw new Error("\"exports\" cannot contain some keys starting with '.' and some not. The exports object must either be an object of package subpath keys or an object of main entry condition name keys only.");
    }
    return n;
   }(r) && (r = {
    ".": r
   }), "object" == typeof r) {
    if (Object.prototype.hasOwnProperty.call(r, n)) {
     const t = r[n];
     return resolveExportsTarget(pathToFileURL(e + "/"), t, "", e, n);
    }
    if ("." === n) return e;
    let t = "";
    for (const e of Object.keys(r)) "/" === e[e.length - 1] && e.length > t.length && n.startsWith(e) && (t = e);
    if ("" !== t) {
     const i = r[t], o = n.slice(t.length);
     return resolveExportsTarget(pathToFileURL(e + "/"), i, o, e, n);
    }
   }
   if ("." === n) return e;
   const s = new Error(`Package exports for '${e}' do not define a '${n}' subpath`);
   throw s.code = "MODULE_NOT_FOUND", s;
  }(resolve(e, n), r) : resolve(e, t);
 }
 return resolve(e, t);
}

function resolveExportsTarget(e, t, n, r, i) {
 if ("string" == typeof t) {
  if (t.startsWith("./") && (0 === n.length || t.endsWith("/"))) {
   const r = new URL(t, e), i = e.pathname, o = r.pathname;
   if (o.startsWith(i) && -1 === o.indexOf("/node_modules/", i.length - 1)) {
    const e = new URL(n, r), t = e.pathname;
    if (t.startsWith(o) && -1 === t.indexOf("/node_modules/", i.length - 1)) return fileURLToPath(e);
   }
  }
 } else if (Array.isArray(t)) {
  for (const s of t) if (!Array.isArray(s)) try {
   return resolveExportsTarget(e, s, n, r, i);
  } catch (o) {
   if ("MODULE_NOT_FOUND" !== o.code) throw o;
  }
 } else if ("object" == typeof t && null !== t && Object.prototype.hasOwnProperty.call(t, "default")) try {
  return resolveExportsTarget(e, t.default, n, r, i);
 } catch (o) {
  if ("MODULE_NOT_FOUND" !== o.code) throw o;
 }
 let o;
 throw o = "." !== i ? new Error(`Package exports for '${r}' do not define a valid '${i}' target${n ? " for " + n : ""}`) : new Error(`No valid exports main found for '${r}'`), 
 o.code = "MODULE_NOT_FOUND", o;
}

function emitCircularRequireWarning(e) {
 console.error(`Accessing non-existent property '${String(e)}' of module exports inside circular dependency`);
}

function getExportsForCircularRequire(e) {
 return e.exports && Object.getPrototypeOf(e.exports) === PublicObjectPrototype && !e.exports.__esModule && Object.setPrototypeOf(e.exports, CircularRequirePrototypeWarningProxy), 
 e.exports;
}

function makeRequireFunction(e) {
 function t(t, n) {
  return Module._resolveFilename(t, e, !1, n);
 }
 const n = function t(n) {
  return e.require(n);
 };
 return n.resolve = t, t.paths = function r(t) {
  return Module._resolveLookupPaths(t, e);
 }, n.extensions = Module._extensions, n.cache = Module._cache, n;
}

var EOL$1, NotImplemented;

const navigator = globalThis.navigator;

let isWindows$2 = !1;

null != globalThis.Deno ? isWindows$2 = "windows" == Deno.build.os : null != (null == navigator ? void 0 : navigator.appVersion) && (isWindows$2 = navigator.appVersion.includes("Win"));

class DenoStdInternalError extends Error {
 constructor(e) {
  super(e), this.name = "DenoStdInternalError";
 }
}

const _win32 = {
 __proto__: null,
 sep: "\\",
 delimiter: ";",
 resolve: resolve$2,
 normalize: normalize$2,
 isAbsolute: function isAbsolute$2(e) {
  assertPath(e);
  const t = e.length;
  if (0 === t) return !1;
  const n = e.charCodeAt(0);
  return !!isPathSeparator(n) || !!(isWindowsDeviceRoot(n) && t > 2 && 58 === e.charCodeAt(1) && isPathSeparator(e.charCodeAt(2)));
 },
 join: function join$2(...e) {
  const t = e.length;
  if (0 === t) return ".";
  let n, r = null;
  for (let i = 0; i < t; ++i) {
   const t = e[i];
   assertPath(t), t.length > 0 && (void 0 === n ? n = r = t : n += `\\${t}`);
  }
  if (void 0 === n) return ".";
  let i = !0, o = 0;
  if (assert(null != r), isPathSeparator(r.charCodeAt(0))) {
   ++o;
   const e = r.length;
   e > 1 && isPathSeparator(r.charCodeAt(1)) && (++o, e > 2 && (isPathSeparator(r.charCodeAt(2)) ? ++o : i = !1));
  }
  if (i) {
   for (;o < n.length && isPathSeparator(n.charCodeAt(o)); ++o) ;
   o >= 2 && (n = `\\${n.slice(o)}`);
  }
  return normalize$2(n);
 },
 relative: function relative$2(e, t) {
  if (assertPath(e), assertPath(t), e === t) return "";
  const n = resolve$2(e), r = resolve$2(t);
  if (n === r) return "";
  if ((e = n.toLowerCase()) === (t = r.toLowerCase())) return "";
  let i = 0, o = e.length;
  for (;i < o && 92 === e.charCodeAt(i); ++i) ;
  for (;o - 1 > i && 92 === e.charCodeAt(o - 1); --o) ;
  const s = o - i;
  let a = 0, l = t.length;
  for (;a < l && 92 === t.charCodeAt(a); ++a) ;
  for (;l - 1 > a && 92 === t.charCodeAt(l - 1); --l) ;
  const c = l - a, u = s < c ? s : c;
  let f = -1, h = 0;
  for (;h <= u; ++h) {
   if (h === u) {
    if (c > u) {
     if (92 === t.charCodeAt(a + h)) return r.slice(a + h + 1);
     if (2 === h) return r.slice(a + h);
    }
    s > u && (92 === e.charCodeAt(i + h) ? f = h : 2 === h && (f = 3));
    break;
   }
   const n = e.charCodeAt(i + h);
   if (n !== t.charCodeAt(a + h)) break;
   92 === n && (f = h);
  }
  if (h !== u && -1 === f) return r;
  let d = "";
  for (-1 === f && (f = 0), h = i + f + 1; h <= o; ++h) h !== o && 92 !== e.charCodeAt(h) || (0 === d.length ? d += ".." : d += "\\..");
  return d.length > 0 ? d + r.slice(a + f, l) : (a += f, 92 === r.charCodeAt(a) && ++a, 
  r.slice(a, l));
 },
 toNamespacedPath: function toNamespacedPath$2(e) {
  if ("string" != typeof e) return e;
  if (0 === e.length) return "";
  const t = resolve$2(e);
  if (t.length >= 3) if (92 === t.charCodeAt(0)) {
   if (92 === t.charCodeAt(1)) {
    const e = t.charCodeAt(2);
    if (63 !== e && 46 !== e) return `\\\\?\\UNC\\${t.slice(2)}`;
   }
  } else if (isWindowsDeviceRoot(t.charCodeAt(0)) && 58 === t.charCodeAt(1) && 92 === t.charCodeAt(2)) return `\\\\?\\${t}`;
  return e;
 },
 dirname: function dirname$2(e) {
  assertPath(e);
  const t = e.length;
  if (0 === t) return ".";
  let n = -1, r = -1, i = !0, o = 0;
  const s = e.charCodeAt(0);
  if (t > 1) if (isPathSeparator(s)) {
   if (n = o = 1, isPathSeparator(e.charCodeAt(1))) {
    let r = 2, i = r;
    for (;r < t && !isPathSeparator(e.charCodeAt(r)); ++r) ;
    if (r < t && r !== i) {
     for (i = r; r < t && isPathSeparator(e.charCodeAt(r)); ++r) ;
     if (r < t && r !== i) {
      for (i = r; r < t && !isPathSeparator(e.charCodeAt(r)); ++r) ;
      if (r === t) return e;
      r !== i && (n = o = r + 1);
     }
    }
   }
  } else isWindowsDeviceRoot(s) && 58 === e.charCodeAt(1) && (n = o = 2, t > 2 && isPathSeparator(e.charCodeAt(2)) && (n = o = 3)); else if (isPathSeparator(s)) return e;
  for (let n = t - 1; n >= o; --n) if (isPathSeparator(e.charCodeAt(n))) {
   if (!i) {
    r = n;
    break;
   }
  } else i = !1;
  if (-1 === r) {
   if (-1 === n) return ".";
   r = n;
  }
  return e.slice(0, r);
 },
 basename: function basename$2(e, t = "") {
  if (void 0 !== t && "string" != typeof t) throw new TypeError('"ext" argument must be a string');
  assertPath(e);
  let n, r = 0, i = -1, o = !0;
  if (e.length >= 2 && isWindowsDeviceRoot(e.charCodeAt(0)) && 58 === e.charCodeAt(1) && (r = 2), 
  void 0 !== t && t.length > 0 && t.length <= e.length) {
   if (t.length === e.length && t === e) return "";
   let s = t.length - 1, a = -1;
   for (n = e.length - 1; n >= r; --n) {
    const l = e.charCodeAt(n);
    if (isPathSeparator(l)) {
     if (!o) {
      r = n + 1;
      break;
     }
    } else -1 === a && (o = !1, a = n + 1), s >= 0 && (l === t.charCodeAt(s) ? -1 == --s && (i = n) : (s = -1, 
    i = a));
   }
   return r === i ? i = a : -1 === i && (i = e.length), e.slice(r, i);
  }
  for (n = e.length - 1; n >= r; --n) if (isPathSeparator(e.charCodeAt(n))) {
   if (!o) {
    r = n + 1;
    break;
   }
  } else -1 === i && (o = !1, i = n + 1);
  return -1 === i ? "" : e.slice(r, i);
 },
 extname: function extname$2(e) {
  assertPath(e);
  let t = 0, n = -1, r = 0, i = -1, o = !0, s = 0;
  e.length >= 2 && 58 === e.charCodeAt(1) && isWindowsDeviceRoot(e.charCodeAt(0)) && (t = r = 2);
  for (let a = e.length - 1; a >= t; --a) {
   const t = e.charCodeAt(a);
   if (isPathSeparator(t)) {
    if (!o) {
     r = a + 1;
     break;
    }
   } else -1 === i && (o = !1, i = a + 1), 46 === t ? -1 === n ? n = a : 1 !== s && (s = 1) : -1 !== n && (s = -1);
  }
  return -1 === n || -1 === i || 0 === s || 1 === s && n === i - 1 && n === r + 1 ? "" : e.slice(n, i);
 },
 format: function format$2(e) {
  if (null === e || "object" != typeof e) throw new TypeError('The "pathObject" argument must be of type Object. Received type ' + typeof e);
  return _format("\\", e);
 },
 parse: function parse$3(e) {
  assertPath(e);
  const t = {
   root: "",
   dir: "",
   base: "",
   ext: "",
   name: ""
  }, n = e.length;
  if (0 === n) return t;
  let r = 0, i = e.charCodeAt(0);
  if (n > 1) {
   if (isPathSeparator(i)) {
    if (r = 1, isPathSeparator(e.charCodeAt(1))) {
     let t = 2, i = t;
     for (;t < n && !isPathSeparator(e.charCodeAt(t)); ++t) ;
     if (t < n && t !== i) {
      for (i = t; t < n && isPathSeparator(e.charCodeAt(t)); ++t) ;
      if (t < n && t !== i) {
       for (i = t; t < n && !isPathSeparator(e.charCodeAt(t)); ++t) ;
       t === n ? r = t : t !== i && (r = t + 1);
      }
     }
    }
   } else if (isWindowsDeviceRoot(i) && 58 === e.charCodeAt(1)) {
    if (r = 2, !(n > 2)) return t.root = t.dir = e, t;
    if (isPathSeparator(e.charCodeAt(2))) {
     if (3 === n) return t.root = t.dir = e, t;
     r = 3;
    }
   }
  } else if (isPathSeparator(i)) return t.root = t.dir = e, t;
  r > 0 && (t.root = e.slice(0, r));
  let o = -1, s = r, a = -1, l = !0, c = e.length - 1, u = 0;
  for (;c >= r; --c) if (i = e.charCodeAt(c), isPathSeparator(i)) {
   if (!l) {
    s = c + 1;
    break;
   }
  } else -1 === a && (l = !1, a = c + 1), 46 === i ? -1 === o ? o = c : 1 !== u && (u = 1) : -1 !== o && (u = -1);
  return -1 === o || -1 === a || 0 === u || 1 === u && o === a - 1 && o === s + 1 ? -1 !== a && (t.base = t.name = e.slice(s, a)) : (t.name = e.slice(s, o), 
  t.base = e.slice(s, a), t.ext = e.slice(o, a)), t.dir = s > 0 && s !== r ? e.slice(0, s - 1) : t.root, 
  t;
 },
 fromFileUrl: function fromFileUrl$2(e) {
  if ("file:" != (e = e instanceof URL ? e : new URL(e)).protocol) throw new TypeError("Must be a file URL.");
  let t = decodeURIComponent(e.pathname.replace(/^\/*([A-Za-z]:)(\/|$)/, "$1/").replace(/\//g, "\\"));
  return "" != e.hostname && (t = `\\\\${e.hostname}${t}`), t;
 }
}, _posix = {
 __proto__: null,
 sep: "/",
 delimiter: ":",
 resolve: resolve$1,
 normalize: normalize$1,
 isAbsolute: function isAbsolute$1(e) {
  return assertPath(e), e.length > 0 && 47 === e.charCodeAt(0);
 },
 join: function join$1(...e) {
  if (0 === e.length) return ".";
  let t;
  for (let n = 0, r = e.length; n < r; ++n) {
   const r = e[n];
   assertPath(r), r.length > 0 && (t ? t += `/${r}` : t = r);
  }
  return t ? normalize$1(t) : ".";
 },
 relative: function relative$1(e, t) {
  if (assertPath(e), assertPath(t), e === t) return "";
  if ((e = resolve$1(e)) === (t = resolve$1(t))) return "";
  let n = 1;
  const r = e.length;
  for (;n < r && 47 === e.charCodeAt(n); ++n) ;
  const i = r - n;
  let o = 1;
  const s = t.length;
  for (;o < s && 47 === t.charCodeAt(o); ++o) ;
  const a = s - o, l = i < a ? i : a;
  let c = -1, u = 0;
  for (;u <= l; ++u) {
   if (u === l) {
    if (a > l) {
     if (47 === t.charCodeAt(o + u)) return t.slice(o + u + 1);
     if (0 === u) return t.slice(o + u);
    } else i > l && (47 === e.charCodeAt(n + u) ? c = u : 0 === u && (c = 0));
    break;
   }
   const r = e.charCodeAt(n + u);
   if (r !== t.charCodeAt(o + u)) break;
   47 === r && (c = u);
  }
  let f = "";
  for (u = n + c + 1; u <= r; ++u) u !== r && 47 !== e.charCodeAt(u) || (0 === f.length ? f += ".." : f += "/..");
  return f.length > 0 ? f + t.slice(o + c) : (o += c, 47 === t.charCodeAt(o) && ++o, 
  t.slice(o));
 },
 toNamespacedPath: function toNamespacedPath$1(e) {
  return e;
 },
 dirname: function dirname$1(e) {
  if (assertPath(e), 0 === e.length) return ".";
  const t = 47 === e.charCodeAt(0);
  let n = -1, r = !0;
  for (let t = e.length - 1; t >= 1; --t) if (47 === e.charCodeAt(t)) {
   if (!r) {
    n = t;
    break;
   }
  } else r = !1;
  return -1 === n ? t ? "/" : "." : t && 1 === n ? "//" : e.slice(0, n);
 },
 basename: function basename$1(e, t = "") {
  if (void 0 !== t && "string" != typeof t) throw new TypeError('"ext" argument must be a string');
  assertPath(e);
  let n, r = 0, i = -1, o = !0;
  if (void 0 !== t && t.length > 0 && t.length <= e.length) {
   if (t.length === e.length && t === e) return "";
   let s = t.length - 1, a = -1;
   for (n = e.length - 1; n >= 0; --n) {
    const l = e.charCodeAt(n);
    if (47 === l) {
     if (!o) {
      r = n + 1;
      break;
     }
    } else -1 === a && (o = !1, a = n + 1), s >= 0 && (l === t.charCodeAt(s) ? -1 == --s && (i = n) : (s = -1, 
    i = a));
   }
   return r === i ? i = a : -1 === i && (i = e.length), e.slice(r, i);
  }
  for (n = e.length - 1; n >= 0; --n) if (47 === e.charCodeAt(n)) {
   if (!o) {
    r = n + 1;
    break;
   }
  } else -1 === i && (o = !1, i = n + 1);
  return -1 === i ? "" : e.slice(r, i);
 },
 extname: function extname$1(e) {
  assertPath(e);
  let t = -1, n = 0, r = -1, i = !0, o = 0;
  for (let s = e.length - 1; s >= 0; --s) {
   const a = e.charCodeAt(s);
   if (47 !== a) -1 === r && (i = !1, r = s + 1), 46 === a ? -1 === t ? t = s : 1 !== o && (o = 1) : -1 !== t && (o = -1); else if (!i) {
    n = s + 1;
    break;
   }
  }
  return -1 === t || -1 === r || 0 === o || 1 === o && t === r - 1 && t === n + 1 ? "" : e.slice(t, r);
 },
 format: function format$1(e) {
  if (null === e || "object" != typeof e) throw new TypeError('The "pathObject" argument must be of type Object. Received type ' + typeof e);
  return _format("/", e);
 },
 parse: function parse$2(e) {
  assertPath(e);
  const t = {
   root: "",
   dir: "",
   base: "",
   ext: "",
   name: ""
  };
  if (0 === e.length) return t;
  const n = 47 === e.charCodeAt(0);
  let r;
  n ? (t.root = "/", r = 1) : r = 0;
  let i = -1, o = 0, s = -1, a = !0, l = e.length - 1, c = 0;
  for (;l >= r; --l) {
   const t = e.charCodeAt(l);
   if (47 !== t) -1 === s && (a = !1, s = l + 1), 46 === t ? -1 === i ? i = l : 1 !== c && (c = 1) : -1 !== i && (c = -1); else if (!a) {
    o = l + 1;
    break;
   }
  }
  return -1 === i || -1 === s || 0 === c || 1 === c && i === s - 1 && i === o + 1 ? -1 !== s && (t.base = t.name = 0 === o && n ? e.slice(1, s) : e.slice(o, s)) : (0 === o && n ? (t.name = e.slice(1, i), 
  t.base = e.slice(1, s)) : (t.name = e.slice(o, i), t.base = e.slice(o, s)), t.ext = e.slice(i, s)), 
  o > 0 ? t.dir = e.slice(0, o - 1) : n && (t.dir = "/"), t;
 },
 fromFileUrl: function fromFileUrl$1(e) {
  if ("file:" != (e = e instanceof URL ? e : new URL(e)).protocol) throw new TypeError("Must be a file URL.");
  return decodeURIComponent(e.pathname);
 }
}, SEP$1 = isWindows$2 ? "\\" : "/", SEP_PATTERN = isWindows$2 ? /[\\/]+/ : /\/+/, SEP = isWindows$2 ? "(?:\\\\|\\/)" : "\\/", SEP_ESC = isWindows$2 ? "\\\\" : "/", SEP_RAW = isWindows$2 ? "\\" : "/", GLOBSTAR = `(?:(?:[^${SEP_ESC}/]*(?:${SEP_ESC}|/|$))*)`, WILDCARD = `(?:[^${SEP_ESC}/]*)`, GLOBSTAR_SEGMENT = `((?:[^${SEP_ESC}/]*(?:${SEP_ESC}|/|$))*)`, WILDCARD_SEGMENT = `(?:[^${SEP_ESC}/]*)`, path = isWindows$2 ? _win32 : _posix, win32 = _win32, posix = _posix, {basename, delimiter, dirname, extname, format, fromFileUrl, isAbsolute, join, normalize, parse: parse$1, relative, resolve, sep, toNamespacedPath} = path;

var EOL;

(EOL = EOL$1 || (EOL$1 = {})).LF = "\n", EOL.CRLF = "\r\n";

const hextable = (new TextEncoder).encode("0123456789abcdef"), _TextDecoder = TextDecoder, _TextEncoder = TextEncoder, notImplementedEncodings = [ "ascii", "binary", "latin1", "ucs2", "utf16le" ], encodingOps = {
 utf8: {
  byteLength: e => (new TextEncoder).encode(e).byteLength
 },
 ucs2: {
  byteLength: e => 2 * e.length
 },
 utf16le: {
  byteLength: e => 2 * e.length
 },
 latin1: {
  byteLength: e => e.length
 },
 ascii: {
  byteLength: e => e.length
 },
 base64: {
  byteLength: e => function t(e, n) {
   return 61 === e.charCodeAt(n - 1) && n--, n > 1 && 61 === e.charCodeAt(n - 1) && n--, 
   3 * n >>> 2;
  }(e, e.length)
 },
 hex: {
  byteLength: e => e.length >>> 1
 }
};

class Buffer extends Uint8Array {
 static alloc(e, t, n = "utf8") {
  if ("number" != typeof e) throw new TypeError('The "size" argument must be of type number. Received type ' + typeof e);
  const r = new Buffer(e);
  if (0 === e) return r;
  let i;
  if ("string" == typeof t) n = checkEncoding$1(n), "string" == typeof t && 1 === t.length && "utf8" === n ? r.fill(t.charCodeAt(0)) : i = Buffer.from(t, n); else if ("number" == typeof t) r.fill(t); else if (t instanceof Uint8Array) {
   if (0 === t.length) throw new TypeError(`The argument "value" is invalid. Received ${t.constructor.name} []`);
   i = t;
  }
  if (i) {
   i.length > r.length && (i = i.subarray(0, r.length));
   let t = 0;
   for (;t < e && (r.set(i, t), t += i.length, !(t + i.length >= e)); ) ;
   t !== e && r.set(i.subarray(0, e - t), t);
  }
  return r;
 }
 static allocUnsafe(e) {
  return new Buffer(e);
 }
 static byteLength(e, t = "utf8") {
  return "string" != typeof e ? e.byteLength : (t = normalizeEncoding$1(t) || "utf8", 
  encodingOps[t].byteLength(e));
 }
 static concat(e, t) {
  if (null == t) {
   t = 0;
   for (const n of e) t += n.length;
  }
  const n = new Buffer(t);
  let r = 0;
  for (const t of e) n.set(t, r), r += t.length;
  return n;
 }
 static from(e, t, n) {
  const r = "string" == typeof t ? void 0 : t;
  let i = "string" == typeof t ? t : void 0;
  return "string" == typeof e ? (i = checkEncoding$1(i, !1), new Buffer("hex" === i ? function o(e) {
   return function t(e) {
    const t = new Uint8Array(function n(e) {
     return e >>> 1;
    }(e.length));
    for (let n = 0; n < t.length; n++) {
     const r = fromHexChar(e[2 * n]), i = fromHexChar(e[2 * n + 1]);
     t[n] = r << 4 | i;
    }
    if (e.length % 2 == 1) throw fromHexChar(e[2 * t.length]), function r() {
     return new Error("encoding/hex: odd length hex string");
    }();
    return t;
   }((new TextEncoder).encode(e));
  }(e).buffer : "base64" === i ? function s(e) {
   const t = function n(e) {
    return atob(e);
   }(e), r = new Uint8Array(t.length);
   for (let e = 0; e < r.length; ++e) r[e] = t.charCodeAt(e);
   return r.buffer;
  }(e) : (new TextEncoder).encode(e).buffer)) : new Buffer(e, r, n);
 }
 static isBuffer(e) {
  return e instanceof Buffer;
 }
 static isEncoding(e) {
  return "string" == typeof e && 0 !== e.length && void 0 !== normalizeEncoding$1(e);
 }
 copy(e, t = 0, n = 0, r = this.length) {
  const i = this.subarray(n, r);
  return e.set(i, t), i.length;
 }
 equals(e) {
  if (!(e instanceof Uint8Array)) throw new TypeError('The "otherBuffer" argument must be an instance of Buffer or Uint8Array. Received type ' + typeof e);
  if (this === e) return !0;
  if (this.byteLength !== e.byteLength) return !1;
  for (let t = 0; t < this.length; t++) if (this[t] !== e[t]) return !1;
  return !0;
 }
 readBigInt64BE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getBigInt64(e);
 }
 readBigInt64LE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getBigInt64(e, !0);
 }
 readBigUInt64BE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getBigUint64(e);
 }
 readBigUInt64LE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getBigUint64(e, !0);
 }
 readDoubleBE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getFloat64(e);
 }
 readDoubleLE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getFloat64(e, !0);
 }
 readFloatBE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getFloat32(e);
 }
 readFloatLE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getFloat32(e, !0);
 }
 readInt8(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getInt8(e);
 }
 readInt16BE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getInt16(e);
 }
 readInt16LE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getInt16(e, !0);
 }
 readInt32BE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getInt32(e);
 }
 readInt32LE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getInt32(e, !0);
 }
 readUInt8(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getUint8(e);
 }
 readUInt16BE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getUint16(e);
 }
 readUInt16LE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getUint16(e, !0);
 }
 readUInt32BE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getUint32(e);
 }
 readUInt32LE(e = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).getUint32(e, !0);
 }
 slice(e = 0, t = this.length) {
  return this.subarray(e, t);
 }
 toJSON() {
  return {
   type: "Buffer",
   data: Array.from(this)
  };
 }
 toString(e = "utf8", t = 0, n = this.length) {
  e = checkEncoding$1(e);
  const r = this.subarray(t, n);
  return "hex" === e ? function i(e) {
   return (new TextDecoder).decode(function t(e) {
    const t = new Uint8Array(function n(e) {
     return 2 * e;
    }(e.length));
    for (let n = 0; n < t.length; n++) {
     const r = e[n];
     t[2 * n] = hextable[r >> 4], t[2 * n + 1] = hextable[15 & r];
    }
    return t;
   }(e));
  }(r) : "base64" === e ? function o(e) {
   if ("string" == typeof e) return btoa(e);
   {
    const t = new Uint8Array(e);
    let n = "";
    for (let e = 0; e < t.length; ++e) n += String.fromCharCode(t[e]);
    return btoa(n);
   }
  }(r.buffer) : new TextDecoder(e).decode(r);
 }
 write(e, t = 0, n = this.length) {
  return (new TextEncoder).encodeInto(e, this.subarray(t, t + n)).written;
 }
 writeBigInt64BE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setBigInt64(t, e), 
  t + 4;
 }
 writeBigInt64LE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setBigInt64(t, e, !0), 
  t + 4;
 }
 writeBigUInt64BE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setBigUint64(t, e), 
  t + 4;
 }
 writeBigUInt64LE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setBigUint64(t, e, !0), 
  t + 4;
 }
 writeDoubleBE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setFloat64(t, e), 
  t + 8;
 }
 writeDoubleLE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setFloat64(t, e, !0), 
  t + 8;
 }
 writeFloatBE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setFloat32(t, e), 
  t + 4;
 }
 writeFloatLE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setFloat32(t, e, !0), 
  t + 4;
 }
 writeInt8(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setInt8(t, e), 
  t + 1;
 }
 writeInt16BE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setInt16(t, e), 
  t + 2;
 }
 writeInt16LE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setInt16(t, e, !0), 
  t + 2;
 }
 writeInt32BE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setUint32(t, e), 
  t + 4;
 }
 writeInt32LE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setInt32(t, e, !0), 
  t + 4;
 }
 writeUInt8(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setUint8(t, e), 
  t + 1;
 }
 writeUInt16BE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setUint16(t, e), 
  t + 2;
 }
 writeUInt16LE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setUint16(t, e, !0), 
  t + 2;
 }
 writeUInt32BE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setUint32(t, e), 
  t + 4;
 }
 writeUInt32LE(e, t = 0) {
  return new DataView(this.buffer, this.byteOffset, this.byteLength).setUint32(t, e, !0), 
  t + 4;
 }
}

Object.defineProperty(globalThis, "Buffer", {
 value: Buffer,
 enumerable: !1,
 writable: !0,
 configurable: !0
});

const nodeBuffer = {
 __proto__: null,
 default: Buffer,
 Buffer
}, kCustomPromisifiedSymbol = Symbol.for("nodejs.util.promisify.custom"), kCustomPromisifyArgsSymbol = Symbol.for("nodejs.util.promisify.customArgs");

class NodeInvalidArgTypeError$1 extends TypeError {
 constructor(e, t, n) {
  super(`The "${e}" argument must be of type ${t}. Received ${typeof n}`), this.code = "ERR_INVALID_ARG_TYPE";
 }
}

promisify.custom = kCustomPromisifiedSymbol;

class NodeFalsyValueRejectionError extends Error {
 constructor(e) {
  super("Promise was rejected with falsy value"), this.code = "ERR_FALSY_VALUE_REJECTION", 
  this.reason = e;
 }
}

class NodeInvalidArgTypeError extends TypeError {
 constructor(e) {
  super(`The ${e} argument must be of type function.`), this.code = "ERR_INVALID_ARG_TYPE";
 }
}

const _toString = Object.prototype.toString, _isObjectLike = e => null !== e && "object" == typeof e, _isFunctionLike = e => null !== e && "function" == typeof e, nodeUtil = {
 __proto__: null,
 types: {
  __proto__: null,
  isAnyArrayBuffer: function isAnyArrayBuffer(e) {
   return _isObjectLike(e) && ("[object ArrayBuffer]" === _toString.call(e) || "[object SharedArrayBuffer]" === _toString.call(e));
  },
  isArrayBufferView: function isArrayBufferView(e) {
   return ArrayBuffer.isView(e);
  },
  isArgumentsObject: function isArgumentsObject(e) {
   return _isObjectLike(e) && "[object Arguments]" === _toString.call(e);
  },
  isArrayBuffer: function isArrayBuffer(e) {
   return _isObjectLike(e) && "[object ArrayBuffer]" === _toString.call(e);
  },
  isAsyncFunction: function isAsyncFunction(e) {
   return _isFunctionLike(e) && "[object AsyncFunction]" === _toString.call(e);
  },
  isBigInt64Array: function isBigInt64Array(e) {
   return _isObjectLike(e) && "[object BigInt64Array]" === _toString.call(e);
  },
  isBigUint64Array: function isBigUint64Array(e) {
   return _isObjectLike(e) && "[object BigUint64Array]" === _toString.call(e);
  },
  isBooleanObject,
  isBoxedPrimitive: function isBoxedPrimitive(e) {
   return isBooleanObject(e) || isStringObject(e) || isNumberObject(e) || isSymbolObject(e) || isBigIntObject(e);
  },
  isDataView: function isDataView(e) {
   return _isObjectLike(e) && "[object DataView]" === _toString.call(e);
  },
  isDate: function isDate(e) {
   return _isObjectLike(e) && "[object Date]" === _toString.call(e);
  },
  isFloat32Array: function isFloat32Array(e) {
   return _isObjectLike(e) && "[object Float32Array]" === _toString.call(e);
  },
  isFloat64Array: function isFloat64Array(e) {
   return _isObjectLike(e) && "[object Float64Array]" === _toString.call(e);
  },
  isGeneratorFunction: function isGeneratorFunction(e) {
   return _isFunctionLike(e) && "[object GeneratorFunction]" === _toString.call(e);
  },
  isGeneratorObject: function isGeneratorObject(e) {
   return _isObjectLike(e) && "[object Generator]" === _toString.call(e);
  },
  isInt8Array: function isInt8Array(e) {
   return _isObjectLike(e) && "[object Int8Array]" === _toString.call(e);
  },
  isInt16Array: function isInt16Array(e) {
   return _isObjectLike(e) && "[object Int16Array]" === _toString.call(e);
  },
  isInt32Array: function isInt32Array(e) {
   return _isObjectLike(e) && "[object Int32Array]" === _toString.call(e);
  },
  isMap: function isMap(e) {
   return _isObjectLike(e) && "[object Map]" === _toString.call(e);
  },
  isMapIterator: function isMapIterator(e) {
   return _isObjectLike(e) && "[object Map Iterator]" === _toString.call(e);
  },
  isModuleNamespaceObject: function isModuleNamespaceObject(e) {
   return _isObjectLike(e) && "[object Module]" === _toString.call(e);
  },
  isNativeError: function isNativeError(e) {
   return _isObjectLike(e) && "[object Error]" === _toString.call(e);
  },
  isNumberObject,
  isBigIntObject,
  isPromise: function isPromise(e) {
   return _isObjectLike(e) && "[object Promise]" === _toString.call(e);
  },
  isRegExp: function isRegExp$1(e) {
   return _isObjectLike(e) && "[object RegExp]" === _toString.call(e);
  },
  isSet: function isSet(e) {
   return _isObjectLike(e) && "[object Set]" === _toString.call(e);
  },
  isSetIterator: function isSetIterator(e) {
   return _isObjectLike(e) && "[object Set Iterator]" === _toString.call(e);
  },
  isSharedArrayBuffer: function isSharedArrayBuffer(e) {
   return _isObjectLike(e) && "[object SharedArrayBuffer]" === _toString.call(e);
  },
  isStringObject,
  isSymbolObject,
  isTypedArray: function isTypedArray(e) {
   return _isObjectLike(e) && /^\[object (?:Float(?:32|64)|(?:Int|Uint)(?:8|16|32)|Uint8Clamped)Array\]$/.test(_toString.call(e));
  },
  isUint8Array: function isUint8Array(e) {
   return _isObjectLike(e) && "[object Uint8Array]" === _toString.call(e);
  },
  isUint8ClampedArray: function isUint8ClampedArray(e) {
   return _isObjectLike(e) && "[object Uint8ClampedArray]" === _toString.call(e);
  },
  isUint16Array: function isUint16Array(e) {
   return _isObjectLike(e) && "[object Uint16Array]" === _toString.call(e);
  },
  isUint32Array: function isUint32Array(e) {
   return _isObjectLike(e) && "[object Uint32Array]" === _toString.call(e);
  },
  isWeakMap: function isWeakMap(e) {
   return _isObjectLike(e) && "[object WeakMap]" === _toString.call(e);
  },
  isWeakSet: function isWeakSet(e) {
   return _isObjectLike(e) && "[object WeakSet]" === _toString.call(e);
  }
 },
 isArray: function isArray(e) {
  return Array.isArray(e);
 },
 isBoolean: function isBoolean(e) {
  return "boolean" == typeof e || e instanceof Boolean;
 },
 isNull: function isNull(e) {
  return null === e;
 },
 isNullOrUndefined: function isNullOrUndefined(e) {
  return null == e;
 },
 isNumber: function isNumber(e) {
  return "number" == typeof e || e instanceof Number;
 },
 isString: function isString(e) {
  return "string" == typeof e || e instanceof String;
 },
 isSymbol: function isSymbol(e) {
  return "symbol" == typeof e;
 },
 isUndefined: function isUndefined(e) {
  return void 0 === e;
 },
 isObject: function isObject(e) {
  return null !== e && "object" == typeof e;
 },
 isError: function isError(e) {
  return e instanceof Error;
 },
 isFunction: function isFunction(e) {
  return "function" == typeof e;
 },
 isRegExp: function isRegExp(e) {
  return e instanceof RegExp;
 },
 isPrimitive: function isPrimitive(e) {
  return null === e || "object" != typeof e && "function" != typeof e;
 },
 validateIntegerRange,
 TextDecoder: _TextDecoder,
 TextEncoder: _TextEncoder,
 promisify,
 callbackify: function callbackify(e) {
  if ("function" != typeof e) throw new NodeInvalidArgTypeError('"original"');
  const t = function(...t) {
   const n = t.pop();
   if ("function" != typeof n) throw new NodeInvalidArgTypeError("last");
   const r = (...e) => {
    n.apply(this, e);
   };
   e.apply(this, t).then((e => {
    queueMicrotask(r.bind(this, null, e));
   }), (e => {
    e = e || new NodeFalsyValueRejectionError(e), queueMicrotask(r.bind(this, e));
   }));
  }, n = Object.getOwnPropertyDescriptors(e);
  return "number" == typeof n.length.value && n.length.value++, "string" == typeof n.name.value && (n.name.value += "Callbackified"), 
  Object.defineProperties(t, n), t;
 }
};

class EventEmitter {
 constructor() {
  this._events = new Map;
 }
 _addListener(e, t, n) {
  if (this.emit("newListener", e, t), this._events.has(e)) {
   const r = this._events.get(e);
   n ? r.unshift(t) : r.push(t);
  } else this._events.set(e, [ t ]);
  const r = this.getMaxListeners();
  if (r > 0 && this.listenerCount(e) > r) {
   const t = new Error(`Possible EventEmitter memory leak detected.\n         ${this.listenerCount(e)} ${e.toString()} listeners.\n         Use emitter.setMaxListeners() to increase limit`);
   t.name = "MaxListenersExceededWarning", console.warn(t);
  }
  return this;
 }
 addListener(e, t) {
  return this._addListener(e, t, !1);
 }
 emit(e, ...t) {
  if (this._events.has(e)) {
   "error" === e && this._events.get(EventEmitter.errorMonitor) && this.emit(EventEmitter.errorMonitor, ...t);
   const n = this._events.get(e).slice();
   for (const e of n) try {
    e.apply(this, t);
   } catch (e) {
    this.emit("error", e);
   }
   return !0;
  }
  if ("error" === e) throw this._events.get(EventEmitter.errorMonitor) && this.emit(EventEmitter.errorMonitor, ...t), 
  t.length > 0 ? t[0] : Error("Unhandled error.");
  return !1;
 }
 eventNames() {
  return Array.from(this._events.keys());
 }
 getMaxListeners() {
  return this.maxListeners || EventEmitter.defaultMaxListeners;
 }
 listenerCount(e) {
  return this._events.has(e) ? this._events.get(e).length : 0;
 }
 _listeners(e, t, n) {
  if (!e._events.has(t)) return [];
  const r = e._events.get(t);
  return n ? this.unwrapListeners(r) : r.slice(0);
 }
 unwrapListeners(e) {
  const t = new Array(e.length);
  for (let n = 0; n < e.length; n++) t[n] = e[n].listener || e[n];
  return t;
 }
 listeners(e) {
  return this._listeners(this, e, !0);
 }
 rawListeners(e) {
  return this._listeners(this, e, !1);
 }
 off(e, t) {
  return this.removeListener(e, t);
 }
 on(e, t) {
  return this.addListener(e, t);
 }
 once(e, t) {
  const n = this.onceWrap(e, t);
  return this.on(e, n), this;
 }
 onceWrap(e, t) {
  const n = function(...e) {
   this.context.removeListener(this.eventName, this.rawListener), this.listener.apply(this.context, e);
  }, r = {
   eventName: e,
   listener: t,
   rawListener: n,
   context: this
  }, i = n.bind(r);
  return r.rawListener = i, i.listener = t, i;
 }
 prependListener(e, t) {
  return this._addListener(e, t, !0);
 }
 prependOnceListener(e, t) {
  const n = this.onceWrap(e, t);
  return this.prependListener(e, n), this;
 }
 removeAllListeners(e) {
  if (void 0 === this._events) return this;
  if (e) {
   if (this._events.has(e)) {
    const t = this._events.get(e).slice();
    this._events.delete(e);
    for (const n of t) this.emit("removeListener", e, n);
   }
  } else this.eventNames().map((e => {
   this.removeAllListeners(e);
  }));
  return this;
 }
 removeListener(e, t) {
  if (this._events.has(e)) {
   const n = this._events.get(e);
   assert(n);
   let r = -1;
   for (let e = n.length - 1; e >= 0; e--) if (n[e] == t || n[e] && n[e].listener == t) {
    r = e;
    break;
   }
   r >= 0 && (n.splice(r, 1), this.emit("removeListener", e, t), 0 === n.length && this._events.delete(e));
  }
  return this;
 }
 setMaxListeners(e) {
  return validateIntegerRange(e, "maxListeners", 0), this.maxListeners = e, this;
 }
}

EventEmitter.defaultMaxListeners = 10, EventEmitter.errorMonitor = Symbol("events.errorMonitor");

const captureRejectionSymbol = Symbol.for("nodejs.rejection"), nodeEvents = {
 __proto__: null,
 default: EventEmitter,
 EventEmitter,
 once: function once(e, t) {
  return new Promise(((n, r) => {
   if (e instanceof EventTarget) e.addEventListener(t, ((...e) => {
    n(e);
   }), {
    once: !0,
    passive: !1,
    capture: !1
   }); else if (e instanceof EventEmitter) {
    const i = (...t) => {
     void 0 !== o && e.removeListener("error", o), n(t);
    };
    let o;
    return "error" !== t && (o = n => {
     e.removeListener(t, i), r(n);
    }, e.once("error", o)), void e.once(t, i);
   }
  }));
 },
 on: function on(e, t) {
  function n(...e) {
   const t = o.shift();
   t ? t.resolve(createIterResult(e, !1)) : i.push(e);
  }
  function r(e) {
   a = !0;
   const t = o.shift();
   t ? t.reject(e) : s = e, l.return();
  }
  const i = [], o = [];
  let s = null, a = !1;
  const l = {
   next() {
    const e = i.shift();
    if (e) return Promise.resolve(createIterResult(e, !1));
    if (s) {
     const e = Promise.reject(s);
     return s = null, e;
    }
    return a ? Promise.resolve(createIterResult(void 0, !0)) : new Promise((function(e, t) {
     o.push({
      resolve: e,
      reject: t
     });
    }));
   },
   return() {
    e.removeListener(t, n), e.removeListener("error", r), a = !0;
    for (const e of o) e.resolve(createIterResult(void 0, !0));
    return Promise.resolve(createIterResult(void 0, !0));
   },
   throw(i) {
    s = i, e.removeListener(t, n), e.removeListener("error", r);
   },
   [Symbol.asyncIterator]() {
    return this;
   }
  };
  return e.on(t, n), e.on("error", r), l;
 },
 captureRejectionSymbol
}, nodePath = {
 __proto__: null,
 SEP: SEP$1,
 SEP_PATTERN,
 common: function common(e, t = SEP$1) {
  const [n = "", ...r] = e;
  if ("" === n || 0 === r.length) return n.substring(0, n.lastIndexOf(t) + 1);
  const i = n.split(t);
  let o = i.length;
  for (const e of r) {
   const n = e.split(t);
   for (let e = 0; e < o; e++) n[e] !== i[e] && (o = e);
   if (0 === o) return "";
  }
  const s = i.slice(0, o).join(t);
  return s.endsWith(t) ? s : `${s}${t}`;
 },
 globToRegExp: function globToRegExp(e, {extended: t = !1, globstar: n = !0} = {}) {
  const r = function i(e, {extended: t = !1, globstar: n = !1, strict: r = !1, filepath: o = !1, flags: s = ""} = {}) {
   function a(e, t = {
    split: !1,
    last: !1,
    only: ""
   }) {
    const {split: n, last: r, only: i} = t;
    "path" !== i && (c += e), o && "regex" !== i && (f += e.match(l) ? SEP : e, n ? (r && (u += e), 
    "" !== u && (s.includes("g") || (u = `^${u}$`), h.push(new RegExp(u, s))), u = "") : u += e);
   }
   const l = new RegExp(`^${SEP}${r ? "" : "+"}$`);
   let c = "", u = "", f = "";
   const h = [];
   let d = !1, p = !1;
   const g = [];
   let m, y;
   for (let i = 0; i < e.length; i++) if (m = e[i], y = e[i + 1], [ "\\", "$", "^", ".", "=" ].includes(m)) a(`\\${m}`); else if (m.match(l)) a(SEP, {
    split: !0
   }), null != y && y.match(l) && !r && (c += "?"); else if ("(" !== m) if (")" !== m) if ("|" !== m) if ("+" !== m) if ("@" === m && t && "(" === y) g.push(m); else if ("!" !== m) if ("?" !== m) if ("[" !== m) if ("]" !== m) if ("{" !== m) if ("}" !== m) if ("," !== m) if ("*" !== m) a(m); else {
    if ("(" === y && t) {
     g.push(m);
     continue;
    }
    const r = e[i - 1];
    let o = 1;
    for (;"*" === e[i + 1]; ) o++, i++;
    const s = e[i + 1];
    n ? o > 1 && [ SEP_RAW, "/", void 0 ].includes(r) && [ SEP_RAW, "/", void 0 ].includes(s) ? (a(GLOBSTAR, {
     only: "regex"
    }), a(GLOBSTAR_SEGMENT, {
     only: "path",
     last: !0,
     split: !0
    }), i++) : (a(WILDCARD, {
     only: "regex"
    }), a(WILDCARD_SEGMENT, {
     only: "path"
    })) : a(".*");
   } else {
    if (d) {
     a("|");
     continue;
    }
    a(`\\${m}`);
   } else {
    if (t) {
     d = !1, a(")");
     continue;
    }
    a(`\\${m}`);
   } else {
    if (t) {
     d = !0, a("(?:");
     continue;
    }
    a(`\\${m}`);
   } else {
    if (t) {
     p = !1, a(m);
     continue;
    }
    a(`\\${m}`);
   } else {
    if (p && ":" === y) {
     i++;
     let t = "";
     for (;":" !== e[++i]; ) t += e[i];
     "alnum" === t ? a("(?:\\w|\\d)") : "space" === t ? a("\\s") : "digit" === t && a("\\d"), 
     i++;
     continue;
    }
    if (t) {
     p = !0, a(m);
     continue;
    }
    a(`\\${m}`);
   } else {
    if (t) {
     "(" === y ? g.push(m) : a(".");
     continue;
    }
    a(`\\${m}`);
   } else {
    if (t) {
     if (p) {
      a("^");
      continue;
     }
     if ("(" === y) {
      g.push(m), a("(?!"), i++;
      continue;
     }
     a(`\\${m}`);
     continue;
    }
    a(`\\${m}`);
   } else {
    if ("(" === y && t) {
     g.push(m);
     continue;
    }
    a(`\\${m}`);
   } else {
    if (g.length) {
     a(m);
     continue;
    }
    a(`\\${m}`);
   } else {
    if (g.length) {
     a(m);
     const e = g.pop();
     a("@" === e ? "{1}" : "!" === e ? WILDCARD : e);
     continue;
    }
    a(`\\${m}`);
   } else {
    if (g.length) {
     a(`${m}?:`);
     continue;
    }
    a(`\\${m}`);
   }
   s.includes("g") || (c = `^${c}$`, u = `^${u}$`, o && (f = `^${f}$`));
   const b = {
    regex: new RegExp(c, s)
   };
   return o && (h.push(new RegExp(u, s)), b.path = {
    regex: new RegExp(f, s),
    segments: h,
    globstar: new RegExp(s.includes("g") ? GLOBSTAR_SEGMENT : `^${GLOBSTAR_SEGMENT}$`, s)
   }), b;
  }(e, {
   extended: t,
   globstar: n,
   strict: !1,
   filepath: !0
  });
  return assert(null != r.path), r.path.regex;
 },
 isGlob: function isGlob(e) {
  const t = {
   "{": "}",
   "(": ")",
   "[": "]"
  }, n = /\\(.)|(^!|\*|[\].+)]\?|\[[^\\\]]+\]|\{[^\\}]+\}|\(\?[:!=][^\\)]+\)|\([^|]+\|[^\\)]+\))/;
  if ("" === e) return !1;
  let r;
  for (;r = n.exec(e); ) {
   if (r[2]) return !0;
   let n = r.index + r[0].length;
   const i = r[1], o = i ? t[i] : null;
   if (i && o) {
    const t = e.indexOf(o, n);
    -1 !== t && (n = t + 1);
   }
   e = e.slice(n);
  }
  return !1;
 },
 normalizeGlob,
 joinGlobs: function joinGlobs(e, {extended: t = !1, globstar: n = !1} = {}) {
  if (!n || 0 == e.length) return join(...e);
  if (0 === e.length) return ".";
  let r;
  for (const t of e) {
   const e = t;
   e.length > 0 && (r ? r += `${SEP$1}${e}` : r = e);
  }
  return r ? normalizeGlob(r, {
   extended: t,
   globstar: n
  }) : ".";
 },
 win32,
 posix,
 basename,
 delimiter,
 dirname,
 extname,
 format,
 fromFileUrl,
 isAbsolute,
 join,
 normalize,
 parse: parse$1,
 relative,
 resolve,
 sep,
 toNamespacedPath
}, allowedModes = /^[0-7]{3}/, mod = {
 __proto__: null,
 writeFile: function writeFile(e, t, n) {
  return new Promise(((r, i) => {
   writeFile$1(e, t, n, (e => {
    if (e) return i(e);
    r();
   }));
  }));
 },
 readFile: function readFile(e, t) {
  return new Promise(((n, r) => {
   readFile$1(e, t, ((e, t) => e ? r(e) : null == t ? r(new Error("Invalid state: data missing, but no error")) : void n(t)));
  }));
 }
}, nodeFs = {
 __proto__: null,
 access: function access(e, t, n) {
  notImplemented("Not yet available");
 },
 accessSync: function accessSync(e, t) {
  notImplemented("Not yet available");
 },
 appendFile: function appendFile(e, t, n, r) {
  e = e instanceof URL ? fromFileUrl(e) : e;
  const i = n instanceof Function ? n : r, o = n instanceof Function ? void 0 : n;
  if (!i) throw new Error("No callback function supplied");
  validateEncoding(o);
  let s = -1;
  const a = (new TextEncoder).encode(t);
  new Promise(((t, n) => {
   if ("number" == typeof e) s = e, Deno.write(s, a).then(t).catch(n); else {
    const r = isFileOptions(o) ? o.mode : void 0, i = isFileOptions(o) ? o.flag : void 0;
    r && notImplemented("Deno does not yet support setting mode on create"), Deno.open(e, getOpenOptions(i)).then((({rid: e}) => (s = e, 
    Deno.write(e, a)))).then(t).catch(n);
   }
  })).then((() => {
   closeRidIfNecessary("string" == typeof e, s), i();
  })).catch((t => {
   closeRidIfNecessary("string" == typeof e, s), i(t);
  }));
 },
 appendFileSync: function appendFileSync(e, t, n) {
  let r = -1;
  validateEncoding(n), e = e instanceof URL ? fromFileUrl(e) : e;
  try {
   if ("number" == typeof e) r = e; else {
    const t = isFileOptions(n) ? n.mode : void 0, i = isFileOptions(n) ? n.flag : void 0;
    t && notImplemented("Deno does not yet support setting mode on create"), r = Deno.openSync(e, getOpenOptions(i)).rid;
   }
   const i = (new TextEncoder).encode(t);
   Deno.writeSync(r, i);
  } finally {
   closeRidIfNecessary("string" == typeof e, r);
  }
 },
 chmod: function chmod(e, t, n) {
  e = e instanceof URL ? fromFileUrl(e) : e, Deno.chmod(e, getResolvedMode(t)).then((() => n())).catch(n);
 },
 chmodSync: function chmodSync(e, t) {
  e = e instanceof URL ? fromFileUrl(e) : e, Deno.chmodSync(e, getResolvedMode(t));
 },
 chown: function chown(e, t, n, r) {
  e = e instanceof URL ? fromFileUrl(e) : e, Deno.chown(e, t, n).then((() => r())).catch(r);
 },
 chownSync: function chownSync(e, t, n) {
  e = e instanceof URL ? fromFileUrl(e) : e, Deno.chownSync(e, t, n);
 },
 close: function close(e, t) {
  queueMicrotask((() => {
   try {
    Deno.close(e), t(null);
   } catch (e) {
    t(e);
   }
  }));
 },
 closeSync: function closeSync(e) {
  Deno.close(e);
 },
 constants: {
  __proto__: null,
  F_OK: 0,
  R_OK: 4,
  W_OK: 2,
  X_OK: 1,
  S_IRUSR: 256,
  S_IWUSR: 128,
  S_IXUSR: 64,
  S_IRGRP: 32,
  S_IWGRP: 16,
  S_IXGRP: 8,
  S_IROTH: 4,
  S_IWOTH: 2,
  S_IXOTH: 1
 },
 copyFile: function copyFile(e, t, n) {
  e = e instanceof URL ? fromFileUrl(e) : e, Deno.copyFile(e, t).then((() => n())).catch(n);
 },
 copyFileSync: function copyFileSync(e, t) {
  e = e instanceof URL ? fromFileUrl(e) : e, Deno.copyFileSync(e, t);
 },
 exists: function exists(e, t) {
  e = e instanceof URL ? fromFileUrl(e) : e, Deno.lstat(e).then((() => {
   t(!0);
  })).catch((() => t(!1)));
 },
 existsSync: function existsSync(e) {
  e = e instanceof URL ? fromFileUrl(e) : e;
  try {
   return Deno.lstatSync(e), !0;
  } catch (e) {
   if (e instanceof Deno.errors.NotFound) return !1;
   throw e;
  }
 },
 readFile: readFile$1,
 readFileSync: function readFileSync(e, t) {
  e = e instanceof URL ? fromFileUrl(e) : e;
  const n = Deno.readFileSync(e), r = getEncoding$1(t);
  return maybeDecode(n, r);
 },
 readlink: function readlink(e, t, n) {
  let r;
  e = e instanceof URL ? fromFileUrl(e) : e, r = "function" == typeof t ? t : n;
  const i = getEncoding(t);
  !function o(e, t, n, ...r) {
   e(...r).then((e => n && n(null, t(e)))).catch((e => n && n(e, null)));
  }(Deno.readLink, (e => maybeEncode(e, i)), r, e);
 },
 readlinkSync: function readlinkSync(e, t) {
  return e = e instanceof URL ? fromFileUrl(e) : e, maybeEncode(Deno.readLinkSync(e), getEncoding(t));
 },
 mkdir: function mkdir(e, t, n) {
  e = e instanceof URL ? fromFileUrl(e) : e;
  let r = 511, i = !1;
  if ("function" == typeof t ? n = t : "number" == typeof t ? r = t : "boolean" == typeof t ? i = t : t && (void 0 !== t.recursive && (i = t.recursive), 
  void 0 !== t.mode && (r = t.mode)), "boolean" != typeof i) throw new Deno.errors.InvalidData("invalid recursive option , must be a boolean");
  Deno.mkdir(e, {
   recursive: i,
   mode: r
  }).then((() => {
   "function" == typeof n && n();
  })).catch((e => {
   "function" == typeof n && n(e);
  }));
 },
 mkdirSync: function mkdirSync(e, t) {
  e = e instanceof URL ? fromFileUrl(e) : e;
  let n = 511, r = !1;
  if ("number" == typeof t ? n = t : "boolean" == typeof t ? r = t : t && (void 0 !== t.recursive && (r = t.recursive), 
  void 0 !== t.mode && (n = t.mode)), "boolean" != typeof r) throw new Deno.errors.InvalidData("invalid recursive option , must be a boolean");
  Deno.mkdirSync(e, {
   recursive: r,
   mode: n
  });
 },
 writeFile: writeFile$1,
 writeFileSync: function writeFileSync(e, t, n) {
  e = e instanceof URL ? fromFileUrl(e) : e;
  const r = isFileOptions(n) ? n.flag : void 0, i = isFileOptions(n) ? n.mode : void 0, o = checkEncoding(getEncoding$1(n)) || "utf8", s = getOpenOptions(r || "w");
  "string" == typeof t && (t = Buffer.from(t, o));
  const a = "number" == typeof e;
  let l, c = null;
  try {
   l = a ? new Deno.File(e) : Deno.openSync(e, s), !a && i && ("windows" === Deno.build.os && notImplemented('"mode" on Windows'), 
   Deno.chmodSync(e, i)), Deno.writeAllSync(l, t);
  } catch (e) {
   c = e;
  } finally {
   if (!a && l && l.close(), c) throw c;
  }
 },
 promises: mod
}, process = {
 arch: Deno.build.arch,
 chdir: Deno.chdir,
 cwd: Deno.cwd,
 exit: Deno.exit,
 pid: Deno.pid,
 platform: "windows" === Deno.build.os ? "win32" : Deno.build.os,
 version: "v12.0.0",
 versions: {
  node: "v12.0.0",
  ...Deno.version
 },
 on() {},
 env: {},
 argv: [ "deno", ...Deno.args ]
}, SEE_GITHUB_ISSUE = "See https://github.com/denoland/deno/issues/3802";

arch[Symbol.toPrimitive] = () => arch(), endianness[Symbol.toPrimitive] = () => endianness(), 
freemem[Symbol.toPrimitive] = () => freemem(), homedir[Symbol.toPrimitive] = () => homedir(), 
hostname[Symbol.toPrimitive] = () => hostname(), platform[Symbol.toPrimitive] = () => platform(), 
release[Symbol.toPrimitive] = () => release(), totalmem[Symbol.toPrimitive] = () => totalmem(), 
type[Symbol.toPrimitive] = () => type(), uptime[Symbol.toPrimitive] = () => uptime();

const nodeOs = {
 __proto__: null,
 arch,
 cpus: function cpus() {
  notImplemented(SEE_GITHUB_ISSUE);
 },
 endianness,
 freemem,
 getPriority: function getPriority(e = 0) {
  validateIntegerRange(e, "pid"), notImplemented(SEE_GITHUB_ISSUE);
 },
 homedir,
 hostname,
 loadavg: function loadavg() {
  return "windows" === Deno.build.os ? [ 0, 0, 0 ] : Deno.loadavg();
 },
 networkInterfaces: function networkInterfaces() {
  notImplemented(SEE_GITHUB_ISSUE);
 },
 platform,
 release,
 setPriority: function setPriority(e, t) {
  void 0 === t && (t = e, e = 0), validateIntegerRange(e, "pid"), validateIntegerRange(t, "priority", -20, 19), 
  notImplemented(SEE_GITHUB_ISSUE);
 },
 tmpdir: function tmpdir() {
  notImplemented(SEE_GITHUB_ISSUE);
 },
 totalmem,
 type,
 uptime,
 userInfo: function userInfo(e = {
  encoding: "utf-8"
 }) {
  notImplemented(SEE_GITHUB_ISSUE);
 },
 constants: {
  dlopen: {},
  errno: {},
  signals: Deno.Signal,
  priority: {}
 },
 EOL: "windows" == Deno.build.os ? EOL$1.CRLF : EOL$1.LF
}, nodeTimers = {
 __proto__: null,
 setTimeout: window.setTimeout,
 clearTimeout: window.clearTimeout,
 setInterval: window.setInterval,
 clearInterval: window.clearInterval,
 setImmediate: (e, ...t) => window.setTimeout(e, 0, ...t),
 clearImmediate: window.clearTimeout
}, hexTable = new Array(256);

for (let e = 0; e < 256; ++e) hexTable[e] = "%" + ((e < 16 ? "0" : "") + e.toString(16)).toUpperCase();

const unescape = decodeURIComponent, escape = encodeURIComponent, nodeQueryString = {
 __proto__: null,
 hexTable,
 parse,
 encodeStr: function encodeStr(e, t, n) {
  const r = e.length;
  if (0 === r) return "";
  let i = "", o = 0;
  for (let s = 0; s < r; s++) {
   let a = e.charCodeAt(s);
   if (a < 128) {
    if (1 === t[a]) continue;
    o < s && (i += e.slice(o, s)), o = s + 1, i += n[a];
   } else if (o < s && (i += e.slice(o, s)), a < 2048) o = s + 1, i += n[192 | a >> 6] + n[128 | 63 & a]; else if (a < 55296 || a >= 57344) o = s + 1, 
   i += n[224 | a >> 12] + n[128 | a >> 6 & 63] + n[128 | 63 & a]; else {
    if (++s, s >= r) throw new Deno.errors.InvalidData("invalid URI");
    o = s + 1, a = 65536 + ((1023 & a) << 10 | 1023 & e.charCodeAt(s)), i += n[240 | a >> 18] + n[128 | a >> 12 & 63] + n[128 | a >> 6 & 63] + n[128 | 63 & a];
   }
  }
  return 0 === o ? e : o < r ? i + e.slice(o) : i;
 },
 stringify,
 decode: parse,
 encode: stringify,
 unescape,
 escape
};

!function(e) {
 e[e.ascii = 0] = "ascii", e[e.latin1 = 1] = "latin1", e[e.utf16le = 2] = "utf16le";
}(NotImplemented || (NotImplemented = {}));

class StringDecoderBase {
 constructor(e, t) {
  this.encoding = e, this.lastNeed = 0, this.lastTotal = 0, this.lastChar = Buffer.allocUnsafe(t);
 }
}

class Base64Decoder extends StringDecoderBase {
 constructor(e) {
  super(normalizeEncoding(e), 3), this.end = base64End, this.fillLast = utf8FillLastIncomplete, 
  this.text = base64Text, this.write = utf8Write;
 }
}

class GenericDecoder extends StringDecoderBase {
 constructor(e) {
  super(normalizeEncoding(e), 4), this.end = simpleEnd, this.fillLast = void 0, this.text = utf8Text, 
  this.write = simpleWrite;
 }
}

class Utf8Decoder extends StringDecoderBase {
 constructor(e) {
  super(normalizeEncoding(e), 4), this.end = utf8End, this.fillLast = utf8FillLastComplete, 
  this.text = utf8Text, this.write = utf8Write;
 }
}

const nodeStringDecoder = {
 __proto__: null,
 StringDecoder: class StringDecoder {
  constructor(e) {
   let t;
   switch (e) {
   case "utf8":
    t = new Utf8Decoder(e);
    break;

   case "base64":
    t = new Base64Decoder(e);
    break;

   default:
    t = new GenericDecoder(e);
   }
   this.encoding = t.encoding, this.end = t.end, this.fillLast = t.fillLast, this.lastChar = t.lastChar, 
   this.lastNeed = t.lastNeed, this.lastTotal = t.lastTotal, this.text = t.text, this.write = t.write;
  }
 }
}, isWindows$1 = "windows" === Deno.build.os, forwardSlashRegEx = /\//g, percentRegEx = /%/g, backslashRegEx = /\\/g, newlineRegEx = /\n/g, carriageReturnRegEx = /\r/g, tabRegEx = /\t/g, CHAR_FORWARD_SLASH = "/".charCodeAt(0), CHAR_BACKWARD_SLASH = "\\".charCodeAt(0), CHAR_COLON = ":".charCodeAt(0), isWindows = "windows" == Deno.build.os, relativeResolveCache = Object.create(null);

let requireDepth = 0, statCache = null;

class Module {
 constructor(e = "", t) {
  this.id = e, this.exports = {}, this.parent = t || null, updateChildren(t || null, this, !1), 
  this.filename = null, this.loaded = !1, this.children = [], this.paths = [], this.path = dirname(e);
 }
 require(e) {
  if ("" === e) throw new Error(`id '${e}' must be a non-empty string`);
  requireDepth++;
  try {
   return Module._load(e, this, !1);
  } finally {
   requireDepth--;
  }
 }
 load(e) {
  assert(!this.loaded), this.filename = e, this.paths = Module._nodeModulePaths(dirname(e));
  const t = function n(e) {
   const t = basename(e);
   let n, r, i = 0;
   for (;-1 !== (r = t.indexOf(".", i)); ) if (i = r + 1, 0 !== r && (n = t.slice(r), 
   Module._extensions[n])) return n;
   return ".js";
  }(e);
  Module._extensions[t](this, e), this.loaded = !0;
 }
 _compile(e, t) {
  const n = function r(e, t) {
   const n = Module.wrap(t), [r, i] = Deno.core.evalContext(n, e);
   if (i) throw i;
   return r;
  }(t, e), i = dirname(t), o = makeRequireFunction(this), s = this.exports, a = s;
  0 === requireDepth && (statCache = new Map);
  const l = n.call(a, s, o, this, t, i);
  return 0 === requireDepth && (statCache = null), l;
 }
 static _resolveLookupPaths(e, t) {
  if ("." !== e.charAt(0) || e.length > 1 && "." !== e.charAt(1) && "/" !== e.charAt(1) && (!isWindows || "\\" !== e.charAt(1))) {
   let e = modulePaths;
   return null !== t && t.paths && t.paths.length && (e = t.paths.concat(e)), e.length > 0 ? e : null;
  }
  return t && t.id && t.filename ? [ dirname(t.filename) ] : [ "." ].concat(Module._nodeModulePaths("."), modulePaths);
 }
 static _resolveFilename(e, t, n, r) {
  if (function i(e) {
   return nativeModulePolyfill.has(e);
  }(e)) return e;
  let o;
  if ("object" == typeof r && null !== r) if (Array.isArray(r.paths)) if (e.startsWith("./") || e.startsWith("../") || isWindows && e.startsWith(".\\") || e.startsWith("..\\")) o = r.paths; else {
   const t = new Module("", null);
   o = [];
   for (let n = 0; n < r.paths.length; n++) {
    const i = r.paths[n];
    t.paths = Module._nodeModulePaths(i);
    const s = Module._resolveLookupPaths(e, t);
    for (let e = 0; e < s.length; e++) o.includes(s[e]) || o.push(s[e]);
   }
  } else {
   if (void 0 !== r.paths) throw new Error("options.paths is invalid");
   o = Module._resolveLookupPaths(e, t);
  } else o = Module._resolveLookupPaths(e, t);
  const s = Module._findPath(e, o, n);
  if (!s) {
   const n = [];
   for (let e = t; e; e = e.parent) n.push(e.filename || e.id);
   let r = `Cannot find module '${e}'`;
   n.length > 0 && (r = r + "\nRequire stack:\n- " + n.join("\n- "));
   const i = new Error(r);
   throw i.code = "MODULE_NOT_FOUND", i.requireStack = n, i;
  }
  return s;
 }
 static _findPath(e, t, n) {
  const r = isAbsolute(e);
  if (r) t = [ "" ]; else if (!t || 0 === t.length) return !1;
  const i = e + "\0" + (1 === t.length ? t[0] : t.join("\0")), o = Module._pathCache[i];
  if (o) return o;
  let s, a = e.length > 0 && e.charCodeAt(e.length - 1) === CHAR_FORWARD_SLASH;
  a || (a = /(?:^|\/)\.?\.$/.test(e));
  for (let n = 0; n < t.length; n++) {
   const o = t[n];
   if (o && stat(o) < 1) continue;
   const l = resolveExports(o, e, r);
   let c;
   const u = stat(l);
   if (a || (0 === u && (c = toRealPath(l)), c || (void 0 === s && (s = Object.keys(Module._extensions)), 
   c = tryExtensions(l, s))), c || 1 !== u || (void 0 === s && (s = Object.keys(Module._extensions)), 
   c = tryPackage(l, s)), c) return Module._pathCache[i] = c, c;
  }
  return !1;
 }
 static _load(e, t, n) {
  let r;
  if (t) {
   r = `${t.path}\0${e}`;
   const n = relativeResolveCache[r];
   if (void 0 !== n) {
    const e = Module._cache[n];
    if (void 0 !== e) return updateChildren(t, e, !0), e.loaded ? e.exports : getExportsForCircularRequire(e);
    delete relativeResolveCache[r];
   }
  }
  const i = Module._resolveFilename(e, t, n), o = Module._cache[i];
  if (void 0 !== o) return updateChildren(t, o, !0), o.loaded ? o.exports : getExportsForCircularRequire(o);
  const s = function a(e, t) {
   return nativeModulePolyfill.get(t);
  }(0, e);
  if (s) return s.exports;
  const l = new Module(i, t);
  n && (l.id = "."), Module._cache[i] = l, void 0 !== t && (assert(r), relativeResolveCache[r] = i);
  let c = !0;
  try {
   l.load(i), c = !1;
  } finally {
   c ? (delete Module._cache[i], void 0 !== t && (assert(r), delete relativeResolveCache[r])) : l.exports && Object.getPrototypeOf(l.exports) === CircularRequirePrototypeWarningProxy && Object.setPrototypeOf(l.exports, PublicObjectPrototype);
  }
  return l.exports;
 }
 static wrap(e) {
  return `${Module.wrapper[0]}${e}${Module.wrapper[1]}`;
 }
 static _nodeModulePaths(e) {
  if (isWindows) {
   if ((e = resolve(e)).charCodeAt(e.length - 1) === CHAR_BACKWARD_SLASH && e.charCodeAt(e.length - 2) === CHAR_COLON) return [ e + "node_modules" ];
   const t = [];
   for (let n = e.length - 1, r = 0, i = e.length; n >= 0; --n) {
    const o = e.charCodeAt(n);
    o === CHAR_BACKWARD_SLASH || o === CHAR_FORWARD_SLASH || o === CHAR_COLON ? (r !== nmLen && t.push(e.slice(0, i) + "\\node_modules"), 
    i = n, r = 0) : -1 !== r && (nmChars[r] === o ? ++r : r = -1);
   }
   return t;
  }
  {
   if ("/" === (e = resolve(e))) return [ "/node_modules" ];
   const t = [];
   for (let n = e.length - 1, r = 0, i = e.length; n >= 0; --n) {
    const o = e.charCodeAt(n);
    o === CHAR_FORWARD_SLASH ? (r !== nmLen && t.push(e.slice(0, i) + "/node_modules"), 
    i = n, r = 0) : -1 !== r && (nmChars[r] === o ? ++r : r = -1);
   }
   return t.push("/node_modules"), t;
  }
 }
 static createRequire(e) {
  let t;
  if (e instanceof URL || "string" == typeof e && !isAbsolute(e)) t = fileURLToPath(e); else {
   if ("string" != typeof e) throw new Error("filename should be a string");
   t = e;
  }
  return function n(e) {
   const t = e.endsWith("/") || isWindows && e.endsWith("\\") ? join(e, "noop.js") : e, n = new Module(t);
   return n.filename = t, n.paths = Module._nodeModulePaths(n.path), makeRequireFunction(n);
  }(t);
 }
 static _initPaths() {
  const e = Deno.env.get("HOME"), t = Deno.env.get("NODE_PATH");
  let n = [];
  e && (n.unshift(resolve(e, ".node_libraries")), n.unshift(resolve(e, ".node_modules"))), 
  t && (n = t.split(delimiter).filter((function e(t) {
   return !!t;
  })).concat(n)), modulePaths = n, Module.globalPaths = modulePaths.slice(0);
 }
 static _preloadModules(e) {
  if (!Array.isArray(e)) return;
  const t = new Module("internal/preload", null);
  try {
   t.paths = Module._nodeModulePaths(Deno.cwd());
  } catch (e) {
   if ("ENOENT" !== e.code) throw e;
  }
  for (let n = 0; n < e.length; n++) t.require(e[n]);
 }
}

Module.builtinModules = [], Module._extensions = Object.create(null), Module._cache = Object.create(null), 
Module._pathCache = Object.create(null), Module.globalPaths = [], Module.wrapper = [ "(function (exports, require, module, __filename, __dirname) { ", "\n});" ];

const nativeModulePolyfill = new Map;

nativeModulePolyfill.set("buffer", createNativeModule("buffer", nodeBuffer)), nativeModulePolyfill.set("events", createNativeModule("events", nodeEvents)), 
nativeModulePolyfill.set("fs", createNativeModule("fs", nodeFs)), nativeModulePolyfill.set("os", createNativeModule("os", nodeOs)), 
nativeModulePolyfill.set("path", createNativeModule("path", nodePath)), nativeModulePolyfill.set("querystring", createNativeModule("querystring", nodeQueryString)), 
nativeModulePolyfill.set("string_decoder", createNativeModule("string_decoder", nodeStringDecoder)), 
nativeModulePolyfill.set("timers", createNativeModule("timers", nodeTimers)), nativeModulePolyfill.set("util", createNativeModule("util", nodeUtil));

for (const e of nativeModulePolyfill.keys()) Module.builtinModules.push(e);

let modulePaths = [];

const packageJsonCache = new Map, EXPORTS_PATTERN = /^((?:@[^/\\%]+\/)?[^./\\%][^/\\%]*)(\/.*)?$/, nmChars = [ 115, 101, 108, 117, 100, 111, 109, 95, 101, 100, 111, 110 ], nmLen = nmChars.length, CircularRequirePrototypeWarningProxy = new Proxy({}, {
 get(e, t) {
  if (t in e) return e[t];
  emitCircularRequireWarning(t);
 },
 getOwnPropertyDescriptor(e, t) {
  if (Object.prototype.hasOwnProperty.call(e, t)) return Object.getOwnPropertyDescriptor(e, t);
  emitCircularRequireWarning(t);
 }
}), PublicObjectPrototype = window.Object.prototype;

Module._extensions[".js"] = (e, t) => {
 if (t.endsWith(".js")) {
  const e = function n(e) {
   const t = e.indexOf(sep);
   let n;
   for (;(n = e.lastIndexOf(sep)) > t; ) {
    if ((e = e.slice(0, n)).endsWith(sep + "node_modules")) return !1;
    const t = readPackage(e);
    if (t) return {
     path: e,
     data: t
    };
   }
   return !1;
  }(t);
  if (!1 !== e && e.data && "module" === e.data.type) throw new Error("Importing ESM module");
 }
 const r = (new TextDecoder).decode(Deno.readFileSync(t));
 e._compile(r, t);
}, Module._extensions[".json"] = (e, t) => {
 const n = (new TextDecoder).decode(Deno.readFileSync(t));
 try {
  e.exports = JSON.parse(function r(e) {
   return 65279 === e.charCodeAt(0) && (e = e.slice(1)), e;
  }(n));
 } catch (e) {
  throw e.message = t + ": " + e.message, e;
 }
};

const createRequire = Module.createRequire;

Object.assign(nodeFs, {
 stat: (...e) => {
  const t = e[0], n = e.length > 2 ? e[2] : e[1];
  try {
   const e = Deno.statSync(t);
   n && n(null, {
    isFile: () => e.isFile,
    isDirectory: () => e.isDirectory,
    isSymbolicLink: () => e.isSymlink,
    size: e.size
   });
  } catch (e) {
   n && n(e);
  }
 },
 statSync: e => {
  const t = Deno.statSync(e);
  return {
   isFile: () => t.isFile,
   isDirectory: () => t.isDirectory,
   isSymbolicLink: () => t.isSymlink,
   size: t.size
  };
 }
});

const applyNodeCompat = e => {
 globalThis.process = process;
 const t = createRequire(join(e.fromDir, "noop.js"));
 globalThis.require = t;
};

export { applyNodeCompat };