'use strict';

Object.defineProperty(exports, '__esModule', { value: true });

const index = require('./index-a0a08b2a.js');
const helpers = require('./helpers-d381ec4d.js');
const ionicGlobal = require('./ionic-global-06f21c1a.js');
const theme = require('./theme-30b7a575.js');

const Route = class {
  constructor(hostRef) {
    index.registerInstance(this, hostRef);
    this.ionRouteDataChanged = index.createEvent(this, "ionRouteDataChanged", 7);
    /**
     * Relative path that needs to match in order for this route to apply.
     *
     * Accepts paths similar to expressjs so that you can define parameters
     * in the url /foo/:bar where bar would be available in incoming props.
     */
    this.url = '';
  }
  onUpdate(newValue) {
    this.ionRouteDataChanged.emit(newValue);
  }
  onComponentProps(newValue, oldValue) {
    if (newValue === oldValue) {
      return;
    }
    const keys1 = newValue ? Object.keys(newValue) : [];
    const keys2 = oldValue ? Object.keys(oldValue) : [];
    if (keys1.length !== keys2.length) {
      this.onUpdate(newValue);
      return;
    }
    for (const key of keys1) {
      if (newValue[key] !== oldValue[key]) {
        this.onUpdate(newValue);
        return;
      }
    }
  }
  connectedCallback() {
    this.ionRouteDataChanged.emit();
  }
  static get watchers() { return {
    "url": ["onUpdate"],
    "component": ["onUpdate"],
    "componentProps": ["onComponentProps"]
  }; }
};

const RouteRedirect = class {
  constructor(hostRef) {
    index.registerInstance(this, hostRef);
    this.ionRouteRedirectChanged = index.createEvent(this, "ionRouteRedirectChanged", 7);
  }
  propDidChange() {
    this.ionRouteRedirectChanged.emit();
  }
  connectedCallback() {
    this.ionRouteRedirectChanged.emit();
  }
  static get watchers() { return {
    "from": ["propDidChange"],
    "to": ["propDidChange"]
  }; }
};

const ROUTER_INTENT_NONE = 'root';
const ROUTER_INTENT_FORWARD = 'forward';
const ROUTER_INTENT_BACK = 'back';

// Join the non empty segments with "/".
const generatePath = (segments) => {
  const path = segments
    .filter(s => s.length > 0)
    .join('/');
  return '/' + path;
};
const generateUrl = (segments, useHash, queryString) => {
  let url = generatePath(segments);
  if (useHash) {
    url = '#' + url;
  }
  if (queryString !== undefined) {
    url += '?' + queryString;
  }
  return url;
};
const writePath = (history, root, useHash, path, direction, state, queryString) => {
  const url = generateUrl([...parsePath(root).segments, ...path], useHash, queryString);
  if (direction === ROUTER_INTENT_FORWARD) {
    history.pushState(state, '', url);
  }
  else {
    history.replaceState(state, '', url);
  }
};
const chainToPath = (chain) => {
  const path = [];
  for (const route of chain) {
    for (const segment of route.path) {
      if (segment[0] === ':') {
        const param = route.params && route.params[segment.slice(1)];
        if (!param) {
          return null;
        }
        path.push(param);
      }
      else if (segment !== '') {
        path.push(segment);
      }
    }
  }
  return path;
};
// Remove the prefix segments from the path segments.
//
// Return:
// - null when the path segments do not start with the passed prefix,
// - the path segments after the prefix otherwise.
const removePrefix = (prefix, path) => {
  if (prefix.length > path.length) {
    return null;
  }
  if (prefix.length <= 1 && prefix[0] === '') {
    return path;
  }
  for (let i = 0; i < prefix.length; i++) {
    if (prefix[i] !== path[i]) {
      return null;
    }
  }
  if (path.length === prefix.length) {
    return [''];
  }
  return path.slice(prefix.length);
};
const readPath = (loc, root, useHash) => {
  const prefix = parsePath(root).segments;
  const pathname = useHash ? loc.hash.slice(1) : loc.pathname;
  const path = parsePath(pathname).segments;
  return removePrefix(prefix, path);
};
// Parses the path to:
// - segments an array of '/' separated parts,
// - queryString (undefined when no query string).
const parsePath = (path) => {
  let segments = [''];
  let queryString;
  if (path != null) {
    const qsStart = path.indexOf('?');
    if (qsStart > -1) {
      queryString = path.substr(qsStart + 1);
      path = path.substr(0, qsStart);
    }
    segments = path.split('/')
      .map(s => s.trim())
      .filter(s => s.length > 0);
    if (segments.length === 0) {
      segments = [''];
    }
  }
  return { segments, queryString };
};

