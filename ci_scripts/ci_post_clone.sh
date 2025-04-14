#!/bin/sh

brew tap tuist/tuist
brew install --formula tuist

defaults delete com.apple.dt.Xcode IDEDisableAutomaticPackageResolution
defaults delete com.apple.dt.Xcode IDEPackageOnlyUseVersionsFromResolvedFile
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES

tuist generate --path .. --no-open
