/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: '#111827', // App Light Primary (Charcoal)
        secondary: '#06C167', // App Light Secondary (Brand Green)
        tertiary: '#10B981', // App Light Tertiary (Mint Green)
        dark: '#0B0F14', // App Dark Surface
        light: '#F3F4F6', // App Light Surface
        surface: '#FFFFFF', // App Light Card Background
      },
      fontFamily: {
        sans: ['Inter', 'sans-serif'],
      },
    },
  },
  plugins: [],
}