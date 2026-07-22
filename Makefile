help:
	@echo "Targets: get, analyze, test, format, run, build-apk, build-ios, clean"

get:
	flutter pub get

format:
	dart format lib test

analyze:
	dart analyze --fatal-infos

test:
	flutter test

run:
	flutter run

build-apk:
	flutter build apk --release --split-debug-info=build/symbols

build-ios:
	flutter build ios --release --no-codesign

clean:
	flutter clean
	rm -rf build
