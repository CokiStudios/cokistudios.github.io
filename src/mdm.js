//
//  src/mdm.js
//  Coki Studios Native Apple MDM & SHSH Blob Manager
//  Cloudflare Worker implementation for Supervised Devices & ECID/SHSH2 Preservation
//

const SUPABASE_URL = "https://cmkumxprmmhuinxfppxl.supabase.co/rest/v1";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3VteHBybW1odWlueGZwcHhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0OTkxNzEsImV4cCI6MjA5MzA3NTE3MX0.BNbSSxoObXMGpyin4-3udSM6ricoTO57Zaade5dTfxQ";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, HEAD, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, X-CS-Client, X-Mdm-Signature",
  "Timing-Allow-Origin": "*"
};

// ─────────────────────────────────────────────────────────────
// 1. Apple XML Plist Parser & Serializer (Pure Edge JS)
// ─────────────────────────────────────────────────────────────

export function parseApplePlist(xml) {
  if (!xml || typeof xml !== "string") return {};

  const cleanXml = xml
    .replace(/<\?xml[\s\S]*?\?>/i, "")
    .replace(/<!DOCTYPE[\s\S]*?>/i, "")
    .trim();

  const plistMatch = cleanXml.match(/<plist[\s\S]*?>([\s\S]*?)<\/plist>/i);
  const content = (plistMatch ? plistMatch[1] : cleanXml).trim();

  let pos = 0;

  function skipWhitespace() {
    while (pos < content.length && /\s/.test(content[pos])) pos++;
  }

  function parseNext() {
    skipWhitespace();
    if (pos >= content.length) return null;

    if (content.startsWith("<true/>", pos) || content.startsWith("<true></true>", pos)) {
      pos = content.indexOf(">", pos) + 1;
      return true;
    }
    if (content.startsWith("<false/>", pos) || content.startsWith("<false></false>", pos)) {
      pos = content.indexOf(">", pos) + 1;
      return false;
    }
    if (content.startsWith("<dict/>", pos)) {
      pos += 7;
      return {};
    }
    if (content.startsWith("<array/>", pos)) {
      pos += 8;
      return [];
    }

    const tagMatch = content.slice(pos).match(/^<([a-zA-Z0-9]+)>/);
    if (!tagMatch) {
      pos++;
      return null;
    }

    const tagName = tagMatch[1];
    pos += tagMatch[0].length;

    if (tagName === "dict") {
      const dict = {};
      while (pos < content.length) {
        skipWhitespace();
        if (content.startsWith("</dict>", pos)) {
          pos += 7;
          break;
        }
        if (content.startsWith("<key>", pos)) {
          pos += 5;
          const endKey = content.indexOf("</key>", pos);
          const key = content.slice(pos, endKey).trim();
          pos = endKey + 6;
          const val = parseNext();
          dict[key] = val;
        } else {
          pos++;
        }
      }
      return dict;
    }

    if (tagName === "array") {
      const arr = [];
      while (pos < content.length) {
        skipWhitespace();
        if (content.startsWith("</array>", pos)) {
          pos += 8;
          break;
        }
        const val = parseNext();
        if (val !== null) arr.push(val);
      }
      return arr;
    }

    const endTag = `</${tagName}>`;
    const endPos = content.indexOf(endTag, pos);
    const innerText = endPos !== -1 ? content.slice(pos, endPos) : "";
    pos = endPos !== -1 ? endPos + endTag.length : content.length;

    if (tagName === "string") return innerText.replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">");
    if (tagName === "integer") return /^-?\d+$/.test(innerText.trim()) ? parseInt(innerText.trim(), 10) : innerText.trim();
    if (tagName === "real") return parseFloat(innerText.trim());
    if (tagName === "data") return innerText.replace(/\s+/g, "");
    if (tagName === "date") return innerText.trim();

    return innerText;
  }

  return parseNext() || {};
}

