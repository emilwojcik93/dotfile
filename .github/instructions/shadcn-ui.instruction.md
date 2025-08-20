---
applyTo: '**/*.{js,jsx,ts,tsx,md}'
---

# shadcn/ui Development Instructions (2025)

Last updated: August 2025

## Core Principle
• Always use the fetch tool to look up the latest component usage, install name, and best practices directly from the official shadcn/ui documentation: https://ui.shadcn.com/docs/components
• Do not rely on what you think you know about shadcn/ui components, as they are frequently updated and improved. Your training data is outdated.
• For any shadcn/ui component, CLI command, or usage pattern, fetch the relevant page from the docs and follow the instructions there.

## Component Usage Rules

### Installation and Setup
1. **Always fetch documentation first**: Before using any component, use fetch_webpage to get the latest docs from https://ui.shadcn.com/docs/components/[component-name]
2. **Use the CLI**: pnpm dlx shadcn@latest add <component> or 
px shadcn@latest add <component>
3. **Check dependencies**: Some components require additional packages - always check the component's docs

### Code Practices
1. **Import paths**: Always import from @/components/ui/<component>
2. **Customization**: Components are designed to be copied and modified - don't hesitate to customize
3. **Accessibility**: Follow the accessibility guidelines provided in each component's documentation
4. **Composition**: Use component composition patterns as shown in the docs

### Common Components (Always verify with fetch before using)

#### Form Components
- **Form**: Complex validation with React Hook Form and Zod
- **Input**: Text input with variants
- **Button**: Primary interaction element
- **Select**: Dropdown selection
- **Checkbox**: Boolean selection
- **RadioGroup**: Single selection from multiple options

#### Layout Components  
- **Card**: Content containers
- **Sheet**: Slide-out panels
- **Dialog**: Modal dialogs
- **Tabs**: Tabbed interfaces
- **Accordion**: Collapsible content

#### Data Display
- **Table**: Data tables with sorting/filtering
- **Badge**: Status indicators
- **Avatar**: User representation
- **Skeleton**: Loading states

### Development Workflow
1. **Research**: Use fetch_webpage to get latest component documentation
2. **Install**: Use CLI to add component to project
3. **Import**: Import from local path @/components/ui/
4. **Customize**: Modify as needed for your use case
5. **Test**: Ensure accessibility and responsiveness

### Best Practices
- **Performance**: Components are optimized but watch bundle size
- **Theming**: Use CSS variables for consistent theming
- **Responsive**: Test all breakpoints
- **Dark Mode**: Components support dark mode by default
- **Type Safety**: Full TypeScript support included

### Troubleshooting
- **Import errors**: Check if component was installed via CLI
- **Styling issues**: Verify Tailwind CSS is properly configured
- **Type errors**: Ensure latest TypeScript types are installed
- **Missing dependencies**: Check component docs for required packages

## Summary
> For all shadcn/ui work, always use the fetch tool to look up the latest component documentation and usage from https://ui.shadcn.com/docs/components. Do not rely on static instructions.
