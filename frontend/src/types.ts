/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

export interface Movie {
  id: string;
  title: string;
  genre: string[];
  year: number;
  posterUrl: string;
  overview: string;
  rating: number; // For CF simulation (e.g., standard users average rating)
  popularity: number; // 0-100 scale
  duration: string;
  director: string;
  cast: string[];
  
  // AI and Hybrid calculations done on server
  cfScore?: number;
  contentScore?: number;
  popularityScore?: number;
  finalWeightedScore?: number;
  
  // Custom generation flags
  isAIGenerated?: boolean;
}

export interface User {
  id: string;
  email: string;
  name: string;
  joinedAt: string;
}

export interface RecommendationWeights {
  alpha: number; // Collaborative Filtering (CF) score
  beta: number;  // Content-based score
  gamma: number; // Popularity score
}

export interface FeedbackData {
  movieId: string;
  action: 'like' | 'dislike';
  timestamp: string;
}

export interface RedisCacheStats {
  hits: number;
  misses: number;
  keysCount: number;
  entries: { key: string; expiresAt: string; size: number }[];
}

export interface RecommendationResponse {
  movies: Movie[];
  cacheHit: boolean;
  weights: RecommendationWeights;
  activeFeedbacks: string[]; // movieId array of disliked
}
