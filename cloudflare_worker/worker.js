/**
 * Cloudflare Worker for izi VPN Server Distribution
 * 
 * Features:
 * 1. Resilient edge distribution across Cloudflare's global network
 * 2. Fetches fresh servers from GitHub / jsDelivr with edge caching
 * 3. Base64 encoding option to bypass DPI / censorship filters
 * 4. Direct JSON response for the Flutter app
 */

// Fallback servers directly embedded in worker in case upstream is unreachable
const FALLBACK_SERVERS = [
  {
    "id": "msK8E5pqOetnJ4uMmuV3",
    "serverName": "Germany Server 1",
    "country": "Germany",
    "flag": "de",
    "vip": false,
    "config": "vless://50414e45-4c5f-5a45-5553-df0ccb215ccc@147.78.140.109:2083?path=%2Fstream%2FPANEL_ZEUS%2Fdf0ccb215ccc&security=tls&encryption=none&host=bvzh11e2unzs.m-ds7yf-5n5l7t43sh77kw8.workers.dev&fp=unsafe&type=ws&sni=bvzh11e2unzs.m-ds7yf-5n5l7t43sh77kw8.workers.dev#ZEUS%20%7C%20%F0%9F%8C%90%20%7C%20non-ip"
  },
  {
    "id": "JN86fApY49mMGnD6AmBH",
    "serverName": "United States 2 (Kansas City)",
    "country": "United States",
    "flag": "us",
    "vip": false,
    "config": "vless://e55f018b-62e1-4319-8fbe-9e263b0e5631@grimness-backlogs.cdn-content.com:443?encryption=none&type=ws&path=%2Fws&host=grimness-backlogs.cdn-content.com&security=tls&sni=grimness-backlogs.cdn-content.com&fp=chrome&alpn=http%2F1.1#FreeSocks%20%C2%B7%20Kansas%20City%20%C2%B7%20CEAK"
  }
];

// Primary upstream source on GitHub (via jsDelivr CDN)
const UPSTREAM_URL = "https://cdn.jsdelivr.net/gh/arshamc/izivpn@main/servers.json";

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    const corsHeaders = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
      "Cache-Control": "public, max-age=180", // 3 minutes edge cache
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    let serversJson = "";

    try {
      // 1. Fetch from jsDelivr / GitHub with 4 second timeout
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 4000);

      const upstreamResponse = await fetch(UPSTREAM_URL, {
        signal: controller.signal,
        headers: { "User-Agent": "iziVPN-Worker/1.0" }
      });
      clearTimeout(timeoutId);

      if (upstreamResponse.ok) {
        serversJson = await upstreamResponse.text();
      } else {
        throw new Error("Upstream returned " + upstreamResponse.status);
      }
    } catch (err) {
      // 2. Fallback to embedded servers if upstream is unreachable
      serversJson = JSON.stringify(FALLBACK_SERVERS);
    }

    // Support base64 format to bypass keyword filtering (e.g. ?format=base64)
    if (url.searchParams.get("format") === "base64") {
      const base64Data = btoa(unescape(encodeURIComponent(serversJson)));
      return new Response(base64Data, {
        headers: {
          ...corsHeaders,
          "Content-Type": "text/plain; charset=utf-8"
        }
      });
    }

    // Default: Return JSON
    return new Response(serversJson, {
      headers: {
        ...corsHeaders,
        "Content-Type": "application/json; charset=utf-8"
      }
    });
  }
};
