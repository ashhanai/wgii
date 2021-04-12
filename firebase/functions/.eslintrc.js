module.exports = {
	root: true,
	env: {
		es6: true,
		node: true,
	},
	extends: [
		"eslint:recommended",
		"google",
	],
	rules: {
		"quotes": ["error", "double"],
		"indent": ["error", "tab"],
		"object-curly-spacing": ["error", "always"],
		"no-tabs": ["off"],
		"max-len": ["error", { code: 100 }],
		"semi": ["error", "always", { omitLastInOneLineBlock: true }],
		"require-jsdoc": ["off"],
		"no-undef": ["off"],
	},
	parserOptions: {
		ecmaVersion: 8,
	},
};
