import { UserProfile } from "@/types";

const BASE = process.env.NEXT_PUBLIC_SIKANUA_API_URL ?? "http://localhost:8000";

export interface StreamCallbacks {
  onToken:  (token: string) => void;
  onDone:   () => void;
  onError:  (err: Error) => void;
}

/**
 * Send messages to the OpenAI-compatible /v1/chat/completions endpoint
 * with streaming enabled.
 */
export async function streamChatCompletion(
  messages: { role: string; content: string }[],
  callbacks: StreamCallbacks,
) {
  try {
    const res = await fetch(`${BASE}/v1/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: "sikanua-v1",
        messages,
        stream: true,
      }),
    });

    if (!res.ok) {
      throw new Error(`API error ${res.status}: ${await res.text()}`);
    }

    const reader  = res.body!.getReader();
    const decoder = new TextDecoder();
    let   buffer  = "";

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split("\n");
      buffer = lines.pop() ?? "";

      for (const line of lines) {
        if (!line.startsWith("data: ")) continue;
        const data = line.slice(6).trim();
        if (data === "[DONE]") { callbacks.onDone(); return; }
        try {
          const json  = JSON.parse(data);
          const delta = json.choices?.[0]?.delta?.content ?? "";
          if (delta) callbacks.onToken(delta);
        } catch {
          // skip malformed chunk
        }
      }
    }
    callbacks.onDone();
  } catch (err) {
    callbacks.onError(err instanceof Error ? err : new Error(String(err)));
  }
}

/**
 * Non-streaming direct plan generation.
 */
export async function generatePlan(profile: UserProfile) {
  const res = await fetch(`${BASE}/v1/plan`, {
    method:  "POST",
    headers: { "Content-Type": "application/json" },
    body:    JSON.stringify(profile),
  });
  if (!res.ok) throw new Error(`API error ${res.status}`);
  return res.json();
}

export async function checkHealth(): Promise<boolean> {
  try {
    const res = await fetch(`${BASE}/`, { signal: AbortSignal.timeout(3000) });
    return res.ok;
  } catch {
    return false;
  }
}
