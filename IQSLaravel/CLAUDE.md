<laravel-boost-guidelines>
=== foundation rules ===

# Laravel Boost Guidelines

The Laravel Boost guidelines are specifically curated by Laravel maintainers for this application. These guidelines should be followed closely to ensure the best experience when building Laravel applications.

## Foundational Context

This application is a Laravel application and its main Laravel ecosystems package & versions are below. You are an expert with them all. Ensure you abide by these specific packages & versions.

- php - 8.2
- laravel/framework (LARAVEL) - v12
- laravel/prompts (PROMPTS) - v0
- laravel/sanctum (SANCTUM) - v4
- laravel/boost (BOOST) - v2
- laravel/mcp (MCP) - v0
- laravel/pail (PAIL) - v1
- laravel/pint (PINT) - v1
- laravel/sail (SAIL) - v1
- phpunit/phpunit (PHPUNIT) - v11
- vue (VUE) - v3
- tailwindcss (TAILWINDCSS) - v4

## Conventions

- You must follow all existing code conventions used in this application. When creating or editing a file, check sibling files for the correct structure, approach, and naming.
- Use descriptive names for variables and methods. For example, `isRegisteredForDiscounts`, not `discount()`.
- Check for existing components to reuse before writing a new one.

## Verification Scripts

- Do not create verification scripts or tinker when tests cover that functionality and prove they work. Unit and feature tests are more important.

## Application Structure & Architecture

- Stick to existing directory structure; don't create new base folders without approval.
- Do not change the application's dependencies without approval.

## Frontend Bundling

- If the user doesn't see a frontend change reflected in the UI, it could mean they need to run `npm run build`, `npm run dev`, or `composer run dev`. Ask them.

## Documentation Files

- You must only create documentation files if explicitly requested by the user.

## Replies

- Be concise in your explanations - focus on what's important rather than explaining obvious details.

=== boost rules ===

# Laravel Boost

## Artisan

- Run Artisan commands directly via the command line (e.g., `php artisan route:list`). Use `php artisan list` to discover available commands and `php artisan [command] --help` to check parameters.
- Inspect routes with `php artisan route:list`. Filter with: `--method=GET`, `--name=users`, `--path=api`, `--except-vendor`, `--only-vendor`.
- Read configuration values using dot notation: `php artisan config:show app.name`, `php artisan config:show database.default`. Or read config files directly from the `config/` directory.

## Tinker

- Execute PHP in app context for debugging and testing code. Do not create models without user approval, prefer tests with factories instead. Prefer existing Artisan commands over custom tinker code.
- Always use single quotes to prevent shell expansion: `php artisan tinker --execute 'Your::code();'`
  - Double quotes for PHP strings inside: `php artisan tinker --execute 'User::where("active", true)->count();'`

=== php rules ===

# PHP

- Always use curly braces for control structures, even for single-line bodies.
- Use PHP 8 constructor property promotion: `public function __construct(public GitHub $github) { }`. Do not leave empty zero-parameter `__construct()` methods unless the constructor is private.
- Use explicit return type declarations and type hints for all method parameters: `function isAccessible(User $user, ?string $path = null): bool`
- Use TitleCase for Enum keys: `FavoritePerson`, `BestLake`, `Monthly`.
- Prefer PHPDoc blocks over inline comments. Only add inline comments for exceptionally complex logic.
- Use array shape type definitions in PHPDoc blocks.

=== deployments rules ===

# Deployment

