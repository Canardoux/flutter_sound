const postcss = require('postcss')
const postcssrc = require('postcss-load-config')
const ctx = { parser: true, map: 'inline' }
const { plugins } = postcssrc.sync(ctx)
const logger = require('../logger')
const getVueJestConfig = require('../get-vue-jest-config')
const ensureRequire = require('../ensure-require')

let prevCheckIsAsync = null
function hasAsyncPlugin () {
  if (prevCheckIsAsync !== null) {
    return prevCheckIsAsync
  }
  const result = postcss(plugins)
    .process('', {
      from: undefined
    })

  if (result.processing) {
    prevCheckIsAsync = true
    return prevCheckIsAsync
  }
  for (const plugin of result.processor.plugins) {
    const promise = result.run(plugin)
    if (typeof promise === 'object' && typeof promise.then === 'function') {
      prevCheckIsAsync = true
      break
    }
  }
  if (prevCheckIsAsync === null) {
    prevCheckIsAsync = false
  }

  return prevCheckIsAsync
}

function catchError (error, filePath, jestConfig) {
  if (!getVueJestConfig(jestConfig).hideStyleWarn) {
    logger.warn(`There was an error rendering the POSTCSS in ${filePath}. `)
    logger.warn(`Error while compiling styles: ${error}`)
  }
}

module.exports = (content, filePath, jestConfig) => {
  ensureRequire('postcss', ['postcss'])

  let css = null

  const res = postcss(plugins)
    .process(content, {
      from: undefined
    })

  if (hasAsyncPlugin()) {
    res
      .then(result => {
        css = result.css || ''
      })
      .catch((e) => {
        css = ''
        catchError(e, filePath, jestConfig)
      })

    while (css === null) { //eslint-disable-line
      require('deasync').sleep(100)
    }

    return css
  }

  try {
    return res.css
  } catch (e) {
    catchError(e, filePath, jestConfig)
    return ''
  }
}
