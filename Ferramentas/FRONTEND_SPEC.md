# Frontend Design Specification

## Color Palette (Tailwind Tokens)

### Primary Colors
| Role           | Light Mode          | Dark Mode            | Tailwind Class                        |
|---------------|---------------------|----------------------|---------------------------------------|
| Primary       | `#3b82f6`           | `#60a5fa`            | `blue-500` / `blue-400`               |
| Primary Hover | `#2563eb`           | `#3b82f6`            | `blue-600` / `blue-500`               |

### Surface Colors
| Role           | Light Mode          | Dark Mode            | Tailwind Class                        |
|---------------|---------------------|----------------------|---------------------------------------|
| Page Background| `#f8fafc`           | `#0f172a`            | `bg-slate-50` / `dark:bg-slate-900`   |
| Card Surface  | `#ffffff`           | `#1e293b`            | `bg-white` / `dark:bg-slate-800`      |
| Sidebar       | `#ffffff`           | `#0f172a`            | `bg-white` / `dark:bg-slate-900`      |
| Navbar        | `#ffffff`           | `#1e293b`            | `bg-white` / `dark:bg-slate-800`      |
| Input         | `#ffffff`           | `#1e293b`            | `bg-white dark:bg-slate-800`          |

### Border Colors
| Role           | Light Mode          | Dark Mode            | Tailwind Class                        |
|---------------|---------------------|----------------------|---------------------------------------|
| Default       | `#e2e8f0`           | `#334155`            | `border-slate-200 dark:border-slate-700`|
| Strong        | `#cbd5e1`           | `#475569`            | `border-slate-300 dark:border-slate-600`|

### Text Colors
| Role           | Light Mode          | Dark Mode            | Tailwind Class                        |
|---------------|---------------------|----------------------|---------------------------------------|
| Primary Text  | `#0f172a`           | `#f8fafc`            | `text-slate-900 dark:text-white`      |
| Secondary Text| `#64748b`           | `#94a3b8`            | `text-slate-500 dark:text-slate-400`  |
| Muted Text    | `#94a3b8`           | `#64748b`            | `text-slate-400 dark:text-slate-500`  |
| Link Text     | `#3b82f6`           | `#60a5fa`            | `text-blue-600 dark:text-blue-400`    |

### Status Colors
| Status       | Background (light)   | Text (light)        | Background (dark)     | Text (dark)         |
|-------------|---------------------|---------------------|----------------------|---------------------|
| open        | `bg-blue-50`        | `text-blue-700`     | `dark:bg-blue-900/30`| `dark:text-blue-400`|
| in_progress | `bg-amber-50`       | `text-amber-700`    | `dark:bg-amber-900/30`| `dark:text-amber-400`|
| resolved    | `bg-emerald-50`     | `text-emerald-700`  | `dark:bg-emerald-900/30`| `dark:text-emerald-400`|
| closed      | `bg-slate-50`       | `text-slate-600`    | `dark:bg-slate-700`  | `dark:text-slate-400`|

### Priority Colors
| Priority  | Background (light)  | Text (light)      | Background (dark)      | Text (dark)         |
|----------|--------------------|--------------------|-----------------------|---------------------|
| low      | `bg-slate-100`     | `text-slate-700`   | `dark:bg-slate-700`   | `dark:text-slate-300`|
| medium   | `bg-blue-100`      | `text-blue-700`    | `dark:bg-blue-900/30` | `dark:text-blue-400` |
| high     | `bg-orange-100`    | `text-orange-700`  | `dark:bg-orange-900/30`| `dark:text-orange-400`|
| critical | `bg-red-100`       | `text-red-700`     | `dark:bg-red-900/30`  | `dark:text-red-400`  |

---

## Typography Scale

| Element          | Size    | Weight   | Tailwind Classes                          |
|-----------------|---------|----------|-------------------------------------------|
| Page Title      | 24px    | 700      | `text-2xl font-bold`                       |
| Section Title   | 18px    | 600      | `text-lg font-semibold`                    |
| Card Title      | 14px    | 500      | `text-sm font-medium`                      |
| Body Text       | 14px    | 400      | `text-sm`                                  |
| Small/Label     | 12px    | 500      | `text-xs font-medium`                      |
| KPI Value       | 30px    | 700      | `text-3xl font-bold`                       |
| Table Header    | 12px    | 600      | `text-xs font-semibold uppercase tracking-wider` |
| Table Body      | 14px    | 400      | `text-sm`                                  |
| Button          | 14px    | 500      | `text-sm font-medium`                      |

---

## Spacing System