export function toApplePlist(obj) {
  function serializeValue(val, indent = "  ") {
    if (val === null || val === undefined) {
      return `${indent}<string></string>\n`;
    }
    if (typeof val === "boolean") {
      return `${indent}${val ? "<true/>" : "<false/>"}\n`;
    }
    if (typeof val === "number") {
      if (Number.isInteger(val)) {
        return `${indent}<integer>${val}</integer>\n`;
      }
      return `${indent}<real>${val}</real>\n`;
    }
    if (val && typeof val === "object" && val._data) {
      return `${indent}<data>\n${indent}${val._data.replace(/\s+/g, "")}\n${indent}</data>\n`;
    }
    if (typeof val === "string") {
      const escaped = val
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;");
      return `${indent}<string>${escaped}</string>\n`;
    }
    if (Array.isArray(val)) {
      let xml = `${indent}<array>\n`;
      for (const item of val) {
        xml += serializeValue(item, indent + "  ");
      }
      xml += `${indent}</array>\n`;
      return xml;
    }
    if (typeof val === "object") {
      let xml = `${indent}<dict>\n`;
      for (const [k, v] of Object.entries(val)) {
        xml += `${indent}  <key>${k}</key>\n`;
        xml += serializeValue(v, indent + "  ");
      }
      xml += `${indent}</dict>\n`;
      return xml;
    }
    return `${indent}<string>${String(val)}</string>\n`;
  }

  return `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
${serializeValue(obj, "").trim()}
</plist>`;
}

// ─────────────────────────────────────────────────────────────
// 2. Supabase Storage Helpers
// ─────────────────────────────────────────────────────────────

async function supabaseFetch(endpoint, options = {}) {
  const url = `${SUPABASE_URL}/${endpoint}`;
  const headers = {
    "apikey": SUPABASE_KEY,
    "Authorization": `Bearer ${SUPABASE_KEY}`,
    "Content-Type": "application/json",
    ...(options.headers || {})
  };
  return fetch(url, { ...options, headers });
}

// ─────────────────────────────────────────────────────────────
// 3. Apple MDM Enrollment & Supervision Profiles (.mobileconfig)
// ─────────────────────────────────────────────────────────────

const MDM_IDENTITY_P12_BASE64 = "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";

export function generateEnrollmentProfile(origin = "https://cokistudios.com") {
  const profileUUID = "C0C10000-E2EE-4MDM-A001-COKISTUDIOS01";
  const certUUID = "C0C10000-CERT-4MDM-A001-IDENTITYCERT01";
  const mdmUUID = "C0C10000-E2EE-4MDM-B002-COKISTUDIOS02";

  const config = {
    PayloadDescription: "Perfil de Gestión y Supervisión Oficial de Coki Studios",
    PayloadDisplayName: "Coki Studios MDM & Device Supervisor",
    PayloadIdentifier: "com.cokistudios.mdm.enrollment",
    PayloadOrganization: "Coki Studios",
    PayloadType: "Configuration",
    PayloadUUID: profileUUID,
    PayloadVersion: 1,
    PayloadRemovalDisallowed: false,
    PayloadContent: [
      {
        PayloadType: "com.apple.security.pkcs12",
        PayloadVersion: 1,
        PayloadIdentifier: "com.cokistudios.mdm.identity",
        PayloadUUID: certUUID,
        PayloadDisplayName: "Coki Studios Device Identity Certificate",
        PayloadCertificateFileName: "CokiStudios-DeviceIdentity.p12",
        PayloadContent: { _data: MDM_IDENTITY_P12_BASE64 },
        Password: "cokistudios"
      },
      {
        PayloadType: "com.apple.mdm",
        PayloadVersion: 1,
        PayloadIdentifier: "com.cokistudios.mdm.payload",
        PayloadUUID: mdmUUID,
        PayloadDisplayName: "Coki Studios MDM Service",
        PayloadOrganization: "Coki Studios",
        IdentityCertificateUUID: certUUID,
        ServerURL: `${origin}/api/mdm/connect`,
        CheckInURL: `${origin}/api/mdm/checkin`,
        Topic: "com.apple.mgmt.External.coki-studios-mdm",
        AccessRights: 8191, // Full management access
        UseDevelopmentAPNS: false,
        SignMessage: false,
        CheckOutWhenRemoved: true
      }
    ]
  };

  return toApplePlist(config);
}

