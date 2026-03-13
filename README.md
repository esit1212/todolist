# testverst4

A new Flutter project.

## Собрать тестовый `.ipa` на старом Mac (старый Xcode)

Если Xcode/ macOS старые, локальная сборка iOS часто не взлетает (несовместимые Xcode/SDK/Pods). Самый надёжный способ — собрать `.ipa` удалённо на актуальном macOS через CI (например, Codemagic).

### Вариант A (рекомендуется): Codemagic

В репозитории уже есть `codemagic.yaml` с workflow `ios_ipa_release`.

1) Запушьте проект в ваш GitHub.

2) В Codemagic:
- Add app → выберите репозиторий.
- Включите сборку из `codemagic.yaml`.

3) Настройте bundle id.
- В `codemagic.yaml` измените `CM_BUNDLE_ID` на ваш реальный bundle id (он должен существовать в Apple Developer аккаунте).

4) Настройте подпись (чтобы `.ipa` установился на устройство).
В Codemagic UI добавьте secure env vars для App Store Connect API key:
- `APP_STORE_CONNECT_KEY_IDENTIFIER`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

Workflow скачает development-сертификат/профиль и соберёт **подписанный** release `.ipa`.

5) Запустите build. Готовый файл появится в Artifacts:
- `build/ios/ipa/*.ipa`

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# todolist