const printRoutes = (routes) => {
  console.group(`[ion-core] ROUTES[${routes.length}]`);
  for (const chain of routes) {
    const path = [];
    chain.forEach(r => path.push(...r.path));
    const ids = chain.map(r => r.id);
    console.debug(`%c ${generatePath(path)}`, 'font-weight: bold; padding-left: 20px', '=>\t', `(${ids.join(', ')})`);
  }
  console.groupEnd();
};
const printRedirects = (redirects) => {
  console.group(`[ion-core] REDIRECTS[${redirects.length}]`);
  for (const redirect of redirects) {
    if (redirect.to) {
      console.debug('FROM: ', `$c ${generatePath(redirect.from)}`, 'font-weight: bold', ' TO: ', `$c ${generatePath(redirect.to.segments)}`, 'font-weight: bold');
    }
  }
  console.groupEnd();
};

const writeNavState = async (root, chain, direction, index, changed = false, animation) => {
  try {
    // find next navigation outlet in the DOM
    const outlet = searchNavNode(root);
    // make sure we can continue interacting the DOM, otherwise abort
    if (index >= chain.length || !outlet) {
      return changed;
    }
    await new Promise(resolve => helpers.componentOnReady(outlet, resolve));
    const route = chain[index];
    const result = await outlet.setRouteId(route.id, route.params, direction, animation);
    // if the outlet changed the page, reset navigation to neutral (no direction)
    // this means nested outlets will not animate
    if (result.changed) {
      direction = ROUTER_INTENT_NONE;
      changed = true;
    }
    // recursively set nested outlets
    changed = await writeNavState(result.element, chain, direction, index + 1, changed, animation);
    // once all nested outlets are visible let's make the parent visible too,
    // using markVisible prevents flickering
    if (result.markVisible) {
      await result.markVisible();
    }
    return changed;
  }
  catch (e) {
    console.error(e);
    return false;
  }
};
const readNavState = async (root) => {
  const ids = [];
  let outlet;
  let node = root;
  // tslint:disable-next-line:no-constant-condition
  while (true) {
    outlet = searchNavNode(node);
    if (outlet) {
      const id = await outlet.getRouteId();
      if (id) {
        node = id.element;
        id.element = undefined;
        ids.push(id);
      }
      else {
        break;
      }
    }
    else {
      break;
    }
  }
  return { ids, outlet };
};
const waitUntilNavNode = () => {
  if (searchNavNode(document.body)) {
    return Promise.resolve();
  }
  return new Promise(resolve => {
    window.addEventListener('ionNavWillLoad', resolve, { once: true });
  });
};
const QUERY = ':not([no-router]) ion-nav, :not([no-router]) ion-tabs, :not([no-router]) ion-router-outlet';
const searchNavNode = (root) => {
  if (!root) {
    return undefined;
  }
  if (root.matches(QUERY)) {
    return root;
  }
  const outlet = root.querySelector(QUERY);
  return outlet !== null && outlet !== void 0 ? outlet : undefined;
};

