const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const KEY = Buffer.from('IZIVPN_AES_KEY_32BYTES_PROD_2026', 'utf8');
const IV = Buffer.from('IZIVPN_IV_16BYTE', 'utf8');

const rawPath = path.join(__dirname, '..', 'servers_raw.json');
const outPath = path.join(__dirname, '..', 'servers.json');

if (!fs.existsSync(rawPath)) {
  console.error('Error: servers_raw.json not found at ' + rawPath);
  process.exit(1);
}

const rawContent = fs.readFileSync(rawPath, 'utf8');
const cipher = crypto.createCipheriv('aes-256-cbc', KEY, IV);
let encrypted = cipher.update(rawContent, 'utf8', 'base64');
encrypted += cipher.final('base64');

fs.writeFileSync(outPath, encrypted, 'utf8');
console.log('✅ Successfully encrypted servers_raw.json -> servers.json (' + encrypted.length + ' chars)');

// Self-test verification:
const decipher = crypto.createDecipheriv('aes-256-cbc', KEY, IV);
let decrypted = decipher.update(encrypted, 'base64', 'utf8');
decrypted += decipher.final('utf8');
const parsed = JSON.parse(decrypted);
const count = Array.isArray(parsed) ? parsed.length : (parsed.servers ? parsed.servers.length : 0);
console.log('✅ Self-test verified: successfully decrypted ' + count + ' servers.');
