"use client";
import { create } from "zustand";
import { ChatMessage, UserProfile, Step } from "@/types";

interface SikanuaStore {
  step: Step;
  profile: Partial<UserProfile>;
  messages: ChatMessage[];
  streaming: boolean;

  setStep: (s: Step) => void;
  setProfile: (p: Partial<UserProfile>) => void;
  addMessage: (m: ChatMessage) => void;
  updateLastAssistant: (delta: string) => void;
  setStreaming: (v: boolean) => void;
  clearMessages: () => void;
}

export const useSikanuaStore = create<SikanuaStore>((set) => ({
  step: "welcome",
  profile: {},
  messages: [],
  streaming: false,

  setStep:    (step)    => set({ step }),
  setProfile: (profile) => set((s) => ({ profile: { ...s.profile, ...profile } })),
  setStreaming: (streaming) => set({ streaming }),
  clearMessages: () => set({ messages: [] }),

  addMessage: (msg) =>
    set((s) => ({ messages: [...s.messages, msg] })),

  updateLastAssistant: (delta) =>
    set((s) => {
      const msgs = [...s.messages];
      const last = msgs[msgs.length - 1];
      if (last?.role === "assistant") {
        msgs[msgs.length - 1] = { ...last, content: last.content + delta };
      }
      return { messages: msgs };
    }),
}));
