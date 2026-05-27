/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { Play, Info, Volume2, VolumeX, Star, Award, Sparkles, AlertTriangle } from 'lucide-react';
import { Movie } from '../types';

interface HeroSliderProps {
  movie: Movie | null;
  onPlay: (movie: Movie) => void;
  onShowDetails: (movie: Movie) => void;
}

export default function HeroSlider({ movie, onPlay, onShowDetails }: HeroSliderProps) {
  const [muted, setMuted] = useState(true);

  if (!movie) {
    return (
      <div className="h-[60vh] bg-zinc-950 flex items-center justify-center border-b border-zinc-900">
        <div className="flex flex-col items-center gap-3">
          <Sparkles className="w-10 h-10 text-brand-red animate-spin" />
          <span className="text-zinc-500 font-mono text-xs">영화 아카이브 동기화 중...</span>
        </div>
      </div>
    );
  }

  return (
    <div className="relative h-[65vh] w-full bg-black overflow-hidden border-b border-zinc-900 group">
      {/* Background Image with Netflix-style gradient mask */}
      <img
        src={movie.posterUrl || "https://images.unsplash.com/photo-1444703686981-a3abbc4d4fe3?w=1600"}
        alt={movie.title}
        referrerPolicy="no-referrer"
        className="absolute top-0 left-0 w-full h-full object-cover opacity-60 scale-105 transition-all duration-[8000ms] ease-out select-none"
      />
      
      {/* Cinematic Overlays */}
      <div className="absolute inset-0 bg-gradient-to-t from-black via-transparent to-black/70" />
      <div className="absolute inset-0 bg-gradient-to-r from-black via-black/50 to-transparent" />

      {/* Decorative pulse glow lines mimicking active AI tracking */}
      <div className="absolute left-0 bottom-0 w-full h-[3px] bg-gradient-to-r from-brand-red via-brand-red/10 to-transparent pulse-glow" />

      {/* Hero Content Panel */}
      <div className="absolute bottom-16 left-6 md:left-12 max-w-2xl z-10 space-y-4">
        {/* Subtitle / Badge */}
        <div className="flex items-center gap-2">
          <div className="bg-brand-red text-white text-[10px] font-bold px-2 py-0.5 rounded-sm tracking-widest font-display flex items-center gap-1 shadow-sm">
            <Award className="w-3 h-3" />
            TOP 10 ALGO SPOTLIGHT
          </div>
          <span className="text-zinc-300 font-mono text-xs">
            {movie.year} • {movie.duration}
          </span>
          <div className="flex items-center gap-1 text-amber-500 text-xs font-mono font-bold bg-zinc-950/90 px-2 py-0.5 rounded-sm border border-white/10">
            <Star className="w-3 h-3 fill-amber-500" />
            {movie.rating}
          </div>
        </div>

        {/* Big Title (Premium cinematic styling) */}
        <h1 className="font-display font-black text-5xl md:text-6xl lg:text-7xl text-white tracking-tighter drop-shadow-2xl uppercase italic leading-none">
          {movie.title}
        </h1>

        {/* Synopsis */}
        <p className="text-sm md:text-base text-[#A3A3A3] drop-shadow-md max-w-xl leading-relaxed font-sans font-medium">
          {movie.overview}
        </p>

        {/* Highlight Score Breakdown if hovering */}
        {movie.finalWeightedScore && (
          <div className="bg-zinc-950/90 border border-white/10 backdrop-blur-md p-3.5 rounded-sm text-xs space-y-1.5 my-4 w-fit shadow-2xl">
            <div className="text-zinc-400 font-mono text-[10px] uppercase tracking-wider">AI 하이브리드 추천 매칭 스코어</div>
            <div className="text-base text-brand-red font-display font-black tracking-tight flex items-center gap-1.5">
              <span>★ {movie.finalWeightedScore}점</span> 
              <span className="text-zinc-500 font-normal font-sans text-[11px]">(100점 만점)</span>
            </div>
          </div>
        )}

        {/* Action Controls */}
        <div className="flex items-center gap-3 pt-2">
          <button
            onClick={() => onPlay(movie)}
            className="bg-white hover:bg-gray-200 text-black font-extrabold text-sm px-6 py-2.5 rounded-sm flex items-center gap-2 transition-all cursor-pointer hover:scale-[1.03] active:scale-95 shadow-md font-sans"
          >
            <Play className="w-4 h-4 fill-black text-black" />
            <span>Play Now</span>
          </button>
          
          <button
            onClick={() => onShowDetails(movie)}
            className="bg-white/20 hover:bg-white/30 text-white font-bold text-sm px-5 py-2.5 rounded-sm flex items-center gap-2 transition-all cursor-pointer hover:scale-[1.03] active:scale-95 backdrop-blur-md"
          >
            <Info className="w-4.5 h-4.5" />
            <span>More Info</span>
          </button>
        </div>
      </div>

      {/* Right Side Status & Volume Mute Indicator */}
      <div className="absolute bottom-12 right-6 md:right-12 z-10 flex items-center gap-4">
        <button
          onClick={() => setMuted(!muted)}
          className="p-2 bg-zinc-900/60 hover:bg-zinc-800 border border-zinc-800 rounded-full text-zinc-400 hover:text-white transition-all cursor-pointer"
          title={muted ? "음소거 해제" : "음소거"}
        >
          {muted ? <VolumeX className="w-5 h-5" /> : <Volume2 className="w-5 h-5" />}
        </button>
        <div className="w-1 bg-zinc-800 h-8 rounded-full overflow-hidden block">
          <div className="bg-brand-red h-3/5 rounded-full pulse-glow" />
        </div>
        <span className="text-zinc-500 font-mono text-[10px] hidden sm:inline">ALGO_STREAM ACTIVE</span>
      </div>
    </div>
  );
}
