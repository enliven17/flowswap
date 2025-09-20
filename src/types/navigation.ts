export interface NavItem {
  id: string;
  label: string;
  icon: React.ReactNode;
  active?: boolean;
  disabled?: boolean;
}

export interface NavigationState {
  activeItem: string;
  history: string[];
}

export type NavItemId = 'balance' | 'swap' | 'pools' | 'bridge' | 'info' | 'actions';