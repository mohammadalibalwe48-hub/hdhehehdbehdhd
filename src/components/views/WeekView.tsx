import { useState, useMemo } from 'react';
import { motion, AnimatePresence, PanInfo } from 'framer-motion';
import { ChevronRight, ChevronLeft, Calendar } from 'lucide-react';
import { format, addDays, isToday, isSameDay } from 'date-fns';
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
      <div className="px-4 pt-4 pb-3">
        <div className="flex items-center justify-between">
          <motion.button
            onClick={() => {
              setDirection(1);
              onWeekChange('next');
            }}
            className="p-2.5 rounded-xl hover:bg-muted transition-colors"
            whileTap={{ scale: 0.9 }}
          >
            <ChevronRight className="w-5 h-5 text-muted-foreground" />
          </motion.button>
          
          <div className="flex items-center gap-2">
            <Calendar className="w-4 h-4 text-primary" />
            <h2 className="text-base font-bold text-foreground">{formatWeekRange()}</h2>
          </div>
          
          <motion.button
            onClick={() => {
              setDirection(-1);
              onWeekChange('prev');
            }}
            className="p-2.5 rounded-xl hover:bg-muted transition-colors"
            whileTap={{ scale: 0.9 }}
          >
            <ChevronLeft className="w-5 h-5 text-muted-foreground" />
          </motion.button>
        </div>
      </div>

      {/* Week Calendar */}
      <motion.div
        className="px-3"
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
            className="grid grid-cols-7 gap-1.5 p-2 bg-muted/30 rounded-2xl"
          >
            {weekDays.map((date, index) => {
              const isSelected = isSameDay(date, selectedDate);
              const isTodayDate = isToday(date);
              const hasLessonsForDay = hasLessons(date);
              const dayIndex = date.getDay();
              const lessonCount = getOccurrencesForDate(date).length;

              return (
                <motion.button
                  key={date.toISOString()}
                  onClick={() => setSelectedDate(date)}
                  className={`relative flex flex-col items-center py-2.5 px-0.5 rounded-xl transition-all ${
                    isSelected
                      ? 'bg-primary text-primary-foreground shadow-button'
                      : isTodayDate
                      ? 'bg-primary/15 text-primary ring-1 ring-primary/30'
                      : 'text-foreground hover:bg-muted'
                  }`}
                  whileTap={{ scale: 0.92 }}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: index * 0.03 }}
                >
                  <span className={`text-[10px] font-medium mb-0.5 ${isSelected ? 'opacity-80' : 'opacity-60'}`}>
                    {WEEKDAYS_AR[dayIndex].short}
                  </span>
                  <span className={`text-lg font-bold leading-none ${isSelected ? '' : ''}`}>
                    {format(date, 'd')}
                  </span>
                  
                  {/* Lesson indicator */}
                  {hasLessonsForDay && (
                    <div className="flex gap-0.5 mt-1.5">
                      {Array.from({ length: Math.min(lessonCount, 3) }).map((_, i) => (
                        <div
                          key={i}
                          className={`w-1 h-1 rounded-full ${
                            isSelected ? 'bg-primary-foreground/70' : 'bg-accent'
                          }`}
                        />
                      ))}
                    </div>
                  )}
                </motion.button>
              );
            })}
          </motion.div>
        </AnimatePresence>
      </motion.div>

      {/* Selected Day Header */}
      <div className="px-4 pt-4 pb-2">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-medium text-muted-foreground">
            {format(selectedDate, 'EEEE، d MMMM', { locale: ar })}
          </h3>
          {selectedDateOccurrences.length > 0 && (
            <span className="text-xs font-medium text-primary bg-primary/10 px-2 py-0.5 rounded-full">
              {selectedDateOccurrences.length} {selectedDateOccurrences.length === 1 ? 'درس' : 'دروس'}
            </span>
          )}
        </div>
      </div>

      {/* Lessons List */}
      <div className="flex-1 overflow-y-auto px-4 pb-32">
        {selectedDateOccurrences.length === 0 ? (
          <EmptyState
            type="no-lessons-today"
            message={isToday(selectedDate) ? 'لا توجد دروس اليوم' : 'لا توجد دروس في هذا اليوم'}
          />
        ) : (
          <motion.div 
            className="space-y-3"
            initial="hidden"
            animate="visible"
            variants={{
              visible: {
                transition: {
                  staggerChildren: 0.05,
                },
              },
            }}
          >
            {selectedDateOccurrences.map((occurrence, index) => (
              <LessonCard
                key={`${occurrence.lessonId}-${occurrence.date}-${index}`}
                occurrence={occurrence}
                onClick={() => onLessonClick(occurrence)}
              />
            ))}
          </motion.div>
        )}
      </div>
    </div>
  );
}
