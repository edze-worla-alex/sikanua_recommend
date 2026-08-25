"use client";
import { useEffect, useRef, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { Send, RotateCcw, Leaf, AlertCircle } from "lucide-react";
import { useSikanuaStore } from "@/store";
import { streamChatCompletion } from "@/lib/api";

// ── Typing indicator ──────────────────────────────────────────────────────────
function TypingDots() {
  return (
    <div className="flex items-center gap-1 px-4 py-3">
      {[0, 1, 2].map((i) => (
        <span
          key={i}
          className="w-2 h-2 rounded-full bg-forest/60 animate-[pulseDot_1.4s_ease-in-out_infinite]"
          style={{ animationDelay: `${i * 0.16}s` }}
        />
      ))}
    </div>
  );
}

// ── Single message bubble ─────────────────────────────────────────────────────
function MessageBubble({
  role, content,
}: {
  role: "user" | "assistant";
  content: string;
}) {
  const isUser = role === "user";
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className={`flex gap-3 ${isUser ? "flex-row-reverse" : "flex-row"}`}
    >
      {/* Avatar */}
      {!isUser && (
        <div className="flex-shrink-0 w-8 h-8 rounded-xl bg-forest flex items-center justify-center shadow-sm mt-0.5">
          <Leaf className="w-4 h-4 text-white" />
        </div>
      )}

      <div
        className={`max-w-[82%] rounded-2xl px-4 py-3 text-sm leading-relaxed shadow-sm ${
          isUser
            ? "bg-forest text-white rounded-br-sm"
            : "bg-white border border-forest-light rounded-bl-sm"
        }`}
      >
        {isUser ? (
          <p className="whitespace-pre-wrap break-words">{content}</p>
        ) : (
          <div className="prose-chat">
            <ReactMarkdown remarkPlugins={[remarkGfm]}>
              {content}
            </ReactMarkdown>
          </div>
        )}
      </div>
    </motion.div>
  );
}

// ── Main Chat Component ───────────────────────────────────────────────────────
export default function ChatInterface() {
  const { messages, streaming, setStreaming, addMessage, updateLastAssistant, clearMessages, setStep } =
    useSikanuaStore();
  const [input, setInput]     = useState("");
  const [error, setError]     = useState<string | null>(null);
  const [initiated, setInit]  = useState(false);
  const bottomRef             = useRef<HTMLDivElement>(null);
  const textareaRef           = useRef<HTMLTextAreaElement>(null);

  // Auto-trigger plan generation for the first profile message
  useEffect(() => {
    if (!initiated && messages.length === 1 && messages[0].role === "user") {
      setInit(true);
      triggerStream(messages);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [messages]);

  // Scroll to bottom on new messages
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, streaming]);

  const triggerStream = (msgHistory: typeof messages) => {
    setError(null);
    setStreaming(true);
    const assistantId = `msg-${Date.now()}`;
    addMessage({ id: assistantId, role: "assistant", content: "", timestamp: new Date() });

    streamChatCompletion(
      msgHistory.map((m) => ({ role: m.role, content: m.content })),
      {
        onToken: (token) => updateLastAssistant(token),
        onDone:  () => setStreaming(false),
        onError: (err) => {
          setStreaming(false);
          setError(err.message);
        },
      },
    );
  };

  const sendMessage = () => {
    const text = input.trim();
    if (!text || streaming) return;
    setInput("");

    const newMsg = { id: `msg-${Date.now()}`, role: "user" as const, content: text, timestamp: new Date() };
    const history = [...messages, newMsg];
    addMessage(newMsg);
    triggerStream(history);
  };

  const handleKey = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) { e.preventDefault(); sendMessage(); }
  };

  const handleReset = () => {
    clearMessages();
    setInit(false);
    setStep("profile");
  };

  return (
    <div className="flex flex-col h-screen max-w-3xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 bg-white border-b border-forest-light shadow-sm flex-shrink-0">
        <div className="flex items-center gap-2.5">
          <div className="w-8 h-8 bg-forest rounded-xl flex items-center justify-center">
            <Leaf className="w-4 h-4 text-white" />
          </div>
          <div>
            <p className="font-display font-bold text-sm text-ink">SIKANUA</p>
            <p className="text-xs text-ink/50">Nutrition & Fitness AI</p>
          </div>
        </div>
        <button
          onClick={handleReset}
          className="flex items-center gap-1.5 text-xs text-ink/50 hover:text-forest transition-colors"
        >
          <RotateCcw className="w-3.5 h-3.5" />
          New Plan
        </button>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-6 space-y-4">
        <AnimatePresence initial={false}>
          {messages.map((msg) => (
            <MessageBubble key={msg.id} role={msg.role} content={msg.content} />
          ))}
        </AnimatePresence>

        {streaming && messages[messages.length - 1]?.role !== "assistant" && (
          <div className="flex gap-3">
            <div className="w-8 h-8 rounded-xl bg-forest flex items-center justify-center flex-shrink-0 mt-0.5">
              <Leaf className="w-4 h-4 text-white" />
            </div>
            <div className="bg-white border border-forest-light rounded-2xl rounded-bl-sm">
              <TypingDots />
            </div>
          </div>
        )}

        {error && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="flex items-start gap-2 bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-700"
          >
            <AlertCircle className="w-4 h-4 flex-shrink-0 mt-0.5" />
            <span>
              <strong>Connection error:</strong> {error}
              <br />
              <span className="text-xs text-red-500">Ensure the backend is running on port 8000.</span>
            </span>
          </motion.div>
        )}

        <div ref={bottomRef} />
      </div>

      {/* Input bar */}
      <div className="flex-shrink-0 px-4 pb-5 pt-3 bg-white border-t border-forest-light">
        <div className="flex items-end gap-2 bg-[#F7FAF8] rounded-2xl border border-forest-light px-4 py-2.5">
          <textarea
            ref={textareaRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKey}
            disabled={streaming}
            placeholder="Ask about your plan or share a new profile…"
            rows={1}
            className="flex-1 bg-transparent resize-none text-sm text-ink placeholder:text-ink/40
                       focus:outline-none max-h-32 leading-relaxed"
            style={{ height: "auto" }}
          />
          <motion.button
            whileTap={{ scale: 0.9 }}
            onClick={sendMessage}
            disabled={streaming || !input.trim()}
            className="flex-shrink-0 w-8 h-8 rounded-xl bg-forest text-white flex items-center justify-center
                       disabled:opacity-40 disabled:cursor-not-allowed hover:bg-forest-dark transition-colors"
          >
            <Send className="w-3.5 h-3.5" />
          </motion.button>
        </div>
        <p className="text-center text-xs text-ink/30 mt-2">
          Powered by PyTorch · Not a substitute for medical advice
        </p>
      </div>
    </div>
  );
}
