import '@testing-library/jest-dom'
import 'whatwg-fetch'

// Mock do serviço de geocoding
jest.mock('@/lib/geocoding', () => ({
  reverseGeocode: jest.fn().mockResolvedValue({
    success: true,
    address: {
      street: 'Test Street',
      number: '123',
      city: 'Test City',
      state: 'Test State',
      country: 'Test Country',
      postalCode: '12345',
    },
  }),
}))

// Configuração global do fetch
global.fetch = jest.fn()

// Limpar mocks após cada teste
afterEach(() => {
  jest.clearAllMocks()
})

// Silenciar warnings do console durante os testes
global.console = {
  ...console,
  warn: jest.fn(),
  error: jest.fn(),
}
