import React from 'react';
import { FlickeringGridDemo } from '@/components/ui/flickering-grid-demo';

export default function TestFlickeringGridPage() {
  return (
    <div className="min-h-screen bg-black">
      <FlickeringGridDemo />
      
      {/* Overlay content */}
      <div className="absolute inset-0 flex items-center justify-center z-20">
        <div className="text-center text-white">
          <h1 className="text-6xl font-bold mb-4">FlowSwap</h1>
          <p className="text-xl opacity-80">Flickering Grid Background Test</p>
        </div>
      </div>
    </div>
  );
} 