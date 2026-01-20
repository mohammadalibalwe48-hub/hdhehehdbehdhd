import { motion } from 'framer-motion';
import { Calendar, List } from 'lucide-react';

type Tab = 'week' | 'list';

interface BottomNavProps {
  activeTab: Tab;
  onTabChange: (tab: Tab) => void;
}

export function BottomNav({ activeTab, onTabChange }: BottomNavProps) {
  const tabs = [
    { id: 'week' as Tab, label: 'الأسبوع', icon: Calendar },
    { id: 'list' as Tab, label: 'القائمة', icon: List },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-30 bottom-nav safe-area-bottom">
      <div className="flex justify-center items-center h-16 max-w-md mx-auto gap-2 px-8">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          const Icon = tab.icon;

          return (
            <motion.button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className={`relative flex items-center justify-center gap-2 px-6 py-2.5 rounded-2xl transition-all flex-1 ${
                isActive
                  ? 'bg-primary text-primary-foreground shadow-button'
                  : 'text-muted-foreground hover:bg-muted/50'
              }`}
              whileTap={{ scale: 0.95 }}
              layout
            >
              <Icon className="w-5 h-5" />
              <motion.span
                className="text-sm font-semibold"
                initial={false}
                animate={{ opacity: isActive ? 1 : 0.8 }}
              >
                {tab.label}
              </motion.span>
              
              {isActive && (
                <motion.div
                  layoutId="activeTabIndicator"
                  className="absolute inset-0 bg-primary rounded-2xl -z-10"
                  transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                />
              )}
            </motion.button>
          );
        })}
      </div>
    </nav>
  );
}
