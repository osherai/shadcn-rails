# Installation

The more automated way to install the components into your application is via the gem packaged
within this application. The gem provides generators that will setup your applications as best as
possible without potentially overwriting any existing code as well as copy components and their
dependencies to your application.

## Add the Gem

First step is adding the gem to your gemfile.

```sh
bundle add shadcn-ui
bundle install
```

## Install and Setup Dependencies

### TailwindCSS

The components need a few things in order to render and function properly

1. Tailwindcss must be installed in your application. If it's not already, I recommend just using
   the `tailwindcss-rails` gem and running its installer to bootstrap your application with
   TailwindCSS.

2. A few Tailwind CSS npm packages are required by the theme and the best way to get them is to add
   them to your package.json. Even if your application doesn't otherwise use Node packages (for
   example because you rely on import maps), having a lightweight `package.json` is enough for the
   Tailwind CLI to resolve these optional plugins. Create a package.json if you need via
   `echo '{}' >> package.json`, then add the following dependencies:

```
@tailwindcss/forms
@tailwindcss/aspect-ratio
@tailwindcss/typography
@tailwindcss/container-queries
```

Animation utilities used by the components ship with the gem, so no additional animation plugin is required when using Tailwind CSS v4.

### shadcn CSS - Required

#### shadcn.css

These steps were not automated and are required to be done manually.

The components also require a few CSS variables to be set in order to render properly. It's a two
step process, first, the gem installation should have added `app/assets/stylesheets/shadcn.css` to
your application. You need to make sure this is imported by your Tailwind entrypoint (for example
`app/assets/tailwind/application.css`), which should have happened automatically, but double check.

```
@config "../../../config/tailwind.config.js";
@tailwind base;
@tailwind components;
@tailwind utilities;

@import "../stylesheets/shadcn.css";
```

Adjust the relative paths in the snippet above if your entrypoint lives somewhere other than
`app/assets/tailwind`.

#### shadcn.tailwind configuration

The installation also should have added a `config/shadcn.tailwind.*` file to your application. The
extension matches the Tailwind config that already exists in your project (`tailwind.config.js`,
`tailwind.config.ts`, etc.). Make sure to import it in that config.

If you are using a CommonJS config (`tailwind.config.js` / `.cjs`):

```js
const defaultTheme = require("tailwindcss/defaultTheme");
const shadcnConfig = require("./shadcn.tailwind.js");

module.exports = {
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
  ...shadcnConfig,
};
```

For an ESM or TypeScript config (`tailwind.config.mjs` / `.ts`):

```ts
import forms from "@tailwindcss/forms";
import aspectRatio from "@tailwindcss/aspect-ratio";
import typography from "@tailwindcss/typography";
import containerQueries from "@tailwindcss/container-queries";
import defaultTheme from "tailwindcss/defaultTheme";
import shadcnConfig from "./shadcn.tailwind";

export default {
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter var", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [forms, aspectRatio, typography, containerQueries],
  ...shadcnConfig,
};
```

You can also export the shadcn config directly if you do not need further customization:

```ts
import shadcnConfig from "./shadcn.tailwind";

export default {
  ...shadcnConfig,
};
```

After that feel free to add further customizatios to your tailwind config. For an existing tailwind
config, just add shadcnConfig to the end of the config object. It will override any settings needed
by being at the end. And obviously feel free to inspect shadcnConfig and keep only what's reui

## End

That's it! You are now set to start
[installing components via the generator](/docs/generators) and rendering them into your
views.

# Manual Installation

Prior to the initial gem release, you can use this as an alpha by cloning this repository and
starting up the app as you would a standard rails app.

```sh
git clone https://github.com/aviflombaum/shadcn-rails.git
cd shadcn-rails
bundle install
./bin/dev
```

There are very few dependencies and no database so it should just boot up. Visit
http://localhost:3000 to see the demo app which is also the documentation. You'll be able to browse
the components at http://localhost:3000/components.

If there's a component you want to try in your app, you will be copying the code from this app to
yours. There's a few other steps you'll need.

## Installing a Component

### Add Tailwind CSS

Components are styled using Tailwind CSS. You need to install Tailwind CSS in your project.

