#!/usr/bin/env node

/**
 * Development server wrapper that handles Windows file system errors
 * by automatically cleaning .next directory on errors
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

const NEXT_DIR = path.join(__dirname, '..', '.next');
let retryCount = 0;
const MAX_RETRIES = 3;

function cleanNextDir() {
  try {
    if (fs.existsSync(NEXT_DIR)) {
      console.log('🧹 Cleaning .next directory...');
      fs.rmSync(NEXT_DIR, { recursive: true, force: true });
      console.log('✅ Cleaned successfully');
    }
  } catch (error) {
    console.error('❌ Error cleaning .next:', error.message);
  }
}

function startDevServer() {
  console.log(`🚀 Starting Next.js dev server (attempt ${retryCount + 1}/${MAX_RETRIES})...`);
  
  const devProcess = spawn('npx', ['next', 'dev', '--hostname', '0.0.0.0', '--port', '3000'], {
    stdio: 'inherit',
    shell: true,
    cwd: path.join(__dirname, '..'),
  });

  devProcess.on('error', (error) => {
    console.error('❌ Failed to start dev server:', error.message);
    if (retryCount < MAX_RETRIES) {
      retryCount++;
      console.log(`🔄 Retrying in 2 seconds...`);
      setTimeout(() => {
        cleanNextDir();
        startDevServer();
      }, 2000);
    } else {
      console.error('❌ Max retries reached. Please check your setup.');
      process.exit(1);
    }
  });

  devProcess.on('exit', (code) => {
    if (code !== 0 && code !== null) {
      console.log(`\n⚠️  Dev server exited with code ${code}`);
      // Check if it's a file system error (errno -4094)
      if (retryCount < MAX_RETRIES) {
        retryCount++;
        console.log(`🔄 Cleaning and retrying in 2 seconds...`);
        setTimeout(() => {
          cleanNextDir();
          startDevServer();
        }, 2000);
      }
    }
  });

  // Handle Ctrl+C gracefully
  process.on('SIGINT', () => {
    console.log('\n🛑 Stopping dev server...');
    devProcess.kill();
    process.exit(0);
  });
}

// Clean before starting
cleanNextDir();
startDevServer();

