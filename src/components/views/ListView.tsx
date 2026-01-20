import { useState, useMemo } from 'react';
import { motion } from 'framer-motion';
import { Search, Filter, ChevronDown } from 'lucide-react';
import { format, parseISO, isToday, isTomorrow } from 'date-fns';
import { ar } from 'date-fns/locale';
import { LessonCard } from '@/components/ui/LessonCard';
import { EmptyState } from '@/components/ui/EmptyState';
import { LessonOccurrence, WEEKDAYS_AR } from '@/types/lesson';

interface ListViewProps {
  occurrences: LessonOccurrence[];
  onLessonClick: (occurrence: LessonOccurrence) => void;
}

export function ListView({ occurrences, onLessonClick }: ListViewProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDay, setSelectedDay] = useState<number | null>(null);
  const [showFilters, setShowFilters] = useState(false);

  const filteredOccurrences = useMemo(() => {
    return occurrences.filter(occurrence => {
      // Search filter
      if (searchQuery) {
        const query = searchQuery.toLowerCase();
        const matchesTitle = occurrence.title.toLowerCase().includes(query);
        const matchesTeacher = occurrence.teacherName?.toLowerCase().includes(query);
        if (!matchesTitle && !matchesTeacher) return false;
      }

      // Day filter
      if (selectedDay !== null) {
        const date = parseISO(occurrence.date);
        if (date.getDay() !== selectedDay) return false;
      }

      return true;
    });
  }, [occurrences, searchQuery, selectedDay]);

  // Group by date
  const groupedOccurrences = useMemo(() => {
    const groups: Record<string, LessonOccurrence[]> = {};
    
    filteredOccurrences.forEach(occurrence => {
      if (!groups[occurrence.date]) {
        groups[occurrence.date] = [];
      }
      groups[occurrence.date].push(occurrence);
    });

    // Sort groups by date
    return Object.entries(groups).sort(([a], [b]) => a.localeCompare(b));
  }, [filteredOccurrences]);

  const formatDateHeader = (dateStr: string) => {
    const date = parseISO(dateStr);
    if (isToday(date)) return 'اليوم';
    if (isTomorrow(date)) return 'غدًا';
    return format(date, 'EEEE، d MMMM', { locale: ar });
  };

  return (
    <div className="flex flex-col h-full">
      {/* Search & Filters */}
      <div className="px-4 pt-4 pb-2 space-y-3">
        {/* Search */}
        <div className="relative">
          <Search className="absolute right-3 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="بحث بالمادة أو المدرّس..."
            className="input-premium pr-10"
          />
        </div>

        {/* Filter Toggle */}
        <button
          onClick={() => setShowFilters(!showFilters)}
          className="flex items-center gap-2 text-sm text-muted-foreground"
        >
          <Filter className="w-4 h-4" />
          <span>تصفية</span>
          <ChevronDown className={`w-4 h-4 transition-transform ${showFilters ? 'rotate-180' : ''}`} />
        </button>

        {/* Filters */}
        {showFilters && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="space-y-2"
          >
            <p className="text-xs text-muted-foreground">تصفية حسب اليوم:</p>
            <div className="flex flex-wrap gap-2">
              <motion.button
                onClick={() => setSelectedDay(null)}
                className={`day-chip ${selectedDay === null ? 'selected' : ''}`}
                whileTap={{ scale: 0.95 }}
              >
                الكل
              </motion.button>
              {WEEKDAYS_AR.map((day) => (
                <motion.button
                  key={day.value}
                  onClick={() => setSelectedDay(day.value)}
                  className={`day-chip ${selectedDay === day.value ? 'selected' : ''}`}
                  whileTap={{ scale: 0.95 }}
                >
                  {day.label}
                </motion.button>
              ))}
            </div>
          </motion.div>
        )}
      </div>

      {/* Results Header */}
      <div className="px-4 py-2">
        <p className="text-sm text-muted-foreground">
          {filteredOccurrences.length > 0
            ? `${filteredOccurrences.length} درس`
            : 'لا توجد نتائج'}
        </p>
      </div>

      {/* Lessons List */}
      <div className="flex-1 overflow-y-auto px-4 pb-32">
        {groupedOccurrences.length === 0 ? (
          <EmptyState
            type="no-lessons"
            message={searchQuery ? 'لا توجد نتائج للبحث' : 'لا توجد دروس هذا الأسبوع'}
          />
        ) : (
          <div className="space-y-6">
            {groupedOccurrences.map(([date, lessons]) => (
              <div key={date}>
                <h3 className="text-sm font-bold text-foreground mb-3 sticky top-0 bg-background/95 backdrop-blur-sm py-1">
                  {formatDateHeader(date)}
                </h3>
                <div className="space-y-3">
                  {lessons.map((occurrence, index) => (
                    <LessonCard
                      key={`${occurrence.lessonId}-${occurrence.date}-${index}`}
                      occurrence={occurrence}
                      onClick={() => onLessonClick(occurrence)}
                    />
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
