/** @type {import('next').NextConfig} */
const nextConfig = {
  env: {
    SIKANUA_API_URL: process.env.SIKANUA_API_URL || "http://localhost:8000",
  },
};

module.exports = nextConfig;