- Laravel can be deployed using [Laravel Cloud](https://cloud.laravel.com/), which is the fastest way to deploy and scale production Laravel applications.

=== laravel/core rules ===

# Do Things the Laravel Way

- Use `php artisan make:` commands to create new files (i.e. migrations, controllers, models, etc.). You can list available Artisan commands using `php artisan list` and check their parameters with `php artisan [command] --help`.
- If you're creating a generic PHP class, use `php artisan make:class`.
- Pass `--no-interaction` to all Artisan commands to ensure they work without user input. You should also pass the correct `--options` to ensure correct behavior.

### Model Creation

- When creating new models, create useful factories and seeders for them too. Ask the user if they need any other things, using `php artisan make:model --help` to check the available options.

## APIs & Eloquent Resources

- For APIs, default to using Eloquent API Resources and API versioning unless existing API routes do not, then you should follow existing application convention.

## URL Generation

- When generating links to other pages, prefer named routes and the `route()` function.

## Testing

- When creating models for tests, use the factories for the models. Check if the factory has custom states that can be used before manually setting up the model.
- Faker: Use methods such as `$this->faker->word()` or `fake()->randomDigit()`. Follow existing conventions whether to use `$this->faker` or `fake()`.
- When creating tests, make use of `php artisan make:test [options] {name}` to create a feature test, and pass `--unit` to create a unit test. Most tests should be feature tests.

## Vite Error

- If you receive an "Illuminate\Foundation\ViteException: Unable to locate file in Vite manifest" error, you can run `npm run build` or ask the user to run `npm run dev` or `composer run dev`.

=== laravel/v12 rules ===

# Laravel 12

- Since Laravel 11, Laravel has a new streamlined file structure which this project uses.

## Laravel 12 Structure

- In Laravel 12, middleware are no longer registered in `app/Http/Kernel.php`.
- Middleware are configured declaratively in `bootstrap/app.php` using `Application::configure()->withMiddleware()`.
- `bootstrap/app.php` is the file to register middleware, exceptions, and routing files.
- `bootstrap/providers.php` contains application specific service providers.
- The `app/Console/Kernel.php` file no longer exists; use `bootstrap/app.php` or `routes/console.php` for console configuration.
- Console commands in `app/Console/Commands/` are automatically available and do not require manual registration.

## Database

- When modifying a column, the migration must include all of the attributes that were previously defined on the column. Otherwise, they will be dropped and lost.
- Laravel 12 allows limiting eagerly loaded records natively, without external packages: `$query->latest()->limit(10);`.

### Models

- Casts can and likely should be set in a `casts()` method on a model rather than the `$casts` property. Follow existing conventions from other models.

=== pint/core rules ===

# Laravel Pint Code Formatter

- If you have modified any PHP files, you must run `vendor/bin/pint --dirty --format agent` before finalizing changes to ensure your code matches the project's expected style.
- Do not run `vendor/bin/pint --test --format agent`, simply run `vendor/bin/pint --format agent` to fix any formatting issues.

=== phpunit/core rules ===

# PHPUnit

- This application uses PHPUnit for testing. All tests must be written as PHPUnit classes. Use `php artisan make:test --phpunit {name}` to create a new test.
- If you see a test using "Pest", convert it to PHPUnit.
- Every time a test has been updated, run that singular test.
- When the tests relating to your feature are passing, ask the user if they would like to also run the entire test suite to make sure everything is still passing.
- Tests should cover all happy paths, failure paths, and edge cases.
- You must not remove any tests or test files from the tests directory without approval. These are not temporary or helper files; these are core to the application.

## Running Tests

- Run the minimal number of tests, using an appropriate filter, before finalizing.
- To run all tests: `php artisan test --compact`.
- To run all tests in a file: `php artisan test --compact tests/Feature/ExampleTest.php`.
- To filter on a particular test name: `php artisan test --compact --filter=testName` (recommended after making a change to a related file).

</laravel-boost-guidelines>

# Admin Panel Frontend (Vue 3 SPA)

The admin panel is a standalone **Vue 3 SPA** in `resources/js/admin/`, served by the `/admin/{any?}` shell route (`resources/views/admin.blade.php`). Stack: Vue 3 + Vue Router (history, base `/admin`) + Pinia + **PrimeVue 4** + Tailwind v4. It is **Arabic-first / RTL**, with a working LTR + light/dark toggle. Built by Vite — after changing admin frontend files run `npm run build` (or `npm run dev`).

## PrimeVue is the UI kit — use it, don't hand-roll

- **Always build forms, inputs, dropdowns, tables, dialogs, menus and overlays with PrimeVue components.** Do not hand-roll `<select>`, `<input>`, custom modals, custom dropdowns, or custom tables when a PrimeVue component exists. Tailwind is for **layout and spacing only** (flex/grid/padding/gap, theme-aware `surface-*`/`primary` utilities from `tailwindcss-primeui`), not for re-implementing components.
- Component name map (PrimeVue 4 renamed several — use the new names):
  - Dropdown/select → **`Select`** (single) / **`MultiSelect`** (multi). (Not `Dropdown`.)
  - Sidebar/drawer → **`Drawer`**. Switch → **`ToggleSwitch`**. Calendar → **`DatePicker`**.
  - Text → `InputText`, `Textarea`, `Password`, `InputNumber`. Choice → `Checkbox` (`:binary`), `RadioButton`, `SelectButton`.
  - Data → `DataTable` + `Column` (with `paginator`, `sortable`, `filters`). Feedback → `Toast` (`useToast`), `ConfirmDialog` (`useConfirm`), `Tag`, `Badge`, `Message`.
- Commonly used components are **globally registered** in `resources/js/admin/plugins/primevue-components.js` — to use a new one, add its import there once, then use it in templates (no per-file import needed). Composables (`useToast`, `useConfirm`, `usePrimeVue`) are still imported per file.
- **Server-side validation is the source of truth.** Map 422 field errors back onto the PrimeVue inputs (use the `invalid` prop + `Message`); client validation is UX only.

## Theme, RTL & i18n

- **Theme:** emerald primary on a slate neutral surface scale, defined once in `resources/js/admin/theme/preset.js` (PrimeVue preset, Aura-based). Do not hardcode brand colors in components — use `primary`/`surface-*`/`emerald-*` utilities and PrimeVue `severity` props so light/dark and theming stay consistent. Dark mode = `.dark` class on `<html>` (toggled by the `ui` store).
- **RTL:** direction follows the locale (`ar` → `rtl`, `en` → `ltr`) and is set on `<html dir>`. Use Tailwind **logical** utilities (`ps-*`/`pe-*`, `ms-*`/`me-*`, `start-*`/`end-*`, `text-start`/`text-end`, `border-s`/`border-e`) instead of physical `left`/`right` so layouts mirror automatically. Force LTR only for inert data like phone numbers/scores (`dir="ltr"`).
- **i18n:** all user-facing strings go through vue-i18n (`t('...')`) with keys in **both** `resources/js/admin/i18n/locales/ar.js` and `en.js` — never hardcode UI copy. Arabic is the primary/default locale.
- **Permissions:** gate nav and actions client-side with `useCan('permission name')` (`composables/useCan.js`); the server still enforces via spatie `permission:` middleware.

## Structure & conventions

- `layouts/` (AppLayout = sidebar + topbar + footer; AuthLayout), `components/` (shared: PageHeader, StatCard, EmptyState, App*), `views/<module>/` (one folder per plan module), `stores/` (Pinia: `ui`, `auth`, per-domain), `api/` (axios modules; `client.js` is the configured instance with `withCredentials` + XSRF), `config/navigation.js` (sidebar — add new modules here), `composables/`.
- Auth runs in **DEMO_MODE** (`stores/auth.js`) until the `/admin/api/v1/{login,logout,me}` endpoints exist — flip `DEMO_MODE = false` to use the real session/`web`-guard backend.
- New page = add a route in `router/index.js` (with `meta.titleKey`, `meta.icon`, `meta.permission`), a nav entry in `config/navigation.js`, a view under `views/`, and i18n keys in both locale files. Start each view with `<PageHeader>`.
