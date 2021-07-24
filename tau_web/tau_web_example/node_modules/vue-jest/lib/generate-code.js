const { SourceNode, SourceMapConsumer } = require('source-map')

function addToSourceMap(node, result) {
  if (result && result.code) {
    if (result.map) {
      node.add(
        SourceNode.fromStringWithSourceMap(
          result.code,
          new SourceMapConsumer(result.map)
        )
      )
    } else {
      node.add(result.code)
    }
  }
}

module.exports = function generateCode(
  scriptResult,
  scriptSetupResult,
  templateResult,
  filename,
  stylesResult
) {
  var node = new SourceNode(null, null, null)
  addToSourceMap(node, scriptResult)
  addToSourceMap(node, scriptSetupResult)
  addToSourceMap(node, templateResult)

  var tempOutput = node.toString()

  if (
    // vue-property-decorator also exports Vue, which can be used to create a class component.
    // In that case vue-class-component is not present in the tempOutput.
    tempOutput.includes('vue-class-component') ||
    tempOutput.includes('vue-property-decorator')
  ) {
    node.add(`
      ;exports.default = {
      ...exports.default.__vccBase,
      ...exports.default.__vccOpts
    };`)
  }

  if (tempOutput.includes('exports.render = render;')) {
    node.add(';exports.default = {...exports.default, render};')
  } else {
    // node.add(';exports.default = {...exports.default};')
  }
  if (Array.isArray(stylesResult)) {
    const mergedStyle = {}
    stylesResult.forEach(styleObj => {
      const { code, moduleName } = styleObj
      mergedStyle[moduleName] = {
        ...(mergedStyle[moduleName] || {}),
        ...(JSON.parse(code) || {})
      }
    })
    node.add(
      `;exports.default = {...exports.default, __cssModules: ${JSON.stringify(
        mergedStyle
      )}}`
    )
  }

  return node.toStringWithSourceMap({ file: filename })
}
