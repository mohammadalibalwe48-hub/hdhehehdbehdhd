import { Clock, User, Video, Building, ChevronLeft, Sparkles } from 'lucide-react';
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

  const isOnline = occurrence.locationType === 'online';

  return (
    <div
      onClick={onClick}
      className={`lesson-card p-4 cursor-pointer ${isOnline ? 'online' : 'in-person'} active:scale-[0.98] transition-transform`}
    >
      <div className="flex items-start gap-3">
        {/* Time indicator */}
        <div className="flex-shrink-0 w-16 text-center">
          <div className="relative inline-block">
            <div className="text-sm font-bold text-primary">
              {formatTime(occurrence.startTime)}
            </div>
            {occurrence.endTime && (
              <div className="text-xs text-muted-foreground mt-0.5">
                {formatTime(occurrence.endTime)}
              </div>
            )}
          </div>
        </div>

        {/* Divider with gradient */}
        <div className="relative w-0.5 h-14 bg-gradient-to-b from-primary/40 via-primary to-primary/40 rounded-full flex-shrink-0">
          <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-2 h-2 rounded-full bg-primary shadow-sm" />
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2">
            <h3 className="font-bold text-foreground truncate text-base">{occurrence.title}</h3>
            {occurrence.isException && (
              <div className="flex-shrink-0">
                <Sparkles className="w-3.5 h-3.5 text-accent" />
              </div>
            )}
          </div>
          
          <div className="flex flex-wrap gap-x-3 gap-y-1 mt-2">
            {occurrence.teacherName && (
              <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                <User className="w-3.5 h-3.5 text-primary/70" />
                <span className="truncate max-w-[100px]">{occurrence.teacherName}</span>
              </div>
            )}
            
            <div className="flex items-center gap-1.5 text-xs">
              {isOnline ? (
                <>
                  <Video className="w-3.5 h-3.5 text-primary/70" />
                  <span className="text-primary font-medium">أونلاين</span>
                </>
              ) : (
                <>
                  <Building className="w-3.5 h-3.5 text-accent/70" />
                  <span className="text-accent font-medium">حضوري</span>
                </>
              )}
            </div>
          </div>
        </div>

        {/* Arrow */}
        <div className="flex-shrink-0 self-center">
          <ChevronLeft className="w-5 h-5 text-muted-foreground/40" />
        </div>
      </div>
    </div>
  );
}
