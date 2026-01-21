import { Plus, Sparkles } from 'lucide-react';

interface FABProps {
  onClick: () => void;
}

export function FAB({ onClick }: FABProps) {
  return (
    <button
      onClick={onClick}
      className="fixed z-40 fab w-14 h-14 rounded-2xl flex items-center justify-center group active:scale-90 transition-transform animate-in"
      style={{
        bottom: 'calc(5.5rem + env(safe-area-inset-bottom, 0px))',
        left: '1rem',
      }}
    >
      {/* Icon */}
      <Plus className="w-7 h-7 text-primary-foreground" strokeWidth={2.5} />

      {/* Sparkle decoration */}
      <div className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-accent flex items-center justify-center shadow-sm">
        <Sparkles className="w-2.5 h-2.5 text-accent-foreground" />
      </div>
    </button>
  );
}
