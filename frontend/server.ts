/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import express from "express";
import path from "path";
import fs from "fs";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import dotenv from "dotenv";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI, Type } from "@google/genai";

dotenv.config();

const app = express();
const PORT = 3000;
const JWT_SECRET = process.env.JWT_SECRET || "algomovie_super_secret_session_key";

// Setup Middlewares
app.use(express.json());

// In-Memory Database (Robust State Store)
interface DbUser {
  id: string;
  email: string;
  name: string;
  passwordHash: string;
  ratingsCount: number;
  preferences: string[];
  dislikedMovies: string[]; // IDs of movies user disliked (replaces in recommendations)
  likedMovies: string[];    // IDs of movies user liked
}

const usersDb = new Map<string, DbUser>();
// Insert a clean seed user for local testing
const seedHash = bcrypt.hashSync("admin123", 10);
usersDb.set("munseohee3070@gmail.com", {
  id: "user_seed_1",
  email: "munseohee3070@gmail.com",
  name: "문서희",
  passwordHash: seedHash,
  ratingsCount: 8, // Initialized with some ratings so CF weight scale is live!
  preferences: ["Sci-Fi", "Action", "Thriller"],
  dislikedMovies: [],
  likedMovies: ["m_1", "m_5"]
});

// Seed Movie Catalogue with detailed metadata for Content & CF calculations
const MOVIE_CATALOGUE = [
  {
    id: "m_1",
    title: "인셉션 (Inception)",
    genre: ["Sci-Fi", "Action", "Thriller"],
    year: 2010,
    posterUrl: "https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=600&auto=format&fit=crop&q=80",
    overview: "타인의 꿈에 침투하여 기억을 해킹해 생각을 주입하는 특수 작전을 둘러싼 압도적 스릴러.",
    rating: 8.8,
    popularity: 95,
    duration: "2시간 28분",
    director: "크리스토퍼 놀란",
    cast: ["레오나르도 디카프리오", "엘리엇 페이지", "톰 하디"]
  },
  {
    id: "m_2",
    title: "인터스텔라 (Interstellar)",
    genre: ["Sci-Fi", "Drama", "Adventure"],
    year: 2014,
    posterUrl: "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&auto=format&fit=crop&q=80",
    overview: "멸망해가는 인류를 구하기 위해 시공간의 한계를 넘어 블랙홀 너머 새로운 보금자리를 찾아 떠나는 경이로운 탐험.",
    rating: 8.6,
    popularity: 97,
    duration: "2시간 49분",
    director: "크리스토퍼 놀란",
    cast: ["매튜 맥코너히", "앤 해서웨이", "제시카 차스테인"]
  },
  {
    id: "m_3",
    title: "다크 나이트 (The Dark Knight)",
    genre: ["Action", "Crime", "Drama"],
    year: 2008,
    posterUrl: "https://images.unsplash.com/photo-1478760329108-5c3ed9d495a0?w=600&auto=format&fit=crop&q=80",
    overview: "고담시를 위협하는 궁극의 악당 조커에 맞서 정의의 경계를 고민하는 배트맨의 고뇌.",
    rating: 9.0,
    popularity: 99,
    duration: "2시간 32분",
    director: "크리스토퍼 놀란",
    cast: ["크리스찬 베일", "히스 레저", "아론 에크하트"]
  },
  {
    id: "m_4",
    title: "기생충 (Parasite)",
    genre: ["Thriller", "Drama", "Comedy"],
    year: 2019,
    posterUrl: "https://images.unsplash.com/photo-1585647347483-22b66260dfff?w=600&auto=format&fit=crop&q=80",
    overview: "전혀 다른 두 가족의 우연한 만남이 걷잡을 수 없는 겉잡을 수 없는 비극의 파동으로 번져가는 빈부격차 풍자 스릴러.",
    rating: 8.6,
    popularity: 91,
    duration: "2시간 12분",
    director: "봉준호",
    cast: ["송강호", "이선균", "조여정", "최우식"]
  },
  {
    id: "m_5",
    title: "라라랜드 (La La Land)",
    genre: ["Romance", "Drama", "Music"],
    year: 2016,
    posterUrl: "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=600&auto=format&fit=crop&q=80",
    overview: "꿈을 가꾸어 나가는 재즈 피아니스트와 배우 지향생 지망생의 애틋하면서도 서정적인 찬란한 사랑 이야기.",
    rating: 8.0,
    popularity: 88,
    duration: "2시간 8분",
    director: "데이미언 셔젤",
    cast: ["라이언 고슬링", "엠마 스톤"]
  },
  {
    id: "m_6",
    title: "센과 치히로의 행방불명 (Spirited Away)",
    genre: ["Animation", "Fantasy", "Adventure"],
    year: 2001,
    posterUrl: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop&q=80",
    overview: "인간 출입이 금지된 신비로운 정령의 세계에 갇힌 치히로가 부모를 되찾기 위해 헤쳐나가는 환상적인 여정.",
    rating: 8.6,
    popularity: 94,
    duration: "2시간 5분",
    director: "미야자키 하야오",
    cast: ["히라기 루미", "이리노 미유"]
  },
  {
    id: "m_7",
    title: "듄: 파트 2 (Dune: Part Two)",
    genre: ["Sci-Fi", "Adventure", "Action"],
    year: 2024,
    posterUrl: "https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=600&auto=format&fit=crop&q=80",
    overview: "가문의 멸망 이후 모래사막 아라키스에서 펼쳐지는 파울 아트레이데스의 대서사시적인 복수와 우주의 격변.",
    rating: 8.9,
    popularity: 98,
    duration: "2시간 46분",
    director: "드니 빌뇌브",
    cast: ["티모시 샬라메", "젠데이아", "레베카 퍼거슨"]
  },
  {
    id: "m_8",
    title: "매트릭스 (The Matrix)",
    genre: ["Sci-Fi", "Action"],
    year: 1999,
    posterUrl: "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=600&auto=format&fit=crop&q=80",
    overview: "가짜 세계 가설과 시뮬레이션 현실을 다루며 인류 구원자로 선택된 네오의 화려하고 압도적인 SF 액션의 기념비적 명작.",
    rating: 8.7,
    popularity: 92,
    duration: "2시간 16분",
    director: "라나 워쇼스키, 릴리 워쇼스키",
    cast: ["키아누 리브스", "로렌스 피시번", "캐리앤 모스"]
  },
  {
    id: "m_9",
    title: "아가씨 (The Handmaiden)",
    genre: ["Thriller", "Drama", "Romance"],
    year: 2016,
    posterUrl: "", // INTENTIONAL MISSING POSTER TO TEST FALLBACK LOGIC
    overview: "막대한 재산을 상속받은 귀족 아가씨와 그녀의 부를 빼앗으려는 하녀, 그리고 백작의 얽히고설킨 음모와 반전의 드라마.",
    rating: 8.3,
    popularity: 85,
    duration: "2시간 24분",
    director: "박찬욱",
    cast: ["김민희", "김태리", "하정우", "조진웅"]
  },
  {
    id: "m_10",
    title: "콘택트 (Contact)",
    genre: ["Sci-Fi", "Drama", "Mystery"],
    year: 1997,
    posterUrl: "https://images.unsplash.com/photo-1444703686981-a3abbc4d4fe3?w=600&auto=format&fit=crop&q=80",
    overview: "심우주 깊은 곳으로부터 도달한 정체불명의 우주 신호를 해독하여 외계 지적 생명체와 만나는 위대한 전율.",
    rating: 8.1,
    popularity: 80,
    duration: "2시간 30분",
    director: "로버트 저메키스",
    cast: ["조디 포스터", "매튜 맥코너히"]
  },
  {
    id: "m_11",
    title: "광해, 왕이 된 남자",
    genre: ["Drama", "History"],
    year: 2012,
    posterUrl: "https://images.unsplash.com/photo-1599708149871-331579ded578?w=600&auto=format&fit=crop&q=80",
    overview: "광해군을 대신해 가짜 왕 역할을 하게 된 천민 하선이 진정한 군주로서 눈떠가는 사극 명작.",
    rating: 8.5,
    popularity: 89,
    duration: "2시간 11분",
    director: "추창민",
    cast: ["이병헌", "류승룡", "한효주"]
  },
  {
    id: "m_12",
    title: "어바웃 타임 (About Time)",
    genre: ["Romance", "Comedy", "Drama"],
    year: 2013,
    posterUrl: "https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=600&auto=format&fit=crop&q=80",
    overview: "가문의 비밀인 시간 여행 능력을 가지게 된 청년의 삶과 서툰 진정한 인생의 의미를 깨달아가는 로맨스 영화.",
    rating: 8.2,
    popularity: 90,
    duration: "2시간 3분",
    director: "리처드 커티스",
    cast: ["도널 글리슨", "레이첼 맥아담스"]
  },
  {
    id: "m_13",
    title: "화양연화 (In the Mood for Love)",
    genre: ["Romance", "Drama"],
    year: 2000,
    posterUrl: "https://images.unsplash.com/photo-1543536448-d209d2d13a1c?w=600&auto=format&fit=crop&q=80",
    overview: "같은 아파트로 이사해 외로운 삶을 공유하며 점차 겉잡을 수 없는 감정에 빠져드는 남녀의 쓸쓸한 사랑과 영상미.",
    rating: 8.1,
    popularity: 82,
    duration: "1시간 38분",
    director: "왕가위",
    cast: ["양조위", "장만옥"]
  },
  {
    id: "m_14",
    title: "올드보이 (Oldboy)",
    genre: ["Thriller", "Action", "Mystery"],
    year: 2003,
    posterUrl: "https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=600&auto=format&fit=crop&q=80",
    overview: "영문도 모른 채 15년간 사설 감금방에 갇혀 지내던 오대수가 풀려난 뒤 벌어지는 처절한 복수극과 경악할 만한 반전.",
    rating: 8.4,
    popularity: 96,
    duration: "2시간",
    director: "박찬욱",
    cast: ["최민식", "유지태", "강혜정"]
  }
];

