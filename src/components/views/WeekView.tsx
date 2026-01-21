import { useState, useMemo } from 'react';
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
          <button
            onClick={() => onWeekChange('next')}
            className="p-2.5 rounded-xl hover:bg-muted active:scale-90 transition-all"
          >
            <ChevronRight className="w-5 h-5 text-muted-foreground" />
          </button>
          
          <div className="flex items-center gap-2">
            <Calendar className="w-4 h-4 text-primary" />
            <h2 className="text-base font-bold text-foreground">{formatWeekRange()}</h2>
          </div>
          
          <button
            onClick={() => onWeekChange('prev')}
            className="p-2.5 rounded-xl hover:bg-muted active:scale-90 transition-all"
          >
            <ChevronLeft className="w-5 h-5 text-muted-foreground" />
          </button>
        </div>
      </div>

      {/* Week Calendar */}
      <div className="px-3">
        <div className="grid grid-cols-7 gap-1.5 p-2 bg-muted/30 rounded-2xl">
          {weekDays.map((date) => {
            const isSelected = isSameDay(date, selectedDate);
            const isTodayDate = isToday(date);
            const hasLessonsForDay = hasLessons(date);
            const dayIndex = date.getDay();
            const lessonCount = getOccurrencesForDate(date).length;

            return (
              <button
                key={date.toISOString()}
                onClick={() => setSelectedDate(date)}
                className={`relative flex flex-col items-center py-2.5 px-0.5 rounded-xl transition-colors active:scale-95 ${
                  isSelected
                    ? 'bg-primary text-primary-foreground shadow-button'
                    : isTodayDate
                    ? 'bg-primary/15 text-primary ring-1 ring-primary/30'
                    : 'text-foreground hover:bg-muted'
                }`}
              >
                <span className={`text-[10px] font-medium mb-0.5 ${isSelected ? 'opacity-80' : 'opacity-60'}`}>
                  {WEEKDAYS_AR[dayIndex].short}
                </span>
                <span className="text-lg font-bold leading-none">
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
              </button>
            );
          })}
        </div>
      </div>

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