// Generates a Supervised Lock Profile (Kiosk / Restrictions)
export function generateSupervisedRestrictionsProfile(options = {}) {
  const profileUUID = "C0C10000-LOCK-4MDM-C003-RESTRICTIONS01";
  const { singleAppBundleId = null, disallowErase = true, disallowAppRemoval = true } = options;

  const payloads = [
    {
      PayloadType: "com.apple.applicationaccess",
      PayloadVersion: 1,
      PayloadIdentifier: "com.cokistudios.restrictions",
      PayloadUUID: "C0C10000-LOCK-4MDM-C003-APPACCESS001",
      PayloadDisplayName: "Coki Studios Security Restrictions",
      allowEraseContentAndSettings: !disallowErase,
      allowAppRemoval: !disallowAppRemoval,
      allowUntrustedTLSPrompts: false,
      allowPairing: true
    }
  ];

  // If Kiosk Mode (Single App Mode) is requested
  if (singleAppBundleId) {
    payloads.push({
      PayloadType: "com.apple.app.lock",
      PayloadVersion: 1,
      PayloadIdentifier: "com.cokistudios.applock",
      PayloadUUID: "C0C10000-LOCK-4MDM-C003-SINGLEAPP001",
      PayloadDisplayName: "Coki Studios Kiosk Mode",
      App: {
        Identifier: singleAppBundleId,
        Options: {
          DisableTouch: false,
          DisableDeviceRotation: false,
          DisableVolumeButtons: false,
          DisableRingerSwitch: false,
          DisableSleepWakeButton: false,
          DisableAutoLock: false
        }
      }
    });
  }

  const config = {
    PayloadDescription: "Políticas de Supervisión y Seguridad de Coki Studios",
    PayloadDisplayName: "Coki Studios Supervised Fleet Policy",
    PayloadIdentifier: "com.cokistudios.supervised.policy",
    PayloadOrganization: "Coki Studios",
    PayloadType: "Configuration",
    PayloadUUID: profileUUID,
    PayloadVersion: 1,
    PayloadRemovalDisallowed: true,
    PayloadContent: payloads
  };

  return toApplePlist(config);
}

// ─────────────────────────────────────────────────────────────
// 4. Apple MDM Protocol Handlers (Checkin & Connect)
// ─────────────────────────────────────────────────────────────

