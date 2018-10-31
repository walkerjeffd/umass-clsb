module.exports = {
  root: true,
  env: {
    node: true
  },
  'extends': [
    'plugin:vue/essential',
    '@vue/airbnb'
  ],
  globals: {
    'L': true
  },
  rules: {
    'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'no-param-reassign': 'off',
    'comma-dangle': 'off',
    'no-alert': 'off',
    'no-plusplus': 'off',
    'consistent-return': 'off',
    'prefer-destructuring': 'off',
    'object-shorthand': 'off',
    'max-len': 'off'
  },
  parserOptions: {
    parser: 'babel-eslint'
  }
}