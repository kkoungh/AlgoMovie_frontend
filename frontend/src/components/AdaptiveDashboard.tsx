/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { Sliders, HelpCircle, RefreshCw, BarChart2, Star, CheckCircle, Info, Heart, Trash2 } from 'lucide-react';
import { RecommendationWeights } from '../types';

interface AdaptiveDashboardProps {
  weights: RecommendationWeights;
  userStats: {
    name: string;
    email: string;
    ratingsCount: number;
    likedCount: number;
    dislikedCount: number;
    preferences: string[];
  };
  onWeightsChange: (newWeights: RecommendationWeights) => void;
  onPreferencesChange: (genres: string[]) => void;
  onReset: () => void;
}

const GENRE_POOL = ["Action", "Sci-Fi", "Drama", "Thriller", "Adventure", "Crime", "Comedy", "Romance", "Animation"];

export default function AdaptiveDashboard({
  weights,
  userStats,
  onWeightsChange,
  onPreferencesChange,
  onReset
}: AdaptiveDashboardProps) {

  const handleSliderChange = (param: 'alpha' | 'beta' | 'gamma', value: number) => {
    // If the account has 0 reviews, the rule locks alpha at 0.0, beta=0.5, gamma=0.5. Let's warn them!
    if (userStats.ratingsCount === 0) {
      alert("신규 가입 유저(평점 0개)의 가중치는 규칙에 따라 고정됩니다: [α=0.0, β=0.5, γ=0.5]\n평가를 등록하거나 '만족해요/불만족해요' 단추를 눌러 평점 개수를 적립하세요!");
      return;
    }

    const nextWeights = { ...weights };
    nextWeights[param] = value;
    
    // Auto-normalize the other two weights so the sum always equals 1.0
    const otherParams = (['alpha', 'beta', 'gamma'] as const).filter(p => p !== param);
    const sumOthers = nextWeights[otherParams[0]] + nextWeights[otherParams[1]];

    const remaining = 1.0 - value;
    if (sumOthers > 0) {
      nextWeights[otherParams[0]] = Number((remaining * (nextWeights[otherParams[0]] / sumOthers)).toFixed(3));
      nextWeights[otherParams[1]] = Number((remaining * (nextWeights[otherParams[1]] / sumOthers)).toFixed(3));
    } else {
      nextWeights[otherParams[0]] = Number((remaining * 0.5).toFixed(3));
      nextWeights[otherParams[1]] = Number((remaining * 0.5).toFixed(3));
    }

    onWeightsChange(nextWeights);
  };

  const toggleGenrePreference = (genre: string) => {
    const nextPrefs = userStats.preferences.includes(genre)
      ? userStats.preferences.filter(g => g !== genre)
      : [...userStats.preferences, genre];
    onPreferencesChange(nextPrefs);
  };

  // Determine evolutionary scale mode description
  const count = userStats.ratingsCount;
  let adaptiveStatus = "";
  let adaptiveSubtitle = "";
  
  if (count === 0) {
    adaptiveStatus = "신입 관객 (Mute CF Mode)";
    adaptiveSubtitle = "등록 평점 0개: 협업 필터링 미활성화 (α=0.0, β=0.5, γ=0.5 고정)";
  } else if (count >= 1 && count < 20) {
    adaptiveStatus = "성장하는 알고리즘 (Adaptive Real-Time)";
    adaptiveSubtitle = `등록 평점 ${count}개: 밀도에 따른 인핸싱 (α=${weights.alpha}, β=${weights.beta}, γ=${weights.gamma})`;
  } else {
    adaptiveStatus = "메가 영화마니아 프로 (Expert CF Unlock)";
    adaptiveSubtitle = `등록 평점 ${count}개 돌파: 하이브리드 완전 개방 (CF 최대 비율 α=0.7)`;
  }

  return (
    <div className="bg-zinc-950 border border-zinc-900 rounded-2xl p-6 md:p-8 space-y-6 shadow-2xl">
      
      {/* Header Info */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-zinc-900 pb-5">
        <div>
          <div className="flex items-center gap-2">
            <Sliders className="w-5 h-5 text-brand-red animate-pulse" />
            <h3 className="font-display font-extrabold text-lg text-white">진화형 하이브리드 추천 통제 패널</h3>
          </div>
          <p className="text-xs text-zinc-500 mt-1">창원대학교 하이브리드 점수 가중치 방정식 통계 대시보드</p>
        </div>

        <button
          onClick={onReset}
          className="flex items-center gap-1.5 px-3 py-1.5 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 hover:border-brand-red rounded-lg text-zinc-300 hover:text-white text-xs cursor-pointer transition-all self-start md:self-auto"
        >
          <RefreshCw className="w-3.5 h-3.5" />
          <span>기본 비례 갱신</span>
        </button>
      </div>

      {/* Formula Math Box */}
      <div className="bg-netflix-black border border-zinc-900 rounded-xl p-4 md:px-6 flex flex-col md:flex-row items-center justify-between gap-4 text-center md:text-left relative overflow-hidden">
        <div className="absolute top-0 right-0 w-32 h-32 bg-brand-red/5 rounded-full blur-2xl pointer-events-none" />
        
        <div className="space-y-1">
          <div className="text-[10px] font-mono text-zinc-500 tracking-wider">HARMONIC RECR_ENGINE FORMULA</div>
          <div className="font-display text-base md:text-lg text-white font-extrabold tracking-tight">
            최종 점수 = <span className="text-indigo-400 font-mono">(α × CF)</span> + <span className="text-green-400 font-mono">(β × Content)</span> + <span className="text-amber-400 font-mono">(γ × Popularity)</span>
          </div>
          <div className="text-[11px] text-zinc-400 font-sans">
            개별 인덱스의 유사 도출값을 가중 합성하여 정렬 스코어를 출력하는 실시간 다차원 정렬 수식
          </div>
        </div>

        <div className="bg-zinc-950 p-2 px-4 rounded-xl border border-zinc-900 text-center flex-none min-w-[140px]">
          <span className="text-[9px] font-mono text-zinc-500 block uppercase">실시간 합성 합계</span>
          <span className="text-xl font-display font-black text-brand-red">
            {(weights.alpha + weights.beta + weights.gamma).toFixed(1)} <span className="text-xs text-zinc-400">/ 1.0</span>
          </span>
        </div>
      </div>

      {/* Evolutionary adaptive banner */}
      <div className="bg-zinc-900/40 border border-zinc-800/50 rounded-xl p-4 flex items-start gap-3">
        <Info className="w-5 h-5 text-indigo-400 flex-none mt-0.5" />
        <div className="space-y-1">
          <span className="text-xs font-mono font-bold text-indigo-400 uppercase tracking-widest block">
            {adaptiveStatus}
          </span>
          <p className="text-xs text-zinc-300 leading-normal font-sans">
            {adaptiveSubtitle}
          </p>
          <div className="text-[10px] text-zinc-500">
            * 피드백 누적수가 임계점(5개, 20개)을 초과할 경우, 데이터 밀집도가 확보되어 협업 알고리즘(CF)의 가중 비중이 확장 연동됩니다.
          </div>
        </div>
      </div>

      {/* Main Weights Controls Sliders */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        
        {/* ALPHA Collaborative Filtering Slider */}
        <div className="bg-zinc-950 border border-zinc-900 p-4 rounded-xl space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-xs font-bold text-zinc-300 flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 bg-indigo-500 rounded-full inline-block"></span>
              협업 필터링 (α)
            </span>
            <span className="text-xs font-mono font-bold text-indigo-400 bg-indigo-950 px-2 py-0.5 rounded border border-indigo-900">
              {weights.alpha.toFixed(3)}
            </span>
          </div>
          <p className="text-[10px] text-zinc-500">
            유사 유저 성향 및 내가 예전에 &apos;만족해요&apos;를 눌렀던 영화 평점 데이터를 비교 매치하는 척도입니다.
          </p>
          <input
            type="range"
            min="0"
            max="0.7"
            step="0.01"
            disabled={userStats.ratingsCount === 0}
            value={weights.alpha}
            onChange={(e) => handleSliderChange('alpha', Number(e.target.value))}
            className="w-full accent-indigo-500 cursor-pointer h-1.5 bg-zinc-900 rounded-lg disabled:opacity-30"
          />
          <div className="flex justify-between text-[8px] text-zinc-600 font-mono">
            <span>최소: 0.0</span>
            <span>최대 상한선: 0.7</span>
          </div>
        </div>

        {/* BETA Content Weight Slider */}
        <div className="bg-zinc-950 border border-zinc-900 p-4 rounded-xl space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-xs font-bold text-zinc-300 flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 bg-green-500 rounded-full inline-block"></span>
              인물/장르 시너스 (β)
            </span>
            <span className="text-xs font-mono font-bold text-green-400 bg-green-950 px-2 py-0.5 rounded border border-green-900">
              {weights.beta.toFixed(3)}
            </span>
          </div>
          <p className="text-[10px] text-zinc-500">
            내가 선택한 메타 선호 장르 뼈대 및 핵심 시놉시스 키워드 텍스트 유사도를 도출하여 비교합니다.
          </p>
          <input
            type="range"
            min="0.1"
            max="0.9"
            step="0.01"
            disabled={userStats.ratingsCount === 0}
            value={weights.beta}
            onChange={(e) => handleSliderChange('beta', Number(e.target.value))}
            className="w-full accent-green-500 cursor-pointer h-1.5 bg-zinc-900 rounded-lg disabled:opacity-30"
          />
          <div className="flex justify-between text-[8px] text-zinc-600 font-mono">
            <span>최소: 0.1</span>
            <span>최대: 0.9</span>
          </div>
        </div>

        {/* GAMMA Popularity Weight Slider */}
        <div className="bg-zinc-950 border border-zinc-900 p-4 rounded-xl space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-xs font-bold text-zinc-300 flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 bg-amber-500 rounded-full inline-block"></span>
              대중성/트렌드 (γ)
            </span>
            <span className="text-xs font-mono font-bold text-amber-400 bg-amber-950 px-2 py-0.5 rounded border border-amber-900">
              {weights.gamma.toFixed(3)}
            </span>
          </div>
          <p className="text-[10px] text-zinc-500">
            전체 관람 인원수 및 평단의 객관적 흥행 스코어 스케일을 반영하여 검증 빈도를 가중 조절합니다.
          </p>
          <input
            type="range"
            min="0.1"
            max="0.9"
            step="0.01"
            disabled={userStats.ratingsCount === 0}
            value={weights.gamma}
            onChange={(e) => handleSliderChange('gamma', Number(e.target.value))}
            className="w-full accent-amber-500 cursor-pointer h-1.5 bg-zinc-900 rounded-lg disabled:opacity-30"
          />
          <div className="flex justify-between text-[8px] text-zinc-600 font-mono">
            <span>최소: 0.1</span>
            <span>최대: 0.9</span>
          </div>
        </div>

      </div>

      {/* Dynamic Profile Genre Settings */}
      <div className="bg-netflix-black border border-zinc-900 p-5 rounded-xl space-y-4">
        <div className="flex justify-between items-center border-b border-zinc-900 pb-3">
          <span className="text-xs font-bold text-zinc-300 flex items-center gap-1.5">
            <Heart className="w-4 h-4 text-brand-red fill-brand-red" />
            내 시놉시스 선호 관심 장르 (실시간 β-Content 점수 향상 유도)
          </span>
          <span className="text-[10px] text-zinc-500 font-mono">{userStats.preferences.length}개 선택됨</span>
        </div>
        <div className="flex flex-wrap gap-2">
          {GENRE_POOL.map((genre) => {
            const isSelected = userStats.preferences.includes(genre);
            return (
              <button
                key={genre}
                onClick={() => toggleGenrePreference(genre)}
                className={`text-xs px-3 py-1.5 rounded-full cursor-pointer transition-all border ${
                  isSelected 
                    ? 'bg-brand-red/10 border-brand-red text-white font-medium' 
                    : 'bg-zinc-900 border-zinc-800 text-zinc-400 hover:text-white hover:border-zinc-700'
                }`}
              >
                {genre}
              </button>
            );
          })}
        </div>
      </div>

      {/* User Interaction Stats row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="bg-zinc-950 border border-zinc-900 p-4 rounded-xl text-center">
          <span className="text-[10px] font-mono text-zinc-500 uppercase block">관객 수강생</span>
          <span className="text-sm font-bold text-white block mt-1 truncate">{userStats.name}</span>
        </div>
        <div className="bg-zinc-950 border border-zinc-900 p-4 rounded-xl text-center">
          <span className="text-[10px] font-mono text-zinc-500 uppercase block">적립 평가 수</span>
          <span className="text-lg font-display font-extrabold text-indigo-400 block mt-1">{userStats.ratingsCount}개</span>
        </div>
        <div className="bg-zinc-950 border border-zinc-900 p-4 rounded-xl text-center">
          <span className="text-[10px] font-mono text-zinc-500 uppercase block">도출 만족도 (L)</span>
          <span className="text-lg font-display font-extrabold text-green-400 block mt-1">{userStats.likedCount}개</span>
        </div>
        <div className="bg-zinc-950 border border-zinc-900 p-4 rounded-xl text-center">
          <span className="text-[10px] font-mono text-zinc-500 uppercase block">격리 비추수 (D)</span>
          <span className="text-lg font-display font-extrabold text-brand-red block mt-1">{userStats.dislikedCount}개</span>
        </div>
      </div>

    </div>
  );
}
