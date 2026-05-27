/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { ThumbsUp, ThumbsDown, Star, Sparkles, AlertTriangle, Play, HelpCircle } from 'lucide-react';
import { AnimatePresence, motion } from 'motion/react';
import { Movie } from '../types';

interface RecommendationSliderProps {
  title: string;
  movies: Movie[];
  onLike: (movieId: string) => void;
  onDislike: (movieId: string) => void;
  onSelect: (movie: Movie) => void;
}

export default function RecommendationSlider({ title, movies, onLike, onDislike, onSelect }: RecommendationSliderProps) {
  const [hoveredId, setHoveredId] = useState<string | null>(null);

  return (
    <div className="space-y-4 px-6 md:px-12 py-4">
      <div className="flex items-center justify-between">
        <h2 className="font-display font-extrabold text-xl md:text-2xl text-white tracking-tight flex items-center gap-2">
          <span className="w-1.5 h-6 bg-brand-red rounded-full"></span>
          {title}
        </h2>
        <span className="text-xs text-zinc-500 font-mono">가로 스크롤로 보기 • {movies.length}개 결과</span>
      </div>

      {movies.length === 0 ? (
        <div id="empty-state" className="flex flex-col items-center justify-center p-12 bg-zinc-950/80 rounded-2xl border border-zinc-900 border-dashed text-center space-y-3">
          <HelpCircle className="w-10 h-10 text-zinc-600 animate-bounce" />
          <p className="text-zinc-400 text-sm font-sans font-medium">찾으시는 조건의 추천 영화가 목록에 없습니다.</p>
          <span className="text-xs text-zinc-500">불만족 필터링을 조절하거나 가중치 배율을 초기화해보세요.</span>
        </div>
      ) : (
        <div 
          className="flex overflow-x-auto gap-4 md:gap-5 pb-6 pt-2 scroll-smooth scrollbar-thin select-none snap-x"
          style={{ contentVisibility: 'auto' }}
        >
          <AnimatePresence mode="popLayout">
            {movies.map((movie) => {
              const isHovered = hoveredId === movie.id;
              
              return (
                <motion.div
                  key={movie.id}
                  layoutId={`movie-${movie.id}`}
                  initial={{ opacity: 0, scale: 0.9 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.8, y: 15 }}
                  transition={{ 
                    duration: 0.35, 
                    ease: "easeInOut"
                  }}
                  className="relative flex-none w-[170px] md:w-[220px] snap-start"
                  onMouseEnter={() => setHoveredId(movie.id)}
                  onMouseLeave={() => setHoveredId(null)}
                >
                  {/* Aspect Ratio 2:3 Vertical Poster Container */}
                  <div className="relative aspect-[2/3] w-full rounded-xl overflow-hidden bg-zinc-900 border border-zinc-800/80 group/card shadow-lg hover:shadow-brand-red/10 cursor-pointer">
                    
                    {/* Fallback image widget if poster Url is missing */}
                    {movie.posterUrl ? (
                      <img
                        src={movie.posterUrl}
                        alt={movie.title}
                        referrerPolicy="referrer"
                        className="w-full h-full object-cover group-hover/card:scale-105 transition-transform duration-500 rounded-xl"
                      />
                    ) : (
                      <div className="w-full h-full bg-gradient-to-br from-zinc-900 to-zinc-950 flex flex-col justify-between p-4 rounded-xl relative border border-zinc-700/30">
                        {/* 넷플릭스 로고 형태의 다크 그레이 기본 대체 위젯 */}
                        <div className="text-brand-red font-display font-extrabold text-xl tracking-tighter">N</div>
                        <div className="space-y-1">
                          <div className="text-zinc-400 font-sans font-bold text-xs truncate">{movie.title}</div>
                          <div className="text-zinc-600 font-mono text-[9px]">POSTER PENDING</div>
                        </div>
                        <div className="absolute inset-0 bg-neutral-900/40 flex items-center justify-center">
                          <AlertTriangle className="w-6 h-6 text-zinc-700/60" />
                        </div>
                      </div>
                    )}

                    {/* Gradient Overlay */}
                    <div className="absolute inset-0 bg-gradient-to-t from-black via-black/20 to-transparent opacity-80" />

                    {/* Quick Hybrid Score Badge top-right */}
                    {movie.finalWeightedScore && (
                      <div className="absolute top-2.5 right-2.5 bg-brand-red/90 text-white font-display text-[10px] font-bold px-2 py-0.5 rounded-full backdrop-blur shadow border border-brand-red">
                        ★ {movie.finalWeightedScore}
                      </div>
                    )}

                    {/* Footer Title Text */}
                    <div className="absolute bottom-3 left-3 right-3 z-10 block group-hover/card:hidden">
                      <h3 className="text-xs font-bold text-white truncate">{movie.title}</h3>
                      <div className="flex items-center justify-between mt-1 text-[9px] text-zinc-400 font-mono">
                        <span>{movie.year}</span>
                        <span>★ {movie.rating}</span>
                      </div>
                    </div>

                    {/* Expand Hover Layer */}
                    <div className="absolute inset-0 bg-black/90 p-4 flex flex-col justify-between opacity-0 group-hover/card:opacity-100 transition-opacity duration-300 z-20">
                      <div onClick={() => onSelect(movie)} className="flex-1 space-y-2">
                        <div className="flex items-center gap-1.5 justify-between">
                          <span className="text-[10px] font-mono text-zinc-500 uppercase">개요</span>
                          <span className="text-[10px] text-zinc-400 font-sans">{movie.year} • {movie.duration}</span>
                        </div>
                        <h4 className="text-xs font-display font-extrabold text-white leading-tight line-clamp-1">{movie.title}</h4>
                        <p className="text-[10px] text-zinc-400 font-sans leading-relaxed line-clamp-3">
                          {movie.overview}
                        </p>
                        
                        {/* Live Equation Breakdown in popover */}
                        {movie.finalWeightedScore !== undefined && (
                          <div className="text-[9px] font-mono bg-zinc-950 p-2 rounded border border-zinc-800 space-y-1">
                            <div className="flex justify-between text-zinc-500 border-b border-zinc-900 pb-0.5">
                              <span>하이브리드 분할</span>
                              <span className="text-brand-red">W_Score</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-indigo-400">α·CF</span>
                              <span className="text-zinc-300">{movie.cfScore}</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-green-400">β·Content</span>
                              <span className="text-zinc-300">{movie.contentScore}</span>
                            </div>
                            <div className="flex justify-between">
                              <span className="text-amber-400">γ·Popularity</span>
                              <span className="text-zinc-300">{movie.popularityScore}</span>
                            </div>
                          </div>
                        )}
                      </div>

                      {/* Interactive Bottom Feedback Panel */}
                      <div className="flex items-center gap-2 pt-2 border-t border-zinc-900">
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            onSelect(movie);
                          }}
                          className="flex-1 bg-zinc-800 hover:bg-zinc-700 text-white text-[10px] py-1 rounded font-medium text-center"
                        >
                          정보
                        </button>
                        
                        {/* Satisfaction (LIKE) feedback action */}
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            onLike(movie.id);
                          }}
                          className="p-1 px-1.5 bg-zinc-900 border border-zinc-800 hover:border-indigo-500 rounded text-zinc-400 hover:text-white hover:bg-neutral-800 transition-all flex items-center justify-center"
                          title="만족해요"
                        >
                          <ThumbsUp className="w-3.5 h-3.5 text-indigo-400" />
                        </button>

                        {/* Dissatisfaction (DISLIKE) feedback action -> Optimistic Trigger */}
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            onDislike(movie.id);
                          }}
                          className="p-1 px-1.5 bg-zinc-900 border border-zinc-800 hover:border-brand-red rounded text-zinc-400 hover:text-white hover:bg-neutral-800 transition-all flex items-center justify-center"
                          title="불만족해요 (목록에서 페이드아웃 청소)"
                        >
                          <ThumbsDown className="w-3.5 h-3.5 text-brand-red" />
                        </button>
                      </div>
                    </div>

                  </div>
                </motion.div>
              );
            })}
          </AnimatePresence>
        </div>
      )}
    </div>
  );
}
