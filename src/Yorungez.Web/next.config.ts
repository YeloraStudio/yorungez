import type { NextConfig } from "next";
const config: NextConfig = {
  distDir: process.env.YORUNGEZ_BUILD_DIR === ".next-preview" ? ".next-preview" : ".next",
  poweredByHeader: false,
  reactStrictMode: true,
  serverExternalPackages: ["geo-tz"],
  async headers() {
    return [{source:"/sw.js",headers:[{key:"Cache-Control",value:"no-store, no-cache, must-revalidate"},{key:"Content-Type",value:"application/javascript; charset=utf-8"}]},{source:"/pwa-pack.json",headers:[{key:"Cache-Control",value:"no-store"}]},{ source: "/:path*", headers: [
      { key: "X-Content-Type-Options", value: "nosniff" },
      { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
      { key: "Permissions-Policy", value: "camera=(self), microphone=(), accelerometer=(self), gyroscope=(self), magnetometer=(self), geolocation=(self)" }
    ] },{source:"/:lang/account/:action",headers:[{key:"Cache-Control",value:"no-store, private"},{key:"Referrer-Policy",value:"no-referrer"}]}];
  }
};
export default config;
