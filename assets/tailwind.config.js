// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");

module.exports = {
  content: ["./js/**/*.js", "../lib/roomy_web.ex", "../lib/roomy_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        brand: "#FD4F00",
        my_gray: "#F1F0F3",
        bubble_1: "#EDDBDB",
        bubble_2: "#D7EDC1",
        bubble_1_dark: "#E4D1D1",
        bubble_2_dark: "#CAE3B7",
        purple: "#1B0036",
        dark: "#250036",
      },
      animation: {
        bounce: "bounce 1.5s infinite",
      },
      keyframes: {
        bounce: {
          "0%, 80%, 100%": { transform: "scale(0)" },
          "40%": { transform: "scale(1)" },
        },
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant("phx-click-loading", [
        ".phx-click-loading&",
        ".phx-click-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-submit-loading", [
        ".phx-submit-loading&",
        ".phx-submit-loading &",
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant("phx-change-loading", [
        ".phx-change-loading&",
        ".phx-change-loading &",
      ])
    ),
  ],
};
