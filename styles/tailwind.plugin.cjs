/**
 * elm-web3-ui — Tailwind CSS Plugin
 *
 * Maps all elm-web3-ui class names to Tailwind utilities.
 * Works with plain Tailwind or Tailwind + shadcn/ui.
 *
 * Usage (tailwind.config.js):
 *   const web3Ui = require('./styles/tailwind.plugin.cjs')
 *   module.exports = { plugins: [web3Ui] }
 *
 * Or if installed as a package:
 *   plugins: [require('elm-web3-ui/styles/tailwind.plugin.cjs')]
 *
 * With shadcn: the plugin uses shadcn's CSS variable conventions
 * (bg-primary, text-primary-foreground, etc.) so your shadcn
 * theme is picked up automatically.
 *
 * Without shadcn: defaults to sensible neutral Tailwind classes.
 * Override by editing this file or extending your theme.
 */

const plugin = require('tailwindcss/plugin')

module.exports = plugin(function ({ addComponents, addUtilities }) {
  // ----- Shared button base ----------------------------------
  const buttonBase = {
    display: 'inline-flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '0.5rem',
    padding: '0.5rem 1rem',
    fontSize: '0.875rem',
    fontWeight: '500',
    lineHeight: '1.25rem',
    borderRadius: 'var(--radius, 0.375rem)',
    border: '1px solid transparent',
    cursor: 'pointer',
    textDecoration: 'none',
    whiteSpace: 'nowrap',
    transitionProperty: 'color, background-color, border-color, box-shadow, opacity',
    transitionDuration: '150ms',
    transitionTimingFunction: 'ease',
    '&:focus-visible': {
      outline: '2px solid transparent',
      outlineOffset: '2px',
      boxShadow:
        '0 0 0 2px hsl(var(--background, 255 255 255)), 0 0 0 4px hsl(var(--ring, 240 5.9% 10%))',
    },
    '&:disabled': {
      pointerEvents: 'none',
      opacity: '0.5',
    },
  }

  addComponents({
    // ----- Buttons -------------------------------------------
    '.web3-connect-btn': {
      ...buttonBase,
      backgroundColor: 'hsl(var(--primary, 240 5.9% 10%))',
      color: 'hsl(var(--primary-foreground, 0 0% 98%))',
      '&:hover:not(:disabled)': {
        backgroundColor: 'hsl(var(--primary, 240 5.9% 10%) / 0.9)',
      },
    },

    '.web3-disconnect-btn': {
      ...buttonBase,
      backgroundColor: 'hsl(var(--background, 0 0% 100%))',
      color: 'hsl(var(--foreground, 240 10% 3.9%))',
      borderColor: 'hsl(var(--input, 240 5.9% 90%))',
      '&:hover': {
        backgroundColor: 'hsl(var(--accent, 240 4.8% 95.9%))',
        color: 'hsl(var(--accent-foreground, 240 5.9% 10%))',
      },
    },

    '.web3-action-btn': {
      ...buttonBase,
      backgroundColor: 'hsl(var(--primary, 240 5.9% 10%))',
      color: 'hsl(var(--primary-foreground, 0 0% 98%))',
      '&:hover:not(:disabled)': {
        backgroundColor: 'hsl(var(--primary, 240 5.9% 10%) / 0.9)',
      },
    },

    '.web3-action-btn--pending': {
      pointerEvents: 'none',
      opacity: '0.5',
    },

    '.web3-sign-btn': {
      ...buttonBase,
      backgroundColor: 'hsl(var(--primary, 240 5.9% 10%))',
      color: 'hsl(var(--primary-foreground, 0 0% 98%))',
      '&:hover:not(:disabled)': {
        backgroundColor: 'hsl(var(--primary, 240 5.9% 10%) / 0.9)',
      },
    },

    // ----- Wallet UI -----------------------------------------
    '.web3-wallet-state': {
      display: 'inline-flex',
      alignItems: 'center',
      gap: '0.75rem',
      flexWrap: 'wrap',
    },

    '.web3-wallet-picker': {
      display: 'flex',
      flexDirection: 'column',
      gap: '0.25rem',
      minWidth: '240px',
      padding: '0.25rem',
      backgroundColor: 'hsl(var(--popover, 0 0% 100%))',
      border: '1px solid hsl(var(--border, 240 5.9% 90%))',
      borderRadius: 'calc(var(--radius, 0.5rem) + 0.125rem)',
      boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.07), 0 2px 4px -2px rgb(0 0 0 / 0.05)',
    },

    '.web3-wallet-option': {
      ...buttonBase,
      display: 'flex',
      justifyContent: 'flex-start',
      padding: '0.5rem 0.75rem',
      backgroundColor: 'transparent',
      color: 'hsl(var(--popover-foreground, 240 10% 3.9%))',
      fontWeight: '400',
      textTransform: 'none',
      letterSpacing: 'normal',
      '&:hover': {
        backgroundColor: 'hsl(var(--accent, 240 4.8% 95.9%))',
        color: 'hsl(var(--accent-foreground, 240 5.9% 10%))',
      },
      '& img': {
        width: '1.5rem',
        height: '1.5rem',
        borderRadius: '0.25rem',
        flexShrink: '0',
      },
    },

    '.web3-chain-badge': {
      display: 'inline-flex',
      alignItems: 'center',
      padding: '0.125rem 0.625rem',
      fontSize: '0.75rem',
      fontWeight: '500',
      borderRadius: '9999px',
      border: '1px solid hsl(var(--border, 240 5.9% 90%))',
      backgroundColor: 'hsl(var(--secondary, 240 4.8% 95.9%))',
      color: 'hsl(var(--secondary-foreground, 240 5.9% 10%))',
      whiteSpace: 'nowrap',
    },

    // ----- Transaction badges --------------------------------
    '.web3-tx-badge': {
      display: 'inline-flex',
      alignItems: 'center',
      padding: '0.125rem 0.625rem',
      fontSize: '0.75rem',
      fontWeight: '500',
      borderRadius: '9999px',
      border: '1px solid transparent',
      whiteSpace: 'nowrap',
    },

    '.web3-tx-badge--idle': {
      backgroundColor: 'hsl(var(--muted, 240 4.8% 95.9%))',
      color: 'hsl(var(--muted-foreground, 240 3.8% 46.1%))',
    },

    '.web3-tx-badge--pending': {
      backgroundColor: 'hsl(38 92% 95%)',
      color: 'hsl(32 95% 35%)',
      borderColor: 'hsl(38 92% 80%)',
    },

    '.web3-tx-badge--confirmed': {
      backgroundColor: 'hsl(142 72% 94%)',
      color: 'hsl(142 76% 25%)',
      borderColor: 'hsl(142 72% 78%)',
    },

    '.web3-tx-badge--failed': {
      backgroundColor: 'hsl(var(--destructive, 0 84.2% 60.2%) / 0.1)',
      color: 'hsl(var(--destructive, 0 84.2% 60.2%))',
      borderColor: 'hsl(var(--destructive, 0 84.2% 60.2%) / 0.3)',
    },

    '.web3-tx-badge--rejected': {
      backgroundColor: 'hsl(var(--muted, 240 4.8% 95.9%))',
      color: 'hsl(var(--muted-foreground, 240 3.8% 46.1%))',
    },

    // ----- Links & display -----------------------------------
    '.web3-tx-link': {
      fontFamily: 'ui-monospace, SFMono-Regular, Menlo, "Courier New", monospace',
      fontSize: '0.8125rem',
      color: 'hsl(var(--primary, 240 5.9% 10%))',
      textDecoration: 'underline',
      textUnderlineOffset: '4px',
      textDecorationColor: 'hsl(var(--primary, 240 5.9% 10%) / 0.4)',
      '&:hover': {
        textDecorationColor: 'hsl(var(--primary, 240 5.9% 10%))',
      },
    },

    '.web3-address': {
      fontFamily: 'ui-monospace, SFMono-Regular, Menlo, "Courier New", monospace',
      fontSize: '0.8125rem',
      color: 'hsl(var(--foreground, 240 10% 3.9%))',
      textDecoration: 'none',
    },

    'a.web3-address': {
      color: 'hsl(var(--primary, 240 5.9% 10%))',
      textDecoration: 'underline',
      textUnderlineOffset: '4px',
    },

    // ----- Receipt -------------------------------------------
    '.web3-receipt': {
      display: 'flex',
      flexDirection: 'column',
      gap: '0.625rem',
      padding: '1rem',
      backgroundColor: 'hsl(var(--card, 0 0% 100%))',
      color: 'hsl(var(--card-foreground, 240 10% 3.9%))',
      border: '1px solid hsl(var(--border, 240 5.9% 90%))',
      borderRadius: 'var(--radius, 0.5rem)',
      fontSize: '0.875rem',
    },

    '.web3-receipt--success': {
      borderColor: 'hsl(142 72% 78%)',
    },

    '.web3-receipt--failed': {
      borderColor: 'hsl(var(--destructive, 0 84.2% 60.2%) / 0.4)',
    },

    '.web3-receipt-field': {
      display: 'flex',
      alignItems: 'center',
      gap: '0.5rem',
      color: 'hsl(var(--muted-foreground, 240 3.8% 46.1%))',
    },

    // ----- Balance -------------------------------------------
    '.web3-balance': {
      fontVariantNumeric: 'tabular-nums',
      fontSize: '0.9375rem',
      fontWeight: '500',
      color: 'hsl(var(--foreground, 240 10% 3.9%))',
    },

    '.web3-balance--loading': {
      color: 'hsl(var(--muted-foreground, 240 3.8% 46.1%))',
      animation: 'web3-pulse 1.5s ease-in-out infinite',
    },

    // ----- Inputs --------------------------------------------
    '.web3-input-address, .web3-input-bigint, .web3-input-text, .web3-input-bytes': {
      boxSizing: 'border-box',
      display: 'block',
      width: '100%',
      padding: '0.5rem 0.75rem',
      fontSize: '0.875rem',
      lineHeight: '1.5',
      color: 'hsl(var(--foreground, 240 10% 3.9%))',
      backgroundColor: 'hsl(var(--background, 0 0% 100%))',
      border: '1px solid hsl(var(--input, 240 5.9% 90%))',
      borderRadius: 'var(--radius, 0.5rem)',
      outline: 'none',
      transitionProperty: 'border-color, box-shadow',
      transitionDuration: '150ms',
      '&:focus': {
        borderColor: 'hsl(var(--ring, 240 5.9% 10%))',
        boxShadow:
          '0 0 0 2px hsl(var(--background, 0 0% 100%)), 0 0 0 4px hsl(var(--ring, 240 5.9% 10%))',
      },
    },

    '.web3-input-address, .web3-input-bytes': {
      fontFamily: 'ui-monospace, SFMono-Regular, Menlo, "Courier New", monospace',
      fontSize: '0.8125rem',
    },

    '.web3-input-address--invalid, .web3-input-bigint--invalid, .web3-input-bytes--invalid': {
      borderColor: 'hsl(var(--destructive, 0 84.2% 60.2%))',
      '&:focus': {
        boxShadow:
          '0 0 0 2px hsl(var(--background, 0 0% 100%)), 0 0 0 4px hsl(var(--destructive, 0 84.2% 60.2%))',
      },
    },

    '.web3-input-bool': {
      width: '1rem',
      height: '1rem',
      cursor: 'pointer',
      accentColor: 'hsl(var(--primary, 240 5.9% 10%))',
    },

    // ----- Sign ----------------------------------------------
    '.web3-sign-state': {
      display: 'inline-block',
      fontSize: '0.875rem',
      color: 'hsl(var(--muted-foreground, 240 3.8% 46.1%))',
    },

    '.web3-signature': {
      padding: '0.875rem',
      backgroundColor: 'hsl(var(--muted, 240 4.8% 95.9%))',
      border: '1px solid hsl(var(--border, 240 5.9% 90%))',
      borderRadius: 'var(--radius, 0.5rem)',
      wordBreak: 'break-all',
    },

    '.web3-signature-value': {
      fontFamily: 'ui-monospace, SFMono-Regular, Menlo, "Courier New", monospace',
      fontSize: '0.75rem',
      color: 'hsl(var(--muted-foreground, 240 3.8% 46.1%))',
      background: 'none',
      padding: '0',
    },
  })

  // Keyframe for loading animation
  addUtilities({
    '@keyframes web3-pulse': {
      '0%, 100%': { opacity: '1' },
      '50%': { opacity: '0.4' },
    },
  })
})
