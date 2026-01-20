import { useState } from 'react';
import { BottomSheet } from '@/components/ui/BottomSheet';
import { LessonFormData, WEEKDAYS_AR } from '@/types/lesson';
import { format } from 'date-fns';
import { Check, Video, Building } from 'lucide-react';
import { motion } from 'framer-motion';

interface AddLessonSheetProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: LessonFormData) => void;
  initialData?: Partial<LessonFormData>;
  isEditing?: boolean;
}

export function AddLessonSheet({ isOpen, onClose, onSubmit, initialData, isEditing }: AddLessonSheetProps) {
  const [formData, setFormData] = useState<LessonFormData>({
    title: initialData?.title || '',
    teacherName: initialData?.teacherName || '',
    weekdays: initialData?.weekdays || [],
    startTime: initialData?.startTime || '',
    endTime: initialData?.endTime || '',
    hasEndTime: initialData?.hasEndTime ?? true,
    startDate: initialData?.startDate || format(new Date(), 'yyyy-MM-dd'),
    endDate: initialData?.endDate || '',
    hasEndDate: initialData?.hasEndDate ?? false,
    locationType: initialData?.locationType || 'online',
    locationDetails: initialData?.locationDetails || '',
    notes: initialData?.notes || '',
  });

  const [errors, setErrors] = useState<Record<string, string>>({});

  const toggleWeekday = (day: number) => {
    setFormData(prev => ({
      ...prev,
      weekdays: prev.weekdays.includes(day)
        ? prev.weekdays.filter(d => d !== day)
        : [...prev.weekdays, day].sort(),
    }));
  };

  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};
    
    if (!formData.title.trim()) {
      newErrors.title = 'اسم الدرس مطلوب';
    }
    if (formData.weekdays.length === 0) {
      newErrors.weekdays = 'اختر يومًا واحدًا على الأقل';
    }
    if (!formData.startTime) {
      newErrors.startTime = 'وقت البداية مطلوب';
    }
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = () => {
    if (validate()) {
      onSubmit(formData);
      onClose();
      // Reset form
      setFormData({
        title: '',
        teacherName: '',
        weekdays: [],
        startTime: '',
        endTime: '',
        hasEndTime: true,
        startDate: format(new Date(), 'yyyy-MM-dd'),
        endDate: '',
        hasEndDate: false,
        locationType: 'online',
        locationDetails: '',
        notes: '',
      });
    }
  };

  return (
    <BottomSheet
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? 'تعديل الدرس' : 'إضافة درس جديد'}
    >
      <div className="px-5 py-4 space-y-5">
        {/* Title */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">
            اسم الدرس / المادة <span className="text-destructive">*</span>
          </label>
          <input
            type="text"
            value={formData.title}
            onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
            className="input-premium"
            placeholder="مثال: الرياضيات"
          />
          {errors.title && (
            <p className="text-destructive text-xs mt-1">{errors.title}</p>
          )}
        </div>

        {/* Teacher Name */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">
            اسم المدرّس (اختياري)
          </label>
          <input
            type="text"
            value={formData.teacherName}
            onChange={(e) => setFormData(prev => ({ ...prev, teacherName: e.target.value }))}
            className="input-premium"
            placeholder="مثال: أ. محمد"
          />
        </div>

        {/* Weekdays */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">
            الأيام <span className="text-destructive">*</span>
          </label>
          <div className="flex flex-wrap gap-2">
            {WEEKDAYS_AR.map((day) => (
              <motion.button
                key={day.value}
                type="button"
                onClick={() => toggleWeekday(day.value)}
                className={`day-chip ${formData.weekdays.includes(day.value) ? 'selected' : ''}`}
                whileTap={{ scale: 0.95 }}
              >
                {day.label}
                {formData.weekdays.includes(day.value) && (
                  <Check className="w-3.5 h-3.5 mr-1 inline" />
                )}
              </motion.button>
            ))}
          </div>
          {errors.weekdays && (
            <p className="text-destructive text-xs mt-1">{errors.weekdays}</p>
          )}
        </div>

        {/* Time */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">
              وقت البداية <span className="text-destructive">*</span>
            </label>
            <input
              type="time"
              value={formData.startTime}
              onChange={(e) => setFormData(prev => ({ ...prev, startTime: e.target.value }))}
              className="input-premium"
            />
            {errors.startTime && (
              <p className="text-destructive text-xs mt-1">{errors.startTime}</p>
            )}
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">
              وقت النهاية
            </label>
            <input
              type="time"
              value={formData.endTime}
              onChange={(e) => setFormData(prev => ({ ...prev, endTime: e.target.value }))}
              className="input-premium"
              disabled={!formData.hasEndTime}
            />
          </div>
        </div>
        <label className="flex items-center gap-2 text-sm text-muted-foreground">
          <input
            type="checkbox"
            checked={!formData.hasEndTime}
            onChange={(e) => setFormData(prev => ({ ...prev, hasEndTime: !e.target.checked, endTime: '' }))}
            className="rounded border-border text-primary focus:ring-primary"
          />
          بدون وقت نهاية
        </label>

        {/* Dates */}
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">
              تاريخ البداية
            </label>
            <input
              type="date"
              value={formData.startDate}
              onChange={(e) => setFormData(prev => ({ ...prev, startDate: e.target.value }))}
              className="input-premium"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-foreground mb-2">
              تاريخ النهاية
            </label>
            <input
              type="date"
              value={formData.endDate}
              onChange={(e) => setFormData(prev => ({ ...prev, endDate: e.target.value }))}
              className="input-premium"
              disabled={!formData.hasEndDate}
            />
          </div>
        </div>
        <label className="flex items-center gap-2 text-sm text-muted-foreground">
          <input
            type="checkbox"
            checked={!formData.hasEndDate}
            onChange={(e) => setFormData(prev => ({ ...prev, hasEndDate: !e.target.checked, endDate: '' }))}
            className="rounded border-border text-primary focus:ring-primary"
          />
          بدون نهاية
        </label>

        {/* Location Type */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">
            المكان
          </label>
          <div className="grid grid-cols-2 gap-3">
            <motion.button
              type="button"
              onClick={() => setFormData(prev => ({ ...prev, locationType: 'online' }))}
              className={`flex items-center justify-center gap-2 py-3 rounded-xl border-2 transition-all ${
                formData.locationType === 'online'
                  ? 'border-primary bg-primary/10 text-primary'
                  : 'border-border text-muted-foreground'
              }`}
              whileTap={{ scale: 0.98 }}
            >
              <Video className="w-5 h-5" />
              <span className="font-medium">أونلاين</span>
            </motion.button>
            <motion.button
              type="button"
              onClick={() => setFormData(prev => ({ ...prev, locationType: 'in_person' }))}
              className={`flex items-center justify-center gap-2 py-3 rounded-xl border-2 transition-all ${
                formData.locationType === 'in_person'
                  ? 'border-primary bg-primary/10 text-primary'
                  : 'border-border text-muted-foreground'
              }`}
              whileTap={{ scale: 0.98 }}
            >
              <Building className="w-5 h-5" />
              <span className="font-medium">حضوري</span>
            </motion.button>
          </div>
        </div>

        {/* Location Details */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">
            تفاصيل المكان (اختياري)
          </label>
          <input
            type="text"
            value={formData.locationDetails}
            onChange={(e) => setFormData(prev => ({ ...prev, locationDetails: e.target.value }))}
            className="input-premium"
            placeholder={formData.locationType === 'online' ? 'رابط الاجتماع...' : 'العنوان...'}
          />
        </div>

        {/* Notes */}
        <div>
          <label className="block text-sm font-medium text-foreground mb-2">
            ملاحظات (اختياري)
          </label>
          <textarea
            value={formData.notes}
            onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
            className="input-premium resize-none"
            rows={3}
            placeholder="أي ملاحظات إضافية..."
          />
        </div>

        {/* Submit Button */}
        <motion.button
          type="button"
          onClick={handleSubmit}
          className="w-full btn-primary py-4 rounded-xl text-lg font-bold"
          whileTap={{ scale: 0.98 }}
        >
          {isEditing ? 'حفظ التغييرات' : 'إضافة الدرس'}
        </motion.button>
      </div>
    </BottomSheet>
  );
}
