import { useMemo } from 'react';
import { useLessons } from './useLessons';

export function useTeacherSuggestions() {
  const { lessons } = useLessons();

  // Extract unique teacher names from all lessons
  const teacherNames = useMemo(() => {
    const names = new Set<string>();
    
    lessons.forEach(lesson => {
      if (lesson.teacher_name && lesson.teacher_name.trim()) {
        names.add(lesson.teacher_name.trim());
      }
    });

    return Array.from(names).sort((a, b) => a.localeCompare(b, 'ar'));
  }, [lessons]);

  // Filter suggestions based on input
  const getSuggestions = (input: string): string[] => {
    if (!input.trim()) return teacherNames.slice(0, 5);
    
    const query = input.trim().toLowerCase();
    return teacherNames
      .filter(name => name.toLowerCase().includes(query))
      .slice(0, 5);
  };

  return {
    teacherNames,
    getSuggestions,
  };
}