// Returns whether the given redirect matches the given path segments.
//
// A redirect matches when the segments of the path and redirect.from are equal.
// Note that segments are only checked until redirect.from contains a '*' which matches any path segment.
// The path ['some', 'path', 'to', 'page'] matches both ['some', 'path', 'to', 'page'] and ['some', 'path', '*'].
const matchesRedirect = (path, redirect) => {
  const { from, to } = redirect;
  if (to === undefined) {
    return false;
  }
  if (from.length > path.length) {
    return false;
  }
  for (let i = 0; i < from.length; i++) {
    const expected = from[i];
    if (expected === '*') {
      return true;
    }
    if (expected !== path[i]) {
      return false;
    }
  }
  return from.length === path.length;
};
// Returns the first redirect matching the path segments or undefined when no match found.
const findRouteRedirect = (path, redirects) => {
  return redirects.find(redirect => matchesRedirect(path, redirect));
};
const matchesIDs = (ids, chain) => {
  const len = Math.min(ids.length, chain.length);
  let i = 0;
  for (; i < len; i++) {
    if (ids[i].toLowerCase() !== chain[i].id) {
      break;
    }
  }
  return i;
};
const matchesPath = (inputPath, chain) => {
  const segments = new RouterSegments(inputPath);
  let matchesDefault = false;
  let allparams;
  for (let i = 0; i < chain.length; i++) {
    const path = chain[i].path;
    if (path[0] === '') {
      matchesDefault = true;
    }
    else {
      for (const segment of path) {
        const data = segments.next();
        // data param
        if (segment[0] === ':') {
          if (data === '') {
            return null;
          }
          allparams = allparams || [];
          const params = allparams[i] || (allparams[i] = {});
          params[segment.slice(1)] = data;
        }
        else if (data !== segment) {
          return null;
        }
      }
      matchesDefault = false;
    }
  }
  const matches = (matchesDefault)
    ? matchesDefault === (segments.next() === '')
    : true;
  if (!matches) {
    return null;
  }
  if (allparams) {
    return chain.map((route, i) => ({
      id: route.id,
      path: route.path,
      params: mergeParams(route.params, allparams[i]),
      beforeEnter: route.beforeEnter,
      beforeLeave: route.beforeLeave
    }));
  }
  return chain;
};
// Merges the route parameter objects.
// Returns undefined when both parameters are undefined.
const mergeParams = (a, b) => {
  return a || b ? Object.assign(Object.assign({}, a), b) : undefined;
};
const routerIDsToChain = (ids, chains) => {
  let match = null;
  let maxMatches = 0;
  const plainIDs = ids.map(i => i.id);
  for (const chain of chains) {
    const score = matchesIDs(plainIDs, chain);
    if (score > maxMatches) {
      match = chain;
      maxMatches = score;
    }
  }
  if (match) {
    return match.map((route, i) => ({
      id: route.id,
      path: route.path,
      params: mergeParams(route.params, ids[i] && ids[i].params)
    }));
  }
  return null;
};
const routerPathToChain = (path, chains) => {
  let match = null;
  let matches = 0;
  for (const chain of chains) {
    const matchedChain = matchesPath(path, chain);
    if (matchedChain !== null) {
      const score = computePriority(matchedChain);
      if (score > matches) {
        matches = score;
        match = matchedChain;
      }
    }
  }
  return match;
};
const computePriority = (chain) => {
  let score = 1;
  let level = 1;
  for (const route of chain) {
    for (const path of route.path) {
      if (path[0] === ':') {
        score += Math.pow(1, level);
      }
      else if (path !== '') {
        score += Math.pow(2, level);
      }
      level++;
    }
  }
  return score;
};
class RouterSegments {
  constructor(path) {
    this.path = path.slice();
  }
  next() {
    if (this.path.length > 0) {
      return this.path.shift();
    }
    return '';
  }
}

