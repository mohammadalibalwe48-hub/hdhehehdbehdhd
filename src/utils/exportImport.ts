import { Lesson, LessonException } from '@/types/lesson';

export interface ExportData {
  version: 1;
  exportedAt: string;
  lessons: Omit<Lesson, 'user_id'>[];
  exceptions: LessonException[];
}

export function exportLessonsToJSON(
  lessons: Lesson[],
  exceptions: LessonException[]
): void {
  const data: ExportData = {
    version: 1,
    exportedAt: new Date().toISOString(),
    lessons: lessons.map(({ user_id, ...rest }) => rest),
    exceptions: exceptions.filter((e) =>
      lessons.some((l) => l.id === e.lesson_id)
    ),
  };

  const blob = new Blob([JSON.stringify(data, null, 2)], {
    type: 'application/json',
  });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `lessons-backup-${new Date().toISOString().slice(0, 10)}.json`;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

export function readFileAsJSON(file: File): Promise<ExportData> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      try {
        const data = JSON.parse(reader.result as string) as ExportData;
        if (!data.version || !Array.isArray(data.lessons)) {
          reject(new Error('ملف غير صالح'));
          return;
        }
        resolve(data);
      } catch {
        reject(new Error('ملف غير صالح'));
      }
    };
    reader.onerror = () => reject(new Error('فشل قراءة الملف'));
    reader.readAsText(file);
  });
}
