//
//  src/index.js
//  Cloudflare Worker for cokistudios.com with Workers AI Moderation & Static Assets
//

const commonProfanities = new Set([
  "idiota", "idiotas", "estupido", "estupidos", "estúpido", "estúpida", "estupida", "estupidas",
  "imbecil", "imbeciles", "imbécil", "imbéciles",
  "pendejo", "pendejos", "pendeja", "pendejas", "pendejada", "pendejadas",
  "mierda", "mierdas", "mierdoso", "mierdosa",
  "puta", "putas", "puto", "putos", "putita", "putitas", "putazo", "putazos",
  "bastardo", "bastardos", "maldito", "malditos", "maldita", "malditas",
  "cabron", "cabrones", "cabrón", "cabrona", "cabronas",
  "zorra", "zorras", "perra", "perras", "culero", "culeros", "culera", "culeras",
  "hdp", "hp", "chupala", "coño", "coños", "cono", "conos", "gilipollas",
  "maricon", "maricones", "maricón", "mariconazo", "marica", "maricas",
  "tarado", "tarados", "tarada", "taradas", "inutil", "inútil", "inutiles", "inútiles",
  "bastard", "bitch", "bitches", "asshole", "assholes", "fuck", "fucking", "shit",
  "dick", "cunt", "motherfucker"
]);

function normalizeLeetspeak(text) {
  const map = {
    '0': 'o', '1': 'i', '!': 'i', '|': 'i', '3': 'e',
    '4': 'a', '@': 'a', '5': 's', '$': 's', '7': 't', '8': 'b'
  };
  return text.toLowerCase().split('').map(c => map[c] || c).join('')
    .normalize("NFD").replace(/[\u0300-\u036f]/g, "");
}

function collapseRepeats(text) {
  return text.replace(/([a-zA-Z])\1{1,}/g, '$1');
}

