import { useState } from 'react';
import { motion } from 'framer-motion';
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
      {/* Decorative elements */}
      <div className="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none">
        <div className="absolute top-10 right-10 w-40 h-40 rounded-full bg-primary/5 blur-3xl" />
        <div className="absolute bottom-40 left-10 w-60 h-60 rounded-full bg-accent/5 blur-3xl" />
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 py-8 relative z-10">
        {/* Logo */}
        <motion.div
          initial={{ scale: 0, opacity: 0, rotateZ: -10 }}
          animate={{ scale: 1, opacity: 1, rotateZ: 0 }}
          transition={{ type: 'spring', stiffness: 200, damping: 15, delay: 0.1 }}
          className="w-28 h-28 rounded-[2rem] auth-logo flex items-center justify-center mb-8 relative"
        >
          <BookOpen className="w-14 h-14 text-primary-foreground" strokeWidth={1.5} />
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.5, type: 'spring' }}
            className="absolute -top-1 -left-1 w-6 h-6 rounded-full bg-accent flex items-center justify-center shadow-lg"
          >
            <Sparkles className="w-3.5 h-3.5 text-accent-foreground" />
          </motion.div>
        </motion.div>

        {/* Title */}
        <motion.h1
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.2 }}
          className="text-4xl font-black text-foreground mb-2 text-center"
        >
          جدول دروسي
        </motion.h1>
        <motion.p
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.3 }}
          className="text-muted-foreground text-lg text-center mb-10"
        >
          نظّم دروسك بسهولة وذكاء ✨
        </motion.p>

        {/* Auth Card */}
        <motion.div
          initial={{ y: 30, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.4, type: 'spring', stiffness: 100 }}
          className="w-full max-w-sm"
        >
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
            <motion.button
              type="submit"
              disabled={loading}
              className="w-full btn-primary py-4 rounded-2xl text-lg font-bold flex items-center justify-center gap-3 mt-8"
              whileTap={{ scale: 0.98 }}
            >
              {loading ? (
                <Loader2 className="w-6 h-6 animate-spin" />
              ) : isLogin ? (
                <>
                  تسجيل الدخول
                </>
              ) : (
                <>
                  إنشاء حساب
                </>
              )}
            </motion.button>
          </form>
        </motion.div>
      </div>

      {/* Footer */}
      <motion.div 
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.6 }}
        className="px-6 pb-8 text-center"
      >
        <p className="text-sm text-muted-foreground">
          بياناتك محفوظة ومشفرة بشكل آمن 🔒
        </p>
      </motion.div>
    </div>
  );
}