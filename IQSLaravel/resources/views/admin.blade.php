<!DOCTYPE html>
<html lang="ar" dir="rtl" class="h-full">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <meta name="color-scheme" content="light dark">
    <title>{{ config('app.name', 'IQS') }} — لوحة التحكم</title>

    {{-- Fonts: Cairo covers Arabic + Latin glyphs for a consistent RTL/LTR look --}}
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">

    {{-- Apply persisted theme before paint to avoid a flash of the wrong mode --}}
    <script>
        (function () {
            try {
                if (localStorage.getItem('iqs.theme') === 'dark') {
                    document.documentElement.classList.add('dark');
                }
                var locale = localStorage.getItem('iqs.locale') || 'ar';
                document.documentElement.lang = locale;
                document.documentElement.dir = locale === 'ar' ? 'rtl' : 'ltr';
            } catch (e) {}
        })();
    </script>

    @vite(['resources/css/admin.css', 'resources/js/admin/main.js'])
</head>
<body class="h-full antialiased">
    <div id="admin-app" class="h-full"></div>
</body>
</html>