const readProp = (el, prop) => {
  if (prop in el) {
    return el[prop];
  }
  if (el.hasAttribute(prop)) {
    return el.getAttribute(prop);
  }
  return null;
};
const readRedirects = (root) => {
  return Array.from(root.children)
    .filter(el => el.tagName === 'ION-ROUTE-REDIRECT')
    .map(el => {
    const to = readProp(el, 'to');
    return {
      from: parsePath(readProp(el, 'from')).segments,
      to: to == null ? undefined : parsePath(to),
    };
  });
};
const readRoutes = (root) => {
  return flattenRouterTree(readRouteNodes(root));
};
const readRouteNodes = (node) => {
  return Array.from(node.children)
    .filter(el => el.tagName === 'ION-ROUTE' && el.component)
    .map(el => {
    const component = readProp(el, 'component');
    return {
      path: parsePath(readProp(el, 'url')).segments,
      id: component.toLowerCase(),
      params: el.componentProps,
      beforeLeave: el.beforeLeave,
      beforeEnter: el.beforeEnter,
      children: readRouteNodes(el)
    };
  });
};
const flattenRouterTree = (nodes) => {
  const chains = [];
  for (const node of nodes) {
    flattenNode([], chains, node);
  }
  return chains;
};
const flattenNode = (chain, chains, node) => {
  chain = chain.slice();
  chain.push({
    id: node.id,
    path: node.path,
    params: node.params,
    beforeLeave: node.beforeLeave,
    beforeEnter: node.beforeEnter
  });
  if (node.children.length === 0) {
    chains.push(chain);
    return;
  }
  for (const child of node.children) {
    flattenNode(chain, chains, child);
  }
};

