import { motion } from 'framer-motion';
import { Plus, Sparkles } from 'lucide-react';

interface FABProps {
  onClick: () => void;
}

export function FAB({ onClick }: FABProps) {
  return (
    <motion.button
      onClick={onClick}
      className="fixed z-40 fab w-16 h-16 rounded-2xl flex items-center justify-center group"
      style={{
        bottom: 'calc(5.5rem + env(safe-area-inset-bottom, 0px))',
        left: '1rem',
      }}
      whileHover={{ scale: 1.08, rotate: 5 }}
      whileTap={{ scale: 0.92 }}
      initial={{ scale: 0, opacity: 0, rotate: -180 }}
      animate={{ scale: 1, opacity: 1, rotate: 0 }}
      transition={{ type: 'spring', stiffness: 300, damping: 20, delay: 0.2 }}
    >
      {/* Inner glow */}
      <div className="absolute inset-0 rounded-2xl bg-gradient-to-br from-primary-foreground/20 to-transparent opacity-0 group-hover:opacity-100 transition-opacity" />
      
      {/* Icon */}
      <motion.div
        className="relative"
        whileHover={{ rotate: 90 }}
        transition={{ type: 'spring', stiffness: 300 }}
      >
        <Plus className="w-8 h-8 text-primary-foreground" strokeWidth={2.5} />
      </motion.div>

      {/* Sparkle decoration */}
      <motion.div
        className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-accent flex items-center justify-center shadow-sm"
        initial={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{ delay: 0.5, type: 'spring' }}
      >
        <Sparkles className="w-3 h-3 text-accent-foreground" />
      </motion.div>
    </motion.button>
  );
}
