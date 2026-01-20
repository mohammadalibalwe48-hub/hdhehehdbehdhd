import { motion } from 'framer-motion';
import { Clock, MapPin, User, Video, Building, ChevronLeft } from 'lucide-react';
import { LessonOccurrence } from '@/types/lesson';

interface LessonCardProps {
  occurrence: LessonOccurrence;
  onClick?: () => void;
  showDate?: boolean;
}

export function LessonCard({ occurrence, onClick, showDate }: LessonCardProps) {
  const formatTime = (time: string) => {
    const [hours, minutes] = time.split(':');
    const hour = parseInt(hours);
    const ampm = hour >= 12 ? 'م' : 'ص';
    const hour12 = hour % 12 || 12;
    return `${hour12}:${minutes} ${ampm}`;
  };

  return (
    <motion.div
      onClick={onClick}
      className="lesson-card p-4 cursor-pointer active:scale-[0.98] transition-transform"
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      whileTap={{ scale: 0.98 }}
    >
      <div className="flex items-start gap-3">
        {/* Time indicator */}
        <div className="flex-shrink-0 w-16 text-center">
          <div className="text-sm font-bold text-primary">
            {formatTime(occurrence.startTime)}
          </div>
          {occurrence.endTime && (
            <div className="text-xs text-muted-foreground mt-0.5">
              {formatTime(occurrence.endTime)}
            </div>
          )}
        </div>

        {/* Divider */}
        <div className="w-0.5 h-12 bg-primary/20 rounded-full flex-shrink-0" />

        {/* Content */}
        <div className="flex-1 min-w-0">
          <h3 className="font-bold text-foreground truncate">{occurrence.title}</h3>
          
          <div className="flex flex-wrap gap-2 mt-2">
            {occurrence.teacherName && (
              <div className="flex items-center gap-1 text-xs text-muted-foreground">
                <User className="w-3.5 h-3.5" />
                <span className="truncate">{occurrence.teacherName}</span>
              </div>
            )}
            
            <div className="flex items-center gap-1 text-xs text-muted-foreground">
              {occurrence.locationType === 'online' ? (
                <>
                  <Video className="w-3.5 h-3.5" />
                  <span>أونلاين</span>
                </>
              ) : (
                <>
                  <Building className="w-3.5 h-3.5" />
                  <span>حضوري</span>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Arrow */}
        <ChevronLeft className="w-5 h-5 text-muted-foreground/50 flex-shrink-0" />
      </div>
    </motion.div>
  );
}
