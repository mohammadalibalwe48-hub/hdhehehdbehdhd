import { useState, useEffect, useRef } from 'react';
import { BottomSheet } from '@/components/ui/BottomSheet';
import { LessonFormData, WEEKDAYS_AR } from '@/types/lesson';
import { useTeacherSuggestions } from '@/hooks/useTeacherSuggestions';
import { format } from 'date-fns';
import { Check, Video, MapPin, Clock, Calendar, User, FileText, Link, ChevronDown, Sparkles } from 'lucide-react';

interface AddLessonSheetProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (data: LessonFormData) => void;
  initialData?: Partial<LessonFormData>;
  isEditing?: boolean;
}

export function AddLessonSheet({ isOpen, onClose, onSubmit, initialData, isEditing }: AddLessonSheetProps) {
  const { getSuggestions } = useTeacherSuggestions();
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
  const [showTeacherSuggestions, setShowTeacherSuggestions] = useState(false);
  const [teacherSuggestions, setTeacherSuggestions] = useState<string[]>([]);
  const teacherInputRef = useRef<HTMLInputElement>(null);

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
      setShowTeacherSuggestions(false);
    }
  }, [isOpen, initialData]);

  // Update teacher suggestions when input changes
  useEffect(() => {
    const suggestions = getSuggestions(formData.teacherName);
    setTeacherSuggestions(suggestions);
  }, [formData.teacherName, getSuggestions]);

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

  const selectTeacher = (name: string) => {
    setFormData(prev => ({ ...prev, teacherName: name }));
    setShowTeacherSuggestions(false);
    teacherInputRef.current?.blur();
  };

  return (
    <BottomSheet
      isOpen={isOpen}
      onClose={onClose}
      title={isEditing ? 'تعديل الدرس' : 'درس جديد ✨'}
    >
      <div className="px-5 py-2 pb-8 space-y-5">
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

          {/* Teacher Name with Suggestions */}
          <div className="relative">
            <label className="form-label flex items-center gap-1.5">
              اسم المدرّس
              {teacherSuggestions.length > 0 && (
                <span className="text-xs text-primary flex items-center gap-0.5">
                  <Sparkles className="w-3 h-3" />
                  اقتراحات
                </span>
              )}
            </label>
            <div className="relative">
              <input
                ref={teacherInputRef}
                type="text"
                value={formData.teacherName}
                onChange={(e) => setFormData(prev => ({ ...prev, teacherName: e.target.value }))}
                onFocus={() => setShowTeacherSuggestions(true)}
                onBlur={() => setTimeout(() => setShowTeacherSuggestions(false), 200)}
                className="input-premium pr-12"
                placeholder="مثال: أ. محمد أحمد"
              />
              <div className="absolute right-4 top-1/2 -translate-y-1/2">
                <User className="w-5 h-5 text-muted-foreground/40" />
              </div>
              {teacherSuggestions.length > 0 && (
                <button
                  type="button"
                  onClick={() => setShowTeacherSuggestions(!showTeacherSuggestions)}
                  className="absolute left-4 top-1/2 -translate-y-1/2"
                >
                  <ChevronDown className={`w-4 h-4 text-muted-foreground transition-transform ${showTeacherSuggestions ? 'rotate-180' : ''}`} />
                </button>
              )}
            </div>

            {/* Teacher Suggestions Dropdown */}
            {showTeacherSuggestions && teacherSuggestions.length > 0 && (
              <div className="absolute z-50 top-full mt-1 w-full bg-card border border-border rounded-xl shadow-lg overflow-hidden animate-in">
                {teacherSuggestions.map((name) => (
                  <button
                    key={name}
                    type="button"
                    onClick={() => selectTeacher(name)}
                    className="w-full px-4 py-3 text-right hover:bg-muted/50 flex items-center gap-2 transition-colors border-b border-border/50 last:border-0"
                  >
                    <User className="w-4 h-4 text-primary" />
                    <span className="text-sm font-medium text-foreground">{name}</span>
                  </button>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Divider */}
        <div className="h-px bg-gradient-to-l from-transparent via-border to-transparent" />

        {/* Weekdays Section */}
        <div>
          <label className="form-label form-label-required mb-3">
            أيام الدرس
          </label>
          <div className="grid grid-cols-7 gap-1.5">
            {WEEKDAYS_AR.map((day) => (
              <button
                key={day.value}
                type="button"
                onClick={() => toggleWeekday(day.value)}
                className={`day-chip-compact ${formData.weekdays.includes(day.value) ? 'selected' : ''} active:scale-95 transition-transform`}
              >
                <span className="text-xs font-semibold">{day.short}</span>
                {formData.weekdays.includes(day.value) && (
                  <div className="absolute -top-1 -left-1 w-4 h-4 rounded-full bg-accent flex items-center justify-center">
                    <Check className="w-2.5 h-2.5 text-accent-foreground" />
                  </div>
                )}
              </button>
            ))}
          </div>
          {errors.weekdays && <p className="form-error">{errors.weekdays}</p>}
        </div>

        {/* Time Section */}
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-primary/10 flex items-center justify-center">
              <Clock className="w-4 h-4 text-primary" />
            </div>
            <span className="text-sm font-semibold text-foreground">الوقت</span>
          </div>
          
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label form-label-required text-xs">البداية</label>
              <input
                type="time"
                value={formData.startTime}
                onChange={(e) => {
                  setFormData(prev => ({ ...prev, startTime: e.target.value }));
                  if (errors.startTime) setErrors(prev => ({ ...prev, startTime: '' }));
                }}
                className="input-premium text-center text-sm"
                dir="ltr"
              />
              {errors.startTime && <p className="form-error">{errors.startTime}</p>}
            </div>
            <div>
              <label className="form-label text-xs">النهاية</label>
              <input
                type="time"
                value={formData.endTime}
                onChange={(e) => setFormData(prev => ({ ...prev, endTime: e.target.value }))}
                className="input-premium text-center text-sm"
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
        <div className="space-y-3">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-accent/10 flex items-center justify-center">
              <Calendar className="w-4 h-4 text-accent" />
            </div>
            <span className="text-sm font-semibold text-foreground">التاريخ</span>
          </div>
          
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="form-label text-xs">تاريخ البداية</label>
              <input
                type="date"
                value={formData.startDate}
                onChange={(e) => setFormData(prev => ({ ...prev, startDate: e.target.value }))}
                className="input-premium text-center text-sm"
                dir="ltr"
              />
            </div>
            <div>
              <label className="form-label text-xs">تاريخ النهاية</label>
              <input
                type="date"
                value={formData.endDate}
                onChange={(e) => setFormData(prev => ({ ...prev, endDate: e.target.value }))}
                className="input-premium text-center text-sm"
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
        <div className="h-px bg-gradient-to-l from-transparent via-border to-transparent" />

        {/* Location Section */}
        <div className="space-y-3">
          <label className="form-label">نوع الحضور</label>
          <div className="grid grid-cols-2 gap-3">
            <button
              type="button"
              onClick={() => setFormData(prev => ({ ...prev, locationType: 'online' }))}
              className={`location-btn ${formData.locationType === 'online' ? 'selected online' : ''} active:scale-[0.97] transition-transform`}
            >
              <Video className="w-5 h-5" />
              <span>أونلاين</span>
            </button>
            <button
              type="button"
              onClick={() => setFormData(prev => ({ ...prev, locationType: 'in_person' }))}
              className={`location-btn ${formData.locationType === 'in_person' ? 'selected in-person' : ''} active:scale-[0.97] transition-transform`}
            >
              <MapPin className="w-5 h-5" />
              <span>حضوري</span>
            </button>
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
          <label className="form-label">ملاحظات</label>
          <textarea
            value={formData.notes}
            onChange={(e) => setFormData(prev => ({ ...prev, notes: e.target.value }))}
            className="input-premium resize-none"
            rows={2}
            placeholder="أي ملاحظات تريد تذكرها..."
          />
        </div>

        {/* Submit Button */}
        <button
          type="button"
          onClick={handleSubmit}
          className="w-full btn-primary py-4 rounded-2xl text-lg font-bold mt-4 relative overflow-hidden active:scale-[0.98] transition-transform"
        >
          <span className="relative z-10">
            {isEditing ? 'حفظ التغييرات ✓' : 'إضافة الدرس ✨'}
          </span>
        </button>
      </div>
    </BottomSheet>
  );
}
