##key : share freely##

####About Key####
Key is an end-to-end encrypted social utility that allows people to share freely with their friends. 

Key is built on top of the FreeKey encryption protocol, which is a custom implementation of the axolotl protocol developed by Open Whisper Systems and Trevor Perrin. 

FreeKey is designed to offer perfect forward secrecy and replay protection, and relies on:
-EC-25519 for Public/Private Key generation 
-ECDH for Shared-Key Agreement 
-ECDSA for signing
-SHA-256 for MAC generation and verification.

####Running Locally####

- Install CocoaPods
- Run `$ pod install`
- CocoaPods will generate a new Key.xcworkspace file
- Open the new Key.xcworkspace file
- Build and run the Key project

