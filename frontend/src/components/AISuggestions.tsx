/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { Sparkles, ArrowRight, MessageSquare, HelpCircle, Star, AlertCircle, Play } from 'lucide-react';
import { Movie } from '../types';

interface AISuggestionsProps {
  token: string;
  onSelectMovie: (movie: Movie) => void;
}

export default function AISuggestions({ token, onSelectMovie }: AISuggestionsProps) {
  const [prompt, setPrompt] = useState('');
  const [loading, setLoading] = useState(false);
  const [aiText, setAiText] = useState('');
  const [matchedMovies, setMatchedMovies] = useState<Movie[]>([]);
  const [isAIReal, setIsAIReal] = useState(false);
  const [error, setError] = useState('');

  const PRESET_QUERIES = [
    { text: "시공간 아인슈타인 수식 블랙홀 공상과학 명작", label: "🪐 블랙홀 과학극" },
    { text: "현대 사회 빈부 격차와 서스펜스가 혼합된 한국 블랙 코미디 스릴러", label: "🏠 기생충 서스펜스" },
    { text: "라이언 고슬링이 나오는 밤하늘 야경 배경의 서정적이고 애절한 멜로 음악물", label: "🎷 라라랜드 낭만주의" }
  ];

  const handleAsk = async (e?: React.FormEvent, customValue?: string) => {
    if (e) e.preventDefault();
    const queryValue = customValue || prompt;
    if (!queryValue.trim()) return;

    setLoading(true);
    setError('');
    setAiText('');
    setMatchedMovies([]);

    try {
      const response = await fetch('/api/movies/ai-suggest', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify({ prompt: queryValue })
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || 'Gemini AI 연동 실패');
      }

      setAiText(data.aiText);
      setMatchedMovies(data.matchedMovies || []);
      setIsAIReal(data.isAIReal);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-zinc-950 border border-zinc-900 rounded-2xl p-6 md:p-8 space-y-6 shadow-2xl relative">
      <div>
        <div className="flex items-center gap-2">
          <Sparkles className="w-5 h-5 text-brand-red animate-pulse" />
          <h3 className="font-display font-extrabold text-lg text-white">Gemini AI 개인 맞춤 시놉시스 매칭</h3>
        </div>
        <p className="text-xs text-zinc-500 mt-1">
          질문하는 감정이나 테마에 가장 극적인 영화를 Gemini 인지 모델이 대화형으로 고속 추려냅니다
        </p>
      </div>

      {/* Blueprints / Quick buttons */}
      <div className="space-y-2">
        <span className="text-[10px] font-mono text-zinc-500 uppercase block">추천 질문 가이드 템플릿</span>
        <div className="flex flex-wrap gap-2">
          {PRESET_QUERIES.map((p, idx) => (
            <button
              key={idx}
              onClick={() => {
                setPrompt(p.text);
                handleAsk(undefined, p.text);
              }}
              disabled={loading}
              className="text-xs bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 hover:border-brand-red text-zinc-300 hover:text-white px-3 py-1.5 rounded-lg cursor-pointer transition-all text-left"
            >
              {p.label}
            </button>
          ))}
        </div>
      </div>

      {/* Main chat input */}
      <form onSubmit={(e) => handleAsk(e)} className="relative">
        <input
          type="text"
          value={prompt}
          onChange={(e) => setPrompt(e.target.value)}
          placeholder="인문학적 사유를 깊게 자극하는 고품격 시네마 스릴러 소개해 줘..."
          className="w-full bg-netflix-black border border-zinc-800 focus:border-brand-red rounded-xl py-4 pl-4 pr-16 text-sm text-white focus:outline-none focus:ring-1 focus:ring-brand-red font-sans transition-all"
        />
        <button
          type="submit"
          disabled={loading}
          className="absolute right-2 top-2.5 bg-brand-red hover:bg-brand-red-hover p-2 text-white rounded-lg flex items-center justify-center transition-all cursor-pointer disabled:opacity-50"
        >
          {loading ? (
            <span className="h-4 w-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
          ) : (
            <ArrowRight className="w-4 h-4" />
          )}
        </button>
      </form>

      {/* Response Display panel */}
      {(aiText || loading || error) && (
        <div className="border border-zinc-800 bg-netflix-black rounded-xl p-5 space-y-4">
          <div className="flex items-center justify-between border-b border-zinc-900 pb-3">
            <span className="text-xs font-mono text-zinc-400 flex items-center gap-1.5">
              <MessageSquare className="w-4 h-4 text-brand-red" />
              Gemini AI Specialist RECR
            </span>
            <div className="flex items-center gap-1">
              <span className={`w-2 h-2 rounded-full ${isAIReal ? 'bg-purple-500' : 'bg-amber-500'}`}></span>
              <span className="text-[10px] font-mono text-zinc-500">
                {isAIReal ? 'GEMINI_SERVER_ONLINE' : 'LOCAL_HEURISTICS_FALLBACK'}
              </span>
            </div>
          </div>

          {loading ? (
            <div className="flex flex-col items-center justify-center py-6 gap-2">
              <span className="h-6 w-6 border-2 border-brand-red border-t-transparent rounded-full animate-spin"></span>
              <span className="text-xs font-mono text-zinc-500 animate-pulse">지능형 텍스트 구조 분석 검색 중...</span>
            </div>
          ) : error ? (
            <div className="p-3 bg-red-950/20 border border-brand-red/40 text-red-200 text-xs rounded-lg flex items-center gap-2">
              <AlertCircle className="w-4 h-4 text-brand-red" />
              <span>오류가 발생했습니다: {error}</span>
            </div>
          ) : (
            <div className="space-y-4">
              <p className="text-sm font-sans text-zinc-200 leading-relaxed whitespace-pre-wrap">
                {aiText}
              </p>

              {/* Matched movies inside AI context */}
              {matchedMovies.length > 0 && (
                <div className="space-y-2 pt-2 border-t border-zinc-900">
                  <span className="text-[10px] font-mono text-zinc-500 uppercase block">추천 연관 콘텐츠 매칭 결과</span>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {matchedMovies.map((movie) => (
                      <div
                        key={movie.id}
                        onClick={() => onSelectMovie(movie)}
                        className="bg-zinc-900 hover:bg-zinc-800/80 border border-zinc-800 hover:border-brand-red/50 rounded-lg p-3 flex gap-3 items-center cursor-pointer transition-all"
                      >
                        {movie.posterUrl ? (
                          <img
                            src={movie.posterUrl}
                            alt={movie.title}
                            className="w-10 h-14 object-cover rounded shadow"
                          />
                        ) : (
                          <div className="w-10 h-14 bg-zinc-950 border border-zinc-800 rounded flex items-center justify-center text-[10px] text-zinc-600 font-mono">
                            N
                          </div>
                        )}
                        <div className="flex-1 min-w-0">
                          <h4 className="text-xs font-bold text-white truncate">{movie.title}</h4>
                          <span className="text-[10px] text-zinc-500 block mt-0.5">{movie.genre.join(", ")} • {movie.year}</span>
                          <span className="text-[10px] text-brand-red font-mono font-semibold block mt-1">★ {movie.rating}</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
