import { useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { BookOpen, Eye, EyeOff, Loader2, User, Lock, Sparkles } from 'lucide-react';
import { toast } from 'sonner';

export function AuthPage() {
  const [isLogin, setIsLogin] = useState(true);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const { signIn, signUp } = useAuth();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    const trimmedUsername = username.trim();
    
    if (!trimmedUsername || !password.trim()) {
      toast.error('الرجاء إدخال اسم المستخدم وكلمة المرور');
      return;
    }

    if (trimmedUsername.length < 3) {
      toast.error('اسم المستخدم يجب أن يكون 3 أحرف على الأقل');
      return;
    }

    if (password.length < 6) {
      toast.error('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
      return;
    }

    setLoading(true);

    try {
      const { error } = isLogin
        ? await signIn(trimmedUsername, password)
        : await signUp(trimmedUsername, password);

      if (error) {
        if (error.message.includes('Invalid login')) {
          toast.error('اسم المستخدم أو كلمة المرور غير صحيحة');
        } else if (error.message.includes('already registered')) {
          toast.error('اسم المستخدم مستخدم مسبقًا');
        } else {
          toast.error('حدث خطأ، يرجى المحاولة مرة أخرى');
        }
      } else if (!isLogin) {
        toast.success('تم إنشاء الحساب بنجاح! 🎉');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col auth-hero safe-area-top safe-area-bottom">
      {/* Main Content */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 py-8 relative z-10">
        {/* Logo */}
        <div className="w-24 h-24 rounded-[1.5rem] auth-logo flex items-center justify-center mb-6 relative animate-in">
          <BookOpen className="w-12 h-12 text-primary-foreground" strokeWidth={1.5} />
          <div className="absolute -top-1 -left-1 w-5 h-5 rounded-full bg-accent flex items-center justify-center shadow-lg">
            <Sparkles className="w-3 h-3 text-accent-foreground" />
          </div>
        </div>

        {/* Title */}
        <h1 className="text-3xl font-black text-foreground mb-2 text-center animate-in">
          جدول دروسي
        </h1>
        <p className="text-muted-foreground text-base text-center mb-8 animate-in">
          نظّم دروسك بسهولة وذكاء ✨
        </p>

        {/* Auth Card */}
        <div className="w-full max-w-sm animate-in">
          {/* Tabs */}
          <div className="auth-tabs mb-8">
            <button
              onClick={() => setIsLogin(true)}
              className={`auth-tab ${isLogin ? 'active' : ''}`}
            >
              تسجيل الدخول
            </button>
            <button
              onClick={() => setIsLogin(false)}
              className={`auth-tab ${!isLogin ? 'active' : ''}`}
            >
              حساب جديد
            </button>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Username Field */}
            <div>
              <label className="form-label">
                اسم المستخدم
              </label>
              <div className="relative">
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="input-premium pr-12"
                  placeholder="أدخل اسم المستخدم"
                  autoComplete="username"
                  autoCapitalize="off"
                />
                <div className="absolute right-4 top-1/2 -translate-y-1/2">
                  <User className="w-5 h-5 text-muted-foreground/50" />
                </div>
              </div>
            </div>

            {/* Password Field */}
            <div>
              <label className="form-label">
                كلمة المرور
              </label>
              <div className="relative">
                <input
                  type={showPassword ? 'text' : 'password'}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="input-premium pr-12 pl-12"
                  placeholder="••••••••"
                  dir="ltr"
                  autoComplete={isLogin ? 'current-password' : 'new-password'}
                />
                <div className="absolute right-4 top-1/2 -translate-y-1/2">
                  <Lock className="w-5 h-5 text-muted-foreground/50" />
                </div>
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground/70 hover:text-muted-foreground transition-colors"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
              {!isLogin && (
                <p className="form-hint">
                  6 أحرف على الأقل
                </p>
              )}
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={loading}
              className="w-full btn-primary py-4 rounded-2xl text-lg font-bold flex items-center justify-center gap-3 mt-8 active:scale-[0.98] transition-transform"
            >
              {loading ? (
                <Loader2 className="w-6 h-6 animate-spin" />
              ) : isLogin ? (
                <>تسجيل الدخول</>
              ) : (
                <>إنشاء حساب</>
              )}
            </button>
          </form>
        </div>
      </div>

      {/* Footer */}
      <div className="px-6 pb-8 text-center">
        <p className="text-sm text-muted-foreground">
          بياناتك محفوظة ومشفرة بشكل آمن 🔒
        </p>
      </div>
    </div>
  );
}