const Router = class {
  constructor(hostRef) {
    index.registerInstance(this, hostRef);
    this.ionRouteWillChange = index.createEvent(this, "ionRouteWillChange", 7);
    this.ionRouteDidChange = index.createEvent(this, "ionRouteDidChange", 7);
    this.previousPath = null;
    this.busy = false;
    this.state = 0;
    this.lastState = 0;
    /**
     * By default `ion-router` will match the routes at the root path ("/").
     * That can be changed when
     *
     */
    this.root = '/';
    /**
     * The router can work in two "modes":
     * - With hash: `/index.html#/path/to/page`
     * - Without hash: `/path/to/page`
     *
     * Using one or another might depend in the requirements of your app and/or where it's deployed.
     *
     * Usually "hash-less" navigation works better for SEO and it's more user friendly too, but it might
     * requires additional server-side configuration in order to properly work.
     *
     * On the other side hash-navigation is much easier to deploy, it even works over the file protocol.
     *
     * By default, this property is `true`, change to `false` to allow hash-less URLs.
     */
    this.useHash = true;
  }
  async componentWillLoad() {
    await waitUntilNavNode();
    const canProceed = await this.runGuards(this.getPath());
    if (canProceed !== true) {
      if (typeof canProceed === 'object') {
        const { redirect } = canProceed;
        const path = parsePath(redirect);
        this.setPath(path.segments, ROUTER_INTENT_NONE, path.queryString);
        await this.writeNavStateRoot(path.segments, ROUTER_INTENT_NONE);
      }
    }
    else {
      await this.onRoutesChanged();
    }
  }
  componentDidLoad() {
    window.addEventListener('ionRouteRedirectChanged', helpers.debounce(this.onRedirectChanged.bind(this), 10));
    window.addEventListener('ionRouteDataChanged', helpers.debounce(this.onRoutesChanged.bind(this), 100));
  }
  async onPopState() {
    const direction = this.historyDirection();
    let segments = this.getPath();
    const canProceed = await this.runGuards(segments);
    if (canProceed !== true) {
      if (typeof canProceed === 'object') {
        segments = parsePath(canProceed.redirect).segments;
      }
      else {
        return false;
      }
    }
    return this.writeNavStateRoot(segments, direction);
  }
  onBackButton(ev) {
    ev.detail.register(0, processNextHandler => {
      this.back();
      processNextHandler();
    });
  }
  /** @internal */
  async canTransition() {
    const canProceed = await this.runGuards();
    if (canProceed !== true) {
      if (typeof canProceed === 'object') {
        return canProceed.redirect;
      }
      else {
        return false;
      }
    }
    return true;
  }
  /**
   * Navigate to the specified URL.
   *
   * @param url The url to navigate to.
   * @param direction The direction of the animation. Defaults to `"forward"`.
   */
  async push(url, direction = 'forward', animation) {
    if (url.startsWith('.')) {
      url = (new URL(url, window.location.href)).pathname;
    }
    let parsedPath = parsePath(url);
    const canProceed = await this.runGuards(parsedPath.segments);
    if (canProceed !== true) {
      if (typeof canProceed === 'object') {
        parsedPath = parsePath(canProceed.redirect);
      }
      else {
        return false;
      }
    }
    this.setPath(parsedPath.segments, direction, parsedPath.queryString);
    return this.writeNavStateRoot(parsedPath.segments, direction, animation);
  }
  /**
   * Go back to previous page in the window.history.
   */
  back() {
    window.history.back();
    return Promise.resolve(this.waitPromise);
  }
  /** @internal */
  async printDebug() {
    printRoutes(readRoutes(this.el));
    printRedirects(readRedirects(this.el));
  }
  /** @internal */
  async navChanged(direction) {
    if (this.busy) {
      console.warn('[ion-router] router is busy, navChanged was cancelled');
      return false;
    }
    const { ids, outlet } = await readNavState(window.document.body);
    const routes = readRoutes(this.el);
    const chain = routerIDsToChain(ids, routes);
    if (!chain) {
      console.warn('[ion-router] no matching URL for ', ids.map(i => i.id));
      return false;
    }
    const path = chainToPath(chain);
    if (!path) {
      console.warn('[ion-router] router could not match path because some required param is missing');
      return false;
    }
    this.setPath(path, direction);
    await this.safeWriteNavState(outlet, chain, ROUTER_INTENT_NONE, path, null, ids.length);
    return true;
  }
  // This handler gets called when a `ion-route-redirect` component is added to the DOM or if the from or to property of such node changes.
  onRedirectChanged() {
    const path = this.getPath();
    if (path && findRouteRedirect(path, readRedirects(this.el))) {
      this.writeNavStateRoot(path, ROUTER_INTENT_NONE);
    }
  }
  // This handler gets called when a `ion-route` component is added to the DOM or if the from or to property of such node changes.
  onRoutesChanged() {
    return this.writeNavStateRoot(this.getPath(), ROUTER_INTENT_NONE);
  }
  historyDirection() {
    var _a;
    const win = window;
    if (win.history.state === null) {
      this.state++;
      win.history.replaceState(this.state, win.document.title, (_a = win.document.location) === null || _a === void 0 ? void 0 : _a.href);
    }
    const state = win.history.state;
    const lastState = this.lastState;
    this.lastState = state;
    if (state > lastState || (state >= lastState && lastState > 0)) {
      return ROUTER_INTENT_FORWARD;
    }
    if (state < lastState) {
      return ROUTER_INTENT_BACK;
    }
    return ROUTER_INTENT_NONE;
  }
  async writeNavStateRoot(path, direction, animation) {
    if (!path) {
      console.error('[ion-router] URL is not part of the routing set');
      return false;
    }
    // lookup redirect rule
    const redirects = readRedirects(this.el);
    const redirect = findRouteRedirect(path, redirects);
    let redirectFrom = null;
    if (redirect) {
      const { segments, queryString } = redirect.to;
      this.setPath(segments, direction, queryString);
      redirectFrom = redirect.from;
      path = segments;
    }
    // lookup route chain
    const routes = readRoutes(this.el);
    const chain = routerPathToChain(path, routes);
    if (!chain) {
      console.error('[ion-router] the path does not match any route');
      return false;
    }
    // write DOM give
    return this.safeWriteNavState(document.body, chain, direction, path, redirectFrom, 0, animation);
  }
  async safeWriteNavState(node, chain, direction, path, redirectFrom, index = 0, animation) {
    const unlock = await this.lock();
    let changed = false;
    try {
      changed = await this.writeNavState(node, chain, direction, path, redirectFrom, index, animation);
    }
    catch (e) {
      console.error(e);
    }
    unlock();
    return changed;
  }
  async lock() {
    const p = this.waitPromise;
    let resolve;
    this.waitPromise = new Promise(r => resolve = r);
    if (p !== undefined) {
      await p;
    }
    return resolve;
  }
  // Executes the beforeLeave hook of the source route and the beforeEnter hook of the target route if they exist.
  //
  // When the beforeLeave hook does not return true (to allow navigating) then that value is returned early and the beforeEnter is executed.
  // Otherwise the beforeEnterHook hook of the target route is executed.
  async runGuards(to = this.getPath(), from) {
    if (from === undefined) {
      from = parsePath(this.previousPath).segments;
    }
    if (!to || !from) {
      return true;
    }
    const routes = readRoutes(this.el);
    const fromChain = routerPathToChain(from, routes);
    const beforeLeaveHook = fromChain && fromChain[fromChain.length - 1].beforeLeave;
    const canLeave = beforeLeaveHook ? await beforeLeaveHook() : true;
    if (canLeave === false || typeof canLeave === 'object') {
      return canLeave;
    }
    const toChain = routerPathToChain(to, routes);
    const beforeEnterHook = toChain && toChain[toChain.length - 1].beforeEnter;
    return beforeEnterHook ? beforeEnterHook() : true;
  }
  async writeNavState(node, chain, direction, path, redirectFrom, index = 0, animation) {
    if (this.busy) {
      console.warn('[ion-router] router is busy, transition was cancelled');
      return false;
    }
    this.busy = true;
    // generate route event and emit will change
    const routeEvent = this.routeChangeEvent(path, redirectFrom);
    if (routeEvent) {
      this.ionRouteWillChange.emit(routeEvent);
    }
    const changed = await writeNavState(node, chain, direction, index, false, animation);
    this.busy = false;
    // emit did change
    if (routeEvent) {
      this.ionRouteDidChange.emit(routeEvent);
    }
    return changed;
  }
  setPath(path, direction, queryString) {
    this.state++;
    writePath(window.history, this.root, this.useHash, path, direction, this.state, queryString);
  }
  getPath() {
    return readPath(window.location, this.root, this.useHash);
  }
  routeChangeEvent(path, redirectFromPath) {
    const from = this.previousPath;
    const to = generatePath(path);
    this.previousPath = to;
    if (to === from) {
      return null;
    }
    const redirectedFrom = redirectFromPath ? generatePath(redirectFromPath) : null;
    return {
      from,
      redirectedFrom,
      to,
    };
  }
  get el() { return index.getElement(this); }
};

