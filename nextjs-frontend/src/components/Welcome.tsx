"use client";
import { motion } from "framer-motion";
import { Leaf, Zap, Shield, ArrowRight } from "lucide-react";
import { useSikanuaStore } from "@/store";

const features = [
  { icon: Leaf,   label: "Personalised Nutrition",  desc: "7-day meal plans built around your body, goals, and food culture." },
  { icon: Zap,    label: "Adaptive Fitness",         desc: "Workouts matched to your equipment, schedule, and experience." },
  { icon: Shield, label: "Health-Aware",             desc: "Active health conditions shape every recommendation automatically." },
];

export default function Welcome() {
  const setStep = useSikanuaStore((s) => s.setStep);

  return (
    <div className="min-h-screen flex flex-col items-center justify-center px-6 py-16">
      {/* Ambient background blob */}
      <div
        aria-hidden
        className="pointer-events-none absolute top-0 left-1/2 -translate-x-1/2 w-[700px] h-[400px] rounded-full blur-3xl opacity-20"
        style={{ background: "radial-gradient(ellipse, #1A6B3C 0%, transparent 70%)" }}
      />

      <motion.div
        initial={{ opacity: 0, y: 24 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6 }}
        className="relative z-10 max-w-2xl w-full text-center"
      >
        {/* Logo mark */}
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-forest mb-6 shadow-lg shadow-forest/30">
          <Leaf className="w-8 h-8 text-white" />
        </div>

        <h1 className="font-display text-5xl font-bold text-ink tracking-tight leading-tight mb-3">
          SIKANUA
        </h1>
        <p className="text-sage font-display text-lg font-medium mb-2">
          Nutrition & Fitness Intelligence
        </p>
        <p className="text-ink/60 text-base max-w-md mx-auto mb-10 leading-relaxed">
          A PyTorch-powered AI that builds your personalised 7-day diet and
          fitness plan — reviewed and adapted every week.
        </p>

        {/* Feature cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-10">
          {features.map(({ icon: Icon, label, desc }) => (
            <motion.div
              key={label}
              whileHover={{ y: -3 }}
              className="bg-white border border-forest-light rounded-2xl p-5 text-left shadow-sm"
            >
              <div className="w-9 h-9 bg-forest-light rounded-xl flex items-center justify-center mb-3">
                <Icon className="w-4 h-4 text-forest" />
              </div>
              <p className="font-semibold text-sm text-ink mb-1">{label}</p>
              <p className="text-xs text-ink/60 leading-relaxed">{desc}</p>
            </motion.div>
          ))}
        </div>

        <motion.button
          whileHover={{ scale: 1.03 }}
          whileTap={{ scale: 0.97 }}
          onClick={() => setStep("profile")}
          className="inline-flex items-center gap-2 bg-forest text-white font-semibold
                     px-8 py-3.5 rounded-full shadow-lg shadow-forest/30 text-sm
                     hover:bg-forest-dark transition-colors"
        >
          Build My Plan
          <ArrowRight className="w-4 h-4" />
        </motion.button>

        <p className="mt-4 text-xs text-ink/40">
          Free to use · No account required · Powered by PyTorch
        </p>
      </motion.div>
    </div>
  );
}
