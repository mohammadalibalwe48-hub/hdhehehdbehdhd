import { motion, AnimatePresence, useDragControls, PanInfo } from 'framer-motion';
import { useRef } from 'react';
import { X } from 'lucide-react';

interface BottomSheetProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
}

export function BottomSheet({ isOpen, onClose, title, children }: BottomSheetProps) {
  const dragControls = useDragControls();
  const constraintsRef = useRef(null);

  const handleDragEnd = (_: any, info: PanInfo) => {
    if (info.velocity.y > 500 || info.offset.y > 200) {
      onClose();
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Overlay */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.25 }}
            className="fixed inset-0 z-50 bottom-sheet-overlay"
            onClick={onClose}
          />

          {/* Sheet */}
          <motion.div
            ref={constraintsRef}
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 32, stiffness: 350 }}
            drag="y"
            dragControls={dragControls}
            dragConstraints={{ top: 0, bottom: 0 }}
            dragElastic={{ top: 0, bottom: 0.6 }}
            onDragEnd={handleDragEnd}
            className="fixed bottom-0 left-0 right-0 z-50 bottom-sheet-content max-h-[92vh] overflow-hidden"
          >
            {/* Handle */}
            <div
              className="flex justify-center pt-4 pb-2 cursor-grab active:cursor-grabbing"
              onPointerDown={(e) => dragControls.start(e)}
            >
              <div className="bottom-sheet-handle" />
            </div>

            {/* Header */}
            {title && (
              <div className="flex items-center justify-between px-5 pb-4">
                <h2 className="text-xl font-bold text-foreground">{title}</h2>
                <motion.button
                  onClick={onClose}
                  className="p-2.5 rounded-xl hover:bg-muted transition-colors"
                  whileTap={{ scale: 0.95 }}
                >
                  <X className="w-5 h-5 text-muted-foreground" />
                </motion.button>
              </div>
            )}

            {/* Content */}
            <div className="overflow-y-auto max-h-[calc(92vh-80px)] overscroll-contain no-scrollbar">
              {children}
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}