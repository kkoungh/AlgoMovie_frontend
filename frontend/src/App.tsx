/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect, useCallback } from 'react';
import { 
  Film, Sparkles, Sliders, LogOut, Heart, Globe, 
  HelpCircle, User as UserIcon, Star, Play, X, PlayCircle, RefreshCw
} from 'lucide-react';

import { Movie, RecommendationWeights, RedisCacheStats } from './types';
import AuthScreen from './components/AuthScreen';
import HeroSlider from './components/HeroSlider';
import RecommendationSlider from './components/RecommendationSlider';
import AdaptiveDashboard from './components/AdaptiveDashboard';
import RedisConsole from './components/RedisConsole';
import AISuggestions from './components/AISuggestions';

export default function App() {
  // Auth state
  const [token, setToken] = useState<string | null>(localStorage.getItem('algomovie_token'));
  const [user, setUser] = useState<{
    id: string;
    email: string;
    name: string;
    ratingsCount: number;
    likedCount: number;
    dislikedCount: number;
    preferences: string[];
  } | null>(null);

  // Recommendations state
  const [movies, setMovies] = useState<Movie[]>([]);
  const [activeWeights, setActiveWeights] = useState<RecommendationWeights>({ alpha: 0.3, beta: 0.4, gamma: 0.3 });
  const [genreFilter, setGenreFilter] = useState<string>('전체');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [cacheHit, setCacheHit] = useState(false);
  const [loading, setLoading] = useState(false);

  // Redis monitor state
  const [redisStats, setRedisStats] = useState<RedisCacheStats>({
    hits: 0,
    misses: 0,
    keysCount: 0,
    entries: []
  });

  // Selected spotlight movie detailing
  const [spotlightMovie, setSpotlightMovie] = useState<Movie | null>(null);

  // Video Playing Modal state
  const [playingMovie, setPlayingMovie] = useState<Movie | null>(null);

  // Status message alerts
  const [bellText, setBellText] = useState<string | null>(null);

  // ----------------------------------------------------------------
  // SESSION RECOVERY ON BOOT
  // ----------------------------------------------------------------
  useEffect(() => {
    if (token) {
      setLoading(true);
      fetch('/api/auth/me', {
        headers: { 'Authorization': `Bearer ${token}` }
      })
      .then(res => {
        if (!res.ok) {
          throw new Error('의심스러운 세션 토큰 만료');
        }
        return res.json();
      })
      .then(userData => {
        // Fetch full stats by counting likes/dislikes
        setUser({
          ...userData,
          likedCount: 0,
          dislikedCount: 0
        });
      })
      .catch(() => {
        // Clear broken session
        handleLogout();
      })
      .finally(() => {
        setLoading(false);
      });
    }
  }, [token]);

  // ----------------------------------------------------------------
  // CORE DISPATCH: FETCH RECOMMENDATIONS
  // ----------------------------------------------------------------
  const fetchRecommendations = useCallback((currentWeights?: RecommendationWeights, filter?: string, query?: string) => {
    if (!token) return;

    const w = currentWeights || activeWeights;
    const g = filter !== undefined ? filter : genreFilter;
    const q = query !== undefined ? query : searchQuery;

    setLoading(true);
    fetch('/api/movies/recommend', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify({
        alpha: w.alpha,
        beta: w.beta,
        gamma: w.gamma,
        genre: g,
        query: q
      })
    })
    .then(res => res.json())
    .then(data => {
      setMovies(data.movies || []);
      setCacheHit(data.cacheHit);
      
      // Update actual calculated weights as resolved by server adaptive scaling rules
      if (data.weights) {
        setActiveWeights(data.weights);
      }

      // Sync active stats with count of likes/dislikes
      if (data.activeFeedbacks && user) {
        setUser(prev => prev ? {
          ...prev,
          dislikedCount: data.activeFeedbacks.length
        } : null);
      }

      // Auto-spotlight the first film if we don't have one
      if (data.movies && data.movies.length > 0) {
        setSpotlightMovie(data.movies[0]);
      } else {
        setSpotlightMovie(null);
      }
    })
    .catch(err => {
      console.error(err);
      triggerToast("추천 알고리즘 연동 오류 발생");
    })
    .finally(() => {
      setLoading(false);
      fetchRedisStats();
    });
  }, [token, activeWeights, genreFilter, searchQuery, user]);

  // Fetch Redis stats
  const fetchRedisStats = useCallback(() => {
    if (!token) return;
    fetch('/api/cache/stats', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
    .then(res => res.json())
    .then(stats => {
      setRedisStats(stats);
    })
    .catch(console.error);
  }, [token]);

  // Run initial fetch on login load
  useEffect(() => {
    if (user && token) {
      fetchRecommendations();
    }
  }, [user, token]);

  // ----------------------------------------------------------------
  // INTERACTIVE FEEDBACK HANDLER (OPTIMISTIC UPDATES)
  // ----------------------------------------------------------------
  const handleLike = async (movieId: string) => {
    if (!token || !user) return;

    try {
      // Direct request
      const res = await fetch('/api/movies/feedback', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ movieId, action: 'like' })
      });

      const data = await res.json();
      if (res.ok) {
        triggerToast("만족해요(LIKE) 등록 완료! 장르 유사도와 CF 가중치가 변동되었습니다.");
        
        // Update local stats count
        setUser(prev => prev ? {
          ...prev,
          ratingsCount: data.user.ratingsCount,
          likedCount: data.user.likedCount,
          dislikedCount: data.user.dislikedCount
        } : null);

        // Fetch fresh scores
        fetchRecommendations();
      }
    } catch (err) {
      triggerToast("피드백 데이터베이스 전송 중에 네트워크 에러 발생");
    }
  };

  const handleDislike = async (movieId: string) => {
    if (!token || !user) return;

    triggerToast("불만족해요(DISLIKE)! 카드를 즉시 청소하고 다음 영화 연동을 진행합니다.", true);

    // 1. OPTIMISTIC UPDATE: IMMEDIATELY FADE OUT THE CARD IN MAIN FRONTEND STATE (remove from local list)
    const originalList = [...movies];
    setMovies(prev => prev.filter(m => m.id !== movieId));

    try {
      const res = await fetch('/api/movies/feedback', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ movieId, action: 'dislike' })
      });

      const data = await res.json();
      if (res.ok) {
        // Update user feedback stats count
        setUser(prev => prev ? {
          ...prev,
          ratingsCount: data.user.ratingsCount,
          likedCount: data.user.likedCount,
          dislikedCount: data.user.dislikedCount
        } : null);

        // Append the replacement film (next best ranked movie) returned by server algorithm directly in place!
        if (data.replacementMovie) {
          setMovies(prev => {
            // Guarantee no duplicates
            if (prev.some(m => m.id === data.replacementMovie.id)) return prev;
            return [...prev, data.replacementMovie];
          });
        }
      } else {
        // Rollback on rare server failure
        setMovies(originalList);
      }
    } catch (err) {
      setMovies(originalList);
      triggerToast("서버 피드백 소거 도중에 문제가 있어 롤백합니다.");
    }
  };

  // ----------------------------------------------------------------
  // AUTHENTICATION HELPERS
  // ----------------------------------------------------------------
  const handleAuthSuccess = (token: string, userData: any) => {
    localStorage.setItem('algomovie_token', token);
    setToken(token);
    setUser({
      ...userData,
      likedCount: userData.likedCount || 0,
      dislikedCount: userData.dislikedCount || 0
    });
    triggerToast(`${userData.name}님 환영합니다! 알고무비가 부팅되었습니다.`);
  };

  const handleLogout = () => {
    localStorage.removeItem('algomovie_token');
    setToken(null);
    setUser(null);
    setMovies([]);
    setSpotlightMovie(null);
    triggerToast("성공적으로 세션이 로그아웃 되었습니다.");
  };

  // ----------------------------------------------------------------
  // GENRE FILTER SELECTION
  // ----------------------------------------------------------------
  const handleGenreSelect = (genreName: string) => {
    setGenreFilter(genreName);
    fetchRecommendations(activeWeights, genreName);
  };

  // Weight controller slide triggers
  const handleWeightsTweak = (newWeights: RecommendationWeights) => {
    setActiveWeights(newWeights);
    fetchRecommendations(newWeights);
  };

  const handlePreferencesTweak = async (prefs: string[]) => {
    if (!token || !user) return;
    try {
      const response = await fetch('/api/user/preferences', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ preferences: prefs })
      });
      const data = await response.json();
      if (response.ok) {
        setUser(prev => prev ? { ...prev, preferences: data.preferences } : null);
        triggerToast("관심 장르 프로필이 즉각 갱신되었습니다. β 지수 상향 적용!");
        fetchRecommendations();
      }
    } catch (err) {
      console.error(err);
    }
  };

  const handleResetWeights = () => {
    if (!user) return;
    // Core default ratios
    const defaults = { alpha: 0.3, beta: 0.4, gamma: 0.3 };
    setActiveWeights(defaults);
    fetchRecommendations(defaults);
    triggerToast("하이브리드 비중 배율을 기본 정규 값으로 리셋 해제했습니다.");
  };

  const handleClearRedis = async () => {
    if (!token) return;
    try {
      const res = await fetch('/api/cache/clear', {
        method: 'POST',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (res.ok) {
        triggerToast(data.message);
        fetchRedisStats();
      }
    } catch (err) {
      console.error(err);
    }
  };

  // Utility toast
  const triggerToast = (msg: string, urgent = false) => {
    setBellText(msg);
    setTimeout(() => {
      setBellText(null);
    }, 4500);
  };

  // Unauthenticated screen guard
  if (!token || !user) {
    return <AuthScreen onSuccess={handleAuthSuccess} />;
  }

  return (
    <div className="min-h-screen bg-netflix-black text-white selection:bg-brand-red selection:text-white font-sans">
      
      {/* Real-time Dynamic Toast banner inside portal frame */}
      {bellText && (
        <div className="fixed top-20 right-6 z-50 animate-bounce max-w-sm px-4 py-3 bg-zinc-950 border-l-4 border-brand-red text-zinc-100 text-xs rounded-r-xl shadow-2xl flex items-center gap-3 backdrop-blur-md">
          <Sparkles className="w-4 h-4 text-brand-red animate-pulse flex-none" />
          <span className="font-sans font-medium">{bellText}</span>
        </div>
      )}

      {/* Top Netflix Inspired Header */}
      <nav className="sticky top-0 z-40 bg-black/90 border-b border-white/5 px-6 md:px-12 py-4 flex items-center justify-between backdrop-blur-md">
        <div className="flex items-center gap-8">
          {/* Logo */}
          <div className="flex items-center gap-2 cursor-pointer select-none" onClick={() => fetchRecommendations()}>
            <span className="text-brand-red text-3xl font-black tracking-tighter uppercase">
              ALGOMOVIE
            </span>
          </div>

          {/* Quick Stats labels */}
          <div className="hidden lg:flex items-center gap-6 text-xs text-zinc-400 font-mono">
            <div className="flex items-center gap-1.5">
              <Globe className="w-3.5 h-3.5 text-zinc-500" />
              <span>창원대 CAPSTONE SYSTEM ACTIVE</span>
            </div>
            {cacheHit && (
              <span className="bg-green-950 border border-green-900 text-green-300 text-[10px] px-2 py-0.5 rounded font-mono">
                REDIS HIT • 1h TTL
              </span>
            )}
          </div>
        </div>

        {/* Action Profiles */}
        <div className="flex items-center gap-4">
          <div className="text-right text-xs">
            <span className="text-zinc-400 font-sans block text-[10px]">영화분석원</span>
            <span className="text-white font-bold font-sans flex items-center gap-1">
              <UserIcon className="w-3 h-3 text-brand-red inline" />
              {user.name}님
            </span>
          </div>
          
          <button 
            onClick={handleLogout}
            className="p-2 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 rounded-lg text-zinc-400 hover:text-white transition-all cursor-pointer"
            title="로그아웃"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </nav>

      {/* Hero Poster Spotlight header */}
      <HeroSlider 
        movie={spotlightMovie} 
        onPlay={(m) => setPlayingMovie(m)} 
        onShowDetails={(m) => setSpotlightMovie(m)} 
      />

      {/* Genre Filter Row */}
      <div className="px-6 md:px-12 py-5 bg-gradient-to-b from-black to-netflix-black flex items-center gap-2 overflow-x-auto scrollbar-none border-b border-zinc-900/40">
        <span className="text-zinc-500 font-mono text-[10px] uppercase mr-3 flex-none">장르 분할 수평기</span>
        {["전체", "Sci-Fi", "Action", "Thriller", "Romance", "Drama", "Animation"].map((genre) => {
          const isSelected = genreFilter === genre;
          return (
            <button
              key={genre}
              onClick={() => handleGenreSelect(genre)}
              className={`px-3 py-1 text-xs rounded-full cursor-pointer transition-all ${
                isSelected 
                  ? 'bg-brand-red text-white font-bold shadow' 
                  : 'bg-zinc-900/60 text-zinc-400 hover:text-white border border-transparent hover:border-zinc-800'
              }`}
            >
              {genre}
            </button>
          );
        })}
      </div>

      {/* Integrated Search and Live feedback dashboard row */}
      <div className="px-6 md:px-12 pt-6">
        <div className="relative max-w-md">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              fetchRecommendations(activeWeights, genreFilter, e.target.value);
            }}
            placeholder="실시간 영화명, 인물, 시놉시스 키워드 타이핑..."
            className="w-full bg-zinc-900/80 border border-zinc-800 focus:border-indigo-500 rounded-lg py-2 pl-4 pr-10 text-xs text-white focus:outline-none focus:ring-1 focus:ring-indigo-500 font-sans transition-all"
          />
          <span className="absolute right-3 top-2.5 text-[9px] font-mono text-zinc-500 bg-zinc-950 px-1 py-0.5 rounded">AUTO_COMPUTE</span>
        </div>
      </div>

      {/* Recommendation lists slider mimicking horizontal scroll lists */}
      <RecommendationSlider
        title={genreFilter === "전체" ? "🔥 실시간 AI 개인 맞춤 하이브리드 순위" : `🎬 ${genreFilter} 장르 맞춤 순위`}
        movies={movies}
        onLike={handleLike}
        onDislike={handleDislike}
        onSelect={(m) => {
          setSpotlightMovie(m);
          window.scrollTo({ top: 350, behavior: 'smooth' });
        }}
      />

      {/* Control consoles bento section layout */}
      <main className="max-w-7xl mx-auto px-6 md:px-12 py-12 space-y-10">
        
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          
          {/* Column Left: Weights tweak controls dashboard */}
          <div className="lg:col-span-8 space-y-8">
            <AdaptiveDashboard
              weights={activeWeights}
              userStats={{
                name: user.name,
                email: user.email,
                ratingsCount: user.ratingsCount,
                likedCount: user.ratingsCount - user.dislikedCount > 0 ? Math.max(0, user.ratingsCount - user.dislikedCount) : user.likedCount,
                dislikedCount: user.dislikedCount,
                preferences: user.preferences
              }}
              onWeightsChange={handleWeightsTweak}
              onPreferencesChange={handlePreferencesTweak}
              onReset={handleResetWeights}
            />

            {/* Smart chatbot assistant layer powered by Gemini */}
            <AISuggestions 
              token={token} 
              onSelectMovie={(movie) => {
                setSpotlightMovie(movie);
                window.scrollTo({ top: 350, behavior: 'smooth' });
                triggerToast(`"${movie.title}" 스포트라이트가 연동되었습니다.`);
              }} 
            />
          </div>

          {/* Column Right: Caching consoles admin panel */}
          <div className="lg:col-span-4 h-full">
            <RedisConsole
              stats={redisStats}
              onClear={handleClearRedis}
              onRefresh={fetchRedisStats}
            />
          </div>

        </div>

      </main>

      {/* Video Interactive mock modal layer */}
      {playingMovie && (
        <div id="video-modal" className="fixed inset-0 z-50 flex items-center justify-center bg-black/90 p-4 backdrop-blur-sm animate-fade-in">
          <div className="w-full max-w-3xl bg-zinc-950 border border-zinc-800 rounded-2xl overflow-hidden shadow-2xl relative">
            <button 
              onClick={() => setPlayingMovie(null)}
              className="absolute top-4 right-4 text-zinc-500 hover:text-white bg-zinc-900/60 hover:bg-neutral-800 rounded-full p-1.5 transition-all cursor-pointer z-10"
            >
              <X className="w-5 h-5" />
            </button>
            
            {/* Cinematic trailer screen mock area */}
            <div className="relative aspect-video bg-zinc-900 flex flex-col items-center justify-center text-center p-6 bg-cover bg-center"
                 style={{ backgroundImage: `linear-gradient(rgba(0,0,0,0.8), rgba(0,0,0,0.85)), url(${playingMovie.posterUrl})` }}>
              <PlayCircle className="w-16 h-16 text-brand-red animate-pulse mb-4" />
              <div className="space-y-2 max-w-md">
                <h3 className="font-display font-extrabold text-2xl text-white block">{playingMovie.title}</h3>
                <p className="text-zinc-400 text-xs font-sans leading-relaxed">
                  [국립창원대학교 AlgoMovie] 현재 본 페이지는 프로토타입 시각화 가동 단계입니다. 실제 TMDB 스트리밍 영상 플레이어가 유효하지 않은 경우, 이 세련된 모크 플레이어가 UI의 파괴를 완벽 수비합니다.
                </p>
                <div className="text-[10px] text-zinc-500 font-mono uppercase bg-neutral-950 border border-zinc-800 rounded py-1 px-3 inline-block">
                  TRAILER_STREAM_EMULATOR :: {playingMovie.id}
                </div>
              </div>
            </div>

            <div className="p-6 bg-zinc-950 border-t border-zinc-900 space-y-4">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-zinc-900 pb-3">
                <div className="flex items-center gap-2">
                  <span className="text-xs bg-brand-red text-white font-bold px-2 py-0.5 rounded text-[9px]">HD</span>
                  <span className="text-xs text-zinc-400 font-mono">{playingMovie.year} • {playingMovie.duration}</span>
                </div>
                <div className="flex items-center gap-1 text-xs text-amber-500 font-mono">
                  <Star className="w-3.5 h-3.5 fill-amber-500" />
                  <span>평단 스코어 {playingMovie.rating} / 10</span>
                </div>
              </div>
              <div className="space-y-1 text-xs text-zinc-300">
                <div><strong className="text-zinc-500">감독 :</strong> {playingMovie.director}</div>
                <div><strong className="text-zinc-500">출연진 :</strong> {playingMovie.cast.join(", ")}</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Footer Branding credits */}
      <footer className="border-t border-white/5 py-10 bg-black text-center text-zinc-600 text-xs font-mono space-y-2">
        <div className="flex justify-center items-center gap-2">
          <span className="text-brand-red font-black tracking-tight text-sm uppercase">ALGOMOVIE ENGINE</span>
        </div>
        <p className="text-[10px] text-zinc-500">Copyright © 2026 Changwon National University CompSci Capstone Project. All rights reserved.</p>
        <p className="text-[9px] text-zinc-700">PORT: 3000 // REDIS_TTL: 3600 // GRADIENT_STABILITY_OK</p>
      </footer>

    </div>
  );
}