// Redis Cache Mocking Class (TTL 1 hour)
class RedisCacheMock {
  private store = new Map<string, { value: any; expiresAt: number; size: number }>();
  public hits = 0;
  public misses = 0;

  get(key: string): any | null {
    const item = this.store.get(key);
    if (!item) {
      this.misses++;
      return null;
    }
    if (Date.now() > item.expiresAt) {
      this.store.delete(key);
      this.misses++;
      return null;
    }
    this.hits++;
    return item.value;
  }

  set(key: string, value: any, ttlMs: number = 3600000): void {
    const expiresAt = Date.now() + ttlMs;
    const size = JSON.stringify(value).length;
    this.store.set(key, { value, expiresAt, size });
  }

  delete(key: string): void {
    this.store.delete(key);
  }

  clear(): void {
    this.store.clear();
  }

  getStats() {
    const activeEntries: { key: string; expiresAt: string; size: number }[] = [];
    this.store.forEach((val, key) => {
      if (Date.now() < val.expiresAt) {
        activeEntries.push({
          key,
          expiresAt: new Date(val.expiresAt).toISOString(),
          size: val.size
        });
      }
    });

    return {
      hits: this.hits,
      misses: this.misses,
      keysCount: activeEntries.length,
      entries: activeEntries
    };
  }
}

