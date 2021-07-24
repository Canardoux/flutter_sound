# @vue/eslint-config-typescript

> eslint-config-typescript for vue-cli

See [@typescript-eslint/eslint-plugin](https://typescript-eslint.io/eslint-plugin) for available rules.

This config is specifically designed to be used by Vue CLI setups
and is not meant for outside use (it can be used but some adaptations
on the user side might be needed - for details see the config file).

A part of its design is that this config may implicitly depend on
other parts of Vue CLI setups, such as `eslint-plugin-vue` being
extended in the same resulting config.

## Installation

This config requires several peer dependencies. So it's recommended to use the `install-peerdeps` command:

```sh
npx install-peerdeps --dev @vue/eslint-config-typescript
```

## Usage

This package comes with 2 rulesets.

### `@vue/eslint-config-typescript`

This ruleset is the base configuration for Vue-TypeScript projects.
Besides setting the parser and plugin options, it also turns off several conflicting rules in the `eslint:recommended` ruleset.
So when used alongside other sharable configs, this config should be placed at the end of the `extends` array.

An example `.eslintrc.js`:

```js
module.exports = {
  extends: [
    'plugin:vue/essential',
    'eslint:recommended',
    '@vue/typescript'
  ]
}
```

### `@vue/eslint-config-typescript/recommended`

This is extended from the `@typescript-eslint/recommended` ruleset, which is an **_opinionated_** ruleset.
See the [originial documentation](https://github.com/typescript-eslint/typescript-eslint/tree/master/packages/eslint-plugin/src/configs#recommended) for more information.

Some of its rules, however, might conflict with `prettier`.
So when used alongside other sharable configs, this config should be placed after all other configs except for the `prettier` ones in the `extends` array.
And make sure to also include the `@typescript-eslint` sub ruleset of the `prettier` config.

An example `.eslintrc.js`:

```js
module.exports = {
  extends: [
    'plugin:vue/essential',
    '@vue/airbnb',
    '@vue/typescript/recommended',

    '@vue/prettier',
    '@vue/prettier/@typescript-eslint'
  ]
}
```