Follows Tailwind's default spacing scale:
- Page padding: `p-6` (24px)
- Card padding: `p-6` (24px)
- Card gap: `gap-4` (16px) in grids
- Section vertical spacing: `space-y-6` (24px)
- Inline element spacing: `gap-2` or `gap-3`
- Table cell padding: `px-4 py-3`

---

## Dark Mode Strategy

**Method:** Tailwind `dark` class strategy (not media query).

**Implementation:**
1. `DarkModeToggle` component in Navbar
2. On toggle: `document.documentElement.classList.toggle('dark')`
3. Persisted to `localStorage` key `'darkMode'`
4. On app init: read `localStorage`, apply class if `true`
5. Zustand store holds `darkMode: boolean`
6. All components use `dark:` variants in Tailwind classes

**No `prefers-color-scheme`** — user explicitly controls the mode.

---

## Component Naming Conventions

- **Files:** PascalCase for components (`IncidentTable.jsx`), camelCase for utilities (`csvExport.js`)
- **Exports:** Named exports for all components (`export function Sidebar() {}`)
- **Props:** camelCase, React types via JSDoc (no TypeScript required)
- **State:** camelCase, prefixed with intent (`isLoading`, `sortField`, `filterValue`)
- **Events:** `on` prefix for callback props (`onSort`, `onFilterChange`, `onSubmit`)
- **Store actions:** verb-first (`setIncidents`, `addIncident`, `toggleSidebar`)

---

## Component Patterns

### All components follow this structure:
```jsx
export function ComponentName({ prop1, prop2, ...rest }) {
  // 1. Hooks (useState, useEffect, useMemo, etc.)
  // 2. Derived state / computations
  // 3. Event handlers
  // 4. Render
  return (
    <div className="...">
      {/* JSX */}
    </div>
  );
}
```

### Conditional classes:
Use template literals or array join pattern:
```jsx
className={cn(
  'base-classes',
  condition && 'conditional-classes',
  darkMode && 'dark-classes'
)}
```

A `cn` utility (clsx-style) is provided in `utils/cn.js`:
```js
export function cn(...classes) {
  return classes.filter(Boolean).join(' ');
}
```

---

## Button Styles

| Variant   | Light                          | Dark                              |
|-----------|--------------------------------|-----------------------------------|
| Primary   | `bg-blue-600 text-white hover:bg-blue-700` | `dark:bg-blue-500 dark:hover:bg-blue-600` |
| Secondary | `bg-white text-slate-700 border border-slate-300 hover:bg-slate-50` | `dark:bg-slate-800 dark:text-slate-300 dark:border-slate-600` |
| Danger    | `bg-red-600 text-white hover:bg-red-700` | `dark:bg-red-500 dark:hover:bg-red-600` |
| Ghost     | `text-slate-600 hover:bg-slate-100` | `dark:text-slate-400 dark:hover:bg-slate-700` |

All buttons: `rounded-lg px-4 py-2 text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2`

---

## Input Styles

Base: `w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:border-slate-600 dark:bg-slate-800 dark:text-white dark:placeholder:text-slate-500`

---

## Table Styles

- Container: `overflow-x-auto rounded-lg border border-slate-200 dark:border-slate-700`
- Header row: `bg-slate-50 dark:bg-slate-800`
- Body rows: `bg-white dark:bg-slate-900`, hover: `hover:bg-slate-50 dark:hover:bg-slate-800/50`
- Borders: `border-b border-slate-200 dark:border-slate-700`
- Striped (optional): odd rows `bg-slate-50/50 dark:bg-slate-800/30`

---

## Responsive Breakpoints

| Breakpoint | Width    | Behavior                          |
|-----------|----------|-----------------------------------|
| Mobile    | < 640px  | Single column, collapsed sidebar, stacked cards |
| Tablet    | 640-1024px | 2-column grid, collapsible sidebar |
| Desktop   | > 1024px | Full layout, 4-column grid, expanded sidebar default |
| Wide      | > 1280px | Max-width container 1280px for content |

---

## Transitions & Animations

- Sidebar collapse: `transition-all duration-300 ease-in-out`
- Card hover: `transition-shadow duration-200 hover:shadow-md`
- Page transitions: React.Suspense with fade (opacity 0→1, 200ms)
- Modal: backdrop fade + scale transform on panel
- Skeleton: `animate-pulse` (Tailwind built-in)
- Dark mode toggle: `transition-colors duration-200` on root element

---

## Scrollbar Styling

Custom CSS for webkit scrollbars:
```css
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 3px; }
.dark ::-webkit-scrollbar-thumb { background: #475569; }
```
