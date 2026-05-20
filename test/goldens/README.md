# Golden Tests

Use Flutter's golden tests to validate UI consistency. This project uses `golden_toolkit` and `network_image_mock`.

## Run and Update Goldens

```bash
flutter test --update-goldens
```

## Notes

- If tests fail on CI, regenerate goldens locally with the command above and commit updated images.
- Ensure fonts load by keeping `loadAppFonts()` in golden tests.