const redisCache = new RedisCacheMock();

// Gemini Client Getter
let aiClient: GoogleGenAI | null = null;
function getGeminiClient(): GoogleGenAI | null {
  const key = process.env.GEMINI_API_KEY;
  if (!key || key === "MY_GEMINI_API_KEY" || key === "") {
    return null;
  }
  if (!aiClient) {
    aiClient = new GoogleGenAI({
      apiKey: key,
      httpOptions: {
        headers: {
          'User-Agent': 'aistudio-build',
        }
      }
    });
  }
  return aiClient;
}

// User Extraction Middleware helper
function authenticateToken(req: express.Request, res: express.Response, next: express.NextFunction) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: "세션 토큰이 누락되었습니다." });
  }

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as any;
    const user = usersDb.get(decoded.email);
    if (!user) {
      return res.status(404).json({ error: "존재하지 않는 유저입니다." });
    }
    (req as any).user = user;
    next();
  } catch (err) {
    return res.status(403).json({ error: "유효하지 않거나 만료된 세션 토큰입니다." });
  }
}

// ==========================================
// API ENDPOINTS
// ==========================================

// Auth REST API: Registration and Login
app.post("/api/auth/register", async (req, res) => {
  const { email, name, password } = req.body;
  if (!email || !name || !password) {
    return res.status(400).json({ error: "모든 필드를 기입해 주세요." });
  }
  if (usersDb.has(email)) {
    return res.status(400).json({ error: "이미 가입 완료된 이메일 주소입니다." });
  }

  const saltRounds = 10;
  const hash = bcrypt.hashSync(password, saltRounds);

  const newUser: DbUser = {
    id: `u_${Date.now()}`,
    email,
    name,
    passwordHash: hash,
    ratingsCount: 0, // Freshly registered users start with 0 rating feedback -> CF weight gets muted!
    preferences: ["Sci-Fi", "Drama"],
    dislikedMovies: [],
    likedMovies: []
  };

  usersDb.set(email, newUser);

  // Auto issue token
  const token = jwt.sign({ email: newUser.email, id: newUser.id }, JWT_SECRET, { expiresIn: "24h" });

  res.status(201).json({
    message: "성공적으로 가입되었습니다.",
    token,
    user: {
      id: newUser.id,
      email: newUser.email,
      name: newUser.name,
      ratingsCount: newUser.ratingsCount
    }
  });
});

