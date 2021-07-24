/*! Copyright 2018-2020 the Deno authors. All rights reserved. MIT license.
 *  https://github.com/denoland/deno/blob/master/LICENSE
 *  https://deno.land/  */
import "../../compiler/stencil.js";

import { createDenoSys } from "./index.js";

const coreCompiler = globalThis.stencil, denoSys = createDenoSys({
 Deno
}), msgHandler = coreCompiler.createWorkerMessageHandler(denoSys);

((e, s) => {
 let r = !1;
 const n = [], t = () => {
  r = !1, e.postMessage(n), n.length = 0;
 }, o = e => {
  n.push(e), r || (r = !0, queueMicrotask(t));
 }, c = (e, s) => {
  const r = {
   stencilId: e,
   stencilRtnValue: null,
   stencilRtnError: "Error"
  };
  "string" == typeof s ? r.stencilRtnError += ": " + s : s && (s.stack ? r.stencilRtnError += ": " + s.stack : s.message && (r.stencilRtnError += ": " + s.message)), 
  o(r);
 }, l = async e => {
  if (e && "number" == typeof e.stencilId) try {
   const r = {
    stencilId: e.stencilId,
    stencilRtnValue: await s(e),
    stencilRtnError: null
   };
   o(r);
  } catch (s) {
   c(e.stencilId, s);
  }
 };
 e.onmessage = e => {
  const s = e.data;
  if (Array.isArray(s)) for (const e of s) l(e);
 }, e.onerror = e => {
  c(-1, e);
 };
})(globalThis, msgHandler);