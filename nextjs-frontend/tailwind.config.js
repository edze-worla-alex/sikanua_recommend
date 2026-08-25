/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        forest:  { DEFAULT: "#1A6B3C", light: "#D6EFE0", dark: "#134f2d" },
        sage:    { DEFAULT: "#2E8B57" },
        amber:   { DEFAULT: "#F4A72A", light: "#FEF3D7" },
        ink:     { DEFAULT: "#1C2B24" },
      },
      fontFamily: {
        sans:    ["var(--font-inter)", "system-ui", "sans-serif"],
        display: ["var(--font-sora)",  "system-ui", "sans-serif"],
        mono:    ["var(--font-mono)",  "monospace"],
      },
      animation: {
        "fade-up":   "fadeUp 0.5s ease forwards",
        "pulse-dot": "pulseDot 1.4s ease-in-out infinite",
      },
      keyframes: {
        fadeUp: {
          "0%":   { opacity: "0", transform: "translateY(12px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        pulseDot: {
          "0%, 80%, 100%": { transform: "scale(0.6)", opacity: "0.4" },
          "40%":            { transform: "scale(1.0)", opacity: "1" },
        },
      },
    },
  },
  plugins: [],
};