app.post("/api/auth/login", async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: "이메일과 비밀번호를 제공하세요." });
  }

  const user = usersDb.get(email);
  if (!user) {
    return res.status(400).json({ error: "등록되지 않은 가입 계정 정보입니다." });
  }

  // Check matching password hash
  const match = bcrypt.compareSync(password, user.passwordHash);
  if (!match) {
    return res.status(400).json({ error: "비밀번호가 올바르지 않습니다." });
  }

  const token = jwt.sign({ email: user.email, id: user.id }, JWT_SECRET, { expiresIn: "24h" });

  res.json({
    message: "로그인 성공",
    token,
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      ratingsCount: user.ratingsCount,
      preferences: user.preferences
    }
  });
});

// Fetch current user details
app.get("/api/auth/me", authenticateToken, (req, res) => {
  const user = (req as any).user as DbUser;
  res.json({
    id: user.id,
    email: user.email,
    name: user.name,
    ratingsCount: user.ratingsCount,
    preferences: user.preferences
  });
});

// Live Feedback endpoint (LIKE / DISLIKE) -> instantaneous fade-out on negative
app.post("/api/movies/feedback", authenticateToken, (req, res) => {
  const user = (req as any).user as DbUser;
  const { movieId, action } = req.body;

  if (!movieId || !["like", "dislike"].includes(action)) {
    return res.status(400).json({ error: "형식이 유효하지 않은 피드백 요청입니다." });
  }

  // Find target movie
  const movieExists = MOVIE_CATALOGUE.some(m => m.id === movieId);
  if (!movieExists) {
    return res.status(404).json({ error: "해당 영화를 찾을 수 없습니다." });
  }

  // Increment total feedback rating count (shifts recommendation CF weight parameter!)
  user.ratingsCount += 1;

  if (action === "like") {
    // Add to likes, remove from dislike if exists
    if (!user.likedMovies.includes(movieId)) {
      user.likedMovies.push(movieId);
    }
    user.dislikedMovies = user.dislikedMovies.filter(id => id !== movieId);
  } else {
    // Add to dislikes (replaces in recommendations), remove from likes
    if (!user.dislikedMovies.includes(movieId)) {
      user.dislikedMovies.push(movieId);
    }
    user.likedMovies = user.likedMovies.filter(id => id !== movieId);
  }

  // Save changes to user store
  usersDb.set(user.email, user);

  // Clear recommended cache to force fresh formula generation on next load
  redisCache.delete(`recommendations_${user.id}`);

  // Calculate next potential replacement movie for optimistic swap UI
  // The client swaps out this ID and grabs another movie immediately. We can calculate the next best catalog movie.
  const recalculatedMovies = calculateHybridWeightedMovies(user, 0.4, 0.3, 0.3); // fallback weights
  const replacementMovie = recalculatedMovies.movies.find(m => !user.dislikedMovies.includes(m.id) && m.id !== movieId);

  res.json({
    success: true,
    message: `${action === "like" ? "만족해요 (LIKE)" : "불만족해요 (DISLIKE)"} 피드백이 등록되었습니다. 실시간 알고리즘 갱신 완료.`,
    user: {
      email: user.email,
      ratingsCount: user.ratingsCount,
      likedCount: user.likedMovies.length,
      dislikedCount: user.dislikedMovies.length
    },
    replacementMovie
  });
});

