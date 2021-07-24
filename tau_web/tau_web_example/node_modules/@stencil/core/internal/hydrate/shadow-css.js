const _parenSuffix = ")(?:\\(((?:\\([^)(]*\\)|[^)(]*)+?)\\))?([^,{]*)", _cssColonHostRe = new RegExp("(-shadowcsshost" + _parenSuffix, "gim"), _cssColonHostContextRe = new RegExp("(-shadowcsscontext" + _parenSuffix, "gim"), _cssColonSlottedRe = new RegExp("(-shadowcssslotted" + _parenSuffix, "gim"), _polyfillHostNoCombinatorRe = /-shadowcsshost-no-combinator([^\s]*)/, _shadowDOMSelectorsRe = [ /::shadow/g, /::content/g ], _polyfillHostRe = /-shadowcsshost/gim, _colonHostRe = /:host/gim, _colonSlottedRe = /::slotted/gim, _colonHostContextRe = /:host-context/gim, _commentRe = /\/\*\s*[\s\S]*?\*\//g, _commentWithHashRe = /\/\*\s*#\s*source(Mapping)?URL=[\s\S]+?\*\//g, _ruleRe = /(\s*)([^;\{\}]+?)(\s*)((?:{%BLOCK%}?\s*;?)|(?:\s*;))/g, _curlyRe = /([{}])/g, processRules = (e, t) => {
 const s = escapeBlocks(e);
 let o = 0;
 return s.escapedString.replace(_ruleRe, ((...e) => {
  const c = e[2];
  let r = "", n = e[4], l = "";
  n && n.startsWith("{%BLOCK%") && (r = s.blocks[o++], n = n.substring("%BLOCK%".length + 1), 
  l = "{");
  const a = t({
   selector: c,
   content: r
  });
  return `${e[1]}${a.selector}${e[3]}${l}${a.content}${n}`;
 }));
}, escapeBlocks = e => {
 const t = e.split(_curlyRe), s = [], o = [];
 let c = 0, r = [];
 for (let e = 0; e < t.length; e++) {
  const n = t[e];
  "}" === n && c--, c > 0 ? r.push(n) : (r.length > 0 && (o.push(r.join("")), s.push("%BLOCK%"), 
  r = []), s.push(n)), "{" === n && c++;
 }
 return r.length > 0 && (o.push(r.join("")), s.push("%BLOCK%")), {
  escapedString: s.join(""),
  blocks: o
 };
}, convertColonRule = (e, t, s) => e.replace(t, ((...e) => {
 if (e[2]) {
  const t = e[2].split(","), o = [];
  for (let c = 0; c < t.length; c++) {
   const r = t[c].trim();
   if (!r) break;
   o.push(s("-shadowcsshost-no-combinator", r, e[3]));
  }
  return o.join(",");
 }
 return "-shadowcsshost-no-combinator" + e[3];
})), colonHostPartReplacer = (e, t, s) => e + t.replace("-shadowcsshost", "") + s, colonHostContextPartReplacer = (e, t, s) => t.indexOf("-shadowcsshost") > -1 ? colonHostPartReplacer(e, t, s) : e + t + s + ", " + t + " " + e + s, scopeSelectors = (e, t, s, o, c) => processRules(e, (e => {
 let c = e.selector, r = e.content;
 return "@" !== e.selector[0] ? c = ((e, t, s, o) => e.split(",").map((e => o && e.indexOf("." + o) > -1 ? e.trim() : ((e, t) => !(e => (e = e.replace(/\[/g, "\\[").replace(/\]/g, "\\]"), 
 new RegExp("^(" + e + ")([>\\s~+[.,{:][\\s\\S]*)?$", "m")))(t).test(e))(e, t) ? ((e, t, s) => {
  const o = "." + (t = t.replace(/\[is=([^\]]*)\]/g, ((e, ...t) => t[0]))), c = e => {
   let c = e.trim();
   if (!c) return "";
   if (e.indexOf("-shadowcsshost-no-combinator") > -1) c = ((e, t, s) => {
    if (_polyfillHostRe.lastIndex = 0, _polyfillHostRe.test(e)) {
     const t = `.${s}`;
     return e.replace(_polyfillHostNoCombinatorRe, ((e, s) => s.replace(/([^:]*)(:*)(.*)/, ((e, s, o, c) => s + t + o + c)))).replace(_polyfillHostRe, t + " ");
    }
    return t + " " + e;
   })(e, t, s); else {
    const t = e.replace(_polyfillHostRe, "");
    if (t.length > 0) {
     const e = t.match(/([^:]*)(:*)(.*)/);
     e && (c = e[1] + o + e[2] + e[3]);
    }
   }
   return c;
  }, r = (e => {
   const t = [];
   let s, o = 0;
   return s = (e = e.replace(/(\[[^\]]*\])/g, ((e, s) => {
    const c = `__ph-${o}__`;
    return t.push(s), o++, c;
   }))).replace(/(:nth-[-\w]+)(\([^)]+\))/g, ((e, s, c) => {
    const r = `__ph-${o}__`;
    return t.push(c), o++, s + r;
   })), {
    content: s,
    placeholders: t
   };
  })(e);
  let n, l = "", a = 0;
  const p = /( |>|\+|~(?!=))\s*/g;
  let i = !((e = r.content).indexOf("-shadowcsshost-no-combinator") > -1);
  for (;null !== (n = p.exec(e)); ) {
   const t = n[1], s = e.slice(a, n.index).trim();
   i = i || s.indexOf("-shadowcsshost-no-combinator") > -1, l += `${i ? c(s) : s} ${t} `, 
   a = p.lastIndex;
  }
  const h = e.substring(a);
  return i = i || h.indexOf("-shadowcsshost-no-combinator") > -1, l += i ? c(h) : h, 
  u = r.placeholders, l.replace(/__ph-(\d+)__/g, ((e, t) => u[+t]));
  var u;
 })(e, t, s).trim() : e.trim())).join(", "))(e.selector, t, s, o) : (e.selector.startsWith("@media") || e.selector.startsWith("@supports") || e.selector.startsWith("@page") || e.selector.startsWith("@document")) && (r = scopeSelectors(e.content, t, s, o)), 
 {
  selector: c.replace(/\s{2,}/g, " ").trim(),
  content: r
 };
})), scopeCss = (e, t, s) => {
 const o = t + "-h", c = t + "-s", r = e.match(_commentWithHashRe) || [];
 e = e.replace(_commentRe, "");
 const n = [];
 if (s) {
  const t = e => {
   const t = `/*!@___${n.length}___*/`, s = `/*!@${e.selector}*/`;
   return n.push({
    placeholder: t,
    comment: s
   }), e.selector = t + e.selector, e;
  };
  e = processRules(e, (e => "@" !== e.selector[0] ? t(e) : e.selector.startsWith("@media") || e.selector.startsWith("@supports") || e.selector.startsWith("@page") || e.selector.startsWith("@document") ? (e.content = processRules(e.content, t), 
  e) : e));
 }
 const l = ((e, t, s, o, c) => {
  const r = ((e, t) => {
   const s = "." + t + " > ", o = [];
   return e = e.replace(_cssColonSlottedRe, ((...e) => {
    if (e[2]) {
     const t = e[2].trim(), c = e[3], r = s + t + c;
     let n = "";
     for (let t = e[4] - 1; t >= 0; t--) {
      const s = e[5][t];
      if ("}" === s || "," === s) break;
      n = s + n;
     }
     const l = n + r, a = `${n.trimRight()}${r.trim()}`;
     if (l.trim() !== a.trim()) {
      const e = `${a}, ${l}`;
      o.push({
       orgSelector: l,
       updatedSelector: e
      });
     }
     return r;
    }
    return "-shadowcsshost-no-combinator" + e[3];
   })), {
    selectors: o,
    cssText: e
   };
  })(e = (e => convertColonRule(e, _cssColonHostContextRe, colonHostContextPartReplacer))(e = (e => convertColonRule(e, _cssColonHostRe, colonHostPartReplacer))(e = e.replace(_colonHostContextRe, "-shadowcsscontext").replace(_colonHostRe, "-shadowcsshost").replace(_colonSlottedRe, "-shadowcssslotted"))), o);
  return e = (e => _shadowDOMSelectorsRe.reduce(((e, t) => e.replace(t, " ")), e))(e = r.cssText), 
  t && (e = scopeSelectors(e, t, s, o)), {
   cssText: (e = (e = e.replace(/-shadowcsshost-no-combinator/g, `.${s}`)).replace(/>\s*\*\s+([^{, ]+)/gm, " $1 ")).trim(),
   slottedSelectors: r.selectors
  };
 })(e, t, o, c);
 return e = [ l.cssText, ...r ].join("\n"), s && n.forEach((({placeholder: t, comment: s}) => {
  e = e.replace(t, s);
 })), l.slottedSelectors.forEach((t => {
  e = e.replace(t.orgSelector, t.updatedSelector);
 })), e;
};

export { scopeCss };