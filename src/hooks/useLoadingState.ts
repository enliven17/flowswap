import { useState, useCallback } from 'react';

export interface LoadingState {
  isLoading: boolean;
  error: string | null;
  success: boolean;
}

export function useLoadingState(initialState: Partial<LoadingState> = {}) {
  const [state, setState] = useState<LoadingState>({
    isLoading: false,
    error: null,
    success: false,
    ...initialState,
  });

  const setLoading = useCallback((loading: boolean) => {
    setState(prev => ({
      ...prev,
      isLoading: loading,
      error: loading ? null : prev.error,
      success: loading ? false : prev.success,
    }));
  }, []);

  const setError = useCallback((error: string | null) => {
    setState(prev => ({
      ...prev,
      error,
      isLoading: false,
      success: false,
    }));
  }, []);

  const setSuccess = useCallback((success: boolean) => {
    setState(prev => ({
      ...prev,
      success,
      isLoading: false,
      error: success ? null : prev.error,
    }));
  }, []);

  const reset = useCallback(() => {
    setState({
      isLoading: false,
      error: null,
      success: false,
    });
  }, []);

  return {
    ...state,
    setLoading,
    setError,
    setSuccess,
    reset,
  };
}