// Calculate math-based adaptive hybrid recommendation scoring on Server
// 최종 점수 = (α × CF_score) + (β × Content_score) + (γ × Popularity_score)
function calculateHybridWeightedMovies(
  user: DbUser,
  customAlpha: number,
  customBeta: number,
  customGamma: number,
  genreFilter?: string,
  searchQuery?: string
) {
  // Let's resolve ADAPTIVE weights based on Ratings Count
  // 평점 0개(신규): α=0.0, β=0.5, γ=0.5 / 평점 5~19개: 실시간 변동 / 평점 20개 이상: α 최대 0.7
  let alpha = customAlpha;
  let beta = customBeta;
  let gamma = customGamma;

  const count = user.ratingsCount;
  if (count === 0) {
    alpha = 0.0;
    beta = 0.5;
    gamma = 0.5;
  } else if (count >= 1 && count < 20) {
    // Ramp up alpha gradually based on feedback density, balance others
    alpha = Number((0.035 * count).toFixed(3));
    if (alpha > 0.7) alpha = 0.7;
    // Distribute remaining weight between content and popularity
    const remaining = 1.0 - alpha;
    beta = Number((remaining * 0.5).toFixed(3));
    gamma = Number((remaining * 0.5).toFixed(3));
  } else {
    // 20 reviews or more: allow alpha up to 0.7 (let user tweak slider if they want up to 0.7)
    // We check if slider alpha is high, cap it properly
    alpha = Math.min(Math.max(customAlpha, 0.5), 0.7);
    const sumBC = customBeta + customGamma;
    if (sumBC > 0) {
      beta = Number(((1.0 - alpha) * (customBeta / sumBC)).toFixed(3));
      gamma = Number(((1.0 - alpha) * (customGamma / sumBC)).toFixed(3));
    } else {
      beta = Number(((1.0 - alpha) * 0.5).toFixed(3));
      gamma = Number(((1.0 - alpha) * 0.5).toFixed(3));
    }
  }

  // Normalize final weights sum to 1
  const sumWeights = alpha + beta + gamma;
  const normAlpha = Number((alpha / sumWeights).toFixed(3));
  const normBeta = Number((beta / sumWeights).toFixed(3));
  const normGamma = Number((gamma / sumWeights).toFixed(3));

  // Compute scores for each movie
  const calculated = MOVIE_CATALOGUE.map((movie) => {
    // 1) CF_Score Calculation (0-100 scale)
    // Collaborative filtering similarity. Boost score based on:
    // - Movie rating (e.g. 9.0 out of 10 -> base 90)
    // - Co-liked similarity: if user liked other Sci-Fi movies or dramas
    let cfBase = movie.rating * 10;
    let cfBoost = 0;
    
    // Check overlapping genres of previously liked movies
    user.likedMovies.forEach(likedId => {
      const likedFilm = MOVIE_CATALOGUE.find(f => f.id === likedId);
      if (likedFilm) {
        const overlap = likedFilm.genre.filter(g => movie.genre.includes(g)).length;
        cfBoost += overlap * 2.5; // Every matching liked genre boosts similarity
      }
    });
    
    const cfScore = Math.min(Math.max(cfBase + cfBoost, 20), 100);

    // 2) Content_Score Calculation (0-100 scale)
    // Jaccard similarity text correlation with user-selected preferences and optional search query
    let contentScore = 30; // base score
    
    // Fit user selected preferred genres
    const preferredIntersection = movie.genre.filter(g => user.preferences.includes(g)).length;
    contentScore += preferredIntersection * 15;

    // Direct search/text match similarity
    if (searchQuery) {
      const q = searchQuery.toLowerCase();
      const hasTitle = movie.title.toLowerCase().includes(q);
      const hasOverview = movie.overview.toLowerCase().includes(q);
      const hasGenre = movie.genre.some(g => g.toLowerCase().includes(q));
      
      if (hasTitle) contentScore += 40;
      if (hasGenre) contentScore += 25;
      if (hasOverview) contentScore += 15;
    }
    
    contentScore = Math.min(contentScore, 100);

    // 3) Popularity_Score Calculation (0-100 scale)
    // Built-in static catalog popularity
    const popularityScore = movie.popularity;

    // Final Formula Multiplier Synthesis
    const finalScore = (normAlpha * cfScore) + (normBeta * contentScore) + (normGamma * popularityScore);

    return {
      ...movie,
      cfScore: Number(cfScore.toFixed(1)),
      contentScore: Number(contentScore.toFixed(1)),
      popularityScore: Number(popularityScore.toFixed(1)),
      finalWeightedScore: Number(finalScore.toFixed(1))
    };
  });

  // Filter out disliked movies entirely (Optimistic updates / negative feedback penalty)
  let result = calculated.filter(m => !user.dislikedMovies.includes(m.id));

  // Genre Filtering
  if (genreFilter && genreFilter !== "전체") {
    result = result.filter(m => m.genre.includes(genreFilter));
  }

  // Sort by highest weighted recommendation score descending
  result.sort((a, b) => b.finalWeightedScore - a.finalWeightedScore);

  return {
    movies: result,
    resolvedWeights: {
      alpha: normAlpha,
      beta: normBeta,
      gamma: normGamma
    }
  };
}

