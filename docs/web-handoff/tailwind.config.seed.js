/**
 * Seed Tailwind config for mss-web, generated from the Flutter app's design
 * tokens (see 01-DESIGN-SYSTEM.md for the source values and rationale).
 *
 * Copy this file into the new Next.js project as `tailwind.config.js` and
 * adjust `content` paths to match the project's actual file layout.
 */

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: "#2563EB",
        secondary: "#1565C0",
        accent: "#FF9933",
        success: "#2E7D32",
        warning: "#FB8C00",
        error: "#D32F2F",
        background: "#F8FAFC",
        surface: "#FFFFFF",
        border: "#E5E7EB",
        "text-primary": "#111827",
        "text-secondary": "#6B7280",
      },
      spacing: {
        hairline: "2px",
        xs: "4px",
        tight: "6px",
        sm: "8px",
        md: "12px",
        lg: "16px",
        xl: "20px",
        xxl: "24px",
        xxxl: "32px",
      },
      borderRadius: {
        card: "16px",
        pill: "9999px",
        control: "12px",
      },
      backgroundImage: {
        "blue-gradient":
          "linear-gradient(135deg, #F8FAFC 0%, #E0F2FE 50%, #EFF6FF 100%)",
        "glass-gradient":
          "linear-gradient(135deg, rgba(255,255,255,0.7) 0%, rgba(255,255,255,0.6) 100%)",
      },
      fontFamily: {
        // Load via next/font/google in the app; these names just need to
        // match whatever CSS variable / font-family you register there.
        heading: ["Poppins", "sans-serif"],
        body: ["Inter", "sans-serif"],
        "heading-ta": ["Arima", "sans-serif"],
        "body-ta": ["Noto Sans Tamil", "sans-serif"],
      },
      fontSize: {
        "display-lg": ["28px", { lineHeight: "1.3", fontWeight: "700" }],
        "headline-md": ["22px", { lineHeight: "1.3", fontWeight: "700" }],
        "title-md": ["16px", { lineHeight: "1.3", fontWeight: "600" }],
        "body-regular": ["14px", { lineHeight: "1.45", fontWeight: "400" }],
        "body-sm": ["12px", { lineHeight: "1.4", fontWeight: "500" }],
        "label-sm": ["10.5px", { lineHeight: "1.25", fontWeight: "700" }],
      },
    },
  },
  plugins: [],
};
