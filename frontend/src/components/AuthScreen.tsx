/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState } from 'react';
import { Film, User, Mail, Lock, ShieldCheck, ArrowRight } from 'lucide-react';

interface AuthScreenProps {
  onSuccess: (token: string, user: { id: string; email: string; name: string; ratingsCount: number; preferences: string[] }) => void;
}

export default function AuthScreen({ onSuccess }: AuthScreenProps) {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('munseohee3070@gmail.com');
  const [password, setPassword] = useState('admin123');
  const [name, setName] = useState('문서희');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleAuth = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    const url = isLogin ? '/api/auth/login' : '/api/auth/register';
    const body = isLogin ? { email, password } : { email, name, password };

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });

      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.error || '인증 과정에 실패했습니다.');
      }

      onSuccess(data.token, data.user);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const loadDemoUser = () => {
    setEmail('munseohee3070@gmail.com');
    setPassword('admin123');
    setIsLogin(true);
  };

  return (
    <div 
      className="relative min-h-screen flex items-center justify-center bg-cover bg-center px-4"
      style={{
        backgroundImage: 'linear-gradient(rgba(0, 0, 0, 0.75), rgba(0, 0, 0, 0.9)), url("https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1600&auto=format&fit=crop&q=80")'
      }}
    >
      <div 
        id="authtitle-bar" 
        className="absolute top-0 left-0 w-full p-6 flex justify-between items-center border-b border-zinc-900 bg-gradient-to-b from-black/80 to-transparent"
      >
        <div className="flex items-center gap-2">
          <Film className="w-8 h-8 text-brand-red fill-brand-red animate-pulse" />
          <span className="font-display font-extrabold text-2xl tracking-tighter text-brand-red">
            AlgoMovie
          </span>
        </div>
        <div className="text-xs text-zinc-500 font-mono hidden md:block">
          국립창원대학교 컴퓨터공학과 프로젝트 최적화 아키텍처
        </div>
      </div>

      <div 
        id="auth-card" 
        className="w-full max-w-md bg-zinc-950/95 border border-zinc-800 p-8 rounded-2xl shadow-2xl backdrop-blur-md"
      >
        <div className="text-center mb-6">
          <h2 className="font-display font-bold text-3xl text-white">
            {isLogin ? '로그인' : '회원가입'}
          </h2>
          <p className="text-xs text-zinc-400 mt-2">
            AlgoMovie 가중치 기반 개인화 알고리즘에 가입하세요
          </p>
        </div>

        {error && (
          <div className="bg-red-950/60 border border-brand-red text-red-200 text-xs p-3 rounded-lg mb-4 text-center font-sans tracking-wide">
            ⚠️ {error}
          </div>
        )}

        <form onSubmit={handleAuth} className="space-y-4">
          {!isLogin && (
            <div>
              <label className="block text-xs font-medium text-zinc-400 mb-1">성함</label>
              <div className="relative">
                <User className="absolute left-3 top-2.5 text-zinc-500 w-4.5 h-4.5" />
                <input
                  type="text"
                  required
                  placeholder="홍길동"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full bg-zinc-900/80 border border-zinc-700/60 rounded-lg py-2 pl-10 pr-4 text-sm text-white focus:outline-none focus:border-brand-red focus:ring-1 focus:ring-brand-red transition-all"
                />
              </div>
            </div>
          )}

          <div>
            <label className="block text-xs font-medium text-zinc-400 mb-1">이메일 주소</label>
            <div className="relative">
              <Mail className="absolute left-3 top-2.5 text-zinc-500 w-4.5 h-4.5" />
              <input
                type="email"
                required
                placeholder="you@domain.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full bg-zinc-900/80 border border-zinc-700/60 rounded-lg py-2 pl-10 pr-4 text-sm text-white focus:outline-none focus:border-brand-red focus:ring-1 focus:ring-brand-red transition-all"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium text-zinc-400 mb-1">비밀번호</label>
            <div className="relative">
              <Lock className="absolute left-3 top-2.5 text-zinc-500 w-4.5 h-4.5" />
              <input
                type="password"
                required
                minLength={6}
                placeholder="••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full bg-zinc-900/80 border border-zinc-700/60 rounded-lg py-2 pl-10 pr-4 text-sm text-white focus:outline-none focus:border-brand-red focus:ring-1 focus:ring-brand-red transition-all"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-brand-red hover:bg-brand-red-hover hover:scale-[1.02] text-white font-semibold text-sm py-2.5 rounded-lg flex items-center justify-center gap-2 cursor-pointer transition-all hover:shadow-lg hover:shadow-brand-red/20 active:scale-[0.98] mt-6"
          >
            {loading ? (
              <span className="h-4 w-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
            ) : (
              <>
                <span>{isLogin ? '로그인 완료' : '회원가입 완료'}</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        <div className="relative my-6">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-zinc-800"></div>
          </div>
          <div className="relative flex justify-center text-xs">
            <span className="bg-zinc-950 px-2 text-zinc-500 font-sans">또는 빠른 계정</span>
          </div>
        </div>

        <button
          onClick={loadDemoUser}
          className="w-full bg-zinc-900 border border-zinc-800 hover:bg-zinc-800/80 text-zinc-200 text-xs py-2 rounded-lg flex items-center justify-center gap-2 cursor-pointer transition-all"
        >
          <ShieldCheck className="w-4 h-4 text-green-500" />
          <span>창원대 테스트 데모 계정 즉시 연결</span>
        </button>

        <div className="text-center mt-6 text-xs text-zinc-400">
          {isLogin ? '아직 계정이 없으신가요?' : '이미 계정이 있으신가요?'} {' '}
          <button
            onClick={() => setIsLogin(!isLogin)}
            className="text-brand-red hover:underline font-medium ml-1 cursor-pointer"
          >
            {isLogin ? '회원가입하기' : '로그인하러 가기'}
          </button>
        </div>
      </div>
    </div>
  );
}
