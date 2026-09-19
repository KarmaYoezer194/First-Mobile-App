// One-time script: copies FakeStoreAPI's product catalog into this
// project's Firestore `products` and `categories` collections, so the app
// owns its catalog data instead of depending on FakeStoreAPI at runtime.
//
// Firestore's REST API is protected by firestore.rules, which (correctly)
// blocks client writes to `products`/`categories` — so this can't run
// against the rules deployed for the live app. See SETUP.md for the
// "flip the rule, run this, flip it back" steps this is meant to be run
// under.
//
// Usage:  node tool/seed_firestore.js
//
// No npm install needed — only built-in Node modules.

const https = require("https");

const PROJECT_ID = "premium-auth-app-97063";
// This is the app's public Web API key (see lib/firebase_options.dart) —
// safe to use here, same as the Flutter app itself does. It identifies the
// project; it does not grant access on its own — Firestore's security
// rules are what decide whether a write succeeds.
const API_KEY = "AIzaSyATFDFrd-1OEh30tA5FHIsoziMpr120NxA";

function get(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => resolve(JSON.parse(data)));
      })
      .on("error", reject);
  });
}

function firestoreWrite(collection, docId, fields) {
  const body = JSON.stringify({ fields: toFirestoreFields(fields) });
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}?documentId=${encodeURIComponent(docId)}&key=${API_KEY}`;

  return new Promise((resolve, reject) => {
    const req = https.request(
      url,
      { method: "POST", headers: { "Content-Type": "application/json" } },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            resolve();
          } else {
            reject(new Error(`${collection}/${docId} -> HTTP ${res.statusCode}: ${data}`));
          }
        });
      },
    );
    req.on("error", reject);
    req.write(body);
    req.end();
  });
}

// Converts a plain JS object into Firestore's typed REST document format.
function toFirestoreFields(obj) {
  const fields = {};
  for (const [key, value] of Object.entries(obj)) {
    fields[key] = toFirestoreValue(value);
  }
  return fields;
}

function toFirestoreValue(value) {
  if (typeof value === "string") return { stringValue: value };
  if (typeof value === "number") {
    return Number.isInteger(value) ? { integerValue: value } : { doubleValue: value };
  }
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map(toFirestoreValue) } };
  }
  throw new Error(`Unsupported value type for Firestore seed: ${typeof value}`);
}

async function main() {
  console.log("Fetching catalog from FakeStoreAPI...");
  const [products, categorySlugs] = await Promise.all([
    get("https://fakestoreapi.com/products"),
    get("https://fakestoreapi.com/products/categories"),
  ]);

  console.log(`Seeding ${categorySlugs.length} categories...`);
  for (const slug of categorySlugs) {
    const name = slug
      .split(" ")
      .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
      .join(" ");
    await firestoreWrite("categories", slug.replace(/\s+/g, "-"), { slug, name });
    process.stdout.write(".");
  }
  console.log();

  console.log(`Seeding ${products.length} products...`);
  for (const p of products) {
    await firestoreWrite("products", String(p.id), {
      id: p.id,
      title: p.title,
      description: p.description,
      price: p.price,
      rating: p.rating?.rate ?? 0,
      stock: 999,
      category: p.category,
      brand: "Unbranded",
      thumbnail: p.image,
      images: [p.image],
      discountPercentage: 0,
    });
    process.stdout.write(".");
  }
  console.log("\nDone.");
}

main().catch((err) => {
  console.error("\nSeed failed:", err.message);
  process.exit(1);
});