const routerLinkCss = ":host{--background:transparent;--color:var(--ion-color-primary, #3880ff);background:var(--background);color:var(--color)}:host(.ion-color){color:var(--ion-color-base)}a{font-family:inherit;font-size:inherit;font-style:inherit;font-weight:inherit;letter-spacing:inherit;text-decoration:inherit;text-indent:inherit;text-overflow:inherit;text-transform:inherit;text-align:inherit;white-space:inherit;color:inherit}";

const RouterLink = class {
  constructor(hostRef) {
    index.registerInstance(this, hostRef);
    /**
     * When using a router, it specifies the transition direction when navigating to
     * another page using `href`.
     */
    this.routerDirection = 'forward';
    this.onClick = (ev) => {
      theme.openURL(this.href, ev, this.routerDirection, this.routerAnimation);
    };
  }
  render() {
    const mode = ionicGlobal.getIonMode(this);
    const attrs = {
      href: this.href,
      rel: this.rel,
      target: this.target
    };
    return (index.h(index.Host, { onClick: this.onClick, class: theme.createColorClasses(this.color, {
        [mode]: true,
        'ion-activatable': true
      }) }, index.h("a", Object.assign({}, attrs), index.h("slot", null))));
  }
};
RouterLink.style = routerLinkCss;

exports.ion_route = Route;
exports.ion_route_redirect = RouteRedirect;
exports.ion_router = Router;
exports.ion_router_link = RouterLink;
