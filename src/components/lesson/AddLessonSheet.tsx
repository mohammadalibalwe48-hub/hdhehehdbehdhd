import { useState, useEffect } from 'react';
import { BottomSheet } from '@/components/ui/BottomSheet';
import { LessonFormData, WEEKDAYS_AR } from '@/types/lesson';
import { format } from 'date-fns';
import { Check, Video, MapPin, Clock, Calendar, User, FileText, Link } from 'lucide-react';
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

  // Reset form when sheet opens with new data
  useEffect(() => {
    if (isOpen) {
      setFormData({
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
      setErrors({});
    }
  }, [isOpen, initialData]);

  const toggleWeekday = (day: number) => {
    setFormData(prev => ({
      ...prev,
      weekdays: prev.weekdays.includes(day)
        ? prev.weekdays.filter(d => d !== day)
        : [...prev.weekdays, day].sort(),
    }));
    // Clear weekdays error when user selects a day
    if (errors.weekdays) {
      setErrors(prev => ({ ...prev, weekdays: '' }));
    }
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
    }
  };

  return (
    <BottomSheet
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? 'تعديل الدرس' : 'درس جديد ✨'}
    >
      <div className="px-5 py-2 pb-8 space-y-6">
        {/* Title & Teacher Section */}
        <div className="space-y-4">
          {/* Lesson Title */}
          <div>
            <label className="form-label form-label-required">
              اسم الدرس
            </label>
            <div className="relative">
              <input
                type="text"
                value={formData.title}
                onChange={(e) => {
                  setFormData(prev => ({ ...prev, title: e.target.value }));
                  if (errors.title) setErrors(prev => ({ ...prev, title: '' }));
                }}
                className="input-premium pr-12"
                placeholder="مثال: الرياضيات"
              />
              <div className="absolute right-4 top-1/2 -translate-y-1/2">
                <FileText className="w-5 h-5 text-muted-foreground/40" />
              </div>
            </div>
            {errors.title && <p className="form-error">{errors.title}</p>}
          </div>

          {/* Teacher Name */}
          <div>
            <label className="form-label">
              اسم المدرّس
            </label>
            <div className="relative">
              <input
                type="text"
                value={formData.teacherName}
                onChange={(e) => setFormData(prev => ({ ...prev, teacherName: e.target.value }))}
                className="input-premium pr-12"
                placeholder="مثال: أ. محمد أحمد"
              />
              <div className="absolute right-4 top-1/2 -translate-y-1/2">
                <User className="w-5 h-5 text-muted-foreground/40" />
              </div>
            </div>
          </div>
        </div>

        {/* Divider */}
        <div className="h-px bg-border/60" />

        {/* Weekdays Section */}
        <div>
          <label className="form-label form-label-required mb-3">
            أيام الدرس
          </label>
          <div className="grid grid-cols-4 gap-2">
            {WEEKDAYS_AR.map((day, index) => (
              <motion.button
                key={day.value}
                type="button"
                onClick={() => toggleWeekday(day.value)}
                className={`day-chip ${formData.weekdays.includes(day.value) ? 'selected' : ''}`}
                whileTap={{ scale: 0.95 }}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.03 }}
              >
                <span className="flex items-center justify-center gap-1">
                  {day.short}
                  {formData.weekdays.includes(day.value) && (
                    <Check className="w-3.5 h-3.5" />
                  )}
                </span>
              </motion.button>
            ))}
          </div>
          {errors.weekdays && <p className="form-error">{errors.weekdays}</p>}
        </div>

        {/* Time Section */}
        <div className="space-y-4">
          <div className="flex items-center gap-2 mb-2">
            <Clock className="w-4 h-4 text-primary" />
            <span className="text-sm font-semibold text-foreground">الوقت</span>
          </div>
          
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label form-label-required text-xs">
                البداية
              </label>
              <input
                type="time"
                value={formData.startTime}
                onChange={(e) => {
                  setFormData(prev => ({ ...prev, startTime: e.target.value }));
                  if (errors.startTime) setErrors(prev => ({ ...prev, startTime: '' }));
                }}
                className="input-premium text-center"
                dir="ltr"
              />
              {errors.startTime && <p className="form-error">{errors.startTime}</p>}
            </div>
            <div>
              <label className="form-label text-xs">
                النهاية
              </label>
              <input
                type="time"
                value={formData.endTime}
                onChange={(e) => setFormData(prev => ({ ...prev, endTime: e.target.value }))}
                className="input-premium text-center"
                dir="ltr"
                disabled={!formData.hasEndTime}
              />
            </div>
          </div>
          
          <label className="flex items-center gap-3 cursor-pointer py-1">
            <input
              type="checkbox"
              checked={!formData.hasEndTime}
              onChange={(e) => setFormData(prev => ({ ...prev, hasEndTime: !e.target.checked, endTime: '' }))}
              className="checkbox-premium"
            />
            <span className="text-sm text-muted-foreground">بدون وقت نهاية</span>
          </label>
        </div>

        {/* Date Section */}
        <div className="space-y-4">
          <div className="flex items-center gap-2 mb-2">
            <Calendar className="w-4 h-4 text-primary" />
            <span className="text-sm font-semibold text-foreground">التاريخ</span>
          </div>
          
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label text-xs">
                تاريخ البداية
              </label>
              <input
                type="date"
                value={formData.startDate}
                onChange={(e) => setFormData(prev => ({ ...prev, startDate: e.target.value }))}
                className="input-premium text-center"
                dir="ltr"
              />
            </div>
            <div>
              <label className="form-label text-xs">
                تاريخ النهاية
              </label>
              <input
                type="date"
                value={formData.endDate}
                onChange={(e) => setFormData(prev => ({ ...prev, endDate: e.target.value }))}
                className="input-premium text-center"
                dir="ltr"
                disabled={!formData.hasEndDate}
              />
            </div>
          </div>
          
          <label className="flex items-center gap-3 cursor-pointer py-1">
            <input
              type="checkbox"
              checked={!formData.hasEndDate}
              onChange={(e) => setFormData(prev => ({ ...prev, hasEndDate: !e.target.checked, endDate: '' }))}
              className="checkbox-premium"
            />
            <span className="text-sm text-muted-foreground">بدون تاريخ نهاية (مستمر)</span>
          </label>
        </div>

        {/* Divider */}
        <div className="h-px bg-border/60" />

        {/* Location Section */}
        <div className="space-y-4">
          <label className="form-label">
            نوع الحضور
          </label>
          <div className="grid grid-cols-2 gap-3">
            <motion.button
              type="button"
              onClick={() => setFormData(prev => ({ ...prev, locationType: 'online' }))}
              className={`location-btn ${formData.locationType === 'online' ? 'selected online' : ''}`}
              whileTap={{ scale: 0.98 }}
            >
              <Video className="w-5 h-5" />
              <span>أونلاين</span>
            </motion.button>
            <motion.button
              type="button"
              onClick={() => setFormData(prev => ({ ...prev, locationType: 'in_person' }))}
              className={`location-btn ${formData.locationType === 'in_person' ? 'selected in-person' : ''}`}
              whileTap={{ scale: 0.98 }}
            >
              <MapPin className="w-5 h-5" />
              <span>حضوري</span>
            </motion.button>
          </div>
        </div>

        {/* Location Details */}
        <div>
          <label className="form-label">
            {formData.locationType === 'online' ? 'رابط الاجتماع' : 'العنوان'}
          </label>
          <div className="relative">
            <input
              type="text"
              value={formData.locationDetails}
              onChange={(e) => setFormData(prev => ({ ...prev, locationDetails: e.target.value }))}
              className="input-premium pr-12"
              placeholder={formData.locationType === 'online' ? 'رابط الزوم أو جوجل ميت...' : 'المبنى، الغرفة...'}
              dir={formData.locationType === 'online' ? 'ltr' : 'rtl'}
            />
            <div className="absolute right-4 top-1/2 -translate-y-1/2">
              {formData.locationType === 'online' ? (
                <Link className="w-5 h-5 text-muted-foreground/40" />
              ) : (
                <MapPin className="w-5 h-5 text-muted-foreground/40" />
              )}
            </div>
          </div>
        </div>

        {/* Notes */}
        <div>
          <label className="form-label">
            ملاحظات
          </label>
          <textarea
            value={formData.notes}
            onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
            className="input-premium resize-none"
            rows={3}
            placeholder="أي ملاحظات تريد تذكرها..."
          />
        </div>

        {/* Submit Button */}
        <motion.button
          type="button"
          onClick={handleSubmit}
          className="w-full btn-primary py-4 rounded-2xl text-lg font-bold mt-4"
          whileTap={{ scale: 0.98 }}
        >
          {isEditing ? 'حفظ التغييرات ✓' : 'إضافة الدرس ✨'}
        </motion.button>
      </div>
    </BottomSheet>
  );
}