export async function handleMDMCheckin(request) {
  const rawBody = await request.text();
  const plist = parseApplePlist(rawBody);

  const messageType = plist.MessageType;
  const udid = plist.UDID;

  if (!udid) {
    return new Response(toApplePlist({ Error: "Missing UDID in checkin payload" }), {
      status: 400,
      headers: { "Content-Type": "application/x-apple-aspen-config" }
    });
  }

  if (messageType === "Authenticate") {
    // Device enrollment handshake
    const deviceData = {
      udid,
      serial_number: plist.SerialNumber || null,
      model: plist.ProductName || plist.Model || null,
      os_version: plist.OSVersion || null,
      build_version: plist.BuildVersion || null,
      status: "enrolled",
      last_seen_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    // Upsert into managed_devices
    await supabaseFetch(`managed_devices?on_conflict=udid`, {
      method: "POST",
      headers: { "Prefer": "resolution=merge-duplicates" },
      body: JSON.stringify(deviceData)
    });

    // Auto-queue DeviceInformation command to gather complete hardware specs & ECID
    const cmdUuid = `cmd-info-${Date.now()}`;
    await supabaseFetch("mdm_commands", {
      method: "POST",
      body: JSON.stringify({
        udid,
        command_uuid: cmdUuid,
        request_type: "DeviceInformation",
        payload: {
          Queries: [
            "UDID", "SerialNumber", "DeviceName", "OSVersion", "BuildVersion",
            "ModelName", "Model", "ProductName", "WiFiMAC", "BluetoothMAC",
            "IsSupervised", "UniqueChipID"
          ]
        },
        status: "pending"
      })
    });

    return new Response(toApplePlist({ Status: "Acknowledged" }), {
      status: 200,
      headers: { "Content-Type": "application/x-apple-aspen-config" }
    });
  }

  if (messageType === "TokenUpdate") {
    // Device APNs token & PushMagic
    const token = plist.Token;
    const pushMagic = plist.PushMagic;
    const unlockToken = plist.UnlockToken;

    await supabaseFetch(`managed_devices?udid=eq.${encodeURIComponent(udid)}`, {
      method: "PATCH",
      body: JSON.stringify({
        push_token: typeof token === "string" ? token : JSON.stringify(token),
        push_magic: pushMagic,
        unlock_token: unlockToken || null,
        status: "enrolled",
        last_seen_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
      })
    });

    return new Response(toApplePlist({ Status: "Acknowledged" }), {
      status: 200,
      headers: { "Content-Type": "application/x-apple-aspen-config" }
    });
  }

  if (messageType === "CheckOut") {
    // Device un-enrolling
    await supabaseFetch(`managed_devices?udid=eq.${encodeURIComponent(udid)}`, {
      method: "PATCH",
      body: JSON.stringify({
        status: "unenrolled",
        updated_at: new Date().toISOString()
      })
    });

    return new Response(toApplePlist({ Status: "Acknowledged" }), {
      status: 200,
      headers: { "Content-Type": "application/x-apple-aspen-config" }
    });
  }

  return new Response(toApplePlist({ Status: "Acknowledged" }), {
    status: 200,
    headers: { "Content-Type": "application/x-apple-aspen-config" }
  });
}

export async function handleMDMConnect(request) {
  const rawBody = await request.text();
  const plist = parseApplePlist(rawBody);

  const udid = plist.UDID;
  const status = plist.Status;
  const commandUUID = plist.CommandUUID;

  if (!udid) {
    return new Response(toApplePlist({}), {
      status: 200,
      headers: { "Content-Type": "application/x-apple-aspen-config" }
    });
  }

  // Update device ping
  await supabaseFetch(`managed_devices?udid=eq.${encodeURIComponent(udid)}`, {
    method: "PATCH",
    body: JSON.stringify({ last_seen_at: new Date().toISOString() })
  });

  // Handle Command Acknowledgment from device
  if (status === "Acknowledged" && commandUUID) {
    const queryResp = plist.QueryResponses;

    await supabaseFetch(`mdm_commands?command_uuid=eq.${encodeURIComponent(commandUUID)}`, {
      method: "PATCH",
      body: JSON.stringify({
        status: "acknowledged",
        response: plist,
        executed_at: new Date().toISOString()
      })
    });

    // If DeviceInformation response arrived, sync hardware attributes
    if (queryResp) {
      const updates = {};
      if (queryResp.DeviceName) updates.device_name = queryResp.DeviceName;
      if (queryResp.ModelName) updates.model = queryResp.ModelName;
      if (queryResp.OSVersion) updates.os_version = queryResp.OSVersion;
      if (queryResp.BuildVersion) updates.build_version = queryResp.BuildVersion;
      if (queryResp.IsSupervised !== undefined) updates.is_supervised = Boolean(queryResp.IsSupervised);
      if (queryResp.UniqueChipID) {
        // Chip ID / ECID reported by device query
        const ecidVal = String(queryResp.UniqueChipID);
        updates.ecid = ecidVal.startsWith("0x") ? ecidVal : `0x${Number(ecidVal).toString(16)}`;
      }

      if (Object.keys(updates).length > 0) {
        updates.updated_at = new Date().toISOString();
        await supabaseFetch(`managed_devices?udid=eq.${encodeURIComponent(udid)}`, {
          method: "PATCH",
          body: JSON.stringify(updates)
        });
      }
    }
  } else if (status === "Error" && commandUUID) {
    await supabaseFetch(`mdm_commands?command_uuid=eq.${encodeURIComponent(commandUUID)}`, {
      method: "PATCH",
      body: JSON.stringify({
        status: "error",
        response: plist,
        executed_at: new Date().toISOString()
      })
    });
  }

  // Look for next pending command for this device
  const cmdRes = await supabaseFetch(
    `mdm_commands?udid=eq.${encodeURIComponent(udid)}&status=eq.pending&order=created_at.asc&limit=1`
  );
  const pendingCommands = await cmdRes.json().catch(() => []);

  if (Array.isArray(pendingCommands) && pendingCommands.length > 0) {
    const nextCmd = pendingCommands[0];

    // Mark as sent
    await supabaseFetch(`mdm_commands?id=eq.${nextCmd.id}`, {
      method: "PATCH",
      body: JSON.stringify({ status: "sent" })
    });

    // Format Apple Command Plist
    const commandPayload = {
      CommandUUID: nextCmd.command_uuid,
      Command: {
        RequestType: nextCmd.request_type,
        ...(nextCmd.payload || {})
      }
    };

    return new Response(toApplePlist(commandPayload), {
      status: 200,
      headers: { "Content-Type": "application/x-apple-aspen-config" }
    });
  }

  // No command pending: Return empty 200 OK Plist
  return new Response(toApplePlist({}), {
    status: 200,
    headers: { "Content-Type": "application/x-apple-aspen-config" }
  });
}

// ─────────────────────────────────────────────────────────────
// 5. ECID & SHSH Blobs API Handlers
// ─────────────────────────────────────────────────────────────

export async function handleDeviceRegister(request) {
  const body = await request.json().catch(() => ({}));
  let {
    ecid,
    udid,
    serial_number,
    device_name,
    model,
    board_config,
    chip_id,
    os_version,
    build_version,
    is_supervised = false,
    assigned_user_email,
    notes
  } = body;

  if (!ecid && !udid && !serial_number) {
    return Response.json(
      { success: false, error: "Debes especificar al menos un identificador (ECID, UDID o Serial Number)." },
      { status: 400, headers: CORS_HEADERS }
    );
  }

  // Normalize ECID (ensure hex string with 0x prefix if numeric or string)
  if (ecid) {
    const cleanEcid = String(ecid).trim();
    if (!cleanEcid.startsWith("0x")) {
      try {
        const bigIntEcid = BigInt(cleanEcid);
        ecid = `0x${bigIntEcid.toString(16).toUpperCase()}`;
      } catch {
        ecid = cleanEcid.toUpperCase();
      }
    } else {
      ecid = cleanEcid.toUpperCase();
    }
  }

  const payload = {
    ecid,
    udid,
    serial_number,
    device_name: device_name || `Dispositivo ${model || "Apple"}`,
    model,
    board_config,
    chip_id,
    os_version,
    build_version,
    is_supervised: Boolean(is_supervised),
    status: "enrolled",
    assigned_user_email,
    notes,
    last_seen_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };

  // Upsert into managed_devices
  const conflictCol = ecid ? "ecid" : (udid ? "udid" : "serial_number");
  const res = await supabaseFetch(`managed_devices?on_conflict=${conflictCol}`, {
    method: "POST",
    headers: {
      "Prefer": "return=representation,resolution=merge-duplicates"
    },
    body: JSON.stringify(payload)
  });

  const saved = await res.json().catch(() => []);
  return Response.json(
    {
      success: true,
      message: "Dispositivo registrado y supervisado en Coki Studios MDM.",
      device: Array.isArray(saved) ? saved[0] : saved
    },
    { headers: CORS_HEADERS }
  );
}

export async function handleBlobSave(request) {
  const body = await request.json().catch(() => ({}));
  let {
    ecid,
    ios_version,
    build_id,
    board_config,
    generator = "0x1111111111111111",
    apnonce,
    blob_format = "shsh2",
    blob_payload
  } = body;

  if (!ecid || !ios_version || !build_id || !blob_payload) {
    return Response.json(
      {
        success: false,
        error: "Faltan campos mandatorios: ecid, ios_version, build_id y blob_payload."
      },
      { status: 400, headers: CORS_HEADERS }
    );
  }

  // Normalize ECID
  const cleanEcid = String(ecid).trim();
  const normalizedEcid = cleanEcid.startsWith("0x")
    ? cleanEcid.toUpperCase()
    : `0x${BigInt(cleanEcid).toString(16).toUpperCase()}`;

  // Find linked managed_device id if exists
  const devRes = await supabaseFetch(`managed_devices?ecid=eq.${encodeURIComponent(normalizedEcid)}&select=id`);
  const devRows = await devRes.json().catch(() => []);
  const deviceId = Array.isArray(devRows) && devRows.length > 0 ? devRows[0].id : null;

  const blobData = {
    device_id: deviceId,
    ecid: normalizedEcid,
    ios_version: String(ios_version).trim(),
    build_id: String(build_id).trim(),
    board_config,
    generator,
    apnonce,
    blob_format,
    blob_payload: typeof blob_payload === "object" ? JSON.stringify(blob_payload) : String(blob_payload),
    is_signed_by_apple: true,
    created_at: new Date().toISOString()
  };

  const insertRes = await supabaseFetch("device_shsh_blobs", {
    method: "POST",
    headers: { "Prefer": "return=representation" },
    body: JSON.stringify(blobData)
  });

  const savedBlob = await insertRes.json().catch(() => []);
  return Response.json(
    {
      success: true,
      message: `Ticket SHSH2 preservado con éxito para ECID ${normalizedEcid} en iOS ${ios_version} (${build_id}).`,
      blob: Array.isArray(savedBlob) ? savedBlob[0] : savedBlob
    },
    { headers: CORS_HEADERS }
  );
}

export async function handleBlobGet(request, ecid) {
  if (!ecid) {
    return Response.json({ success: false, error: "ECID requerido" }, { status: 400, headers: CORS_HEADERS });
  }

  const normalizedEcid = ecid.startsWith("0x")
    ? ecid.toUpperCase()
    : `0x${BigInt(ecid).toString(16).toUpperCase()}`;

  const res = await supabaseFetch(
    `device_shsh_blobs?ecid=eq.${encodeURIComponent(normalizedEcid)}&order=created_at.desc`
  );
  const blobs = await res.json().catch(() => []);

  return Response.json(
    {
      success: true,
      ecid: normalizedEcid,
      count: Array.isArray(blobs) ? blobs.length : 0,
      blobs: Array.isArray(blobs) ? blobs : []
    },
    { headers: CORS_HEADERS }
  );
}

export async function handleRequestAppleTSS(request) {
  const body = await request.json().catch(() => ({}));
  const { ecid, board_config, chip_id, build_id, ios_version } = body;

  if (!ecid || !board_config || !chip_id) {
    return Response.json(
      {
        success: false,
        error: "Para solicitar ticket TSS a Apple se requiere: ecid, board_config y chip_id."
      },
      { status: 400, headers: CORS_HEADERS }
    );
  }

  // Parse decimal ECID for Apple TSS
  let decimalEcid;
  try {
    decimalEcid = ecid.startsWith("0x") ? BigInt(ecid).toString() : String(ecid);
  } catch {
    decimalEcid = ecid;
  }

  // Construct minimal TSS Request Plist for Apple TSS Server
  const tssRequestPlist = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>@HostPlatformInfo</key>
  <string>macOS</string>
  <key>@VersionInfo</key>
  <string>libauthinstall-1000.0.0</string>
  <key>ApECID</key>
  <integer>${decimalEcid}</integer>
  <key>ApChipID</key>
  <integer>${parseInt(chip_id, 16) || parseInt(chip_id, 10) || 33056}</integer>
  <key>ApBoardID</key>
  <integer>${parseInt(board_config, 16) || 0}</integer>
  <key>ApSecurityDomain</key>
  <integer>1</integer>
  <key>ApNonce</key>
  <data>ERERERERERERERER</data>
</dict>
</plist>`;

  try {
    const appleTssResponse = await fetch("https://gs.apple.com/TSS/controller?action=2", {
      method: "POST",
      headers: {
        "Content-Type": "text/xml; charset=utf-8",
        "User-Agent": "InetURL/1.0",
        "Host": "gs.apple.com"
      },
      body: tssRequestPlist
    });

    const responseText = await appleTssResponse.text();
    const isSigned = responseText.includes("STATUS=0") || responseText.includes("<key>ApImg4Ticket</key>");

    if (isSigned) {
      // Auto-save the fetched blob into Supabase
      const normalizedEcid = ecid.startsWith("0x") ? ecid.toUpperCase() : `0x${BigInt(ecid).toString(16).toUpperCase()}`;
      await supabaseFetch("device_shsh_blobs", {
        method: "POST",
        body: JSON.stringify({
          ecid: normalizedEcid,
          ios_version: ios_version || "current-signed",
          build_id: build_id || "tss-live",
          board_config,
          generator: "0x1111111111111111",
          blob_format: "plist",
          blob_payload: responseText,
          is_signed_by_apple: true
        })
      });

      return Response.json({
        success: true,
        message: "Ticket TSS firmado exitosamente por Apple (gs.apple.com) y preservado en Coki Studios.",
        ecid: decimalEcid,
        raw_response: responseText.slice(0, 1000) + "..."
      }, { headers: CORS_HEADERS });
    } else {
      return Response.json({
        success: false,
        message: "Apple TSS respondió pero la firma no fue aprobada (posiblemente versión de iOS no firmada actualmente).",
        apple_status: responseText
      }, { status: 400, headers: CORS_HEADERS });
    }
  } catch (err) {
    return Response.json({
      success: false,
      error: `Error al contactar Apple TSS: ${err.message}`
    }, { status: 502, headers: CORS_HEADERS });
  }
}

export async function handleDeviceList() {
  const res = await supabaseFetch("managed_devices?order=last_seen_at.desc&select=*");
  const devices = await res.json().catch(() => []);

  // Fetch blob counts per ECID
  const blobsRes = await supabaseFetch("device_shsh_blobs?select=ecid");
  const blobRows = await blobsRes.json().catch(() => []);
  const countsByEcid = {};
  if (Array.isArray(blobRows)) {
    for (const b of blobRows) {
      if (b.ecid) {
        countsByEcid[b.ecid] = (countsByEcid[b.ecid] || 0) + 1;
      }
    }
  }

  const enriched = (Array.isArray(devices) ? devices : []).map(d => ({
    ...d,
    saved_blobs_count: d.ecid ? (countsByEcid[d.ecid] || 0) : 0
  }));

  return Response.json({ success: true, count: enriched.length, devices: enriched }, { headers: CORS_HEADERS });
}

export async function handleQueueCommand(request, udid) {
  const body = await request.json().catch(() => ({}));
  const { request_type, payload = {} } = body;

  if (!udid || !request_type) {
    return Response.json(
      { success: false, error: "Se requiere udid y request_type (ej. DeviceInformation, DeviceLock, EraseDevice)." },
      { status: 400, headers: CORS_HEADERS }
    );
  }

  const commandUUID = `cmd-${request_type.toLowerCase()}-${Date.now()}`;
  const cmdRes = await supabaseFetch("mdm_commands", {
    method: "POST",
    headers: { "Prefer": "return=representation" },
    body: JSON.stringify({
      udid,
      command_uuid: commandUUID,
      request_type,
      payload,
      status: "pending"
    })
  });

  const created = await cmdRes.json().catch(() => []);
  return Response.json(
    {
      success: true,
      message: `Comando ${request_type} encolado para el dispositivo con UDID ${udid}.`,
      command: Array.isArray(created) ? created[0] : created
    },
    { headers: CORS_HEADERS }
  );
}

// ─────────────────────────────────────────────────────────────
// 6. Main MDM Router Dispatcher
// ─────────────────────────────────────────────────────────────

export async function handleMDMRequest(request, env, ctx) {
  const url = new URL(request.url);
  const path = url.pathname;

  if (request.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  // Apple Service Discovery (Account-driven enrollment)
  if (path === "/.well-known/com.apple.remotemanagement") {
    return Response.json({
      Servers: [
        {
          Version: "mdm-byod",
          BaseURL: `${url.origin}/api/mdm/enroll`
        }
      ]
    }, { headers: CORS_HEADERS });
  }

  // 1. Download Enrollment Profile (.mobileconfig)
  if (path === "/api/mdm/enroll" || path === "/mdm/enroll" || path === "/enroll.mobileconfig") {
    const profile = generateEnrollmentProfile(url.origin);
    return new Response(profile, {
      status: 200,
      headers: {
        "Content-Type": "application/x-apple-aspen-config",
        "Content-Disposition": 'attachment; filename="CokiStudios-Enrollment.mobileconfig"',
        ...CORS_HEADERS
      }
    });
  }

  // 2. Download Supervised Restrictions / Kiosk Profile
  if (path === "/api/mdm/profile/supervised") {
    const singleApp = url.searchParams.get("app") || null;
    const profile = generateSupervisedRestrictionsProfile({ singleAppBundleId: singleApp });
    return new Response(profile, {
      status: 200,
      headers: {
        "Content-Type": "application/x-apple-aspen-config",
        "Content-Disposition": 'attachment; filename="CokiStudios-Supervised.mobileconfig"',
        ...CORS_HEADERS
      }
    });
  }

  // 3. Apple MDM Check-in Endpoint
  if (path === "/api/mdm/checkin" || path === "/mdm/checkin") {
    return handleMDMCheckin(request);
  }

  // 4. Apple MDM Connect / Command Endpoint
  if (path === "/api/mdm/connect" || path === "/mdm/connect") {
    return handleMDMConnect(request);
  }

  // 5. Hardware Device Registration (ECID, UDID, Serial)
  if (path === "/api/mdm/devices/register" && request.method === "POST") {
    return handleDeviceRegister(request);
  }

  // 6. Device List
  if (path === "/api/mdm/devices" && request.method === "GET") {
    return handleDeviceList();
  }

  // 7. Queue MDM Command to Device
  const cmdMatch = path.match(/^\/api\/mdm\/devices\/([^/]+)\/command$/);
  if (cmdMatch && request.method === "POST") {
    return handleQueueCommand(request, cmdMatch[1]);
  }

  // 8. SHSH Blobs Preservation Endpoints
  if (path === "/api/mdm/blobs/save" && request.method === "POST") {
    return handleBlobSave(request);
  }

  if (path === "/api/mdm/blobs/request-tss" && request.method === "POST") {
    return handleRequestAppleTSS(request);
  }

  const blobGetMatch = path.match(/^\/api\/mdm\/blobs\/([^/]+)$/);
  if (blobGetMatch && request.method === "GET") {
    return handleBlobGet(request, blobGetMatch[1]);
  }

  return Response.json({ error: "Endpoint MDM no encontrado" }, { status: 404, headers: CORS_HEADERS });
}
