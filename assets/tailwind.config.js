// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin");

module.exports = {
  content: ["./js/**/*.js", "../lib/roomy_web.ex", "../lib/roomy_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        bubble_1: "#E0F1CF",
        bubble_1_dark: "#D4ECBC",
        bubble_2: "#E0CFF1",
        bubble_2_dark: "#D4BCEC",
        my_red: "#AD3333",
        my_red_dark: "#942B2B",
        my_blue: "#33ADAD",
        my_blue_dark: "#2B9494",
        my_green: "#70AD33",
        my_green_dark: "#60942B",
        my_purple: "#7033AD",
        my_purple_dark: "#602B94",
        my_purple_very_dark: "#30154A",
        my_purple_very_light: "#F9F5FC",
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
