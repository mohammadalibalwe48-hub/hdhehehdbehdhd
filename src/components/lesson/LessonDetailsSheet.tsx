import { useState } from 'react';
import { BottomSheet } from '@/components/ui/BottomSheet';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { LessonOccurrence, WEEKDAYS_AR } from '@/types/lesson';
import { Clock, MapPin, User, Video, Building, Calendar, FileText, Pencil, Trash2, Check } from 'lucide-react';
import { motion } from 'framer-motion';
import { format, parseISO } from 'date-fns';
import { ar } from 'date-fns/locale';

interface LessonDetailsSheetProps {
  isOpen: boolean;
  onClose: () => void;
  occurrence: LessonOccurrence | null;
  onEdit: (type: 'single' | 'all') => void;
  onDelete: (type: 'single' | 'all') => void;
  onMarkComplete?: () => void;
}

export function LessonDetailsSheet({
  isOpen,
  onClose,
  occurrence,
  onEdit,
  onDelete,
  onMarkComplete,
}: LessonDetailsSheetProps) {
  const [showEditOptions, setShowEditOptions] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [deleteType, setDeleteType] = useState<'single' | 'all'>('single');

  if (!occurrence) return null;

  const formatTime = (time: string) => {
    const [hours, minutes] = time.split(':');
    const hour = parseInt(hours);
    const ampm = hour >= 12 ? 'م' : 'ص';
    const hour12 = hour % 12 || 12;
    return `${hour12}:${minutes} ${ampm}`;
  };

  const formatDate = (dateStr: string) => {
    const date = parseISO(dateStr);
    return format(date, 'EEEE، d MMMM yyyy', { locale: ar });
  };

  const handleDeleteClick = (type: 'single' | 'all') => {
    setDeleteType(type);
    setShowDeleteConfirm(true);
  };

  return (
    <>
      <BottomSheet isOpen={isOpen} onClose={onClose} title="تفاصيل الدرس">
        <div className="px-5 py-4">
          {/* Header */}
          <div className="mb-6">
            <h2 className="text-2xl font-bold text-foreground mb-2">{occurrence.title}</h2>
            <div className="flex items-center gap-2 text-muted-foreground">
              <Calendar className="w-4 h-4" />
              <span className="text-sm">{formatDate(occurrence.date)}</span>
            </div>
          </div>

          {/* Details Grid */}
          <div className="space-y-4 mb-6">
            {/* Time */}
            <div className="flex items-start gap-3 p-3 rounded-xl bg-muted/50">
              <Clock className="w-5 h-5 text-primary mt-0.5" />
              <div>
                <p className="text-sm text-muted-foreground">الوقت</p>
                <p className="font-medium text-foreground">
                  {formatTime(occurrence.startTime)}
                  {occurrence.endTime && ` - ${formatTime(occurrence.endTime)}`}
                </p>
              </div>
            </div>

            {/* Teacher */}
            {occurrence.teacherName && (
              <div className="flex items-start gap-3 p-3 rounded-xl bg-muted/50">
                <User className="w-5 h-5 text-primary mt-0.5" />
                <div>
                  <p className="text-sm text-muted-foreground">المدرّس</p>
                  <p className="font-medium text-foreground">{occurrence.teacherName}</p>
                </div>
              </div>
            )}

            {/* Location */}
            <div className="flex items-start gap-3 p-3 rounded-xl bg-muted/50">
              {occurrence.locationType === 'online' ? (
                <Video className="w-5 h-5 text-primary mt-0.5" />
              ) : (
                <Building className="w-5 h-5 text-primary mt-0.5" />
              )}
              <div>
                <p className="text-sm text-muted-foreground">المكان</p>
                <p className="font-medium text-foreground">
                  {occurrence.locationType === 'online' ? 'أونلاين' : 'حضوري'}
                  {occurrence.locationDetails && ` • ${occurrence.locationDetails}`}
                </p>
              </div>
            </div>

            {/* Notes */}
            {occurrence.notes && (
              <div className="flex items-start gap-3 p-3 rounded-xl bg-muted/50">
                <FileText className="w-5 h-5 text-primary mt-0.5" />
                <div>
                  <p className="text-sm text-muted-foreground">ملاحظات</p>
                  <p className="font-medium text-foreground">{occurrence.notes}</p>
                </div>
              </div>
            )}
          </div>

          {/* Action Buttons */}
          <div className="space-y-3">
            {/* Edit Options */}
            {showEditOptions ? (
              <div className="space-y-2">
                <motion.button
                  onClick={() => {
                    onEdit('single');
                    setShowEditOptions(false);
                    onClose();
                  }}
                  className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-secondary text-secondary-foreground font-medium"
                  whileTap={{ scale: 0.98 }}
                >
                  <Pencil className="w-5 h-5" />
                  تعديل هذا الموعد فقط
                </motion.button>
                <motion.button
                  onClick={() => {
                    onEdit('all');
                    setShowEditOptions(false);
                    onClose();
                  }}
                  className="w-full flex items-center justify-center gap-2 py-3 rounded-xl bg-secondary text-secondary-foreground font-medium"
                  whileTap={{ scale: 0.98 }}
                >
                  <Pencil className="w-5 h-5" />
                  تعديل كل المواعيد القادمة
                </motion.button>
                <button
                  onClick={() => setShowEditOptions(false)}
                  className="w-full py-2 text-muted-foreground text-sm"
                >
                  إلغاء
                </button>
              </div>
            ) : (
              <>
                <div className="grid grid-cols-2 gap-3">
                  <motion.button
                    onClick={() => setShowEditOptions(true)}
                    className="flex items-center justify-center gap-2 py-3 rounded-xl bg-secondary text-secondary-foreground font-medium"
                    whileTap={{ scale: 0.98 }}
                  >
                    <Pencil className="w-5 h-5" />
                    تعديل
                  </motion.button>
                  <motion.button
                    onClick={() => handleDeleteClick('single')}
                    className="flex items-center justify-center gap-2 py-3 rounded-xl bg-destructive/10 text-destructive font-medium"
                    whileTap={{ scale: 0.98 }}
                  >
                    <Trash2 className="w-5 h-5" />
                    حذف
                  </motion.button>
                </div>

                <motion.button
                  onClick={() => handleDeleteClick('all')}
                  className="w-full py-3 text-destructive text-sm font-medium"
                  whileTap={{ scale: 0.98 }}
                >
                  حذف كل المواعيد
                </motion.button>
              </>
            )}
          </div>
        </div>
      </BottomSheet>

      <ConfirmDialog
        isOpen={showDeleteConfirm}
        onClose={() => setShowDeleteConfirm(false)}
        onConfirm={() => {
          onDelete(deleteType);
          onClose();
        }}
        title={deleteType === 'single' ? 'حذف هذا الموعد' : 'حذف كل المواعيد'}
        message={
          deleteType === 'single'
            ? 'هل أنت متأكد من حذف هذا الموعد فقط؟'
            : 'هل أنت متأكد من حذف كل مواعيد هذا الدرس؟'
        }
        confirmText="حذف"
        variant="danger"
      />
    </>
  );
}
