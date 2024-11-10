module.exports = {
   testEnvironment: 'jsdom',
   setupFilesAfterEnv: ['<rootDir>/config/jest/jest.setup.js'],
   testPathIgnorePatterns: ['<rootDir>/.next/', '<rootDir>/node_modules/'],
   moduleNameMapper: {
     '^@/(.*)$': '<rootDir>/src/$1',
     '\\.(css|less|sass|scss)$': 'identity-obj-proxy',
   },
   transform: {
     '^.+\\.(js|jsx|ts|tsx)$': ['babel-jest', { presets: ['next/babel'] }],
   },
   collectCoverageFrom: [
     'src/**/*.{js,jsx,ts,tsx}',
     '!src/**/*.d.ts',
     '!src/**/*.stories.{js,jsx,ts,tsx}',
     '!src/**/*.test.{js,jsx,ts,tsx}',
     '!src/types/**/*',
   ],
   coverageThreshold: {
     global: {
       branches: 80,
       functions: 80,
       lines: 80,
       statements: 80,
     },
   },
 }
 