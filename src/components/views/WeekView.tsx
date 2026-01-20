import { useState, useMemo } from 'react';
import { motion, AnimatePresence, PanInfo } from 'framer-motion';
import { ChevronRight, ChevronLeft } from 'lucide-react';
import { format, addDays, startOfWeek, isToday, isSameDay, parseISO } from 'date-fns';
import { ar } from 'date-fns/locale';
import { LessonCard } from '@/components/ui/LessonCard';
import { EmptyState } from '@/components/ui/EmptyState';
import { LessonOccurrence, WEEKDAYS_AR } from '@/types/lesson';

interface WeekViewProps {
  weekStart: Date;
  onWeekChange: (direction: 'prev' | 'next') => void;
  occurrences: LessonOccurrence[];
  onLessonClick: (occurrence: LessonOccurrence) => void;
}

export function WeekView({ weekStart, onWeekChange, occurrences, onLessonClick }: WeekViewProps) {
  const [selectedDate, setSelectedDate] = useState<Date>(new Date());
  const [direction, setDirection] = useState(0);

  const weekDays = useMemo(() => {
    return Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));
  }, [weekStart]);

  const getOccurrencesForDate = (date: Date) => {
    const dateStr = format(date, 'yyyy-MM-dd');
    return occurrences.filter(o => o.date === dateStr);
  };

  const selectedDateOccurrences = useMemo(() => {
    return getOccurrencesForDate(selectedDate);
  }, [selectedDate, occurrences]);

  const hasLessons = (date: Date) => {
    return getOccurrencesForDate(date).length > 0;
  };

  const handleSwipe = (_: any, info: PanInfo) => {
    if (Math.abs(info.offset.x) > 100) {
      if (info.offset.x > 0) {
        setDirection(1);
        onWeekChange('next'); // RTL: swipe right = next week
      } else {
        setDirection(-1);
        onWeekChange('prev'); // RTL: swipe left = prev week
      }
    }
  };

  const formatWeekRange = () => {
    const endDate = addDays(weekStart, 6);
    const startMonth = format(weekStart, 'MMMM', { locale: ar });
    const endMonth = format(endDate, 'MMMM', { locale: ar });
    const year = format(weekStart, 'yyyy');
    
    if (startMonth === endMonth) {
      return `${format(weekStart, 'd')} - ${format(endDate, 'd')} ${startMonth} ${year}`;
    }
    return `${format(weekStart, 'd')} ${startMonth} - ${format(endDate, 'd')} ${endMonth} ${year}`;
  };

  return (
    <div className="flex flex-col h-full">
      {/* Week Header */}
      <div className="px-4 pt-4 pb-2">
        <div className="flex items-center justify-between mb-4">
          <button
            onClick={() => {
              setDirection(1);
              onWeekChange('next');
            }}
            className="p-2 rounded-full hover:bg-muted transition-colors"
          >
            <ChevronRight className="w-5 h-5 text-muted-foreground" />
          </button>
          <h2 className="text-lg font-bold text-foreground">{formatWeekRange()}</h2>
          <button
            onClick={() => {
              setDirection(-1);
              onWeekChange('prev');
            }}
            className="p-2 rounded-full hover:bg-muted transition-colors"
          >
            <ChevronLeft className="w-5 h-5 text-muted-foreground" />
          </button>
        </div>
      </div>

      {/* Week Calendar */}
      <motion.div
        className="px-4"
        drag="x"
        dragConstraints={{ left: 0, right: 0 }}
        dragElastic={0.2}
        onDragEnd={handleSwipe}
      >
        <AnimatePresence mode="wait" initial={false}>
          <motion.div
            key={weekStart.toISOString()}
            initial={{ opacity: 0, x: direction * 50 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: direction * -50 }}
            transition={{ duration: 0.2 }}
            className="grid grid-cols-7 gap-1"
          >
            {weekDays.map((date) => {
              const isSelected = isSameDay(date, selectedDate);
              const isTodayDate = isToday(date);
              const hasLessonsForDay = hasLessons(date);
              const dayIndex = date.getDay();

              return (
                <motion.button
                  key={date.toISOString()}
                  onClick={() => setSelectedDate(date)}
                  className={`relative flex flex-col items-center py-2 px-1 rounded-xl transition-all ${
                    isSelected
                      ? 'bg-primary text-primary-foreground shadow-medium'
                      : isTodayDate
                      ? 'bg-primary/10 text-primary'
                      : 'text-foreground hover:bg-muted'
                  }`}
                  whileTap={{ scale: 0.95 }}
                >
                  <span className="text-[10px] font-medium mb-1 opacity-70">
                    {WEEKDAYS_AR[dayIndex].short}
                  </span>
                  <span className={`text-lg font-bold ${isSelected ? '' : ''}`}>
                    {format(date, 'd')}
                  </span>
                  {hasLessonsForDay && (
                    <div
                      className={`absolute bottom-1 w-1.5 h-1.5 rounded-full ${
                        isSelected ? 'bg-primary-foreground' : 'bg-accent'
                      }`}
                    />
                  )}
                </motion.button>
              );
            })}
          </motion.div>
        </AnimatePresence>
      </motion.div>

      {/* Selected Day Header */}
      <div className="px-4 pt-4 pb-2">
        <h3 className="text-sm font-medium text-muted-foreground">
          تفاصيل يوم {format(selectedDate, 'EEEE، d MMMM', { locale: ar })}
        </h3>
      </div>

      {/* Lessons List */}
      <div className="flex-1 overflow-y-auto px-4 pb-32">
        {selectedDateOccurrences.length === 0 ? (
          <EmptyState
            type="no-lessons-today"
            message={isToday(selectedDate) ? 'لا توجد دروس اليوم' : 'لا توجد دروس في هذا اليوم'}
          />
        ) : (
          <div className="space-y-3">
            {selectedDateOccurrences.map((occurrence, index) => (
              <LessonCard
                key={`${occurrence.lessonId}-${occurrence.date}-${index}`}
                occurrence={occurrence}
                onClick={() => onLessonClick(occurrence)}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
