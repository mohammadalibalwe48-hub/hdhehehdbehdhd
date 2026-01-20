import { motion } from 'framer-motion';
import { CalendarX, BookOpen } from 'lucide-react';

interface EmptyStateProps {
  type: 'no-lessons' | 'no-lessons-today' | 'list' | 'week' | 'day';
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
    'list': {
      icon: BookOpen,
      title: 'لا توجد دروس مسجّلة',
      description: message || 'أضف درسك الأول بالضغط على زر +',
    },
    'week': {
      icon: CalendarX,
      title: 'لا توجد دروس هذا الأسبوع',
      description: message || 'اختر أسبوعًا آخر أو أضف درسًا جديدًا',
    },
    'day': {
      icon: CalendarX,
      title: 'لا توجد دروس في هذا اليوم',
      description: message || 'اختر يومًا آخر',
    },
  };

  const { icon: Icon, title, description } = config[type];

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="empty-state px-6"
    >
      <div className="w-24 h-24 rounded-3xl bg-muted/50 flex items-center justify-center mb-4">
        <Icon className="w-12 h-12 text-muted-foreground/50" />
      </div>
      <h3 className="text-lg font-bold text-foreground mb-2">{title}</h3>
      <p className="text-muted-foreground text-sm max-w-[200px]">{description}</p>
    </motion.div>
  );
}
