import { useState, useMemo } from 'react';
import { motion } from 'framer-motion';
import { Search, Filter, ChevronDown, Clock, User, Video, MapPin } from 'lucide-react';
import { Lesson, WEEKDAYS_AR } from '@/types/lesson';
import { EmptyState } from '@/components/ui/EmptyState';

interface ListViewProps {
  lessons: Lesson[];
  onLessonClick: (lesson: Lesson) => void;
}

export function ListView({ lessons, onLessonClick }: ListViewProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedDay, setSelectedDay] = useState<number | null>(null);
  const [showFilters, setShowFilters] = useState(false);

  // Filter lessons based on search and day filter
  const filteredLessons = useMemo(() => {
    return lessons.filter(lesson => {
      // Search filter
      if (searchQuery) {
        const query = searchQuery.toLowerCase();
        const matchesTitle = lesson.title.toLowerCase().includes(query);
        const matchesTeacher = lesson.teacher_name?.toLowerCase().includes(query);
        if (!matchesTitle && !matchesTeacher) return false;
      }

      // Day filter
      if (selectedDay !== null) {
        if (!lesson.weekdays.includes(selectedDay)) return false;
      }

      return true;
    });
  }, [lessons, searchQuery, selectedDay]);

  // Group lessons by their weekdays (Saturday to Friday order)
  const groupedByDay = useMemo(() => {
    // Create a map for each day of the week (Saturday=6 to Friday=5)
    const dayOrder = [6, 0, 1, 2, 3, 4, 5]; // Saturday first
    const groups: Record<number, Lesson[]> = {};

    dayOrder.forEach(day => {
      const lessonsForDay = filteredLessons.filter(lesson => 
        lesson.weekdays.includes(day)
      ).sort((a, b) => a.start_time.localeCompare(b.start_time));
      
      if (lessonsForDay.length > 0) {
        groups[day] = lessonsForDay;
      }
    });

    return groups;
  }, [filteredLessons]);

  const getDayName = (dayValue: number) => {
    return WEEKDAYS_AR.find(d => d.value === dayValue)?.label || '';
  };

  const formatTime = (time: string) => {
    const [hours, minutes] = time.split(':');
    const h = parseInt(hours);
    const period = h >= 12 ? 'م' : 'ص';
    const displayHour = h > 12 ? h - 12 : h === 0 ? 12 : h;
    return `${displayHour}:${minutes} ${period}`;
  };

  const totalLessonsCount = Object.values(groupedByDay).reduce((acc, arr) => acc + arr.length, 0);
  const dayOrder = [6, 0, 1, 2, 3, 4, 5]; // Saturday first

  return (
    <div className="flex flex-col h-full">
      {/* Search & Filters */}
      <div className="px-4 pt-4 pb-2 space-y-3">
        {/* Search */}
        <div className="relative">
          <Search className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-muted-foreground/50" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="بحث بالمادة أو المدرّس..."
            className="input-premium pr-12"
          />
        </div>

        {/* Filter Toggle */}
        <button
          onClick={() => setShowFilters(!showFilters)}
          className="flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors"
        >
          <Filter className="w-4 h-4" />
          <span>تصفية حسب اليوم</span>
          <ChevronDown className={`w-4 h-4 transition-transform ${showFilters ? 'rotate-180' : ''}`} />
        </button>

        {/* Filters */}
        {showFilters && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="space-y-3 pt-2"
          >
            <div className="flex flex-wrap gap-2">
              <motion.button
                onClick={() => setSelectedDay(null)}
                className={`day-chip ${selectedDay === null ? 'selected' : ''}`}
                whileTap={{ scale: 0.95 }}
              >
                الكل
              </motion.button>
              {dayOrder.map((dayValue) => (
                <motion.button
                  key={dayValue}
                  onClick={() => setSelectedDay(dayValue)}
                  className={`day-chip ${selectedDay === dayValue ? 'selected' : ''}`}
                  whileTap={{ scale: 0.95 }}
                >
                  {WEEKDAYS_AR.find(d => d.value === dayValue)?.short}
                </motion.button>
              ))}
            </div>
          </motion.div>
        )}
      </div>

      {/* Results Header */}
      <div className="px-4 py-3 border-b border-border/40">
        <p className="text-sm font-medium text-muted-foreground">
          {totalLessonsCount > 0
            ? `${lessons.length} درس مسجّل`
            : 'لا توجد دروس'}
        </p>
      </div>

      {/* Lessons List - Grouped by Day */}
      <div className="flex-1 overflow-y-auto px-4 pb-32">
        {totalLessonsCount === 0 ? (
          <EmptyState
            type="list"
            message={searchQuery ? 'لا توجد نتائج للبحث' : 'لا توجد دروس مسجّلة'}
          />
        ) : (
          <div className="space-y-6 py-4">
            {dayOrder.map(dayValue => {
              const dayLessons = groupedByDay[dayValue];
              if (!dayLessons || dayLessons.length === 0) return null;

              return (
                <motion.div 
                  key={dayValue}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                >
                  {/* Day Header */}
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-10 h-10 rounded-xl bg-primary/10 flex items-center justify-center">
                      <span className="text-sm font-bold text-primary">
                        {WEEKDAYS_AR.find(d => d.value === dayValue)?.short}
                      </span>
                    </div>
                    <div>
                      <h3 className="font-bold text-foreground">{getDayName(dayValue)}</h3>
                      <p className="text-xs text-muted-foreground">{dayLessons.length} درس</p>
                    </div>
                  </div>

                  {/* Lessons for this day */}
                  <div className="space-y-3 mr-5 pr-8 border-r-2 border-primary/20">
                    {dayLessons.map((lesson, index) => (
                      <motion.button
                        key={lesson.id}
                        onClick={() => onLessonClick(lesson)}
                        className="lesson-card w-full text-right p-4"
                        initial={{ opacity: 0, x: -10 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: index * 0.05 }}
                        whileTap={{ scale: 0.98 }}
                      >
                        <div className="flex items-start justify-between gap-3">
                          <div className="flex-1 min-w-0">
                            {/* Title */}
                            <h4 className="font-bold text-foreground text-base truncate mb-1.5">
                              {lesson.title}
                            </h4>
                            
                            {/* Meta info */}
                            <div className="flex flex-wrap items-center gap-x-4 gap-y-1.5">
                              {/* Time */}
                              <div className="flex items-center gap-1.5 text-muted-foreground">
                                <Clock className="w-3.5 h-3.5" />
                                <span className="text-sm font-medium" dir="ltr">
                                  {formatTime(lesson.start_time)}
                                  {lesson.end_time && ` - ${formatTime(lesson.end_time)}`}
                                </span>
                              </div>
                              
                              {/* Teacher */}
                              {lesson.teacher_name && (
                                <div className="flex items-center gap-1.5 text-muted-foreground">
                                  <User className="w-3.5 h-3.5" />
                                  <span className="text-sm truncate max-w-[100px]">{lesson.teacher_name}</span>
                                </div>
                              )}
                            </div>

                            {/* Days this lesson repeats */}
                            <div className="flex flex-wrap gap-1 mt-2">
                              {lesson.weekdays.sort().map(d => (
                                <span 
                                  key={d} 
                                  className={`text-[10px] px-2 py-0.5 rounded-full ${
                                    d === dayValue 
                                      ? 'bg-primary/20 text-primary font-semibold' 
                                      : 'bg-muted text-muted-foreground'
                                  }`}
                                >
                                  {WEEKDAYS_AR.find(w => w.value === d)?.short}
                                </span>
                              ))}
                            </div>
                          </div>
                          
                          {/* Location badge */}
                          <div className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold shrink-0 ${
                            lesson.location_type === 'online'
                              ? 'bg-primary/10 text-primary' 
                              : 'bg-accent/10 text-accent-foreground'
                          }`}>
                            {lesson.location_type === 'online' ? (
                              <>
                                <Video className="w-3.5 h-3.5" />
                                <span>أونلاين</span>
                              </>
                            ) : (
                              <>
                                <MapPin className="w-3.5 h-3.5" />
                                <span>حضوري</span>
                              </>
                            )}
                          </div>
                        </div>
                      </motion.button>
                    ))}
                  </div>
                </motion.div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}