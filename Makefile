# Clinical Scribe - Build and Package
#
# Quick start:
#   make build              # Build unsigned .app
#   make dmg                # Create unsigned DMG
#
# With code signing:
#   make build DEVELOPER_ID="Developer ID Application: Your Name (TEAM_ID)"
#   make dmg DEVELOPER_ID="Developer ID Application: Your Name (TEAM_ID)"
#
# Full release:
#   make release DEVELOPER_ID="..." APPLE_ID="..." TEAM_ID="..." APP_PASSWORD="..."

.PHONY: build dmg notarize release install run clean help

# Export for subscripts
export DEVELOPER_ID
export APPLE_ID
export TEAM_ID
export APP_PASSWORD

build:
	@chmod +x scripts/build-app.sh
	@./scripts/build-app.sh

dmg: build
	@chmod +x scripts/create-dmg.sh
	@./scripts/create-dmg.sh

notarize:
	@chmod +x scripts/notarize.sh
	@./scripts/notarize.sh

release: dmg notarize
	@echo "🎉 Release build complete!"

install: build
	@cp -R "build/Clinical Scribe.app" /Applications/
	@echo "✅ Installed to /Applications/Clinical Scribe.app"

run: build
	@open "build/Clinical Scribe.app"

clean:
	@rm -rf build/ .build/
	@echo "✅ Cleaned"

help:
	@echo "Targets:"
	@echo "  build     - Build .app bundle"
	@echo "  dmg       - Create DMG installer"
	@echo "  notarize  - Notarize for distribution"
	@echo "  release   - Full signed + notarized release"
	@echo "  install   - Install to /Applications"
	@echo "  run       - Build and launch"
	@echo "  clean     - Remove build artifacts"