// Fetch Movies with Custom Recommendation weights and Redis cache query
app.post("/api/movies/recommend", authenticateToken, (req, res) => {
  const user = (req as any).user as DbUser;
  const { alpha = 0.3, beta = 0.4, gamma = 0.3, genre = "전체", query = "", bypassCache = false } = req.body;

  const cacheKey = `recommendations_${user.id}_g_${genre}_q_${query}_a_${alpha}_b_${beta}_c_${gamma}`;
  
  if (!bypassCache) {
    const cached = redisCache.get(cacheKey);
    if (cached) {
      return res.json({
        ...cached,
        cacheHit: true
      });
    }
  }

  // Perform Server Calculation
  const { movies, resolvedWeights } = calculateHybridWeightedMovies(
    user,
    Number(alpha),
    Number(beta),
    Number(gamma),
    genre,
    query
  );

  const payload = {
    movies,
    cacheHit: false,
    weights: resolvedWeights,
    activeFeedbacks: user.dislikedMovies
  };

  // Cache recommendations for 1 hour
  redisCache.set(cacheKey, payload, 3600000);

  res.json(payload);
});

// AI suggestions endpoint powered strictly by Gemini
app.post("/api/movies/ai-suggest", authenticateToken, async (req, res) => {
  const user = (req as any).user as DbUser;
  const { prompt } = req.body;

  if (!prompt || prompt.trim() === "") {
    return res.status(400).json({ error: "스마트 제안 질문을 작성해 주세요." });
  }

  const ai = getGeminiClient();

  // If Gemini API is not setup, fall back gracefully with local metadata semantic logic,
  // providing an explanation without failing
  if (!ai) {
    console.log("No GEMINI_API_KEY detected. Running intelligent local heuristics instead...");
    const matched = MOVIE_CATALOGUE.filter(m => {
      const text = (m.title + m.overview + m.genre.join(" ")).toLowerCase();
      return text.includes(prompt.toLowerCase()) || 
             m.genre.some(g => prompt.includes(g));
    });

    const mockAiExplanation = `💡 **[로컬 AI 학습 분석 모드]**
유저 한글 질의어: "${prompt}"
현재 개발 테스팅 환경으로 서버의 'GEMINI_API_KEY'가 비어있어, 로컬 하이브리드 엔진이 시맨틱 매칭을 대신 연동하였습니다. 
장르 가중치 및 스토리라인 텍스트 추출에 기반하여 사용자의 감성에 일치하는 최적의 수작 3건을 맞춤 추출하였습니다.`;

    return res.json({
      matchedMovies: matched.slice(0, 3),
      aiText: mockAiExplanation,
      isAIReal: false
    });
  }

  try {
    // We request Structured Recommendations based on Movie Catalogue schemas!
    const catalogueSummary = MOVIE_CATALOGUE.map(m => ({
      id: m.id,
      title: m.title,
      genre: m.genre,
      overview: m.overview,
      year: m.year
    }));

    const response = await ai.models.generateContent({
      model: "gemini-3.5-flash",
      contents: `You are AlgoMovie's personal recommendation specialist.
Analyze the user's emotional query/preferences: "${prompt}".
Assess this exact film database catalog JSON:
${JSON.stringify(catalogueSummary)}

Our current user's profile preferences include: ${user.preferences.join(", ")} and historical liked film keys are ${JSON.stringify(user.likedMovies)}.

Provide a highly empathetic Korean recommendation paragraphs (about 3-4 sentences in friendly, professional corporate speech) summarizing which movies match their feeling, and explain why.
Your response MUST output a valid JSON containing exact fields:
{
  "explanation": "Korean review text explanation with deep context...",
  "recommendedMovieIds": ["list", "of", "matching", "catalog", "movie", "ids", "in", "order"]
}
Ensure the JSON is well-formatted and strictly valid.`,
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.OBJECT,
          properties: {
            explanation: { type: Type.STRING },
            recommendedMovieIds: {
              type: Type.ARRAY,
              items: { type: Type.STRING }
            }
          },
          required: ["explanation", "recommendedMovieIds"]
        }
      }
    });

    const responseText = response.text || "{}";
    const result = JSON.parse(responseText);

    const matchedMovies = MOVIE_CATALOGUE.filter(m => 
      result.recommendedMovieIds?.includes(m.id)
    );

    res.json({
      matchedMovies: matchedMovies.slice(0, 4),
      aiText: result.explanation || "사용자 분석에 적합한 추천을 제공합니다.",
      isAIReal: true
    });

  } catch (error: any) {
    console.error("Gemini API Recommendation Error:", error);
    res.status(500).json({ error: "Gemini AI 모델 질의 중에 문제가 발생했습니다.", details: error.message });
  }
});

