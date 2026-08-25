"use client";
import { AnimatePresence, motion } from "framer-motion";
import { useSikanuaStore } from "@/store";
import Welcome from "@/components/Welcome";
import ProfileForm from "@/components/ProfileForm";
import ChatInterface from "@/components/ChatInterface";

export default function Home() {
  const step = useSikanuaStore((s) => s.step);

  return (
    <main>
      <AnimatePresence mode="wait">
        {step === "welcome" && (
          <motion.div key="welcome" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.3 }}>
            <Welcome />
          </motion.div>
        )}
        {step === "profile" && (
          <motion.div key="profile" initial={{ opacity: 0, x: 40 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -40 }} transition={{ duration: 0.3 }}>
            <ProfileForm />
          </motion.div>
        )}
        {step === "chat" && (
          <motion.div key="chat" initial={{ opacity: 0, x: 40 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -40 }} transition={{ duration: 0.3 }}>
            <ChatInterface />
          </motion.div>
        )}
      </AnimatePresence>
    </main>
  );
}
