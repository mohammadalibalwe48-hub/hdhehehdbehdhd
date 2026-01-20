import { motion } from 'framer-motion';
import { Plus } from 'lucide-react';

interface FABProps {
  onClick: () => void;
}

export function FAB({ onClick }: FABProps) {
  return (
    <motion.button
      onClick={onClick}
      className="fixed z-40 fab w-14 h-14 rounded-full flex items-center justify-center"
      style={{
        bottom: 'calc(5rem + env(safe-area-inset-bottom, 0px))',
        left: '1rem',
      }}
      whileHover={{ scale: 1.08 }}
      whileTap={{ scale: 0.95 }}
      initial={{ scale: 0, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      transition={{ type: 'spring', stiffness: 300, damping: 20 }}
    >
      <Plus className="w-7 h-7 text-primary-foreground" strokeWidth={2.5} />
    </motion.button>
  );
}
