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
      <div className="flex justify-center items-center h-16 max-w-md mx-auto gap-1.5 px-5">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id;
          const Icon = tab.icon;

          return (
            <button
              key={tab.id}
              onClick={() => onTabChange(tab.id)}
              className="relative flex items-center justify-center gap-2 px-5 py-2.5 rounded-2xl flex-1 active:scale-95 transition-transform"
            >
              {isActive && (
                <motion.div
                  layoutId="bottom-nav-active"
                  className="absolute inset-0 rounded-2xl"
                  style={{ background: 'var(--gradient-primary)', boxShadow: 'var(--shadow-button)' }}
                  transition={{ type: 'spring', stiffness: 380, damping: 32 }}
                />
              )}
              <Icon
                className={`relative w-5 h-5 transition-colors ${
                  isActive ? 'text-primary-foreground' : 'text-muted-foreground'
                }`}
                strokeWidth={isActive ? 2.4 : 2}
              />
              <span
                className={`relative text-sm font-semibold transition-colors ${
                  isActive ? 'text-primary-foreground' : 'text-muted-foreground'
                }`}
              >
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
