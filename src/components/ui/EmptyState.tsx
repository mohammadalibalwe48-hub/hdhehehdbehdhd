import { motion } from 'framer-motion';
import { CalendarX, BookOpen } from 'lucide-react';

interface EmptyStateProps {
  type: 'no-lessons' | 'no-lessons-today';
  message?: string;
}

export function EmptyState({ type, message }: EmptyStateProps) {
  const config = {
    'no-lessons': {
      icon: BookOpen,
      title: 'لا توجد دروس',
      description: message || 'أضف درسك الأول بالضغط على زر +',
    },
    'no-lessons-today': {
      icon: CalendarX,
      title: 'لا توجد دروس اليوم',
      description: message || 'يوم فارغ! استمتع بوقتك',
    },
  };

  const { icon: Icon, title, description } = config[type];

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
      className="empty-state px-6"
    >
      <div className="relative mb-5">
        <div
          className="absolute inset-0 rounded-[2rem] blur-2xl opacity-40"
          style={{ background: 'var(--gradient-primary)' }}
          aria-hidden
        />
        <div className="relative w-24 h-24 rounded-[1.75rem] flex items-center justify-center border border-border/50 bg-gradient-to-br from-card to-muted/40 shadow-soft">
          <Icon className="w-11 h-11 text-primary/60" strokeWidth={1.5} />
        </div>
      </div>
      <h3 className="text-lg font-bold text-foreground mb-1.5">{title}</h3>
      <p className="text-muted-foreground text-sm max-w-[240px] leading-relaxed">{description}</p>
    </motion.div>
  );
}
