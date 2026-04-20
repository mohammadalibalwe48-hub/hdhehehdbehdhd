import { User, Video, Building, ChevronLeft, Sparkles } from 'lucide-react';
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
      <div className="flex items-stretch gap-3.5">
        {/* Time indicator */}
        <div className={`flex-shrink-0 w-16 flex flex-col items-center justify-center rounded-xl py-2 ${
          isOnline ? 'bg-primary/10' : 'bg-accent/10'
        }`}>
          <div className={`text-sm font-extrabold leading-tight ${isOnline ? 'text-primary' : 'text-accent-foreground'}`}>
            {formatTime(occurrence.startTime)}
          </div>
          {occurrence.endTime && (
            <>
              <div className="w-5 h-px my-1 bg-current opacity-20" />
              <div className="text-[11px] text-muted-foreground font-medium leading-tight">
                {formatTime(occurrence.endTime)}
              </div>
            </>
          )}
        </div>

        {/* Content */}
        <div className="flex-1 min-w-0 flex flex-col justify-center py-0.5">
          <div className="flex items-start justify-between gap-2">
            <h3 className="font-bold text-foreground truncate text-base leading-snug">{occurrence.title}</h3>
            {occurrence.isException && (
              <div className="flex-shrink-0 mt-0.5">
                <Sparkles className="w-3.5 h-3.5 text-accent" />
              </div>
            )}
          </div>

          <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-1.5">
            {occurrence.teacherName && (
              <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
                <User className="w-3.5 h-3.5 text-muted-foreground/70" />
                <span className="truncate max-w-[110px]">{occurrence.teacherName}</span>
              </div>
            )}

            <div className={`inline-flex items-center gap-1.5 text-[11px] font-semibold px-2 py-0.5 rounded-full ${
              isOnline
                ? 'bg-primary/10 text-primary'
                : 'bg-accent/15 text-accent-foreground'
            }`}>
              {isOnline ? (
                <>
                  <Video className="w-3 h-3" />
                  <span>أونلاين</span>
                </>
              ) : (
                <>
                  <Building className="w-3 h-3" />
                  <span>حضوري</span>
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
