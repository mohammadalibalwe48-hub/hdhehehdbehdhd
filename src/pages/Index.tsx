import { useAuth } from '@/contexts/AuthContext';
import { AuthPage } from './AuthPage';
import { HomePage } from './HomePage';
import { Loader2 } from 'lucide-react';

const Index = () => {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background">
        <div className="flex flex-col items-center gap-4">
          <div className="w-16 h-16 rounded-2xl fab flex items-center justify-center">
            <Loader2 className="w-8 h-8 text-primary-foreground animate-spin" />
          </div>
          <p className="text-muted-foreground">جاري التحميل...</p>
        </div>
      </div>
    );
  }

  return user ? <HomePage /> : <AuthPage />;
};

export default Index;