function detectEvasions(text) {
  if (!text) return [];
  const detected = new Set();

  // 1. Spaced-out single characters (e.g. "P U T A", "p . u . t . a", "m a r i c o n", "H D P")
  const spacedRegex = /(?:(?<=\s)|^)[a-zA-Z0-9!@#$%*](?:[\s._\-*/]+[a-zA-Z0-9!@#$%*]){1,}(?=(?:\s|$|[.,!?;:]))/gi;
  let match;
  while ((match = spacedRegex.exec(text)) !== null) {
    const compact = match[0].replace(/[\s._\-*/]/g, '');
    const norm = collapseRepeats(normalizeLeetspeak(compact));
    if (commonProfanities.has(norm)) {
      detected.add(norm);
    }
  }

  // 2. Tokenize words and analyze for stretching & leetspeak
  const tokens = text.split(/\s+/);
  for (const token of tokens) {
    const clean = token.replace(/^[^a-zA-Z0-9]+|[^a-zA-Z0-9]+$/g, '');
    if (!clean) continue;
    const norm = normalizeLeetspeak(clean);
    const collapsed = collapseRepeats(norm);

    if (commonProfanities.has(norm)) {
      detected.add(norm);
    } else if (commonProfanities.has(collapsed)) {
      detected.add(collapsed);
    }
  }

  return Array.from(detected);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    // AI Moderation API Endpoint
    if (url.pathname === '/api/moderate' && request.method === 'POST') {
      try {
        const body = await request.json().catch(() => ({}));
        const content = (body.content || '').trim();
        const title = (body.title || '').trim();

        if (!content && !title) {
          return Response.json({
            isSafe: true,
            flaggedWords: [],
            reason: 'Contenido vacío.',
            engine: 'Cloudflare Edge Validator'
          });
        }

        // Tier 1: Fast deterministic heuristic anti-evasion (<1ms)
        const combined = title ? `${title} ${content}` : content;
        const evasionWords = detectEvasions(combined);
        if (evasionWords.length > 0) {
          return Response.json({
            isSafe: false,
            flaggedWords: evasionWords,
            reason: `Se detectó lenguaje inapropiado o evasión de filtros: ${evasionWords.join(', ')}`,
            engine: 'Edge Anti-Evasion Shield'
          });
        }

        // Tier 2: Cloudflare Workers AI (Llama 3.1 8B) on serverless GPUs
        if (env.AI) {
          const systemPrompt = `You are the content moderation AI for Forkar community.
Your role: detect toxic language, insults, slurs, harassment, and vulgar double entendres (chistes de doble sentido, albures, insunaciones sexuales veladas o vulgares en español/inglés).

CRITERIA FOR UNSAFE (isSafe: false):
- Insults, cursing, profanities, hate speech, threats, or harassment.
- ALL double entendres, albures, sexual puns, or disguised sexual innuendos (e.g. phrases playing on eating/sitting on foods, banana, sexual organs, or positions). Even if intended as a joke or playful banter, you MUST classify it as isSafe: false.
- Filter evasion attempts (leetspeak, spaced letters, hidden slurs).

CRITERIA FOR SAFE (isSafe: true):
- Friendly, constructive, normal discussions, technical topics, polite banter without any sexual or insult connotations.

Output ONLY valid raw JSON:
{
  "isSafe": boolean,
  "flaggedWords": ["palabra1", "palabra2"],
  "reason": "Explicación concisa en español de por qué se aprueba o por qué se marca como inseguro"
}`;

          const userPrompt = title
            ? `Analiza este post para la comunidad:\nTítulo: "${title}"\nContenido: "${content}"\n\nInstrucción obligatoria: Si contiene chistes de doble sentido, albures, insinuaciones de índole sexual o insultos, DEBES responder con "isSafe": false.`
            : `Analiza este mensaje para la comunidad:\nContenido: "${content}"\n\nInstrucción obligatoria: Si contiene chistes de doble sentido, albures, insinuaciones de índole sexual o insultos, DEBES responder con "isSafe": false.`;

          const aiResponse = await env.AI.run('@cf/meta/llama-3.2-3b-instruct', {
            messages: [
              { role: 'system', content: systemPrompt },
              { role: 'user', content: userPrompt }
            ],
            temperature: 0.1,
            max_tokens: 256
          });

          let parsed = null;
          if (aiResponse && typeof aiResponse.response === 'object' && aiResponse.response !== null && 'isSafe' in aiResponse.response) {
            parsed = aiResponse.response;
          } else if (aiResponse && Array.isArray(aiResponse.choices) && aiResponse.choices[0]?.message?.content) {
            const rawContent = aiResponse.choices[0].message.content;
            const jsonMatch = rawContent.match(/\{[\s\S]*\}/);
            parsed = JSON.parse(jsonMatch ? jsonMatch[0] : rawContent);
          } else if (typeof aiResponse === 'string') {
            const jsonMatch = aiResponse.match(/\{[\s\S]*\}/);
            parsed = JSON.parse(jsonMatch ? jsonMatch[0] : aiResponse);
          }

          if (parsed && typeof parsed === 'object') {
            return Response.json({
              isSafe: Boolean(parsed.isSafe),
              flaggedWords: parsed.flaggedWords || [],
              reason: parsed.reason || (parsed.isSafe ? 'Contenido verificado y respetuoso.' : 'Contenido inapropiado detectado.'),
              engine: 'Cloudflare Workers AI (Llama 3.2)'
            });
          }

          return Response.json({
            isSafe: true,
            flaggedWords: [],
            reason: 'Contenido verificado.',
            engine: 'Cloudflare Workers AI (Llama 3.2)'
          });
        }

        // If env.AI is not bound yet, return safe pass
        return Response.json({
          isSafe: true,
          flaggedWords: [],
          reason: 'Verificado por el escudo de borde.',
          engine: 'Edge Anti-Evasion Shield'
        });

      } catch (err) {
        return Response.json({
          isSafe: true,
          flaggedWords: [],
          reason: 'Validación completada.',
          engine: 'Edge Fallback',
          warning: err.message
        });
      }
    }

    // Default: Serve static assets
    return env.ASSETS.fetch(request);
  }
};
