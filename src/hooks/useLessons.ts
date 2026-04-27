import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import { Lesson, LessonException, LessonOccurrence, LessonFormData } from '@/types/lesson';
import { ExportData } from '@/utils/exportImport';
import { format, parseISO, addDays, startOfWeek, endOfWeek, isWithinInterval } from 'date-fns';
import { toast } from 'sonner';

export function useLessons() {
  const { user } = useAuth();
  const queryClient = useQueryClient();

  // Fetch all lessons
  const lessonsQuery = useQuery({
    queryKey: ['lessons', user?.id],
    queryFn: async () => {
      if (!user) return [];
      const { data, error } = await supabase
        .from('lessons')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false });
      
      if (error) throw error;
      return data as Lesson[];
    },
    enabled: !!user,
  });

  // Fetch all exceptions
  const exceptionsQuery = useQuery({
    queryKey: ['lesson_exceptions', user?.id],
    queryFn: async () => {
      if (!user) return [];
      const { data, error } = await supabase
        .from('lesson_exceptions')
        .select('*');
      
      if (error) throw error;
      return data as LessonException[];
    },
    enabled: !!user,
  });

  // Create lesson
  const createLesson = useMutation({
    mutationFn: async (formData: LessonFormData) => {
      if (!user) throw new Error('Not authenticated');
      
      const { data, error } = await supabase
        .from('lessons')
        .insert({
          user_id: user.id,
          title: formData.title,
          teacher_name: formData.teacherName || null,
          weekdays: formData.weekdays,
          start_time: formData.startTime,
          end_time: formData.hasEndTime ? formData.endTime : null,
          start_date: formData.startDate || format(new Date(), 'yyyy-MM-dd'),
          end_date: formData.hasEndDate ? formData.endDate : null,
          location_type: formData.locationType,
          location_details: formData.locationDetails || null,
          notes: formData.notes || null,
        })
        .select()
        .single();
      
      if (error) throw error;
      return data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lessons'] });
      toast.success('تم إضافة الدرس بنجاح');
    },
    onError: () => {
      toast.error('حدث خطأ أثناء إضافة الدرس');
    },
  });

  // Update lesson
  const updateLesson = useMutation({
    mutationFn: async ({ id, formData }: { id: string; formData: Partial<LessonFormData> }) => {
      const updateData: Partial<Lesson> = {};
      if (formData.title !== undefined) updateData.title = formData.title;
      if (formData.teacherName !== undefined) updateData.teacher_name = formData.teacherName || null;
      if (formData.weekdays !== undefined) updateData.weekdays = formData.weekdays;
      if (formData.startTime !== undefined) updateData.start_time = formData.startTime;
      if (formData.hasEndTime !== undefined) updateData.end_time = formData.hasEndTime ? formData.endTime : null;
      if (formData.startDate !== undefined) updateData.start_date = formData.startDate;
      if (formData.hasEndDate !== undefined) updateData.end_date = formData.hasEndDate ? formData.endDate : null;
      if (formData.locationType !== undefined) updateData.location_type = formData.locationType;
      if (formData.locationDetails !== undefined) updateData.location_details = formData.locationDetails || null;
      if (formData.notes !== undefined) updateData.notes = formData.notes || null;

      const { error } = await supabase
        .from('lessons')
        .update(updateData)
        .eq('id', id);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lessons'] });
      toast.success('تم تعديل الدرس بنجاح');
    },
    onError: () => {
      toast.error('حدث خطأ أثناء تعديل الدرس');
    },
  });

  // Delete lesson
  const deleteLesson = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('lessons')
        .delete()
        .eq('id', id);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lessons'] });
      toast.success('تم حذف الدرس بنجاح');
    },
    onError: () => {
      toast.error('حدث خطأ أثناء حذف الدرس');
    },
  });

  // Create exception (single occurrence edit/delete)
  const createException = useMutation({
    mutationFn: async (data: Partial<LessonException> & { lesson_id: string; exception_date: string }) => {
      const { error } = await supabase
        .from('lesson_exceptions')
        .upsert({
          lesson_id: data.lesson_id,
          exception_date: data.exception_date,
          is_deleted: data.is_deleted || false,
          title: data.title || null,
          teacher_name: data.teacher_name || null,
          start_time: data.start_time || null,
          end_time: data.end_time || null,
          location_type: data.location_type || null,
          location_details: data.location_details || null,
          notes: data.notes || null,
        });
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lesson_exceptions'] });
      toast.success('تم تعديل الموعد بنجاح');
    },
    onError: () => {
      toast.error('حدث خطأ أثناء تعديل الموعد');
    },
  });

  // Delete exception
  const deleteException = useMutation({
    mutationFn: async (id: string) => {
      const { error } = await supabase
        .from('lesson_exceptions')
        .delete()
        .eq('id', id);
      
      if (error) throw error;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lesson_exceptions'] });
    },
  });

  // Import lessons from exported data
  const importLessons = useMutation({
    mutationFn: async (data: ExportData) => {
      if (!user) throw new Error('Not authenticated');

      const oldToNewId = new Map<string, string>();

      for (const lesson of data.lessons) {
        const { id: oldId, created_at, updated_at, ...rest } = lesson;
        const { data: inserted, error } = await supabase
          .from('lessons')
          .insert({ ...rest, user_id: user.id })
          .select()
          .single();

        if (error) throw error;
        oldToNewId.set(oldId, inserted.id);
      }

      const exceptionsToInsert = data.exceptions
        .filter((e) => oldToNewId.has(e.lesson_id))
        .map(({ id, created_at, ...rest }) => ({
          ...rest,
          lesson_id: oldToNewId.get(rest.lesson_id)!,
        }));

      if (exceptionsToInsert.length > 0) {
        const { error } = await supabase
          .from('lesson_exceptions')
          .insert(exceptionsToInsert);
        if (error) throw error;
      }
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['lessons'] });
      queryClient.invalidateQueries({ queryKey: ['lesson_exceptions'] });
      toast.success('تم استيراد الدروس بنجاح');
    },
    onError: () => {
      toast.error('حدث خطأ أثناء استيراد الدروس');
    },
  });

  // Get occurrences for a specific week
  const getOccurrencesForWeek = (weekStart: Date): LessonOccurrence[] => {
    const lessons = lessonsQuery.data || [];
    const exceptions = exceptionsQuery.data || [];
    const occurrences: LessonOccurrence[] = [];
    const weekEnd = endOfWeek(weekStart, { weekStartsOn: 0 });

    lessons.forEach(lesson => {
      const lessonStartDate = parseISO(lesson.start_date);
      const lessonEndDate = lesson.end_date ? parseISO(lesson.end_date) : null;

      // Check each day of the week
      for (let i = 0; i < 7; i++) {
        const currentDate = addDays(weekStart, i);
        const currentDayOfWeek = currentDate.getDay();
        const dateStr = format(currentDate, 'yyyy-MM-dd');

        // Check if this lesson occurs on this day
        if (!lesson.weekdays.includes(currentDayOfWeek)) continue;
        
        // Check if within lesson date range
        if (currentDate < lessonStartDate) continue;
        if (lessonEndDate && currentDate > lessonEndDate) continue;

        // Check for exception
        const exception = exceptions.find(
          e => e.lesson_id === lesson.id && e.exception_date === dateStr
        );

        // Skip if deleted
        if (exception?.is_deleted) continue;

        occurrences.push({
          lessonId: lesson.id,
          date: dateStr,
          title: exception?.title || lesson.title,
          teacherName: exception?.teacher_name ?? lesson.teacher_name,
          startTime: exception?.start_time || lesson.start_time,
          endTime: exception?.end_time ?? lesson.end_time,
          locationType: exception?.location_type || lesson.location_type,
          locationDetails: exception?.location_details ?? lesson.location_details,
          notes: exception?.notes ?? lesson.notes,
          isException: !!exception,
          exceptionId: exception?.id,
        });
      }
    });

    // Sort by date and time
    return occurrences.sort((a, b) => {
      if (a.date !== b.date) return a.date.localeCompare(b.date);
      return a.startTime.localeCompare(b.startTime);
    });
  };

  // Get occurrences for a specific date
  const getOccurrencesForDate = (date: Date): LessonOccurrence[] => {
    const dateStr = format(date, 'yyyy-MM-dd');
    const weekStart = startOfWeek(date, { weekStartsOn: 0 });
    const allOccurrences = getOccurrencesForWeek(weekStart);
    return allOccurrences.filter(o => o.date === dateStr);
  };

  return {
    lessons: lessonsQuery.data || [],
    exceptions: exceptionsQuery.data || [],
    isLoading: lessonsQuery.isLoading || exceptionsQuery.isLoading,
    error: lessonsQuery.error || exceptionsQuery.error,
    createLesson,
    updateLesson,
    deleteLesson,
    createException,
    deleteException,
    importLessons,
    getOccurrencesForWeek,
    getOccurrencesForDate,
  };
}
