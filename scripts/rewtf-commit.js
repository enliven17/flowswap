#!/usr/bin/env node

/**
 * REWTF Commit Helper
 * 
 * Bu script, REWTF programı için optimize edilmiş commit mesajları oluşturur.
 * Düzenli commit'ler daha fazla puan kazandırır.
 */

const { execSync } = require('child_process');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const commitTypes = {
  'feat': '✨ Yeni özellik',
  'fix': '🐛 Bug düzeltmesi', 
  'docs': '📚 Dokümantasyon',
  'style': '💄 Stil değişiklikleri',
  'refactor': '♻️ Kod refactoring',
  'test': '🧪 Test ekleme/düzeltme',
  'chore': '🔧 Bakım işleri',
  'perf': '⚡ Performans iyileştirmesi',
  'build': '📦 Build sistem değişiklikleri',
  'ci': '👷 CI/CD değişiklikleri'
};

console.log('🌊 REWTF Commit Helper - FlowSwap');
console.log('================================\n');

console.log('Commit türünü seçin:');
Object.entries(commitTypes).forEach(([key, value], index) => {
  console.log(`${index + 1}. ${key}: ${value}`);
});

rl.question('\nTür numarası (1-10): ', (typeNum) => {
  const types = Object.keys(commitTypes);
  const selectedType = types[parseInt(typeNum) - 1];
  
  if (!selectedType) {
    console.log('❌ Geçersiz seçim!');
    process.exit(1);
  }

  rl.question('Commit mesajı: ', (message) => {
    rl.question('Detaylı açıklama (opsiyonel): ', (description) => {
      
      let commitMessage = `${selectedType}: ${message}`;
      
      if (description) {
        commitMessage += `\n\n${description}`;
      }
      
      // REWTF hashtag'i ekle
      commitMessage += '\n\n#ReWTF #FlowBlockchain';
      
      try {
        // Git add ve commit
        execSync('git add .', { stdio: 'inherit' });
        execSync(`git commit -m "${commitMessage}"`, { stdio: 'inherit' });
        
        console.log('\n✅ Commit başarılı!');
        console.log('💡 İpucu: Düzenli commit\'ler REWTF\'de daha fazla puan kazandırır!');
        
      } catch (error) {
        console.error('❌ Commit hatası:', error.message);
      }
      
      rl.close();
    });
  });
});