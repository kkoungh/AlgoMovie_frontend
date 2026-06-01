/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React from 'react';
import { Database, Trash2, Shield, Radio, Activity, RefreshCw } from 'lucide-react';
import { RedisCacheStats } from '../types';

interface RedisConsoleProps {
  stats: RedisCacheStats;
  onClear: () => void;
  onRefresh: () => void;
}

export default function RedisConsole({ stats, onClear, onRefresh }: RedisConsoleProps) {
  const hitRatio = stats.hits + stats.misses > 0 
    ? ((stats.hits / (stats.hits + stats.misses)) * 100).toFixed(1)
    : "0.0";

  return (
    <div className="bg-zinc-950 border border-zinc-900 rounded-2xl p-6 md:p-8 space-y-6 shadow-2xl relative overflow-hidden">
      
      {/* Decorative pulse point */}
      <div className="absolute top-6 right-6 flex items-center gap-2">
        <span className="w-2 h-2 rounded-full bg-green-500 animate-ping"></span>
        <span className="text-[10px] font-mono text-zinc-500">REDIS_STANDBY</span>
      </div>

      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 border-b border-zinc-900 pb-5">
        <div>
          <div className="flex items-center gap-2">
            <Database className="w-5 h-5 text-brand-red" />
            <h3 className="font-display font-extrabold text-lg text-white">Redis Cache 고속 분산 캐시 터미널</h3>
          </div>
          <p className="text-xs text-zinc-500 mt-1">TTL 1시간 설정 기반 추천 가중치 데이터베이스 응답 캐싱</p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={onRefresh}
            className="p-1 px-3 bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 hover:border-zinc-700 text-zinc-400 hover:text-white rounded-lg text-xs flex items-center gap-1 cursor-pointer transition-all"
            title="콘솔 통계 동기화"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>상태 갱신</span>
          </button>
          
          <button
            onClick={onClear}
            className="p-1 px-3 bg-red-950/40 hover:bg-red-900/40 border border-brand-red/30 hover:border-brand-red text-brand-red text-xs rounded-lg flex items-center gap-1.5 cursor-pointer transition-all font-medium"
            title="캐시 비우기"
          >
            <Trash2 className="w-3.5 h-3.5" />
            <span>캐시 소거</span>
          </button>
        </div>
      </div>

      {/* Numerical Metrics */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        
        <div className="bg-netflix-black border border-zinc-900 p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-mono text-zinc-500 uppercase">성공 캐시 히트 (Hits)</span>
            <Activity className="w-3.5 h-3.5 text-green-500" />
          </div>
          <span className="text-2xl font-display font-extrabold text-green-400 block mt-1">{stats.hits}</span>
        </div>

        <div className="bg-netflix-black border border-zinc-900 p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-mono text-zinc-500 uppercase">미스 카운트 (Misses)</span>
            <Radio className="w-3.5 h-3.5 text-zinc-500 animate-pulse" />
          </div>
          <span className="text-2xl font-display font-extrabold text-zinc-400 block mt-1">{stats.misses}</span>
        </div>

        <div className="bg-netflix-black border border-zinc-900 p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-mono text-zinc-500 uppercase">최종 적중 배율 (%)</span>
            <span className="text-[10px] font-mono text-indigo-400">Hits/Queries</span>
          </div>
          <span className="text-2xl font-display font-extrabold text-indigo-400 block mt-1">{hitRatio}%</span>
        </div>

        <div className="bg-netflix-black border border-zinc-900 p-4 rounded-xl">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-mono text-zinc-500 uppercase">캐싱 분할 개수</span>
            <Shield className="w-3.5 h-3.5 text-brand-red" />
          </div>
          <span className="text-2xl font-display font-extrabold text-brand-red block mt-1">{stats.keysCount}개</span>
        </div>

      </div>

      {/* Terminal Display */}
      <div className="bg-neutral-950 font-mono text-xs rounded-xl border border-zinc-900 p-4 space-y-3 dark:shadow-inner text-zinc-400">
        <div className="flex items-center gap-1.5 text-zinc-500 border-b border-zinc-900 pb-2">
          <span className="w-2.5 h-2.5 rounded-full bg-brand-red inline-block"></span>
          <span className="w-2.5 h-2.5 rounded-full bg-amber-500 inline-block"></span>
          <span className="w-2.5 h-2.5 rounded-full bg-zinc-800 inline-block"></span>
          <span className="ml-2">algomovie@redis-cluster:~# keys *</span>
        </div>

        <div className="max-h-[160px] overflow-y-auto space-y-2.5 pr-2">
          {stats.entries.length === 0 ? (
            <div className="text-zinc-600 italic select-none">
              (Empty Redis DB - 가산 필터나 정렬 가중치를 수정하여 캐시 세션을 수집하세요)
            </div>
          ) : (
            stats.entries.map((entry, idx) => (
              <div key={idx} className="bg-zinc-900/60 p-2.5 rounded border border-zinc-800/50 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div className="space-y-0.5 truncate">
                  <div className="text-zinc-300 font-semibold truncate select-all">{entry.key}</div>
                  <div className="text-[10px] text-zinc-500">
                    만료시각: {new Date(entry.expiresAt).toLocaleTimeString()} (TTL 1Hour)
                  </div>
                </div>
                <div className="text-[10px] font-bold bg-zinc-800/80 p-0.5 px-2 rounded text-indigo-400 border border-zinc-700/60 select-none flex-none self-start sm:self-auto">
                  {entry.size} Bytes
                </div>
              </div>
            ))
          )}
        </div>
      </div>
      
    </div>
  );
}