[Follow the Tailwind CSS installation instructions to get started.](https://tailwindcss.com/docs/installation)

### Add dependencies

If you haven't already, install Tailwind into your rails application by adding `tailwindcss-rails`
to your `Gemfile` and install tailwind into your app:

```sh
./bin/bundle add tailwindcss-rails
./bin/rails tailwindcss:install
```

Then install ./bin/rails tailwindcss:install

### Configure tailwind.config.js

Here's what my `tailwind.config.js` file looks like:

```js
const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  darkMode: ["class"],
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: {
        "2xl": "1400px",
      },
    },
    extend: {
      colors: {
        border: "hsl(var(--border))",
        input: "hsl(var(--input))",
        ring: "hsl(var(--ring))",
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        primary: {
          DEFAULT: "hsl(var(--primary))",
          foreground: "hsl(var(--primary-foreground))",
        },
        secondary: {
          DEFAULT: "hsl(var(--secondary))",
          foreground: "hsl(var(--secondary-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
          foreground: "hsl(var(--destructive-foreground))",
        },
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        accent: {
          DEFAULT: "hsl(var(--accent))",
          foreground: "hsl(var(--accent-foreground))",
        },
        popover: {
          DEFAULT: "hsl(var(--popover))",
          foreground: "hsl(var(--popover-foreground))",
        },
        card: {
          DEFAULT: "hsl(var(--card))",
          foreground: "hsl(var(--card-foreground))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      fontFamily: {
        sans: ["var(--font-sans)", ...defaultTheme.fontFamily.sans],
      },
      keyframes: {
        "accordion-down": {
          from: { height: 0 },
          to: { height: "var(--radix-accordion-content-height)" },
        },
        "accordion-up": {
          from: { height: "var(--radix-accordion-content-height)" },
          to: { height: 0 },
        },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
};
```

### Configure styles

Add the following to your Tailwind entrypoint (for example `app/assets/tailwind/application.css`, `app/assets/stylesheets/application.tailwind.css`, or `app/frontend/stylesheets/application.css`).

```css
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 47.4% 11.2%;

    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;

    --popover: 0 0% 100%;
    --popover-foreground: 222.2 47.4% 11.2%;

    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;

    --card: 0 0% 100%;
    --card-foreground: 222.2 47.4% 11.2%;

    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;

    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;

    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;

    --destructive: 0 100% 50%;
    --destructive-foreground: 210 40% 98%;

    --ring: 215 20.2% 65.1%;

    --radius: 0.5rem;
  }

  .dark {
    --background: 224 71% 4%;
    --foreground: 213 31% 91%;

    --muted: 223 47% 11%;
    --muted-foreground: 215.4 16.3% 56.9%;

    --accent: 216 34% 17%;
    --accent-foreground: 210 40% 98%;

    --popover: 224 71% 4%;
    --popover-foreground: 215 20.2% 65.1%;

    --border: 216 34% 17%;
    --input: 216 34% 17%;

    --card: 224 71% 4%;
    --card-foreground: 213 31% 91%;

    --primary: 210 40% 98%;
    --primary-foreground: 222.2 47.4% 1.2%;

    --secondary: 222.2 47.4% 11.2%;
    --secondary-foreground: 210 40% 98%;

    --destructive: 0 63% 31%;
    --destructive-foreground: 210 40% 98%;

    --ring: 216 34% 17%;

    --radius: 0.5rem;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
    font-feature-settings:
      "rlig" 1,
      "calt" 1;
  }
}
```

### Copy Component Files

For example, if you want to use the Accordion component, you would copy the following files to your
application:

- `app/javascript/controllers/components/ui/accordion_controller.js` The Stimulus controller for any
  component that requires javascript.
- `app/helpers/components/accordion_helper.rb` The helper for the component that allows for easy
  rendering within views.
- `app/views/components/ui/_accordion.html.erb` The html for the component.

Once those are copied in your application you can render an accordion with:

```
<%%= render_accordion title: "Did you know?",
                      description: "You can wrap shadcn helpers in any
                                    component library you want!" %>
```

Result:

<img src="/accordion.png" alt="Example of Accordion" />

See the component's demo page in `app/views/examples/components/accordion.html.erb` for more
examples.

This will be similar for each component.

# Conclusion

You can freely mix and match both styles as your application evolves. The end goal of each of them
is to get the component code into your application so you can further customize and take ownership
of your design system.
