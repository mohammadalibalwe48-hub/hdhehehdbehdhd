export interface Lesson {
  id: string;
  user_id: string;
  title: string;
  teacher_name: string | null;
  weekdays: number[]; // 0=Sunday, 1=Monday, etc.
  start_time: string; // HH:MM format
  end_time: string | null;
  start_date: string; // YYYY-MM-DD
  end_date: string | null;
  location_type: 'online' | 'in_person';
  location_details: string | null;
  notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface LessonException {
  id: string;
  lesson_id: string;
  exception_date: string;
  is_deleted: boolean;
  title: string | null;
  teacher_name: string | null;
  start_time: string | null;
  end_time: string | null;
  location_type: 'online' | 'in_person' | null;
  location_details: string | null;
  notes: string | null;
  created_at: string;
}

export interface LessonOccurrence {
  lessonId: string;
  date: string; // YYYY-MM-DD
  title: string;
  teacherName: string | null;
  startTime: string;
  endTime: string | null;
  locationType: 'online' | 'in_person';
  locationDetails: string | null;
  notes: string | null;
  isException: boolean;
  exceptionId?: string;
}

export interface LessonFormData {
  title: string;
  teacherName: string;
  weekdays: number[];
  startTime: string;
  endTime: string;
  hasEndTime: boolean;
  startDate: string;
  endDate: string;
  hasEndDate: boolean;
  locationType: 'online' | 'in_person';
  locationDetails: string;
  notes: string;
}

export const WEEKDAYS_AR = [
  { value: 0, label: 'الأحد', short: 'أحد' },
  { value: 1, label: 'الاثنين', short: 'إثنين' },
  { value: 2, label: 'الثلاثاء', short: 'ثلاثاء' },
  { value: 3, label: 'الأربعاء', short: 'أربعاء' },
  { value: 4, label: 'الخميس', short: 'خميس' },
  { value: 5, label: 'الجمعة', short: 'جمعة' },
  { value: 6, label: 'السبت', short: 'سبت' },
] as const;
