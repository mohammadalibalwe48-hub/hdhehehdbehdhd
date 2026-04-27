import { useEffect, useState } from 'react';
import { Smartphone, X, Download } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const DISMISS_KEY = 'studies:android-install-banner-dismissed-at';
/** Show again this long after the user dismissed it. */
const DISMISS_TTL_MS = 1000 * 60 * 60 * 24 * 14; // 14 days

const APK_URL = '/studies.apk';

function isAndroid(): boolean {
  if (typeof navigator === 'undefined') return false;
  const ua = navigator.userAgent || '';
  return /android/i.test(ua);
}

function isStandalonePwa(): boolean {
  if (typeof window === 'undefined') return false;
  // Users who already installed the PWA shouldn't be nagged about the APK.
  return (
    window.matchMedia?.('(display-mode: standalone)').matches ||
    // @ts-expect-error iOS-only legacy flag, harmless elsewhere
    window.navigator?.standalone === true
  );
}

function wasRecentlyDismissed(): boolean {
  try {
    const raw = window.localStorage.getItem(DISMISS_KEY);
    if (!raw) return false;
    const ts = Number(raw);
    if (!Number.isFinite(ts)) return false;
    return Date.now() - ts < DISMISS_TTL_MS;
  } catch {
    return false;
  }
}

export function AndroidInstallBanner() {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (!isAndroid()) return;
    if (isStandalonePwa()) return;
    if (wasRecentlyDismissed()) return;
    // Small delay so it doesn't race the splash / auth flash on first paint.
    const t = window.setTimeout(() => setVisible(true), 800);
    return () => window.clearTimeout(t);
  }, []);

  const dismiss = () => {
    try {
      window.localStorage.setItem(DISMISS_KEY, String(Date.now()));
    } catch {
      /* private mode — just hide for the session */
    }
    setVisible(false);
  };

  const download = () => {
    // Mark dismissed on download so we don't prompt right after install.
    try {
      window.localStorage.setItem(DISMISS_KEY, String(Date.now()));
    } catch {
      /* noop */
    }
    setVisible(false);
  };

  return (
    <AnimatePresence>
      {visible && (
        <>
          <motion.div
            key="scrim"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.2 }}
            onClick={dismiss}
            className="fixed inset-0 z-[60] bg-black/40 backdrop-blur-sm"
          />
          <motion.div
            key="sheet"
            role="dialog"
            aria-labelledby="android-install-title"
            aria-describedby="android-install-desc"
            initial={{ y: 80, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: 80, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 360, damping: 34 }}
            className="fixed inset-x-0 bottom-0 z-[70] px-3 pb-3 pt-0"
            style={{
              paddingBottom: 'max(0.75rem, env(safe-area-inset-bottom))',
            }}
          >
            <div className="glass-card rounded-3xl border border-border/60 bg-card/95 p-5 shadow-2xl">
              <div className="flex items-start gap-3">
                <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-gradient-to-br from-primary to-primary/60 text-primary-foreground shadow-lg">
                  <Smartphone className="h-5 w-5" />
                </div>
                <div className="flex-1 min-w-0">
                  <h2
                    id="android-install-title"
                    className="text-base font-extrabold leading-tight text-foreground"
                  >
                    جرّب تطبيق Studies على هاتفك
                  </h2>
                  <p
                    id="android-install-desc"
                    className="mt-1 text-sm leading-relaxed text-muted-foreground"
                  >
                    تطبيق Android رسمي — يعمل دون إنترنت، يذكّرك قبل كل درس،
                    ويتزامن مع حسابك هنا مباشرة.
                  </p>
                </div>
                <button
                  onClick={dismiss}
                  aria-label="إغلاق"
                  className="inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-muted-foreground transition hover:bg-muted hover:text-foreground"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>

              <div className="mt-4 flex flex-col-reverse gap-2 sm:flex-row sm:items-center sm:justify-end">
                <button
                  onClick={dismiss}
                  className="inline-flex h-11 items-center justify-center rounded-2xl px-4 text-sm font-semibold text-muted-foreground transition hover:bg-muted hover:text-foreground"
                >
                  ليس الآن
                </button>
                <a
                  href={APK_URL}
                  download="studies.apk"
                  onClick={download}
                  className="inline-flex h-11 items-center justify-center gap-2 rounded-2xl bg-gradient-to-r from-primary to-primary/80 px-5 text-sm font-bold text-primary-foreground shadow-lg shadow-primary/25 transition hover:shadow-primary/40 active:translate-y-px"
                >
                  <Download className="h-4 w-4" />
                  تنزيل التطبيق (APK)
                </a>
              </div>

              <p className="mt-3 text-[11px] leading-relaxed text-muted-foreground/90">
                بعد التنزيل قد يطلب منك الهاتف السماح بتثبيت التطبيقات من المتصفح.
                هذا طبيعي لأن التطبيق خارج متجر Google Play.
              </p>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}

export default AndroidInstallBanner;
