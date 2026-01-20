import { useState, useMemo } from 'react';
import { motion } from 'framer-motion';
import { startOfWeek, addWeeks, subWeeks } from 'date-fns';
import { LogOut, BookOpen, Sparkles } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';
import { useLessons } from '@/hooks/useLessons';
import { BottomNav } from '@/components/ui/BottomNav';
import { FAB } from '@/components/ui/FAB';
import { WeekView } from '@/components/views/WeekView';
import { ListView } from '@/components/views/ListView';
import { AddLessonSheet } from '@/components/lesson/AddLessonSheet';
import { LessonDetailsSheet } from '@/components/lesson/LessonDetailsSheet';
import { LessonFormData, LessonOccurrence, Lesson } from '@/types/lesson';
import { toast } from 'sonner';

type Tab = 'week' | 'list';

export function HomePage() {
  const { signOut, user } = useAuth();
  const {
    lessons,
    isLoading,
    createLesson,
    updateLesson,
    deleteLesson,
    createException,
    getOccurrencesForWeek,
  } = useLessons();

  const [activeTab, setActiveTab] = useState<Tab>('week');
  const [weekStart, setWeekStart] = useState(() => startOfWeek(new Date(), { weekStartsOn: 0 }));
  const [showAddSheet, setShowAddSheet] = useState(false);
  const [showDetailsSheet, setShowDetailsSheet] = useState(false);
  const [selectedOccurrence, setSelectedOccurrence] = useState<LessonOccurrence | null>(null);
  const [editingLesson, setEditingLesson] = useState<{ lesson: Lesson; type: 'single' | 'all'; date: string } | null>(null);

  // Get occurrences for the current week
  const occurrences = useMemo(() => {
    return getOccurrencesForWeek(weekStart);
  }, [weekStart, lessons, getOccurrencesForWeek]);

  const handleWeekChange = (direction: 'prev' | 'next') => {
    setWeekStart(prev =>
      direction === 'next' ? addWeeks(prev, 1) : subWeeks(prev, 1)
    );
  };

  const handleAddLesson = (formData: LessonFormData) => {
    createLesson.mutate(formData);
  };

  const handleLessonClick = (occurrence: LessonOccurrence) => {
    setSelectedOccurrence(occurrence);
    setShowDetailsSheet(true);
  };

  // Handle click from ListView (which uses Lesson objects)
  const handleLessonFromListClick = (lesson: Lesson) => {
    // For list view, we edit the entire lesson (all occurrences)
    setEditingLesson({ lesson, type: 'all', date: '' });
    setShowAddSheet(true);
  };

  const handleEdit = (type: 'single' | 'all') => {
    if (!selectedOccurrence) return;
    
    const lesson = lessons.find(l => l.id === selectedOccurrence.lessonId);
    if (!lesson) return;

    setEditingLesson({ lesson, type, date: selectedOccurrence.date });
    setShowDetailsSheet(false);
    setShowAddSheet(true);
  };

  const handleEditSubmit = (formData: LessonFormData) => {
    if (!editingLesson) {
      handleAddLesson(formData);
      return;
    }

    if (editingLesson.type === 'all') {
      // Update the main lesson
      updateLesson.mutate({
        id: editingLesson.lesson.id,
        formData,
      });
    } else {
      // Create an exception for this date
      createException.mutate({
        lesson_id: editingLesson.lesson.id,
        exception_date: editingLesson.date,
        title: formData.title,
        teacher_name: formData.teacherName || null,
        start_time: formData.startTime,
        end_time: formData.hasEndTime ? formData.endTime : null,
        location_type: formData.locationType,
        location_details: formData.locationDetails || null,
        notes: formData.notes || null,
      });
    }

    setEditingLesson(null);
  };

  const handleDelete = (type: 'single' | 'all') => {
    if (!selectedOccurrence) return;

    if (type === 'all') {
      deleteLesson.mutate(selectedOccurrence.lessonId, {
        onSuccess: () => {
          toast.success('تم حذف الدرس', {
            action: {
              label: 'تراجع',
              onClick: () => {
                toast.info('عذرًا، لا يمكن التراجع حاليًا');
              },
            },
          });
        },
      });
    } else {
      // Delete only this occurrence (create exception)
      createException.mutate({
        lesson_id: selectedOccurrence.lessonId,
        exception_date: selectedOccurrence.date,
        is_deleted: true,
      }, {
        onSuccess: () => {
          toast.success('تم حذف الموعد', {
            action: {
              label: 'تراجع',
              onClick: () => {
                toast.info('عذرًا، لا يمكن التراجع حاليًا');
              },
            },
          });
        },
      });
    }

    setSelectedOccurrence(null);
  };

  const getEditInitialData = (): Partial<LessonFormData> | undefined => {
    if (!editingLesson) return undefined;

    const { lesson, type, date } = editingLesson;

    if (type === 'single' && selectedOccurrence) {
      // Use the occurrence data (might be from exception)
      return {
        title: selectedOccurrence.title,
        teacherName: selectedOccurrence.teacherName || '',
        weekdays: lesson.weekdays,
        startTime: selectedOccurrence.startTime,
        endTime: selectedOccurrence.endTime || '',
        hasEndTime: !!selectedOccurrence.endTime,
        startDate: lesson.start_date,
        endDate: lesson.end_date || '',
        hasEndDate: !!lesson.end_date,
        locationType: selectedOccurrence.locationType,
        locationDetails: selectedOccurrence.locationDetails || '',
        notes: selectedOccurrence.notes || '',
      };
    }

    // Use the main lesson data
    return {
      title: lesson.title,
      teacherName: lesson.teacher_name || '',
      weekdays: lesson.weekdays,
      startTime: lesson.start_time,
      endTime: lesson.end_time || '',
      hasEndTime: !!lesson.end_time,
      startDate: lesson.start_date,
      endDate: lesson.end_date || '',
      hasEndDate: !!lesson.end_date,
      locationType: lesson.location_type,
      locationDetails: lesson.location_details || '',
      notes: lesson.notes || '',
    };
  };

  const handleSignOut = async () => {
    await signOut();
    toast.success('تم تسجيل الخروج');
  };

  // Extract username from email
  const displayName = user?.user_metadata?.username || user?.email?.split('@')[0] || 'المستخدم';

  return (
    <div className="min-h-screen bg-background flex flex-col max-w-md mx-auto relative">
      {/* Premium Header */}
      <header className="sticky top-0 z-40 glass-card border-b border-border/40 safe-area-top">
        <div className="flex items-center justify-between px-5 py-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl fab flex items-center justify-center">
              <BookOpen className="w-5 h-5 text-primary-foreground" strokeWidth={2} />
            </div>
            <div>
              <h1 className="text-lg font-bold text-foreground leading-tight">جدول دروسي</h1>
              <p className="text-xs text-muted-foreground">أهلاً {displayName} 👋</p>
            </div>
          </div>
          <motion.button
            onClick={handleSignOut}
            className="p-2.5 rounded-xl hover:bg-muted transition-colors"
            whileTap={{ scale: 0.95 }}
          >
            <LogOut className="w-5 h-5 text-muted-foreground" />
          </motion.button>
        </div>
      </header>

      {/* Main Content */}
      <main className="flex-1 overflow-hidden pb-24">
        {activeTab === 'week' ? (
          <WeekView
            weekStart={weekStart}
            onWeekChange={handleWeekChange}
            occurrences={occurrences}
            onLessonClick={handleLessonClick}
          />
        ) : (
          <ListView
            lessons={lessons}
            onLessonClick={handleLessonFromListClick}
          />
        )}
      </main>

      {/* FAB */}
      <FAB onClick={() => {
        setEditingLesson(null);
        setShowAddSheet(true);
      }} />

      {/* Bottom Navigation */}
      <BottomNav activeTab={activeTab} onTabChange={setActiveTab} />

      {/* Add/Edit Lesson Sheet */}
      <AddLessonSheet
        isOpen={showAddSheet}
        onClose={() => {
          setShowAddSheet(false);
          setEditingLesson(null);
        }}
        onSubmit={handleEditSubmit}
        initialData={getEditInitialData()}
        isEditing={!!editingLesson}
      />

      {/* Lesson Details Sheet */}
      <LessonDetailsSheet
        isOpen={showDetailsSheet}
        onClose={() => setShowDetailsSheet(false)}
        occurrence={selectedOccurrence}
        onEdit={handleEdit}
        onDelete={handleDelete}
      />
    </div>
  );
}