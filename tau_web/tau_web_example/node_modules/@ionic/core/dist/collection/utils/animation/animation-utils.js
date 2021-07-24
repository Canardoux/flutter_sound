let animationPrefix;
/**
 * Web Animations requires hyphenated CSS properties
 * to be written in camelCase when animating
 */
export const processKeyframes = (keyframes) => {
  keyframes.forEach(keyframe => {
    for (const key in keyframe) {
      if (keyframe.hasOwnProperty(key)) {
        const value = keyframe[key];
        if (key === 'easing') {
          const newKey = 'animation-timing-function';
          keyframe[newKey] = value;
          delete keyframe[key];
        }
        else {
          const newKey = convertCamelCaseToHypen(key);
          if (newKey !== key) {
            keyframe[newKey] = value;
            delete keyframe[key];
          }
        }
      }
    }
  });
  return keyframes;
};
const convertCamelCaseToHypen = (str) => {
  return str.replace(/([a-z0-9])([A-Z])/g, '$1-$2').toLowerCase();
};
export const getAnimationPrefix = (el) => {
  if (animationPrefix === undefined) {
    const supportsUnprefixed = el.style.animationName !== undefined;
    const supportsWebkitPrefix = el.style.webkitAnimationName !== undefined;
    animationPrefix = (!supportsUnprefixed && supportsWebkitPrefix) ? '-webkit-' : '';
  }
  return animationPrefix;
};
export const setStyleProperty = (element, propertyName, value) => {
  const prefix = propertyName.startsWith('animation') ? getAnimationPrefix(element) : '';
  element.style.setProperty(prefix + propertyName, value);
};
export const removeStyleProperty = (element, propertyName) => {
  const prefix = propertyName.startsWith('animation') ? getAnimationPrefix(element) : '';
  element.style.removeProperty(prefix + propertyName);
};
export const animationEnd = (el, callback) => {
  let unRegTrans;
  const opts = { passive: true };
  const unregister = () => {
    if (unRegTrans) {
      unRegTrans();
    }
  };
  const onTransitionEnd = (ev) => {
    if (el === ev.target) {
      unregister();
      callback(ev);
    }
  };
  if (el) {
    el.addEventListener('webkitAnimationEnd', onTransitionEnd, opts);
    el.addEventListener('animationend', onTransitionEnd, opts);
    unRegTrans = () => {
      el.removeEventListener('webkitAnimationEnd', onTransitionEnd, opts);
      el.removeEventListener('animationend', onTransitionEnd, opts);
    };
  }
  return unregister;
};
export const generateKeyframeRules = (keyframes = []) => {
  return keyframes.map(keyframe => {
    const offset = keyframe.offset;
    const frameString = [];
    for (const property in keyframe) {
      if (keyframe.hasOwnProperty(property) && property !== 'offset') {
        frameString.push(`${property}: ${keyframe[property]};`);
      }
    }
    return `${offset * 100}% { ${frameString.join(' ')} }`;
  }).join(' ');
};
const keyframeIds = [];
export const generateKeyframeName = (keyframeRules) => {
  let index = keyframeIds.indexOf(keyframeRules);
  if (index < 0) {
    index = (keyframeIds.push(keyframeRules) - 1);
  }
  return `ion-animation-${index}`;
};
export const getStyleContainer = (element) => {
  const rootNode = element.getRootNode();
  return (rootNode.head || rootNode);
};
export const createKeyframeStylesheet = (keyframeName, keyframeRules, element) => {
  const styleContainer = getStyleContainer(element);
  const keyframePrefix = getAnimationPrefix(element);
  const existingStylesheet = styleContainer.querySelector('#' + keyframeName);
  if (existingStylesheet) {
    return existingStylesheet;
  }
  const stylesheet = (element.ownerDocument || document).createElement('style');
  stylesheet.id = keyframeName;
  stylesheet.textContent = `@${keyframePrefix}keyframes ${keyframeName} { ${keyframeRules} } @${keyframePrefix}keyframes ${keyframeName}-alt { ${keyframeRules} }`;
  styleContainer.appendChild(stylesheet);
  return stylesheet;
};
export const addClassToArray = (classes = [], className) => {
  if (className !== undefined) {
    const classNameToAppend = (Array.isArray(className)) ? className : [className];
    return [...classes, ...classNameToAppend];
  }
  return classes;
};
