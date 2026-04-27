import { useState, useMemo, useRef } from 'react';
import { motion } from 'framer-motion';
import { startOfWeek, addWeeks, subWeeks } from 'date-fns';
import { LogOut, BookOpen, Sparkles, Download, Upload } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';
import { useLessons } from '@/hooks/useLessons';
import { BottomNav } from '@/components/ui/BottomNav';
import { FAB } from '@/components/ui/FAB';
import { ThemeToggle } from '@/components/ui/ThemeToggle';
import { WeekView } from '@/components/views/WeekView';
import { ListView } from '@/components/views/ListView';
import { AddLessonSheet } from '@/components/lesson/AddLessonSheet';
import { LessonDetailsSheet } from '@/components/lesson/LessonDetailsSheet';
import { LessonFormData, LessonOccurrence, Lesson } from '@/types/lesson';
import { exportLessonsToJSON, readFileAsJSON } from '@/utils/exportImport';
import { toast } from 'sonner';

type Tab = 'week' | 'list';

export function HomePage() {
  const { signOut, user } = useAuth();
  const {
    lessons,
    exceptions,
    isLoading,
    createLesson,
    updateLesson,
    deleteLesson,
    createException,
    importLessons,
    getOccurrencesForWeek,
  } = useLessons();

  const fileInputRef = useRef<HTMLInputElement>(null);

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

  const handleExport = () => {
    if (lessons.length === 0) {
      toast.error('لا توجد دروس للتصدير');
      return;
    }
    exportLessonsToJSON(lessons, exceptions);
    toast.success('تم تصدير الدروس بنجاح');
  };

  const handleImportClick = () => {
    fileInputRef.current?.click();
  };

  const handleImportFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      const data = await readFileAsJSON(file);
      importLessons.mutate(data);
    } catch {
      toast.error('ملف غير صالح');
    }

    e.target.value = '';
  };

  const handleSignOut = async () => {
    await signOut();
    toast.success('تم تسجيل الخروج');
  };

  // Extract username from email
  const displayName = user?.user_metadata?.username || user?.email?.split('@')[0] || 'المستخدم';

  return (
    <div className="min-h-screen bg-background flex flex-col max-w-md mx-auto relative overflow-hidden">
      {/* Background decoration */}
      <div className="pointer-events-none absolute -top-16 -right-16 w-80 h-80 rounded-full bg-primary/10 blur-3xl -z-10" />
      <div className="pointer-events-none absolute top-1/3 -left-20 w-72 h-72 rounded-full bg-accent/8 blur-3xl -z-10" />
      <div className="pointer-events-none absolute bottom-40 right-0 w-60 h-60 rounded-full bg-primary/5 blur-3xl -z-10" />

      {/* Premium Header */}
      <header className="sticky top-0 z-40 glass-card border-b border-border/40 safe-area-top">
        <div className="flex items-center justify-between px-4 py-3">
          <div className="flex items-center gap-3">
            <motion.div
              className="relative w-11 h-11 rounded-2xl fab flex items-center justify-center"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
            >
              <BookOpen className="w-5 h-5 text-primary-foreground relative z-10" strokeWidth={2} />
            </motion.div>
            <div>
              <h1 className="text-lg font-extrabold leading-tight text-gradient">جدول دروسي</h1>
              <p className="text-xs text-muted-foreground flex items-center gap-1 mt-0.5">
                <span>أهلاً</span>
                <span className="font-semibold text-foreground/80">{displayName}</span>
                <Sparkles className="w-3 h-3 text-accent" />
              </p>
            </div>
          </div>
          <div className="flex items-center gap-1.5">
            <motion.button
              onClick={handleExport}
              aria-label="تصدير الدروس"
              className="p-2.5 rounded-xl hover:bg-primary/10 transition-colors group"
              whileTap={{ scale: 0.95 }}
            >
              <Download className="w-5 h-5 text-muted-foreground group-hover:text-primary transition-colors" />
            </motion.button>
            <motion.button
              onClick={handleImportClick}
              aria-label="استيراد الدروس"
              className="p-2.5 rounded-xl hover:bg-primary/10 transition-colors group"
              whileTap={{ scale: 0.95 }}
            >
              <Upload className="w-5 h-5 text-muted-foreground group-hover:text-primary transition-colors" />
            </motion.button>
            <input
              ref={fileInputRef}
              type="file"
              accept=".json"
              onChange={handleImportFile}
              className="hidden"
            />
            <ThemeToggle />
            <motion.button
              onClick={handleSignOut}
              aria-label="تسجيل الخروج"
              className="p-2.5 rounded-xl hover:bg-destructive/10 transition-colors group"
              whileTap={{ scale: 0.95 }}
            >
              <LogOut className="w-5 h-5 text-muted-foreground group-hover:text-destructive transition-colors" />
            </motion.button>
          </div>
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
            occurrences={occurrences}
            onLessonClick={handleLessonClick}
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
