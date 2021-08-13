module.exports = {
  // extends: "stylelint-config-standard",
  plugins: ["stylelint-scss"],
  rules: {
    "at-rule-no-unknown": [
      true,
      {
        ignoreAtRules: [
          "tailwind",
          "apply",
          "variants",
          "responsive",
          "screen",
        ],
      },
    ],
    "declaration-block-trailing-semicolon": null,
    "no-descending-specificity": null,
    "declaration-empty-line-before": null,
    "rule-empty-line-before": null
  },
};