// Cache Dashboard stats retrieval
app.get("/api/cache/stats", authenticateToken, (req, res) => {
  res.json(redisCache.getStats());
});

app.post("/api/cache/clear", authenticateToken, (req, res) => {
  redisCache.clear();
  res.json({ success: true, message: "Redis 캐시 메모리가 격리 및 초기화 청소 완료되었습니다." });
});

// User preference updates
app.post("/api/user/preferences", authenticateToken, (req, res) => {
  const user = (req as any).user as DbUser;
  const { preferences } = req.body;
  
  if (Array.isArray(preferences)) {
    user.preferences = preferences;
    usersDb.set(user.email, user);
    redisCache.delete(`recommendations_${user.id}`);
    res.json({ success: true, preferences: user.preferences });
  } else {
    res.status(400).json({ error: "형식이 바르지 않은 선호도 목록입니다." });
  }
});


// ==========================================
// VITE AND STATIC ASSETS HANDLER
// ==========================================

async function startServer() {
  if (process.env.NODE_ENV !== "production") {
    // Setup Vite Server in mid-middleware mode
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    // Serve Static production outputs
    const distPath = path.join(process.cwd(), 'dist');
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`=============================================================`);
    console.log(`🎬 AlgoMovie Full-Stack Service booted successfully!`);
    console.log(`🚀 Portal Server running securely on http://0.0.0.0:${PORT}`);
    console.log(`=============================================================`);
  });
}

startServer();
